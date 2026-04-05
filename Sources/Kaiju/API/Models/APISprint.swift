import Foundation

struct APISprint: Codable, Sendable {
    let id: Int
    let state: String?  // "active", "closed", "future"
    let name: String?
    let startDate: String?
    let endDate: String?
    let completeDate: String?
    let goal: String?
    let boardId: Int?
}

struct APISprintList: Codable, Sendable {
    let maxResults: Int
    let startAt: Int
    let isLast: Bool?
    let values: [APISprint]
}
