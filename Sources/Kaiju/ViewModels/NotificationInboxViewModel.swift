import Foundation
import os

/// ViewModel for the notification inbox
@Observable
@MainActor
final class NotificationInboxViewModel {
    private(set) var notifications: [NotificationRecord] = []
    private(set) var unreadCount: Int = 0
    private(set) var isLoading = false

    private let inboxStore: NotificationInboxStore
    private let logger = KaijuLogger.notification

    init(inboxStore: NotificationInboxStore) {
        self.inboxStore = inboxStore
    }

    /// Load all notifications
    func loadNotifications() async {
        isLoading = true

        do {
            notifications = try await inboxStore.allNotifications(limit: 100)
            unreadCount = try await inboxStore.unreadCount()
        } catch {
            logger.error("Failed to load notifications: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Mark a single notification as read
    func markAsRead(_ notification: NotificationRecord) async {
        guard let id = notification.id else { return }
        do {
            try await inboxStore.markRead(id: id)
            await loadNotifications()
        } catch {
            logger.error("Failed to mark notification read: \(error.localizedDescription)")
        }
    }

    /// Mark all notifications as read
    func markAllAsRead() async {
        do {
            try await inboxStore.markAllRead()
            await loadNotifications()
        } catch {
            logger.error("Failed to mark all read: \(error.localizedDescription)")
        }
    }

    /// Refresh unread count (called from other views to update badge)
    func refreshUnreadCount() async {
        do {
            unreadCount = try await inboxStore.unreadCount()
        } catch {
            logger.error("Failed to refresh unread count: \(error.localizedDescription)")
        }
    }
}
