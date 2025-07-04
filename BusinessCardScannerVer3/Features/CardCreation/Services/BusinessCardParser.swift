//
//  BusinessCardParser.swift
//  Business card parsing logic integrating OCR results
//
//  Created by mike liu on 2025/6/25.
//

import UIKit
import Foundation

protocol BusinessCardParserProtocol {
    func parse(ocrText: String) -> ParsedCardData
    func parse(ocrResult: OCRProcessingResult) -> ParsedCardData
    func enhanceParsingResult(_ basicResult: ParsedCardData, with ocrResult: OCRProcessingResult) -> ParsedCardData
}

class BusinessCardParser: BusinessCardParserProtocol {
    
    // MARK: - Properties
    private let confidenceThreshold: Double = 0.6
    
    // MARK: - Public Methods
    
    /// Parse business card from plain OCR text
    /// - Parameter ocrText: Recognized text from OCR
    /// - Returns: Parsed card data
    func parse(ocrText: String) -> ParsedCardData {
        print("📝 BusinessCardParser: 解析純文字 OCR 結果")
        
        var result = ParsedCardData()
        result.source = .local
        
        // Basic text-based extraction
        result.name = extractName(from: ocrText)
        result.email = extractEmail(from: ocrText)
        
        // 分別提取電話和手機（參考 Ver2）
        result.phone = extractLandlinePhone(from: ocrText)
        result.mobile = extractMobilePhone(from: ocrText)
        
        result.company = extractCompany(from: ocrText)
        result.jobTitle = extractJobTitle(from: ocrText)
        result.address = extractAddress(from: ocrText)
        result.website = extractWebsite(from: ocrText)
        
        // Calculate basic confidence
        result.confidence = calculateConfidence(for: result)
        
        print("✅ 基礎解析完成，信心度: \(String(format: "%.2f", result.confidence))")
        return result
    }
    
    /// Parse business card from OCR processing result (enhanced)
    /// - Parameter ocrResult: Complete OCR processing result
    /// - Returns: Enhanced parsed card data
    func parse(ocrResult: OCRProcessingResult) -> ParsedCardData {
        print("🔍 BusinessCardParser: 解析增強 OCR 結果")
        
        var result = ParsedCardData()
        result.source = .local
        
        // Use pre-extracted fields from OCRProcessor
        result.name = selectBestValue(candidates: [
            ocrResult.extractedFields["name"],
            extractName(from: ocrResult.preprocessedText)
        ])
        
        result.email = selectBestValue(candidates: [
            ocrResult.extractedFields["email"],
            extractEmail(from: ocrResult.preprocessedText)
        ])
        
        // 分別處理電話和手機欄位
        result.phone = selectBestValue(candidates: [
            ocrResult.extractedFields["phone"],
            extractLandlinePhone(from: ocrResult.preprocessedText)
        ])
        
        result.mobile = selectBestValue(candidates: [
            ocrResult.extractedFields["mobile"],
            extractMobilePhone(from: ocrResult.preprocessedText)
        ])
        
        result.company = selectBestValue(candidates: [
            ocrResult.extractedFields["company"],
            extractCompany(from: ocrResult.preprocessedText)
        ])
        
        result.jobTitle = selectBestValue(candidates: [
            ocrResult.extractedFields["title"],  // 修正：OCRProcessor 使用 "title" 而非 "jobTitle"
            extractJobTitle(from: ocrResult.preprocessedText)
        ])
        
        result.address = selectBestValue(candidates: [
            ocrResult.extractedFields["address"],
            extractAddress(from: ocrResult.preprocessedText)
        ])
        
        result.website = selectBestValue(candidates: [
            ocrResult.extractedFields["website"],
            extractWebsite(from: ocrResult.preprocessedText)
        ])
        
        // Enhanced confidence calculation using OCR confidence
        result.confidence = calculateEnhancedConfidence(for: result, ocrResult: ocrResult)
        
        print("✅ 增強解析完成，信心度: \(String(format: "%.2f", result.confidence))")
        return result
    }
    
