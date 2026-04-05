import XCTest
@testable import Kaiju

final class SyncEngineTests: XCTestCase {

    func test_conflict_resolver_uses_remote_by_default() {
        let resolver = ConflictResolver()
        let local = makeTestIssue(key: "KAI-1", statusName: "To Do")
        let remote = makeTestIssue(key: "KAI-1", statusName: "Done")

        let resolution = resolver.resolve(local: local, remote: remote)

        switch resolution {
        case .useRemote:
            break  // Expected
        default:
            XCTFail("Expected .useRemote resolution")
        }
    }

    func test_conflict_resolver_detects_pending_write() {
        let resolver = ConflictResolver()
        let writes = [
            PendingWriteRecord(
                id: 1, operation: "transition", endpoint: "issue/KAI-1/transitions",
                method: "POST", body: "{}", createdAt: "2024-01-01T00:00:00Z",
                retryCount: 0, lastError: nil, issueKey: "KAI-1"
            )
        ]

        XCTAssertTrue(resolver.hasPendingWrite(issueKey: "KAI-1", pendingWrites: writes))
        XCTAssertFalse(resolver.hasPendingWrite(issueKey: "KAI-2", pendingWrites: writes))
    }

    func test_sync_queue_retry_logic() async {
        let queue = SyncQueue(maxRetries: 3)

        let write = PendingWriteRecord(
            id: 1, operation: "update", endpoint: "issue/KAI-1",
            method: "PUT", body: "{}", createdAt: "2024-01-01T00:00:00Z",
            retryCount: 0, lastError: nil, issueKey: "KAI-1"
        )

        let shouldRetry = await queue.shouldRetry(write)
        XCTAssertTrue(shouldRetry)

        var failedWrite = write
        failedWrite.retryCount = 3
        let shouldNotRetry = await queue.shouldRetry(failedWrite)
        XCTAssertFalse(shouldNotRetry)
    }

    func test_sync_queue_exponential_backoff() async {
        let queue = SyncQueue()

        var write = PendingWriteRecord(
            id: 1, operation: "update", endpoint: "issue/KAI-1",
            method: "PUT", body: "{}", createdAt: "2024-01-01T00:00:00Z",
            retryCount: 0, lastError: nil, issueKey: nil
        )

        let delay0 = await queue.retryDelay(for: write)
        write.retryCount = 1
        let delay1 = await queue.retryDelay(for: write)
        write.retryCount = 2
        let delay2 = await queue.retryDelay(for: write)

        // Each retry should have increasing delay (with jitter)
        XCTAssertLessThanOrEqual(delay0, 2.0)  // 2^0 + jitter
        XCTAssertLessThanOrEqual(delay1, 3.0)  // 2^1 + jitter
        XCTAssertLessThanOrEqual(delay2, 5.0)  // 2^2 + jitter
    }

    // MARK: - Helpers

    private func makeTestIssue(key: String, statusName: String) -> IssueRecord {
        IssueRecord(
            id: "10001", key: key, summary: "Test", descriptionAdf: nil,
            statusId: "1", statusName: statusName, statusCategory: "new",
            priorityId: "3", priorityName: "Medium", issueTypeId: "10001",
            issueTypeName: "Task", assigneeAccountId: nil, assigneeDisplayName: nil,
            assigneeAvatarUrl: nil, reporterAccountId: nil, reporterDisplayName: nil,
            projectKey: "KAI", labels: nil, sprintId: nil, rank: nil,
            storyPoints: nil, createdAt: nil, updatedAt: nil
        )
    }
}
