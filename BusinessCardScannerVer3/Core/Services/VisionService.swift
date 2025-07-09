//
//  VisionService.swift
//  BusinessCardScannerVer3
//
//  Vision Framework OCR 服務
//

import UIKit
import Vision
import Combine
import CoreImage

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

/// 名片偵測結果
struct CardDetectionResult {
    let observation: VNRectangleObservation
    let croppedImage: UIImage
    let confidence: Float
}

/// 完整的名片處理結果
struct BusinessCardProcessResult {
    let croppedImage: UIImage
    let ocrResult: OCRResult
}

/// Vision 服務錯誤類型
enum VisionError: LocalizedError {
    case imageProcessingFailed
    case noTextFound
    case visionRequestFailed(Error)
    case invalidImage
    case noRectangleDetected
    case croppingFailed
    case lowConfidence
    
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
        case .noRectangleDetected:
            return "未偵測到名片"
        case .croppingFailed:
            return "裁切失敗"
        case .lowConfidence:
            return "識別信心度過低"
        }
    }
}

/// OCR 錯誤類型（向後相容）
typealias OCRError = VisionError

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
        
        // 使用最新的 revision 以確保 API 安全性和兼容性
        // 移除已棄用的 supportedRecognitionLanguages 檢查，直接設定支援的語言
        print("🌍 VisionService: 使用系統預設支援的語言配置")
        
        // 修正：使用 Ver2 的條件式語言設定邏輯
        if #available(iOS 16.0, *) {
            // iOS 16+ 支援更多語言
            request.recognitionLanguages = ["zh-Hant", "en-US"] // 繁體中文和英文
            print("🎯 iOS 16+ 使用語言: [\"zh-Hant\", \"en-US\"]")
        } else {
            // iOS 15 及以下版本使用英文
            request.recognitionLanguages = ["en-US"]
            print("🎯 iOS 15- 使用語言: [\"en-US\"]")
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
        
        // 先正規化圖片方向（參考 Ver2）
        guard let normalizedImage = image.normalizeOrientation(),
              let cgImage = normalizedImage.cgImage else {
            completion(.failure(.invalidImage))
            return
        }
        
        // 在背景執行緒處理
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let request = self.textRecognitionRequest
            // 使用正規化後的圖片，方向為 .up
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            
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
    
    // MARK: - 名片偵測與裁切 (參考 Ver2)
    
    /// 偵測圖片中的矩形（名片）
    func detectRectangle(in image: UIImage, completion: @escaping (Result<VNRectangleObservation, VisionError>) -> Void) {
        print("🔍 VisionService: 開始偵測名片矩形，圖片尺寸: \(image.size)")
        
        // 先正規化圖片方向
        guard let normalizedImage = image.normalizeOrientation(),
              let cgImage = normalizedImage.cgImage else {
            print("❌ VisionService: 圖片正規化失敗")
            completion(.failure(.imageProcessingFailed))
            return
        }
        
        print("🔍 VisionService: 圖片正規化完成，CGImage 尺寸: \(cgImage.width)x\(cgImage.height)")
        
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                print("🔍 VisionService: 矩形偵測錯誤: \(error)")
                completion(.failure(.noRectangleDetected))
                return
            }
            
            guard let observations = request.results as? [VNRectangleObservation] else {
                print("🔍 VisionService: 沒有偵測結果")
                completion(.failure(.noRectangleDetected))
                return
            }
            
            print("🔍 VisionService: 偵測到 \(observations.count) 個矩形候選")
            
            if observations.isEmpty {
                print("🔍 VisionService: 矩形列表為空")
                completion(.failure(.noRectangleDetected))
                return
            }
            
            // 顯示所有偵測結果的詳細資訊
            for (index, obs) in observations.enumerated() {
                print("🔍 矩形 \(index + 1): 信心度=\(String(format: "%.3f", obs.confidence))")
            }
            
            // 選擇信心度最高的矩形
            let sortedObservations = observations.sorted { $0.confidence > $1.confidence }
            if let best = sortedObservations.first {
                print("✅ VisionService: 選擇最佳矩形，信心度: \(String(format: "%.3f", best.confidence))")
                completion(.success(best))
            } else {
                print("❌ VisionService: 無法找到合適的矩形")
                completion(.failure(.noRectangleDetected))
            }
        }
        
        // 設定偵測參數（參考 Ver2 的成功經驗）
        request.minimumAspectRatio = 0.3  // 名片可能的最小長寬比
        request.maximumAspectRatio = 0.9  // 名片可能的最大長寬比
        request.minimumSize = 0.2         // 最小尺寸（相對於圖片）
        request.maximumObservations = 3   // 最多偵測3個矩形
        request.minimumConfidence = 0.5   // 最低信心度
        
        print("🔍 VisionService: 偵測參數設定完成")
        print("   - 長寬比範圍: \(request.minimumAspectRatio) ~ \(request.maximumAspectRatio)")
        print("   - 最小尺寸: \(request.minimumSize)")
        print("   - 最低信心度: \(request.minimumConfidence)")
        print("   - 最大觀察數: \(request.maximumObservations)")
        
        // 執行請求 - 使用正規化後的圖片，方向為 .up
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Vision 執行錯誤: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.noRectangleDetected))
                }
            }
        }
    }
    
    /// 根據偵測結果裁切名片
    func cropCard(from image: UIImage, observation: VNRectangleObservation, completion: @escaping (Result<UIImage, VisionError>) -> Void) {
        print("✂️ VisionService: 開始裁切名片，觀察信心度: \(String(format: "%.3f", observation.confidence))")
        
        // 先將 UIImage 正規化（修正方向）
        guard let normalizedImage = image.normalizeOrientation(),
              let cgImage = normalizedImage.cgImage else {
            print("❌ VisionService: 裁切前圖片正規化失敗")
            completion(.failure(.imageProcessingFailed))
            return
        }
        
        print("✂️ VisionService: 裁切圖片正規化完成，尺寸: \(cgImage.width)x\(cgImage.height)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 使用 Core Image 進行透視校正和裁切
            let ciImage = CIImage(cgImage: cgImage)
            
            // 將正規化座標轉換為圖片座標
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            
            // Vision Framework 的座標系統：左下角為原點 (0,0)
            // Core Image 的座標系統：左下角為原點 (0,0)
            // 所以不需要 Y 軸反轉
            let topLeft = CGPoint(x: observation.topLeft.x * imageSize.width,
                                 y: observation.topLeft.y * imageSize.height)
            let topRight = CGPoint(x: observation.topRight.x * imageSize.width,
                                  y: observation.topRight.y * imageSize.height)
            let bottomLeft = CGPoint(x: observation.bottomLeft.x * imageSize.width,
                                    y: observation.bottomLeft.y * imageSize.height)
            let bottomRight = CGPoint(x: observation.bottomRight.x * imageSize.width,
                                     y: observation.bottomRight.y * imageSize.height)
            
            // 建立透視校正濾鏡
            guard let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection") else {
                DispatchQueue.main.async {
                    completion(.failure(.croppingFailed))
                }
                return
            }
            
            perspectiveFilter.setValue(ciImage, forKey: kCIInputImageKey)
            perspectiveFilter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
            perspectiveFilter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
            perspectiveFilter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
            perspectiveFilter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
            
            // 取得校正後的圖片
            guard let outputImage = perspectiveFilter.outputImage else {
                DispatchQueue.main.async {
                    completion(.failure(.croppingFailed))
                }
                return
            }
            
            // 轉換回 UIImage
            let context = CIContext()
            if let correctedCGImage = context.createCGImage(outputImage, from: outputImage.extent) {
                // 使用正常方向建立 UIImage
                let correctedUIImage = UIImage(cgImage: correctedCGImage)
                print("✅ VisionService: 透視校正成功，裁切後尺寸: \(correctedUIImage.size)")
                DispatchQueue.main.async {
                    completion(.success(correctedUIImage))
                }
            } else {
                print("❌ VisionService: 透視校正後無法建立 UIImage")
                DispatchQueue.main.async {
                    completion(.failure(.croppingFailed))
                }
            }
        }
    }
    
    /// 完整的名片處理流程：偵測 → 裁切 → OCR
    func processBusinessCard(image: UIImage, completion: @escaping (Result<BusinessCardProcessResult, VisionError>) -> Void) {
        print("🎯 VisionService: 開始完整名片處理流程")
        
        // Step 1: 偵測名片
        detectRectangle(in: image) { [weak self] rectangleResult in
            guard let self = self else { return }
            
            switch rectangleResult {
            case .success(let observation):
                print("✅ VisionService: Step 1 完成 - 名片偵測成功")
                
                // Step 2: 裁切名片
                self.cropCard(from: image, observation: observation) { cropResult in
                    switch cropResult {
                    case .success(let croppedImage):
                        print("✅ VisionService: Step 2 完成 - 名片裁切成功，尺寸: \(croppedImage.size)")
                        
                        // Step 3: OCR 識別
                        self.recognizeText(from: croppedImage) { ocrResult in
                            switch ocrResult {
                            case .success(let ocr):
                                print("✅ VisionService: Step 3 完成 - OCR 識別成功")
                                let result = BusinessCardProcessResult(croppedImage: croppedImage, ocrResult: ocr)
                                completion(.success(result))
                            case .failure(let error):
                                print("❌ VisionService: Step 3 失敗 - OCR 識別失敗: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        print("❌ VisionService: Step 2 失敗 - 名片裁切失敗: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                // 如果偵測失敗，直接對原圖進行 OCR
                print("⚠️ VisionService: Step 1 失敗 - 矩形偵測失敗，改用原圖 OCR")
                self.recognizeText(from: image) { ocrResult in
                    switch ocrResult {
                    case .success(let ocr):
                        print("✅ VisionService: 原圖 OCR 成功 - 使用原圖作為結果")
                        // 返回原圖和 OCR 結果
                        let result = BusinessCardProcessResult(croppedImage: image, ocrResult: ocr)
                        completion(.success(result))
                    case .failure:
                        print("❌ VisionService: 原圖 OCR 也失敗")
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// 取得圖片方向
    private func imageOrientation(from image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
}

// MARK: - UIImage Extension (參考 Ver2)
extension UIImage {
    /// 正規化圖片方向
    func normalizeOrientation() -> UIImage? {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}