    /// Enhance parsing result with additional context
    /// - Parameters:
    ///   - basicResult: Basic parsed result
    ///   - ocrResult: OCR processing result for context
    /// - Returns: Enhanced parsed card data
    func enhanceParsingResult(_ basicResult: ParsedCardData, with ocrResult: OCRProcessingResult) -> ParsedCardData {
        print("⚡ BusinessCardParser: 增強解析結果")
        
        var enhanced = basicResult
        
        // Fill missing fields using spatial analysis
        if enhanced.name == nil {
            enhanced.name = extractNameWithSpatialAnalysis(from: ocrResult)
        }
        
        if enhanced.company == nil {
            enhanced.company = extractCompanyWithSpatialAnalysis(from: ocrResult)
        }
        
        if enhanced.jobTitle == nil {
            enhanced.jobTitle = extractJobTitleWithSpatialAnalysis(from: ocrResult)
        }
        
        // Validate and clean extracted data
        enhanced = validateAndCleanData(enhanced)
        
        // Update confidence
        enhanced.confidence = calculateEnhancedConfidence(for: enhanced, ocrResult: ocrResult)
        
        return enhanced
    }
}

// MARK: - Private Extraction Methods
private extension BusinessCardParser {
    
    func extractName(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        print("🔍 BusinessCardParser: 分析 \(lines.count) 行文字尋找人名")
        
        // Chinese name pattern (2-4 characters)
        let chineseNamePattern = "^[\\u{4e00}-\\u{9fff}]{2,4}$"
        
        // English name pattern - 改進以精確匹配 "First Last" 格式
        let englishNamePattern = "^[A-Za-z]+\\s+[A-Za-z]+$"
        
        // 增強的排除關鍵字列表
        let excludeKeywords = [
            "公司", "企業", "集團", "有限", "股份", "科技", "實業", "貿易",
            "Ltd", "Inc", "Corp", "Company", "Enterprise", "Group", "Technology", "Tech",
            "@", "www", ".com", ".tw", ".cn", "http", "phone", "tel", "fax",
            "manager", "director", "engineer", "designer"
        ]
        
        // 優先檢查前5行（通常名字在較前面的位置）
        for line in lines.prefix(5) {
            print("📝 檢查行: '\(line)'")
            
            // 檢查是否包含排除關鍵字
            let containsExcludeKeyword = excludeKeywords.contains { keyword in
                line.localizedCaseInsensitiveContains(keyword)
            }
            
            if containsExcludeKeyword {
                print("⛔ 跳過包含排除關鍵字的行: '\(line)'")
                continue
            }
            
            // 首先檢查英文人名模式（針對 "Kevin Su" 問題）
            if matches(line, pattern: englishNamePattern) {
                print("✅ 找到英文人名: '\(line)'")
                return line
            }
            
            // 再檢查中文人名模式
            if matches(line, pattern: chineseNamePattern) {
                print("✅ 找到中文人名: '\(line)'")
                return line
            }
        }
        
        // 如果沒有找到符合嚴格模式的，使用寬鬆模式
        for line in lines.prefix(5) {
            let length = line.count
            
            // 排除明顯不是名字的行
            if length >= 2 && length <= 15 {
                let containsExcludeKeyword = excludeKeywords.contains { keyword in
                    line.localizedCaseInsensitiveContains(keyword)
                }
                
                // 排除包含數字的行（通常是電話或地址）
                let containsNumbers = line.rangeOfCharacter(from: .decimalDigits) != nil
                
                if !containsExcludeKeyword && !containsNumbers {
                    print("🤔 寬鬆模式找到可能的人名: '\(line)'")
                    return line
                }
            }
        }
        
        print("⚠️ BusinessCardParser: 未找到合適的人名")
        return nil
    }
    
    func extractEmail(from text: String) -> String? {
        let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return extractFirst(from: text, pattern: emailPattern)
    }
    
