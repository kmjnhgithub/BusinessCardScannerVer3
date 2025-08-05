import Foundation
import Combine
@testable import BusinessCardScannerVer3

/// Mock OpenAI 服務，用於測試 AI 功能
final class MockOpenAIService: OpenAIServiceProtocol {
    
    // MARK: - Mock Configuration
    
    /// 是否模擬成功回應
    var shouldSucceed: Bool = true
    
    /// 模擬錯誤
    var mockError: Error = MockError.networkUnavailable
    
    /// 回應延遲（秒）
    var responseDelay: TimeInterval = 0.5
    
    /// 是否有有效 API Key
    var hasValidKey: Bool = true
    
    /// Mock Token 使用量
    var mockTokenUsage: TokenUsage = TokenUsage(
        promptTokens: 150,
        completionTokens: 80,
        totalTokens: 230
    )
    
    // MARK: - Mock Response Data
    
    /// 預設 Mock AI 回應
    var mockAIResponse: AIResponse = AIResponse(
        id: "chatcmpl-test123",
        model: "gpt-3.5-turbo",
        choices: [
            AIResponse.Choice(
                message: AIResponse.Message(
                    role: "assistant",
                    content: """
                    {
                        "name": "王大明",
                        "namePhonetic": "Wang Da Ming",
                        "company": "ABC科技公司",
                        "jobTitle": "產品經理",
                        "department": "產品部",
                        "phone": "02-1234-5678",
                        "mobile": "0912-345-678",
                        "email": "wang@abc.com",
                        "website": "www.abc.com",
                        "address": "台北市信義區信義路五段7號",
                        "confidence": 0.92
                    }
                    """
                ),
                finishReason: "stop"
            )
        ],
        usage: TokenUsage(promptTokens: 150, completionTokens: 80, totalTokens: 230)
    )
    
    /// 不同場景的 Mock 回應
    var scenarioResponses: [String: AIResponse] = [:]
    
    // MARK: - Test Scenarios Configuration
    
