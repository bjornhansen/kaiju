import XCTest
@testable import Kaiju

final class KeychainTests: XCTestCase {

    func test_keychain_save_and_load() throws {
        let keychain = MockKeychainHelper()

        try keychain.save(key: KeychainKeys.siteUrl, value: "https://mysite.atlassian.net")
        try keychain.save(key: KeychainKeys.email, value: "user@example.com")
        try keychain.save(key: KeychainKeys.apiToken, value: "secret-token")

        XCTAssertEqual(try keychain.load(key: KeychainKeys.siteUrl), "https://mysite.atlassian.net")
        XCTAssertEqual(try keychain.load(key: KeychainKeys.email), "user@example.com")
        XCTAssertEqual(try keychain.load(key: KeychainKeys.apiToken), "secret-token")
    }

    func test_keychain_delete_all_clears_credentials() throws {
        let keychain = MockKeychainHelper()

        try keychain.save(key: KeychainKeys.siteUrl, value: "https://mysite.atlassian.net")
        try keychain.save(key: KeychainKeys.email, value: "user@example.com")
        try keychain.save(key: KeychainKeys.apiToken, value: "secret-token")

        try keychain.deleteAll()

        XCTAssertNil(try keychain.load(key: KeychainKeys.siteUrl))
        XCTAssertNil(try keychain.load(key: KeychainKeys.email))
        XCTAssertNil(try keychain.load(key: KeychainKeys.apiToken))
    }

    func test_keychain_load_missing_key_returns_nil() throws {
        let keychain = MockKeychainHelper()
        XCTAssertNil(try keychain.load(key: "nonexistent"))
    }
}
