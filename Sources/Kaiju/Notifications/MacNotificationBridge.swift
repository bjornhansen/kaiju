import Foundation
import UserNotifications
import os

/// Bridge to macOS native notification center (UNUserNotificationCenter).
/// Gracefully no-ops when running without a proper app bundle (SPM executables).
final class MacNotificationBridge: Sendable {
    private let logger = KaijuLogger.notification

    /// Whether we're running in a proper app bundle that supports notifications
    private var hasBundle: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    /// Request notification permissions
    func requestPermission() async -> Bool {
        guard hasBundle else {
            logger.info("Skipping notification permissions — no app bundle")
            return false
        }
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
        guard hasBundle else { return }

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
        guard hasBundle else { return }
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
