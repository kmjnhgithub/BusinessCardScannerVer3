import Foundation
import Combine
@testable import BusinessCardScannerVer3

/// Mock ExportService for testing
/// 提供資料匯出服務的模擬實作，支援各種測試場景
/// 需添加 MockError.exportFailed 支援
class MockExportService: ExportServiceProtocol {
    
    // MARK: - Properties
    
    /// 是否應該成功
    var shouldSucceed: Bool = true
    
    /// 處理延遲（秒）
    var processingDelay: TimeInterval = 0.1
    
    /// 模擬的 CSV 匯出檔案 URL
    var mockCSVURL: URL?
    
    /// 模擬的 vCard 匯出檔案 URL
    var mockVCardURL: URL?
    
    /// 模擬的儲存資訊
    var mockStorageInfo: StorageInfo?
    
    /// 錯誤場景設定
    var mockError: Error?
    
    /// 呼叫記錄
    var exportToCSVCallCount = 0
    var lastCSVExportCards: [BusinessCard] = []
    
    var exportToVCardCallCount = 0
    var lastVCardExportCards: [BusinessCard] = []
    
    // MARK: - ExportServiceProtocol Implementation
    
    func exportAsCSV(cards: [BusinessCard]) -> AnyPublisher<URL, Error> {
        exportToCSVCallCount += 1
        lastCSVExportCards = cards
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockError.serviceUnavailable))
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.processingDelay) {
                if let error = self.mockError {
                    promise(.failure(error))
                    return
                }
                
                if self.shouldSucceed {
                    let url = self.mockCSVURL ?? self.createMockCSVURL()
                    promise(.success(url))
                } else {
                    promise(.failure(MockError.operationFailed))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func exportAsVCard(cards: [BusinessCard]) -> AnyPublisher<URL, Error> {
        exportToVCardCallCount += 1
        lastVCardExportCards = cards
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockError.serviceUnavailable))
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.processingDelay) {
                if let error = self.mockError {
                    promise(.failure(error))
                    return
                }
                
                if self.shouldSucceed {
                    let url = self.mockVCardURL ?? self.createMockVCardURL()
                    promise(.success(url))
                } else {
                    promise(.failure(MockError.operationFailed))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Note: calculateStorageUsage method removed as it's not part of ExportServiceProtocol
    
    // MARK: - Helper Methods
    
    /// 重置 Mock 狀態
    func reset() {
        shouldSucceed = true
        processingDelay = 0.1
        mockCSVURL = nil
        mockVCardURL = nil
        mockStorageInfo = nil
        mockError = nil
        
        exportToCSVCallCount = 0
        lastCSVExportCards = []
        
        exportToVCardCallCount = 0
        lastVCardExportCards = []
        
        // Note: calculateStorageUsageCallCount removed
    }
    
    /// 設定失敗場景
    func setFailureScenario(error: Error = MockError.operationFailed) {
        shouldSucceed = false
        mockError = error
    }
    
    /// 設定成功場景
    func setSuccessScenario() {
        shouldSucceed = true
        mockError = nil
    }
    
    /// 設定處理延遲
    func setProcessingDelay(_ delay: TimeInterval) {
        processingDelay = delay
    }
    
    /// 設定模擬結果
    func setMockCSVURL(_ url: URL) {
        mockCSVURL = url
    }
    
    func setMockVCardURL(_ url: URL) {
        mockVCardURL = url
    }
    
    func setMockStorageInfo(_ info: StorageInfo) {
        mockStorageInfo = info
    }
    
    /// 設定大檔案場景（用於測試大量資料匯出）
    func setLargeFileScenario() {
        processingDelay = 2.0
        mockStorageInfo = StorageInfo(
            totalSize: 50 * 1024 * 1024, // 50MB
            imageSize: 40 * 1024 * 1024,  // 40MB
            databaseSize: 10 * 1024 * 1024, // 10MB
            cardCount: 5000
        )
    }
    
    /// 設定磁碟空間不足場景
    func setDiskFullScenario() {
        setFailureScenario(error: MockError.operationFailed)
    }
    
    /// 設定權限不足場景
    func setPermissionDeniedScenario() {
        setFailureScenario(error: MockError.operationFailed)
    }
    
    // MARK: - Private Helper Methods
    
    private func createMockCSVURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("mock_business_cards_\(Date().timeIntervalSince1970).csv")
    }
    
    private func createMockVCardURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("mock_business_cards_\(Date().timeIntervalSince1970).vcf")
    }
    
    private func createDefaultStorageInfo() -> StorageInfo {
        return StorageInfo(
            totalSize: 5 * 1024 * 1024,   // 5MB
            imageSize: 3 * 1024 * 1024,   // 3MB
            databaseSize: 2 * 1024 * 1024, // 2MB
            cardCount: 100
        )
    }
}

// MARK: - Export Error Types
// Note: Using MockError from ServiceProtocols.swift instead of defining separate ExportError

// MARK: - Export Test Scenarios

extension MockExportService {
    
    /// 設定 CSV 匯出成功場景
    func setupCSVSuccessScenario() -> URL {
        let url = createMockCSVURL()
        setMockCSVURL(url)
        setSuccessScenario()
        return url
    }
    
    /// 設定 vCard 匯出成功場景
    func setupVCardSuccessScenario() -> URL {
        let url = createMockVCardURL()
        setMockVCardURL(url)
        setSuccessScenario()
        return url
    }
    
    /// 設定多格式匯出測試場景
    func setupMultiFormatExportScenario() -> (csvURL: URL, vCardURL: URL) {
        let csvURL = setupCSVSuccessScenario()
        let vCardURL = setupVCardSuccessScenario()
        return (csvURL: csvURL, vCardURL: vCardURL)
    }
    
    /// 模擬實際建立測試檔案（用於整合測試）
    func createActualTestFiles() {
        if let csvURL = mockCSVURL {
            let csvContent = "Name,Company,Phone,Email\nTest User,Test Company,02-1234-5678,test@example.com"
            try? csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        }
        
        if let vCardURL = mockVCardURL {
            let vCardContent = """
            BEGIN:VCARD
            VERSION:3.0
            FN:Test User
            ORG:Test Company
            TEL:02-1234-5678
            EMAIL:test@example.com
            END:VCARD
            """
            try? vCardContent.write(to: vCardURL, atomically: true, encoding: .utf8)
        }
    }
    
    /// 清理測試檔案
    func cleanupTestFiles() {
        if let csvURL = mockCSVURL {
            try? FileManager.default.removeItem(at: csvURL)
        }
        
        if let vCardURL = mockVCardURL {
            try? FileManager.default.removeItem(at: vCardURL)
        }
    }
}