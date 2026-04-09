import Foundation
import os

/// Manages dynamic webhook registration with Jira
actor WebhookRegistrar {
    private let apiClient: JiraAPIClientProtocol
    private let logger = KaijuLogger.webhook

    /// IDs of registered webhooks (for refresh/cleanup)
    private(set) var registeredWebhookIds: [Int] = []

    /// URL of the relay server
    let relayBaseURL: String

    /// When webhooks expire (Jira webhooks have a 30-day TTL)
    private var expiryDate: Date?
    private var refreshTask: Task<Void, Never>?

    init(apiClient: JiraAPIClientProtocol, relayBaseURL: String) {
        self.apiClient = apiClient
        self.relayBaseURL = relayBaseURL
    }

    /// Register webhooks for the given cloud ID and projects
    func register(siteId: String, projectKeys: [String]) async throws {
        let jqlFilter = projectKeys.isEmpty
            ? nil
            : "project IN (\(projectKeys.joined(separator: ", ")))"

        let request = WebhookRegistrationRequest(
            url: "\(relayBaseURL)/webhook/\(siteId)",
            webhooks: [
                WebhookDefinition(
                    events: [
                        "jira:issue_created",
                        "jira:issue_updated",
                        "jira:issue_deleted",
                        "comment_created",
                        "comment_updated",
                        "comment_deleted",
                    ],
                    jqlFilter: jqlFilter,
                    fieldIdsFilter: ["summary", "status", "assignee", "priority", "comment"]
                )
            ]
        )

        let body = try JSONEncoder().encode(request)
        let responseData = try await apiClient.registerWebhooks(body: body)

        // Parse response to get webhook IDs
        if let response = try? JSONDecoder().decode(WebhookRegistrationResponse.self, from: responseData) {
            registeredWebhookIds = response.webhookRegistrationResult?
                .compactMap(\.createdWebhookId) ?? []
        }

        // Set expiry (webhooks expire after 30 days)
        expiryDate = Date().addingTimeInterval(30 * 24 * 60 * 60)

        // Schedule refresh before expiry
        scheduleRefresh()

        logger.info("Registered \(self.registeredWebhookIds.count) webhooks")
    }

    /// Refresh webhook registration before expiry
    func refresh() async throws {
        guard !registeredWebhookIds.isEmpty else { return }

        try await apiClient.refreshWebhooks(webhookIds: registeredWebhookIds)
        expiryDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        scheduleRefresh()

        logger.info("Refreshed \(self.registeredWebhookIds.count) webhooks")
    }

    /// Unregister all webhooks (on sign-out)
    func unregisterAll() {
        refreshTask?.cancel()
        refreshTask = nil
        registeredWebhookIds = []
        expiryDate = nil
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()

        guard let expiry = expiryDate else { return }

        // Refresh 1 day before expiry
        let refreshDate = expiry.addingTimeInterval(-24 * 60 * 60)
        let delay = max(refreshDate.timeIntervalSinceNow, 60)

        refreshTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            try? await self.refresh()
        }
    }
}
