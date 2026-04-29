import SwiftUI

/// Translucent issue card — Vibrancy 3-row layout adapted to the live data:
///   1) priority chevron + key + assignee avatar
///   2) summary (12.5px / 500)
///   3) labels • due date • comments
struct IssueCardView: View {
    let issue: IssueRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            metaRow
            titleRow
            bottomRow
        }
        .padding(.horizontal, VibrancyTokens.Spacing.cardPaddingX)
        .padding(.vertical, VibrancyTokens.Spacing.cardPaddingY)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: VibrancyTokens.Radius.card, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VibrancyTokens.Radius.card, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        .contentShape(Rectangle())
    }

    // MARK: - Rows

    private var metaRow: some View {
        HStack(spacing: 6) {
            if let priorityName = issue.priorityName {
                PriorityBadge(priorityName: priorityName)
            }
            Text(issue.key)
                .font(.system(size: 10.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            AvatarView(
                url: issue.assigneeAvatarUrl,
                displayName: issue.assigneeDisplayName,
                size: 16
            )
        }
    }

    private var titleRow: some View {
        Text(issue.summary)
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var bottomRow: some View {
        HStack(spacing: 5) {
            ForEach(decodedLabels.prefix(2), id: \.self) { label in
                labelChip(label)
            }
            if let due = formattedDueDate {
                dueDatePill(due)
            }
            Spacer(minLength: 0)
            // Comment count is not on IssueRecord (comments live in their own
            // table). Surface it later by joining; omitted for now.
        }
    }

    // MARK: - Labels

    private var decodedLabels: [String] {
        guard let labelsJSON = issue.labels,
              let labels = try? JSONDecoder().decode([String].self, from: Data(labelsJSON.utf8))
        else { return [] }
        return labels
    }

    private func labelChip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(VibrancyTokens.accent)
            .padding(.horizontal, 6)
            .padding(.vertical, 1.5)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(VibrancyTokens.accent.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(VibrancyTokens.accent.opacity(0.25), lineWidth: 0.5)
            )
    }

    // MARK: - Due date

    /// Due date as "MMM d" (e.g. "Apr 28"). Renders red if overdue.
    private var formattedDueDate: (text: String, isOverdue: Bool)? {
        guard let raw = issue.dueDate, !raw.isEmpty else { return nil }
        let date = Self.dueDateInputFormatter.date(from: raw)
            ?? DateFormatters.parseJiraDate(raw)
        guard let date else { return nil }
        let text = Self.dueDateDisplayFormatter.string(from: date)
        let isOverdue = date < Calendar.current.startOfDay(for: Date())
        return (text, isOverdue)
    }

    private func dueDatePill(_ due: (text: String, isOverdue: Bool)) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "calendar")
                .font(.system(size: 9, weight: .medium))
            Text(due.text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(due.isOverdue ? Color.red : Color.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 1.5)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(due.isOverdue ? Color.red.opacity(0.12) : Color.primary.opacity(0.05))
        )
    }

    // Jira's `duedate` field is a "yyyy-MM-dd" date string (no time component).
    private static let dueDateInputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let dueDateDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}

/// Issue type icon based on type name. Used by `IssueDetailView`.
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
