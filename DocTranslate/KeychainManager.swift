import Foundation
import Security

class KeychainManager {
    
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidItemFormat
        case unhandledError(status: OSStatus)
    }
    
    static let shared = KeychainManager()
    
    private let service = "com.document-translator-v4.DocScannerTest"
    
    private init() {}
    
    // Save string to Keychain
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing items
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // Retrieve string from Keychain
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        guard let data = item as? Data, 
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // Delete item from Keychain
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // Validate API key format
    func isValidAPIKey(_ key: String) -> Bool {
        // DeepL API keys follow pattern: 
        // - Free account: 32 chars ending with ":fx"
        // - Pro account: 32 chars ending with no suffix
        
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Length check
        if trimmedKey.count < 32 {
            return false
        }
        
        // Basic format check - alphanumeric with possible :fx at the end
        let pattern = "^[a-zA-Z0-9]{32}(:fx)?$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: trimmedKey.utf16.count)
        return regex?.firstMatch(in: trimmedKey, options: [], range: range) != nil
    }
} 