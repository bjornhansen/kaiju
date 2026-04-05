import Foundation
import UserNotifications
import os

/// Notification preferences per event type
struct NotificationPreferences: Codable, Sendable {
    var assignedToMe: Bool = true
    var mentionedInComment: Bool = true
    var commentOnWatched: Bool = true
    var statusChanged: Bool = true
}

/// Decides what events warrant notifications and triggers them
actor NotificationEngine {
    private let store: LocalStoreProtocol
    private let bridge: MacNotificationBridge
    private let logger = KaijuLogger.notification

    /// Current user's account ID (for determining "assigned to me", "mentioned", etc.)
    var currentUserAccountId: String?

    /// User notification preferences
    var preferences: NotificationPreferences = NotificationPreferences()

    init(store: LocalStoreProtocol, bridge: MacNotificationBridge = MacNotificationBridge()) {
        self.store = store
        self.bridge = bridge
    }

    /// Process a webhook event and determine if a notification should be shown
    func processWebhookEvent(_ event: WebhookEvent) async {
        guard let issueKey = event.issueKey ?? event.issue?.key else { return }

        let eventType = determineNotificationType(event)
        guard let eventType = eventType else { return }
        guard shouldNotify(eventType: eventType) else { return }

        let issueSummary = event.issue?.fields?.summary ?? issueKey
        let actorName = event.user?.displayName ?? "Someone"

        let detail = buildNotificationDetail(
            eventType: eventType,
            actorName: actorName,
            event: event
        )

        // Save to in-app inbox
        let notification = NotificationRecord(
            id: nil,
            eventType: eventType,
            issueKey: issueKey,
            issueSummary: issueSummary,
            actorDisplayName: actorName,
            actorAvatarUrl: event.user?.avatarUrls?["24x24"],
            detail: detail,
            isRead: false,
            createdAt: DateFormatters.nowISO8601()
        )

        do {
            try await store.saveNotification(notification)
        } catch {
            logger.error("Failed to save notification: \(error.localizedDescription)")
        }

        // Send macOS native notification
        await bridge.sendNotification(
            title: "\(actorName) - \(issueKey)",
            body: detail,
            identifier: "kaiju-\(issueKey)-\(Date().timeIntervalSince1970)"
        )
    }

    private func determineNotificationType(_ event: WebhookEvent) -> String? {
        guard let currentUser = currentUserAccountId else { return nil }

        let eventTypeStr = event.webhookEvent

        // Check if assigned to current user
        if eventTypeStr.contains("updated"),
           event.issue?.fields?.assignee?.accountId == currentUser,
           event.user?.accountId != currentUser {
            return "assigned"
        }

        // Check for comment events (could be mention)
        if eventTypeStr.contains("comment_created"),
           event.user?.accountId != currentUser {
            return "commented"
        }

        // Status change on issues assigned to me
        if eventTypeStr.contains("updated"),
           event.user?.accountId != currentUser {
            return "status_changed"
        }

        return nil
    }

    private func shouldNotify(eventType: String) -> Bool {
        switch eventType {
        case "assigned": return preferences.assignedToMe
        case "mentioned": return preferences.mentionedInComment
        case "commented": return preferences.commentOnWatched
        case "status_changed": return preferences.statusChanged
        default: return false
        }
    }

    private func buildNotificationDetail(
        eventType: String,
        actorName: String,
        event: WebhookEvent
    ) -> String {
        switch eventType {
        case "assigned":
            return "\(actorName) assigned this issue to you"
        case "mentioned":
            return "\(actorName) mentioned you in a comment"
        case "commented":
            return "\(actorName) added a comment"
        case "status_changed":
            let newStatus = event.issue?.fields?.status?.name ?? "unknown"
            return "\(actorName) changed status to \(newStatus)"
        default:
            return "\(actorName) updated this issue"
        }
    }
}
