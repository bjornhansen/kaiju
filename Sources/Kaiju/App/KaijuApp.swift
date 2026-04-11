import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@main
struct KaijuApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    // SPM executables aren't proper .app bundles, so macOS
                    // doesn't automatically make them foreground apps. Without
                    // this, the window appears but can't receive keyboard input.
                    #if canImport(AppKit)
                    NSApplication.shared.setActivationPolicy(.regular)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    #endif
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Issue") {
                    appState.showCreateIssue = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button("Refresh") {
                    Task { await appState.boardVM.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Search") {
                    appState.showSearch.toggle()
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("Notifications") {
                    // Toggle notification inbox
                }
                .keyboardShortcut("i", modifiers: .command)
            }
        }
    }
}

/// Main content view that switches between auth and main app
struct ContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        Group {
            switch appState.authManager.state {
            case .signedOut, .error:
                AuthView(authManager: appState.authManager)

            case .signingIn:
                VStack {
                    ProgressView("Connecting to Jira...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .authenticated(_, let siteName):
                MainAppView(appState: appState, siteName: siteName)
                    .task {
                        await appState.startServices()
                    }
            }
        }
        .task {
            await appState.authManager.restoreSession()
        }
    }
}

/// Main app layout with sidebar, board, and detail panel
struct MainAppView: View {
    @Bindable var appState: AppState
    let siteName: String

    var body: some View {
        NavigationSplitView {
            ProjectSidebarView(
                viewModel: appState.projectListVM,
                notificationViewModel: appState.notificationInboxVM
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } content: {
            BoardView(
                viewModel: appState.boardVM,
                onIssueSelected: { key in
                    appState.selectedIssueKey = key
                }
            )
            .navigationSplitViewColumnWidth(min: 500, ideal: 700)
        } detail: {
            IssueDetailView(viewModel: appState.issueDetailVM)
        }
        .navigationTitle("\(siteName) — Kaiju")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showSearch.toggle() }) {
                    Image(systemName: "magnifyingglass")
                }
                .keyboardShortcut("k", modifiers: .command)
                .help("Search (Cmd+K)")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showCreateIssue = true }) {
                    Image(systemName: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("New Issue (Cmd+N)")
            }

            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("Sign Out") {
                        Task {
                            await appState.stopServices()
                            try? await appState.authManager.signOut()
                        }
                    }
                } label: {
                    Image(systemName: "person.circle")
                }
            }
        }
        .sheet(isPresented: $appState.showCreateIssue) {
            CreateIssueView(
                viewModel: appState.createIssueVM,
                defaultProjectKey: appState.projectListVM.selectedProjectKey ?? ""
            )
        }
        .sheet(isPresented: $appState.showSearch) {
            SearchView(
                viewModel: appState.searchVM,
                onIssueSelected: { key in
                    appState.selectedIssueKey = key
                    appState.showSearch = false
                }
            )
            .frame(minWidth: 600, minHeight: 400)
        }
        .onChange(of: appState.projectListVM.selectedProjectKey) { _, newKey in
            if let key = newKey {
                Task { await appState.boardVM.loadBoards(projectKey: key) }
            }
        }
    }
}
