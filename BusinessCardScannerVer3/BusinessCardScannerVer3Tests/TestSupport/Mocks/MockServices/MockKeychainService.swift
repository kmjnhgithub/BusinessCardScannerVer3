//
//  MockKeychainService.swift
//  BusinessCardScannerVer3Tests
//
//  Mock implementation of KeychainService for testing
//  Provides in-memory storage simulation without actual Keychain operations
//

import Foundation
@testable import BusinessCardScannerVer3

/// Mock implementation of KeychainService for testing purposes
/// Simulates Keychain operations using in-memory storage
final class MockKeychainService: KeychainServiceProtocol {
    
    // MARK: - Mock Storage
    
    private var mockStorage: [String: Data] = [:]
    
    // MARK: - Mock Configuration
    
    /// 模擬 API Key
    var mockAPIKey: String? = "sk-test-mock-api-key"
    
    /// 是否模擬成功操作
    var shouldSucceed: Bool = true
    
    // MARK: - Analytics
    
    private(set) var saveAPIKeyCallCount: Int = 0
    private(set) var getAPIKeyCallCount: Int = 0
    private(set) var deleteAPIKeyCallCount: Int = 0
    
    // MARK: - KeychainServiceProtocol Implementation
    
    func saveAPIKey(_ apiKey: String) -> Bool {
        saveAPIKeyCallCount += 1
        
        guard shouldSucceed else { return false }
        
        mockAPIKey = apiKey
        if let data = apiKey.data(using: .utf8) {
            mockStorage["openai_api_key"] = data
        }
        return true
    }
    
    func getAPIKey() -> String? {
        getAPIKeyCallCount += 1
        
        guard shouldSucceed else { return nil }
        
        return mockAPIKey
    }
    
    func deleteAPIKey() -> Bool {
        deleteAPIKeyCallCount += 1
        
        guard shouldSucceed else { return false }
        
        mockAPIKey = nil
        mockStorage.removeValue(forKey: "openai_api_key")
        return true
    }
    
    func saveSecureData(_ data: Data, for key: String) -> Bool {
        guard shouldSucceed else { return false }
        
        mockStorage[key] = data
        return true
    }
    
    func getSecureData(for key: String) -> Data? {
        guard shouldSucceed else { return nil }
        
        return mockStorage[key]
    }
    
    func deleteSecureData(for key: String) -> Bool {
        guard shouldSucceed else { return false }
        
        mockStorage.removeValue(forKey: key)
        return true
    }
    
    // MARK: - Test Helpers
    
    /// 重置 Mock 狀態
    func resetMockState() {
        mockStorage.removeAll()
        mockAPIKey = "sk-test-mock-api-key"
        shouldSucceed = true
        
        saveAPIKeyCallCount = 0
        getAPIKeyCallCount = 0
        deleteAPIKeyCallCount = 0
    }
    
    /// 設定無 API Key 場景
    func setNoAPIKeyScenario() {
        mockAPIKey = nil
        mockStorage.removeValue(forKey: "openai_api_key")
    }
    
    /// 預設資料供測試使用
    func presetData(key: String, value: String) {
        if let data = value.data(using: .utf8) {
            mockStorage[key] = data
        }
    }
    
    /// 取得目前儲存的資料數量
    var storedDataCount: Int {
        return mockStorage.count
    }
}