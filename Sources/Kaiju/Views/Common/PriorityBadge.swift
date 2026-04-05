import SwiftUI

/// Displays a priority indicator
struct PriorityBadge: View {
    let priorityName: String

    var body: some View {
        Image(systemName: iconName)
            .font(.caption2)
            .foregroundStyle(color)
            .help(priorityName)
    }

    private var iconName: String {
        switch priorityName.lowercased() {
        case "highest": return "chevron.up.2"
        case "high": return "chevron.up"
        case "medium": return "equal"
        case "low": return "chevron.down"
        case "lowest": return "chevron.down.2"
        default: return "minus"
        }
    }

    private var color: Color {
        switch priorityName.lowercased() {
        case "highest": return .red
        case "high": return .orange
        case "medium": return .yellow
        case "low": return .blue
        case "lowest": return .gray
        default: return .secondary
        }
    }
}
