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
        .windowStyle(.hiddenTitleBar)
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
            }

            CommandGroup(after: .windowArrangement) {
                OpenVibrancyPreviewButton()
            }
        }

        Window("Vibrancy Preview", id: "vibrancy-preview") {
            VibrancyView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
    }
}

/// Menu-bar button that opens the Vibrancy design preview window. Wrapped in
/// its own view so we can pull `openWindow` from the environment.
private struct OpenVibrancyPreviewButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Vibrancy Preview") {
            openWindow(id: "vibrancy-preview")
        }
        .keyboardShortcut("0", modifiers: [.command, .option])
    }
}

/// Main content view that switches between auth and main app
struct ContentView: View {
    @Bindable var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

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
        .containerBackground(for: .window) {
            VibrancyTokens.wallpaper(for: colorScheme)
        }
    }
}

/// Main app layout — Vibrancy variation: floating inset sidebar + board, with
/// an `.inspector` panel that slides in from the right when an issue is selected.
struct MainAppView: View {
    @Bindable var appState: AppState
    let siteName: String

    private var inspecting: Binding<Bool> {
        Binding(
            get: { appState.selectedIssueKey != nil },
            set: { newValue in
                if !newValue { appState.selectedIssueKey = nil }
            }
        )
    }

    var body: some View {
        NavigationSplitView {
            ProjectSidebarView(
                viewModel: appState.projectListVM,
                notificationViewModel: appState.notificationInboxVM,
                siteName: siteName,
                onSignOut: signOut
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 232, max: 280)
            .toolbar(removing: .sidebarToggle)
            .scrollContentBackground(.hidden)
        } detail: {
            BoardView(
                viewModel: appState.boardVM,
                onIssueSelected: { key in
                    appState.selectedIssueKey = key
                },
                onCreateIssue: { appState.showCreateIssue = true },
                onSearchToggle: { appState.showSearch.toggle() }
            )
            .scrollContentBackground(.hidden)
            .inspector(isPresented: inspecting) {
                IssueDetailView(
                    viewModel: appState.issueDetailVM,
                    onClose: { appState.selectedIssueKey = nil }
                )
                .inspectorColumnWidth(min: 320, ideal: 400, max: 600)
            }
        }
        .navigationSplitViewStyle(.balanced)
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

    private func signOut() {
        Task {
            await appState.stopServices()
            try? await appState.authManager.signOut()
        }
    }
}
