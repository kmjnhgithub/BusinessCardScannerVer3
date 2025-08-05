import Foundation
import Combine
import UIKit
@testable import BusinessCardScannerVer3

/// Mock AICardParser for testing
/// 提供 AI 名片解析器的模擬實作，支援各種測試場景
class MockAICardParser: AICardParserProtocol {
    
    // MARK: - Properties
    
    /// 是否可用
    var isServiceAvailable: Bool = true
    
    /// 是否應該成功
    var shouldSucceed: Bool = true
    
    /// 處理延遲（秒）
    var processingDelay: TimeInterval = 0.1
    
    /// 模擬的解析結果
    var mockParsedData: ParsedCardData?
    
    /// 錯誤場景設定
    var mockError: Error?
    
    /// 呼叫記錄
    var parseCardCallCount = 0
    var lastOCRText: String?
    var lastImageData: Data?
    
    var isAvailableCallCount = 0
    
    // MARK: - AICardParserProtocol Implementation
    
    var isAvailable: Bool {
        isAvailableCallCount += 1
        return isServiceAvailable
    }
    
    func parseCard(request: AIProcessingRequest) -> AnyPublisher<ParsedCardData, Error> {
        parseCardCallCount += 1
        lastOCRText = request.ocrText
        lastImageData = request.imageData
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockError.serviceUnavailable))
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.processingDelay) {
                if !self.isServiceAvailable {
                    promise(.failure(AIParserError.serviceUnavailable))
                    return
                }
                
                if let error = self.mockError {
                    promise(.failure(error))
                    return
                }
                
                if self.shouldSucceed {
                    let result = self.mockParsedData ?? self.createDefaultParsedData(from: request.ocrText)
                    promise(.success(result))
                } else {
                    promise(.failure(AIParserError.parsingFailed))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    /// 重置 Mock 狀態
    func reset() {
        isServiceAvailable = true
        shouldSucceed = true
        processingDelay = 0.1
        mockParsedData = nil
        mockError = nil
        
        parseCardCallCount = 0
        lastOCRText = nil
        lastImageData = nil
        
        isAvailableCallCount = 0
    }
    
    /// 設定服務可用性
    func setServiceAvailable(_ available: Bool) {
        isServiceAvailable = available
    }
    
    /// 設定失敗場景
    func setFailureScenario(error: Error = AIParserError.parsingFailed) {
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
    func setMockParsedData(_ data: ParsedCardData) {
        mockParsedData = data
    }
    
    /// 設定網路錯誤場景
    func setNetworkErrorScenario() {
        setFailureScenario(error: AIParserError.networkError)
    }
    
    /// 設定 API 配額超限場景
    func setQuotaExceededScenario() {
        setFailureScenario(error: AIParserError.quotaExceeded)
    }
    
    /// 設定無效 API Key 場景
    func setInvalidAPIKeyScenario() {
        setFailureScenario(error: AIParserError.invalidAPIKey)
    }
    
    /// 設定服務不可用場景
    func setServiceUnavailableScenario() {
        setServiceAvailable(false)
    }
    
    /// 設定高品質解析場景
    func setHighQualityParsingScenario() {
        let highQualityData = ParsedCardData(
            name: "王大明 David Wang",
            namePhonetic: nil,
            jobTitle: "產品經理 Product Manager",
            company: "ABC科技股份有限公司 ABC Technology Co., Ltd.",
            department: "產品部 Product Department",
            email: "david.wang@abc.com.tw",
            phone: "02-1234-5678",
            mobile: "0912-345-678",
            address: "台北市信義區信義路五段7號",
            website: "www.abc.com.tw",
            confidence: 0.95,
            source: .ai
        )
        setMockParsedData(highQualityData)
        setSuccessScenario()
    }
    
    /// 設定中品質解析場景（部分欄位缺失）
    func setMediumQualityParsingScenario() {
        let mediumQualityData = ParsedCardData(
            name: "李小華",
            namePhonetic: nil,
            jobTitle: "創意總監",
            company: "XYZ設計工作室",
            department: nil,
            email: "lisa@xyz.com",
            phone: "02-5678-1234",
            mobile: nil,
            address: nil,
            website: nil,
            confidence: 0.78,
            source: .ai
        )
        setMockParsedData(mediumQualityData)
        setSuccessScenario()
    }
    
    /// 設定低品質解析場景（僅基本資訊）
    func setLowQualityParsingScenario() {
        let lowQualityData = ParsedCardData(
            name: "張志偉",
            namePhonetic: nil,
            jobTitle: nil,
            company: nil,
            department: nil,
            email: nil,
            phone: "02-9999-8888",
            mobile: nil,
            address: nil,
            website: nil,
            confidence: 0.65,
            source: .ai
        )
        setMockParsedData(lowQualityData)
        setSuccessScenario()
    }
    
    // MARK: - Private Helper Methods
    
    private func createDefaultParsedData(from ocrText: String) -> ParsedCardData {
        // 簡單的文字解析邏輯，模擬 AI 處理結果
        let lines = ocrText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        var name: String?
        var company: String?
        var phone: String?
        var email: String?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 簡單的欄位識別邏輯
            if name == nil && !trimmedLine.contains("@") && !trimmedLine.contains("-") {
                name = trimmedLine
            } else if phone == nil && (trimmedLine.contains("-") || trimmedLine.hasPrefix("09")) {
                phone = trimmedLine
            } else if email == nil && trimmedLine.contains("@") {
                email = trimmedLine
            } else if company == nil && name != nil {
                company = trimmedLine
            }
        }
        
        return ParsedCardData(
            name: name ?? "Unknown",
            namePhonetic: nil,
            jobTitle: nil,
            company: company,
            department: nil,
            email: email,
            phone: phone,
            mobile: nil,
            address: nil,
            website: nil,
            confidence: 0.80,
            source: .ai
        )
    }
}

// MARK: - AI Parser Error Types

enum AIParserError: Error, LocalizedError {
    case serviceUnavailable
    case parsingFailed
    case networkError
    case quotaExceeded
    case invalidAPIKey
    case invalidResponse
    case timeoutError
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI 服務不可用"
        case .parsingFailed:
            return "AI 解析失敗"
        case .networkError:
            return "網路連接錯誤"
        case .quotaExceeded:
            return "API 配額已用完"
        case .invalidAPIKey:
            return "API Key 無效"
        case .invalidResponse:
            return "AI 回應格式無效"
        case .timeoutError:
            return "處理逾時"
        }
    }
}

