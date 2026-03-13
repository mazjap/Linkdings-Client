import Foundation
import Security

enum KeychainHelper {
    enum KeychainError: Error {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case invalidData
    }
    
    private static let instanceURLKey = "instanceURL"
    private static let apiKeyKey = "apiKey"

    static var instanceURL: String? {
        get {
            do {
                return try get(identifier: instanceURLKey)
            } catch .itemNotFound {
                return nil
            } catch {
                fatalError("Failed to get instanceURL from keychain")
            }
        }
        set {
            do {
                try set(identifier: instanceURLKey, to: newValue)
            } catch {
                fatalError("Failed to set instanceURL to keychain")
            }
        }
    }

    static var apiKey: String? {
        get {
            do {
                return try get(identifier: apiKeyKey)
            } catch .itemNotFound {
                return nil
            } catch {
                fatalError("Failed to get apiKey from keychain")
            }
        }
        set {
            do {
                try set(identifier: apiKeyKey, to: newValue)
            } catch {
                fatalError("Failed to set apiKey to keychain")
            }
        }
    }

    static var isConfigured: Bool {
        instanceURL != nil && apiKey != nil
    }

    static func makeAPI() -> LinkdingAPI? {
        guard let urlString = instanceURL,
              let url = URL(string: urlString),
              let key = apiKey else { return nil }
        return LinkdingAPI(baseURL: url, apiKey: key)
    }

    static func clear() {
        do {
            try set(identifier: instanceURLKey, to: nil)
            try set(identifier: apiKeyKey, to: nil)
        } catch {
            fatalError("Cannot remove from keychain")
        }
    }
    
    static private func get(identifier: String) throws(KeychainError) -> String? {
        guard let data = try retrieve(account: identifier) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    static private func set(identifier: String, to string: String?) throws(KeychainError) {
        guard let string else {
            try delete(account: identifier)
            return
        }
        
        guard let data = string.data(using: .utf8) else { throw .invalidData }
        
        do {
            try save(data: data, account: identifier)
        } catch .duplicateItem {
            try update(data: data, account: identifier)
        }
    }
    
    static private func save(data: Data, account: String) throws(KeychainError) {
        let query: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SharedConstants.bundleID,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw .duplicateItem
        default:
            throw .unexpectedStatus(status)
        }
    }
    
    static private func update(data: Data, account: String) throws(KeychainError) {
        let query: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: SharedConstants.bundleID
        ]
        
        let attributesToUpdate: [String : Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(
            query as CFDictionary,
            attributesToUpdate as CFDictionary
        )
        
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    static private func retrieve(account: String) throws(KeychainError) -> Data? {
        let query: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: SharedConstants.bundleID,
            kSecMatchLimit as String: kSecMatchLimitOne,
            // Request the data be returned
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    static private func delete(account: String) throws(KeychainError) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: SharedConstants.bundleID
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound: // Both are acceptable
            return
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
