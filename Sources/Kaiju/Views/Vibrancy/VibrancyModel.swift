import SwiftUI

/// Minimal model types for the Vibrancy variation. Mirrors the JS shapes in
/// `docs/design_handoff_kaiju_vibrancy/source/data.jsx`. These are intentionally
/// distinct from the live `IssueRecord` model so the design preview can iterate
/// independently of sync/store concerns.
enum VibrancyStatus: String, CaseIterable, Hashable, Identifiable {
    case backlog, todo, doing, review, done
    var id: String { rawValue }

    var name: String {
        switch self {
        case .backlog: return "Backlog"
        case .todo:    return "To Do"
        case .doing:   return "In Progress"
        case .review:  return "In Review"
        case .done:    return "Done"
        }
    }

    var color: Color {
        switch self {
        case .backlog: return VibrancyTokens.Status.backlog
        case .todo:    return VibrancyTokens.Status.todo
        case .doing:   return VibrancyTokens.Status.inProgress
        case .review:  return VibrancyTokens.Status.inReview
        case .done:    return VibrancyTokens.Status.done
        }
    }
}

enum VibrancyPriority: String, CaseIterable, Hashable {
    case urgent, high, med, low, none

    var name: String {
        switch self {
        case .urgent: return "Urgent"
        case .high:   return "High"
        case .med:    return "Medium"
        case .low:    return "Low"
        case .none:   return "None"
        }
    }

    var color: Color {
        switch self {
        case .urgent: return VibrancyTokens.Priority.urgent
        case .high:   return VibrancyTokens.Priority.high
        case .med:    return VibrancyTokens.Priority.medium
        case .low:    return VibrancyTokens.Priority.low
        case .none:   return VibrancyTokens.Priority.none
        }
    }

}

struct VibrancyUser: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let color: Color
}

struct VibrancyLabel: Identifiable, Hashable {
    var id: String { key }
    let key: String
    let name: String
    let color: Color
}

struct VibrancyIssue: Identifiable, Hashable {
    let id: String                 // e.g. "WEB-256"
    var title: String
    var status: VibrancyStatus
    var priority: VibrancyPriority
    var assigneeID: VibrancyUser.ID?
    var labels: [VibrancyLabel]
    var estimate: Int
    var comments: Int
}
