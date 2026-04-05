import SwiftUI

/// Displays a status badge with color based on status category
struct StatusBadge: View {
    let name: String
    let category: String?

    var body: some View {
        Text(name.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch category?.lowercased() {
        case "done": return Color.green.opacity(0.15)
        case "in progress", "indeterminate": return Color.blue.opacity(0.15)
        default: return Color(.controlBackgroundColor)  // "To Do" / "new"
        }
    }

    private var textColor: Color {
        switch category?.lowercased() {
        case "done": return .green
        case "in progress", "indeterminate": return .blue
        default: return .secondary
        }
    }
}
