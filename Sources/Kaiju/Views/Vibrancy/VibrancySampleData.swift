import SwiftUI

/// Hard-coded sample data for the Vibrancy skeleton. Step 2 of the implementation
/// order will port the full `KAIJU_*` set from `source/data.jsx`; for now we keep
/// just enough to fill one column of static cards.
enum VibrancySampleData {
    static let labels: [String: VibrancyLabel] = [
        "bug":      .init(key: "bug",      name: "bug",      color: Color(hex: 0xE11D48)),
        "feature":  .init(key: "feature",  name: "feature",  color: Color(hex: 0x2563EB)),
        "perf":     .init(key: "perf",     name: "performance", color: Color(hex: 0xEA580C)),
    ]

    static let users: [VibrancyUser] = [
        .init(id: "u1", name: "Maya Chen",     initials: "MC", color: Color(hex: 0xF472B6)),
        .init(id: "u3", name: "Sasha Reyes",   initials: "SR", color: Color(hex: 0x34D399)),
        .init(id: "u6", name: "Theo Lindgren", initials: "TL", color: Color(hex: 0xFB7185)),
    ]

    /// One column's worth of cards — the "In Progress" column.
    static let inProgressIssues: [VibrancyIssue] = [
        VibrancyIssue(
            id: "WEB-256",
            title: "Command palette: fuzzy match by alias",
            status: .doing,
            priority: .high,
            assigneeID: "u1",
            labels: [labels["feature"]!],
            estimate: 5,
            comments: 8
        ),
        VibrancyIssue(
            id: "WEB-253",
            title: "Sticky table headers regress on Safari 17.4",
            status: .doing,
            priority: .urgent,
            assigneeID: "u6",
            labels: [labels["bug"]!],
            estimate: 3,
            comments: 12
        ),
        VibrancyIssue(
            id: "WEB-249",
            title: "Reduce Time-to-Interactive on org switcher",
            status: .doing,
            priority: .high,
            assigneeID: "u3",
            labels: [labels["perf"]!],
            estimate: 5,
            comments: 4
        ),
    ]

    static func user(id: VibrancyUser.ID?) -> VibrancyUser? {
        guard let id else { return nil }
        return users.first { $0.id == id }
    }
}

/// Sidebar nav identifiers — single source of truth for selection.
enum VibrancyNavItem: String, Hashable, CaseIterable {
    case inbox, assigned, created, subscribed
    case board, list, sprints, roadmap, projects
}

struct VibrancySidebarItem: Identifiable, Hashable {
    var id: VibrancyNavItem { item }
    let item: VibrancyNavItem
    let label: String
    let symbol: String
    var count: Int? = nil
}

enum VibrancySidebarData {
    static let myWork: [VibrancySidebarItem] = [
        .init(item: .inbox,      label: "Inbox",      symbol: "tray",                   count: 4),
        .init(item: .assigned,   label: "Assigned",   symbol: "person.crop.circle",     count: 7),
        .init(item: .created,    label: "Created",    symbol: "square.and.pencil",      count: 12),
        .init(item: .subscribed, label: "Subscribed", symbol: "bell",                   count: 3),
    ]

    static let workspace: [VibrancySidebarItem] = [
        .init(item: .board,    label: "Board",      symbol: "square.grid.2x2"),
        .init(item: .list,     label: "All issues", symbol: "list.bullet"),
        .init(item: .sprints,  label: "Sprints",    symbol: "timer"),
        .init(item: .roadmap,  label: "Roadmap",    symbol: "map"),
        .init(item: .projects, label: "Projects",   symbol: "folder"),
    ]

    struct SavedFilter: Identifiable, Hashable {
        var id: String { label }
        let label: String
        let color: Color
    }

    static let filters: [SavedFilter] = [
        .init(label: "My open bugs",     color: Color(hex: 0xE11D48)),
        .init(label: "Needs review",     color: Color(hex: 0xA855F7)),
        .init(label: "High priority",    color: Color(hex: 0xEA580C)),
        .init(label: "Without estimate", color: Color(hex: 0x64748B)),
    ]
}
