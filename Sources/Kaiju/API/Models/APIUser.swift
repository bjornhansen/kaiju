import Foundation

struct APIUser: Codable, Sendable {
    let accountId: String
    let displayName: String?
    let avatarUrls: [String: String]?
    let active: Bool?
    let emailAddress: String?
}
