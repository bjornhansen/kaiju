import SwiftUI

/// A card representing an issue on the board
struct IssueCardView: View {
    let issue: IssueRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Issue key and type
            HStack {
                // Issue type icon
                IssueTypeIcon(typeName: issue.issueTypeName)

                Text(issue.key)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)

                Spacer()

                // Priority icon
                if let priorityName = issue.priorityName {
                    PriorityBadge(priorityName: priorityName)
                }
            }

            // Summary
            Text(issue.summary)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // Bottom row: labels, assignee
            HStack {
                // Labels
                if let labelsJSON = issue.labels,
                   let labels = try? JSONDecoder().decode([String].self, from: Data(labelsJSON.utf8)),
                   !labels.isEmpty {
                    ForEach(labels.prefix(2), id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                // Story points
                if let points = issue.storyPoints {
                    Text("\(Int(points))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(4)
                }

                // Assignee avatar
                AvatarView(
                    url: issue.assigneeAvatarUrl,
                    displayName: issue.assigneeDisplayName,
                    size: 24
                )
            }
        }
        .padding(10)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        .contentShape(Rectangle())
    }
}

/// Issue type icon based on type name
struct IssueTypeIcon: View {
    let typeName: String?

    var body: some View {
        let (icon, color) = iconAndColor

        Image(systemName: icon)
            .font(.caption2)
            .foregroundStyle(color)
    }

    private var iconAndColor: (String, Color) {
        switch typeName?.lowercased() {
        case "bug": return ("ladybug.fill", .red)
        case "story": return ("bookmark.fill", .green)
        case "epic": return ("bolt.fill", .purple)
        case "sub-task", "subtask": return ("list.bullet.indent", .blue)
        default: return ("checkmark.square.fill", .blue)  // Task
        }
    }
}
