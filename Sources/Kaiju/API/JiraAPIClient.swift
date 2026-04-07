import Foundation
import os

/// Errors from the Jira API client
enum JiraAPIError: Error, Sendable {
    case notAuthenticated
    case invalidURL(String)
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case networkError(Error)
    case transitionFailed(statusCode: Int, message: String?)
}

/// Protocol for the Jira API client, enabling mocking in tests
protocol JiraAPIClientProtocol: Sendable {
    // MARK: - Auth
    func fetchAccessibleResources(accessToken: String) async throws -> [APIAccessibleResource]
    func exchangeCodeForTokens(code: String, clientId: String, clientSecret: String, redirectURI: String) async throws -> APIOAuthTokenResponse
    func refreshTokens(refreshToken: String, clientId: String, clientSecret: String) async throws -> APIOAuthTokenResponse

    // MARK: - Current User
    func fetchMyself() async throws -> APIUser

    // MARK: - Projects
    func fetchProjects() async throws -> [APIProject]
    func fetchRecentProjects() async throws -> [APIProject]

    // MARK: - Boards
    func fetchBoards(projectKey: String?) async throws -> [APIBoard]
    func fetchBoardConfiguration(boardId: Int) async throws -> APIBoardConfiguration
    func fetchBoardIssues(boardId: Int, startAt: Int, maxResults: Int, fields: String?) async throws -> APIBoardIssueList

    // MARK: - Issues
    func fetchIssue(key: String, fields: String?) async throws -> APIIssue
    func createIssue(body: Data) async throws -> APIIssue
    func updateIssue(key: String, body: Data) async throws
    func fetchTransitions(issueKey: String) async throws -> [APITransition]
    func performTransition(issueKey: String, transitionId: String) async throws

    // MARK: - Comments
    func fetchComments(issueKey: String, startAt: Int, maxResults: Int) async throws -> APICommentPage
    func addComment(issueKey: String, body: ADFDocument) async throws -> APIComment

    // MARK: - Search
    func searchJQL(jql: String, startAt: Int, maxResults: Int, fields: String?) async throws -> APISearchResult

    // MARK: - Reference Data
    func fetchPriorities() async throws -> [APIPriority]
    func fetchStatuses() async throws -> [APIStatus]
    func fetchIssueTypes() async throws -> [APIIssueType]
    func fetchAssignableUsers(projectKey: String, query: String?) async throws -> [APIUser]

    // MARK: - Webhooks
    func registerWebhooks(body: Data) async throws -> Data
    func refreshWebhooks(webhookIds: [Int]) async throws
}

/// Live Jira API client using URLSession
final class JiraAPIClient: JiraAPIClientProtocol, @unchecked Sendable {
    private let rateLimiter: RateLimiter
    private let session: URLSession
    private let logger = Logger(subsystem: "com.kaiju.app", category: "JiraAPIClient")

    /// Cloud ID for the connected Jira site. Set after OAuth completes.
    var cloudId: String?

    /// Closure to get current access token. Set by AuthManager.
    var accessTokenProvider: (@Sendable () async throws -> String)?

    init(
        rateLimiter: RateLimiter = RateLimiter(),
        session: URLSession = .shared
    ) {
        self.rateLimiter = rateLimiter
        self.session = session
    }

    // MARK: - Private helpers

    private func makeRequest(
        url urlString: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw JiraAPIError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            guard let provider = accessTokenProvider else {
                throw JiraAPIError.notAuthenticated
            }
            let token = try await provider()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        return request
    }

    private func performRequest<T: Decodable>(
        url: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = try await makeRequest(
            url: url,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )

        let (data, response) = try await rateLimiter.execute(request: request, session: session)

        guard (200...299).contains(response.statusCode) else {
            throw JiraAPIError.httpError(statusCode: response.statusCode, data: data)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw JiraAPIError.decodingError(error)
        }
    }

