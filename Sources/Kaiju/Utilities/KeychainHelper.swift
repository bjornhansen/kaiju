import Foundation
@preconcurrency import KeychainAccess

/// Protocol for keychain operations, enabling test mocking
protocol KeychainHelperProtocol: Sendable {
    func save(key: String, value: String) throws
    func load(key: String) throws -> String?
    func delete(key: String) throws
    func deleteAll() throws
}

/// Wraps KeychainAccess for secure token storage
final class KeychainHelper: KeychainHelperProtocol, Sendable {
    private let keychain: Keychain

    init(service: String = "com.kaiju.app") {
        keychain = Keychain(service: service)
    }

    func save(key: String, value: String) throws {
        try keychain.set(value, key: key)
    }

    func load(key: String) throws -> String? {
        try keychain.get(key)
    }

    func delete(key: String) throws {
        try keychain.remove(key)
    }

    func deleteAll() throws {
        try keychain.removeAll()
    }
}

/// Keys used for keychain storage
enum KeychainKeys {
    static let accessToken = "kaiju_access_token"
    static let refreshToken = "kaiju_refresh_token"
    static let tokenExpiry = "kaiju_token_expiry"
    static let cloudId = "kaiju_cloud_id"
    static let siteName = "kaiju_site_name"
    static let siteUrl = "kaiju_site_url"
}

/// In-memory keychain implementation for testing
final class MockKeychainHelper: KeychainHelperProtocol, @unchecked Sendable {
    private var storage: [String: String] = [:]
    private let lock = NSLock()

    func save(key: String, value: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }

    func load(key: String) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func delete(key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    func deleteAll() throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}
