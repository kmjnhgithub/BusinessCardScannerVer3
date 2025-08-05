import Foundation
import Combine
import UIKit
@testable import BusinessCardScannerVer3

/// Mock Vision OCR 服務，用於測試 OCR 功能
final class MockVisionService: VisionServiceProtocol {
    
    // MARK: - Mock Configuration
    
    /// 是否模擬成功識別
    var shouldSucceed: Bool = true
    
    /// Mock 識別文字
    var mockRecognizedText: String = """
    王大明
    ABC科技公司
    產品經理
    電話：02-1234-5678
    手機：0912-345-678
    信箱：wang@abc.com
    地址：台北市信義區信義路五段7號
    """
    
    /// Mock 信心度
    var mockConfidence: Double = 0.85
    
    /// Mock 邊界框
    var mockBoundingBoxes: [CGRect] = [
        CGRect(x: 10, y: 10, width: 100, height: 20),
        CGRect(x: 10, y: 35, width: 120, height: 20),
        CGRect(x: 10, y: 60, width: 80, height: 20)
    ]
    
    /// 處理延遲（秒）
    var processingDelay: TimeInterval = 0.2
    
    /// 模擬錯誤
    var mockError: VisionError = .processingFailed
    
    // MARK: - Test Scenarios
    
    /// 多語言測試場景
    var languageScenarios: [String: String] = [
        "chinese": """
        王大明
        ABC科技公司
        產品經理
        電話：02-1234-5678
        """,
        "english": """
        John Smith
        ABC Technology Inc.
        Product Manager
        Phone: +1-555-0123
        """,
        "mixed": """
        王大明 John Wang
        ABC科技 Technology Inc.
        產品經理 Product Manager
        電話: +886-2-1234-5678
        """
    ]
    
    /// 品質測試場景
    var qualityScenarios: [String: (text: String, confidence: Double)] = [
        "high": ("清晰的名片文字內容", 0.95),
        "medium": ("稍微模糊的文字", 0.75),
        "low": ("很模糊 ???", 0.35),
        "poor": ("無法識別", 0.15)
    ]
    
    // MARK: - Analytics
    
    private(set) var recognizeCallCount: Int = 0
    private(set) var lastProcessedImage: UIImage?
    private(set) var processingTimes: [TimeInterval] = []
    
    // MARK: - VisionServiceProtocol Implementation
    
