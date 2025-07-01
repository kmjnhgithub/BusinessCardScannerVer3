//
//  OCRProcessor.swift
//  BusinessCardScannerVer3
//
//  OCR 處理器，負責圖片的文字識別和預處理
//

import UIKit
import Vision
import Combine

/// OCR 處理結果
struct OCRProcessingResult {
    let originalImage: UIImage
    let ocrResult: OCRResult
    let preprocessedText: String
    let extractedFields: [String: String]
}

/// OCR 處理器
class OCRProcessor {
    
    // MARK: - Properties
    
    private let visionService: VisionService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(visionService: VisionService? = nil) {
        self.visionService = visionService ?? ServiceContainer.shared.visionService
    }
    
    // MARK: - Public Methods
    
    /// 處理圖片並執行 OCR
    /// - Parameters:
    ///   - image: 要處理的圖片
    ///   - completion: 完成回調
    func processImage(_ image: UIImage, completion: @escaping (Result<OCRProcessingResult, OCRError>) -> Void) {
        print("🔄 OCRProcessor: 開始處理圖片")
        
        // 1. 預處理圖片
        let preprocessedImage = preprocessImage(image)
        
        // 2. 執行 OCR
        visionService.recognizeText(from: preprocessedImage) { [weak self] result in
            switch result {
            case .success(let ocrResult):
                // 3. 後處理文字
                let preprocessedText = self?.preprocessText(ocrResult.recognizedText) ?? ocrResult.recognizedText
                
                // 4. 提取欄位
                let extractedFields = self?.extractBusinessCardFields(from: ocrResult) ?? [:]
                
                // 5. 建立最終結果
                let processingResult = OCRProcessingResult(
                    originalImage: image,
                    ocrResult: ocrResult,
                    preprocessedText: preprocessedText,
                    extractedFields: extractedFields
                )
                
                print("✅ OCRProcessor: 處理完成")
                completion(.success(processingResult))
                
            case .failure(let error):
                print("❌ OCRProcessor: 處理失敗 - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    /// 處理圖片並執行 OCR (Combine 版本)
    /// - Parameter image: 要處理的圖片
    /// - Returns: 處理結果的 Publisher
    func processImage(_ image: UIImage) -> AnyPublisher<OCRProcessingResult, OCRError> {
        return Future { [weak self] promise in
            self?.processImage(image) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Image Preprocessing
    
    /// 預處理圖片以提高 OCR 準確度
    /// - Parameter image: 原始圖片
    /// - Returns: 預處理後的圖片
    private func preprocessImage(_ image: UIImage) -> UIImage {
        print("🖼️ OCRProcessor: 預處理圖片")
        
        // 調整圖片大小（過大的圖片會影響處理速度）
        let resizedImage = resizeImageIfNeeded(image)
        
        // 增強對比度和亮度
        let enhancedImage = enhanceImageContrast(resizedImage)
        
        return enhancedImage
    }
    
    /// 調整圖片大小
    /// - Parameter image: 原始圖片
    /// - Returns: 調整大小後的圖片
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 2048
        let size = image.size
        
        // 如果圖片已經夠小，直接返回
        if max(size.width, size.height) <= maxDimension {
            return image
        }
        
        // 計算新尺寸
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // 調整圖片大小
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        print("📏 圖片大小調整: \(Int(size.width))x\(Int(size.height)) → \(Int(newSize.width))x\(Int(newSize.height))")
        
        return resizedImage ?? image
    }
    
    /// 增強圖片對比度
    /// - Parameter image: 原始圖片
    /// - Returns: 增強後的圖片
    private func enhanceImageContrast(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        // 針對文字識別優化的濾鏡組合
        var processedImage = ciImage
        
        // 1. 增強對比度
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.3, forKey: kCIInputContrastKey)     // 更強的對比度
            contrastFilter.setValue(0.05, forKey: kCIInputBrightnessKey)  // 輕微增加亮度
            contrastFilter.setValue(0.0, forKey: kCIInputSaturationKey)   // 去飽和度，轉為接近黑白
            
            if let output = contrastFilter.outputImage {
                processedImage = output
            }
        }
        
        // 2. 銳化處理（對中文字特別有效）
        if let sharpenFilter = CIFilter(name: "CIUnsharpMask") {
            sharpenFilter.setValue(processedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.8, forKey: kCIInputIntensityKey)     // 銳化強度
            sharpenFilter.setValue(2.5, forKey: kCIInputRadiusKey)        // 銳化半徑
            
            if let output = sharpenFilter.outputImage {
                processedImage = output
            }
        }
        
        // 3. 噪點減少
        if let noiseFilter = CIFilter(name: "CINoiseReduction") {
            noiseFilter.setValue(processedImage, forKey: kCIInputImageKey)
            noiseFilter.setValue(0.1, forKey: "inputNoiseLevel")
            noiseFilter.setValue(0.4, forKey: "inputSharpness")
            
            if let output = noiseFilter.outputImage {
                processedImage = output
            }
        }
        
        // 轉換回 UIImage
        guard let enhancedCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            return image
        }
        
        print("✨ 圖片增強完成（對比度、銳化、噪點減少）")
        return UIImage(cgImage: enhancedCGImage)
    }
    
    // MARK: - Text Preprocessing
    
    /// 預處理識別的文字
    /// - Parameter text: 原始識別文字
    /// - Returns: 預處理後的文字
    private func preprocessText(_ text: String) -> String {
        print("📝 OCRProcessor: 預處理文字")
        
        // 移除多餘的空白和換行
        var processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 標準化換行符
        processedText = processedText.replacingOccurrences(of: "\r\n", with: "\n")
        processedText = processedText.replacingOccurrences(of: "\r", with: "\n")
        
        // 移除多餘的空行
        let lines = processedText.components(separatedBy: "\n")
        let filteredLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        processedText = filteredLines.joined(separator: "\n")
        
        // 修正常見的 OCR 錯誤
        processedText = fixCommonOCRErrors(processedText)
        
        return processedText
    }
    
    /// 修正常見的 OCR 錯誤
    /// - Parameter text: 原始文字
    /// - Returns: 修正後的文字
    private func fixCommonOCRErrors(_ text: String) -> String {
        var correctedText = text
        
        // 移除多餘的空格和符號
        correctedText = correctedText.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        
        // 修正常見的中文 OCR 錯誤
        let chineseCorrections: [String: String] = [
            "囗": "口",  // 囗 經常被誤識為 口
            "苗": "田",  // 在地址中可能混淆
            "丿": "",    // 移除多餘的撇
            "乀": "",    // 移除多餘的點
            " ": "",     // 移除中文文字中的空格
        ]
        
        // 修正英文 OCR 錯誤 (備用，目前未使用以避免過度修正)
        let _englishCorrections: [String: String] = [
            "rn": "m",   // rn 組合可能被識別為 m
            "vv": "w",   // vv 組合可能被識別為 w
            "cl": "d",   // cl 組合可能被識別為 d
            "li": "h",   // li 組合可能被識別為 h
        ]
        
        // 應用中文修正（但要小心不要過度修正）
        for (wrong, correct) in chineseCorrections {
            // 只在特定上下文中修正，避免誤修正
            if correctedText.contains(wrong) {
                print("🔧 修正中文字元: \(wrong) → \(correct)")
                correctedText = correctedText.replacingOccurrences(of: wrong, with: correct)
            }
        }
        
        // 修正電話號碼中的常見錯誤
        correctedText = fixPhoneNumberErrors(correctedText)
        
        // 修正電子郵件中的常見錯誤
        correctedText = fixEmailErrors(correctedText)
        
        return correctedText
    }
    
    /// 修正電話號碼錯誤
    private func fixPhoneNumberErrors(_ text: String) -> String {
        var correctedText = text
        
        // 常見的電話號碼字元錯誤
        let phoneCorrections: [String: String] = [
            "O": "0",   // 字母 O 在電話號碼中應該是數字 0
            "I": "1",   // 字母 I 在電話號碼中應該是數字 1
            "S": "5",   // 字母 S 在電話號碼中應該是數字 5
            "B": "8",   // 字母 B 在電話號碼中應該是數字 8
        ]
        
        // 使用正則表達式找到電話號碼模式
        let phonePattern = "[\\+]?[\\d\\s\\-\\(\\)]{8,15}"
        do {
            let regex = try NSRegularExpression(pattern: phonePattern)
            let matches = regex.matches(in: correctedText, range: NSRange(correctedText.startIndex..., in: correctedText))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: correctedText) {
                    var phoneNumber = String(correctedText[range])
                    
                    // 在電話號碼中應用修正
                    for (wrong, correct) in phoneCorrections {
                        phoneNumber = phoneNumber.replacingOccurrences(of: wrong, with: correct)
                    }
                    
                    correctedText.replaceSubrange(range, with: phoneNumber)
                }
            }
        } catch {
            print("❌ 電話號碼修正錯誤: \(error)")
        }
        
        return correctedText
    }
    
