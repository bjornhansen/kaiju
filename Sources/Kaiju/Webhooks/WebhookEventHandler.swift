import Foundation
import os

/// Routes webhook events to the appropriate sync engine actions
actor WebhookEventHandler {
    private let syncEngine: SyncEngine
    private let notificationEngine: NotificationEngine
    private let logger = KaijuLogger.webhook

    init(syncEngine: SyncEngine, notificationEngine: NotificationEngine) {
        self.syncEngine = syncEngine
        self.notificationEngine = notificationEngine
    }

    /// Handle a raw SSE event
    func handleEvent(eventType: String, data: String) async {
        guard let jsonData = data.data(using: .utf8) else {
            logger.error("Failed to parse event data as UTF-8")
            return
        }

        do {
            let event = try JSONDecoder().decode(WebhookEvent.self, from: jsonData)
            await routeEvent(event)
        } catch {
            logger.error("Failed to decode webhook event: \(error.localizedDescription)")
        }
    }

    private func routeEvent(_ event: WebhookEvent) async {
        guard let eventType = WebhookEventType(rawValue: event.webhookEvent) else {
            logger.warning("Unknown webhook event type: \(event.webhookEvent)")
            return
        }

        let issueKey = event.issueKey ?? event.issue?.key

        switch eventType {
        case .issueCreated, .issueUpdated:
            if let key = issueKey {
                await syncEngine.requestSync(scope: .issue(issueKey: key))
                await notificationEngine.processWebhookEvent(event)
            }

        case .issueDeleted:
            if let key = issueKey {
                // Remove from local store will happen via sync
                await syncEngine.requestSync(scope: .issue(issueKey: key))
            }

        case .commentCreated, .commentUpdated:
            if let key = issueKey {
                await syncEngine.requestSync(scope: .issue(issueKey: key))
                await notificationEngine.processWebhookEvent(event)
            }

        case .commentDeleted:
            if let key = issueKey {
                await syncEngine.requestSync(scope: .issue(issueKey: key))
            }
        }

        logger.info("Processed webhook event: \(eventType.rawValue) for \(issueKey ?? "unknown")")
    }
}
