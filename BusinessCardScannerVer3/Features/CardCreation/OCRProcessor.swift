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
        
        // 1. 預處理圖片
        let preprocessedImage = preprocessImage(image)
        
        // 2. 執行 OCR
        visionService.recognizeText(from: preprocessedImage) { [self] result in
            switch result {
            case .success(let ocrResult):
                // 3. 後處理文字
                let preprocessedText = self.preprocessText(ocrResult.recognizedText)
                
                // 4. 提取欄位
                let extractedFields = self.extractBusinessCardFields(from: ocrResult)
                
                // 5. 建立最終結果
                let processingResult = OCRProcessingResult(
                    originalImage: image,
                    ocrResult: ocrResult,
                    preprocessedText: preprocessedText,
                    extractedFields: extractedFields
                )
                
                completion(.success(processingResult))
                
            case .failure(let error):
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
        
        // 修正常見的中文 OCR 錯誤（擴充版）
        let chineseCorrections: [String: String] = [
            // 基本字符修正
            "囗": "口",  // 囗 經常被誤識為 口
            "苗": "田",  // 在地址中可能混淆
            "丿": "",    // 移除多餘的撇
            "乀": "",    // 移除多餘的點
            
            // 人名相關修正
            "勤": "勤",  // 確保正確的勤字
            "德": "德",  // 確保正確的德字
            
            // 職位相關修正
            "栽": "裁",  // 總栽 → 總裁
            "哉": "裁",  // 總哉 → 總裁
            "埋": "理",  // 經埋 → 經理
            "肋": "助",  // 特肋 → 特助
            "勘": "助",  // 特勘 → 特助
            "衍": "行",  // 執衍長 → 執行長
            
            // 公司相關修正
            "集園": "集團", // 集園 → 集團
            "集困": "集團", // 集困 → 集團
        ]
        
        // 注意：英文 OCR 修正功能暫時移除以避免過度修正
        // 如果未來需要英文修正，可在此處添加相關邏輯
        
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
    internal func extractBusinessCardFields(from ocrResult: OCRResult) -> [String: String] {
        let text = ocrResult.recognizedText
        var extractedFields: [String: String] = [:]
        
        // 分別提取市內電話和手機號碼
        let phoneNumbers = extractPhoneNumbers(from: text)
        let (landlinePhone, mobilePhone) = separatePhoneNumbers(phoneNumbers)
        
        extractedFields["phone"] = landlinePhone
        extractedFields["mobile"] = mobilePhone
        
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
        return extractedFields
    }
    
    /// 提取電話號碼
    /// - Parameter text: 文字內容
    /// - Returns: 電話號碼陣列
    private func extractPhoneNumbers(from text: String) -> [String] {
        // 改進的台灣電話號碼模式
        let phonePatterns = [
            // 手機號碼模式
            "09\\d{2}[\\s\\-]?\\d{3}[\\s\\-]?\\d{3}",           // 09xx-xxx-xxx
            "\\+?886[\\s\\-]?9\\d{2}[\\s\\-]?\\d{3}[\\s\\-]?\\d{3}", // +886-9xx-xxx-xxx
            
            // 市內電話模式
            "\\(?0[2-8]\\)?[\\s\\-]?\\d{3,4}[\\s\\-]?\\d{4}",    // (0x)xxxx-xxxx
            "\\+?886[\\s\\-]?[2-8][\\s\\-]?\\d{3,4}[\\s\\-]?\\d{4}", // +886-x-xxxx-xxxx
            
            // 簡化格式（更寬鬆）
            "\\d{8,10}",                                       // 純數字8-10位
            "\\d{2,4}[\\s\\-]\\d{4}[\\s\\-]?\\d{4}?",           // 2-4位區碼格式
            "\\(\\d{2,4}\\)[\\s\\-]?\\d{4}[\\s\\-]?\\d{4}?"     // 括號格式
        ]
        
        var results = extractWithPatterns(from: text, patterns: phonePatterns)
        
        // 從關鍵字後提取電話號碼（改進版）
        let phoneKeywords = ["電話", "Tel", "Phone", "手機", "Mobile", "Cell", "Fax"]
        for keyword in phoneKeywords {
            // 更寬鬆的模式，支援更多格式
            if let regex = try? NSRegularExpression(pattern: "\\b\(keyword)[：:﹕︰\\s]*([\\d\\s\\-\\(\\)\\+]{8,20})", options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) {
                        let phone = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !phone.isEmpty {
                            print("📞 從關鍵字 '\(keyword)' 提取到電話: '\(phone)'")
                            results.append(phone)
                        }
                    }
                }
            }
        }
        
        // 去重並清理
        let uniqueResults = Array(Set(results))
        return uniqueResults.map { cleanPhoneNumber($0) }.filter { !$0.isEmpty }
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
    
    /// 分離市內電話和手機號碼
    /// - Parameter phoneNumbers: 電話號碼陣列
    /// - Returns: (市內電話, 手機號碼)
    private func separatePhoneNumbers(_ phoneNumbers: [String]) -> (String?, String?) {
        var landlinePhone: String? = nil
        var mobilePhone: String? = nil
        
        for phone in phoneNumbers {
            // 保留原始格式，用於判斷的清理版本
            let cleanPhoneForCheck = phone.replacingOccurrences(of: "[^\\d+]", with: "", options: .regularExpression)
            let originalPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 判斷是否為手機號碼
            if cleanPhoneForCheck.hasPrefix("09") || cleanPhoneForCheck.hasPrefix("+8869") || cleanPhoneForCheck.hasPrefix("8869") {
                if mobilePhone == nil {
                    mobilePhone = originalPhone  // 保留原始格式
                }
            } else {
                // 判斷是否為市內電話
                if (cleanPhoneForCheck.hasPrefix("02") || cleanPhoneForCheck.hasPrefix("03") || cleanPhoneForCheck.hasPrefix("04") || 
                    cleanPhoneForCheck.hasPrefix("05") || cleanPhoneForCheck.hasPrefix("06") || cleanPhoneForCheck.hasPrefix("07") || 
                    cleanPhoneForCheck.hasPrefix("08") || cleanPhoneForCheck.hasPrefix("+8862") || cleanPhoneForCheck.hasPrefix("+8863") ||
                    cleanPhoneForCheck.hasPrefix("+8864") || cleanPhoneForCheck.hasPrefix("+8865") || cleanPhoneForCheck.hasPrefix("+8866") ||
                    cleanPhoneForCheck.hasPrefix("+8867") || cleanPhoneForCheck.hasPrefix("+8868")) {
                    if landlinePhone == nil {
                        landlinePhone = originalPhone  // 保留原始格式
                    }
                } else if cleanPhoneForCheck.count >= 8 && cleanPhoneForCheck.count <= 10 && !cleanPhoneForCheck.hasPrefix("09") {
                    // 其他可能的市內電話格式
                    if landlinePhone == nil {
                        landlinePhone = originalPhone  // 保留原始格式
                    }
                }
            }
        }
        
        return (landlinePhone, mobilePhone)
    }
    
    /// 清理電話號碼格式
    /// - Parameter phone: 原始電話號碼
    /// - Returns: 清理後的電話號碼
    private func cleanPhoneNumber(_ phone: String) -> String {
        // 移除多餘的空格和符號
        var cleaned = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除重複的連字符
        cleaned = cleaned.replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
        
        // 移除多餘的空格
        cleaned = cleaned.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        
        return cleaned
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
        let upperRegion = CGRect(x: 0, y: 0, width: 1.0, height: 0.5)
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
        // 調整人名區域：通常在名片的上方區域（y: 0 表示從頂部開始）
        let upperRegion = CGRect(x: 0, y: 0, width: 1.0, height: 0.5)
        let upperTexts = visionService.extractTextInRegion(ocrResult.boundingBoxes, region: upperRegion)
                
        // 中文人名特徵：2-4個中文字元，不包含數字和符號
        let chineseNamePattern = "^[\\u4e00-\\u9fff]{2,4}$"
        
        // 英文人名特徵：改進模式，支援 "First Last" 格式
        let englishNamePattern = "^[A-Za-z]+\\s+[A-Za-z]+$"
        
        // 台灣名片優先尋找中文人名
        var chineseNameCandidate: String? = nil
        var englishNameCandidate: String? = nil
        
        // 排除關鍵字
        let excludeKeywords = ["公司", "企業", "集團", "有限", "股份", "科技", "實業", "貿易", "Ltd", "Inc", "Corp", "Company", "Technology", "Tech", "@", "www", ".com"]
        
        // 收集候選人名
        for text in upperTexts {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 檢查是否包含排除關鍵字
            let containsExcludeKeyword = excludeKeywords.contains { keyword in
                trimmedText.localizedCaseInsensitiveContains(keyword)
            }
            
            // 收集中文人名候選
            if trimmedText.range(of: chineseNamePattern, options: .regularExpression) != nil && !containsExcludeKeyword {
                if chineseNameCandidate == nil {
                    chineseNameCandidate = trimmedText
                }
            } else if trimmedText.range(of: chineseNamePattern, options: .regularExpression) != nil {
            }
            
            // 收集英文人名候選
            if trimmedText.range(of: englishNamePattern, options: .regularExpression) != nil &&
               !trimmedText.contains("@") && 
               !trimmedText.contains("www") && 
               !trimmedText.contains(".com") &&
               !trimmedText.localizedCaseInsensitiveContains("company") &&
               !trimmedText.localizedCaseInsensitiveContains("ltd") &&
               !trimmedText.localizedCaseInsensitiveContains("inc") {
                if englishNameCandidate == nil {
                    englishNameCandidate = trimmedText
                }
            }
        }
        
        // 優先返回中文人名
        if let chineseName = chineseNameCandidate {
            return chineseName
        }
        
        // 備選英文人名
        if let englishName = englishNameCandidate {
            return englishName
        }
        
        // 如果沒有找到符合嚴格模式的，使用寬鬆邏輯
        // 但排除明顯的公司名稱和聯絡資訊
        for text in upperTexts {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let length = trimmedText.count
            
            // 長度適中且不包含排除關鍵字
            if length >= 2 && length <= 15 {
                let containsExcludeKeyword = excludeKeywords.contains { keyword in
                    trimmedText.localizedCaseInsensitiveContains(keyword)
                }
                
                if !containsExcludeKeyword {
                    return trimmedText
                }
            }
        }
        return nil
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
