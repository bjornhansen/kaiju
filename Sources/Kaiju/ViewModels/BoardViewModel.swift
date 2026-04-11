import Foundation
import os

/// Represents a column on the board with its issues
struct BoardColumn: Identifiable, Sendable {
    let id: String  // column name
    let name: String
    let statusIds: [String]
    var issues: [IssueRecord]
}

/// ViewModel for the Kanban board view
@Observable
@MainActor
final class BoardViewModel {
    private(set) var columns: [BoardColumn] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var boardName: String = ""
    private(set) var availableBoards: [BoardRecord] = []

    var selectedBoardId: Int? {
        didSet {
            if let id = selectedBoardId {
                Task { await loadBoard(id: id) }
            }
        }
    }

    private let store: LocalStoreProtocol
    private let syncEngine: SyncEngine
    private let apiClient: JiraAPIClientProtocol
    private let logger = KaijuLogger.ui

    init(store: LocalStoreProtocol, syncEngine: SyncEngine, apiClient: JiraAPIClientProtocol? = nil) {
        self.store = store
        self.syncEngine = syncEngine
        self.apiClient = apiClient ?? JiraAPIClient()
    }

    /// Load boards for a project — fetches from API, saves locally, then selects the first one
    func loadBoards(projectKey: String) async {
        isLoading = true
        do {
            // Fetch boards from Jira API
            let apiBoards = try await apiClient.fetchBoards(projectKey: projectKey)
            let records = apiBoards.map { board in
                BoardRecord(id: board.id, name: board.name, type: board.type, projectKey: projectKey)
            }
            for record in records {
                try await store.saveBoard(record)
            }
            availableBoards = records

            // Auto-select the first board
            if let firstBoard = availableBoards.first {
                selectedBoardId = firstBoard.id
            }
        } catch {
            // Fall back to local store
            do {
                availableBoards = try await store.boards(forProject: projectKey)
                if let firstBoard = availableBoards.first {
                    selectedBoardId = firstBoard.id
                }
            } catch {
                errorMessage = "Failed to load boards"
            }
        }
        isLoading = false
    }

    /// Load a specific board's columns and issues
    func loadBoard(id: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            // Load board columns from local store
            let columnRecords = try await store.boardColumns(forBoard: id)

            if columnRecords.isEmpty {
                // Sync board configuration first
                await syncEngine.requestSync(scope: .boardConfiguration(boardId: id))
                await syncEngine.requestSync(scope: .board(boardId: id))

                // Reload after sync
                let updatedColumns = try await store.boardColumns(forBoard: id)
                await buildColumns(from: updatedColumns, boardId: id)
            } else {
                await buildColumns(from: columnRecords, boardId: id)
            }
        } catch {
            errorMessage = "Failed to load board"
            logger.error("Failed to load board \(id): \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Refresh the current board data
    func refresh() async {
        guard let boardId = selectedBoardId else { return }
        await syncEngine.requestSync(scope: .board(boardId: boardId))
        await loadBoard(id: boardId)
    }

    /// Handle drag-and-drop of an issue between columns
    func moveIssue(issueKey: String, toColumn: BoardColumn, transitionId: String) async {
        // Find the target status from the column
        guard let targetStatusId = toColumn.statusIds.first else { return }
        let targetStatusName = toColumn.name

        // Optimistic update: move in local columns
        updateLocalColumns(issueKey: issueKey, toColumnId: toColumn.id)

        // Trigger transition via sync engine
        await syncEngine.transitionIssue(
            key: issueKey,
            toStatusName: targetStatusName,
            toStatusId: targetStatusId,
            transitionId: transitionId
        )
    }

    private func buildColumns(from records: [BoardColumnRecord], boardId: Int) async {
        var newColumns: [BoardColumn] = []

        for record in records {
            let statusIds = decodeJSONArray(record.statusIds)
            let projectKey = availableBoards.first(where: { $0.id == boardId })?.projectKey ?? ""

            let issues: [IssueRecord]
            do {
                issues = try await store.issues(forStatusIds: statusIds, projectKey: projectKey)
            } catch {
                issues = []
            }

            newColumns.append(BoardColumn(
                id: record.name,
                name: record.name,
                statusIds: statusIds,
                issues: issues
            ))
        }

        columns = newColumns
    }

    private func updateLocalColumns(issueKey: String, toColumnId: String) {
        // Remove issue from current column
        var movedIssue: IssueRecord?
        for i in columns.indices {
            if let idx = columns[i].issues.firstIndex(where: { $0.key == issueKey }) {
                movedIssue = columns[i].issues.remove(at: idx)
                break
            }
        }

        // Add to target column
        if let issue = movedIssue,
           let targetIdx = columns.firstIndex(where: { $0.id == toColumnId }) {
            columns[targetIdx].issues.append(issue)
        }
    }

    private func decodeJSONArray(_ json: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return array
    }
}
