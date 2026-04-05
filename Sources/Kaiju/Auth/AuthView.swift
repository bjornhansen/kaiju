import SwiftUI

/// Sign-in view with Atlassian OAuth
struct AuthView: View {
    let authManager: AuthManager

    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var showSiteSelector = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon and name
            VStack(spacing: 12) {
                Image(systemName: "lizard.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.accent)

                Text("Kaiju")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("A native Jira client for macOS")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Sign in button
            Button(action: {
                Task { await signIn() }
            }) {
                HStack(spacing: 8) {
                    if isSigningIn {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(isSigningIn ? "Signing in..." : "Sign in with Atlassian")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 240, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSigningIn)

            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            Spacer()
        }
        .frame(minWidth: 400, minHeight: 300)
        .sheet(isPresented: $showSiteSelector) {
            SiteSelectorView(
                sites: authManager.availableSites,
                onSelect: { site in
                    Task {
                        try? await authManager.selectSite(site)
                        showSiteSelector = false
                    }
                }
            )
        }
    }

    private func signIn() async {
        isSigningIn = true
        errorMessage = nil

        do {
            try await authManager.signIn()

            // If multiple sites, show selector
            if authManager.availableSites.count > 1 {
                showSiteSelector = true
            }
        } catch {
            errorMessage = "Sign-in failed. Please try again."
        }

        isSigningIn = false
    }
}

/// Site selector for users with access to multiple Jira sites
struct SiteSelectorView: View {
    let sites: [JiraSite]
    let onSelect: (JiraSite) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Select a Jira Site")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You have access to multiple sites. Choose one to connect.")
                .foregroundStyle(.secondary)

            List(sites) { site in
                Button(action: { onSelect(site) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(site.name)
                                .fontWeight(.medium)
                            Text(site.url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .frame(minHeight: 200)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}
