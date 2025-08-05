import Foundation
import Combine
import UIKit
import AVFoundation
@testable import BusinessCardScannerVer3

// MARK: - Repository Protocols

/// 名片資料存取協議
protocol BusinessCardRepositoryProtocol {
    func fetchAllCards() -> AnyPublisher<[BusinessCard], Error>
    func fetchCard(byID id: UUID) -> AnyPublisher<BusinessCard?, Error>
    func createCard(_ card: BusinessCard) -> AnyPublisher<BusinessCard, Error>
    func updateCard(_ card: BusinessCard) -> AnyPublisher<BusinessCard, Error>
    func deleteCard(_ card: BusinessCard) -> AnyPublisher<Void, Error>
    func deleteCard(byID id: UUID) -> AnyPublisher<Void, Error>
}

// MARK: - Core Service Protocols

// Note: PhotoServiceProtocol 直接使用主專案中的定義，避免重複定義

/// Vision OCR 服務協議
protocol VisionServiceProtocol {
    func recognizeText(from image: UIImage) -> AnyPublisher<OCRResult, Error>
    func recognizeText(from image: UIImage, completion: @escaping (Result<OCRResult, VisionError>) -> Void)
}

/// 權限管理協議
protocol PermissionManagerProtocol {
    func requestCameraPermission() -> AnyPublisher<AVAuthorizationStatus, Never>
    func requestPhotoLibraryPermission() -> AnyPublisher<Bool, Never>
    func checkCameraPermission() -> AVAuthorizationStatus
    func checkPhotoLibraryPermission() -> Bool
}

/// Keychain 服務協議
protocol KeychainServiceProtocol {
    func saveAPIKey(_ apiKey: String) -> Bool
    func getAPIKey() -> String?
    func deleteAPIKey() -> Bool
    func saveSecureData(_ data: Data, for key: String) -> Bool
    func getSecureData(for key: String) -> Data?
    func deleteSecureData(for key: String) -> Bool
}

/// 資料驗證服務協議
protocol ValidationServiceProtocol {
    func validateEmail(_ email: String) -> Bool
    func validatePhone(_ phone: String) -> Bool
    func validateWebsite(_ website: String) -> Bool
    func validateRequiredField(_ text: String) -> Bool
    func validateName(_ name: String) -> Bool
}

// MARK: - Feature Service Protocols

/// OpenAI 服務協議
protocol OpenAIServiceProtocol {
    func processCard(ocrText: String, imageData: Data?) -> AnyPublisher<AIResponse, Error>
    func hasValidAPIKey() -> Bool
    var tokenUsage: TokenUsage { get }
}

// MARK: - AI Processing Protocols

/// AI 名片解析協議
protocol AICardParserProtocol {
    var isAvailable: Bool { get }
    func parseCard(request: AIProcessingRequest) -> AnyPublisher<ParsedCardData, Error>
}

/// 匯出服務協議
protocol ExportServiceProtocol {
    func exportAsCSV(cards: [BusinessCard]) -> AnyPublisher<URL, Error>
    func exportAsVCard(cards: [BusinessCard]) -> AnyPublisher<URL, Error>
}

// MARK: - Protocol Notes
// BusinessCardParserProtocol, BusinessCardServiceProtocol
// 這些協議已在主專案中定義，測試中直接使用主專案的協議定義，避免重複宣告錯誤

// MARK: - Supporting Types
// Note: OCRResult, TextBoundingBox, VisionError 等類型直接使用主專案中的定義，避免重複定義

/// Mock 測試錯誤類型 - 統一的測試錯誤定義
enum MockError: Error, LocalizedError {
    case serviceUnavailable
    case networkError
    case networkUnavailable
    case dataCorrupted
    case invalidInput
    case operationFailed
    case timeout
    case quotaExceeded
    case invalidAPIKey
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Mock service unavailable"
        case .networkError:
            return "Mock network error"
        case .networkUnavailable:
            return "Mock network unavailable"
        case .dataCorrupted:
            return "Mock data corrupted"
        case .invalidInput:
            return "Mock invalid input"
        case .operationFailed:
            return "Mock operation failed"
        case .timeout:
            return "Mock timeout"
        case .quotaExceeded:
            return "Mock quota exceeded"
        case .invalidAPIKey:
            return "Mock invalid API key"
        }
    }
}

/// 圖片來源類型
enum ImageSourceType {
    case camera
    case photoLibrary
    case manual
}

/// 儲存資訊
struct StorageInfo {
    let totalSize: Int64
    let imageSize: Int64
    let databaseSize: Int64
    let cardCount: Int
}

// MARK: - Protocol Extensions

extension BusinessCardRepositoryProtocol {
    /// 便利方法：計算名片總數
    func cardCount() -> AnyPublisher<Int, Error> {
        fetchAllCards()
            .map { $0.count }
            .eraseToAnyPublisher()
    }
}

extension VisionServiceProtocol {
    /// 便利方法：批次處理多張圖片
    func recognizeText(from images: [UIImage]) -> AnyPublisher<[OCRResult], Error> {
        let publishers = images.map { recognizeText(from: $0) }
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
}

extension ValidationServiceProtocol {
    /// 便利方法：驗證聯絡資訊
    func validateContactInfo(_ contact: ContactInfo) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // 移除 contact.name 驗證，因為 ContactInfo 沒有 name 屬性
        // ContactInfo 主要包含聯絡方式資訊，姓名驗證應在其他層級處理
        
        if let email = contact.email, !email.isEmpty && !validateEmail(email) {
            errors.append(.invalidFormat("Email 格式不正確"))
        }
        
        if let phone = contact.phone, !phone.isEmpty && !validatePhone(phone) {
            errors.append(.invalidFormat("電話號碼格式不正確"))
        }
        
        if let website = contact.website, !website.isEmpty && !validateWebsite(website) {
            errors.append(.invalidFormat("網站格式不正確"))
        }
        
        return errors
    }
}

// Note: ValidationError 直接使用主專案中的定義，避免重複定義