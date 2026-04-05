import Foundation
import GRDB

/// Protocol for the local data store, enabling testing with mocks
protocol LocalStoreProtocol: Sendable {
    // MARK: - Issues
    func saveIssue(_ issue: IssueRecord) async throws
    func saveIssues(_ issues: [IssueRecord]) async throws
    func issue(byKey key: String) async throws -> IssueRecord?
    func issues(forProject projectKey: String) async throws -> [IssueRecord]
    func issues(forStatusIds statusIds: [String], projectKey: String) async throws -> [IssueRecord]
    func deleteIssue(byKey key: String) async throws

    // MARK: - Projects
    func saveProject(_ project: ProjectRecord) async throws
    func saveProjects(_ projects: [ProjectRecord]) async throws
    func allProjects() async throws -> [ProjectRecord]
    func project(byKey key: String) async throws -> ProjectRecord?

    // MARK: - Boards
    func saveBoard(_ board: BoardRecord) async throws
    func saveBoards(_ boards: [BoardRecord]) async throws
    func boards(forProject projectKey: String) async throws -> [BoardRecord]
    func saveBoardColumns(_ columns: [BoardColumnRecord], forBoard boardId: Int) async throws
    func boardColumns(forBoard boardId: Int) async throws -> [BoardColumnRecord]

    // MARK: - Comments
    func saveComment(_ comment: CommentRecord) async throws
    func saveComments(_ comments: [CommentRecord]) async throws
    func comments(forIssue issueId: String) async throws -> [CommentRecord]

    // MARK: - Attachments
    func saveAttachments(_ attachments: [AttachmentRecord]) async throws
    func attachments(forIssue issueId: String) async throws -> [AttachmentRecord]

    // MARK: - Pending Writes
    func enqueuePendingWrite(_ write: PendingWriteRecord) async throws
    func pendingWrites() async throws -> [PendingWriteRecord]
    func deletePendingWrite(id: Int64) async throws
    func updatePendingWrite(_ write: PendingWriteRecord) async throws

    // MARK: - Notifications
    func saveNotification(_ notification: NotificationRecord) async throws
    func unreadNotifications() async throws -> [NotificationRecord]
    func allNotifications(limit: Int) async throws -> [NotificationRecord]
    func unreadNotificationCount() async throws -> Int
    func markNotificationRead(id: Int64) async throws
    func markAllNotificationsRead() async throws

    // MARK: - Sync State
    func syncState(forScope scope: String) async throws -> SyncStateRecord?
    func saveSyncState(_ state: SyncStateRecord) async throws

    // MARK: - Reference Data
    func saveStatuses(_ statuses: [StatusRecord]) async throws
    func savePriorities(_ priorities: [PriorityRecord]) async throws
    func saveIssueTypes(_ types: [IssueTypeRecord]) async throws
    func saveUsers(_ users: [UserRecord]) async throws
    func allStatuses() async throws -> [StatusRecord]
    func allPriorities() async throws -> [PriorityRecord]
    func allIssueTypes() async throws -> [IssueTypeRecord]
    func searchUsers(query: String) async throws -> [UserRecord]

    // MARK: - Cleanup
    func clearAllData() async throws
}

/// SQLite-backed local store using GRDB
final class LocalStore: LocalStoreProtocol, @unchecked Sendable {
    private let dbQueue: DatabaseQueue

