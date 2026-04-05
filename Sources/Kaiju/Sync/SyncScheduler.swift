import Foundation
import os

/// Schedules periodic background syncs.
/// Suppresses polling when webhooks are active.
actor SyncScheduler {
    private let syncEngine: SyncEngine
    private let logger = KaijuLogger.sync

    /// Polling interval in seconds (default 2 minutes)
    let pollInterval: TimeInterval

    private var timerTask: Task<Void, Never>?
    private var isRunning = false

    /// Scopes to sync on each poll cycle
    private var activeScopes: [SyncScope] = []

    init(syncEngine: SyncEngine, pollInterval: TimeInterval = 120) {
        self.syncEngine = syncEngine
        self.pollInterval = pollInterval
    }

    /// Start the scheduler with the given scopes
    func start(scopes: [SyncScope]) {
        activeScopes = scopes
        guard !isRunning else { return }
        isRunning = true

        timerTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.pollInterval * 1_000_000_000))

                guard !Task.isCancelled else { break }

                // Skip polling if webhooks are active
                let webhooksActive = await self.syncEngine.webhooksActive
                if webhooksActive {
                    self.logger.debug("Polling suppressed — webhooks active")
                    continue
                }

                await self.pollOnce()
            }
        }

        logger.info("Sync scheduler started with \(scopes.count) scopes, interval \(self.pollInterval)s")
    }

    /// Stop the scheduler
    func stop() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        logger.info("Sync scheduler stopped")
    }

    /// Update the active scopes
    func updateScopes(_ scopes: [SyncScope]) {
        activeScopes = scopes
    }

    /// Trigger an immediate sync for all active scopes
    func syncNow() async {
        await pollOnce()
    }

    private func pollOnce() async {
        for scope in activeScopes {
            await syncEngine.requestSync(scope: scope)
        }
    }
}
