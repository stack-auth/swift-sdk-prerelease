import Foundation
import Security

public protocol TokenStore {
    func getAccessToken() async -> String?
    func getRefreshToken() async -> String?
    func setTokens(accessToken: String?, refreshToken: String?) async
    func clearTokens() async
}

public enum TokenStoreType {
    case memory
    case keychain(service: String)
    case explicit(accessToken: String?, refreshToken: String?)
    case none
}

public class MemoryTokenStore: TokenStore {
    private var accessToken: String?
    private var refreshToken: String?

    public init() {}

    public func getAccessToken() async -> String? {
        return accessToken
    }

    public func getRefreshToken() async -> String? {
        return refreshToken
    }

    public func setTokens(accessToken: String?, refreshToken: String?) async {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    public func clearTokens() async {
        self.accessToken = nil
        self.refreshToken = nil
    }
}

public class ExplicitTokenStore: TokenStore {
    private let accessToken: String?
    private let refreshToken: String?

    public init(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    public func getAccessToken() async -> String? {
        return accessToken
    }

    public func getRefreshToken() async -> String? {
        return refreshToken
    }

    public func setTokens(accessToken: String?, refreshToken: String?) async {
        // Explicit token store is immutable
    }

    public func clearTokens() async {
        // Explicit token store is immutable
    }
}

public class NoTokenStore: TokenStore {
    public init() {}

    public func getAccessToken() async -> String? {
        return nil
    }

    public func getRefreshToken() async -> String? {
        return nil
    }

    public func setTokens(accessToken: String?, refreshToken: String?) async {
        // No-op
    }

    public func clearTokens() async {
        // No-op
    }
}

/// Keychain-based token store for persistent secure storage on macOS/iOS
public class KeychainTokenStore: TokenStore {
    private let service: String
    private let accessTokenKey = "stack_auth_access_token"
    private let refreshTokenKey = "stack_auth_refresh_token"
    
    public init(service: String) {
        self.service = service
    }
    
    public func getAccessToken() async -> String? {
        return getKeychainItem(key: accessTokenKey)
    }
    
    public func getRefreshToken() async -> String? {
        return getKeychainItem(key: refreshTokenKey)
    }
    
    public func setTokens(accessToken: String?, refreshToken: String?) async {
        if let accessToken = accessToken {
            setKeychainItem(key: accessTokenKey, value: accessToken)
        } else {
            deleteKeychainItem(key: accessTokenKey)
        }
        
        if let refreshToken = refreshToken {
            setKeychainItem(key: refreshTokenKey, value: refreshToken)
        } else {
            deleteKeychainItem(key: refreshTokenKey)
        }
    }
    
    public func clearTokens() async {
        deleteKeychainItem(key: accessTokenKey)
        deleteKeychainItem(key: refreshTokenKey)
    }
    
    // MARK: - Keychain Helpers
    
    private func getKeychainItem(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func setKeychainItem(key: String, value: String) {
        // First try to delete existing item
        deleteKeychainItem(key: key)
        
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func deleteKeychainItem(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

public func createTokenStore(type: TokenStoreType) -> TokenStore {
    switch type {
    case .memory:
        return MemoryTokenStore()
    case .keychain(let service):
        return KeychainTokenStore(service: service)
    case .explicit(let accessToken, let refreshToken):
        return ExplicitTokenStore(accessToken: accessToken, refreshToken: refreshToken)
    case .none:
        return NoTokenStore()
    }
}
