import Foundation

enum BlacksmithStatusClient {
    static func fetch() async throws -> BlacksmithStatus {
        let url = URL(string: "https://status.blacksmith.sh/summary.json")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try HTTP.validate(response: response, data: data)
        let summary = try JSONDecoder().decode(StatusSummaryResponse.self, from: data)
        return BlacksmithStatus(
            pageStatus: summary.page.status,
            incidents: summary.activeIncidents.map { StatusEvent(id: $0.id, name: $0.name, status: $0.status) },
            maintenances: summary.activeMaintenances.map { StatusEvent(id: $0.id, name: $0.name, status: $0.status) }
        )
    }
}

private struct StatusSummaryResponse: Decodable {
    var page: StatusPage
    var activeIncidents: [StatusEventResponse]
    var activeMaintenances: [StatusEventResponse]

    enum CodingKeys: String, CodingKey {
        case page
        case activeIncidents
        case activeMaintenances
        case active_incidents
        case active_maintenances
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        page = try container.decode(StatusPage.self, forKey: .page)
        activeIncidents = try container.decodeIfPresent([StatusEventResponse].self, forKey: .activeIncidents)
            ?? container.decodeIfPresent([StatusEventResponse].self, forKey: .active_incidents)
            ?? []
        activeMaintenances = try container.decodeIfPresent([StatusEventResponse].self, forKey: .activeMaintenances)
            ?? container.decodeIfPresent([StatusEventResponse].self, forKey: .active_maintenances)
            ?? []
    }
}

private struct StatusPage: Decodable {
    var status: String
}

private struct StatusEventResponse: Decodable {
    var id: String
    var name: String
    var status: String
}
