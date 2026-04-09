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

/// Live Jira API client using URLSession with Basic auth (API token)
final class JiraAPIClient: JiraAPIClientProtocol, @unchecked Sendable {
    private let rateLimiter: RateLimiter
    private let session: URLSession
    private let logger = Logger(subsystem: "com.kaiju.app", category: "JiraAPIClient")

    /// Site URL for the connected Jira instance (e.g. "https://mysite.atlassian.net")
    var siteURL: String?

    /// Base64-encoded "email:apiToken" for Basic auth. Set by AuthManager.
    var authHeader: String?

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
        body: Data? = nil
    ) async throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw JiraAPIError.invalidURL(urlString)
        }

        guard let auth = authHeader else {
            throw JiraAPIError.notAuthenticated
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        return request
    }

    private func performRequest<T: Decodable>(
        url: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        let request = try await makeRequest(url: url, method: method, body: body)
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

    private func requireSiteURL() throws -> String {
        guard let siteURL = siteURL else {
            throw JiraAPIError.notAuthenticated
        }
        return siteURL
    }

    // MARK: - Current User

    func fetchMyself() async throws -> APIUser {
        let site = try requireSiteURL()
        return try await performRequest(url: JiraEndpoints.myself(siteURL: site))
    }

    // MARK: - Projects

    func fetchProjects() async throws -> [APIProject] {
        let site = try requireSiteURL()
        return try await performRequest(url: JiraEndpoints.projects(siteURL: site))
    }

    func fetchRecentProjects() async throws -> [APIProject] {
        let site = try requireSiteURL()
        return try await performRequest(url: JiraEndpoints.recentProjects(siteURL: site))
    }

    // MARK: - Boards

    func fetchBoards(projectKey: String?) async throws -> [APIBoard] {
        let site = try requireSiteURL()
        var urlString = JiraEndpoints.boards(siteURL: site)
        if let pk = projectKey {
            urlString += "?projectKeyOrId=\(pk)"
        }
        let result: APIBoardList = try await performRequest(url: urlString)
        return result.values
    }

    func fetchBoardConfiguration(boardId: Int) async throws -> APIBoardConfiguration {
        let site = try requireSiteURL()
        return try await performRequest(
            url: JiraEndpoints.boardConfiguration(siteURL: site, boardId: boardId)
        )
    }

    func fetchBoardIssues(
        boardId: Int,
        startAt: Int = 0,
        maxResults: Int = 50,
        fields: String? = nil
    ) async throws -> APIBoardIssueList {
        let site = try requireSiteURL()
        var urlString = JiraEndpoints.boardIssues(siteURL: site, boardId: boardId)
        urlString += "?startAt=\(startAt)&maxResults=\(maxResults)"
        if let f = fields {
            urlString += "&fields=\(f)"
        }
        return try await performRequest(url: urlString)
    }

    // MARK: - Issues

    func fetchIssue(key: String, fields: String? = nil) async throws -> APIIssue {
        let site = try requireSiteURL()
        var urlString = JiraEndpoints.issue(siteURL: site, key: key)
        if let f = fields {
            urlString += "?fields=\(f)"
        }
        return try await performRequest(url: urlString)
    }

    func createIssue(body: Data) async throws -> APIIssue {
        let site = try requireSiteURL()
        return try await performRequest(
            url: JiraEndpoints.createIssue(siteURL: site),
            method: "POST",
            body: body
        )
    }

    func updateIssue(key: String, body: Data) async throws {
        let site = try requireSiteURL()
        try await performVoidRequest(
            url: JiraEndpoints.issue(siteURL: site, key: key),
            method: "PUT",
            body: body
        )
    }

    func fetchTransitions(issueKey: String) async throws -> [APITransition] {
        let site = try requireSiteURL()
        let result: APITransitionList = try await performRequest(
            url: JiraEndpoints.transitions(siteURL: site, issueKey: issueKey)
        )
        return result.transitions
    }

    func performTransition(issueKey: String, transitionId: String) async throws {
        let site = try requireSiteURL()
        let body = try JSONEncoder().encode(["transition": ["id": transitionId]])
        try await performVoidRequest(
            url: JiraEndpoints.transitions(siteURL: site, issueKey: issueKey),
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
        let site = try requireSiteURL()
        let urlString = JiraEndpoints.comments(siteURL: site, issueKey: issueKey)
            + "?startAt=\(startAt)&maxResults=\(maxResults)"
        return try await performRequest(url: urlString)
    }

    func addComment(issueKey: String, body: ADFDocument) async throws -> APIComment {
        let site = try requireSiteURL()
        let requestBody = try JSONEncoder().encode(["body": body])
        return try await performRequest(
            url: JiraEndpoints.comments(siteURL: site, issueKey: issueKey),
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
        let site = try requireSiteURL()
        let urlString = JiraEndpoints.searchJQL(siteURL: site)
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
        let site = try requireSiteURL()
        return try await performRequest(url: JiraEndpoints.priorities(siteURL: site))
    }

    func fetchStatuses() async throws -> [APIStatus] {
        let site = try requireSiteURL()
        return try await performRequest(url: JiraEndpoints.statuses(siteURL: site))
    }

    func fetchIssueTypes() async throws -> [APIIssueType] {
        let site = try requireSiteURL()
        return try await performRequest(url: JiraEndpoints.issueTypes(siteURL: site))
    }

    func fetchAssignableUsers(projectKey: String, query: String? = nil) async throws -> [APIUser] {
        let site = try requireSiteURL()
        var urlString = JiraEndpoints.assignableUsers(siteURL: site) + "?project=\(projectKey)"
        if let q = query {
            urlString += "&query=\(q)"
        }
        return try await performRequest(url: urlString)
    }

    // MARK: - Webhooks

    func registerWebhooks(body: Data) async throws -> Data {
        let site = try requireSiteURL()
        let request = try await makeRequest(
            url: JiraEndpoints.webhooks(siteURL: site),
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
        let site = try requireSiteURL()
        let body = try JSONEncoder().encode(["webhookIds": webhookIds])
        try await performVoidRequest(
            url: JiraEndpoints.refreshWebhooks(siteURL: site),
            method: "PUT",
            body: body
        )
    }
}