    /// 修正電子郵件錯誤
    private func fixEmailErrors(_ text: String) -> String {
        var correctedText = text
        
        // 常見的電子郵件字元錯誤
        let emailCorrections: [String: String] = [
            " @": "@",      // 移除 @ 前的空格
            "@ ": "@",      // 移除 @ 後的空格
            " .": ".",      // 移除 . 前的空格
            ". ": ".",      // 移除 . 後的空格
            "rnail": "mail", // rn 被誤識為 m
            "corn": "com",   // rn 被誤識為 m
        ]
        
        for (wrong, correct) in emailCorrections {
            correctedText = correctedText.replacingOccurrences(of: wrong, with: correct)
        }
        
        return correctedText
    }
    
    // MARK: - Field Extraction
    
    /// 從 OCR 結果提取名片欄位
    /// - Parameter ocrResult: OCR 識別結果
    /// - Returns: 提取的欄位字典
    private func extractBusinessCardFields(from ocrResult: OCRResult) -> [String: String] {
        print("🏷️ OCRProcessor: 提取名片欄位")
        
        let text = ocrResult.recognizedText
        var extractedFields: [String: String] = [:]
        
        // 提取電話號碼
        extractedFields["phone"] = extractPhoneNumbers(from: text).first
        
        // 提取電子郵件
        extractedFields["email"] = extractEmails(from: text).first
        
        // 提取網址
        extractedFields["website"] = extractWebsites(from: text).first
        
        // 提取公司名稱（基於位置推測）
        extractedFields["company"] = extractCompanyName(from: ocrResult)
        
        // 提取人名（基於位置推測）
        extractedFields["name"] = extractPersonName(from: ocrResult)
        
        // 提取職位
        extractedFields["title"] = extractJobTitle(from: text)
        
        // 提取地址
        extractedFields["address"] = extractAddress(from: text)
        
        print("📊 提取到 \(extractedFields.count) 個欄位")
        
        return extractedFields
    }
    
