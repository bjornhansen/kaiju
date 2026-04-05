import Foundation

/// Constructs Jira API URLs for all v1.0 endpoints
enum JiraEndpoints {
    /// Base URL for Jira Platform REST API v3
    static func platformBase(cloudId: String) -> String {
        "https://api.atlassian.com/ex/jira/\(cloudId)/rest/api/3"
    }

    /// Base URL for Jira Software (Agile) REST API
    static func agileBase(cloudId: String) -> String {
        "https://api.atlassian.com/ex/jira/\(cloudId)/rest/agile/1.0"
    }

    // MARK: - Auth / Resources

    static let accessibleResources = "https://api.atlassian.com/oauth/token/accessible-resources"
    static let tokenEndpoint = "https://auth.atlassian.com/oauth/token"

    static func authorizeURL(clientId: String, redirectURI: String, state: String) -> URL? {
        var components = URLComponents(string: "https://auth.atlassian.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "audience", value: "api.atlassian.com"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "scope", value: "read:jira-work write:jira-work read:jira-user manage:jira-webhook offline_access"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "prompt", value: "consent"),
        ]
        return components?.url
    }

    // MARK: - Current User

    static func myself(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/myself"
    }

    // MARK: - Projects

    static func projects(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/project"
    }

    static func recentProjects(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/project/recent"
    }

    static func project(cloudId: String, key: String) -> String {
        "\(platformBase(cloudId: cloudId))/project/\(key)"
    }

    // MARK: - Issues

    static func issue(cloudId: String, key: String) -> String {
        "\(platformBase(cloudId: cloudId))/issue/\(key)"
    }

    static func createIssue(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/issue"
    }

    static func transitions(cloudId: String, issueKey: String) -> String {
        "\(platformBase(cloudId: cloudId))/issue/\(issueKey)/transitions"
    }

    static func comments(cloudId: String, issueKey: String) -> String {
        "\(platformBase(cloudId: cloudId))/issue/\(issueKey)/comment"
    }

    // MARK: - Search

    static func searchJQL(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/search/jql"
    }

    // MARK: - Reference Data

    static func fields(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/field"
    }

    static func assignableUsers(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/user/assignable/search"
    }

    static func priorities(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/priority"
    }

    static func statuses(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/status"
    }

    static func issueTypes(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/issuetype"
    }

    static func labels(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/label"
    }

    static func myPermissions(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/mypermissions"
    }

    // MARK: - Webhooks

    static func webhooks(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/webhook"
    }

    static func refreshWebhooks(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/webhook/refresh"
    }

    static func failedWebhooks(cloudId: String) -> String {
        "\(platformBase(cloudId: cloudId))/webhook/failed"
    }

    // MARK: - Agile (Boards)

    static func boards(cloudId: String) -> String {
        "\(agileBase(cloudId: cloudId))/board"
    }

    static func board(cloudId: String, boardId: Int) -> String {
        "\(agileBase(cloudId: cloudId))/board/\(boardId)"
    }

    static func boardConfiguration(cloudId: String, boardId: Int) -> String {
        "\(agileBase(cloudId: cloudId))/board/\(boardId)/configuration"
    }

    static func boardIssues(cloudId: String, boardId: Int) -> String {
        "\(agileBase(cloudId: cloudId))/board/\(boardId)/issue"
    }

    // MARK: - Query Parameter Helpers

    /// Fields for board card display (minimal)
    static let boardCardFields = "summary,status,assignee,priority,issuetype,labels,updated,created,customfield_10016"

    /// Fields for full issue detail
    static let issueDetailFields = "summary,description,status,assignee,reporter,priority,issuetype,labels,comment,attachment,issuelinks,subtasks,created,updated,fixVersions,components,customfield_10016"
}