// MARK: - Test Scenario Extensions

extension MockAICardParser {
    
    /// 建立多語言測試場景
    func setupMultiLanguageScenarios() -> [String: ParsedCardData] {
        return [
            "chinese": ParsedCardData(
                name: "王大明",
                namePhonetic: nil,
                jobTitle: "產品經理",
                company: "ABC科技股份有限公司",
                department: nil,
                email: "wang@abc.com.tw",
                phone: "02-1234-5678",
                mobile: "0912-345-678",
                address: nil,
                website: nil,
                confidence: 0.90,
                source: .ai
            ),
            "english": ParsedCardData(
                name: "David Wang",
                namePhonetic: nil,
                jobTitle: "Product Manager",
                company: "ABC Technology Co., Ltd.",
                department: nil,
                email: "david.wang@abc.com",
                phone: "+886-2-1234-5678",
                mobile: "+886-912-345-678",
                address: nil,
                website: nil,
                confidence: 0.92,
                source: .ai
            ),
            "mixed": ParsedCardData(
                name: "王大明 David Wang",
                namePhonetic: nil,
                jobTitle: "產品經理 Product Manager",
                company: "ABC科技 ABC Technology",
                department: nil,
                email: "david.wang@abc.com.tw",
                phone: "02-1234-5678",
                mobile: "0912-345-678",
                address: nil,
                website: nil,
                confidence: 0.88,
                source: .ai
            )
        ]
    }
    
    /// 建立效能測試場景
    func setupPerformanceTestScenario(delay: TimeInterval = 0.001) {
        setProcessingDelay(delay)
        setSuccessScenario()
    }
    
    /// 建立壓力測試場景
    func setupStressTestScenario() {
        setProcessingDelay(0.001) // 最小延遲
        setSuccessScenario()
    }
}