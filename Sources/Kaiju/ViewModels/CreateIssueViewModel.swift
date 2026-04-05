import Foundation
import os

/// ViewModel for the create issue modal
@Observable
@MainActor
final class CreateIssueViewModel {
    var selectedProjectKey: String = ""
    var issueTypeName: String = "Task"
    var summary: String = ""
    var descriptionText: String = ""
    var assigneeAccountId: String?
    var priorityId: String?
    var labels: [String] = []

    private(set) var availableIssueTypes: [IssueTypeRecord] = []
    private(set) var availablePriorities: [PriorityRecord] = []
    private(set) var isCreating = false
    private(set) var errorMessage: String?
    private(set) var createdIssueKey: String?

    private let store: LocalStoreProtocol
    private let apiClient: JiraAPIClientProtocol
    private let syncEngine: SyncEngine
    private let logger = KaijuLogger.ui

    init(store: LocalStoreProtocol, apiClient: JiraAPIClientProtocol, syncEngine: SyncEngine) {
        self.store = store
        self.apiClient = apiClient
        self.syncEngine = syncEngine
    }

    /// Load reference data for the form
    func loadFormData() async {
        do {
            availableIssueTypes = try await store.allIssueTypes()
            availablePriorities = try await store.allPriorities()
        } catch {
            logger.error("Failed to load form data: \(error.localizedDescription)")
        }
    }

    /// Create the issue
    func createIssue() async -> Bool {
        guard !summary.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Summary is required"
            return false
        }

        isCreating = true
        errorMessage = nil

        do {
            var fields: [String: Any] = [
                "project": ["key": selectedProjectKey],
                "summary": summary,
                "issuetype": ["name": issueTypeName],
            ]

            if !descriptionText.isEmpty {
                let adf = ADFDocument.plainText(descriptionText)
                let adfData = try JSONEncoder().encode(adf)
                if let adfDict = try JSONSerialization.jsonObject(with: adfData) as? [String: Any] {
                    fields["description"] = adfDict
                }
            }

            if let assignee = assigneeAccountId {
                fields["assignee"] = ["accountId": assignee]
            }

            if let priority = priorityId {
                fields["priority"] = ["id": priority]
            }

            if !labels.isEmpty {
                fields["labels"] = labels
            }

            let body = try JSONSerialization.data(withJSONObject: ["fields": fields])
            let created = try await apiClient.createIssue(body: body)

            createdIssueKey = created.key
            logger.info("Created issue \(created.key)")

            // Trigger sync for the new issue
            await syncEngine.requestSync(scope: .issue(issueKey: created.key))

            isCreating = false
            return true
        } catch {
            errorMessage = "Failed to create issue: \(error.localizedDescription)"
            isCreating = false
            return false
        }
    }

    /// Reset the form
    func reset() {
        summary = ""
        descriptionText = ""
        assigneeAccountId = nil
        priorityId = nil
        labels = []
        errorMessage = nil
        createdIssueKey = nil
    }
}
