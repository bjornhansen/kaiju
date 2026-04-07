import Foundation
#if canImport(AppKit)
import AppKit
#endif
import os

/// Authentication state
enum AuthState: Sendable, Equatable {
    case signedOut
    case signingIn
    case authenticated(cloudId: String, siteName: String)
    case refreshingToken
    case error(String)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.signedOut, .signedOut): return true
        case (.signingIn, .signingIn): return true
        case let (.authenticated(lId, lName), .authenticated(rId, rName)):
            return lId == rId && lName == rName
        case (.refreshingToken, .refreshingToken): return true
        case let (.error(lMsg), .error(rMsg)): return lMsg == rMsg
        default: return false
        }
    }
}

/// Accessible Jira site for site selection
struct JiraSite: Sendable, Identifiable {
    let id: String  // cloud_id
    let name: String
    let url: String
    let avatarUrl: String?
}

/// Protocol for auth management, enabling test mocking
protocol AuthManagerProtocol: Sendable {
    var state: AuthState { get }
    func signIn() async throws
    func selectSite(_ site: JiraSite) async throws
    func signOut() async throws
    func getAccessToken() async throws -> String
}

/// Manages OAuth 2.0 (3LO) authentication with Atlassian
@Observable
final class AuthManager: @unchecked Sendable {
    // OAuth configuration — replace with actual values
    static let clientId = "YOUR_CLIENT_ID"
    static let clientSecret = "YOUR_CLIENT_SECRET"
    static let redirectURI = "http://127.0.0.1:21456/oauth/callback"

    private(set) var state: AuthState = .signedOut
    private(set) var availableSites: [JiraSite] = []

    private let keychain: KeychainHelperProtocol
    private let apiClient: JiraAPIClientProtocol
    private let logger = KaijuLogger.auth

    private var tokenExpiryDate: Date?
    private var refreshTask: Task<String, Error>?

    init(keychain: KeychainHelperProtocol, apiClient: JiraAPIClientProtocol) {
        self.keychain = keychain
        self.apiClient = apiClient
    }

    /// Attempt to restore session from keychain on app launch
    func restoreSession() async {
        do {
            guard let accessToken = try keychain.load(key: KeychainKeys.accessToken),
                  let refreshToken = try keychain.load(key: KeychainKeys.refreshToken),
                  let cloudId = try keychain.load(key: KeychainKeys.cloudId),
                  let siteName = try keychain.load(key: KeychainKeys.siteName) else {
                state = .signedOut
                return
            }

            // Check if token needs refresh
            if let expiryString = try keychain.load(key: KeychainKeys.tokenExpiry),
               let expiry = TimeInterval(expiryString) {
                tokenExpiryDate = Date(timeIntervalSince1970: expiry)

                if Date().addingTimeInterval(5 * 60) >= tokenExpiryDate! {
                    // Token expired or about to expire, refresh it
                    _ = try await refreshAccessToken(
                        refreshToken: refreshToken,
                        cloudId: cloudId,
                        siteName: siteName
                    )
                }
            }

            state = .authenticated(cloudId: cloudId, siteName: siteName)
            _ = accessToken  // Token is valid and ready
        } catch {
            logger.error("Failed to restore session: \(error.localizedDescription)")
            state = .signedOut
        }
    }

    /// Initiate the OAuth sign-in flow
    func signIn() async throws {
        state = .signingIn

        // Generate random state for CSRF protection
        let stateParam = UUID().uuidString

        // Build authorization URL
        guard let authURL = JiraEndpoints.authorizeURL(
            clientId: Self.clientId,
            redirectURI: Self.redirectURI,
            state: stateParam
        ) else {
            state = .error("Failed to build authorization URL")
            return
        }

        // Start local callback server
        let callbackServer = OAuthCallbackServer()
        let callbackTask = Task {
            try await callbackServer.waitForCallback(expectedState: stateParam)
        }

        // Open browser for auth
        #if canImport(AppKit)
        await MainActor.run {
            NSWorkspace.shared.open(authURL)
        }
        #endif

        // Wait for callback
        let result: OAuthCallbackServer.OAuthCallbackResult
        do {
            result = try await callbackTask.value
        } catch {
            state = .error("Authentication was cancelled or failed")
            throw error
        }

        // Exchange code for tokens
        let tokenResponse = try await apiClient.exchangeCodeForTokens(
            code: result.code,
            clientId: Self.clientId,
            clientSecret: Self.clientSecret,
            redirectURI: Self.redirectURI
        )

        // Store tokens in keychain
        try storeTokens(tokenResponse)

        // Fetch accessible sites
        let resources = try await apiClient.fetchAccessibleResources(
            accessToken: tokenResponse.access_token
        )

        availableSites = resources.map { resource in
            JiraSite(
                id: resource.id,
                name: resource.name,
                url: resource.url,
                avatarUrl: resource.avatarUrl
            )
        }

        // If only one site, auto-select it
        if availableSites.count == 1 {
            try await selectSite(availableSites[0])
        }
        // Otherwise, UI will show site selector
    }

