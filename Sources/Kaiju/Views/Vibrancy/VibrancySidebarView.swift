import SwiftUI

/// Floating inset sidebar for the Vibrancy variation. The sidebar's
/// translucent material comes from `NavigationSplitView` on macOS 14+.
struct VibrancySidebarView: View {
    @Binding var selectedNav: VibrancyNavItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            workspaceSwitcher
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 12)

            sectionHeader("My Work")
            ForEach(VibrancySidebarData.myWork) { item in
                VibrancySidebarRow(
                    item: item,
                    isActive: selectedNav == item.item,
                    onTap: { selectedNav = item.item }
                )
            }

            sectionHeader("Workspace")
            ForEach(VibrancySidebarData.workspace) { item in
                VibrancySidebarRow(
                    item: item,
                    isActive: selectedNav == item.item,
                    onTap: { selectedNav = item.item }
                )
            }

            sectionHeader("Filters")
            ForEach(VibrancySidebarData.filters) { filter in
                filterRow(filter)
            }

            Spacer(minLength: 8)

            userPill
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay(alignment: .top) {
                    Divider().opacity(0.6)
                }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Workspace switcher

    private var workspaceSwitcher: some View {
        HStack(spacing: 8) {
            squircle(letter: "A")
            Text("Acme")
                .font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 4)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func squircle(letter: String) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [VibrancyTokens.accent, VibrancyTokens.accent.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 22, height: 22)
            .overlay(
                Text(letter)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: .white.opacity(0.3), radius: 0, x: 0, y: 0.5)
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    // MARK: - Saved filter row

    private func filterRow(_ filter: VibrancySidebarData.SavedFilter) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(filter.color)
                .frame(width: 8, height: 8)
            Text(filter.label)
                .font(.system(size: 12))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
    }

    // MARK: - User pill

    private var userPill: some View {
        HStack(spacing: 8) {
            VibrancyAvatar(user: VibrancySampleData.users[0], size: 22)
            VStack(alignment: .leading, spacing: 0) {
                Text(VibrancySampleData.users[0].name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text("Online")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button {
                // Settings — out of scope for skeleton.
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Sidebar row

struct VibrancySidebarRow: View {
    let item: VibrancySidebarItem
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: item.symbol)
                    .font(.system(size: 14, weight: .regular))
                    .frame(width: 16)
                    .foregroundStyle(isActive ? VibrancyTokens.accent : Color.secondary)
                Text(item.label)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? VibrancyTokens.accent : Color.primary)
                Spacer(minLength: 0)
                if let count = item.count {
                    Text("\(count)")
                        .font(.system(size: 11, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 27)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive ? VibrancyTokens.accent.opacity(0.18) : Color.clear)
            )
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Avatar (vibrancy variant)

struct VibrancyAvatar: View {
    let user: VibrancyUser
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(user.color)
            .frame(width: size, height: size)
            .overlay(
                Text(user.initials)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}
