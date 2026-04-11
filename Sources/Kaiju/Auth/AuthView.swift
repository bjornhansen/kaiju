import SwiftUI

/// Sign-in view with Jira API token authentication
struct AuthView: View {
    let authManager: AuthManager

    @State private var jiraURL = ""
    @State private var email = ""
    @State private var apiToken = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    private enum Field: Hashable {
        case jiraURL, email, apiToken
    }
    @FocusState private var focusedField: Field?

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
            Form {
                TextField("Jira URL", text: $jiraURL, prompt: Text("https://yoursite.atlassian.net or paste any Jira link"))
                    .focused($focusedField, equals: .jiraURL)

                TextField("Email", text: $email, prompt: Text("you@example.com"))
                    .focused($focusedField, equals: .email)
                    .textContentType(.emailAddress)

                HStack {
                    SecureField("API Token", text: $apiToken, prompt: Text("Paste your API token"))
                        .focused($focusedField, equals: .apiToken)
                    Link("Create one", destination: URL(string: "https://id.atlassian.com/manage-profile/security/api-tokens")!)
                        .font(.callout)
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: 420, maxHeight: 180)
            .onSubmit {
                // Tab through fields, then sign in
                switch focusedField {
                case .jiraURL: focusedField = .email
                case .email: focusedField = .apiToken
                case .apiToken, .none:
                    if !jiraURL.isEmpty && !email.isEmpty && !apiToken.isEmpty {
                        Task { await signIn() }
                    }
                }
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
        .frame(minWidth: 500, minHeight: 500)
        .padding()
        .onAppear {
            focusedField = .jiraURL
        }
    }

    private func signIn() async {
        isSigningIn = true
        errorMessage = nil

        do {
            try await authManager.signIn(jiraURL: jiraURL, email: email, apiToken: apiToken)
        } catch {
            if case .error(let msg) = authManager.state {
                errorMessage = msg
            } else {
                errorMessage = "Connection failed. Check your credentials and try again."
            }
        }

        isSigningIn = false
    }
}
