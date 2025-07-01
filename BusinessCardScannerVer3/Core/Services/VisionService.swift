//
//  VisionService.swift
//  BusinessCardScannerVer3
//
//  Vision Framework OCR 服務
//

import UIKit
import Vision
import Combine

/// OCR 識別結果
struct OCRResult {
    let recognizedText: String
    let confidence: Float
    let boundingBoxes: [TextBoundingBox]
    let processingTime: TimeInterval
}

/// 文字邊界框資訊
struct TextBoundingBox {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
    let topCandidates: [String]
}

/// OCR 錯誤類型
enum OCRError: LocalizedError {
    case imageProcessingFailed
    case noTextFound
    case visionRequestFailed(Error)
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "圖片處理失敗"
        case .noTextFound:
            return "未找到文字"
        case .visionRequestFailed(let error):
            return "Vision 識別失敗: \(error.localizedDescription)"
        case .invalidImage:
            return "無效的圖片"
        }
    }
}

/// Vision Framework OCR 服務
class VisionService {
    
    // MARK: - Singleton
    
    static let shared = VisionService()
    private init() {}
    
    // MARK: - Properties
    
    /// OCR 請求配置
    private var textRecognitionRequest: VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        
        // 設定識別等級（精確度 vs 速度）
        request.recognitionLevel = .accurate
        
        // 檢查並設定支援的語言
        let supportedLanguages = try? VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision1)
        print("🌍 VisionService: 系統支援的語言: \(supportedLanguages ?? [])")
        
        // 優先設定中文識別
        let desiredLanguages = ["zh-Hant", "zh-Hans", "en-US"]
        var availableLanguages: [String] = []
        
        if let supported = supportedLanguages {
            for lang in desiredLanguages {
                if supported.contains(lang) {
                    availableLanguages.append(lang)
                    print("✅ 語言支援: \(lang)")
                } else {
                    print("❌ 語言不支援: \(lang)")
                }
            }
        }
        
        // 如果沒有找到支援的語言，使用預設設定
        if availableLanguages.isEmpty {
            print("⚠️ 使用預設語言設定")
            request.recognitionLanguages = ["en-US"]
        } else {
            request.recognitionLanguages = availableLanguages
            print("🎯 使用語言: \(availableLanguages)")
        }
        
        // 使用語言校正
        request.usesLanguageCorrection = true
        
        // 設定最小文字高度（降低閾值以提高小字識別）
        request.minimumTextHeight = 0.02
        
        // 設定自動識別語言
        request.automaticallyDetectsLanguage = true
        
        return request
    }
    
    // MARK: - Public Methods
    
    /// 對圖片執行 OCR 文字識別
    /// - Parameters:
    ///   - image: 要識別的圖片
    ///   - completion: 完成回調 (Result<OCRResult, OCRError>)
    func recognizeText(from image: UIImage, completion: @escaping (Result<OCRResult, OCRError>) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let cgImage = image.cgImage else {
            completion(.failure(.invalidImage))
            return
        }
        
        // 在背景執行緒處理
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let request = self.textRecognitionRequest
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
                
                guard let observations = request.results else {
                    DispatchQueue.main.async {
                        completion(.failure(.noTextFound))
                    }
                    return
                }
                
                let result = self.processObservations(observations, processingTime: CFAbsoluteTimeGetCurrent() - startTime)
                
                DispatchQueue.main.async {
                    completion(.success(result))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.visionRequestFailed(error)))
                }
            }
        }
    }
    
    /// 對圖片執行 OCR 文字識別 (Combine 版本)
    /// - Parameter image: 要識別的圖片
    /// - Returns: OCR 結果的 Publisher
    func recognizeText(from image: UIImage) -> AnyPublisher<OCRResult, OCRError> {
        return Future { [weak self] promise in
            self?.recognizeText(from: image) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// 處理 Vision 識別結果
    /// - Parameters:
    ///   - observations: Vision 識別觀察結果
    ///   - processingTime: 處理時間
    /// - Returns: OCR 結果
    private func processObservations(_ observations: [VNRecognizedTextObservation], processingTime: TimeInterval) -> OCRResult {
        var allText: [String] = []
        var boundingBoxes: [TextBoundingBox] = []
        var totalConfidence: Float = 0.0
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let text = topCandidate.string
            let confidence = topCandidate.confidence
            
            allText.append(text)
            totalConfidence += confidence
            
            // 取得更多候選項目
            let candidates = observation.topCandidates(3).map { $0.string }
            
            // 建立邊界框資訊
            let boundingBox = TextBoundingBox(
                text: text,
                confidence: confidence,
                boundingBox: observation.boundingBox,
                topCandidates: candidates
            )
            
            boundingBoxes.append(boundingBox)
        }
        
        let recognizedText = allText.joined(separator: "\n")
        let averageConfidence = observations.isEmpty ? 0.0 : totalConfidence / Float(observations.count)
        
        print("🔍 VisionService: OCR 完成")
        print("📝 識別文字長度: \(recognizedText.count) 字元")
        print("🎯 平均信心度: \(String(format: "%.2f", averageConfidence))")
        print("⏱️ 處理時間: \(String(format: "%.3f", processingTime)) 秒")
        print("📦 邊界框數量: \(boundingBoxes.count)")
        
        #if DEBUG
        print("📄 識別內容預覽:")
        print(recognizedText.prefix(200))
        if recognizedText.count > 200 {
            print("... (總共 \(recognizedText.count) 字元)")
        }
        #endif
        
        return OCRResult(
            recognizedText: recognizedText,
            confidence: averageConfidence,
            boundingBoxes: boundingBoxes,
            processingTime: processingTime
        )
    }
    
    // MARK: - Utility Methods
    
    /// 從邊界框資訊提取特定區域的文字
    /// - Parameters:
    ///   - boundingBoxes: 邊界框陣列
    ///   - region: 目標區域 (正規化座標 0.0-1.0)
    /// - Returns: 該區域的文字陣列
    func extractTextInRegion(_ boundingBoxes: [TextBoundingBox], region: CGRect) -> [String] {
        return boundingBoxes.compactMap { box in
            if box.boundingBox.intersects(region) {
                return box.text
            }
            return nil
        }
    }
    
    /// 根據信心度過濾文字
    /// - Parameters:
    ///   - boundingBoxes: 邊界框陣列
    ///   - minimumConfidence: 最小信心度閾值
    /// - Returns: 過濾後的文字陣列
    func filterTextByConfidence(_ boundingBoxes: [TextBoundingBox], minimumConfidence: Float) -> [String] {
        return boundingBoxes.compactMap { box in
            if box.confidence >= minimumConfidence {
                return box.text
            }
            return nil
        }
    }
    
    /// 取得支援的語言列表
    /// - Returns: 支援的語言代碼陣列
    func getSupportedLanguages() -> [String] {
        return ["en-US", "zh-Hant", "zh-Hans"]
    }
    
    /// 檢查 Vision Framework 可用性
    /// - Returns: 是否可用
    func isVisionAvailable() -> Bool {
        if #available(iOS 13.0, *) {
            return true
        } else {
            return false
        }
    }
}

