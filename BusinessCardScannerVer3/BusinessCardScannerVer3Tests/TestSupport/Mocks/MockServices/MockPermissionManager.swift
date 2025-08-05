import Foundation
import Combine
import AVFoundation
@testable import BusinessCardScannerVer3

/// Mock 權限管理器，用於測試權限相關功能
final class MockPermissionManager: PermissionManagerProtocol {
    
    // MARK: - Mock Configuration
    
    /// 相機權限狀態
    var cameraPermissionStatus: AVAuthorizationStatus = .authorized
    
    /// 照片庫權限狀態
    var photoLibraryPermissionStatus: Bool = true
    
    /// 是否模擬權限請求延遲
    var simulateDelay: Bool = false
    
    /// 權限請求延遲時間
    var permissionDelay: TimeInterval = 0.2
    
    // MARK: - Analytics
    
    private(set) var cameraPermissionRequestCount: Int = 0
    private(set) var photoLibraryPermissionRequestCount: Int = 0
    private(set) var cameraPermissionCheckCount: Int = 0
    private(set) var photoLibraryPermissionCheckCount: Int = 0
    
    // MARK: - PermissionManagerProtocol Implementation
    
    func requestCameraPermission() -> AnyPublisher<AVAuthorizationStatus, Never> {
        cameraPermissionRequestCount += 1
        
        return Future<AVAuthorizationStatus, Never> { [weak self] promise in
            guard let self = self else {
                promise(.success(.denied))
                return
            }
            
            let delay = self.simulateDelay ? self.permissionDelay : 0.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                promise(.success(self.cameraPermissionStatus))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func requestPhotoLibraryPermission() -> AnyPublisher<Bool, Never> {
        photoLibraryPermissionRequestCount += 1
        
        return Future<Bool, Never> { [weak self] promise in
            guard let self = self else {
                promise(.success(false))
                return
            }
            
            let delay = self.simulateDelay ? self.permissionDelay : 0.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                promise(.success(self.photoLibraryPermissionStatus))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func checkCameraPermission() -> AVAuthorizationStatus {
        cameraPermissionCheckCount += 1
        return cameraPermissionStatus
    }
    
    func checkPhotoLibraryPermission() -> Bool {
        photoLibraryPermissionCheckCount += 1
        return photoLibraryPermissionStatus
    }
    
    // MARK: - Test Helpers
    
    /// 重置 Mock 狀態
    func reset() {
        cameraPermissionStatus = .authorized
        photoLibraryPermissionStatus = true
        simulateDelay = false
        permissionDelay = 0.2
        
        cameraPermissionRequestCount = 0
        photoLibraryPermissionRequestCount = 0
        cameraPermissionCheckCount = 0
        photoLibraryPermissionCheckCount = 0
    }
    
    /// 設定權限拒絕場景
    func setPermissionDeniedScenario() {
        cameraPermissionStatus = .denied
        photoLibraryPermissionStatus = false
    }
    
    /// 設定未決定權限場景
    func setPermissionNotDeterminedScenario() {
        cameraPermissionStatus = .notDetermined
        photoLibraryPermissionStatus = false
    }
    
    /// 設定受限權限場景  
    func setPermissionRestrictedScenario() {
        cameraPermissionStatus = .restricted
        photoLibraryPermissionStatus = false
    }
    
    /// 模擬權限從拒絕變為允許的場景
    func simulatePermissionGranted() {
        cameraPermissionStatus = .authorized
        photoLibraryPermissionStatus = true
    }
}

/// Mock Keychain 服務
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
    func reset() {
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
    
    /// 取得目前儲存的資料數量
    var storedDataCount: Int {
        return mockStorage.count
    }
}

/// Mock 驗證服務
final class MockValidationService: ValidationServiceProtocol {
    
    // MARK: - Mock Configuration
    
    /// 是否模擬嚴格驗證
    var strictValidation: Bool = false
    
    // MARK: - Analytics
    
    private(set) var emailValidationCount: Int = 0
    private(set) var phoneValidationCount: Int = 0
    private(set) var websiteValidationCount: Int = 0
    
    // MARK: - ValidationServiceProtocol Implementation
    
    func validateEmail(_ email: String) -> Bool {
        emailValidationCount += 1
        
        if strictValidation {
            // 嚴格驗證
            let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: email)
        } else {
            // 寬鬆驗證
            return email.contains("@") && email.contains(".")
        }
    }
    
    func validatePhone(_ phone: String) -> Bool {
        phoneValidationCount += 1
        
        if strictValidation {
            // 嚴格的台灣電話格式驗證
            let phoneRegex = "^(02|03|04|05|06|07|08|09)[0-9-]{7,}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            return phonePredicate.evaluate(with: phone)
        } else {
            // 寬鬆驗證
            return phone.count >= 8 && phone.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        }
    }
    
    func validateWebsite(_ website: String) -> Bool {
        websiteValidationCount += 1
        
        if strictValidation {
            // 嚴格的網址驗證
            let urlString = website.hasPrefix("http") ? website : "https://\(website)"
            guard let url = URL(string: urlString),
                  let host = url.host, !host.isEmpty else { return false }
            
            let hostRegex = "^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$"
            let hostPredicate = NSPredicate(format: "SELF MATCHES %@", hostRegex)
            return hostPredicate.evaluate(with: host)
        } else {
            // 寬鬆驗證
            return website.contains(".") && website.count > 3
        }
    }
    
    func validateRequiredField(_ text: String) -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func validateName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 1 && trimmedName.count <= 50
    }
    
    // MARK: - Test Helpers
    
    /// 重置 Mock 狀態
    func reset() {
        strictValidation = false
        emailValidationCount = 0
        phoneValidationCount = 0
        websiteValidationCount = 0
    }
    
    /// 設定嚴格驗證模式
    func setStrictValidation(_ strict: Bool) {
        strictValidation = strict
    }
}