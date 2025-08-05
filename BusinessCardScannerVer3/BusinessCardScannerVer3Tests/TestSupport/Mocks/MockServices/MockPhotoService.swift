import Foundation
import Combine
import UIKit
@testable import BusinessCardScannerVer3

/// Mock 照片服務，用於測試照片相關功能
final class MockPhotoService: PhotoServiceProtocol {
    
    // MARK: - Mock Configuration
    
    /// 是否模擬成功操作
    var shouldSucceed: Bool = true
    
    /// 模擬錯誤
    var mockError: Error = MockError.serviceUnavailable
    
    /// 操作延遲（秒）
    var operationDelay: TimeInterval = 0.1
    
    // MARK: - Mock Storage
    
    private var mockPhotos: [String: UIImage] = [:]
    private var nextPhotoID: Int = 1
    
    // MARK: - Analytics
    
    private(set) var saveCallCount: Int = 0
    private(set) var loadCallCount: Int = 0
    private(set) var deleteCallCount: Int = 0
    private(set) var thumbnailCallCount: Int = 0
    
    // MARK: - PhotoServiceProtocol Implementation
    
    func savePhoto(_ image: UIImage, for cardId: UUID) -> String? {
        saveCallCount += 1
        
        guard shouldSucceed else { return nil }
        
        let photoPath = "mock_photo_\(cardId.uuidString.prefix(8)).jpg"
        mockPhotos[photoPath] = image
        return photoPath
    }
    
    func loadPhoto(path: String) -> UIImage? {
        loadCallCount += 1
        guard shouldSucceed else { return nil }
        return mockPhotos[path] ?? MockImages.standardImage
    }
    
    func deletePhoto(path: String) -> Bool {
        deleteCallCount += 1
        guard shouldSucceed else { return false }
        mockPhotos.removeValue(forKey: path)
        return true
    }
    
    func photoExists(path: String) -> Bool {
        return mockPhotos[path] != nil
    }
    
    func loadThumbnail(path: String) -> UIImage? {
        thumbnailCallCount += 1
        guard shouldSucceed else { return nil }
        return mockPhotos[path] ?? MockImages.standardImage
    }
    
    func getPhotoFileSize(path: String) -> Int64 {
        guard photoExists(path: path) else { return 0 }
        return 1024 * 100 // Mock file size: 100KB
    }
    
    func getTotalPhotoStorageSize() -> Int64 {
        return Int64(mockPhotos.count) * 1024 * 100 // Mock total size
    }
    
    func cleanupUnusedPhotos(validCardIds: [UUID]) {
        let validPaths = Set(validCardIds.map { "mock_photo_\($0.uuidString.prefix(8)).jpg" })
        mockPhotos = mockPhotos.filter { validPaths.contains($0.key) }
    }
    
    func generateThumbnail(from image: UIImage, size: CGSize) -> UIImage? {
        thumbnailCallCount += 1
        
        guard shouldSucceed else { return nil }
        
        // 模擬縮圖生成
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Test Helpers
    
    /// 重置 Mock 狀態
    func reset() {
        shouldSucceed = true
        mockError = MockError.serviceUnavailable
        operationDelay = 0.1
        
        mockPhotos.removeAll()
        nextPhotoID = 1
        
        saveCallCount = 0
        loadCallCount = 0
        deleteCallCount = 0
        thumbnailCallCount = 0
    }
    
    /// 預先加入 Mock 照片
    func addMockPhoto(_ image: UIImage, at path: String) {
        mockPhotos[path] = image
    }
    
    /// 取得目前儲存的照片數量
    var storedPhotoCount: Int {
        return mockPhotos.count
    }
    
    /// 驗證照片是否存在
    func hasPhoto(at path: String) -> Bool {
        return mockPhotos[path] != nil
    }
}