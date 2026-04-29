import Foundation

// Represents a Jira issue from the REST API
struct APIIssue: Codable, Sendable {
    let id: String
    let key: String
    let fields: APIIssueFields
}

struct APIIssueFields: Codable, Sendable {
    let summary: String
    let description: ADFDocument?
    let status: APIStatus?
    let priority: APIPriority?
    let issuetype: APIIssueType?
    let assignee: APIUser?
    let reporter: APIUser?
    let labels: [String]?
    let comment: APICommentPage?
    let attachment: [APIAttachment]?
    let issuelinks: [APIIssueLink]?
    let subtasks: [APIIssueSummary]?
    let created: String?
    let updated: String?
    let duedate: String?
    let fixVersions: [APIVersion]?
    let components: [APIComponent]?
    let customfield_10016: Double?  // Story points (typical)
    let sprint: APISprint?
}

struct APIIssueSummary: Codable, Sendable {
    let id: String
    let key: String
    let fields: APIIssueSummaryFields
}

struct APIIssueSummaryFields: Codable, Sendable {
    let summary: String
    let status: APIStatus?
    let priority: APIPriority?
    let issuetype: APIIssueType?
}

struct APIIssueLink: Codable, Sendable {
    let id: String
    let type: APIIssueLinkType
    let inwardIssue: APIIssueSummary?
    let outwardIssue: APIIssueSummary?
}

struct APIIssueLinkType: Codable, Sendable {
    let id: String
    let name: String
    let inward: String
    let outward: String
}

struct APIVersion: Codable, Sendable {
    let id: String
    let name: String
    let released: Bool?
    let releaseDate: String?
}

struct APIComponent: Codable, Sendable {
    let id: String
    let name: String
}

struct APISearchResult: Codable, Sendable {
    let startAt: Int
    let maxResults: Int
    let total: Int
    let issues: [APIIssue]
}
