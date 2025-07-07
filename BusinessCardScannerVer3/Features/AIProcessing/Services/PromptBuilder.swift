//
//  PromptBuilder.swift
//  
//
//  Created by 2025/6/25.
//

import Foundation

/// AI Prompt 建構器，負責建立結構化的名片解析提示詞
class PromptBuilder {
    
    // MARK: - Prompt Templates
    
    private static let systemPrompt = """
    你是一個專業的名片資訊解析助手。請將提供的OCR文字解析成結構化的JSON格式。
    
    要求：
    1. 輸出格式必須是有效的JSON
    2. 所有欄位都是可選的，如果無法識別則設為null
    3. 電話號碼請格式化（移除空格、連字號）
    4. 電子郵件請驗證格式正確性
    5. 地址請整理成完整格式
    
    JSON格式範例：
    {
        "name": "王小明",
        "title": "產品經理",
        "company": "科技公司股份有限公司",
        "phone": "0912345678",
        "email": "example@company.com",
        "address": "台北市信義區信義路五段7號",
        "website": "https://www.company.com",
        "fax": null,
        "mobile": null,
        "confidence": 0.85
    }
    """
    
    private static let userPromptTemplate = """
    請解析以下名片OCR文字，輸出結構化的JSON格式：
    
    OCR文字內容：
    %@
    
    語言：%@
    
    請僅回傳JSON格式的結果，不要包含其他說明文字。
    """
    
    // MARK: - Public Methods
    
    /// 建構完整的AI提示詞
    /// - Parameters:
    ///   - ocrText: OCR識別的文字內容
    ///   - language: 語言代碼（如：zh-TW, en-US）
    /// - Returns: 格式化的提示詞
    static func buildPrompt(ocrText: String, language: String = "zh-TW") -> String {
        return String(format: userPromptTemplate, ocrText, language)
    }
    
    /// 獲取系統提示詞
    /// - Returns: 系統提示詞
    static func getSystemPrompt() -> String {
        return systemPrompt
    }
    
    /// 建構多語言提示詞
    /// - Parameters:
    ///   - ocrText: OCR識別的文字內容
    ///   - language: 語言代碼
    /// - Returns: 根據語言調整的提示詞
    static func buildLocalizedPrompt(ocrText: String, language: String) -> String {
        let localizedInstructions = getLocalizedInstructions(for: language)
        let localizedExample = getLocalizedExample(for: language)
        
        let localizedTemplate = """
        \(localizedInstructions)
        
        JSON格式範例：
        \(localizedExample)
        
        請解析以下名片OCR文字，輸出結構化的JSON格式：
        
        OCR文字內容：
        %@
        
        請僅回傳JSON格式的結果，不要包含其他說明文字。
        """
        
        return String(format: localizedTemplate, ocrText)
    }
    
    // MARK: - Private Methods
    
    private static func getLocalizedInstructions(for language: String) -> String {
        switch language {
        case "en-US", "en":
            return """
            You are a professional business card information parser. Please parse the provided OCR text into structured JSON format.
            
            Requirements:
            1. Output must be valid JSON format
            2. All fields are optional, set to null if cannot be identified
            3. Format phone numbers (remove spaces, hyphens)
            4. Validate email format
            5. Organize address into complete format
            """
        case "ja-JP", "ja":
            return """
            あなたは専門的な名刺情報解析アシスタントです。提供されたOCRテキストを構造化されたJSON形式に解析してください。
            
            要求：
            1. 出力は有効なJSON形式でなければなりません
            2. すべてのフィールドはオプショナルで、識別できない場合はnullに設定
            3. 電話番号をフォーマット（スペース、ハイフンを削除）
            4. メールフォーマットを検証
            5. 住所を完全な形式に整理
            """
        default: // zh-TW, zh-CN
            return """
            你是一個專業的名片資訊解析助手。請將提供的OCR文字解析成結構化的JSON格式。
            
            要求：
            1. 輸出格式必須是有效的JSON
            2. 所有欄位都是可選的，如果無法識別則設為null
            3. 電話號碼請格式化（移除空格、連字號）
            4. 電子郵件請驗證格式正確性
            5. 地址請整理成完整格式
            """
        }
    }
    
    private static func getLocalizedExample(for language: String) -> String {
        switch language {
        case "en-US", "en":
            return """
            {
                "name": "John Smith",
                "title": "Product Manager",
                "company": "Tech Company Inc.",
                "phone": "5551234567",
                "email": "john@company.com",
                "address": "123 Main St, New York, NY 10001",
                "website": "https://www.company.com",
                "fax": null,
                "mobile": null,
                "confidence": 0.85
            }
            """
        case "ja-JP", "ja":
            return """
            {
                "name": "田中太郎",
                "title": "プロダクトマネージャー",
                "company": "テック株式会社",
                "phone": "0312345678",
                "email": "tanaka@company.com",
                "address": "東京都新宿区新宿1-1-1",
                "website": "https://www.company.com",
                "fax": null,
                "mobile": null,
                "confidence": 0.85
            }
            """
        default: // zh-TW, zh-CN
            return """
            {
                "name": "王小明",
                "title": "產品經理",
                "company": "科技公司股份有限公司",
                "phone": "0912345678",
                "email": "example@company.com",
                "address": "台北市信義區信義路五段7號",
                "website": "https://www.company.com",
                "fax": null,
                "mobile": null,
                "confidence": 0.85
            }
            """
        }
    }
}