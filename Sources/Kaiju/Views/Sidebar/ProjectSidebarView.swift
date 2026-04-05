import SwiftUI

/// Sidebar showing projects and navigation
struct ProjectSidebarView: View {
    @Bindable var viewModel: ProjectListViewModel
    @Bindable var notificationViewModel: NotificationInboxViewModel
    @State private var searchText = ""
    @State private var showNotificationInbox = false

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter projects", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            List(selection: $viewModel.selectedProjectKey) {
                // Notification inbox
                Section {
                    Button(action: { showNotificationInbox.toggle() }) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.secondary)
                            Text("Notifications")
                            Spacer()
                            if notificationViewModel.unreadCount > 0 {
                                Text("\(notificationViewModel.unreadCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Projects
                Section("Projects") {
                    if viewModel.isLoading && viewModel.projects.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(viewModel.filteredProjects(searchText: searchText), id: \.key) { project in
                            ProjectRow(project: project)
                                .tag(project.key)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 220)
        .sheet(isPresented: $showNotificationInbox) {
            NotificationInboxView(viewModel: notificationViewModel)
        }
        .task {
            await viewModel.loadProjects()
            await notificationViewModel.refreshUnreadCount()
        }
    }
}

struct ProjectRow: View {
    let project: ProjectRecord

    var body: some View {
        HStack(spacing: 8) {
            // Project avatar
            if let avatarUrl = project.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.2))
                }
                .frame(width: 24, height: 24)
                .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text(String(project.key.prefix(2)))
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body)
                    .lineLimit(1)
                Text(project.key)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
