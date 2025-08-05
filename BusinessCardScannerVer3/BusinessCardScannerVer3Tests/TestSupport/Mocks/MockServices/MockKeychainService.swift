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
class MockKeychainService {
    
    // MARK: - Mock Storage
    
    private var mockStorage: [String: String] = [:]
    private var shouldFailOperations = false
    private var failureKeys: Set<String> = []
    
    // MARK: - Mock Configuration
    
    /// Configure the mock to simulate failure scenarios
    /// - Parameter shouldFail: Whether operations should fail
    func configureShouldFail(_ shouldFail: Bool) {
        shouldFailOperations = shouldFail
    }
    
    /// Configure specific keys to fail
    /// - Parameter keys: Set of keys that should fail operations
    func configureFailureKeys(_ keys: Set<String>) {
        failureKeys = keys
    }
    
    /// Reset mock state to default
    func resetMockState() {
        mockStorage.removeAll()
        shouldFailOperations = false
        failureKeys.removeAll()
    }
    
    // MARK: - KeychainService Mock Implementation
    
    func saveString(_ string: String, for key: String) -> Bool {
        // Simulate failure scenarios
        if shouldFailOperations || failureKeys.contains(key) {
            return false
        }
        
        // Simulate successful storage
        mockStorage[key] = string
        return true
    }
    
    func loadString(for key: String) -> String? {
        // Simulate failure scenarios
        if shouldFailOperations || failureKeys.contains(key) {
            return nil
        }
        
        // Return stored value
        return mockStorage[key]
    }
    
    @discardableResult
    func deleteString(for key: String) -> Bool {
        // Simulate failure scenarios
        if shouldFailOperations || failureKeys.contains(key) {
            return false
        }
        
        // Remove from storage
        mockStorage.removeValue(forKey: key)
        return true
    }
    
    func clearAll() {
        if !shouldFailOperations {
            mockStorage.removeAll()
        }
    }
    
    // MARK: - Test Utilities
    
    /// Get current mock storage for verification
    /// - Returns: Current storage dictionary
    func getMockStorage() -> [String: String] {
        return mockStorage
    }
    
    /// Check if a key exists in mock storage
    /// - Parameter key: Key to check
    /// - Returns: Whether the key exists
    func keyExists(_ key: String) -> Bool {
        return mockStorage[key] != nil
    }
    
    /// Get the number of stored items
    /// - Returns: Count of stored items
    func getStoredItemCount() -> Int {
        return mockStorage.count
    }
    
    /// Preset data for testing scenarios
    /// - Parameters:
    ///   - key: Storage key
    ///   - value: Storage value
    func presetData(key: String, value: String) {
        mockStorage[key] = value
    }
    
    /// Simulate common API key scenarios
    func setupCommonTestScenarios() {
        // Preset OpenAI API key for testing
        mockStorage["openai_api_key"] = "test-api-key-12345"
        
        // Preset other common keys
        mockStorage["user_preferences"] = "test-preferences"
        mockStorage["device_id"] = "test-device-id"
    }
}