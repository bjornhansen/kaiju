import SwiftUI

/// In-app notification inbox
struct NotificationInboxView: View {
    @Bindable var viewModel: NotificationInboxViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.unreadCount > 0 {
                    Button("Mark All Read") {
                        Task { await viewModel.markAllAsRead() }
                    }
                }

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Notification list
            if viewModel.notifications.isEmpty {
                VStack {
                    Spacer()
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You're all caught up!")
                    )
                    Spacer()
                }
            } else {
                List(viewModel.notifications, id: \.id) { notification in
                    NotificationRow(notification: notification)
                        .onTapGesture {
                            Task { await viewModel.markAsRead(notification) }
                        }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 400, minHeight: 300, idealHeight: 500)
        .task {
            await viewModel.loadNotifications()
        }
    }
}

struct NotificationRow: View {
    let notification: NotificationRecord

    var body: some View {
        HStack(spacing: 10) {
            // Unread indicator
            Circle()
                .fill(notification.isRead ? Color.clear : Color.accentColor)
                .frame(width: 8, height: 8)

            // Event type icon
            Image(systemName: iconForEventType(notification.eventType))
                .foregroundStyle(colorForEventType(notification.eventType))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(notification.issueKey)
                        .fontWeight(.medium)
                    if let summary = notification.issueSummary {
                        Text(summary)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .font(.callout)

                if let detail = notification.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let date = DateFormatters.parseJiraDate(notification.createdAt) {
                    Text(DateFormatters.relativeString(from: date))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(notification.isRead ? 0.7 : 1.0)
    }

    private func iconForEventType(_ type: String) -> String {
        switch type {
        case "assigned": return "person.badge.plus"
        case "mentioned": return "at"
        case "commented": return "text.bubble"
        case "status_changed": return "arrow.right.circle"
        default: return "bell"
        }
    }

    private func colorForEventType(_ type: String) -> Color {
        switch type {
        case "assigned": return .blue
        case "mentioned": return .orange
        case "commented": return .green
        case "status_changed": return .purple
        default: return .secondary
        }
    }
}
