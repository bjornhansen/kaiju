import Foundation
import os

/// ViewModel for the project sidebar
@Observable
@MainActor
final class ProjectListViewModel {
    private(set) var projects: [ProjectRecord] = []
    private(set) var recentProjects: [ProjectRecord] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var selectedProjectKey: String?

    private let store: LocalStoreProtocol
    private let syncEngine: SyncEngine
    private let logger = KaijuLogger.ui

    init(store: LocalStoreProtocol, syncEngine: SyncEngine) {
        self.store = store
        self.syncEngine = syncEngine
    }

    /// Load projects from local store, then sync
    func loadProjects() async {
        isLoading = true

        do {
            // Load from cache first
            projects = try await store.allProjects()

            // Sync in background
            await syncEngine.requestSync(scope: .allProjects)

            // Reload after sync
            projects = try await store.allProjects()
        } catch {
            errorMessage = "Failed to load projects"
        }

        isLoading = false
    }

    /// Filter projects by search text. Archived projects are always excluded.
    func filteredProjects(searchText: String) -> [ProjectRecord] {
        let active = projects.filter { $0.archived != true }
        guard !searchText.isEmpty else { return active }
        let lower = searchText.lowercased()
        return active.filter {
            $0.name.lowercased().contains(lower) || $0.key.lowercased().contains(lower)
        }
    }
}
