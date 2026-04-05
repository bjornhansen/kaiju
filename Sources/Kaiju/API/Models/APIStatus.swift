import Foundation

struct APIStatus: Codable, Sendable {
    let id: String?
    let name: String
    let statusCategory: APIStatusCategory?
    let iconUrl: String?
}

struct APIStatusCategory: Codable, Sendable {
    let id: Int?
    let key: String?
    let name: String?
    let colorName: String?
}

struct APIPriority: Codable, Sendable {
    let id: String?
    let name: String
    let iconUrl: String?
}

struct APIIssueType: Codable, Sendable {
    let id: String?
    let name: String
    let iconUrl: String?
    let subtask: Bool?
}

struct APIAttachment: Codable, Sendable {
    let id: String
    let filename: String
    let mimeType: String?
    let size: Int?
    let content: String?  // download URL
    let thumbnail: String?
    let author: APIUser?
    let created: String?
}

struct APILabel: Codable, Sendable {
    let label: String
}

struct APILabelList: Codable, Sendable {
    let values: [String]
    let total: Int
}

struct APIAccessibleResource: Codable, Sendable {
    let id: String
    let name: String
    let url: String
    let scopes: [String]?
    let avatarUrl: String?
}

struct APIOAuthTokenResponse: Codable, Sendable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int
    let scope: String?
    let token_type: String?
}