    func extractLandlinePhone(from text: String) -> String? {
        print("📞 BusinessCardParser: 開始提取市內電話")
        print("📄 輸入文字內容: \"\(text)\"")
        
        // 市內電話模式（排除手機號碼）
        let patterns = [
            // 國際格式市話（含分機）：+88636590999105８ (OCR可能將分機直接連接)
            "\\+?886[2-8]\\d{7,12}",
            // 國際格式市話：+886.3.6590999#1058 (支援點號分隔符和分機號碼)
            "\\+?886[.\\-\\s]?[2-8][.\\-\\s]?\\d{3,4}[.\\-\\s]?\\d{4}(?:#\\d+)?",
            // 市話：(02)1234-5678 或 02-1234-5678 (排除09開頭)
            "\\(?0[2-8]\\)?[-\\s]?\\d{3,4}[-\\s]?\\d{4}",
            // 國際格式市話：+886-2-1234-5678 (排除手機)
            "\\+?886[-\\s]?[2-8][-\\s]?\\d{3,4}[-\\s]?\\d{4}",
            // 簡化模式：0x-xxxxxxx 或 0x-xxxx-xxxx
            "0[2-8][-\\s]?\\d{7,8}",
            // 更寬鬆的模式：純數字格式（含可能的分機）
            "0[2-8]\\d{7,12}"
        ]
        
        for (index, pattern) in patterns.enumerated() {
            print("🔍 嘗試模式 \(index + 1): \(pattern)")
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                print("📊 找到 \(matches.count) 個匹配")
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let phone = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        print("🎯 匹配到: '\(phone)'")
                        // 清理電話號碼（移除分機號碼）
                        let cleanPhone = separateExtensionFromPhone(phone)
                        // 確認不是手機號碼
                        if !cleanPhone.contains("09") && !cleanPhone.contains(".9") {
                            print("✅ 找到市內電話: \(cleanPhone)")
                            return formatPhone(cleanPhone)
                        }
                    }
                }
            } else {
                print("❌ 正則表達式無效: \(pattern)")
            }
        }
        
        // 檢查是否包含市內電話關鍵字（參考 Ver2）
        let phoneKeywords = ["電話", "Tel", "Phone", "TEL"]
        for keyword in phoneKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                // 提取關鍵字後的數字
                let keywordPattern = "\(keyword)[：:﹕︰\\s]*([0-9\\-\\(\\)\\+\\s]{8,15})"
                if let regex = try? NSRegularExpression(pattern: keywordPattern, options: .caseInsensitive) {
                    let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                    if let match = matches.first, match.numberOfRanges > 1 {
                        if let range = Range(match.range(at: 1), in: text) {
                            let phone = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                            // 確認不是手機號碼
                            if !phone.contains("09") {
                                print("✅ 透過關鍵字找到市內電話: \(phone)")
                                return formatPhone(phone)
                            }
                        }
                    }
                }
            }
        }
        
        // 最後的通用數字檢測（作為後備）
        print("🔍 嘗試通用數字檢測...")
        let generalNumberPatterns = [
            // 支援前綴字符的國際格式：0 +886.934329856
            "[A-Z0-9]?\\s*\\+?886[.\\-\\s]?[2-8][.\\-\\s]?\\d{7,9}(?:#\\d+)?",
            // 標準格式
            "\\d{8,11}",  // 8-11位數字
            "\\d{2,3}[-\\s]\\d{4}[-\\s]\\d{4}",  // 有分隔符的格式
            "\\d{2,3}\\d{7,8}"  // 連續數字格式
        ]
        
        for pattern in generalNumberPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let number = String(text[range])
                        print("🎯 找到數字: '\(number)'")
                        
                        // 清理前綴字符
                        let cleanNumber = number.replacingOccurrences(of: "^[A-Z0-9]\\s*", with: "", options: .regularExpression)
                        
                        // 分離可能的分機號碼
                        let phoneWithoutExtension = separateExtensionFromPhone(cleanNumber)
                        
                        // 檢查是否為市內電話格式（0開頭但不是09，或+886開頭但不是手機）
                        if (phoneWithoutExtension.hasPrefix("0") && !phoneWithoutExtension.hasPrefix("09") && phoneWithoutExtension.count >= 8) ||
                           (phoneWithoutExtension.hasPrefix("+886") && !phoneWithoutExtension.contains(".9") && !phoneWithoutExtension.contains("-9")) {
                            print("✅ 後備方案找到市內電話: \(phoneWithoutExtension)")
                            return formatPhone(phoneWithoutExtension)
                        }
                    }
                }
            }
        }
        
        print("❌ 未找到市內電話")
        return nil
    }
    
    func extractMobilePhone(from text: String) -> String? {
        print("📱 BusinessCardParser: 開始提取手機號碼")
        print("📄 輸入文字內容: \"\(text)\"")
        
        // 手機號碼模式（只包含手機）
        let patterns = [
            // 國際格式手機：+886.934329856 (支援點號分隔符)
            "\\+?886[.\\-\\s]?9\\d{8}",
            // 國際格式手機：+886-9xx-xxx-xxx
            "\\+?886[-\\s]?9\\d{2}[-\\s]?\\d{3}[-\\s]?\\d{3}",
            // 手機：09xx-xxx-xxx 或 09xxxxxxxx
            "09\\d{2}[-\\s]?\\d{3}[-\\s]?\\d{3}",
            // 簡化模式：09xxxxxxxx
            "09\\d{8}",
            // 更寬鬆的模式：包含空格或其他分隔符
            "0\\s*9\\s*\\d{2}\\s*\\d{3}\\s*\\d{3}"
        ]
        
        for (index, pattern) in patterns.enumerated() {
            print("🔍 嘗試模式 \(index + 1): \(pattern)")
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                print("📊 找到 \(matches.count) 個匹配")
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let phone = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        print("🎯 匹配到: '\(phone)'")
                        // 清理手機號碼
                        let cleanPhone = phone.components(separatedBy: "#").first ?? phone
                        print("✅ 找到手機號碼: \(cleanPhone)")
                        return formatPhone(cleanPhone)
                    }
                }
            } else {
                print("❌ 正則表達式無效: \(pattern)")
            }
        }
        
        // 檢查是否包含手機關鍵字（參考 Ver2）
        let mobileKeywords = ["手機", "Mobile", "Cell", "MOBILE"]
        for keyword in mobileKeywords {
            if text.localizedCaseInsensitiveContains(keyword) {
                // 提取關鍵字後的數字
                let keywordPattern = "\(keyword)[：:﹕︰\\s]*([0-9\\-\\(\\)\\+\\s]{8,15})"
                if let regex = try? NSRegularExpression(pattern: keywordPattern, options: .caseInsensitive) {
                    let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                    if let match = matches.first, match.numberOfRanges > 1 {
                        if let range = Range(match.range(at: 1), in: text) {
                            let phone = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                            // 確認是手機號碼
                            if phone.contains("09") {
                                print("✅ 透過關鍵字找到手機號碼: \(phone)")
                                return formatPhone(phone)
                            }
                        }
                    }
                }
            }
        }
        
        // 最後的通用數字檢測（作為後備）
        print("🔍 嘗試通用數字檢測...")
        let generalNumberPatterns = [
            // 支援前綴字符的國際格式：0 +886.934329856
            "[A-Z0-9]?\\s*\\+?886[.\\-\\s]?9\\d{8}",
            // 標準格式
            "\\d{10}",  // 10位數字
            "09\\d{8}"  // 09開頭的8位數字
        ]
        
        for pattern in generalNumberPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let number = String(text[range])
                        print("🎯 找到數字: '\(number)'")
                        
                        // 清理前綴字符
                        let cleanNumber = number.replacingOccurrences(of: "^[A-Z0-9]\\s*", with: "", options: .regularExpression)
                        
                        // 檢查是否為手機號碼格式（09開頭或+886.9開頭）
                        if cleanNumber.hasPrefix("09") || 
                           (cleanNumber.hasPrefix("+886") && (cleanNumber.contains(".9") || cleanNumber.contains("-9"))) {
                            print("✅ 後備方案找到手機號碼: \(cleanNumber)")
                            return formatPhone(cleanNumber)
                        }
                    }
                }
            }
        }
        
        print("❌ 未找到手機號碼")
        return nil
    }
    
    func extractCompany(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Company keywords
        let chineseKeywords = ["公司", "企業", "集團", "有限", "股份", "科技", "實業", "貿易"]
        let englishKeywords = ["Ltd", "Inc", "Corp", "Company", "Enterprise", "Group", "Technology", "Tech"]
        
        for line in lines {
            // Check for Chinese company keywords
            for keyword in chineseKeywords {
                if line.contains(keyword) {
                    return line
                }
            }
            
            // Check for English company keywords
            for keyword in englishKeywords {
                if line.localizedCaseInsensitiveContains(keyword) {
                    return line
                }
            }
        }
        
        return nil
    }
    
    func extractJobTitle(from text: String) -> String? {
        let jobTitleKeywords = [
            // Executive levels
            "總經理", "執行長", "董事長", "總裁", "副總", "協理", "經理", "副理",
            "CEO", "CTO", "CFO", "COO", "President", "Director", "Manager", "VP",
            
            // Professional titles
            "工程師", "設計師", "分析師", "顧問", "專員", "主任", "組長", "課長",
            "Engineer", "Designer", "Analyst", "Consultant", "Specialist", "Lead",
            
            // Sales and Marketing
            "業務", "行銷", "銷售", "客服", "採購",
            "Sales", "Marketing", "Account", "Business", "Service"
        ]
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            for keyword in jobTitleKeywords {
                if line.contains(keyword) {
                    return line
                }
            }
        }
        
        return nil
    }
    
    func extractAddress(from text: String) -> String? {
        // 地址關鍵字（參考 Ver2）
        let addressKeywords = ["地址", "Address", "Addr", "Add"]
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 檢查是否包含地址關鍵字
        for keyword in addressKeywords {
            for line in lines {
                if line.contains(keyword) {
                    // 提取關鍵字後的內容
                    if let regex = try? NSRegularExpression(pattern: "\(keyword)[：:﹕︰]?\\s*(.+)", options: .caseInsensitive) {
                        let matches = regex.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line))
                        if let match = matches.first, match.numberOfRanges > 1 {
                            if let range = Range(match.range(at: 1), in: line) {
                                let addressText = String(line[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                                return cleanAddress(addressText)
                            }
                        }
                    }
                }
            }
        }
        
        // 台灣地址模式檢查（簡化版，檢查是否包含地址特徵）
        let addressIndicators = ["市", "區", "縣", "路", "街", "巷", "弄", "號"]
        
        for line in lines {
            // 檢查是否包含足夠的地址特徵
            var indicatorCount = 0
            for indicator in addressIndicators {
                if line.contains(indicator) {
                    indicatorCount += 1
                }
            }
            
            // 如果包含至少3個地址特徵且包含「號」，視為地址
            if indicatorCount >= 3 && line.contains("號") && line.count > 8 {
                return cleanAddress(line)
            }
        }
        
        return nil
    }
    
    /// 清理地址中的郵遞區號和序號
    /// - Parameter address: 原始地址
    /// - Returns: 清理後的地址
    private func cleanAddress(_ address: String) -> String {
        guard !address.isEmpty else { return address }
        
        var cleanedAddress = address
        
        // 1. 移除開頭的序號（如：1臺北市、2.新北市、3)高雄市等）
        cleanedAddress = cleanedAddress.replacingOccurrences(
            of: "^\\d+[.\\)）、\\s]*",
            with: "",
            options: .regularExpression
        )
        
        // 2. 移除開頭的郵遞區號（台灣郵遞區號為3-5位數字）
        cleanedAddress = cleanedAddress.replacingOccurrences(
            of: "^\\d{3,5}\\s*",
            with: "",
            options: .regularExpression
        )
        
        // 3. 移除可能的多餘空格和標點符號
        cleanedAddress = cleanedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedAddress
    }
    
    func extractWebsite(from text: String) -> String? {
        let websitePatterns = [
            "https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=]+",
            "www\\.[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=]+",
            "[\\w\\-]+\\.(com|org|net|edu|gov|mil|int|co|tw|cn|jp|kr)"
        ]
        
        for pattern in websitePatterns {
            if let website = extractFirst(from: text, pattern: pattern) {
                return cleanWebsite(website)
            }
        }
        
        return nil
    }
}

