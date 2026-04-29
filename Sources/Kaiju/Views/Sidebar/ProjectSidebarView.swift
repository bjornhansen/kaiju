import SwiftUI

/// Sidebar showing the current workspace, notifications, and the project list.
/// Styled to match the Translucent Vibrancy variation: floating inset, accent
/// pill on the active row, user pill at the bottom.
struct ProjectSidebarView: View {
    @Bindable var viewModel: ProjectListViewModel
    @Bindable var notificationViewModel: NotificationInboxViewModel
    let siteName: String
    let onSignOut: () -> Void

    @State private var searchText = ""
    @State private var showNotificationInbox = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            workspaceHeader
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 10)

            searchField
                .padding(.horizontal, 10)
                .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionHeader("Workspace")
                    notificationsRow

                    sectionHeader("Projects")
                    projectsList
                }
            }
            .scrollContentBackground(.hidden)

            Spacer(minLength: 0)

            userPill
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay(alignment: .top) { Divider().opacity(0.6) }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showNotificationInbox) {
            NotificationInboxView(viewModel: notificationViewModel)
        }
        .task {
            await viewModel.loadProjects()
            await notificationViewModel.refreshUnreadCount()
        }
    }

    // MARK: - Workspace header

    private var workspaceHeader: some View {
        HStack(spacing: 8) {
            workspaceSquircle
            VStack(alignment: .leading, spacing: 0) {
                Text(siteName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var workspaceSquircle: some View {
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
                Text(siteName.prefix(1).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            )
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("Filter projects", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Sections

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    private var notificationsRow: some View {
        sidebarRow(
            symbol: "bell",
            label: "Notifications",
            isActive: false,
            badge: notificationViewModel.unreadCount > 0
                ? "\(notificationViewModel.unreadCount)"
                : nil,
            badgeStyle: .alert,
            action: { showNotificationInbox.toggle() }
        )
    }

    private var projectsList: some View {
        Group {
            if viewModel.isLoading && viewModel.projects.isEmpty {
                ProgressView()
                    .controlSize(.small)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            } else {
                let projects = viewModel.filteredProjects(searchText: searchText)
                ForEach(projects, id: \.key) { project in
                    ProjectSidebarRow(
                        project: project,
                        isActive: viewModel.selectedProjectKey == project.key,
                        onTap: { viewModel.selectedProjectKey = project.key }
                    )
                }
                if projects.isEmpty && !searchText.isEmpty {
                    Text("No matches")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Generic row builder

    private enum BadgeStyle { case neutral, alert }

    @ViewBuilder
    private func sidebarRow(
        symbol: String,
        label: String,
        isActive: Bool,
        badge: String?,
        badgeStyle: BadgeStyle = .neutral,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .regular))
                    .frame(width: 16)
                    .foregroundStyle(isActive ? VibrancyTokens.accent : Color.secondary)
                Text(label)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? VibrancyTokens.accent : Color.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let badge {
                    badgeView(badge, style: badgeStyle)
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

    @ViewBuilder
    private func badgeView(_ text: String, style: BadgeStyle) -> some View {
        switch style {
        case .neutral:
            Text(text)
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        case .alert:
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Capsule().fill(.red))
        }
    }

    // MARK: - User pill

    private var userPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(VibrancyTokens.accent.opacity(0.2))
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(VibrancyTokens.accent)
                )
            VStack(alignment: .leading, spacing: 0) {
                Text(siteName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text("Online")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Menu {
                Button("Sign Out", action: onSignOut)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }
}

// MARK: - Project row

struct ProjectSidebarRow: View {
    let project: ProjectRecord
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                avatar
                Text(project.name)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? VibrancyTokens.accent : Color.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
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

    @ViewBuilder
    private var avatar: some View {
        if let urlString = project.avatarUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable()
            } placeholder: {
                placeholderAvatar
            }
            .frame(width: 16, height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            placeholderAvatar
        }
    }

    private var placeholderAvatar: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(VibrancyTokens.accent.opacity(0.2))
            .frame(width: 16, height: 16)
            .overlay(
                Text(project.key.prefix(1).uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(VibrancyTokens.accent)
            )
    }
}
