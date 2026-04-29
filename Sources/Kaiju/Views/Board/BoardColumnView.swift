import SwiftUI

/// A single column on the board. Vibrancy styling: subtle tinted fill, hairline
/// border, rounded corners. The status donut is intentionally omitted —
/// boards have varying numbers of columns and a "progress" indicator would be
/// misleading.
struct BoardColumnView: View {
    let column: BoardColumn
    let onIssueSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            cards
        }
        .background(
            RoundedRectangle(cornerRadius: VibrancyTokens.Radius.column, style: .continuous)
                .fill(Color.primary.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: VibrancyTokens.Radius.column, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .dropDestination(for: String.self) { items, _ in
            !items.isEmpty
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(column.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
            countBadge
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var countBadge: some View {
        Text("\(column.issues.count)")
            .font(.system(size: 10, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .frame(height: 17)
            .background(Capsule().fill(Color.primary.opacity(0.06)))
    }

    private var cards: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: VibrancyTokens.Spacing.cardGap) {
                ForEach(column.issues, id: \.key) { issue in
                    IssueCardView(issue: issue)
                        .onTapGesture { onIssueSelected(issue.key) }
                        .draggable(issue.key)
                }
                if column.issues.isEmpty {
                    Text("—")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
}
