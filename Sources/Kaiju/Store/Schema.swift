import Foundation
import GRDB

/// Database record types for GRDB persistence
/// Each struct maps to a SQLite table defined in migrations

struct ProjectRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "projects"

    var id: String
    var key: String
    var name: String
    var avatarUrl: String?
    var projectType: String?
    var style: String?
    var updatedAt: String?
}

struct BoardRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "boards"

    var id: Int
    var name: String
    var type: String
    var projectKey: String?
}

struct BoardColumnRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "board_columns"

    var boardId: Int
    var name: String
    var sortOrder: Int
    var statusIds: String  // JSON array of status IDs
}

struct IssueRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "issues"

    var id: String
    var key: String
    var summary: String
    var descriptionAdf: String?
    var statusId: String?
    var statusName: String?
    var statusCategory: String?
    var priorityId: String?
    var priorityName: String?
    var issueTypeId: String?
    var issueTypeName: String?
    var assigneeAccountId: String?
    var assigneeDisplayName: String?
    var assigneeAvatarUrl: String?
    var reporterAccountId: String?
    var reporterDisplayName: String?
    var projectKey: String
    var labels: String?  // JSON array
    var sprintId: Int?
    var rank: String?
    var storyPoints: Double?
    var createdAt: String?
    var updatedAt: String?
}

struct CommentRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "comments"

    var id: String
    var issueId: String
    var authorAccountId: String?
    var authorDisplayName: String?
    var authorAvatarUrl: String?
    var bodyAdf: String?
    var createdAt: String?
    var updatedAt: String?
}

struct AttachmentRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "attachments"

    var id: String
    var issueId: String
    var filename: String
    var mimeType: String?
    var size: Int?
    var contentUrl: String?
    var thumbnailUrl: String?
    var authorDisplayName: String?
    var createdAt: String?
}

struct PendingWriteRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "pending_writes"

    var id: Int64?
    var operation: String
    var endpoint: String
    var method: String
    var body: String
    var createdAt: String
    var retryCount: Int
    var lastError: String?
    var issueKey: String?
}

struct NotificationRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "notifications"

    var id: Int64?
    var eventType: String
    var issueKey: String
    var issueSummary: String?
    var actorDisplayName: String?
    var actorAvatarUrl: String?
    var detail: String?
    var isRead: Bool
    var createdAt: String
}

struct SyncStateRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "sync_state"

    var scope: String
    var lastSyncedAt: String
    var etag: String?
}

struct StatusRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "statuses"

    var id: String
    var name: String?
    var category: String?
    var iconUrl: String?
}

struct PriorityRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "priorities"

    var id: String
    var name: String?
    var iconUrl: String?
    var sortOrder: Int?
}

struct IssueTypeRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "issue_types"

    var id: String
    var name: String?
    var iconUrl: String?
    var subtask: Bool
}

struct UserRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "users"

    var accountId: String
    var displayName: String?
    var avatarUrl: String?
    var active: Bool
}

// Extend UserRecord to use accountId as primary key
extension UserRecord {
    static let persistenceConflictPolicy = PersistenceConflictPolicy(insert: .replace, update: .replace)
}
