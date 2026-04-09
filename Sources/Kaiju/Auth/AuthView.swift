import SwiftUI

/// Sign-in view with Jira API token authentication
struct AuthView: View {
    let authManager: AuthManager

    @State private var jiraURL = ""
    @State private var email = ""
    @State private var apiToken = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon and name
            VStack(spacing: 12) {
                Image(systemName: "lizard.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("Kaiju")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("A native Jira client for macOS")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Login form
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Jira URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("https://yoursite.atlassian.net or paste any Jira link", text: $jiraURL)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("you@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("API Token")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Link("Create one", destination: URL(string: "https://id.atlassian.com/manage-profile/security/api-tokens")!)
                            .font(.caption)
                    }
                    SecureField("Paste your API token", text: $apiToken)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(maxWidth: 360)

            // Sign in button
            Button(action: {
                Task { await signIn() }
            }) {
                HStack(spacing: 8) {
                    if isSigningIn {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(isSigningIn ? "Connecting..." : "Sign In")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 240, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSigningIn || jiraURL.isEmpty || email.isEmpty || apiToken.isEmpty)

            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .frame(maxWidth: 360)
            }

            Spacer()
        }
        .frame(minWidth: 500, minHeight: 450)
        .padding()
    }

    private func signIn() async {
        isSigningIn = true
        errorMessage = nil

        do {
            try await authManager.signIn(jiraURL: jiraURL, email: email, apiToken: apiToken)
        } catch {
            // AuthManager already sets error state, but show it in the view too
            if case .error(let msg) = authManager.state {
                errorMessage = msg
            } else {
                errorMessage = "Connection failed. Check your credentials and try again."
            }
        }

        isSigningIn = false
    }
}
