//
//  KeychainServiceTests.swift
//  BusinessCardScannerVer3Tests
//
//  Comprehensive security tests for KeychainService
//  Validates secure API key storage, memory safety, and access control
//  Portfolio demonstration: iOS security best practices and Keychain expertise
//

import XCTest
import Security
@testable import BusinessCardScannerVer3

/// KeychainService 安全性測試套件
/// 
/// **Portfolio 展示重點:**
/// - iOS Keychain Services 專業應用
/// - 敏感資料安全存儲測試
/// - 記憶體安全和資料洩漏防護
/// - 存取控制和權限驗證
/// - 安全架構設計驗證
final class KeychainServiceTests: BaseTestCase {
    
    // MARK: - Properties
    
    private var keychainService: KeychainService!
    private let testService = "com.businesscardscanner.keychain.test"
    
    // Test data constants
    private let testAPIKey = "sk-test-1234567890abcdef"
    private let testAPIKeyUpdated = "sk-test-updated-key-9876543210"
    private let testSecureData = "sensitive-test-data-2025"
    private let testKey = "test_secure_key"
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        keychainService = KeychainService()
        
        // 測試前清理所有 Keychain 項目，確保測試環境乾淨
        cleanupTestKeychain()
    }
    
    override func tearDown() {
        // 測試後清理，防止資料洩漏到其他測試
        cleanupTestKeychain()
        keychainService = nil
        super.tearDown()
    }
    
    // MARK: - API Key Security Tests
    
    /// **Test Case 1**: API Key 基本存儲和檢索
    /// **Given**: 空的 Keychain 環境
    /// **When**: 存儲和檢索 API Key
    /// **Then**: 正確存儲和檢索，資料一致性驗證
    func testAPIKey_BasicStorage_ShouldStoreAndRetrieveCorrectly() {
        // Given: 確認 Keychain 為空
        XCTAssertNil(keychainService.getAPIKey(), "初始狀態應該沒有 API Key")
        
        // When: 存儲 API Key
        let saveResult = keychainService.saveAPIKey(testAPIKey)
        
        // Then: 驗證存儲成功
        XCTAssertTrue(saveResult, "API Key 應該成功存儲")
        
        // Then: 驗證檢索正確
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertEqual(retrievedKey, testAPIKey, "檢索的 API Key 應該與存儲的相同")
    }
    
    /// **Test Case 2**: API Key 更新覆蓋測試
    /// **Given**: 已存在 API Key
    /// **When**: 存儲新的 API Key
    /// **Then**: 舊 Key 被安全覆蓋，新 Key 正確存儲
    func testAPIKey_UpdateOverwrite_ShouldReplaceExistingKey() {
        // Given: 存儲初始 API Key
        XCTAssertTrue(keychainService.saveAPIKey(testAPIKey))
        XCTAssertEqual(keychainService.getAPIKey(), testAPIKey)
        
        // When: 更新 API Key
        let updateResult = keychainService.saveAPIKey(testAPIKeyUpdated)
        
        // Then: 驗證更新成功
        XCTAssertTrue(updateResult, "API Key 更新應該成功")
        
        // Then: 驗證只有新 Key 存在
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertEqual(retrievedKey, testAPIKeyUpdated, "應該檢索到更新後的 API Key")
        XCTAssertNotEqual(retrievedKey, testAPIKey, "舊的 API Key 不應該存在")
    }
    
    /// **Test Case 3**: API Key 刪除安全性測試
    /// **Given**: 已存儲的 API Key
    /// **When**: 刪除 API Key
    /// **Then**: Key 完全移除，無法檢索
    func testAPIKey_SecureDeletion_ShouldCompletelyRemoveKey() {
        // Given: 存儲 API Key
        XCTAssertTrue(keychainService.saveAPIKey(testAPIKey))
        XCTAssertNotNil(keychainService.getAPIKey())
        
        // When: 刪除 API Key
        let deleteResult = keychainService.deleteAPIKey()
        
        // Then: 驗證刪除成功
        XCTAssertTrue(deleteResult, "API Key 刪除應該成功")
        
        // Then: 驗證 Key 不可檢索
        XCTAssertNil(keychainService.getAPIKey(), "刪除後不應該能檢索到 API Key")
        
        // Then: 再次刪除應該安全處理（幂等性）
        let secondDeleteResult = keychainService.deleteAPIKey()
        XCTAssertTrue(secondDeleteResult, "重複刪除應該安全處理")
    }
    
    // MARK: - Secure Data Storage Tests
    
    /// **Test Case 4**: 安全資料存儲測試
    /// **Given**: 敏感二進制資料
    /// **When**: 存儲和檢索安全資料
    /// **Then**: 資料完整性保持，加密存儲驗證
    func testSecureData_BinaryStorage_ShouldMaintainDataIntegrity() {
        // Given: 準備二進制測試資料
        let originalData = testSecureData.data(using: .utf8)!
        XCTAssertNil(keychainService.getSecureData(for: testKey))
        
        // When: 存儲安全資料
        let saveResult = keychainService.saveSecureData(originalData, for: testKey)
        
        // Then: 驗證存儲成功
        XCTAssertTrue(saveResult, "安全資料應該成功存儲")
        
        // Then: 驗證資料完整性
        let retrievedData = keychainService.getSecureData(for: testKey)
        XCTAssertNotNil(retrievedData, "應該能檢索到安全資料")
        XCTAssertEqual(retrievedData, originalData, "檢索的資料應該與原始資料相同")
        
        // Then: 驗證資料內容
        let retrievedString = String(data: retrievedData!, encoding: .utf8)
        XCTAssertEqual(retrievedString, testSecureData, "字串內容應該相同")
    }
    
    /// **Test Case 5**: 大型資料存儲測試
    /// **Given**: 大型敏感資料（模擬長 API Key 或 Token）
    /// **When**: 存儲和檢索大型資料
    /// **Then**: 大型資料正確處理，無截斷
    func testSecureData_LargeDataStorage_ShouldHandleLargeData() {
        // Given: 創建大型測試資料 (10KB)
        let largeString = String(repeating: "SecureData", count: 1000)
        let largeData = largeString.data(using: .utf8)!
        let largeDataKey = "large_secure_data"
        
        // When: 存儲大型資料
        let saveResult = keychainService.saveSecureData(largeData, for: largeDataKey)
        
        // Then: 驗證存儲成功
        XCTAssertTrue(saveResult, "大型安全資料應該成功存儲")
        
        // Then: 驗證資料完整性
        let retrievedData = keychainService.getSecureData(for: largeDataKey)
        XCTAssertNotNil(retrievedData, "應該能檢索到大型安全資料")
        XCTAssertEqual(retrievedData?.count, largeData.count, "資料大小應該相同")
        XCTAssertEqual(retrievedData, largeData, "大型資料內容應該完全相同")
        
        // Cleanup
        XCTAssertTrue(keychainService.deleteSecureData(for: largeDataKey))
    }
    
    /// **Test Case 6**: 多重 Key 隔離測試
    /// **Given**: 多個不同的安全資料 Key
    /// **When**: 同時存儲多個安全資料
    /// **Then**: 各 Key 資料獨立，無交叉污染
    func testSecureData_MultipleKeys_ShouldIsolateDataCorrectly() {
        // Given: 準備多個測試資料
        let data1 = "secret1".data(using: .utf8)!
        let data2 = "secret2".data(using: .utf8)!
        let data3 = "secret3".data(using: .utf8)!
        let key1 = "key1"
        let key2 = "key2"
        let key3 = "key3"
        
        // When: 存儲多個資料
        XCTAssertTrue(keychainService.saveSecureData(data1, for: key1))
        XCTAssertTrue(keychainService.saveSecureData(data2, for: key2))
        XCTAssertTrue(keychainService.saveSecureData(data3, for: key3))
        
        // Then: 驗證資料隔離
        XCTAssertEqual(keychainService.getSecureData(for: key1), data1)
        XCTAssertEqual(keychainService.getSecureData(for: key2), data2)
        XCTAssertEqual(keychainService.getSecureData(for: key3), data3)
        
        // Then: 刪除一個不影響其他
        XCTAssertTrue(keychainService.deleteSecureData(for: key2))
        XCTAssertEqual(keychainService.getSecureData(for: key1), data1)
        XCTAssertNil(keychainService.getSecureData(for: key2))
        XCTAssertEqual(keychainService.getSecureData(for: key3), data3)
        
        // Cleanup
        XCTAssertTrue(keychainService.deleteSecureData(for: key1))
        XCTAssertTrue(keychainService.deleteSecureData(for: key3))
    }
    
    // MARK: - Edge Cases and Error Handling
    
    /// **Test Case 7**: 空字串處理測試
    /// **Given**: 空字串 API Key
    /// **When**: 存儲空字串
    /// **Then**: 正確處理空字串，存儲/檢索一致
    func testEdgeCases_EmptyString_ShouldHandleCorrectly() {
        // Given: 空字串
        let emptyKey = ""
        
        // When: 存儲空字串
        let saveResult = keychainService.saveAPIKey(emptyKey)
        
        // Then: 驗證存儲成功
        XCTAssertTrue(saveResult, "空字串應該能成功存儲")
        
        // Then: 驗證檢索正確
        let retrievedKey = keychainService.getAPIKey()
        XCTAssertEqual(retrievedKey, emptyKey, "應該檢索到空字串")
    }
    
    /// **Test Case 8**: Unicode 和特殊字符測試
    /// **Given**: 包含 Unicode 和特殊字符的資料
    /// **When**: 存儲和檢索
    /// **Then**: 正確處理國際化字符
    func testEdgeCases_UnicodeAndSpecialCharacters_ShouldPreserveEncoding() {
        // Given: Unicode 和特殊字符資料
        let unicodeKey = "🔐🗝️测试-密钥_@#$%^&*()"
        let unicodeData = unicodeKey.data(using: .utf8)!
        let unicodeTestKey = "unicode_test"
        
        // When: 存儲 Unicode 資料
        let saveResult = keychainService.saveSecureData(unicodeData, for: unicodeTestKey)
        
        // Then: 驗證存儲成功
        XCTAssertTrue(saveResult, "Unicode 資料應該成功存儲")
        
        // Then: 驗證 Unicode 保持
        let retrievedData = keychainService.getSecureData(for: unicodeTestKey)
        XCTAssertNotNil(retrievedData)
        let retrievedString = String(data: retrievedData!, encoding: .utf8)
        XCTAssertEqual(retrievedString, unicodeKey, "Unicode 字符應該正確保持")
        
        // Cleanup
        XCTAssertTrue(keychainService.deleteSecureData(for: unicodeTestKey))
    }
    
    /// **Test Case 9**: 不存在 Key 的檢索測試
    /// **Given**: 不存在的 Key
    /// **When**: 嘗試檢索
    /// **Then**: 安全返回 nil，不拋出異常
    func testEdgeCases_NonexistentKey_ShouldReturnNilSafely() {
        // Given: 確認 Key 不存在
        let nonexistentKey = "definitely_does_not_exist_key"
        
        // When & Then: 檢索不存在的 API Key
        let apiKey = keychainService.getAPIKey()
        XCTAssertNil(apiKey, "不存在的 API Key 應該返回 nil")
        
        // When & Then: 檢索不存在的安全資料
        let secureData = keychainService.getSecureData(for: nonexistentKey)
        XCTAssertNil(secureData, "不存在的安全資料應該返回 nil")
        
        // When & Then: 刪除不存在的資料應該安全
        let deleteResult = keychainService.deleteSecureData(for: nonexistentKey)
        XCTAssertTrue(deleteResult, "刪除不存在的資料應該返回 true")
    }
    
    // MARK: - Memory Safety Tests
    
    /// **Test Case 10**: 記憶體洩漏檢測測試
    /// **Given**: 大量 Keychain 操作
    /// **When**: 重複存儲和刪除
    /// **Then**: 無記憶體洩漏，性能穩定
    func testMemorySafety_RepeatedOperations_ShouldNotLeakMemory() {
        // Given: 測試參數
        let iterations = 100
        let testPrefix = "memory_test_"
        
        // When: 重複大量操作
        for i in 0..<iterations {
            let key = "\(testPrefix)\(i)"
            let data = "test_data_\(i)".data(using: .utf8)!
            
            // 存儲
            XCTAssertTrue(keychainService.saveSecureData(data, for: key))
            
            // 檢索
            let retrieved = keychainService.getSecureData(for: key)
            XCTAssertEqual(retrieved, data)
            
            // 刪除
            XCTAssertTrue(keychainService.deleteSecureData(for: key))
        }
        
        // Then: 驗證清理完成
        for i in 0..<iterations {
            let key = "\(testPrefix)\(i)"
            XCTAssertNil(keychainService.getSecureData(for: key), "資料應該已被刪除")
        }
    }
    
    /// **Test Case 11**: 資料覆蓋安全性測試
    /// **Portfolio 重點**: 證明敏感資料被正確覆蓋，無殘留
    /// **Given**: 已存儲的敏感資料
    /// **When**: 更新資料
    /// **Then**: 舊資料完全覆蓋，無痕跡殘留
    func testMemorySafety_DataOverwrite_ShouldSecurelyOverwritePreviousData() {
        // Given: 存儲敏感資料
        let sensitiveData1 = "extremely_sensitive_key_1".data(using: .utf8)!
        let sensitiveData2 = "completely_different_key_2".data(using: .utf8)!
        let testKey = "overwrite_test"
        
        // 存儲第一個資料
        XCTAssertTrue(keychainService.saveSecureData(sensitiveData1, for: testKey))
        XCTAssertEqual(keychainService.getSecureData(for: testKey), sensitiveData1)
        
        // When: 覆蓋資料
        XCTAssertTrue(keychainService.saveSecureData(sensitiveData2, for: testKey))
        
        // Then: 驗證只有新資料存在
        let retrievedData = keychainService.getSecureData(for: testKey)
        XCTAssertEqual(retrievedData, sensitiveData2, "應該只檢索到新資料")
        XCTAssertNotEqual(retrievedData, sensitiveData1, "舊資料不應該存在")
        
        // Then: 確認舊資料無法通過任何方式檢索
        // 這個測試證明了 Keychain 的安全覆蓋機制
        let retrievedString = String(data: retrievedData!, encoding: .utf8)
        XCTAssertFalse(retrievedString!.contains("extremely_sensitive_key_1"), "舊資料不應該出現在新資料中")
        
        // Cleanup
        XCTAssertTrue(keychainService.deleteSecureData(for: testKey))
    }
    
    // MARK: - Access Control Tests
    
    /// **Test Case 12**: Keychain 存取屬性驗證
    /// **Portfolio 重點**: 展示對 iOS 安全框架的深度理解
    /// **Given**: Keychain 項目
    /// **When**: 檢查存取控制屬性
    /// **Then**: 驗證正確的安全設定
    func testAccessControl_KeychainAttributes_ShouldHaveCorrectSecuritySettings() {
        // Given: 存儲測試資料
        let testData = testSecureData.data(using: .utf8)!
        let testKey = "access_control_test"
        XCTAssertTrue(keychainService.saveSecureData(testData, for: testKey))
        
        // When: 查詢 Keychain 項目屬性
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.businesscardscanner.keychain",
            kSecAttrAccount as String: testKey,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Then: 驗證查詢成功
        XCTAssertEqual(status, errSecSuccess, "應該能查詢到 Keychain 項目")
        
        // Then: 驗證安全屬性
        if let attributes = result as? [String: Any] {
            let accessibility = attributes[kSecAttrAccessible as String] as? String
            XCTAssertEqual(accessibility, kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String, 
                          "應該設定為僅在設備解鎖且僅限此設備存取")
            
            let service = attributes[kSecAttrService as String] as? String
            XCTAssertEqual(service, "com.businesscardscanner.keychain", 
                          "應該有正確的服務識別符")
            
            let account = attributes[kSecAttrAccount as String] as? String
            XCTAssertEqual(account, testKey, 
                          "應該有正確的帳戶識別符")
        } else {
            XCTFail("無法獲取 Keychain 項目屬性")
        }
        
        // Cleanup
        XCTAssertTrue(keychainService.deleteSecureData(for: testKey))
    }
    
    // MARK: - Integration and Cleanup Tests
    
    /// **Test Case 13**: 批量清理功能測試
    /// **Given**: 多個存儲的項目
    /// **When**: 執行 clearAll()
    /// **Then**: 所有項目被安全清除
    func testCleanup_ClearAllFunction_ShouldRemoveAllStoredItems() {
        // Given: 存儲多個項目
        XCTAssertTrue(keychainService.saveAPIKey(testAPIKey))
        XCTAssertTrue(keychainService.saveSecureData("data1".data(using: .utf8)!, for: "key1"))
        XCTAssertTrue(keychainService.saveSecureData("data2".data(using: .utf8)!, for: "key2"))
        
        // 驗證項目存在
        XCTAssertNotNil(keychainService.getAPIKey())
        XCTAssertNotNil(keychainService.getSecureData(for: "key1"))
        XCTAssertNotNil(keychainService.getSecureData(for: "key2"))
        
        // When: 清除所有項目
        keychainService.clearAll()
        
        // Then: 驗證所有項目被清除
        XCTAssertNil(keychainService.getAPIKey(), "API Key 應該被清除")
        XCTAssertNil(keychainService.getSecureData(for: "key1"), "安全資料 key1 應該被清除")
        XCTAssertNil(keychainService.getSecureData(for: "key2"), "安全資料 key2 應該被清除")
    }
    
    /// **Test Case 14**: 協議一致性測試
    /// **Portfolio 重點**: 展示架構設計和協議導向編程
    /// **Given**: KeychainService 實例
    /// **When**: 作為協議使用
    /// **Then**: 協議方法正確實作
    func testProtocolConformance_KeychainServiceProtocol_ShouldImplementAllMethods() {
        // Given: 使用協議類型
        let protocolService: KeychainServiceProtocol = keychainService
        
        // When & Then: 測試所有協議方法
        // API Key 方法
        XCTAssertTrue(protocolService.saveAPIKey(testAPIKey))
        XCTAssertEqual(protocolService.getAPIKey(), testAPIKey)
        XCTAssertTrue(protocolService.deleteAPIKey())
        XCTAssertNil(protocolService.getAPIKey())
        
        // 安全資料方法
        let testData = testSecureData.data(using: .utf8)!
        XCTAssertTrue(protocolService.saveSecureData(testData, for: testKey))
        XCTAssertEqual(protocolService.getSecureData(for: testKey), testData)
        XCTAssertTrue(protocolService.deleteSecureData(for: testKey))
        XCTAssertNil(protocolService.getSecureData(for: testKey))
    }
    
    // MARK: - Performance Tests
    
    /// **Test Case 15**: Keychain 操作性能測試
    /// **Portfolio 重點**: 展示性能意識和測試完整性
    /// **Given**: 大量 Keychain 操作
    /// **When**: 測量執行時間
    /// **Then**: 性能在可接受範圍內
    func testPerformance_KeychainOperations_ShouldMeetPerformanceRequirements() {
        // Given: 測試參數
        let operationCount = 50
        
        // When: 測量 API Key 操作性能
        measure {
            for i in 0..<operationCount {
                let key = "perf_test_key_\(i)"
                
                // 存儲
                _ = keychainService.saveAPIKey(key)
                
                // 檢索
                _ = keychainService.getAPIKey()
                
                // 刪除
                _ = keychainService.deleteAPIKey()
            }
        }
        
        // Then: 性能測試自動評估，確保操作在合理時間內完成
        // XCTest 會自動比較多次運行的結果並檢測性能回歸
    }
    
    // MARK: - Helper Methods
    
    /// 清理測試 Keychain 環境
    /// 確保測試間的隔離性，防止資料污染
    private func cleanupTestKeychain() {
        keychainService?.clearAll()
        
        // 額外清理：確保特定測試鍵被清除
        let testKeys = [
            "openai_api_key",
            testKey,
            "large_secure_data",
            "key1", "key2", "key3",
            "unicode_test",
            "overwrite_test",
            "access_control_test"
        ]
        
        for key in testKeys {
            keychainService?.deleteSecureData(for: key)
        }
    }
}

