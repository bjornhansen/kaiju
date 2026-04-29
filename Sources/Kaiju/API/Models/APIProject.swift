import Foundation

struct APIProject: Codable, Sendable {
    let id: String
    let key: String
    let name: String
    let avatarUrls: [String: String]?
    let projectTypeKey: String?
    let style: String?
    let issueTypes: [APIIssueType]?
    let archived: Bool?
}
