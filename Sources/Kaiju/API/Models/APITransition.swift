import Foundation

struct APITransition: Codable, Sendable {
    let id: String
    let name: String
    let to: APIStatus
    let hasScreen: Bool?
    let isGlobal: Bool?
    let isInitial: Bool?
    let isAvailable: Bool?
    let isConditional: Bool?
}

struct APITransitionList: Codable, Sendable {
    let transitions: [APITransition]
}
