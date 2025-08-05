import Foundation
@testable import BusinessCardScannerVer3

/// Mock BusinessCardParser for testing
/// 提供名片解析器的模擬實作，支援各種測試場景
class MockBusinessCardParser: BusinessCardParserProtocol {
    
    // MARK: - Properties
    
    /// 是否應該成功
    var shouldSucceed: Bool = true
    
    /// 模擬的 OCR 解析結果
    var mockOCRParsedData: ParsedCardData?
    
    /// 錯誤場景設定
    var mockError: Error?
    
    /// 呼叫記錄
    var parseOCRTextCallCount = 0
    var lastOCRText: String?
    
    // MARK: - BusinessCardParserProtocol Implementation
    
    func parse(ocrText: String) -> ParsedCardData {
        parseOCRTextCallCount += 1
        lastOCRText = ocrText
        
        if let mockData = mockOCRParsedData {
            return mockData
        }
        
        if shouldSucceed {
            return createDefaultOCRParsedData(from: ocrText)
        } else {
            // 返回空的解析結果表示失敗
            return createEmptyParsedData(source: .local)
        }
    }
    
    func parse(ocrResult: OCRProcessingResult) -> ParsedCardData {
        parseOCRTextCallCount += 1
        lastOCRText = ocrResult.preprocessedText
        
        if let mockData = mockOCRParsedData {
            return mockData
        }
        
        if shouldSucceed {
            return createDefaultOCRParsedData(from: ocrResult.preprocessedText)
        } else {
            // 返回空的解析結果表示失敗
            return createEmptyParsedData(source: .local)
        }
    }
    
    func enhanceParsingResult(_ basicResult: ParsedCardData, with ocrResult: OCRProcessingResult) -> ParsedCardData {
        // 簡單的增強邏輯，基於基礎結果和 OCR 結果
        var enhanced = basicResult
        enhanced.confidence = min(1.0, enhanced.confidence + 0.1) // 略微提升信心度
        return enhanced
    }
    
    // MARK: - Helper Methods
    
    /// 重置 Mock 狀態
    func reset() {
        shouldSucceed = true
        mockOCRParsedData = nil
        mockError = nil
        
        parseOCRTextCallCount = 0
        lastOCRText = nil
    }
    
    /// 設定失敗場景
    func setFailureScenario() {
        shouldSucceed = false
    }
    
    /// 設定成功場景
    func setSuccessScenario() {
        shouldSucceed = true
        mockError = nil
    }
    
    /// 設定模擬 OCR 解析結果
    func setMockOCRParsedData(_ data: ParsedCardData) {
        mockOCRParsedData = data
    }
    
    
    /// 設定高品質 OCR 解析場景
    func setHighQualityOCRParsingScenario() {
        let highQualityData = ParsedCardData(
            name: "王大明 David Wang",
            namePhonetic: nil,
            jobTitle: "產品經理",
            company: "ABC科技股份有限公司",
            department: "產品部",
            email: "david.wang@abc.com.tw",
            phone: "02-1234-5678",
            mobile: "0912-345-678",
            address: "台北市信義區信義路五段7號",
            website: "www.abc.com.tw",
            confidence: 0.85,
            source: .local
        )
        setMockOCRParsedData(highQualityData)
        setSuccessScenario()
    }
    
    /// 設定中品質 OCR 解析場景
    func setMediumQualityOCRParsingScenario() {
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
            confidence: 0.72,
            source: .local
        )
        setMockOCRParsedData(mediumQualityData)
        setSuccessScenario()
    }
    
    /// 設定低品質 OCR 解析場景
    func setLowQualityOCRParsingScenario() {
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
            confidence: 0.58,
            source: .local
        )
        setMockOCRParsedData(lowQualityData)
        setSuccessScenario()
    }
    
    
    /// 設定複雜排版解析場景
    func setComplexLayoutParsingScenario() {
        let complexData = ParsedCardData(
            name: "劉建國 Jason Liu",
            namePhonetic: nil,
            jobTitle: "技術長\nChief Technology Officer",
            company: "台灣科技解決方案有限公司\nTaiwan Tech Solutions Co., Ltd.",
            department: "研發部 R&D Department",
            email: "jason.liu@techsolutions.tw",
            phone: "02-2345-6789",
            mobile: "0955-666-777",
            address: "新北市板橋區中山路一段161號12樓",
            website: "https://www.techsolutions.tw",
            confidence: 0.79,
            source: .local
        )
        setMockOCRParsedData(complexData)
        setSuccessScenario()
    }
    
    // MARK: - Private Helper Methods
    
    private func createDefaultOCRParsedData(from text: String) -> ParsedCardData {
        // 模擬基本的 OCR 文字解析邏輯
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var name: String?
        var company: String?
        var jobTitle: String?
        var phone: String?
        var mobile: String?
        var email: String?
        var website: String?
        var address: String?
        
        for line in lines {
            // 電話號碼識別
            if phone == nil && (line.contains("-") && (line.hasPrefix("02") || line.hasPrefix("03") || line.hasPrefix("04"))) {
                phone = line
            }
            // 手機號碼識別
            else if mobile == nil && line.hasPrefix("09") {
                mobile = line
            }
            // Email 識別
            else if email == nil && line.contains("@") && line.contains(".") {
                email = line
            }
            // 網站識別
            else if website == nil && (line.hasPrefix("www.") || line.hasPrefix("http")) {
                website = line
            }
            // 地址識別（包含市、區、路等關鍵字）
            else if address == nil && (line.contains("市") || line.contains("區") || line.contains("路") || line.contains("街")) {
                address = line
            }
            // 姓名識別（通常是第一行）
            else if name == nil {
                name = line
            }
            // 公司識別（通常是第二行）
            else if company == nil && name != nil {
                company = line
            }
            // 職位識別（包含職位關鍵字）
            else if jobTitle == nil && (line.contains("經理") || line.contains("總監") || line.contains("主任") || line.contains("工程師") || line.contains("Manager") || line.contains("Director")) {
                jobTitle = line
            }
        }
        
        return ParsedCardData(
            name: name ?? "Unknown",
            namePhonetic: nil,
            jobTitle: jobTitle,
            company: company,
            department: nil,
            email: email,
            phone: phone,
            mobile: mobile,
            address: address,
            website: website,
            confidence: 0.75, // OCR 預設信心度
            source: .local
        )
    }
    
    
    private func createEmptyParsedData(source: ParsedCardData.ParseSource) -> ParsedCardData {
        return ParsedCardData(
            name: nil,
            namePhonetic: nil,
            jobTitle: nil,
            company: nil,
            department: nil,
            email: nil,
            phone: nil,
            mobile: nil,
            address: nil,
            website: nil,
            confidence: 0.0,
            source: source
        )
    }
}

