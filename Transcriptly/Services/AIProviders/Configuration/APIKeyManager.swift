//
//  APIKeyManager.swift
//  Transcriptly
//
//  Created by Claude Code on 6/29/25.
//  Phase 7: AI Providers Integration - API Key Management
//

import Foundation
import Security

class APIKeyManager {
    static let shared = APIKeyManager()
    private let serviceName = "com.yourname.transcriptly"
    
    private init() {}
    
    func storeAPIKey(_ key: String, for provider: ProviderType) throws {
        let account = "\(provider.rawValue)_api_key"
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete existing key first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw ProviderError.apiKeyInvalid
        }
    }
    
    func getAPIKey(for provider: ProviderType) throws -> String? {
        let account = "\(provider.rawValue)_api_key"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey(for provider: ProviderType) throws {
        let account = "\(provider.rawValue)_api_key"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ProviderError.apiKeyInvalid
        }
    }
    
    func hasAPIKey(for provider: ProviderType) -> Bool {
        return (try? getAPIKey(for: provider)) != nil
    }
    
    // Alias for consistency
    func saveAPIKey(_ key: String, for provider: ProviderType) throws {
        try storeAPIKey(key, for: provider)
    }
}