//
//  KeychainService.swift
//  
//  安全的 iOS Keychain 服務，用於存儲敏感資料如 API Keys
//  Created by mike liu on 2025/6/25.
//

import Foundation
import Security

/// iOS Keychain 服務協議
/// 提供安全的本地加密存儲，適用於 API Keys 等敏感資料
protocol KeychainServiceProtocol {
    func saveAPIKey(_ apiKey: String) -> Bool
    func getAPIKey() -> String?
    func deleteAPIKey() -> Bool
    func saveSecureData(_ data: Data, for key: String) -> Bool
    func getSecureData(for key: String) -> Data?
    func deleteSecureData(for key: String) -> Bool
}

/// iOS Keychain 服務實作
/// 提供安全的本地加密存儲，適用於 API Keys 等敏感資料
class KeychainService: KeychainServiceProtocol {
    
    private let service = "com.businesscardscanner.keychain"
    
    /// 儲存字串到 Keychain
    /// - Parameters:
    ///   - string: 要儲存的字串
    ///   - key: 儲存鍵值
    /// - Returns: 是否成功儲存
    func saveString(_ string: String, for key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        
        // 先刪除既有的項目
        deleteString(for: key)
        
        // 建立新的 Keychain 項目
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 從 Keychain 載入字串
    /// - Parameter key: 儲存鍵值
    /// - Returns: 儲存的字串，若不存在則回傳 nil
    func loadString(for key: String) -> String? {
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
    
    /// 從 Keychain 刪除字串
    /// - Parameter key: 儲存鍵值
    /// - Returns: 是否成功刪除
    @discardableResult
    func deleteString(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// 清除所有儲存的項目（主要用於測試或重置）
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - KeychainServiceProtocol Implementation
    
    /// 儲存 OpenAI API Key 到 Keychain
    func saveAPIKey(_ apiKey: String) -> Bool {
        return saveString(apiKey, for: "openai_api_key")
    }
    
    /// 從 Keychain 載入 OpenAI API Key
    func getAPIKey() -> String? {
        return loadString(for: "openai_api_key")
    }
    
    /// 從 Keychain 刪除 OpenAI API Key
    func deleteAPIKey() -> Bool {
        return deleteString(for: "openai_api_key")
    }
    
    /// 儲存安全資料到 Keychain
    func saveSecureData(_ data: Data, for key: String) -> Bool {
        // 先刪除既有的項目
        deleteSecureData(for: key)
        
        // 建立新的 Keychain 項目
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 從 Keychain 載入安全資料
    func getSecureData(for key: String) -> Data? {
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
              let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    /// 從 Keychain 刪除安全資料
    func deleteSecureData(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
