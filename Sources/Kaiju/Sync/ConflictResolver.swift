import Foundation
import os

/// Conflict resolution strategy for sync conflicts.
/// MVP uses last-write-wins: remote always wins, user is notified.
struct ConflictResolver: Sendable {
    private let logger = KaijuLogger.sync

    enum Resolution: Sendable {
        case useRemote
        case useLocal
        case merge
    }

    /// Resolve a conflict between local and remote versions of an issue.
    /// MVP: Remote always wins.
    func resolve(
        local: IssueRecord,
        remote: IssueRecord
    ) -> Resolution {
        // For MVP, remote (server) always wins
        // In future versions, we could compare field-level timestamps
        logger.info("Conflict for \(local.key): using remote version")
        return .useRemote
    }

    /// Check if an issue has a pending local write that should prevent overwriting
    func hasPendingWrite(issueKey: String, pendingWrites: [PendingWriteRecord]) -> Bool {
        pendingWrites.contains { $0.issueKey == issueKey }
    }
}