    func recognizeText(from image: UIImage) -> AnyPublisher<OCRResult, Error> {
        recognizeCallCount += 1
        lastProcessedImage = image
        
        let startTime = Date()
        
        return Future<OCRResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(VisionError.processingFailed))
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + self.processingDelay) {
                let processingTime = Date().timeIntervalSince(startTime)
                self.processingTimes.append(processingTime)
                
                if self.shouldSucceed {
                    let result = OCRResult(
                        recognizedText: self.mockRecognizedText,
                        confidence: Float(self.mockConfidence),
                        boundingBoxes: self.mockBoundingBoxes.map { rect in 
                            TextBoundingBox(
                                text: "Mock Text",
                                confidence: Float(self.mockConfidence),
                                boundingBox: rect,
                                topCandidates: ["Mock Text"]
                            )
                        },
                        processingTime: processingTime
                    )
                    promise(.success(result))
                } else {
                    promise(.failure(self.mockError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func recognizeText(from image: UIImage, completion: @escaping (Result<OCRResult, VisionError>) -> Void) {
        recognizeText(from: image)
            .sink(
                receiveCompletion: { completionResult in
                    switch completionResult {
                    case .finished:
                        break
                    case .failure(let error):
                        if let visionError = error as? VisionError {
                            completion(.failure(visionError))
                        } else {
                            completion(.failure(.processingFailed))
                        }
                    }
                },
                receiveValue: { result in
                    completion(.success(result))
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Test Helpers
    
    /// 重置 Mock 狀態
    func reset() {
        shouldSucceed = true
        mockRecognizedText = """
        王大明
        ABC科技公司
        產品經理
        電話：02-1234-5678
        手機：0912-345-678
        信箱：wang@abc.com
        地址：台北市信義區信義路五段7號
        """
        mockConfidence = 0.85
        processingDelay = 0.2
        mockError = .processingFailed
        
        // 重置分析數據
        recognizeCallCount = 0
        lastProcessedImage = nil
        processingTimes.removeAll()
        
        cancellables.removeAll()
    }
    
    /// 設定語言測試場景
    func setLanguageScenario(_ language: String) {
        if let scenarioText = languageScenarios[language] {
            mockRecognizedText = scenarioText
            
            // 根據語言調整信心度
            switch language {
            case "chinese":
                mockConfidence = 0.88
            case "english":
                mockConfidence = 0.92
            case "mixed":
                mockConfidence = 0.82
            default:
                mockConfidence = 0.85
            }
        }
    }
    
    /// 設定品質測試場景
    func setQualityScenario(_ quality: String) {
        if let scenario = qualityScenarios[quality] {
            mockRecognizedText = scenario.text
            mockConfidence = scenario.confidence
            
            // 調整處理時間（品質越差，處理越久）
            switch quality {
            case "high":
                processingDelay = 0.1
            case "medium":
                processingDelay = 0.2
            case "low":
                processingDelay = 0.4
            case "poor":
                processingDelay = 0.6
            default:
                processingDelay = 0.2
            }
        }
    }
    
    /// 設定無文字場景
    func setNoTextScenario() {
        shouldSucceed = false
        mockError = .noTextFound
    }
    
    /// 設定複雜版面場景
    func setComplexLayoutScenario() {
        mockRecognizedText = """
        王大明          ABC科技公司
        產品經理               TEL 02-1234-5678
                              MOBILE 0912-345-678
        wang@abc.com          台北市信義區
                              信義路五段7號
        """
        mockBoundingBoxes = [
            CGRect(x: 10, y: 10, width: 60, height: 15),   // 姓名
            CGRect(x: 80, y: 10, width: 90, height: 15),   // 公司
            CGRect(x: 10, y: 30, width: 70, height: 15),   // 職位
            CGRect(x: 90, y: 30, width: 100, height: 15),  // 電話
            CGRect(x: 90, y: 50, width: 110, height: 15),  // 手機
            CGRect(x: 10, y: 70, width: 100, height: 15),  // Email
            CGRect(x: 90, y: 70, width: 80, height: 15),   // 地址1
            CGRect(x: 90, y: 90, width: 90, height: 15)    // 地址2
        ]
        mockConfidence = 0.78
    }
    
    /// 設定效能測試場景
    func setPerformanceScenario(imageCount: Int, averageDelay: TimeInterval) {
        processingDelay = averageDelay
        
        // 清除之前的記錄
        processingTimes.removeAll()
        recognizeCallCount = 0
        
        // 預先計算預期的處理時間分佈
        let baseDelay = averageDelay
        let variance = baseDelay * 0.2
        
        // 模擬不同大小圖片的處理時間差異
        print("🎯 效能測試場景已設定：預期處理 \(imageCount) 張圖片，平均延遲 \(averageDelay)s")
    }
    
    // MARK: - Test Verification
    
    /// 驗證 OCR 呼叫次數
    func verifyRecognizeCalled(times expectedTimes: Int) -> Bool {
        return recognizeCallCount == expectedTimes
    }
    
    /// 驗證處理時間是否在預期範圍內
    func verifyProcessingTime(within expectedRange: ClosedRange<TimeInterval>) -> Bool {
        guard let lastTime = processingTimes.last else { return false }
        return expectedRange.contains(lastTime)
    }
    
    /// 驗證平均處理時間
    func averageProcessingTime() -> TimeInterval {
        guard !processingTimes.isEmpty else { return 0.0 }
        return processingTimes.reduce(0, +) / Double(processingTimes.count)
    }
    
    /// 驗證最後處理的圖片尺寸
    func verifyLastImageSize() -> CGSize? {
        return lastProcessedImage?.size
    }
    
    /// 取得信心度統計
    func getConfidenceStats() -> (min: Double, max: Double, average: Double) {
        // 在真實測試中，這裡會記錄多次識別的信心度
        return (min: mockConfidence, max: mockConfidence, average: mockConfidence)
    }
    
    // MARK: - Debug Helpers
    
    /// 印出測試統計資訊
    func printTestStats() {
        print("📊 MockVisionService 測試統計：")
        print("   呼叫次數: \(recognizeCallCount)")
        print("   平均處理時間: \(String(format: "%.3f", averageProcessingTime()))s")
        print("   當前信心度: \(mockConfidence)")
        print("   是否成功: \(shouldSucceed)")
        if let imageSize = lastProcessedImage?.size {
            print("   最後圖片尺寸: \(imageSize)")
        }
    }
}