    private func performVoidRequest(
        url: String,
        method: String = "POST",
        body: Data? = nil
    ) async throws {
        let request = try await makeRequest(url: url, method: method, body: body)
        let (data, response) = try await rateLimiter.execute(request: request, session: session)

        guard (200...299).contains(response.statusCode) else {
            throw JiraAPIError.httpError(statusCode: response.statusCode, data: data)
        }
    }

    private func requireCloudId() throws -> String {
        guard let cloudId = cloudId else {
            throw JiraAPIError.notAuthenticated
        }
        return cloudId
    }

    // MARK: - Auth

    func fetchAccessibleResources(accessToken: String) async throws -> [APIAccessibleResource] {
        var request = URLRequest(url: URL(string: JiraEndpoints.accessibleResources)!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await rateLimiter.execute(request: request, session: session)
        guard (200...299).contains(response.statusCode) else {
            throw JiraAPIError.httpError(statusCode: response.statusCode, data: data)
        }
        return try JSONDecoder().decode([APIAccessibleResource].self, from: data)
    }

    func exchangeCodeForTokens(
        code: String,
        clientId: String,
        clientSecret: String,
        redirectURI: String
    ) async throws -> APIOAuthTokenResponse {
        let body: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": redirectURI,
        ]
        let bodyData = try JSONEncoder().encode(body)

        return try await performRequest(
            url: JiraEndpoints.tokenEndpoint,
            method: "POST",
            body: bodyData,
            requiresAuth: false
        )
    }

    func refreshTokens(
        refreshToken: String,
        clientId: String,
        clientSecret: String
    ) async throws -> APIOAuthTokenResponse {
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
        ]
        let bodyData = try JSONEncoder().encode(body)