    /// 提取電話號碼
    /// - Parameter text: 文字內容
    /// - Returns: 電話號碼陣列
    private func extractPhoneNumbers(from text: String) -> [String] {
        let phonePatterns = [
            "\\+?886[\\s\\-]?\\d[\\s\\-]?\\d{4}[\\s\\-]?\\d{4}",  // 台灣手機
            "\\+?886[\\s\\-]?\\d{1,2}[\\s\\-]?\\d{4}[\\s\\-]?\\d{4}", // 台灣市話
            "\\d{4}[\\s\\-]?\\d{4}",                              // 簡化格式
            "\\d{2,3}[\\s\\-]?\\d{4}[\\s\\-]?\\d{4}",            // 一般格式
            "\\(\\d{2,3}\\)[\\s\\-]?\\d{4}[\\s\\-]?\\d{4}"      // 括號格式
        ]
        
        return extractWithPatterns(from: text, patterns: phonePatterns)
    }
    
    /// 提取電子郵件
    /// - Parameter text: 文字內容
    /// - Returns: 電子郵件陣列
    private func extractEmails(from text: String) -> [String] {
        let emailPattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return extractWithPatterns(from: text, patterns: [emailPattern])
    }
    
    /// 提取網址
    /// - Parameter text: 文字內容
    /// - Returns: 網址陣列
    private func extractWebsites(from text: String) -> [String] {
        let websitePatterns = [
            "https?://[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=]+",
            "www\\.[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=]+",
            "[\\w\\-]+\\.(com|org|net|edu|gov|mil|int|co|tw|cn|jp|kr)"
        ]
        
        return extractWithPatterns(from: text, patterns: websitePatterns)
    }
    