    /// Select a Jira site after sign-in
    func selectSite(_ site: JiraSite) async throws {
        try keychain.save(key: KeychainKeys.cloudId, value: site.id)
        try keychain.save(key: KeychainKeys.siteName, value: site.name)
        try keychain.save(key: KeychainKeys.siteUrl, value: site.url)

        state = .authenticated(cloudId: site.id, siteName: site.name)
        logger.info("Selected site: \(site.name) (\(site.id))")
    }

    /// Sign out: clear tokens and local data
    func signOut() async throws {
        try keychain.deleteAll()
        tokenExpiryDate = nil
        refreshTask = nil
        availableSites = []
        state = .signedOut
        logger.info("Signed out")
    }

    /// Get a valid access token, refreshing if needed
    func getAccessToken() async throws -> String {
        // If there's already a refresh in progress, await it
        if let task = refreshTask {
            return try await task.value
        }

        // Check if we have a token
        guard let token = try keychain.load(key: KeychainKeys.accessToken) else {
            throw JiraAPIError.notAuthenticated
        }

        // Proactive refresh: refresh when < 5 minutes remain
        if let expiry = tokenExpiryDate, Date().addingTimeInterval(5 * 60) >= expiry {
            guard let refreshToken = try keychain.load(key: KeychainKeys.refreshToken),
                  let cloudId = try keychain.load(key: KeychainKeys.cloudId),
                  let siteName = try keychain.load(key: KeychainKeys.siteName) else {
                try await signOut()
                throw JiraAPIError.notAuthenticated
            }

            return try await refreshAccessToken(
                refreshToken: refreshToken,
                cloudId: cloudId,
                siteName: siteName
            )
        }

        return token
    }

    // MARK: - Private

    private func refreshAccessToken(
        refreshToken: String,
        cloudId: String,
        siteName: String
    ) async throws -> String {
        // Deduplicate concurrent refresh calls
        if let task = refreshTask {
            return try await task.value
        }

        let task = Task<String, Error> {
            defer { refreshTask = nil }

            state = .refreshingToken

            do {
                let response = try await apiClient.refreshTokens(
                    refreshToken: refreshToken,
                    clientId: Self.clientId,
                    clientSecret: Self.clientSecret
                )

                // CRITICAL: Persist new refresh token BEFORE using new access token
                // Old refresh token is invalidated immediately
                try storeTokens(response)

                state = .authenticated(cloudId: cloudId, siteName: siteName)
                return response.access_token
            } catch {
                logger.error("Token refresh failed: \(error.localizedDescription)")
                try? await signOut()
                throw JiraAPIError.notAuthenticated
            }
        }

        refreshTask = task
        return try await task.value
    }

    private func storeTokens(_ response: APIOAuthTokenResponse) throws {
        // Store refresh token FIRST (critical ordering)
        if let refreshToken = response.refresh_token {
            try keychain.save(key: KeychainKeys.refreshToken, value: refreshToken)
        }

        try keychain.save(key: KeychainKeys.accessToken, value: response.access_token)

        let expiry = Date().addingTimeInterval(TimeInterval(response.expires_in))
        tokenExpiryDate = expiry
        try keychain.save(
            key: KeychainKeys.tokenExpiry,
            value: String(expiry.timeIntervalSince1970)
        )
    }
}
