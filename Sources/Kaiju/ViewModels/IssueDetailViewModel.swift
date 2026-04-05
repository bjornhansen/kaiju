import Foundation
import os

/// ViewModel for the issue detail panel
@Observable
@MainActor
final class IssueDetailViewModel {
    private(set) var issue: IssueRecord?
    private(set) var comments: [CommentRecord] = []
    private(set) var attachments: [AttachmentRecord] = []
    private(set) var availableTransitions: [APITransition] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var description: ADFDocument?

    var issueKey: String? {
        didSet {
            if let key = issueKey {
                Task { await loadIssue(key: key) }
            } else {
                issue = nil
                comments = []
                attachments = []
            }
        }
    }

    private let store: LocalStoreProtocol
    private let syncEngine: SyncEngine
    private let apiClient: JiraAPIClientProtocol
    private let logger = KaijuLogger.ui

    init(store: LocalStoreProtocol, syncEngine: SyncEngine, apiClient: JiraAPIClientProtocol) {
        self.store = store
        self.syncEngine = syncEngine
        self.apiClient = apiClient
    }

    /// Load issue details from local store, then sync
    func loadIssue(key: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Load from local store first (instant)
            issue = try await store.issue(byKey: key)

            if let issue = issue {
                comments = try await store.comments(forIssue: issue.id)
                attachments = try await store.attachments(forIssue: issue.id)

                // Parse ADF description
                if let adfString = issue.descriptionAdf,
                   let data = adfString.data(using: .utf8) {
                    description = try? ADFParser.parse(data: data)
                }
            }

            // Sync from API in background
            await syncEngine.requestSync(scope: .issue(issueKey: key))

            // Reload after sync
            issue = try await store.issue(byKey: key)
            if let issue = issue {
                comments = try await store.comments(forIssue: issue.id)
                attachments = try await store.attachments(forIssue: issue.id)
                if let adfString = issue.descriptionAdf,
                   let data = adfString.data(using: .utf8) {
                    description = try? ADFParser.parse(data: data)
                }
            }

            // Fetch available transitions
            availableTransitions = try await apiClient.fetchTransitions(issueKey: key)
        } catch {
            errorMessage = "Failed to load issue"
            logger.error("Failed to load issue \(key): \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Change issue status via transition
    func transitionIssue(transitionId: String, toStatusName: String, toStatusId: String?) async {
        guard let key = issueKey else { return }
        await syncEngine.transitionIssue(
            key: key,
            toStatusName: toStatusName,
            toStatusId: toStatusId,
            transitionId: transitionId
        )
        // Reload
        await loadIssue(key: key)
    }

    /// Update assignee
    func updateAssignee(accountId: String?) async {
        guard let key = issueKey else { return }

        // Optimistic update
        issue?.assigneeAccountId = accountId

        do {
            let body: [String: Any] = [
                "fields": ["assignee": accountId != nil ? ["accountId": accountId!] : NSNull()]
            ]
            let data = try JSONSerialization.data(withJSONObject: body)
            try await apiClient.updateIssue(key: key, body: data)
            await syncEngine.requestSync(scope: .issue(issueKey: key))
        } catch {
            errorMessage = "Failed to update assignee"
            await loadIssue(key: key)  // Revert
        }
    }

    /// Add a comment (plain text, converted to simple ADF)
    func addComment(text: String) async {
        guard let key = issueKey else { return }

        let adfDoc = ADFDocument.plainText(text)

        do {
            _ = try await apiClient.addComment(issueKey: key, body: adfDoc)
            // Refresh comments
            await syncEngine.requestSync(scope: .issue(issueKey: key))
            if let issue = issue {
                comments = try await store.comments(forIssue: issue.id)
            }
        } catch {
            errorMessage = "Failed to add comment"
        }
    }

    /// Update issue summary
    func updateSummary(_ newSummary: String) async {
        guard let key = issueKey else { return }

        // Optimistic update
        issue?.summary = newSummary

        do {
            let body: [String: Any] = ["fields": ["summary": newSummary]]
            let data = try JSONSerialization.data(withJSONObject: body)
            try await apiClient.updateIssue(key: key, body: data)
        } catch {
            errorMessage = "Failed to update summary"
            await loadIssue(key: key)
        }
    }

    /// Update priority
    func updatePriority(priorityId: String) async {
        guard let key = issueKey else { return }

        do {
            let body: [String: Any] = ["fields": ["priority": ["id": priorityId]]]
            let data = try JSONSerialization.data(withJSONObject: body)
            try await apiClient.updateIssue(key: key, body: data)
            await syncEngine.requestSync(scope: .issue(issueKey: key))
        } catch {
            errorMessage = "Failed to update priority"
        }
    }
}
