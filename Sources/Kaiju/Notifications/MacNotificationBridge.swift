import Foundation
import UserNotifications
import os

/// Bridge to macOS native notification center (UNUserNotificationCenter)
final class MacNotificationBridge: Sendable {
    private let logger = KaijuLogger.notification

    /// Request notification permissions
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification permission: \(granted)")
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }

    /// Send a native macOS notification
    func sendNotification(title: String, body: String, identifier: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            logger.error("Failed to deliver notification: \(error.localizedDescription)")
        }
    }

    /// Remove all delivered notifications
    func clearAll() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
