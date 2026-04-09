import Foundation
import os

/// Authentication state
enum AuthState: Sendable, Equatable {
    case signedOut
    case signingIn
    case authenticated(siteURL: String, siteName: String)
    case error(String)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.signedOut, .signedOut): return true
        case (.signingIn, .signingIn): return true
        case let (.authenticated(lURL, lName), .authenticated(rURL, rName)):
            return lURL == rURL && lName == rName
        case let (.error(lMsg), .error(rMsg)): return lMsg == rMsg
        default: return false
        }
    }
}

/// Manages authentication using Jira API tokens (Basic auth).
/// User provides their Jira site URL, email, and an API token.
@Observable
final class AuthManager: @unchecked Sendable {

    private(set) var state: AuthState = .signedOut

    private let keychain: KeychainHelperProtocol
    private let apiClient: JiraAPIClient
    private let logger = KaijuLogger.auth

    init(keychain: KeychainHelperProtocol, apiClient: JiraAPIClient) {
        self.keychain = keychain
        self.apiClient = apiClient
    }

    /// Attempt to restore session from keychain on app launch
    func restoreSession() async {
        do {
            guard let siteURL = try keychain.load(key: KeychainKeys.siteUrl),
                  let email = try keychain.load(key: KeychainKeys.email),
                  let apiToken = try keychain.load(key: KeychainKeys.apiToken) else {
                state = .signedOut
                return
            }

            // Configure API client
            configureClient(siteURL: siteURL, email: email, apiToken: apiToken)

            // Validate credentials still work
            _ = try await apiClient.fetchMyself()

            let siteName = JiraEndpoints.siteName(from: siteURL)
            state = .authenticated(siteURL: siteURL, siteName: siteName)
        } catch {
            logger.error("Failed to restore session: \(error.localizedDescription)")
            // Clear stale credentials
            apiClient.siteURL = nil
            apiClient.authHeader = nil
            state = .signedOut
        }
    }

    /// Sign in with a Jira site URL, email, and API token.
    /// Validates credentials by fetching the current user.
    func signIn(jiraURL: String, email: String, apiToken: String) async throws {
        state = .signingIn

        // Parse the site URL from whatever the user pasted
        guard let siteURL = JiraEndpoints.parseSiteURL(from: jiraURL) else {
            state = .error("Invalid Jira URL. Paste your Jira URL, e.g. https://yoursite.atlassian.net")
            return
        }

        // Configure API client
        configureClient(siteURL: siteURL, email: email, apiToken: apiToken)

        // Validate by fetching current user
        do {
            let user = try await apiClient.fetchMyself()
            logger.info("Authenticated as \(user.displayName ?? "unknown")")
        } catch {
            apiClient.siteURL = nil
            apiClient.authHeader = nil
            state = .error("Authentication failed. Check your email and API token.")
            throw error
        }

        // Store credentials
        try keychain.save(key: KeychainKeys.siteUrl, value: siteURL)
        try keychain.save(key: KeychainKeys.email, value: email)
        try keychain.save(key: KeychainKeys.apiToken, value: apiToken)

        let siteName = JiraEndpoints.siteName(from: siteURL)
        state = .authenticated(siteURL: siteURL, siteName: siteName)
    }

    /// Sign out: clear credentials and local data
    func signOut() async throws {
        apiClient.siteURL = nil
        apiClient.authHeader = nil
        try keychain.deleteAll()
        state = .signedOut
        logger.info("Signed out")
    }

    // MARK: - Private

    private func configureClient(siteURL: String, email: String, apiToken: String) {
        apiClient.siteURL = siteURL
        let credentials = "\(email):\(apiToken)"
        apiClient.authHeader = Data(credentials.utf8).base64EncodedString()
    }
}
