import Foundation
import os

/// ViewModel for JQL search
@Observable
@MainActor
final class SearchViewModel {
    private(set) var results: [IssueRecord] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?
    private(set) var totalResults = 0

    var jqlQuery: String = ""
    var recentSearches: [String] = []

    private let store: LocalStoreProtocol
    private let apiClient: JiraAPIClientProtocol
    private let logger = KaijuLogger.ui

    init(store: LocalStoreProtocol, apiClient: JiraAPIClientProtocol) {
        self.store = store
        self.apiClient = apiClient
    }

    /// Execute a JQL search
    func search() async {
        let query = jqlQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil

        do {
            let result = try await apiClient.searchJQL(
                jql: query,
                startAt: 0,
                maxResults: 50,
                fields: JiraEndpoints.boardCardFields
            )

            totalResults = result.total
            results = result.issues.map { issue in
                IssueRecord(
                    id: issue.id,
                    key: issue.key,
                    summary: issue.fields.summary,
                    descriptionAdf: nil,
                    statusId: issue.fields.status?.id,
                    statusName: issue.fields.status?.name,
                    statusCategory: issue.fields.status?.statusCategory?.name,
                    priorityId: issue.fields.priority?.id,
                    priorityName: issue.fields.priority?.name,
                    issueTypeId: issue.fields.issuetype?.id,
                    issueTypeName: issue.fields.issuetype?.name,
                    assigneeAccountId: issue.fields.assignee?.accountId,
                    assigneeDisplayName: issue.fields.assignee?.displayName,
                    assigneeAvatarUrl: issue.fields.assignee?.avatarUrls?["24x24"],
                    reporterAccountId: nil,
                    reporterDisplayName: nil,
                    projectKey: String(issue.key.split(separator: "-").first ?? ""),
                    labels: nil,
                    sprintId: nil,
                    rank: nil,
                    storyPoints: nil,
                    createdAt: issue.fields.created,
                    updatedAt: issue.fields.updated
                )
            }

            // Save to recent searches
            if !recentSearches.contains(query) {
                recentSearches.insert(query, at: 0)
                if recentSearches.count > 10 {
                    recentSearches = Array(recentSearches.prefix(10))
                }
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isSearching = false
    }

    /// Quick search (spotlight-style) — searches by text content
    func quickSearch(text: String) async {
        guard !text.isEmpty else {
            results = []
            return
        }
        jqlQuery = "text ~ \"\(text)\" ORDER BY updated DESC"
        await search()
    }
}
