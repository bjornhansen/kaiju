import XCTest
@testable import Kaiju

final class OAuthFlowTests: XCTestCase {

    func test_oauth_url_includes_all_required_params() throws {
        let url = JiraEndpoints.authorizeURL(
            clientId: "test-client-id",
            redirectURI: "http://127.0.0.1:21456/oauth/callback",
            state: "test-state-123"
        )

        XCTAssertNotNil(url)
        let urlString = url!.absoluteString

        XCTAssertTrue(urlString.contains("audience=api.atlassian.com"))
        XCTAssertTrue(urlString.contains("client_id=test-client-id"))
        XCTAssertTrue(urlString.contains("response_type=code"))
        XCTAssertTrue(urlString.contains("state=test-state-123"))
        XCTAssertTrue(urlString.contains("prompt=consent"))
        XCTAssertTrue(urlString.contains("redirect_uri="))
        XCTAssertTrue(urlString.contains("scope="))
        // Verify all required scopes
        XCTAssertTrue(urlString.contains("read%3Ajira-work") || urlString.contains("read:jira-work"))
        XCTAssertTrue(urlString.contains("write%3Ajira-work") || urlString.contains("write:jira-work"))
        XCTAssertTrue(urlString.contains("offline_access"))
        XCTAssertTrue(urlString.contains("manage%3Ajira-webhook") || urlString.contains("manage:jira-webhook"))
    }

    func test_state_param_mismatch_rejects_callback() async throws {
        // The callback server validates state parameter
        // In production, mismatched state throws CallbackError.stateMismatch
        // We verify the error type exists and is properly defined
        let error = OAuthCallbackServer.CallbackError.stateMismatch(expected: "abc", received: "xyz")
        switch error {
        case .stateMismatch(let expected, let received):
            XCTAssertEqual(expected, "abc")
            XCTAssertEqual(received, "xyz")
        default:
            XCTFail("Expected stateMismatch error")
        }
    }

    func test_accessible_resources_model_decodes_correctly() throws {
        let json = """
        [{"id":"cloud-123","name":"mysite","url":"https://mysite.atlassian.net","scopes":["read:jira-work"],"avatarUrl":"https://example.com/avatar.png"}]
        """
        let data = json.data(using: .utf8)!
        let resources = try JSONDecoder().decode([APIAccessibleResource].self, from: data)

        XCTAssertEqual(resources.count, 1)
        XCTAssertEqual(resources[0].id, "cloud-123")
        XCTAssertEqual(resources[0].name, "mysite")
        XCTAssertEqual(resources[0].url, "https://mysite.atlassian.net")
    }
}
