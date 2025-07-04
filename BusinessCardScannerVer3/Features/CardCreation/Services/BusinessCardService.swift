//
//  BusinessCardService.swift
//  Coordinates OCR processing, parsing, and data storage for business cards
//
//  Created by mike liu on 2025/6/25.
//

import UIKit
import Combine

// MARK: - Business Card Processing Result

enum BusinessCardProcessingResult {
    case success(ParsedCardData, croppedImage: UIImage)  // 包含裁切後的圖片
    case ocrFailed(UIImage) // OCR failed, but user can proceed with original image
    case processingFailed(Error)
}

// MARK: - Business Card Service Protocol

protocol BusinessCardServiceProtocol {
    func processImage(_ image: UIImage) -> AnyPublisher<BusinessCardProcessingResult, Never>
    func saveBusinessCard(_ parsedData: ParsedCardData, with image: UIImage?, rawOCRText: String?) -> AnyPublisher<BusinessCard, Error>
}

// MARK: - Business Card Service Implementation

class BusinessCardService: BusinessCardServiceProtocol {
    private let repository: BusinessCardRepository
    private let photoService: PhotoService
    private let visionService: VisionService
    private let parser: BusinessCardParser
    
    init(repository: BusinessCardRepository,
         photoService: PhotoService,
         visionService: VisionService,
         parser: BusinessCardParser) {
        self.repository = repository
        self.photoService = photoService
        self.visionService = visionService
        self.parser = parser
    }
    
    // MARK: - Image Processing Pipeline
    
    /// Process business card image through OCR and parsing pipeline
    /// - Parameter image: Business card image to process
    /// - Returns: Publisher with processing result
    func processImage(_ image: UIImage) -> AnyPublisher<BusinessCardProcessingResult, Never> {
        print("📱 BusinessCardService: 開始處理圖片...")
        
        return Future<BusinessCardProcessingResult, Never> { [weak self] promise in
            guard let self = self else {
                promise(.success(BusinessCardProcessingResult.processingFailed(BusinessCardError.serviceUnavailable)))
                return
            }
            
            // 使用新的 VisionService 方法進行名片偵測、裁切和 OCR
            self.visionService.processBusinessCard(image: image) { result in
                switch result {
                case .success(let businessCardResult):
                    print("✅ 名片處理完成，使用裁切後的圖片進行解析")
                    
                    // 使用 OCRProcessor 進行完整的欄位提取處理（用裁切後的圖片）
                    let ocrProcessor = OCRProcessor(visionService: self.visionService)
                    
                    // 使用裁切後的圖片進行 OCR 處理
                    ocrProcessor.processImage(businessCardResult.croppedImage) { ocrResult in
                        switch ocrResult {
                        case .success(let ocrProcessingResult):
                            print("✅ OCR 處理完成，提取欄位: \(ocrProcessingResult.extractedFields.keys.joined(separator: ", "))")
                            print("🔍 BusinessCardService: OCR 提取的欄位詳情:")
                            for (key, value) in ocrProcessingResult.extractedFields {
                                print("   \(key): \(value)")
                            }
                            
                            let parsedData = self.parser.parse(ocrResult: ocrProcessingResult)
                            promise(.success(BusinessCardProcessingResult.success(parsedData, croppedImage: businessCardResult.croppedImage)))
                            
                        case .failure(let error):
                            print("❌ OCR 處理失敗: \(error.localizedDescription)")
                            promise(.success(BusinessCardProcessingResult.processingFailed(error)))
                        }
                    }
                    
                case .failure(_):
                    print("❌ 名片偵測失敗，嘗試使用原圖進行 OCR")
                    // 如果名片偵測失敗，回到原本的流程使用原圖
                    let ocrProcessor = OCRProcessor(visionService: self.visionService)
                    ocrProcessor.processImage(image) { ocrResult in
                        switch ocrResult {
                        case .success(let ocrProcessingResult):
                            let parsedData = self.parser.parse(ocrResult: ocrProcessingResult)
                            promise(.success(BusinessCardProcessingResult.success(parsedData, croppedImage: image)))
                        case .failure(let ocrError):
                            promise(.success(BusinessCardProcessingResult.processingFailed(ocrError)))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Business Card Storage
    
    /// Save business card data and associated image
    /// - Parameters:
    ///   - parsedData: Parsed business card data
    ///   - image: Optional business card image
    ///   - rawOCRText: Raw OCR text
    /// - Returns: Publisher with saved business card
    func saveBusinessCard(_ parsedData: ParsedCardData, with image: UIImage?, rawOCRText: String?) -> AnyPublisher<BusinessCard, Error> {
        print("💾 BusinessCardService: 開始儲存名片...")
        
        return Future<BusinessCard, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(BusinessCardError.serviceUnavailable))
                return
            }
            
            // Create business card
            let cardId = UUID()
            
            // Save photo if provided
            var photoPath: String?
            if let image = image {
                photoPath = self.photoService.savePhoto(image, for: cardId)
                if photoPath != nil {
                    print("✅ 照片儲存成功")
                } else {
                    print("⚠️ 照片儲存失敗")
                }
            }
            
            // Create domain model
            let businessCard = BusinessCard(
                id: cardId,
                name: parsedData.name ?? "",
                jobTitle: parsedData.jobTitle,
                company: parsedData.company,
                email: parsedData.email,
                phone: parsedData.phone,
                address: parsedData.address,
                website: parsedData.website,
                photoPath: photoPath,
                createdAt: Date(),
                updatedAt: Date(),
                parseSource: "local",
                parseConfidence: parsedData.confidence,
                rawOCRText: rawOCRText
            )
            
            // Save to repository
            self.repository.create(businessCard)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                            
                        case .failure(let error):
                            print("❌ 名片儲存失敗: \(error.localizedDescription)")
                            
                            // Cleanup photo if card save failed
                            if let photoPath = photoPath {
                                _ = self.photoService.deletePhoto(path: photoPath)
                            }
                            
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { savedCard in
                        print("✅ 名片儲存成功: \(savedCard.name)")
                        promise(.success(savedCard))
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Business Card Error Types

enum BusinessCardError: LocalizedError {
    case serviceUnavailable
    case imageProcessingFailed
    case ocrNotAvailable
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "服務暫時無法使用"
        case .imageProcessingFailed:
            return "圖片處理失敗"
        case .ocrNotAvailable:
            return "文字識別功能不可用"
        case .saveFailed:
            return "儲存失敗"
        }
    }
}
