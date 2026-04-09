import XCTest
@testable import Kaiju

final class EndpointConstructionTests: XCTestCase {
    let siteURL = "https://mysite.atlassian.net"

    func test_platform_base_url() {
        let base = JiraEndpoints.platformBase(siteURL: siteURL)
        XCTAssertEqual(base, "https://mysite.atlassian.net/rest/api/3")
    }

    func test_agile_base_url() {
        let base = JiraEndpoints.agileBase(siteURL: siteURL)
        XCTAssertEqual(base, "https://mysite.atlassian.net/rest/agile/1.0")
    }

    func test_issue_endpoint() {
        let url = JiraEndpoints.issue(siteURL: siteURL, key: "KAI-123")
        XCTAssertTrue(url.hasSuffix("/rest/api/3/issue/KAI-123"))
    }

    func test_transitions_endpoint() {
        let url = JiraEndpoints.transitions(siteURL: siteURL, issueKey: "KAI-456")
        XCTAssertTrue(url.hasSuffix("/rest/api/3/issue/KAI-456/transitions"))
    }

    func test_board_configuration_endpoint() {
        let url = JiraEndpoints.boardConfiguration(siteURL: siteURL, boardId: 42)
        XCTAssertTrue(url.hasSuffix("/rest/agile/1.0/board/42/configuration"))
    }

    func test_board_issues_endpoint() {
        let url = JiraEndpoints.boardIssues(siteURL: siteURL, boardId: 10)
        XCTAssertTrue(url.hasSuffix("/rest/agile/1.0/board/10/issue"))
    }

    func test_search_endpoint() {
        let url = JiraEndpoints.searchJQL(siteURL: siteURL)
        XCTAssertTrue(url.hasSuffix("/rest/api/3/search/jql"))
    }

    func test_webhooks_endpoint() {
        let url = JiraEndpoints.webhooks(siteURL: siteURL)
        XCTAssertTrue(url.hasSuffix("/rest/api/3/webhook"))
    }

    func test_comments_endpoint() {
        let url = JiraEndpoints.comments(siteURL: siteURL, issueKey: "KAI-1")
        XCTAssertTrue(url.hasSuffix("/rest/api/3/issue/KAI-1/comment"))
    }

    func test_parse_site_url_from_full_jira_link() {
        let parsed = JiraEndpoints.parseSiteURL(from: "https://citydetect.atlassian.net/jira/software/c/projects/TECH/boards")
        XCTAssertEqual(parsed, "https://citydetect.atlassian.net")
    }

    func test_parse_site_url_from_bare_domain() {
        let parsed = JiraEndpoints.parseSiteURL(from: "citydetect.atlassian.net")
        XCTAssertEqual(parsed, "https://citydetect.atlassian.net")
    }

    func test_site_name_extraction() {
        let name = JiraEndpoints.siteName(from: "https://citydetect.atlassian.net")
        XCTAssertEqual(name, "citydetect")
    }
}