        return try await performRequest(
            url: JiraEndpoints.tokenEndpoint,
            method: "POST",
            body: bodyData,
            requiresAuth: false
        )
    }

    // MARK: - Current User

    func fetchMyself() async throws -> APIUser {
        let cid = try requireCloudId()
        return try await performRequest(url: JiraEndpoints.myself(cloudId: cid))
    }

    // MARK: - Projects

    func fetchProjects() async throws -> [APIProject] {
        let cid = try requireCloudId()
        return try await performRequest(url: JiraEndpoints.projects(cloudId: cid))
    }

    func fetchRecentProjects() async throws -> [APIProject] {
        let cid = try requireCloudId()
        return try await performRequest(url: JiraEndpoints.recentProjects(cloudId: cid))
    }

    // MARK: - Boards

    func fetchBoards(projectKey: String?) async throws -> [APIBoard] {
        let cid = try requireCloudId()
        var urlString = JiraEndpoints.boards(cloudId: cid)
        if let pk = projectKey {
            urlString += "?projectKeyOrId=\(pk)"
        }
        let result: APIBoardList = try await performRequest(url: urlString)
        return result.values
    }

    func fetchBoardConfiguration(boardId: Int) async throws -> APIBoardConfiguration {
        let cid = try requireCloudId()
        return try await performRequest(
            url: JiraEndpoints.boardConfiguration(cloudId: cid, boardId: boardId)
        )
    }

    func fetchBoardIssues(
        boardId: Int,
        startAt: Int = 0,
        maxResults: Int = 50,
        fields: String? = nil
    ) async throws -> APIBoardIssueList {
        let cid = try requireCloudId()
        var urlString = JiraEndpoints.boardIssues(cloudId: cid, boardId: boardId)
        urlString += "?startAt=\(startAt)&maxResults=\(maxResults)"
        if let f = fields {
            urlString += "&fields=\(f)"
        }
        return try await performRequest(url: urlString)
    }

    // MARK: - Issues

    func fetchIssue(key: String, fields: String? = nil) async throws -> APIIssue {
        let cid = try requireCloudId()
        var urlString = JiraEndpoints.issue(cloudId: cid, key: key)
        if let f = fields {
            urlString += "?fields=\(f)"
        }
        return try await performRequest(url: urlString)
    }

    func createIssue(body: Data) async throws -> APIIssue {
        let cid = try requireCloudId()
        return try await performRequest(
            url: JiraEndpoints.createIssue(cloudId: cid),
            method: "POST",
            body: body
        )
    }

    func updateIssue(key: String, body: Data) async throws {
        let cid = try requireCloudId()
        try await performVoidRequest(
            url: JiraEndpoints.issue(cloudId: cid, key: key),
            method: "PUT",
            body: body
        )
    }

    func fetchTransitions(issueKey: String) async throws -> [APITransition] {
        let cid = try requireCloudId()
        let result: APITransitionList = try await performRequest(
            url: JiraEndpoints.transitions(cloudId: cid, issueKey: issueKey)
        )
        return result.transitions
    }

    func performTransition(issueKey: String, transitionId: String) async throws {
        let cid = try requireCloudId()
        let body = try JSONEncoder().encode(["transition": ["id": transitionId]])
        try await performVoidRequest(
            url: JiraEndpoints.transitions(cloudId: cid, issueKey: issueKey),
            method: "POST",
            body: body
        )
    }

    // MARK: - Comments

    func fetchComments(
        issueKey: String,
        startAt: Int = 0,
        maxResults: Int = 50
    ) async throws -> APICommentPage {
        let cid = try requireCloudId()
        let urlString = JiraEndpoints.comments(cloudId: cid, issueKey: issueKey)
            + "?startAt=\(startAt)&maxResults=\(maxResults)"
        return try await performRequest(url: urlString)
    }

    func addComment(issueKey: String, body: ADFDocument) async throws -> APIComment {
        let cid = try requireCloudId()
        let requestBody = try JSONEncoder().encode(["body": body])
        return try await performRequest(
            url: JiraEndpoints.comments(cloudId: cid, issueKey: issueKey),
            method: "POST",
            body: requestBody
        )
    }

    // MARK: - Search

    func searchJQL(
        jql: String,
        startAt: Int = 0,
        maxResults: Int = 50,
        fields: String? = nil
    ) async throws -> APISearchResult {
        let cid = try requireCloudId()
        let urlString = JiraEndpoints.searchJQL(cloudId: cid)
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "jql", value: jql),
            URLQueryItem(name: "startAt", value: String(startAt)),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
        ]
        if let f = fields {
            components.queryItems?.append(URLQueryItem(name: "fields", value: f))
        }
        return try await performRequest(url: components.url!.absoluteString)
    }

    // MARK: - Reference Data

    func fetchPriorities() async throws -> [APIPriority] {
        let cid = try requireCloudId()
        return try await performRequest(url: JiraEndpoints.priorities(cloudId: cid))
    }

    func fetchStatuses() async throws -> [APIStatus] {
        let cid = try requireCloudId()
        return try await performRequest(url: JiraEndpoints.statuses(cloudId: cid))
    }

    func fetchIssueTypes() async throws -> [APIIssueType] {
        let cid = try requireCloudId()
        return try await performRequest(url: JiraEndpoints.issueTypes(cloudId: cid))
    }

    func fetchAssignableUsers(projectKey: String, query: String? = nil) async throws -> [APIUser] {
        let cid = try requireCloudId()
        var urlString = JiraEndpoints.assignableUsers(cloudId: cid) + "?project=\(projectKey)"
        if let q = query {
            urlString += "&query=\(q)"
        }
        return try await performRequest(url: urlString)
    }

    // MARK: - Webhooks

    func registerWebhooks(body: Data) async throws -> Data {
        let cid = try requireCloudId()
        let request = try await makeRequest(
            url: JiraEndpoints.webhooks(cloudId: cid),
            method: "POST",
            body: body
        )
        let (data, response) = try await rateLimiter.execute(request: request, session: session)
        guard (200...299).contains(response.statusCode) else {
            throw JiraAPIError.httpError(statusCode: response.statusCode, data: data)
        }
        return data
    }

    func refreshWebhooks(webhookIds: [Int]) async throws {
        let cid = try requireCloudId()
        let body = try JSONEncoder().encode(["webhookIds": webhookIds])
        try await performVoidRequest(
            url: JiraEndpoints.refreshWebhooks(cloudId: cid),
            method: "PUT",
            body: body
        )
    }
}
