import SwiftUI

/// A single column in the kanban board
struct BoardColumnView: View {
    let column: BoardColumn
    let onIssueSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column header
            HStack {
                Text(column.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(column.issues.count)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 8)

            // Issue cards
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(column.issues, id: \.key) { issue in
                        IssueCardView(issue: issue)
                            .onTapGesture {
                                onIssueSelected(issue.key)
                            }
                            .draggable(issue.key)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(width: 280)
        .padding(8)
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .dropDestination(for: String.self) { items, _ in
            // Handle drop - items contain issue keys
            return !items.isEmpty
        }
    }
}
