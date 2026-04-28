import SwiftUI

/// Main pane for the Vibrancy variation: title-row toolbar + horizontally
/// scrolling columns of cards. The skeleton renders one fully-styled column
/// ("In Progress") with the others as empty placeholders so the column rhythm
/// is visible.
struct VibrancyBoardView: View {
    @State private var filterText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            toolbar
                .padding(.horizontal, 6)
                .padding(.bottom, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: VibrancyTokens.Spacing.columnGap) {
                    ForEach(VibrancyStatus.allCases) { status in
                        VibrancyColumnView(
                            status: status,
                            issues: issues(for: status)
                        )
                        .frame(minWidth: 260, idealWidth: 300, maxWidth: .infinity, alignment: .top)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
        }
        .padding(VibrancyTokens.Spacing.windowPadding)
    }

    private func issues(for status: VibrancyStatus) -> [VibrancyIssue] {
        guard status == .doing else { return [] }
        guard !filterText.isEmpty else { return VibrancySampleData.inProgressIssues }
        let needle = filterText.lowercased()
        return VibrancySampleData.inProgressIssues.filter {
            $0.title.lowercased().contains(needle) || $0.id.lowercased().contains(needle)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("Board")
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.3)
                Text("· Web Platform")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                sprintPill
            }

            Spacer(minLength: 8)

            filterField

            toolbarPill {
                HStack(spacing: 3) {
                    Image(systemName: "command")
                        .font(.system(size: 10, weight: .medium))
                    Text("K").font(.system(size: 11, weight: .medium))
                }
            }

            toolbarPill {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 12, weight: .medium))
            }

            avatarStack

            newButton
        }
    }

    private var sprintPill: some View {
        Text("Sprint 24")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 1)
            .background(
                Capsule().fill(Color.primary.opacity(0.06))
            )
    }

    private var filterField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("Filter issues…", text: $filterText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .frame(minWidth: 200)
        .background(
            RoundedRectangle(cornerRadius: VibrancyTokens.Radius.pill, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VibrancyTokens.Radius.pill, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func toolbarPill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: VibrancyTokens.Radius.pill, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VibrancyTokens.Radius.pill, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
    }

    private var avatarStack: some View {
        HStack(spacing: -6) {
            ForEach(VibrancySampleData.users.prefix(4)) { user in
                VibrancyAvatar(user: user, size: 22)
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 1.5)
                    )
            }
        }
    }

    private var newButton: some View {
        Button {
            // Out of scope for skeleton.
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("New")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: VibrancyTokens.Radius.pill, style: .continuous)
                    .fill(VibrancyTokens.accent)
            )
            .shadow(color: VibrancyTokens.accent.opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Column

/// Single board column. The skeleton uses static issue arrays — drag/drop
/// + status mutation come in step 5 of the implementation order.
struct VibrancyColumnView: View {
    let status: VibrancyStatus
    let issues: [VibrancyIssue]

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
    }

    private var header: some View {
        HStack(spacing: 8) {
            VibrancyStatusDonut(status: status, size: 12)
            Text(status.name)
                .font(.system(size: 12, weight: .semibold))
            countBadge
            Spacer(minLength: 0)
            Button {
                // Add card — out of scope for skeleton.
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var countBadge: some View {
        Text("\(issues.count)")
            .font(.system(size: 10, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .frame(height: 17)
            .background(
                Capsule().fill(Color.primary.opacity(0.06))
            )
    }

    private var cards: some View {
        VStack(spacing: VibrancyTokens.Spacing.cardGap) {
            ForEach(issues) { issue in
                VibrancyCardView(issue: issue)
            }
            if issues.isEmpty {
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
