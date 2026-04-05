import Foundation

/// Provides notification inbox data to ViewModels via the LocalStore
/// This is a thin convenience layer that wraps LocalStore notification methods
struct NotificationInboxStore: Sendable {
    private let store: LocalStoreProtocol

    init(store: LocalStoreProtocol) {
        self.store = store
    }

    func allNotifications(limit: Int = 100) async throws -> [NotificationRecord] {
        try await store.allNotifications(limit: limit)
    }

    func unreadNotifications() async throws -> [NotificationRecord] {
        try await store.unreadNotifications()
    }

    func unreadCount() async throws -> Int {
        try await store.unreadNotificationCount()
    }

    func markRead(id: Int64) async throws {
        try await store.markNotificationRead(id: id)
    }

    func markAllRead() async throws {
        try await store.markAllNotificationsRead()
    }
}