// MARK: - Spatial Analysis Methods
private extension BusinessCardParser {
    
    func extractNameWithSpatialAnalysis(from ocrResult: OCRProcessingResult) -> String? {
        // 調整與 OCRProcessor 一致的區域範圍
        let nameRegion = CGRect(x: 0, y: 0.5, width: 1.0, height: 0.5)
        let texts = extractTextsInRegion(ocrResult.ocrResult.boundingBoxes, region: nameRegion)
        
        print("🔍 BusinessCardParser: 空間分析找到 \(texts.count) 個候選文字")
        
        // 英文人名優先模式，與 OCRProcessor 邏輯一致
        let englishNamePattern = "^[A-Za-z]+\\s+[A-Za-z]+$"
        let chineseNamePattern = "^[\\u{4e00}-\\u{9fff}]{2,4}$"
        
        let excludeKeywords = [
            "公司", "企業", "集團", "有限", "股份", "科技", "實業", "貿易",
            "Ltd", "Inc", "Corp", "Company", "Enterprise", "Group", "Technology", "Tech",
            "@", "www", ".com"
        ]
        
        // 首先尋找英文人名
        for text in texts {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if matches(trimmedText, pattern: englishNamePattern) {
                let containsExcludeKeyword = excludeKeywords.contains { keyword in
                    trimmedText.localizedCaseInsensitiveContains(keyword)
                }
                
                if !containsExcludeKeyword {
                    print("✅ 空間分析找到英文人名: \(trimmedText)")
                    return trimmedText
                }
            }
        }
        
        // 再尋找中文人名
        for text in texts {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if matches(trimmedText, pattern: chineseNamePattern) {
                print("✅ 空間分析找到中文人名: \(trimmedText)")
                return trimmedText
            }
        }
        
        // 最後使用寬鬆模式
        for text in texts {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let length = trimmedText.count
            
            if length >= 2 && length <= 15 {
                let containsExcludeKeyword = excludeKeywords.contains { keyword in
                    trimmedText.localizedCaseInsensitiveContains(keyword)
                }
                
                let containsNumbers = trimmedText.rangeOfCharacter(from: .decimalDigits) != nil
                
                if !containsExcludeKeyword && !containsNumbers {
                    print("🤔 空間分析寬鬆模式找到人名: \(trimmedText)")
                    return trimmedText
                }
            }
        }
        
        print("⚠️ BusinessCardParser: 空間分析未找到合適的人名")
        return nil
    }
    
