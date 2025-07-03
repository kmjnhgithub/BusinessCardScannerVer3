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
    case success(ParsedCardData)
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
        
        // 使用 OCRProcessor 進行完整的欄位提取處理
        let ocrProcessor = OCRProcessor(visionService: visionService)
        
        return ocrProcessor.processImage(image)
            .map { [weak self] (ocrProcessingResult: OCRProcessingResult) -> BusinessCardProcessingResult in
                guard let self = self else {
                    return BusinessCardProcessingResult.processingFailed(BusinessCardError.serviceUnavailable)
                }
                
                print("✅ OCR 處理完成，提取欄位: \(ocrProcessingResult.extractedFields.keys.joined(separator: ", "))")
                print("🔍 BusinessCardService: OCR 提取的欄位詳情:")
                for (key, value) in ocrProcessingResult.extractedFields {
                    print("   \(key): \(value)")
                }
                
                let parsedData = self.parser.parse(ocrResult: ocrProcessingResult)
                return BusinessCardProcessingResult.success(parsedData)
            }
            .catch { error in
                print("❌ OCR 處理失敗: \(error.localizedDescription)")
                return Just(BusinessCardProcessingResult.processingFailed(error))
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
