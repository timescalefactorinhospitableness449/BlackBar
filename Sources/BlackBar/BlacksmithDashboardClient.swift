import Foundation

struct BlacksmithDashboardClient {
    private let baseURL = URL(string: "https://dashboardbackend.blacksmith.sh/api")!
    private let cookieHeader: String

    init(cookieHeader: String) {
        self.cookieHeader = cookieHeader
    }

    func fetchUser() async throws -> BlacksmithUser {
        let data = try await request(path: "user")
        return try JSONDecoder().decode(BlacksmithUser.self, from: data)
    }

    func fetchUsage(owner: String, repoFilter: String) async throws -> BlacksmithUsage {
        async let currentCoreUsage = fetchCurrentCoreUsage(owner: owner)
        async let coreUsageSamples = fetchCoreUsageTimeseries(owner: owner)
        let core = try await currentCoreUsage
        let samples = (try? await coreUsageSamples) ?? []

        let end = Date()
        let start = end.addingTimeInterval(-12 * 60 * 60)
        var components = URLComponents(url: baseURL.appending(path: "user/github/orgs/\(owner)/metrics/actions/jobs/runs"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "start_date", value: Self.isoString(from: start)),
            URLQueryItem(name: "end_date", value: Self.isoString(from: end)),
            URLQueryItem(name: "limit", value: "200")
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        let jobs = (try? JSONDecoder().decode([BlacksmithJobRun].self, from: try await request(url: url))) ?? []
        let repoNeedle = repoFilter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let relevantJobs = jobs.filter { job in
            guard !repoNeedle.isEmpty else { return true }
            let repo = job.repositoryName.lowercased()
            return repo == repoNeedle || repo.hasSuffix("/\(repoNeedle)")
        }

        let active = relevantJobs.filter { $0.status.normalizedRunStatus == "in_progress" }
        let queued = relevantJobs.filter { $0.status.normalizedRunStatus == "queued" }
        let statusCounts = Dictionary(grouping: relevantJobs, by: { $0.status.normalizedRunStatus })
            .mapValues(\.count)
        let runnerTypes = Array(Set(relevantJobs.compactMap(\.runnerType))).sorted()
        let runs = active.prefix(20).map { job in
            WorkflowRunUsage(
                id: job.id,
                repository: job.repositoryName,
                title: job.name,
                workflowName: job.workflowName,
                url: job.githubURL,
                activeVCPU: job.vcpu,
                activeJobs: 1,
                queuedJobs: 0,
                jobs: [
                    JobUsage(
                        id: job.id,
                        name: job.name,
                        status: job.status,
                        url: job.githubURL,
                        vcpu: job.vcpu,
                        labels: [job.runnerType ?? "unknown"]
                    )
                ]
            )
        }

        return BlacksmithUsage(
            activeVCPU: core.total.vcpus,
            activeJobs: core.total.jobs,
            queuedJobs: queued.count,
            runs: Array(runs),
            fetchedJobs: relevantJobs.count,
            statusCounts: statusCounts,
            runnerTypes: runnerTypes,
            historyVCPU: samples.map(\.total.vcpus),
            platformUsage: core.platformUsage
        )
    }

    private func request(path: String) async throws -> Data {
        try await request(url: baseURL.appending(path: path))
    }

    private func request(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://app.blacksmith.sh", forHTTPHeaderField: "Origin")
        request.setValue("https://app.blacksmith.sh/", forHTTPHeaderField: "Referer")
        let (data, response) = try await URLSession.shared.data(for: request)
        try HTTP.validate(response: response, data: data)
        return data
    }

    private func fetchCurrentCoreUsage(owner: String) async throws -> CoreUsageSnapshot {
        let data = try await request(path: "user/github/orgs/\(owner)/metrics/core-usage/current")
        let response = try JSONDecoder().decode(CoreUsageCurrentResponse.self, from: data)
        return CoreUsageSnapshot(usage: response.currentUsage)
    }

    private func fetchCoreUsageTimeseries(owner: String) async throws -> [CoreUsageSnapshot] {
        let end = Date()
        let start = end.addingTimeInterval(-24 * 60 * 60)
        var components = URLComponents(url: baseURL.appending(path: "user/github/orgs/\(owner)/metrics/core-usage/timeseries"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "window_size", value: "15"),
            URLQueryItem(name: "start_date", value: Self.isoString(from: start)),
            URLQueryItem(name: "end_date", value: Self.isoString(from: end))
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        let response = try JSONDecoder().decode(CoreUsageTimeseriesResponse.self, from: try await request(url: url))
        return response.timeseries.map { CoreUsageSnapshot(usage: $0.usage) }
    }

    private static func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

private struct CoreUsageSnapshot {
    var amd64: CoreUsage
    var arm64: CoreUsage
    var macos: CoreUsage

    init(usage: CoreUsageResponse) {
        amd64 = usage.amd64
        arm64 = usage.arm64
        macos = usage.macos
    }

    var total: CoreUsage {
        CoreUsage(
            vcpus: amd64.vcpus + arm64.vcpus + macos.vcpus,
            jobs: amd64.jobs + arm64.jobs + macos.jobs
        )
    }

    var platformUsage: [String: CoreUsage] {
        [
            "amd64": amd64,
            "arm64": arm64,
            "macos": macos
        ]
    }
}

private struct CoreUsageCurrentResponse: Decodable {
    var currentUsage: CoreUsageResponse

    enum CodingKeys: String, CodingKey {
        case currentUsage = "current_usage"
    }
}

private struct CoreUsageTimeseriesResponse: Decodable {
    var timeseries: [CoreUsageTimeseriesPoint]
}

private struct CoreUsageTimeseriesPoint: Decodable {
    var usage: CoreUsageResponse
}

private struct CoreUsageResponse: Decodable {
    var amd64: CoreUsage
    var arm64: CoreUsage
    var macos: CoreUsage
}

struct BlacksmithUser: Decodable {
    var id: Int?
    var name: String?
    var email: String?
    var username: String?
}

private struct BlacksmithJobRun: Decodable {
    var id: Int64
    var name: String
    var status: String
    var workflowName: String
    var repositoryName: String
    var githubURL: String
    var runnerType: String?

    var vcpu: Int {
        RunnerLabel.vcpu(from: runnerType ?? "")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case workflowName = "workflow_name"
        case repositoryName = "repository_name"
        case githubURL = "github_url"
        case runnerType = "runner_type"
    }
}

enum RunnerLabel {
    static func vcpu(from label: String) -> Int {
        let lower = label.lowercased()
        guard let range = lower.range(of: #"(\d+)vcpu"#, options: .regularExpression) else {
            return lower.contains("blacksmith") ? 2 : 0
        }
        let digits = lower[range].prefix { $0.isNumber }
        return Int(digits) ?? 0
    }
}

private extension String {
    var normalizedRunStatus: String {
        lowercased().replacingOccurrences(of: "-", with: "_")
    }
}
