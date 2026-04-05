import Foundation
import os

/// Manages the queue of pending write operations with retry logic
actor SyncQueue {
    private let logger = KaijuLogger.sync
    private let maxRetries: Int

    init(maxRetries: Int = 5) {
        self.maxRetries = maxRetries
    }

    /// Determine if a pending write should be retried
    func shouldRetry(_ write: PendingWriteRecord) -> Bool {
        write.retryCount < maxRetries
    }

    /// Calculate delay for next retry attempt (exponential backoff)
    func retryDelay(for write: PendingWriteRecord) -> TimeInterval {
        let base = pow(2.0, Double(write.retryCount))
        let jitter = Double.random(in: 0...1)
        return min(base + jitter, 60)
    }

    /// Create an updated write record after a failure
    func markRetry(_ write: PendingWriteRecord, error: String) -> PendingWriteRecord {
        var updated = write
        updated.retryCount += 1
        updated.lastError = error
        return updated
    }
}