    /// 使用正則表達式提取
    /// - Parameters:
    ///   - text: 文字內容
    ///   - patterns: 正則表達式模式陣列
    /// - Returns: 匹配結果陣列
    private func extractWithPatterns(from text: String, patterns: [String]) -> [String] {
        var results: [String] = []
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        results.append(String(text[range]))
                    }
                }
            } catch {
                print("❌ 正則表達式錯誤: \(error)")
            }
        }
        
        return results
    }
    
    /// 提取公司名稱（基於位置推測）
    /// - Parameter ocrResult: OCR 結果
    /// - Returns: 公司名稱
    private func extractCompanyName(from ocrResult: OCRResult) -> String? {
        // 通常公司名稱在名片的上方或中間區域
        let upperRegion = CGRect(x: 0, y: 0.5, width: 1.0, height: 0.5)
        let upperTexts = visionService.extractTextInRegion(ocrResult.boundingBoxes, region: upperRegion)
        
        // 中文公司名稱關鍵字
        let chineseCompanyKeywords = ["公司", "企業", "集團", "有限", "股份", "科技", "實業", "貿易", "工業", "建設", "開發", "投資", "顧問", "事務所", "工作室", "中心"]
        
        // 英文公司名稱關鍵字  
        let englishCompanyKeywords = ["Ltd", "Inc", "Corp", "Company", "Enterprise", "Group", "Technology", "Tech", "Solutions", "Systems", "Services", "Consulting", "Studio", "Center", "LLC", "Co"]
        
        // 優先尋找包含公司關鍵字的文字
        for text in upperTexts.sorted(by: { $0.count > $1.count }) {
            // 檢查中文公司關鍵字
            for keyword in chineseCompanyKeywords {
                if text.contains(keyword) {
                    print("🏢 發現中文公司名稱: \(text)")
                    return text
                }
            }
            
            // 檢查英文公司關鍵字
            for keyword in englishCompanyKeywords {
                if text.localizedCaseInsensitiveContains(keyword) {
                    print("🏢 發現英文公司名稱: \(text)")
                    return text
                }
            }
        }
        
        // 如果沒有找到關鍵字，選擇最長且不是人名的文字
        for text in upperTexts.sorted(by: { $0.count > $1.count }) {
            // 排除可能是人名的短文字（2-4個中文字）
            let chineseNamePattern = "^[\\u4e00-\\u9fff]{2,4}$"
            if text.range(of: chineseNamePattern, options: .regularExpression) == nil &&
               text.count > 4 &&
               !text.contains("@") &&
               !text.contains("www") {
                print("🏢 推測公司名稱: \(text)")
                return text
            }
        }
        
        // 最後選擇最長的文字行
        return upperTexts.max(by: { $0.count < $1.count })
    }
    
    /// 提取人名（基於位置推測）
    /// - Parameter ocrResult: OCR 結果
    /// - Returns: 人名
    private func extractPersonName(from ocrResult: OCRResult) -> String? {
        // 通常人名在名片的上方區域，且相對較短
        let upperRegion = CGRect(x: 0, y: 0.6, width: 1.0, height: 0.4)
        let upperTexts = visionService.extractTextInRegion(ocrResult.boundingBoxes, region: upperRegion)
        
        // 中文人名特徵：2-4個中文字元，不包含數字和符號
        let chineseNamePattern = "^[\\u4e00-\\u9fff]{2,4}$"
        
        // 英文人名特徵：2-20個英文字母和空格
        let englishNamePattern = "^[a-zA-Z\\s]{2,20}$"
        
        // 優先尋找中文人名
        for text in upperTexts {
            if text.range(of: chineseNamePattern, options: .regularExpression) != nil {
                print("🏷️ 發現中文人名候選: \(text)")
                return text
            }
        }
        
        // 再尋找英文人名
        for text in upperTexts {
            if text.range(of: englishNamePattern, options: .regularExpression) != nil &&
               !text.contains("@") && !text.contains("www") && !text.contains(".com") {
                print("🏷️ 發現英文人名候選: \(text)")
                return text
            }
        }
        
        // 如果沒有找到符合模式的，使用原來的邏輯
        let nameCandidate = upperTexts.first { text in
            let length = text.count
            return length >= 2 && length <= 10 && !text.contains("@") && !text.contains("www")
        }
        
        return nameCandidate
    }
    
    /// 提取職位
    /// - Parameter text: 文字內容
    /// - Returns: 職位
    private func extractJobTitle(from text: String) -> String? {
        // 中文職位關鍵字
        let chineseTitleKeywords = [
            // 高階主管
            "執行長", "總經理", "副總經理", "總裁", "副總裁", "董事長", "副董事長",
            // 部門主管
            "總監", "副總監", "經理", "副經理", "協理", "處長", "副處長", "主任", "副主任",
            // 專業職位
            "工程師", "設計師", "分析師", "顧問", "專員", "助理", "秘書", "會計師", "律師",
            // 技術職位
            "開發工程師", "軟體工程師", "系統工程師", "網路工程師", "資深工程師",
            // 業務職位
            "業務經理", "業務代表", "銷售經理", "客戶經理", "專案經理",
            // 其他
            "負責人", "創辦人", "合夥人"
        ]
        
        // 英文職位關鍵字
        let englishTitleKeywords = [
            "CEO", "CTO", "CFO", "COO", "CIO", "CMO", "VP", "SVP", "EVP",
            "President", "Director", "Manager", "Supervisor", "Coordinator",
            "Engineer", "Developer", "Designer", "Analyst", "Consultant",
            "Specialist", "Assistant", "Associate", "Representative",
            "Senior", "Junior", "Lead", "Principal", "Chief"
        ]
        
        let lines = text.components(separatedBy: .newlines)
        
        // 優先尋找中文職位
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            for keyword in chineseTitleKeywords {
                if trimmedLine.contains(keyword) {
                    print("💼 發現中文職位: \(trimmedLine)")
                    return trimmedLine
                }
            }
        }
        
        // 再尋找英文職位
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            for keyword in englishTitleKeywords {
                if trimmedLine.localizedCaseInsensitiveContains(keyword) {
                    print("💼 發現英文職位: \(trimmedLine)")
                    return trimmedLine
                }
            }
        }
        
        // 使用模式匹配尋找可能的職位
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 中文職位模式：包含"長"、"師"、"員"等結尾的詞
            if trimmedLine.range(of: "[\\u4e00-\\u9fff]*[長師員理監]$", options: .regularExpression) != nil &&
               trimmedLine.count >= 2 && trimmedLine.count <= 10 {
                print("💼 模式匹配中文職位: \(trimmedLine)")
                return trimmedLine
            }
            
            // 英文職位模式：以常見職位詞結尾
            if trimmedLine.range(of: "\\b(manager|director|engineer|designer|analyst)\\b", options: [.regularExpression, .caseInsensitive]) != nil {
                print("💼 模式匹配英文職位: \(trimmedLine)")
                return trimmedLine
            }
        }
        
        return nil
    }
    
    /// 提取地址
    /// - Parameter text: 文字內容
    /// - Returns: 地址
    private func extractAddress(from text: String) -> String? {
        // 中文地址關鍵字
        let chineseAddressKeywords = [
            // 行政區劃
            "市", "區", "縣", "鄉", "鎮", "村", "里",
            // 道路類型
            "路", "街", "道", "大道", "小道", "巷", "弄", "衖",
            // 建築物
            "號", "樓", "層", "室", "座", "棟", "館", "大樓", "大廈", "廣場", "中心",
            // 特殊地點
            "工業區", "科技園", "商業區", "開發區"
        ]
        
        // 英文地址關鍵字
        let englishAddressKeywords = [
            "Street", "St", "Road", "Rd", "Avenue", "Ave", "Boulevard", "Blvd",
            "Lane", "Ln", "Drive", "Dr", "Court", "Ct", "Place", "Pl",
            "Floor", "Fl", "Room", "Suite", "Building", "Tower", "Center"
        ]
        
        let lines = text.components(separatedBy: .newlines)
        
        // 尋找包含地址關鍵字的最長行
        var bestAddressLine: String?
        var maxScore = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            var score = 0
            
            // 計算中文地址關鍵字匹配分數
            for keyword in chineseAddressKeywords {
                if trimmedLine.contains(keyword) {
                    score += keyword.count // 關鍵字越長，分數越高
                }
            }
            
            // 計算英文地址關鍵字匹配分數
            for keyword in englishAddressKeywords {
                if trimmedLine.localizedCaseInsensitiveContains(keyword) {
                    score += keyword.count
                }
            }
            
            // 地址必須有一定長度且不能是電話或郵件
            if score > 0 && trimmedLine.count >= 8 && 
               !trimmedLine.contains("@") && 
               trimmedLine.range(of: "\\d{4}-?\\d{4}", options: .regularExpression) == nil {
                
                if score > maxScore {
                    maxScore = score
                    bestAddressLine = trimmedLine
                }
            }
        }
        
        if let address = bestAddressLine {
            print("📍 發現地址: \(address)")
            return address
        }
        
        // 使用模式匹配尋找可能的地址
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 中文地址模式：包含數字+中文地址詞
            if trimmedLine.range(of: "\\d+.*[市區路街號樓]", options: .regularExpression) != nil &&
               trimmedLine.count >= 10 && trimmedLine.count <= 50 {
                print("📍 模式匹配中文地址: \(trimmedLine)")
                return trimmedLine
            }
            
            // 英文地址模式：數字+英文地址詞
            if trimmedLine.range(of: "\\d+.*\\b(street|road|avenue|floor|room)\\b", options: [.regularExpression, .caseInsensitive]) != nil &&
               trimmedLine.count >= 10 && trimmedLine.count <= 50 {
                print("📍 模式匹配英文地址: \(trimmedLine)")
                return trimmedLine
            }
        }
        
        return nil
    }
}