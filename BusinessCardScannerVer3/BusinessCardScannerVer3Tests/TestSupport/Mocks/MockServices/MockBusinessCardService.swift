import Foundation
import Combine
import UIKit
@testable import BusinessCardScannerVer3

/// Mock BusinessCardService for testing
/// 提供名片業務邏輯服務的模擬實作，支援各種測試場景
class MockBusinessCardService: BusinessCardServiceProtocol {
    
    // MARK: - Properties
    
    /// 是否應該成功
    var shouldSucceed: Bool = true
    
    /// 處理延遲（秒）
    var processingDelay: TimeInterval = 0.1
    
    /// 模擬的解析資料
    var mockParsedData: ParsedCardData?
    
    /// 模擬的已儲存名片
    var mockSavedCard: BusinessCard?
    
    /// 錯誤場景設定
    var mockError: Error?
    
    /// 呼叫記錄
    var processImageCallCount = 0
    var lastProcessedImage: UIImage?
    
    var saveBusinessCardCallCount = 0
    var lastSavedParsedData: ParsedCardData?
    var lastSavedImage: UIImage?
    var lastRawOCRText: String?
    
    // MARK: - BusinessCardServiceProtocol Implementation
    
    func processImage(_ image: UIImage) -> AnyPublisher<BusinessCardProcessingResult, Never> {
        processImageCallCount += 1
        lastProcessedImage = image
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.success(.processingFailed(MockError.serviceUnavailable)))
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.processingDelay) {
                if let error = self.mockError {
                    promise(.success(.processingFailed(error)))
                    return
                }
                
                if self.shouldSucceed {
                    let parsedData = self.mockParsedData ?? self.createDefaultParsedCardData()
                    promise(.success(.success(parsedData, croppedImage: image)))
                } else {
                    promise(.success(.ocrFailed(image)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveBusinessCard(_ parsedData: ParsedCardData, with image: UIImage?, rawOCRText: String?) -> AnyPublisher<BusinessCard, Error> {
        saveBusinessCardCallCount += 1
        lastSavedParsedData = parsedData
        lastSavedImage = image
        lastRawOCRText = rawOCRText
        
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
                    let card = self.mockSavedCard ?? self.createBusinessCard(from: parsedData, rawOCRText: rawOCRText)
                    promise(.success(card))
                } else {
                    promise(.failure(MockError.operationFailed))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    /// 重置 Mock 狀態
    func reset() {
        shouldSucceed = true
        processingDelay = 0.1
        mockParsedData = nil
        mockSavedCard = nil
        mockError = nil
        
        processImageCallCount = 0
        lastProcessedImage = nil
        
        saveBusinessCardCallCount = 0
        lastSavedParsedData = nil
        lastSavedImage = nil
        lastRawOCRText = nil
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
    
    /// 設定模擬解析資料
    func setMockParsedData(_ data: ParsedCardData) {
        mockParsedData = data
    }
    
    /// 設定模擬儲存結果
    func setMockSavedCard(_ card: BusinessCard) {
        mockSavedCard = card
    }
    
    // MARK: - Test Scenarios
    
    /// 設定高品質 OCR 成功場景
    func setHighQualityOCRScenario() {
        let highQualityData = ParsedCardData(
            name: "王大明 David Wang",
            namePhonetic: nil,
            jobTitle: "產品經理 Product Manager",
            company: "ABC科技股份有限公司",
            department: "產品部",
            email: "david.wang@abc.com.tw",
            phone: "02-1234-5678",
            mobile: "0912-345-678",
            address: "台北市信義區信義路五段7號",
            website: "www.abc.com.tw",
            confidence: 0.92,
            source: .local
        )
        setMockParsedData(highQualityData)
        setSuccessScenario()
    }
    
    /// 設定 OCR 失敗場景
    func setOCRFailureScenario() {
        shouldSucceed = false
        // OCR 失敗會返回 .ocrFailed，不會拋出錯誤
    }
    
    /// 設定儲存失敗場景
    func setSaveFailureScenario() {
        setFailureScenario(error: MockError.operationFailed)
    }
    
    // MARK: - Private Helper Methods
    
    private func createDefaultParsedCardData() -> ParsedCardData {
        return ParsedCardData(
            name: "測試用戶 Test User",
            namePhonetic: nil,
            jobTitle: "測試職位 Test Position",
            company: "測試公司 Test Company",
            department: nil,
            email: "test@example.com",
            phone: "02-1234-5678",
            mobile: "0912-345-678",
            address: nil,
            website: nil,
            confidence: 0.75,
            source: .local
        )
    }
    
    private func createBusinessCard(from parsedData: ParsedCardData, rawOCRText: String?) -> BusinessCard {
        return BusinessCard(
            id: UUID(),
            name: parsedData.name ?? "Unknown",
            namePhonetic: parsedData.namePhonetic,
            jobTitle: parsedData.jobTitle,
            company: parsedData.company,
            department: parsedData.department,
            email: parsedData.email,
            phone: parsedData.phone,
            mobile: parsedData.mobile,
            address: parsedData.address,
            website: parsedData.website,
            createdAt: Date(),
            updatedAt: Date(),
            parseSource: parsedData.source == .ai ? "ai" : parsedData.source == .local ? "local" : "manual",
            parseConfidence: parsedData.confidence,
            rawOCRText: rawOCRText
        )
    }
}

// MARK: - Mock Error Extensions

extension MockError {
    /// 處理相關的額外錯誤類型
    static let processingFailed = MockError.operationFailed
    static let creationFailed = MockError.operationFailed
}