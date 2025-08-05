import Foundation
import Combine
@testable import BusinessCardScannerVer3

/// Mock 服務容器，專為測試環境設計
/// 提供所有服務的 Mock 版本，支援測試場景的靈活控制
final class MockServiceContainer {
    
    // MARK: - Singleton
    
    static let shared = MockServiceContainer()
    
    // MARK: - Core Mock Services
    
    private(set) var mockBusinessCardRepository: MockBusinessCardRepository
    private(set) var mockPhotoService: MockPhotoService
    private(set) var mockVisionService: MockVisionService
    private(set) var mockPermissionManager: MockPermissionManager
    private(set) var mockKeychainService: MockKeychainService
    private(set) var mockValidationService: MockValidationService
    private(set) var mockOpenAIService: MockOpenAIService
    
    // MARK: - Feature Mock Services
    
    private(set) var mockBusinessCardService: MockBusinessCardService
    private(set) var mockExportService: MockExportService
    private(set) var mockAICardParser: MockAICardParser
    private(set) var mockBusinessCardParser: MockBusinessCardParser
    
    // MARK: - Configuration Properties
    
    /// 全域測試模式設定
    var isTestMode: Bool = true
    
    /// 網路延遲模擬（秒）
    var networkDelay: TimeInterval = 0.1
    
    /// 是否模擬網路錯誤
    var shouldSimulateNetworkError: Bool = false
    
    /// 是否模擬權限拒絕
    var shouldSimulatePermissionDenied: Bool = false
    
    // MARK: - Initialization
    
    private init() {
        // 初始化所有 Mock 服務
        self.mockBusinessCardRepository = MockBusinessCardRepository()
        self.mockPhotoService = MockPhotoService()
        self.mockVisionService = MockVisionService()
        self.mockPermissionManager = MockPermissionManager()
        self.mockKeychainService = MockKeychainService()
        self.mockValidationService = MockValidationService()
        self.mockOpenAIService = MockOpenAIService()
        
        // 特徵服務
        self.mockBusinessCardParser = MockBusinessCardParser()
        self.mockAICardParser = MockAICardParser()  // 修正：移除不需要的參數
        self.mockExportService = MockExportService()
        
        // 業務服務
        self.mockBusinessCardService = MockBusinessCardService()  // 修正：移除不需要的參數
        
        setupMockDefaults()
    }
    
    // MARK: - Setup
    
    private func setupMockDefaults() {
        // 設定預設的 Mock 行為
        mockPermissionManager.cameraPermissionStatus = .authorized  // 這應該是正確的 AVAuthorizationStatus
        mockPermissionManager.photoLibraryPermissionStatus = true  // 修正：Bool 類型使用 true
        mockKeychainService.presetData(key: "openai_api_key", value: "sk-test-mock-api-key")
        mockVisionService.shouldSucceed = true
        mockOpenAIService.shouldSucceed = true
        
        #if DEBUG
        print("✅ MockServiceContainer initialized with default mock behaviors")
        #endif
    }
    
    // MARK: - Test Scenarios
    
    /// 重置所有 Mock 為預設狀態
    func resetToDefaults() {
        shouldSimulateNetworkError = false
        shouldSimulatePermissionDenied = false
        networkDelay = 0.1
        
        // 重置個別服務
        mockBusinessCardRepository.reset()
        mockPhotoService.reset()
        mockVisionService.reset()
        mockPermissionManager.reset()
        mockKeychainService.resetMockState()
        mockValidationService.resetMockState()
        mockOpenAIService.reset()
        
        setupMockDefaults()
    }
    
    /// 設定無網路場景
    func simulateOfflineScenario() {
        shouldSimulateNetworkError = true
        mockOpenAIService.shouldSucceed = false
        mockOpenAIService.mockError = MockServiceError.networkUnavailable  // 修正：使用正確的錯誤類型
    }
    
    /// 設定權限拒絕場景
    func simulatePermissionDeniedScenario() {
        shouldSimulatePermissionDenied = true
        mockPermissionManager.cameraPermissionStatus = .denied
        mockPermissionManager.photoLibraryPermissionStatus = false  // 修正：Bool 類型使用 false
    }
    
    /// 設定低品質 OCR 場景
    func simulatePoorOCRScenario() {
        mockVisionService.mockConfidence = 0.3
        mockVisionService.mockRecognizedText = "模糊文字 123"
    }
    
    /// 設定 API 配額超限場景
    func simulateAPIQuotaExceededScenario() {
        mockOpenAIService.shouldSucceed = false
        mockOpenAIService.mockError = MockServiceError.quotaExceeded  // 修正：使用正確的錯誤類型
    }
    
    // MARK: - Dependency Injection Helpers
    
    /// 為 ViewModel 提供 Mock 依賴
    func makeMockDependencies() -> MockDependencies {
        return MockDependencies(
            repository: mockBusinessCardRepository,
            businessCardService: mockBusinessCardService,
            photoService: mockPhotoService,
            visionService: mockVisionService,
            permissionManager: mockPermissionManager,
            validationService: mockValidationService,
            exportService: mockExportService
        )
    }
}

// MARK: - Mock Dependencies Protocol

/// Mock 依賴協議，用於依賴注入
struct MockDependencies {
    let repository: MockBusinessCardRepository
    let businessCardService: MockBusinessCardService
    let photoService: MockPhotoService
    let visionService: MockVisionService
    let permissionManager: MockPermissionManager
    let validationService: MockValidationService
    let exportService: MockExportService
}

// MARK: - Mock Errors

enum MockServiceError: Error, LocalizedError {
    case networkUnavailable
    case quotaExceeded
    case permissionDenied
    case ocrFailed
    case dataCorrupted
    case mockError
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "網路連線不可用"
        case .quotaExceeded:
            return "API 配額已超限"
        case .permissionDenied:
            return "權限被拒絕"
        case .ocrFailed:
            return "OCR 識別失敗"
        case .dataCorrupted:
            return "資料損壞"
        case .mockError:
            return "Mock 測試錯誤"
        }
    }
}

// MARK: - Test Helpers

extension MockServiceContainer {
    
    /// 快速設定成功場景
    func setupSuccessScenario() {
        resetToDefaults()
        mockBusinessCardRepository.shouldSucceed = true
        mockVisionService.shouldSucceed = true
        mockOpenAIService.shouldSucceed = true
    }
    
    /// 快速設定失敗場景
    func setupFailureScenario() {
        mockBusinessCardRepository.shouldSucceed = false
        mockVisionService.shouldSucceed = false
        mockOpenAIService.shouldSucceed = false
    }
    
    /// 快速設定延遲場景
    func setupSlowNetworkScenario() {
        networkDelay = 2.0
        mockOpenAIService.responseDelay = 2.0
        mockVisionService.processingDelay = 1.5
    }
}