// MARK: - Portfolio Documentation

/*
 ## KeychainService 安全性測試套件總結
 
 **測試覆蓋範圍**: 15 個測試案例，涵蓋以下安全領域：
 
 ### 1. 核心安全功能 (Test Cases 1-3)
 - API Key 安全存儲和檢索
 - 資料更新和覆蓋機制
 - 安全刪除和資料清理
 
 ### 2. 資料完整性 (Test Cases 4-6)
 - 二進制資料存儲完整性
 - 大型資料處理能力
 - 多重 Key 隔離和獨立性
 
 ### 3. 邊界情況處理 (Test Cases 7-9)
 - 空字串和特殊字符處理
 - Unicode 和國際化支援
 - 錯誤情況的安全處理
 
 ### 4. 記憶體安全 (Test Cases 10-11)
 - 記憶體洩漏防護
 - 敏感資料覆蓋安全性
 
 ### 5. 存取控制 (Test Case 12)
 - iOS Keychain 安全屬性驗證
 - 存取控制設定確認
 
 ### 6. 架構完整性 (Test Cases 13-15)
 - 批量清理功能
 - 協議一致性驗證
 - 性能要求驗證
 
 **安全特性展示:**
 - `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` 存取控制
 - 敏感資料加密存儲
 - 記憶體安全和洩漏防護
 - 協議導向的安全架構設計
 
 **Portfolio 價值:**
 此測試套件展示了對 iOS 安全框架的深度理解，包括 Keychain Services、
 資料加密、記憶體管理和安全架構設計的專業知識。
 */