    /// Initialize with a database file path
    init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        try DatabaseMigrator.createMigrator().migrate(dbQueue)
    }

    /// Initialize with an in-memory database (for testing)
    init() throws {
        dbQueue = try DatabaseQueue()
        try DatabaseMigrator.createMigrator().migrate(dbQueue)
    }

    // MARK: - Issues

    func saveIssue(_ issue: IssueRecord) async throws {
        try await dbQueue.write { db in
            try issue.save(db)
        }
    }

    func saveIssues(_ issues: [IssueRecord]) async throws {
        try await dbQueue.write { db in
            for issue in issues {
                try issue.save(db)
            }
        }
    }

    func issue(byKey key: String) async throws -> IssueRecord? {
        try await dbQueue.read { db in
            try IssueRecord.filter(Column("key") == key).fetchOne(db)
        }
    }

    func issues(forProject projectKey: String) async throws -> [IssueRecord] {
        try await dbQueue.read { db in
            try IssueRecord.filter(Column("projectKey") == projectKey)
                .order(Column("updatedAt").desc)
                .fetchAll(db)
        }
    }

    func issues(forStatusIds statusIds: [String], projectKey: String) async throws -> [IssueRecord] {
        try await dbQueue.read { db in
            try IssueRecord
                .filter(statusIds.contains(Column("statusId")))
                .filter(Column("projectKey") == projectKey)
                .fetchAll(db)
        }
    }

    func deleteIssue(byKey key: String) async throws {
        try await dbQueue.write { db in
            _ = try IssueRecord.filter(Column("key") == key).deleteAll(db)
        }
    }

    // MARK: - Projects

    func saveProject(_ project: ProjectRecord) async throws {
        try await dbQueue.write { db in
            try project.save(db)
        }
    }

    func saveProjects(_ projects: [ProjectRecord]) async throws {
        try await dbQueue.write { db in
            for project in projects {
                try project.save(db)
            }
        }
    }

    func allProjects() async throws -> [ProjectRecord] {
        try await dbQueue.read { db in
            try ProjectRecord.order(Column("name")).fetchAll(db)
        }
    }

    func project(byKey key: String) async throws -> ProjectRecord? {
        try await dbQueue.read { db in
            try ProjectRecord.filter(Column("key") == key).fetchOne(db)
        }
    }

    // MARK: - Boards

    func saveBoard(_ board: BoardRecord) async throws {
        try await dbQueue.write { db in
            try board.save(db)
        }
    }

    func saveBoards(_ boards: [BoardRecord]) async throws {
        try await dbQueue.write { db in
            for board in boards {
                try board.save(db)
            }
        }
    }

    func boards(forProject projectKey: String) async throws -> [BoardRecord] {
        try await dbQueue.read { db in
            try BoardRecord.filter(Column("projectKey") == projectKey).fetchAll(db)
        }
    }

    func saveBoardColumns(_ columns: [BoardColumnRecord], forBoard boardId: Int) async throws {
        try await dbQueue.write { db in
            // Remove existing columns for this board
            try BoardColumnRecord.filter(Column("boardId") == boardId).deleteAll(db)
            for column in columns {
                try column.insert(db)
            }
        }
    }

    func boardColumns(forBoard boardId: Int) async throws -> [BoardColumnRecord] {
        try await dbQueue.read { db in
            try BoardColumnRecord
                .filter(Column("boardId") == boardId)
                .order(Column("sortOrder"))
                .fetchAll(db)
        }
    }

    // MARK: - Comments

    func saveComment(_ comment: CommentRecord) async throws {
        try await dbQueue.write { db in
            try comment.save(db)
        }
    }

    func saveComments(_ comments: [CommentRecord]) async throws {
        try await dbQueue.write { db in
            for comment in comments {
                try comment.save(db)
            }
        }
    }

    func comments(forIssue issueId: String) async throws -> [CommentRecord] {
        try await dbQueue.read { db in
            try CommentRecord
                .filter(Column("issueId") == issueId)
                .order(Column("createdAt"))
                .fetchAll(db)
        }
    }

    // MARK: - Attachments

    func saveAttachments(_ attachments: [AttachmentRecord]) async throws {
        try await dbQueue.write { db in
            for attachment in attachments {
                try attachment.save(db)
            }
        }
    }

    func attachments(forIssue issueId: String) async throws -> [AttachmentRecord] {
        try await dbQueue.read { db in
            try AttachmentRecord
                .filter(Column("issueId") == issueId)
                .order(Column("createdAt"))
                .fetchAll(db)
        }
    }

    // MARK: - Pending Writes

    func enqueuePendingWrite(_ write: PendingWriteRecord) async throws {
        try await dbQueue.write { db in
            var mutableWrite = write
            try mutableWrite.insert(db)
        }
    }

    func pendingWrites() async throws -> [PendingWriteRecord] {
        try await dbQueue.read { db in
            try PendingWriteRecord.order(Column("createdAt")).fetchAll(db)
        }
    }

    func deletePendingWrite(id: Int64) async throws {
        try await dbQueue.write { db in
            _ = try PendingWriteRecord.filter(Column("id") == id).deleteAll(db)
        }
    }

    func updatePendingWrite(_ write: PendingWriteRecord) async throws {
        try await dbQueue.write { db in
            try write.update(db)
        }
    }

    // MARK: - Notifications

    func saveNotification(_ notification: NotificationRecord) async throws {
        try await dbQueue.write { db in
            var mutable = notification
            try mutable.insert(db)
        }
    }

    func unreadNotifications() async throws -> [NotificationRecord] {
        try await dbQueue.read { db in
            try NotificationRecord
                .filter(Column("isRead") == false)
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    func allNotifications(limit: Int = 100) async throws -> [NotificationRecord] {
        try await dbQueue.read { db in
            try NotificationRecord
                .order(Column("createdAt").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    func unreadNotificationCount() async throws -> Int {
        try await dbQueue.read { db in
            try NotificationRecord.filter(Column("isRead") == false).fetchCount(db)
        }
    }

    func markNotificationRead(id: Int64) async throws {
        try await dbQueue.write { db in
            if var notification = try NotificationRecord.filter(Column("id") == id).fetchOne(db) {
                notification.isRead = true
                try notification.update(db)
            }
        }
    }

    func markAllNotificationsRead() async throws {
        try await dbQueue.write { db in
            try db.execute(sql: "UPDATE notifications SET isRead = 1 WHERE isRead = 0")
        }
    }

    // MARK: - Sync State

    func syncState(forScope scope: String) async throws -> SyncStateRecord? {
        try await dbQueue.read { db in
            try SyncStateRecord.filter(Column("scope") == scope).fetchOne(db)
        }
    }

    func saveSyncState(_ state: SyncStateRecord) async throws {
        try await dbQueue.write { db in
            try state.save(db)
        }
    }

    // MARK: - Reference Data

    func saveStatuses(_ statuses: [StatusRecord]) async throws {
        try await dbQueue.write { db in
            for status in statuses {
                try status.save(db)
            }
        }
    }

    func savePriorities(_ priorities: [PriorityRecord]) async throws {
        try await dbQueue.write { db in
            for priority in priorities {
                try priority.save(db)
            }
        }
    }

    func saveIssueTypes(_ types: [IssueTypeRecord]) async throws {
        try await dbQueue.write { db in
            for issueType in types {
                try issueType.save(db)
            }
        }
    }

    func saveUsers(_ users: [UserRecord]) async throws {
        try await dbQueue.write { db in
            for user in users {
                try user.save(db)
            }
        }
    }

    func allStatuses() async throws -> [StatusRecord] {
        try await dbQueue.read { db in
            try StatusRecord.fetchAll(db)
        }
    }

    func allPriorities() async throws -> [PriorityRecord] {
        try await dbQueue.read { db in
            try PriorityRecord.order(Column("sortOrder")).fetchAll(db)
        }
    }

    func allIssueTypes() async throws -> [IssueTypeRecord] {
        try await dbQueue.read { db in
            try IssueTypeRecord.fetchAll(db)
        }
    }

    func searchUsers(query: String) async throws -> [UserRecord] {
        try await dbQueue.read { db in
            try UserRecord
                .filter(Column("displayName").like("%\(query)%"))
                .filter(Column("active") == true)
                .fetchAll(db)
        }
    }

    // MARK: - Cleanup

    func clearAllData() async throws {
        try await dbQueue.write { db in
            try db.execute(sql: """
                DELETE FROM comments;
                DELETE FROM attachments;
                DELETE FROM board_columns;
                DELETE FROM boards;
                DELETE FROM issues;
                DELETE FROM projects;
                DELETE FROM pending_writes;
                DELETE FROM notifications;
                DELETE FROM sync_state;
                DELETE FROM statuses;
                DELETE FROM priorities;
                DELETE FROM issue_types;
                DELETE FROM users;
            """)
        }
    }
}
