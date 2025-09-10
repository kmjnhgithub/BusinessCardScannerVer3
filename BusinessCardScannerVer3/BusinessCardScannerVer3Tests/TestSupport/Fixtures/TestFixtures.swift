import Foundation
import UIKit
import XCTest
@testable import BusinessCardScannerVer3

/// 測試夾具（Test Fixtures）
/// 提供預設的測試環境設定和便利方法
struct TestFixtures {
    
    // MARK: - Test Environment Setup
    
    /// 設定標準測試環境
    static func setupStandardTestEnvironment() -> MockServiceContainer {
        let container = MockServiceContainer.shared
        container.resetToDefaults()
        
        // 設定成功場景
        container.getMockBusinessCardRepository().shouldSucceed = true
        container.getMockVisionService().shouldSucceed = true
        container.getMockOpenAIService().shouldSucceed = true
        
        // 設定合理的延遲
        container.networkDelay = 0.1
        container.getMockVisionService().processingDelay = 0.2
        container.getMockOpenAIService().responseDelay = 0.3
        
        return container
    }
    
    /// 設定測試失敗環境
    static func setupFailureTestEnvironment() -> MockServiceContainer {
        let container = MockServiceContainer.shared
        container.resetToDefaults()
        container.setupFailureScenario()
        return container
    }
    
    /// 設定離線測試環境
    static func setupOfflineTestEnvironment() -> MockServiceContainer {
        let container = MockServiceContainer.shared
        container.resetToDefaults()
        container.simulateOfflineScenario()
        return container
    }
    
    // MARK: - Repository Test Fixtures
    
    /// 設定包含標準資料的 Repository
    static func setupRepositoryWithStandardData() -> MockBusinessCardRepository {
        let repository = MockBusinessCardRepository()
        repository.reset()
        
        // 加入標準測試資料
        for card in MockData.standardCards {
            repository.addMockCard(card)
        }
        
        return repository
    }
    
    /// 設定空的 Repository
    static func setupEmptyRepository() -> MockBusinessCardRepository {
        let repository = MockBusinessCardRepository()
        repository.reset()
        repository.setEmptyDataSet()
        return repository
    }
    
    /// 設定大量資料的 Repository（效能測試用）
    static func setupLargeDataRepository(cardCount: Int = 1000) -> MockBusinessCardRepository {
        let repository = MockBusinessCardRepository()
        repository.reset()
        repository.setLargeDataSet(count: cardCount)
        return repository
    }
    
    // MARK: - Vision Service Test Fixtures
    
    /// 設定高品質 OCR 場景
    static func setupHighQualityOCR() -> MockVisionService {
        let service = MockVisionService()
        service.reset()
        service.setQualityScenario("high")
        return service
    }
    
    /// 設定低品質 OCR 場景
    static func setupLowQualityOCR() -> MockVisionService {
        let service = MockVisionService()
        service.reset()
        service.setQualityScenario("poor")
        return service
    }
    
    /// 設定 OCR 失敗場景
    static func setupOCRFailure() -> MockVisionService {
        let service = MockVisionService()
        service.reset()
        service.setNoTextScenario()
        return service
    }
    
    // MARK: - OpenAI Service Test Fixtures
    
    /// 設定 AI 成功場景
    static func setupAISuccess() -> MockOpenAIService {
        let service = MockOpenAIService()
        service.reset()
        service.shouldSucceed = true
        service.mockAIResponse = MockData.successfulAIResponse
        return service
    }
    
    /// 設定 AI 網路錯誤場景
    static func setupAINetworkError() -> MockOpenAIService {
        let service = MockOpenAIService()
        service.reset()
        service.setNetworkErrorScenario()
        return service
    }
    
    /// 設定 API Key 無效場景
    static func setupInvalidAPIKey() -> MockOpenAIService {
        let service = MockOpenAIService()
        service.reset()
        service.setInvalidAPIKeyScenario()
        return service
    }
    
    // MARK: - Test Data Builders
    
    /// 建立測試用的 BusinessCard
    static func buildTestCard(
        name: String = "測試用戶 Test User",
        company: String = "測試公司 Test Company",
        email: String = "test@example.com",
        phone: String = "02-1234-5678",
        parseSource: String = "manual"
    ) -> BusinessCard {
        return BusinessCard(
            id: UUID(),
            name: name,
            company: company,
            email: email,
            phone: phone,
            createdAt: Date(),
            updatedAt: Date(),
            parseSource: parseSource
        )
    }
    
