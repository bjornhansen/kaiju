import XCTest
@testable import Kaiju

final class EndpointConstructionTests: XCTestCase {
    let cloudId = "test-cloud-123"

    func test_platform_base_url() {
        let base = JiraEndpoints.platformBase(cloudId: cloudId)
        XCTAssertEqual(base, "https://api.atlassian.com/ex/jira/test-cloud-123/rest/api/3")
    }

    func test_agile_base_url() {
        let base = JiraEndpoints.agileBase(cloudId: cloudId)
        XCTAssertEqual(base, "https://api.atlassian.com/ex/jira/test-cloud-123/rest/agile/1.0")
    }

    func test_issue_endpoint() {
        let url = JiraEndpoints.issue(cloudId: cloudId, key: "KAI-123")
        XCTAssertTrue(url.hasSuffix("/rest/api/3/issue/KAI-123"))
    }

    func test_transitions_endpoint() {
        let url = JiraEndpoints.transitions(cloudId: cloudId, issueKey: "KAI-456")
        XCTAssertTrue(url.hasSuffix("/rest/api/3/issue/KAI-456/transitions"))
    }

    func test_board_configuration_endpoint() {
        let url = JiraEndpoints.boardConfiguration(cloudId: cloudId, boardId: 42)
        XCTAssertTrue(url.hasSuffix("/rest/agile/1.0/board/42/configuration"))
    }

    func test_board_issues_endpoint() {
        let url = JiraEndpoints.boardIssues(cloudId: cloudId, boardId: 10)
        XCTAssertTrue(url.hasSuffix("/rest/agile/1.0/board/10/issue"))
    }

    func test_search_endpoint() {
        let url = JiraEndpoints.searchJQL(cloudId: cloudId)
        XCTAssertTrue(url.hasSuffix("/rest/api/3/search/jql"))
    }

    func test_webhooks_endpoint() {
        let url = JiraEndpoints.webhooks(cloudId: cloudId)
        XCTAssertTrue(url.hasSuffix("/rest/api/3/webhook"))
    }

    func test_comments_endpoint() {
        let url = JiraEndpoints.comments(cloudId: cloudId, issueKey: "KAI-1")
        XCTAssertTrue(url.hasSuffix("/rest/api/3/issue/KAI-1/comment"))
    }

    func test_authorize_url_construction() {
        let url = JiraEndpoints.authorizeURL(
            clientId: "my-client",
            redirectURI: "http://localhost:21456/oauth/callback",
            state: "random-state"
        )
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.host, "auth.atlassian.com")
        XCTAssertEqual(url?.path, "/authorize")
    }
}