// MARK: - Parser Test Scenarios

extension MockBusinessCardParser {
    
    /// 建立多種語言測試場景
    func setupMultiLanguageParsingScenarios() -> [String: ParsedCardData] {
        return [
            "chinese_traditional": ParsedCardData(
                name: "王大明",
                namePhonetic: nil,
                jobTitle: "產品經理",
                company: "台灣科技股份有限公司",
                department: nil,
                email: "wang@taiwan-tech.com.tw",
                phone: "02-1234-5678",
                mobile: nil,
                address: nil,
                website: nil,
                confidence: 0.82,
                source: .local
            ),
            "english": ParsedCardData(
                name: "John Smith",
                namePhonetic: nil,
                jobTitle: "Sales Manager",
                company: "International Business Corp.",
                department: nil,
                email: "john.smith@intlbiz.com",
                phone: "+1-555-123-4567",
                mobile: nil,
                address: nil,
                website: nil,
                confidence: 0.88,
                source: .local
            ),
            "mixed_language": ParsedCardData(
                name: "李小華 Lisa Lee",
                namePhonetic: nil,
                jobTitle: "Marketing Director 行銷總監",
                company: "Global Solutions 全球解決方案",
                department: nil,
                email: "lisa.lee@globalsolutions.tw",
                phone: "02-5678-9012",
                mobile: nil,
                address: nil,
                website: nil,
                confidence: 0.76,
                source: .local
            )
        ]
    }
    
    /// 建立字段完整性測試場景
    func setupFieldCompletenessScenarios() -> [String: ParsedCardData] {
        return [
            "complete": ParsedCardData(
                name: "張志偉 Jason Chang",
                namePhonetic: nil,
                jobTitle: "技術總監",
                company: "完整資訊科技有限公司",
                department: "研發部",
                email: "jason@complete.com.tw",
                phone: "02-1111-2222",
                mobile: "0912-345-678",
                address: "台北市信義區信義路五段7號35樓",
                website: "www.complete.com.tw",
                confidence: 0.90,
                source: .local
            ),
            "partial": ParsedCardData(
                name: "陳美玲",
                namePhonetic: nil,
                jobTitle: nil,
                company: "設計工作室",
                department: nil,
                email: "chen@design.tw",
                phone: "02-3333-4444",
                mobile: nil,
                address: nil,
                website: nil,
                confidence: 0.65,
                source: .local
            ),
            "minimal": ParsedCardData(
                name: "林大華",
                namePhonetic: nil,
                jobTitle: nil,
                company: nil,
                department: nil,
                email: nil,
                phone: "0987-654-321",
                mobile: nil,
                address: nil,
                website: nil,
                confidence: 0.45,
                source: .local
            )
        ]
    }
    
    /// 建立格式驗證測試場景
    func setupFormatValidationScenarios() -> [String: ParsedCardData] {
        return [
            "valid_formats": ParsedCardData(
                name: "王正確 Correct Wang",
                namePhonetic: nil,
                jobTitle: nil,
                company: "格式正確公司",
                department: nil,
                email: "correct@valid.com.tw",
                phone: "02-1234-5678",
                mobile: "0912-345-678",
                address: nil,
                website: "https://www.valid.com.tw",
                confidence: 0.85,
                source: .local
            ),
            "invalid_formats": ParsedCardData(
                name: "測試錯誤",
                namePhonetic: nil,
                jobTitle: nil,
                company: "錯誤格式公司",
                department: nil,
                email: "invalid-email",
                phone: "invalidphone",
                mobile: "wrongmobile",
                address: nil,
                website: "not-a-website",
                confidence: 0.35,
                source: .local
            )
        ]
    }
}