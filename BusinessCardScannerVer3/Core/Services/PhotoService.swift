//
//  PhotoService.swift
//  PhotoService for business card image storage and management
//
//  Created by mike liu on 2025/6/25.
//

import UIKit
import Foundation

protocol PhotoServiceProtocol {
    func savePhoto(_ image: UIImage, for cardId: UUID) -> String?
    func loadPhoto(path: String) -> UIImage?
    func deletePhoto(path: String) -> Bool
    func photoExists(path: String) -> Bool
    func generateThumbnail(from image: UIImage, size: CGSize) -> UIImage?
    func loadThumbnail(path: String) -> UIImage?
    func getPhotoFileSize(path: String) -> Int64
    func getTotalPhotoStorageSize() -> Int64
    func cleanupUnusedPhotos(validCardIds: [UUID])
}

class PhotoService: PhotoServiceProtocol {
    
    // MARK: - Constants
    private struct Constants {
        static let photosDirectory = "BusinessCards/Photos"
        static let thumbnailPrefix = "thumbnail_"
        static let photoPrefix = "photo_"
        static let jpegCompressionQuality: CGFloat = 0.8
        static let maxImageSize: CGFloat = 1024
        // 🎯 使用名片比例的縮圖尺寸（黃金比例 1:0.618）
        // 寬度 168pt，高度按黃金比例計算：168 * 0.618 ≈ 104pt
        static let thumbnailSize = CGSize(width: 168, height: 104) // @3x for optimal business card ratio
    }
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let imageCache = NSCache<NSString, UIImage>()
    
    // MARK: - Initialization
    init() {
        setupImageCache()
        createPhotosDirectoryIfNeeded()
    }
    
    // MARK: - PhotoServiceProtocol Implementation
    
