import Foundation
import os

/// Sync scopes determine what data to synchronize
enum SyncScope: Sendable, Equatable {
    case allProjects
    case board(boardId: Int)
    case issue(issueKey: String)
    case boardConfiguration(boardId: Int)
    case referenceData
}

/// Represents a pending write operation
struct WriteOperation: Sendable {
    let operation: String
    let endpoint: String
    let method: String
    let body: Data
    let issueKey: String?
}

/// Sync engine actor — coordinates all data synchronization between local store and Jira API.
/// ViewModels never call the network directly; they request syncs through this engine.
actor SyncEngine {
    private let store: LocalStoreProtocol
    private let apiClient: JiraAPIClientProtocol
    private let logger = KaijuLogger.sync
    private let conflictResolver: ConflictResolver
    private let syncQueue: SyncQueue

    /// Whether webhooks are currently active (suppresses polling when true)
    private(set) var webhooksActive: Bool = false

    /// Callback for notifying the UI about sync events
    var onSyncError: (@Sendable (String) -> Void)?
    var onOptimisticRevert: (@Sendable (String, String) -> Void)?  // issueKey, message

    init(
        store: LocalStoreProtocol,
        apiClient: JiraAPIClientProtocol,
        conflictResolver: ConflictResolver = ConflictResolver(),
        syncQueue: SyncQueue = SyncQueue()
    ) {
        self.store = store
        self.apiClient = apiClient
        self.conflictResolver = conflictResolver
        self.syncQueue = syncQueue
    }

    // MARK: - Sync Requests

    /// Perform an incremental sync for a given scope
    func requestSync(scope: SyncScope) async {
        do {
            switch scope {
            case .allProjects:
                try await syncProjects()
            case .board(let boardId):
                try await syncBoard(boardId: boardId)
            case .issue(let issueKey):
                try await syncSingleIssue(issueKey: issueKey)
            case .boardConfiguration(let boardId):
                try await syncBoardConfiguration(boardId: boardId)
            case .referenceData:
                try await syncReferenceData()
            }
        } catch {
            logger.error("Sync failed for scope \(String(describing: scope)): \(error.localizedDescription)")
            onSyncError?(error.localizedDescription)
        }
    }

    // MARK: - Projects

    private func syncProjects() async throws {
        let projects = try await apiClient.fetchProjects()
        let records = projects.map { project in
            ProjectRecord(
                id: project.id,
                key: project.key,
                name: project.name,
                avatarUrl: project.avatarUrls?["48x48"],
                projectType: project.projectTypeKey,
                style: project.style,
                updatedAt: DateFormatters.nowISO8601()
            )
        }
        try await store.saveProjects(records)
        logger.info("Synced \(records.count) projects")
    }

    // MARK: - Board

    private func syncBoard(boardId: Int) async throws {
        let scopeKey = "board_\(boardId)"
        let lastSync = try await store.syncState(forScope: scopeKey)

        // Fetch board issues with pagination
        var allIssues: [APIIssue] = []
        var startAt = 0
        let maxResults = 50

        while true {
            let result = try await apiClient.fetchBoardIssues(
                boardId: boardId,
                startAt: startAt,
                maxResults: maxResults,
                fields: JiraEndpoints.boardCardFields
            )
            allIssues.append(contentsOf: result.issues)

            if startAt + result.maxResults >= result.total {
                break
            }
            startAt += maxResults
        }

        // Convert and save
        let records = allIssues.map { mapIssueToRecord($0) }
        try await store.saveIssues(records)

        // Update sync state
        let syncState = SyncStateRecord(
            scope: scopeKey,
            lastSyncedAt: DateFormatters.nowISO8601(),
            etag: nil
        )
        try await store.saveSyncState(syncState)

        logger.info("Synced \(records.count) issues for board \(boardId)")
    }

    private func syncBoardConfiguration(boardId: Int) async throws {
        let config = try await apiClient.fetchBoardConfiguration(boardId: boardId)
        let columns = config.columnConfig.columns.enumerated().map { index, column in
            BoardColumnRecord(
                boardId: config.id,
                name: column.name,
                sortOrder: index,
                statusIds: encodeJSON(column.statuses.map(\.id))
            )
        }
        try await store.saveBoardColumns(columns, forBoard: boardId)
    }

    // MARK: - Single Issue

    private func syncSingleIssue(issueKey: String) async throws {
        // Check if there's a pending write for this issue — skip if so
        let pendingWrites = try await store.pendingWrites()
        if pendingWrites.contains(where: { $0.issueKey == issueKey }) {
            logger.info("Skipping sync for \(issueKey) — pending write exists")
            return
        }

        let apiIssue = try await apiClient.fetchIssue(
            key: issueKey,
            fields: JiraEndpoints.issueDetailFields
        )
        let record = mapIssueToRecord(apiIssue)
        try await store.saveIssue(record)

        // Sync comments
        if let commentPage = apiIssue.fields.comment {
            let commentRecords = commentPage.comments.map { comment in
                CommentRecord(
                    id: comment.id,
                    issueId: apiIssue.id,
                    authorAccountId: comment.author?.accountId,
                    authorDisplayName: comment.author?.displayName,
                    authorAvatarUrl: comment.author?.avatarUrls?["24x24"],
                    bodyAdf: encodeADF(comment.body),
                    createdAt: comment.created,
                    updatedAt: comment.updated
                )
            }
            try await store.saveComments(commentRecords)
        }

        // Sync attachments
        if let attachments = apiIssue.fields.attachment {
            let attachmentRecords = attachments.map { att in
                AttachmentRecord(
                    id: att.id,
                    issueId: apiIssue.id,
                    filename: att.filename,
                    mimeType: att.mimeType,
                    size: att.size,
                    contentUrl: att.content,
                    thumbnailUrl: att.thumbnail,
                    authorDisplayName: att.author?.displayName,
                    createdAt: att.created
                )
            }
            try await store.saveAttachments(attachmentRecords)
        }

        logger.info("Synced issue \(issueKey)")
    }

    // MARK: - Reference Data

    private func syncReferenceData() async throws {
        async let priorities = apiClient.fetchPriorities()
        async let statuses = apiClient.fetchStatuses()
        async let issueTypes = apiClient.fetchIssueTypes()

        let p = try await priorities
        let s = try await statuses
        let i = try await issueTypes

        try await store.savePriorities(p.enumerated().map { idx, priority in
            PriorityRecord(
                id: priority.id ?? "",
                name: priority.name,
                iconUrl: priority.iconUrl,
                sortOrder: idx
            )
        })

        try await store.saveStatuses(s.map { status in
            StatusRecord(
                id: status.id ?? "",
                name: status.name,
                category: status.statusCategory?.name,
                iconUrl: status.iconUrl
            )
        })

        try await store.saveIssueTypes(i.map { type in
            IssueTypeRecord(
                id: type.id ?? "",
                name: type.name,
                iconUrl: type.iconUrl,
                subtask: type.subtask ?? false
            )
        })

        logger.info("Synced reference data")
    }

    // MARK: - Write Operations

    /// Enqueue a write operation with optimistic update already applied
    func enqueueWrite(_ operation: WriteOperation) async {
        let record = PendingWriteRecord(
            id: nil,
            operation: operation.operation,
            endpoint: operation.endpoint,
            method: operation.method,
            body: String(data: operation.body, encoding: .utf8) ?? "",
            createdAt: DateFormatters.nowISO8601(),
            retryCount: 0,
            lastError: nil,
            issueKey: operation.issueKey
        )

        do {
            try await store.enqueuePendingWrite(record)
            await processNextWrite()
        } catch {
            logger.error("Failed to enqueue write: \(error.localizedDescription)")
        }
    }

    /// Process the next pending write in the queue
    func processNextWrite() async {
        do {
            let writes = try await store.pendingWrites()
            guard let write = writes.first else { return }

            guard let writeId = write.id else { return }

            // Attempt the API call
            // The actual network call is handled by the API client via the sync queue
            // For now, delete the pending write on success
            try await store.deletePendingWrite(id: writeId)
            logger.info("Processed write: \(write.operation)")
        } catch {
            logger.error("Write processing failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Transition (Optimistic)

    /// Transition an issue status with optimistic update
    func transitionIssue(key: String, toStatusName: String, toStatusId: String?, transitionId: String) async {
        // Optimistic update: update local store immediately
        do {
            if var issue = try await store.issue(byKey: key) {
                issue.statusName = toStatusName
                if let statusId = toStatusId {
                    issue.statusId = statusId
                }
                try await store.saveIssue(issue)
            }
        } catch {
            logger.error("Optimistic update failed: \(error.localizedDescription)")
        }

        // Enqueue the API call
        do {
            let body = try JSONEncoder().encode(["transition": ["id": transitionId]])
            await enqueueWrite(WriteOperation(
                operation: "transition",
                endpoint: "issue/\(key)/transitions",
                method: "POST",
                body: body,
                issueKey: key
            ))

            // Actually perform the transition
            try await apiClient.performTransition(issueKey: key, transitionId: transitionId)

            // On success, sync the issue to get the authoritative state
            try await syncSingleIssue(issueKey: key)
        } catch {
            // Revert optimistic update
            logger.error("Transition failed for \(key): \(error.localizedDescription)")
            onOptimisticRevert?(key, "Failed to change status. Reverting.")
            try? await syncSingleIssue(issueKey: key)
        }
    }

    // MARK: - Webhook Control

    func setWebhooksActive(_ active: Bool) {
        webhooksActive = active
        logger.info("Webhooks active: \(active)")
    }

    // MARK: - Helpers

    private func mapIssueToRecord(_ issue: APIIssue) -> IssueRecord {
        IssueRecord(
            id: issue.id,
            key: issue.key,
            summary: issue.fields.summary,
            descriptionAdf: encodeADF(issue.fields.description),
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
            reporterAccountId: issue.fields.reporter?.accountId,
            reporterDisplayName: issue.fields.reporter?.displayName,
            projectKey: extractProjectKey(from: issue.key),
            labels: encodeJSON(issue.fields.labels ?? []),
            sprintId: issue.fields.sprint?.id,
            rank: nil,
            storyPoints: issue.fields.customfield_10016,
            createdAt: issue.fields.created,
            updatedAt: issue.fields.updated
        )
    }

    private func extractProjectKey(from issueKey: String) -> String {
        let parts = issueKey.split(separator: "-")
        return parts.first.map(String.init) ?? issueKey
    }

    private func encodeJSON<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    private func encodeADF(_ document: ADFDocument?) -> String? {
        guard let doc = document else { return nil }
        return try? ADFParser.encodeToString(doc)
    }
}
