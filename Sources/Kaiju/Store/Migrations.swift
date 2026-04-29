import Foundation
import GRDB

enum DatabaseMigrator {
    static func createMigrator() -> GRDB.DatabaseMigrator {
        var migrator = GRDB.DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1_initial") { db in
            // Sync metadata
            try db.create(table: "sync_state") { t in
                t.primaryKey("scope", .text)
                t.column("lastSyncedAt", .text).notNull()
                t.column("etag", .text)
            }

            // Projects
            try db.create(table: "projects") { t in
                t.primaryKey("id", .text)
                t.column("key", .text).notNull().unique()
                t.column("name", .text).notNull()
                t.column("avatarUrl", .text)
                t.column("projectType", .text)
                t.column("style", .text)
                t.column("updatedAt", .text)
            }

            // Boards
            try db.create(table: "boards") { t in
                t.primaryKey("id", .integer)
                t.column("name", .text).notNull()
                t.column("type", .text).notNull()
                t.column("projectKey", .text).references("projects", column: "key")
            }

            // Board columns
            try db.create(table: "board_columns") { t in
                t.autoIncrementedPrimaryKey("rowId")
                t.column("boardId", .integer).notNull().references("boards")
                t.column("name", .text).notNull()
                t.column("sortOrder", .integer).notNull()
                t.column("statusIds", .text).notNull()
            }

            // Issues
            try db.create(table: "issues") { t in
                t.primaryKey("id", .text)
                t.column("key", .text).notNull().unique()
                t.column("summary", .text).notNull()
                t.column("descriptionAdf", .text)
                t.column("statusId", .text)
                t.column("statusName", .text)
                t.column("statusCategory", .text)
                t.column("priorityId", .text)
                t.column("priorityName", .text)
                t.column("issueTypeId", .text)
                t.column("issueTypeName", .text)
                t.column("assigneeAccountId", .text)
                t.column("assigneeDisplayName", .text)
                t.column("assigneeAvatarUrl", .text)
                t.column("reporterAccountId", .text)
                t.column("reporterDisplayName", .text)
                t.column("projectKey", .text).notNull()
                t.column("labels", .text)
                t.column("sprintId", .integer)
                t.column("rank", .text)
                t.column("storyPoints", .double)
                t.column("createdAt", .text)
                t.column("updatedAt", .text)
            }

            try db.create(index: "idx_issues_project", on: "issues", columns: ["projectKey"])
            try db.create(index: "idx_issues_status", on: "issues", columns: ["statusId"])
            try db.create(index: "idx_issues_assignee", on: "issues", columns: ["assigneeAccountId"])
            try db.create(index: "idx_issues_updated", on: "issues", columns: ["updatedAt"])

            // Comments
            try db.create(table: "comments") { t in
                t.primaryKey("id", .text)
                t.column("issueId", .text).notNull().references("issues")
                t.column("authorAccountId", .text)
                t.column("authorDisplayName", .text)
                t.column("authorAvatarUrl", .text)
                t.column("bodyAdf", .text)
                t.column("createdAt", .text)
                t.column("updatedAt", .text)
            }

            // Attachments
            try db.create(table: "attachments") { t in
                t.primaryKey("id", .text)
                t.column("issueId", .text).notNull().references("issues")
                t.column("filename", .text).notNull()
                t.column("mimeType", .text)
                t.column("size", .integer)
                t.column("contentUrl", .text)
                t.column("thumbnailUrl", .text)
                t.column("authorDisplayName", .text)
                t.column("createdAt", .text)
            }

            // Pending writes (sync queue)
            try db.create(table: "pending_writes") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("operation", .text).notNull()
                t.column("endpoint", .text).notNull()
                t.column("method", .text).notNull()
                t.column("body", .text).notNull()
                t.column("createdAt", .text).notNull()
                t.column("retryCount", .integer).defaults(to: 0)
                t.column("lastError", .text)
                t.column("issueKey", .text)
            }

            // Notification inbox
            try db.create(table: "notifications") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("eventType", .text).notNull()
                t.column("issueKey", .text).notNull()
                t.column("issueSummary", .text)
                t.column("actorDisplayName", .text)
                t.column("actorAvatarUrl", .text)
                t.column("detail", .text)
                t.column("isRead", .boolean).defaults(to: false)
                t.column("createdAt", .text).notNull()
            }

            try db.create(index: "idx_notifications_unread", on: "notifications", columns: ["isRead", "createdAt"])

            // Reference data
            try db.create(table: "statuses") { t in
                t.primaryKey("id", .text)
                t.column("name", .text)
                t.column("category", .text)
                t.column("iconUrl", .text)
            }

            try db.create(table: "priorities") { t in
                t.primaryKey("id", .text)
                t.column("name", .text)
                t.column("iconUrl", .text)
                t.column("sortOrder", .integer)
            }

            try db.create(table: "issue_types") { t in
                t.primaryKey("id", .text)
                t.column("name", .text)
                t.column("iconUrl", .text)
                t.column("subtask", .boolean).defaults(to: false)
            }

            try db.create(table: "users") { t in
                t.primaryKey("accountId", .text)
                t.column("displayName", .text)
                t.column("avatarUrl", .text)
                t.column("active", .boolean).defaults(to: true)
            }
        }

        migrator.registerMigration("v2_archived_and_duedate") { db in
            try db.alter(table: "projects") { t in
                t.add(column: "archived", .boolean).defaults(to: false)
            }
            try db.alter(table: "issues") { t in
                t.add(column: "dueDate", .text)
            }
        }

        return migrator
    }
}