    func extractCompanyWithSpatialAnalysis(from ocrResult: OCRProcessingResult) -> String? {
        // Company names are typically in the upper region
        let companyRegion = CGRect(x: 0, y: 0.5, width: 1.0, height: 0.5)
        let texts = extractTextsInRegion(ocrResult.ocrResult.boundingBoxes, region: companyRegion)
        
        for text in texts {
            if let company = extractCompany(from: text) {
                return company
            }
        }
        
        return nil
    }
    
    func extractJobTitleWithSpatialAnalysis(from ocrResult: OCRProcessingResult) -> String? {
        // Job titles are often near the name or in the middle area
        let titleRegion = CGRect(x: 0, y: 0.3, width: 1.0, height: 0.4)
        let texts = extractTextsInRegion(ocrResult.ocrResult.boundingBoxes, region: titleRegion)
        
        for text in texts {
            if let title = extractJobTitle(from: text) {
                return title
            }
        }
        
        return nil
    }
    
    func extractTextsInRegion(_ boundingBoxes: [TextBoundingBox], region: CGRect) -> [String] {
        return boundingBoxes
            .filter { region.intersects($0.boundingBox) }
            .map { $0.text }
    }
}

// MARK: - Helper Methods
private extension BusinessCardParser {
    
    func selectBestValue(candidates: [String?]) -> String? {
        // Select the longest non-empty candidate
        return candidates
            .compactMap { $0 }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .max(by: { $0.count < $1.count })
    }
    
