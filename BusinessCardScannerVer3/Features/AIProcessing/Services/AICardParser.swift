//
//  AICardParser.swift

//
//  Created by mike liu on 2025/6/25.
//

import Foundation
import Combine

class AICardParser {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    var isAvailable: Bool {
        return openAIService.hasValidAPIKey()
    }
    
    // MARK: - Main Parsing Method
    
    /// 使用 AI 解析名片 OCR 文字
    /// - Parameter request: AI 處理請求資料
    /// - Returns: 解析結果的 Publisher
    func parseCard(request: AIProcessingRequest) -> AnyPublisher<ParsedCardData, Error> {
        guard isAvailable else {
            return Fail(error: AIParsingError.serviceUnavailable)
                .eraseToAnyPublisher()
        }
        
        // 建構 AI 提示詞
        let prompt = PromptBuilder.buildLocalizedPrompt(
            ocrText: request.ocrText,
            language: request.language
        )
        
        // 發送 API 請求
        return openAIService.sendRequest(prompt: prompt)
            .tryMap { [weak self] response in
                return try self?.parseAIResponse(response) ?? ParsedCardData()
            }
            .catch { error in
                // 錯誤處理：回傳包含錯誤資訊的結果
                Just(ParsedCardData(source: .manual))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// 解析 AI API 回應
    /// - Parameter response: OpenAI API 回應
    /// - Returns: 解析後的名片資料
    /// - Throws: 解析錯誤
    private func parseAIResponse(_ response: AIResponse) throws -> ParsedCardData {
        guard let firstChoice = response.choices.first else {
            throw AIParsingError.emptyResponse
        }
        
        let content = firstChoice.message.content
        
        // 嘗試解析 JSON
        guard let jsonData = content.data(using: .utf8) else {
            throw AIParsingError.invalidJSONFormat
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            guard let json = jsonObject as? [String: Any] else {
                throw AIParsingError.invalidJSONFormat
            }
            
            return try convertJSONToParsedCardData(json, tokenUsage: response.usage)
            
        } catch {
            // 如果直接解析失敗，嘗試清理 JSON 格式
            let cleanedContent = cleanJSONContent(content)
            guard let cleanedData = cleanedContent.data(using: .utf8),
                  let cleanedJSON = try? JSONSerialization.jsonObject(with: cleanedData, options: []) as? [String: Any] else {
                throw AIParsingError.jsonParsingFailed(error)
            }
            
            return try convertJSONToParsedCardData(cleanedJSON, tokenUsage: response.usage)
        }
    }
    
    /// 將 JSON 轉換為 ParsedCardData
    /// - Parameters:
    ///   - json: JSON 字典
    ///   - tokenUsage: Token 使用量資訊
    /// - Returns: 解析後的名片資料
    /// - Throws: 轉換錯誤
    private func convertJSONToParsedCardData(_ json: [String: Any], tokenUsage: TokenUsage) throws -> ParsedCardData {
        var parsedData = ParsedCardData(source: .ai)
        
        // 提取各個欄位
        parsedData.name = json["name"] as? String
        parsedData.namePhonetic = json["namePhonetic"] as? String
        parsedData.jobTitle = json["title"] as? String ?? json["jobTitle"] as? String
        parsedData.company = json["company"] as? String
        parsedData.department = json["department"] as? String
        parsedData.email = json["email"] as? String
        parsedData.phone = json["phone"] as? String
        parsedData.mobile = json["mobile"] as? String
        parsedData.address = json["address"] as? String
        parsedData.website = json["website"] as? String
        
        // 處理信心度
        if let confidence = json["confidence"] as? Double {
            parsedData.confidence = confidence
        } else if let confidence = json["confidence"] as? NSNumber {
            parsedData.confidence = confidence.doubleValue
        } else {
            // 根據 token 使用量和欄位完整性計算信心度
            parsedData.confidence = calculateConfidence(for: parsedData, tokenUsage: tokenUsage)
        }
        
        // 驗證和清理資料
        parsedData = validateAndCleanData(parsedData)
        
        return parsedData
    }
    
    /// 清理 JSON 內容格式
    /// - Parameter content: 原始內容
    /// - Returns: 清理後的 JSON 字串
    private func cleanJSONContent(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除可能的 markdown 代碼區塊
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        
        // 查找第一個 { 和最後一個 }
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 計算解析信心度
    /// - Parameters:
    ///   - data: 解析後的資料
    ///   - tokenUsage: Token 使用量
    /// - Returns: 信心度 (0.0 - 1.0)
    private func calculateConfidence(for data: ParsedCardData, tokenUsage: TokenUsage) -> Double {
        var score = 0.0
        var totalFields = 0.0
        
        // 評估各欄位的重要性和完整性
        if data.name != nil && !data.name!.isEmpty {
            score += 0.3 // 姓名最重要
        }
        totalFields += 0.3
        
        if data.company != nil && !data.company!.isEmpty {
            score += 0.2 // 公司名稱次重要
        }
        totalFields += 0.2
        
        if data.jobTitle != nil && !data.jobTitle!.isEmpty {
            score += 0.15
        }
        totalFields += 0.15
        
        if data.phone != nil && !data.phone!.isEmpty {
            score += 0.15
        }
        totalFields += 0.15
        
        if data.email != nil && !data.email!.isEmpty {
            score += 0.1
        }
        totalFields += 0.1
        
        if data.address != nil && !data.address!.isEmpty {
            score += 0.1
        }
        totalFields += 0.1
        
        let completeness = score / totalFields
        
        // 根據 token 使用量調整（適量使用表示處理得當）
        let tokenEfficiency = min(1.0, Double(tokenUsage.completionTokens) / 200.0)
        
        return min(1.0, max(0.1, completeness * 0.8 + tokenEfficiency * 0.2))
    }
    
    /// 驗證和清理解析後的資料
    /// - Parameter data: 待驗證的資料
    /// - Returns: 清理後的資料
    private func validateAndCleanData(_ data: ParsedCardData) -> ParsedCardData {
        var cleaned = data
        
        // 清理電話號碼
        if let phone = cleaned.phone {
            cleaned.phone = cleanPhoneNumber(phone)
        }
        if let mobile = cleaned.mobile {
            cleaned.mobile = cleanPhoneNumber(mobile)
        }
        
        // 驗證電子郵件格式
        if let email = cleaned.email, !isValidEmail(email) {
            cleaned.email = nil
        }
        
        // 清理網址格式
        if let website = cleaned.website {
            cleaned.website = cleanWebsiteURL(website)
        }
        
        return cleaned
    }
    
    /// 清理電話號碼格式
    /// - Parameter phone: 原始電話號碼
    /// - Returns: 清理後的電話號碼
    private func cleanPhoneNumber(_ phone: String) -> String {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "+", with: "")
        
        return cleaned
    }
    
    /// 驗證電子郵件格式
    /// - Parameter email: 電子郵件地址
    /// - Returns: 是否為有效格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// 清理網址格式
    /// - Parameter website: 原始網址
    /// - Returns: 清理後的網址
    private func cleanWebsiteURL(_ website: String) -> String {
        var cleaned = website.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleaned.hasPrefix("http://") && !cleaned.hasPrefix("https://") {
            cleaned = "https://" + cleaned
        }
        
        return cleaned
    }
}

// MARK: - Error Types

enum AIParsingError: LocalizedError {
    case serviceUnavailable
    case emptyResponse
    case invalidJSONFormat
    case jsonParsingFailed(Error)
    case dataValidationFailed
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI 解析服務不可用，請檢查 API Key 設定"
        case .emptyResponse:
            return "AI 回應為空"
        case .invalidJSONFormat:
            return "AI 回應的 JSON 格式無效"
        case .jsonParsingFailed(let error):
            return "JSON 解析失敗: \(error.localizedDescription)"
        case .dataValidationFailed:
            return "資料驗證失敗"
        }
    }
}
