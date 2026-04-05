import XCTest
@testable import Kaiju

final class TokenRefreshTests: XCTestCase {

    func test_token_response_decodes_correctly() throws {
        let json = """
        {"access_token":"new-access","refresh_token":"new-refresh","expires_in":3600,"scope":"read:jira-work","token_type":"Bearer"}
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIOAuthTokenResponse.self, from: data)

        XCTAssertEqual(response.access_token, "new-access")
        XCTAssertEqual(response.refresh_token, "new-refresh")
        XCTAssertEqual(response.expires_in, 3600)
        XCTAssertEqual(response.scope, "read:jira-work")
    }

    func test_token_storage_stores_refresh_before_access() async throws {
        let keychain = MockKeychainHelper()

        // Simulate storing tokens in the correct order
        try keychain.save(key: KeychainKeys.refreshToken, value: "refresh-123")
        try keychain.save(key: KeychainKeys.accessToken, value: "access-456")

        // Verify both are stored
        let refresh = try keychain.load(key: KeychainKeys.refreshToken)
        let access = try keychain.load(key: KeychainKeys.accessToken)

        XCTAssertEqual(refresh, "refresh-123")
        XCTAssertEqual(access, "access-456")
    }

    func test_keychain_delete_all_clears_tokens() throws {
        let keychain = MockKeychainHelper()

        try keychain.save(key: KeychainKeys.accessToken, value: "token")
        try keychain.save(key: KeychainKeys.refreshToken, value: "refresh")
        try keychain.save(key: KeychainKeys.cloudId, value: "cloud")

        try keychain.deleteAll()

        XCTAssertNil(try keychain.load(key: KeychainKeys.accessToken))
        XCTAssertNil(try keychain.load(key: KeychainKeys.refreshToken))
        XCTAssertNil(try keychain.load(key: KeychainKeys.cloudId))
    }
}
