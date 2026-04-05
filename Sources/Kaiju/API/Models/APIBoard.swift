import Foundation

struct APIBoard: Codable, Sendable {
    let id: Int
    let name: String
    let type: String
    let location: APIBoardLocation?
}

struct APIBoardLocation: Codable, Sendable {
    let projectId: Int?
    let projectKey: String?
    let projectName: String?
}

struct APIBoardList: Codable, Sendable {
    let maxResults: Int
    let startAt: Int
    let total: Int
    let isLast: Bool?
    let values: [APIBoard]
}

struct APIBoardConfiguration: Codable, Sendable {
    let id: Int
    let name: String
    let columnConfig: APIColumnConfig
    let filter: APIBoardFilter?
}

struct APIColumnConfig: Codable, Sendable {
    let columns: [APIColumn]
}

struct APIColumn: Codable, Sendable {
    let name: String
    let statuses: [APIColumnStatus]
}

struct APIColumnStatus: Codable, Sendable {
    let id: String
}

struct APIBoardFilter: Codable, Sendable {
    let id: String
    let name: String?
}

struct APIBoardIssueList: Codable, Sendable {
    let maxResults: Int
    let startAt: Int
    let total: Int
    let issues: [APIIssue]
}