    func savePhoto(_ image: UIImage, for cardId: UUID) -> String? {
        guard let optimizedImage = optimizeImage(image),
              let imageData = optimizedImage.jpegData(compressionQuality: Constants.jpegCompressionQuality) else {
            print("[PhotoService] Failed to process image for cardId: \(cardId)")
            return nil
        }
        
        let filename = "\(Constants.photoPrefix)\(cardId.uuidString).jpg"
        let photoPath = getPhotoPath(filename: filename)
        
        do {
            try imageData.write(to: URL(fileURLWithPath: photoPath))
            
            // Generate and save thumbnail
            if let thumbnail = generateThumbnail(from: optimizedImage, size: Constants.thumbnailSize) {
                saveThumbnail(thumbnail, for: cardId)
            }
            
            // Cache the image
            imageCache.setObject(optimizedImage, forKey: filename as NSString)
            
            print("[PhotoService] Successfully saved photo: \(filename)")
            return filename
            
        } catch {
            print("[PhotoService] Failed to save photo: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadPhoto(path: String) -> UIImage? {
        // Check cache first
        if let cachedImage = imageCache.object(forKey: path as NSString) {
            return cachedImage
        }
        
        let fullPath = getPhotoPath(filename: path)
        guard fileManager.fileExists(atPath: fullPath),
              let image = UIImage(contentsOfFile: fullPath) else {
            print("[PhotoService] Photo not found at path: \(path)")
            return nil
        }
        
        // Cache the loaded image
        imageCache.setObject(image, forKey: path as NSString)
        return image
    }
    
    func deletePhoto(path: String) -> Bool {
        let fullPath = getPhotoPath(filename: path)
        
        do {
            if fileManager.fileExists(atPath: fullPath) {
                try fileManager.removeItem(atPath: fullPath)
            }
            
            // Delete thumbnail if exists
            let cardId = extractCardId(from: path)
            if let cardId = cardId {
                deleteThumbnail(for: cardId)
            }
            
            // Remove from cache
            imageCache.removeObject(forKey: path as NSString)
            
            print("[PhotoService] Successfully deleted photo: \(path)")
            return true
            
        } catch {
            print("[PhotoService] Failed to delete photo: \(error.localizedDescription)")
            return false
        }
    }
    
    func photoExists(path: String) -> Bool {
        let fullPath = getPhotoPath(filename: path)
        return fileManager.fileExists(atPath: fullPath)
    }
    
    func generateThumbnail(from image: UIImage, size: CGSize) -> UIImage? {
        // 🎯 保持原始比例的智慧縮圖生成
        // 計算適配到目標尺寸的比例，確保圖片不被拉伸
        let imageSize = image.size
        let targetSize = size
        
        // 計算縮放比例（取較小值確保圖片完全適配到容器內）
        let scaleX = targetSize.width / imageSize.width
        let scaleY = targetSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        
        // 計算縮放後的實際尺寸（保持比例）
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        // 計算居中位置
        let x = (targetSize.width - scaledWidth) / 2
        let y = (targetSize.height - scaledHeight) / 2
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            // 填充背景色（可選，保持透明）
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            // 在正確位置和尺寸繪製圖片，保持比例
            image.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
        }
    }
    
    func loadThumbnail(path: String) -> UIImage? {
        guard let cardId = extractCardId(from: path) else { return nil }
        
        let thumbnailFilename = "\(Constants.thumbnailPrefix)\(cardId.uuidString).jpg"
        let thumbnailPath = getPhotoPath(filename: thumbnailFilename)
        
        // Check cache first
        if let cachedThumbnail = imageCache.object(forKey: thumbnailFilename as NSString) {
            return cachedThumbnail
        }
        
        guard fileManager.fileExists(atPath: thumbnailPath),
              let thumbnail = UIImage(contentsOfFile: thumbnailPath) else {
            // Generate thumbnail from original if it doesn't exist
            if let originalImage = loadPhoto(path: path) {
                return generateThumbnail(from: originalImage, size: Constants.thumbnailSize)
            }
            return nil
        }
        
        // Cache the thumbnail
        imageCache.setObject(thumbnail, forKey: thumbnailFilename as NSString)
        return thumbnail
    }
    
    func getPhotoFileSize(path: String) -> Int64 {
        let fullPath = getPhotoPath(filename: path)
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fullPath)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            print("[PhotoService] Failed to get file size for \(path): \(error.localizedDescription)")
            return 0
        }
    }
    
    func getTotalPhotoStorageSize() -> Int64 {
        let photosDirectory = getPhotosDirectory()
        guard let enumerator = fileManager.enumerator(atPath: photosDirectory) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let filename as String in enumerator {
            let filePath = photosDirectory + "/" + filename
            do {
                let attributes = try fileManager.attributesOfItem(atPath: filePath)
                totalSize += attributes[.size] as? Int64 ?? 0
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    func cleanupUnusedPhotos(validCardIds: [UUID]) {
        let photosDirectory = getPhotosDirectory()
        guard let files = try? fileManager.contentsOfDirectory(atPath: photosDirectory) else {
            return
        }
        
        let validCardIdStrings = Set(validCardIds.map { $0.uuidString })
        
        for filename in files {
            if let cardId = extractCardId(from: filename),
               !validCardIdStrings.contains(cardId.uuidString) {
                
                let filePath = photosDirectory + "/" + filename
                do {
                    try fileManager.removeItem(atPath: filePath)
                    print("[PhotoService] Cleaned up unused photo: \(filename)")
                } catch {
                    print("[PhotoService] Failed to cleanup photo \(filename): \(error.localizedDescription)")
                }
            }
        }
        
        // Clear cache for deleted items
        imageCache.removeAllObjects()
    }
}

// MARK: - Private Methods
private extension PhotoService {
    
    func setupImageCache() {
        imageCache.countLimit = 50 // Limit cache to 50 images
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
    }
    
    func createPhotosDirectoryIfNeeded() {
        let photosDirectory = getPhotosDirectory()
        if !fileManager.fileExists(atPath: photosDirectory) {
            do {
                try fileManager.createDirectory(atPath: photosDirectory, 
                                              withIntermediateDirectories: true, 
                                              attributes: nil)
                print("[PhotoService] Created photos directory: \(photosDirectory)")
            } catch {
                print("[PhotoService] Failed to create photos directory: \(error.localizedDescription)")
            }
        }
    }
    
    func getPhotosDirectory() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return documentsPath + "/" + Constants.photosDirectory
    }
    
    func getPhotoPath(filename: String) -> String {
        return getPhotosDirectory() + "/" + filename
    }
    
    func optimizeImage(_ image: UIImage) -> UIImage? {
        let maxSize = Constants.maxImageSize
        let size = image.size
        
        // Calculate new size if image is too large
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func saveThumbnail(_ thumbnail: UIImage, for cardId: UUID) {
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: Constants.jpegCompressionQuality) else {
            return
        }
        
        let filename = "\(Constants.thumbnailPrefix)\(cardId.uuidString).jpg"
        let thumbnailPath = getPhotoPath(filename: filename)
        
        do {
            try thumbnailData.write(to: URL(fileURLWithPath: thumbnailPath))
            imageCache.setObject(thumbnail, forKey: filename as NSString)
        } catch {
            print("[PhotoService] Failed to save thumbnail: \(error.localizedDescription)")
        }
    }
    
    func deleteThumbnail(for cardId: UUID) {
        let filename = "\(Constants.thumbnailPrefix)\(cardId.uuidString).jpg"
        let thumbnailPath = getPhotoPath(filename: filename)
        
        do {
            if fileManager.fileExists(atPath: thumbnailPath) {
                try fileManager.removeItem(atPath: thumbnailPath)
            }
            imageCache.removeObject(forKey: filename as NSString)
        } catch {
            print("[PhotoService] Failed to delete thumbnail: \(error.localizedDescription)")
        }
    }
    
    func extractCardId(from path: String) -> UUID? {
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let uuidString: String
        
        if filename.hasPrefix(Constants.photoPrefix) {
            uuidString = String(filename.dropFirst(Constants.photoPrefix.count).dropLast(4)) // Remove .jpg
        } else if filename.hasPrefix(Constants.thumbnailPrefix) {
            uuidString = String(filename.dropFirst(Constants.thumbnailPrefix.count).dropLast(4)) // Remove .jpg
        } else {
            return nil
        }
        
        return UUID(uuidString: uuidString)
    }
}