    /// 網路錯誤場景
    var networkErrorScenarios: [Error] = [
        MockError.networkUnavailable,
        NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil),
        NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
    ]
    
    /// API 錯誤場景
    var apiErrorScenarios: [Error] = [
        MockError.quotaExceeded,
        NSError(domain: "OpenAI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key"]),
        NSError(domain: "OpenAI", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
    ]
    
    // MARK: - Analytics
    
    private(set) var processCallCount: Int = 0
    private(set) var lastOCRText: String?
    private(set) var lastImageData: Data?
    private(set) var responseTimes: [TimeInterval] = []
    private(set) var totalTokensUsed: Int = 0
    
    // MARK: - OpenAIServiceProtocol Implementation
    
    var tokenUsage: TokenUsage {
        return mockTokenUsage
    }
    
    func processCard(ocrText: String, imageData: Data?) -> AnyPublisher<AIResponse, Error> {
        processCallCount += 1
        lastOCRText = ocrText
        lastImageData = imageData
        
        let startTime = Date()
        
        return Future<AIResponse, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockError.serviceUnavailable))
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.responseDelay) {
                let processingTime = Date().timeIntervalSince(startTime)
                self.responseTimes.append(processingTime)
                
                if self.shouldSucceed {
                    // 更新 Token 使用統計
                    self.totalTokensUsed += self.mockTokenUsage.totalTokens
                    
                    // 根據輸入調整回應
                    let response = self.generateResponseForInput(ocrText)
                    promise(.success(response))
                } else {
                    promise(.failure(self.mockError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func hasValidAPIKey() -> Bool {
        return hasValidKey
    }
    
    // MARK: - Test Helpers
    
    /// 重置 Mock 狀態
    func reset() {
        shouldSucceed = true
        mockError = MockError.networkUnavailable
        responseDelay = 0.5
        hasValidKey = true
        
        // 重置分析數據
        processCallCount = 0
        lastOCRText = nil
        lastImageData = nil
        responseTimes.removeAll()
        totalTokensUsed = 0
        
        // 重置場景回應
        scenarioResponses.removeAll()
        setupDefaultScenarios()
    }
    
    /// 設定預設場景
    private func setupDefaultScenarios() {
        // 中文名片場景
        scenarioResponses["chinese"] = AIResponse(
            id: "chatcmpl-chinese123",
            model: "gpt-3.5-turbo",
            choices: [
                AIResponse.Choice(
                    message: AIResponse.Message(
                        role: "assistant",
                        content: """
                        {
                            "name": "王大明",
                            "namePhonetic": "Wang Da Ming",
                            "company": "ABC科技公司",
                            "jobTitle": "產品經理",
                            "phone": "02-1234-5678",
                            "mobile": "0912-345-678",
                            "email": "wang@abc.com",
                            "confidence": 0.92
                        }
                        """
                    ),
                    finishReason: "stop"
                )
            ],
            usage: mockTokenUsage
        )
        
        // 英文名片場景
        scenarioResponses["english"] = AIResponse(
            id: "chatcmpl-english123",
            model: "gpt-3.5-turbo",
            choices: [
                AIResponse.Choice(
                    message: AIResponse.Message(
                        role: "assistant",
                        content: """
                        {
                            "name": "John Smith",
                            "company": "ABC Technology Inc.",
                            "jobTitle": "Product Manager",
                            "phone": "+1-555-0123",
                            "mobile": "+1-555-0124",
                            "email": "john@abc.com",
                            "website": "www.abc-tech.com",
                            "confidence": 0.95
                        }
                        """
                    ),
                    finishReason: "stop"
                )
            ],
            usage: mockTokenUsage
        )
        
        // 複雜版面場景
        scenarioResponses["complex"] = AIResponse(
            id: "chatcmpl-complex123",
            model: "gpt-3.5-turbo",
            choices: [
                AIResponse.Choice(
                    message: AIResponse.Message(
                        role: "assistant",
                        content: """
                        {
                            "name": "李小華",
                            "company": "XYZ設計工作室",
                            "jobTitle": "創意總監",
                            "department": "設計部",
                            "phone": "02-8765-4321",
                            "mobile": "0987-654-321",
                            "email": "lee@xyz.com",
                            "website": "www.xyz-design.com",
                            "address": "台北市大安區敦化南路二段123號8樓",
                            "confidence": 0.88
                        }
                        """
                    ),
                    finishReason: "stop"
                )
            ],
            usage: TokenUsage(promptTokens: 200, completionTokens: 120, totalTokens: 320)
        )
    }
    
    /// 設定特定場景回應
    func setScenarioResponse(_ scenario: String, response: AIResponse) {
        scenarioResponses[scenario] = response
    }
    
    /// 設定網路錯誤場景
    func setNetworkErrorScenario() {
        shouldSucceed = false
        mockError = networkErrorScenarios.randomElement() ?? MockError.networkUnavailable
    }
    
    /// 設定 API 錯誤場景
    func setAPIErrorScenario() {
        shouldSucceed = false
        mockError = apiErrorScenarios.randomElement() ?? MockError.quotaExceeded
    }
    
    /// 設定無效 API Key 場景
    func setInvalidAPIKeyScenario() {
        hasValidKey = false
        shouldSucceed = false
        mockError = NSError(domain: "OpenAI", code: 401, userInfo: [
            NSLocalizedDescriptionKey: "Invalid API key provided"
        ])
    }
    
    /// 設定配額超限場景
    func setQuotaExceededScenario() {
        shouldSucceed = false
        mockError = MockError.quotaExceeded
    }
    
    /// 設定慢速回應場景
    func setSlowResponseScenario() {
        responseDelay = 5.0
    }
    
    /// 設定高品質解析場景
    func setHighQualityParsingScenario() {
        mockTokenUsage = TokenUsage(promptTokens: 180, completionTokens: 100, totalTokens: 280)
        mockAIResponse = AIResponse(
            id: "chatcmpl-hq123",
            model: "gpt-3.5-turbo",
            choices: [
                AIResponse.Choice(
                    message: AIResponse.Message(
                        role: "assistant",
                        content: """
                        {
                            "name": "王大明",
                            "namePhonetic": "Wang Da Ming",
                            "company": "ABC科技公司",
                            "jobTitle": "產品經理",
                            "department": "產品部",
                            "phone": "02-1234-5678",
                            "mobile": "0912-345-678",
                            "email": "wang@abc.com",
                            "website": "www.abc.com",
                            "address": "台北市信義區信義路五段7號",
                            "confidence": 0.98
                        }
                        """
                    ),
                    finishReason: "stop"
                )
            ],
            usage: mockTokenUsage
        )
    }
    
    /// 設定低品質解析場景
    func setLowQualityParsingScenario() {
        mockAIResponse = AIResponse(
            id: "chatcmpl-lq123",
            model: "gpt-3.5-turbo",
            choices: [
                AIResponse.Choice(
                    message: AIResponse.Message(
                        role: "assistant",
                        content: """
                        {
                            "name": "不確定",
                            "company": "無法識別",
                            "confidence": 0.45
                        }
                        """
                    ),
                    finishReason: "stop"
                )
            ],
            usage: TokenUsage(promptTokens: 220, completionTokens: 60, totalTokens: 280)
        )
    }
    
    // MARK: - Private Helpers
    
    private func generateResponseForInput(_ ocrText: String) -> AIResponse {
        // 根據 OCR 文字內容智慧選擇場景
        let lowercaseText = ocrText.lowercased()
        
        if lowercaseText.contains("john") || lowercaseText.contains("smith") {
            return scenarioResponses["english"] ?? mockAIResponse
        } else if lowercaseText.contains("李小華") || lowercaseText.contains("xyz") {
            return scenarioResponses["complex"] ?? mockAIResponse
        } else if lowercaseText.contains("王") || lowercaseText.contains("abc") {
            return scenarioResponses["chinese"] ?? mockAIResponse
        }
        
        // 預設回應
        return mockAIResponse
    }
    
    // MARK: - Test Verification
    
    /// 驗證 processCard 呼叫次數
    func verifyProcessCalled(times expectedTimes: Int) -> Bool {
        return processCallCount == expectedTimes
    }
    
    /// 驗證最後處理的 OCR 文字
    func verifyLastOCRText(contains expectedText: String) -> Bool {
        guard let lastText = lastOCRText else { return false }
        return lastText.contains(expectedText)
    }
    
    /// 驗證回應時間
    func verifyResponseTime(within expectedRange: ClosedRange<TimeInterval>) -> Bool {
        guard let lastTime = responseTimes.last else { return false }
        return expectedRange.contains(lastTime)
    }
    
    /// 取得平均回應時間
    func averageResponseTime() -> TimeInterval {
        guard !responseTimes.isEmpty else { return 0.0 }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    /// 取得 Token 使用統計
    func getTokenUsageStats() -> (total: Int, average: Double, calls: Int) {
        let averagePerCall = processCallCount > 0 ? Double(totalTokensUsed) / Double(processCallCount) : 0.0
        return (total: totalTokensUsed, average: averagePerCall, calls: processCallCount)
    }
    
    /// 驗證最後處理是否包含圖片資料
    func verifyLastRequestHadImageData() -> Bool {
        return lastImageData != nil
    }
    
    // MARK: - Debug Helpers
    
    /// 印出測試統計資訊
    func printTestStats() {
        print("🤖 MockOpenAIService 測試統計：")
        print("   呼叫次數: \(processCallCount)")
        print("   平均回應時間: \(String(format: "%.3f", averageResponseTime()))s")
        print("   總 Token 使用量: \(totalTokensUsed)")
        print("   是否成功: \(shouldSucceed)")
        print("   有效 API Key: \(hasValidKey)")
        if let lastText = lastOCRText {
            print("   最後處理文字長度: \(lastText.count) 字符")
        }
    }
    
    /// 模擬 Token 成本計算
    func calculateEstimatedCost() -> Double {
        // 假設每 1000 tokens 成本 $0.002
        let costPer1000Tokens = 0.002
        return Double(totalTokensUsed) / 1000.0 * costPer1000Tokens
    }
}