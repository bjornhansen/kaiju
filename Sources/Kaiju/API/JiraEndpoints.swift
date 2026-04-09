import Foundation

/// Constructs Jira API URLs for all endpoints.
/// Uses direct site URLs with API token auth (Basic auth).
enum JiraEndpoints {
    /// Base URL for Jira Platform REST API v3
    static func platformBase(siteURL: String) -> String {
        "\(siteURL)/rest/api/3"
    }

    /// Base URL for Jira Software (Agile) REST API
    static func agileBase(siteURL: String) -> String {
        "\(siteURL)/rest/agile/1.0"
    }

    // MARK: - Current User

    static func myself(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/myself"
    }

    // MARK: - Projects

    static func projects(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/project"
    }

    static func recentProjects(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/project/recent"
    }

    static func project(siteURL: String, key: String) -> String {
        "\(platformBase(siteURL: siteURL))/project/\(key)"
    }

    // MARK: - Issues

    static func issue(siteURL: String, key: String) -> String {
        "\(platformBase(siteURL: siteURL))/issue/\(key)"
    }

    static func createIssue(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/issue"
    }

    static func transitions(siteURL: String, issueKey: String) -> String {
        "\(platformBase(siteURL: siteURL))/issue/\(issueKey)/transitions"
    }

    static func comments(siteURL: String, issueKey: String) -> String {
        "\(platformBase(siteURL: siteURL))/issue/\(issueKey)/comment"
    }

    // MARK: - Search

    static func searchJQL(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/search/jql"
    }

    // MARK: - Reference Data

    static func fields(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/field"
    }

    static func assignableUsers(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/user/assignable/search"
    }

    static func priorities(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/priority"
    }

    static func statuses(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/status"
    }

    static func issueTypes(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/issuetype"
    }

    static func labels(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/label"
    }

    static func myPermissions(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/mypermissions"
    }

    // MARK: - Webhooks

    static func webhooks(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/webhook"
    }

    static func refreshWebhooks(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/webhook/refresh"
    }

    static func failedWebhooks(siteURL: String) -> String {
        "\(platformBase(siteURL: siteURL))/webhook/failed"
    }

    // MARK: - Agile (Boards)

    static func boards(siteURL: String) -> String {
        "\(agileBase(siteURL: siteURL))/board"
    }

    static func board(siteURL: String, boardId: Int) -> String {
        "\(agileBase(siteURL: siteURL))/board/\(boardId)"
    }

    static func boardConfiguration(siteURL: String, boardId: Int) -> String {
        "\(agileBase(siteURL: siteURL))/board/\(boardId)/configuration"
    }

    static func boardIssues(siteURL: String, boardId: Int) -> String {
        "\(agileBase(siteURL: siteURL))/board/\(boardId)/issue"
    }

    // MARK: - URL Parsing

    /// Extract the base site URL from any Jira URL the user might paste.
    /// e.g. "https://citydetect.atlassian.net/jira/software/c/projects/TECH/boards" → "https://citydetect.atlassian.net"
    static func parseSiteURL(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme,
              let host = url.host else {
            // Try prepending https:// if user just pasted "foo.atlassian.net"
            if let url = URL(string: "https://\(trimmed)"),
               let scheme = url.scheme,
               let host = url.host,
               host.contains(".") {
                return "\(scheme)://\(host)"
            }
            return nil
        }
        return "\(scheme)://\(host)"
    }

    /// Extract a display name from a site URL.
    /// e.g. "https://citydetect.atlassian.net" → "citydetect"
    static func siteName(from siteURL: String) -> String {
        guard let url = URL(string: siteURL), let host = url.host else {
            return siteURL
        }
        return host.split(separator: ".").first.map(String.init) ?? host
    }

    // MARK: - Query Parameter Helpers

    /// Fields for board card display (minimal)
    static let boardCardFields = "summary,status,assignee,priority,issuetype,labels,updated,created,customfield_10016"

    /// Fields for full issue detail
    static let issueDetailFields = "summary,description,status,assignee,reporter,priority,issuetype,labels,comment,attachment,issuelinks,subtasks,created,updated,fixVersions,components,customfield_10016"
}
