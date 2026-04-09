import XCTest
@testable import Kaiju

final class AuthFlowTests: XCTestCase {

    func test_parse_site_url_from_full_link() {
        let url = JiraEndpoints.parseSiteURL(from: "https://mysite.atlassian.net/jira/software/c/projects/KAI/boards")
        XCTAssertEqual(url, "https://mysite.atlassian.net")
    }

    func test_parse_site_url_from_base_url() {
        let url = JiraEndpoints.parseSiteURL(from: "https://mysite.atlassian.net")
        XCTAssertEqual(url, "https://mysite.atlassian.net")
    }

    func test_parse_site_url_from_bare_domain() {
        let url = JiraEndpoints.parseSiteURL(from: "mysite.atlassian.net")
        XCTAssertEqual(url, "https://mysite.atlassian.net")
    }

    func test_parse_site_url_rejects_garbage() {
        let url = JiraEndpoints.parseSiteURL(from: "not a url at all")
        XCTAssertNil(url)
    }

    func test_site_name_from_url() {
        let name = JiraEndpoints.siteName(from: "https://citydetect.atlassian.net")
        XCTAssertEqual(name, "citydetect")
    }

    func test_basic_auth_header_encoding() {
        let email = "user@example.com"
        let token = "my-api-token"
        let credentials = "\(email):\(token)"
        let encoded = Data(credentials.utf8).base64EncodedString()

        // Verify it produces valid base64
        XCTAssertFalse(encoded.isEmpty)
        let decoded = Data(base64Encoded: encoded).flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(decoded, "user@example.com:my-api-token")
    }
}
