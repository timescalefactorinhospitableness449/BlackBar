import Foundation

struct DashboardSnapshot {
    var status: BlacksmithStatus
    var usage: BlacksmithUsage
    var refreshedAt: Date?
    var error: String?

    static let empty = DashboardSnapshot(
        status: BlacksmithStatus(pageStatus: "UNKNOWN", incidents: [], maintenances: []),
        usage: BlacksmithUsage(activeVCPU: 0, activeJobs: 0, queuedJobs: 0, runs: []),
        refreshedAt: nil,
        error: nil
    )

    var isOperational: Bool {
        status.isOperational && error == nil
    }

    func with(error: String?) -> DashboardSnapshot {
        DashboardSnapshot(status: status, usage: usage, refreshedAt: refreshedAt, error: error)
    }
}

struct BlacksmithStatus {
    var pageStatus: String
    var incidents: [StatusEvent]
    var maintenances: [StatusEvent]

    var isOperational: Bool {
        pageStatus.uppercased() == "UP" && incidents.isEmpty
    }

    var label: String {
        if isOperational {
            return "All systems operational"
        }
        if let first = incidents.first {
            return first.name
        }
        if let first = maintenances.first {
            return first.name
        }
        return pageStatus
    }
}

struct StatusEvent: Identifiable, Hashable {
    var id: String
    var name: String
    var status: String
}

struct BlacksmithUsage {
    var activeVCPU: Int
    var activeJobs: Int
    var queuedJobs: Int
    var runs: [WorkflowRunUsage]
    var fetchedJobs: Int = 0
    var statusCounts: [String: Int] = [:]
    var runnerTypes: [String] = []
    var historyVCPU: [Int] = []
    var platformUsage: [String: CoreUsage] = [:]

    var debugSummary: String {
        let core = platformUsage
            .sorted { $0.key < $1.key }
            .map { "\($0.key) \($0.value.vcpus)v/\($0.value.jobs)j" }
            .joined(separator: ", ")
        guard fetchedJobs > 0 else { return core.isEmpty ? "no jobs fetched" : "core: \(core)" }
        let statuses = statusCounts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .map { "\($0.key) \($0.value)" }
            .joined(separator: ", ")
        let jobs = statuses.isEmpty ? "\(fetchedJobs) history jobs" : "\(fetchedJobs) history jobs: \(statuses)"
        return core.isEmpty ? jobs : "core: \(core); \(jobs)"
    }
}

struct CoreUsage: Codable, Hashable {
    var vcpus: Int
    var jobs: Int
}

struct WorkflowRunUsage: Identifiable, Hashable {
    var id: Int64
    var repository: String
    var title: String
    var workflowName: String
    var url: String
    var activeVCPU: Int
    var activeJobs: Int
    var queuedJobs: Int
    var jobs: [JobUsage]
}

struct JobUsage: Identifiable, Hashable {
    var id: Int64
    var name: String
    var status: String
    var url: String?
    var vcpu: Int
    var labels: [String]
}
