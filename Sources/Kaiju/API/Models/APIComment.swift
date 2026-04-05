import Foundation

struct APIComment: Codable, Sendable {
    let id: String
    let author: APIUser?
    let body: ADFDocument?
    let created: String?
    let updated: String?
}

struct APICommentPage: Codable, Sendable {
    let startAt: Int?
    let maxResults: Int?
    let total: Int?
    let comments: [APIComment]
}
