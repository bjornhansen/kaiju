import Foundation
import SwiftUI

/// Central app state that wires together all dependencies
@Observable
@MainActor
final class AppState {
    // MARK: - Core Dependencies
    let store: LocalStoreProtocol
    let apiClient: JiraAPIClient
    let authManager: AuthManager
    let syncEngine: SyncEngine
    let syncScheduler: SyncScheduler
    let notificationEngine: NotificationEngine
    let webhookEventHandler: WebhookEventHandler
    let webhookRegistrar: WebhookRegistrar
    let webhookSSEClient: WebhookSSEClient

    // MARK: - View Models
    let projectListVM: ProjectListViewModel
    let boardVM: BoardViewModel
    let issueDetailVM: IssueDetailViewModel
    let searchVM: SearchViewModel
    let createIssueVM: CreateIssueViewModel
    let notificationInboxVM: NotificationInboxViewModel

    // MARK: - UI State
    var showCreateIssue = false
    var showSearch = false
    var selectedIssueKey: String? {
        didSet {
            issueDetailVM.issueKey = selectedIssueKey
        }
    }

    init() {
        // Initialize core dependencies
        let store: LocalStoreProtocol
        do {
            let dbPath = AppState.databasePath()
            store = try LocalStore(path: dbPath)
        } catch {
            // Fallback to in-memory store if file creation fails
            store = try! LocalStore()
        }
        self.store = store

        let apiClient = JiraAPIClient()
        self.apiClient = apiClient

        let keychain = KeychainHelper()
        let authManager = AuthManager(keychain: keychain, apiClient: apiClient)
        self.authManager = authManager

        let syncEngine = SyncEngine(store: store, apiClient: apiClient)
        self.syncEngine = syncEngine

        let syncScheduler = SyncScheduler(syncEngine: syncEngine)
        self.syncScheduler = syncScheduler

        let notificationBridge = MacNotificationBridge()
        let notificationEngine = NotificationEngine(store: store, bridge: notificationBridge)
        self.notificationEngine = notificationEngine

        let webhookEventHandler = WebhookEventHandler(
            syncEngine: syncEngine,
            notificationEngine: notificationEngine
        )
        self.webhookEventHandler = webhookEventHandler

        let webhookRegistrar = WebhookRegistrar(
            apiClient: apiClient,
            relayBaseURL: "https://kaiju-relay.example.workers.dev"  // Configure per deployment
        )
        self.webhookRegistrar = webhookRegistrar

        let webhookSSEClient = WebhookSSEClient(
            relayURL: "https://kaiju-relay.example.workers.dev/events"  // Configure per deployment
        )
        self.webhookSSEClient = webhookSSEClient

        // Initialize ViewModels
        self.projectListVM = ProjectListViewModel(store: store, syncEngine: syncEngine)
        self.boardVM = BoardViewModel(store: store, syncEngine: syncEngine)
        self.issueDetailVM = IssueDetailViewModel(
            store: store,
            syncEngine: syncEngine,
            apiClient: apiClient
        )
        self.searchVM = SearchViewModel(store: store, apiClient: apiClient)
        self.createIssueVM = CreateIssueViewModel(
            store: store,
            apiClient: apiClient,
            syncEngine: syncEngine
        )

        let inboxStore = NotificationInboxStore(store: store)
        self.notificationInboxVM = NotificationInboxViewModel(inboxStore: inboxStore)

        // Wire up API client token provider
        apiClient.accessTokenProvider = { [weak authManager] in
            guard let auth = authManager else { throw JiraAPIError.notAuthenticated }
            return try await auth.getAccessToken()
        }
    }

    /// Start background services after authentication
    func startServices(cloudId: String) async {
        apiClient.cloudId = cloudId

        // Sync reference data first
        await syncEngine.requestSync(scope: .referenceData)
        await syncEngine.requestSync(scope: .allProjects)

        // Start periodic sync
        await syncScheduler.start(scopes: [.allProjects])

        // Request notification permissions
        _ = await MacNotificationBridge().requestPermission()

        // Set current user for notifications
        do {
            let myself = try await apiClient.fetchMyself()
            await notificationEngine.setCurrentUser(accountId: myself.accountId)
        } catch {
            // Non-fatal: notifications just won't filter correctly
        }
    }

    /// Stop all services (on sign-out)
    func stopServices() async {
        await syncScheduler.stop()
        await webhookSSEClient.disconnect()
        await webhookRegistrar.unregisterAll()
        try? await store.clearAllData()
    }

    /// Database file path in app container
    static func databasePath() -> String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("Kaiju", isDirectory: true)

        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        return appSupport.appendingPathComponent("kaiju.sqlite").path
    }
}

// Extension to set current user on NotificationEngine
extension NotificationEngine {
    func setCurrentUser(accountId: String) {
        self.currentUserAccountId = accountId
    }
}