    /// 建立測試用的 OCRResult
    static func buildTestOCRResult(
        text: String = "測試文字 Test Text",
        confidence: Float = 0.85
    ) -> OCRResult {
        return OCRResult(
            recognizedText: text,
            confidence: confidence,
            boundingBoxes: [TextBoundingBox(text: text, confidence: confidence, boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20), topCandidates: [text])],
            processingTime: 1.0
        )
    }
    
    /// 建立測試用的 AIResponse
    static func buildTestAIResponse(
        name: String = "測試用戶 Test User",
        company: String = "測試公司 Test Company",
        confidence: Double = 0.9
    ) -> AIResponse {
        let message = AIResponse.Message(
            role: "assistant", 
            content: "{\"name\": \"\(name)\", \"company\": \"\(company)\", \"confidence\": \(confidence)}"
        )
        let choice = AIResponse.Choice(message: message, finishReason: "stop")
        let usage = TokenUsage(promptTokens: 100, completionTokens: 50, totalTokens: 150)
        
        return AIResponse(
            id: "test-response-id",
            model: "gpt-4o-mini",
            choices: [choice],
            usage: usage
        )
    }
    
    // MARK: - Test Scenario Builders
    
    /// 建立完整的名片建立測試場景
    static func buildCardCreationScenario(
        withImage: Bool = true,
        ocrSuccess: Bool = true,
        aiSuccess: Bool = true
    ) -> (image: UIImage?, ocrResult: OCRResult?, aiResponse: AIResponse?) {
        
        let image = withImage ? MockImages.standardImage : nil
        
        let ocrResult = ocrSuccess ? MockData.highQualityOCR : nil
        
        let aiResponse = aiSuccess ? MockData.successfulAIResponse : nil
        
        return (image: image, ocrResult: ocrResult, aiResponse: aiResponse)
    }
    
    /// 建立搜尋測試場景
    static func buildSearchScenario() -> [BusinessCard] {
        return [
            buildTestCard(name: "王大明 David Wang", company: "ABC科技 ABC Tech"),
            buildTestCard(name: "李小華 Lisa Lee", company: "XYZ設計 XYZ Design"),
            buildTestCard(name: "張志偉 Jason Chang", company: "科技解決方案 Tech Solutions"),
            buildTestCard(name: "陳美玲 Mei-Ling Chen", company: "設計工作室 Design Studio")
        ]
    }
    
    // MARK: - Performance Test Helpers
    
    /// 建立效能測試場景
    static func buildPerformanceTestScenario(
        cardCount: Int = 1000,
        simulateDelay: Bool = false
    ) -> MockServiceContainer {
        let container = MockServiceContainer.shared
        container.resetToDefaults()
        
        // 設定大量資料
        container.getMockBusinessCardRepository().setLargeDataSet(count: cardCount)
        
        if simulateDelay {
            container.networkDelay = 0.5
            container.getMockVisionService().processingDelay = 1.0
            container.getMockOpenAIService().responseDelay = 2.0
        } else {
            // 快速回應用於效能測試
            container.networkDelay = 0.01
            container.getMockVisionService().processingDelay = 0.01
            container.getMockOpenAIService().responseDelay = 0.01
        }
        
        return container
    }
}

// MARK: - Test Assertions Helpers

/// 測試斷言輔助工具
struct TestAssertions {
    
    /// 驗證名片資料是否有效
    static func assertValidBusinessCard(_ card: BusinessCard, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(card.name.isEmpty, "名片姓名不能為空", file: file, line: line)
        XCTAssertNotNil(card.id, "名片 ID 不能為 nil", file: file, line: line)
        XCTAssertNotNil(card.createdAt, "建立時間不能為 nil", file: file, line: line)
    }
    
    /// 驗證 OCR 結果是否有效
    static func assertValidOCRResult(_ result: OCRResult, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(result.recognizedText.isEmpty, "OCR 文字不能為空", file: file, line: line)
        XCTAssertGreaterThan(result.confidence, 0.0, "OCR 信心度必須大於 0", file: file, line: line)
        XCTAssertLessThanOrEqual(result.confidence, 1.0, "OCR 信心度不能超過 1", file: file, line: line)
        XCTAssertGreaterThan(result.processingTime, 0.0, "處理時間必須大於 0", file: file, line: line)
    }
    
    /// 驗證 AI 回應是否有效
    static func assertValidAIResponse(_ response: AIResponse, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(response.id.isEmpty, "AI 回應 ID 不能為空", file: file, line: line)
        XCTAssertFalse(response.choices.isEmpty, "AI 回應選擇不能為空", file: file, line: line)
        XCTAssertGreaterThan(response.usage.totalTokens, 0, "Token 總使用量必須大於 0", file: file, line: line)
        
        if let firstChoice = response.choices.first {
            XCTAssertFalse(firstChoice.message.content.isEmpty, "AI 回應內容不能為空", file: file, line: line)
        }
    }
    
    /// 驗證中英混合文字格式
    static func assertMixedLanguageFormat(_ text: String, file: StaticString = #file, line: UInt = #line) {
        let hasEnglish = text.range(of: "[a-zA-Z]", options: .regularExpression) != nil
        let hasChinese = text.range(of: "[\\u4e00-\\u9fff]", options: .regularExpression) != nil
        
        XCTAssertTrue(hasEnglish || hasChinese, "文字應包含中文或英文", file: file, line: line)
    }
    
    /// 驗證電話號碼格式
    static func assertValidPhoneFormat(_ phone: String?, file: StaticString = #file, line: UInt = #line) {
        guard let phone = phone, !phone.isEmpty else { return }
        
        // 簡單的台灣電話格式驗證
        let phoneRegex = "(02|03|04|05|06|07|08|09)[0-9-]+"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        XCTAssertTrue(phonePredicate.evaluate(with: phone), "電話號碼格式不正確: \(phone)", file: file, line: line)
    }
    
    /// 驗證 Email 格式
    static func assertValidEmailFormat(_ email: String?, file: StaticString = #file, line: UInt = #line) {
        guard let email = email, !email.isEmpty else { return }
        
        XCTAssertTrue(email.contains("@"), "Email 必須包含 @ 符號", file: file, line: line)
        XCTAssertTrue(email.contains("."), "Email 必須包含域名", file: file, line: line)
    }
}