    func matches(_ text: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: text.utf16.count)
            return regex.firstMatch(in: text, range: range) != nil
        } catch {
            return false
        }
    }
    
    func extractFirst(from text: String, pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, range: range),
               let stringRange = Range(match.range, in: text) {
                return String(text[stringRange])
            }
        } catch {
            print("❌ Regex error: \(error)")
        }
        return nil
    }
    
    func cleanPhoneNumber(_ phone: String) -> String {
        // Remove extra spaces and normalize format
        return phone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "--", with: "-")
    }
    
    func separateExtensionFromPhone(_ phone: String) -> String {
        print("🔧 分離分機號碼，原始號碼: '\(phone)'")
        
        // 先處理有#符號的情況
        if phone.contains("#") {
            let components = phone.components(separatedBy: "#")
            let mainPhone = components.first ?? phone
            let extNumber = components.count > 1 ? components[1] : ""
            print("📞 發現#分機號碼 - 主號碼: '\(mainPhone)', 分機: '\(extNumber)'")
            // 重新組合，保留分機號碼
            return extNumber.isEmpty ? mainPhone : "\(mainPhone)#\(extNumber)"
        }
        
        // 處理國際格式市內電話的分機號碼（無#符號）
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        if cleaned.hasPrefix("+886") {
            // 國際格式：+886 + 區碼(1位) + 號碼(7-8位) + 可能的分機(3-4位)
            let withoutCountryCode = String(cleaned.dropFirst(4)) // 移除+886
            print("📊 無國碼部分: '\(withoutCountryCode)', 長度: \(withoutCountryCode.count)")
            
            // 台灣市內電話：區碼1位 + 號碼7-8位 = 8-9位總長度
            // 對於+88636590999105８，應該是3+6590999+1058
            if withoutCountryCode.count > 9 {
                // 根據實際情況，台灣市內電話通常是：區碼(1-2位) + 號碼(7-8位)
                // 03-6590999 應該是正確的格式
                if withoutCountryCode.hasPrefix("3") {
                    // 區碼3 + 7位號碼 = 8位，所以取前8位
                    let phoneDigits = String(withoutCountryCode.prefix(8))
                    let extNumber = String(withoutCountryCode.dropFirst(8))
                    let mainPhone = "+886" + phoneDigits
                    print("📞 國際格式分機分離(修正) - 主號碼: '\(mainPhone)', 分機: '\(extNumber)'")
                    // 重新組合，保留分機號碼
                    return extNumber.isEmpty ? mainPhone : "\(mainPhone)#\(extNumber)"
                } else {
                    // 其他區碼，假設前9位是正確的電話號碼
                    let phoneDigits = String(withoutCountryCode.prefix(9))
                    let extNumber = String(withoutCountryCode.dropFirst(9))
                    let mainPhone = "+886" + phoneDigits
                    print("📞 國際格式分機分離 - 主號碼: '\(mainPhone)', 分機: '\(extNumber)'")
                    // 重新組合，保留分機號碼
                    return extNumber.isEmpty ? mainPhone : "\(mainPhone)#\(extNumber)"
                }
            }
        } else if cleaned.hasPrefix("0") && !cleaned.hasPrefix("09") {
            // 國內格式：0 + 區碼(1位) + 號碼(7-8位) + 可能的分機(3-4位)
            // 正常長度應該是9-10位，如果超過可能有分機
            if cleaned.count > 10 {
                let phoneDigits = String(cleaned.prefix(10))
                let extNumber = String(cleaned.dropFirst(10))
                print("📞 國內格式分機分離 - 主號碼: '\(phoneDigits)', 分機: '\(extNumber)'")
                // 重新組合，保留分機號碼
                return extNumber.isEmpty ? phoneDigits : "\(phoneDigits)#\(extNumber)"
            }
        }
        
        print("📞 無需分離分機，返回原號碼: '\(phone)'")
        return phone
    }
    
    func formatPhone(_ phone: String) -> String {
        print("🔧 格式化電話號碼: '\(phone)'")
        
        // 先檢查是否包含分機號碼
        if phone.contains("#") {
            let components = phone.components(separatedBy: "#")
            let mainPhone = components.first ?? phone
            let extNumber = components.count > 1 ? components[1] : ""
            
            // 格式化主號碼
            let formattedMain = formatPhoneNumber(mainPhone)
            
            // 重新組合
            let result = extNumber.isEmpty ? formattedMain : "\(formattedMain) #\(extNumber)"
            print("📞 格式化包含分機的號碼: '\(result)'")
            return result
        }
        
        // 沒有分機號碼，直接格式化
        return formatPhoneNumber(phone)
    }
    
    private func formatPhoneNumber(_ phone: String) -> String {
        // 移除所有非數字字符（保留+號）（參考 Ver2）
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // 根據長度判斷格式
        if cleaned.hasPrefix("+886") {
            let withoutCountryCode = String(cleaned.dropFirst(4)) // 移除+886
            print("🔧 格式化國際號碼: '\(cleaned)', 無國碼部分: '\(withoutCountryCode)'")
            
            // 判斷是手機還是市內電話
            if withoutCountryCode.hasPrefix("9") {
                // 手機：+886-9xx-xxx-xxx
                if withoutCountryCode.count == 9 {
                    let index1 = withoutCountryCode.index(withoutCountryCode.startIndex, offsetBy: 3)
                    let index2 = withoutCountryCode.index(withoutCountryCode.startIndex, offsetBy: 6)
                    return "+886-" + String(withoutCountryCode[..<index1]) + "-" + String(withoutCountryCode[index1..<index2]) + "-" + String(withoutCountryCode[index2...])
                }
            } else {
                // 市內電話：+886-x-xxxx-xxxx
                if withoutCountryCode.count == 8 && withoutCountryCode.hasPrefix("3") {
                    // 03-xxxx-xxx格式：3+7位數字
                    let areaCode = String(withoutCountryCode.prefix(1)) // 區碼3
                    let number = String(withoutCountryCode.dropFirst(1)) // 剩餘7位
                    if number.count == 7 {
                        let index = number.index(number.startIndex, offsetBy: 4)
                        return "+886-" + areaCode + "-" + String(number[..<index]) + "-" + String(number[index...])
                    }
                } else if withoutCountryCode.count >= 8 {
                    // 其他格式
                    let areaCode = String(withoutCountryCode.prefix(1))
                    let number = String(withoutCountryCode.dropFirst(1))
                    if number.count >= 7 {
                        let phoneNumber = String(number.prefix(7))
                        let index = phoneNumber.index(phoneNumber.startIndex, offsetBy: 4)
                        return "+886-" + areaCode + "-" + String(phoneNumber[..<index]) + "-" + String(phoneNumber[index...])
                    }
                }
            }
            return cleaned
        } else if cleaned.hasPrefix("09") && cleaned.count == 10 {
            // 手機格式：09xx-xxx-xxx
            let index1 = cleaned.index(cleaned.startIndex, offsetBy: 4)
            let index2 = cleaned.index(cleaned.startIndex, offsetBy: 7)
            return String(cleaned[..<index1]) + "-" + String(cleaned[index1..<index2]) + "-" + String(cleaned[index2...])
        } else if cleaned.hasPrefix("0") && cleaned.count >= 9 && cleaned.count <= 11 {
            // 市內電話格式：0x-xxxx-xxxx
            if cleaned.count == 10 {
                // 如 02-1234-5678
                let index1 = cleaned.index(cleaned.startIndex, offsetBy: 2)
                let index2 = cleaned.index(cleaned.startIndex, offsetBy: 6)
                return String(cleaned[..<index1]) + "-" + String(cleaned[index1..<index2]) + "-" + String(cleaned[index2...])
            } else if cleaned.count == 11 {
                // 如 037-123-4567
                let index1 = cleaned.index(cleaned.startIndex, offsetBy: 3)
                let index2 = cleaned.index(cleaned.startIndex, offsetBy: 6)
                return String(cleaned[..<index1]) + "-" + String(cleaned[index1..<index2]) + "-" + String(cleaned[index2...])
            }
        }
        
        return cleaned
    }
    
    func cleanWebsite(_ website: String) -> String {
        var cleaned = website.lowercased()
        if !cleaned.hasPrefix("http") && !cleaned.hasPrefix("www") {
            cleaned = "https://" + cleaned
        }
        return cleaned
    }
    
    func validateAndCleanData(_ data: ParsedCardData) -> ParsedCardData {
        var cleaned = data
        
        // Clean and validate name
        if let name = cleaned.name {
            cleaned.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.name?.isEmpty == true {
                cleaned.name = nil
            }
        }
        
        // Validate email format
        if let email = cleaned.email {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            if !matches(email, pattern: emailRegex) {
                cleaned.email = nil
            }
        }
        
        // Validate phone format (市內電話，支援分機號碼)
        if let phone = cleaned.phone {
            let phoneRegex = "[\\d\\s\\-\\+\\(\\)#]{8,25}"  // 支援#符號和分機，放寬長度
            if !matches(phone, pattern: phoneRegex) {
                cleaned.phone = nil
            }
        }
        
        // Validate mobile format (手機)
        if let mobile = cleaned.mobile {
            let mobileRegex = "[\\d\\s\\-\\+\\(\\)]{8,20}"  // 放寬長度限制，支援國際格式
            if !matches(mobile, pattern: mobileRegex) {
                cleaned.mobile = nil
            }
        }
        
        return cleaned
    }
    
    func calculateConfidence(for data: ParsedCardData) -> Double {
        var score = 0.0
        var maxScore = 0.0
        
        // Weight different fields (包含分離的電話和手機)
        let fieldWeights: [(value: String?, weight: Double)] = [
            (data.name, 0.25),
            (data.company, 0.20),
            (data.email, 0.15),
            (data.phone, 0.10),      // 市內電話
            (data.mobile, 0.10),     // 手機
            (data.jobTitle, 0.08),
            (data.address, 0.07),
            (data.website, 0.05)
        ]
        
        for (value, weight) in fieldWeights {
            maxScore += weight
            if value != nil && !value!.isEmpty {
                score += weight
            }
        }
        
        return maxScore > 0 ? score / maxScore : 0.0
    }
    
    func calculateEnhancedConfidence(for data: ParsedCardData, ocrResult: OCRProcessingResult) -> Double {
        let basicConfidence = calculateConfidence(for: data)
        let ocrConfidence = ocrResult.ocrResult.confidence
        
        // Combine confidences with weights
        return (basicConfidence * 0.7) + (Double(ocrConfidence) * 0.3)
    }
}
