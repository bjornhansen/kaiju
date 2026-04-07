import XCTest
@testable import Kaiju

final class SchemaTests: XCTestCase {

    func test_save_issue_and_retrieve_by_key() async throws {
        let store = try LocalStore()  // In-memory

        let issue = makeTestIssue(key: "KAI-1", statusName: "To Do")
        try await store.saveIssue(issue)

        let retrieved = try await store.issue(byKey: "KAI-1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.key, "KAI-1")
        XCTAssertEqual(retrieved?.summary, "Test issue")
        XCTAssertEqual(retrieved?.statusName, "To Do")
    }

    func test_issues_filtered_by_project_key() async throws {
        let store = try LocalStore()

        // Save issues for two projects
        try await store.saveIssue(makeTestIssue(id: "1", key: "PROJ-1", projectKey: "PROJ"))
        try await store.saveIssue(makeTestIssue(id: "2", key: "PROJ-2", projectKey: "PROJ"))
        try await store.saveIssue(makeTestIssue(id: "3", key: "OTHER-1", projectKey: "OTHER"))

        let projIssues = try await store.issues(forProject: "PROJ")
        XCTAssertEqual(projIssues.count, 2)
        XCTAssertTrue(projIssues.allSatisfy { $0.projectKey == "PROJ" })

        let otherIssues = try await store.issues(forProject: "OTHER")
        XCTAssertEqual(otherIssues.count, 1)
    }

    func test_pending_write_persists_across_store_recreation() async throws {
        // Use a temp file-based store to test persistence
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_\(UUID().uuidString).sqlite").path

        // Create store and insert pending write
        let store1 = try LocalStore(path: dbPath)
        let write = PendingWriteRecord(
            id: nil,
            operation: "transition",
            endpoint: "issue/KAI-1/transitions",
            method: "POST",
            body: "{\"transition\":{\"id\":\"31\"}}",
            createdAt: "2024-01-01T00:00:00Z",
            retryCount: 0,
            lastError: nil,
            issueKey: "KAI-1"
        )
        try await store1.enqueuePendingWrite(write)

        // Create new store instance with same path
        let store2 = try LocalStore(path: dbPath)
        let writes = try await store2.pendingWrites()

        XCTAssertEqual(writes.count, 1)
        XCTAssertEqual(writes[0].operation, "transition")
        XCTAssertEqual(writes[0].issueKey, "KAI-1")

        // Cleanup
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func test_notification_insert_and_unread_count() async throws {
        let store = try LocalStore()

        let notification = NotificationRecord(
            id: nil,
            eventType: "assigned",
            issueKey: "KAI-1",
            issueSummary: "Test issue",
            actorDisplayName: "Alice",
            actorAvatarUrl: nil,
            detail: "Alice assigned this to you",
            isRead: false,
            createdAt: "2024-01-01T00:00:00Z"
        )

        try await store.saveNotification(notification)

        let count = try await store.unreadNotificationCount()
        XCTAssertEqual(count, 1)

        let unread = try await store.unreadNotifications()
        XCTAssertEqual(unread.count, 1)
        XCTAssertEqual(unread[0].eventType, "assigned")
        XCTAssertEqual(unread[0].issueKey, "KAI-1")
    }

    func test_mark_all_notifications_read() async throws {
        let store = try LocalStore()

        for i in 1...3 {
            let notification = NotificationRecord(
                id: nil,
                eventType: "commented",
                issueKey: "KAI-\(i)",
                issueSummary: nil,
                actorDisplayName: nil,
                actorAvatarUrl: nil,
                detail: nil,
                isRead: false,
                createdAt: "2024-01-0\(i)T00:00:00Z"
            )
            try await store.saveNotification(notification)
        }

        let unreadBefore = try await store.unreadNotificationCount()
        XCTAssertEqual(unreadBefore, 3)

        try await store.markAllNotificationsRead()

        let unreadAfter = try await store.unreadNotificationCount()
        XCTAssertEqual(unreadAfter, 0)
    }

    func test_save_and_retrieve_projects() async throws {
        let store = try LocalStore()

        let project = ProjectRecord(
            id: "10001",
            key: "KAI",
            name: "Kaiju",
            avatarUrl: nil,
            projectType: "software",
            style: "classic",
            updatedAt: nil
        )
        try await store.saveProject(project)

        let projects = try await store.allProjects()
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].key, "KAI")
        XCTAssertEqual(projects[0].name, "Kaiju")
    }

    func test_save_and_retrieve_board_columns() async throws {
        let store = try LocalStore()

        // Save a project first (FK constraint)
        let project = ProjectRecord(id: "1", key: "KAI", name: "Kaiju", avatarUrl: nil, projectType: nil, style: nil, updatedAt: nil)
        try await store.saveProject(project)

        let board = BoardRecord(id: 1, name: "KAI Board", type: "kanban", projectKey: "KAI")
        try await store.saveBoard(board)

        let columns = [
            BoardColumnRecord(boardId: 1, name: "To Do", sortOrder: 0, statusIds: "[\"10000\"]"),
            BoardColumnRecord(boardId: 1, name: "In Progress", sortOrder: 1, statusIds: "[\"10001\"]"),
            BoardColumnRecord(boardId: 1, name: "Done", sortOrder: 2, statusIds: "[\"10002\"]"),
        ]
        try await store.saveBoardColumns(columns, forBoard: 1)

        let retrieved = try await store.boardColumns(forBoard: 1)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].name, "To Do")
        XCTAssertEqual(retrieved[1].name, "In Progress")
        XCTAssertEqual(retrieved[2].name, "Done")
    }

    func test_delete_issue_by_key() async throws {
        let store = try LocalStore()

        try await store.saveIssue(makeTestIssue(key: "KAI-1"))
        let saved = try await store.issue(byKey: "KAI-1")
        XCTAssertNotNil(saved)

        try await store.deleteIssue(byKey: "KAI-1")
        let deleted = try await store.issue(byKey: "KAI-1")
        XCTAssertNil(deleted)
    }

    func test_clear_all_data() async throws {
        let store = try LocalStore()

        try await store.saveProject(ProjectRecord(id: "1", key: "KAI", name: "Kaiju", avatarUrl: nil, projectType: nil, style: nil, updatedAt: nil))
        try await store.saveIssue(makeTestIssue(key: "KAI-1"))

        try await store.clearAllData()

        let projects = try await store.allProjects()
        let issue = try await store.issue(byKey: "KAI-1")
        XCTAssertTrue(projects.isEmpty)
        XCTAssertNil(issue)
    }

    // MARK: - Helpers

    private func makeTestIssue(
        id: String = "10001",
        key: String = "KAI-1",
        statusName: String = "To Do",
        projectKey: String? = nil
    ) -> IssueRecord {
        IssueRecord(
            id: id,
            key: key,
            summary: "Test issue",
            descriptionAdf: nil,
            statusId: "1",
            statusName: statusName,
            statusCategory: "new",
            priorityId: "3",
            priorityName: "Medium",
            issueTypeId: "10001",
            issueTypeName: "Task",
            assigneeAccountId: nil,
            assigneeDisplayName: nil,
            assigneeAvatarUrl: nil,
            reporterAccountId: nil,
            reporterDisplayName: nil,
            projectKey: projectKey ?? String(key.split(separator: "-").first ?? "KAI"),
            labels: nil,
            sprintId: nil,
            rank: nil,
            storyPoints: nil,
            createdAt: nil,
            updatedAt: nil
        )
    }
}
