//
//  ServiceContainer.swift
//  
//
//  服務容器：管理所有服務實例
//  位置：Core/DI/ServiceContainer.swift
//

import Foundation
import UIKit
import CoreData

/// 服務容器，管理所有服務的單例實例
final class ServiceContainer {
    
    // MARK: - Singleton
    
    static let shared = ServiceContainer()
    
    // MARK: - Core Data
    
    private(set) lazy var coreDataStack: CoreDataStack = {
        return CoreDataStack()
    }()
    
    // MARK: - Repositories
    
    private(set) lazy var businessCardRepository: BusinessCardRepository = {
        return BusinessCardRepository(coreDataStack: coreDataStack)
    }()
    
    // MARK: - Services
    
    private(set) lazy var photoService: PhotoService = {
        return PhotoService()
    }()
    
    private(set) lazy var visionService: VisionService = {
        return VisionService.shared
    }()
    
    private(set) lazy var permissionManager: PermissionManager = {
        return PermissionManager.shared
    }()
    
    private(set) lazy var keychainService: KeychainService = {
        return KeychainService()
    }()
    
    // MARK: - Feature Services
    
    /// CardCreation 模組的服務
    private(set) lazy var businessCardService: BusinessCardService = {
        return BusinessCardService(
            repository: businessCardRepository,
            photoService: photoService,
            visionService: visionService,
            parser: businessCardParser,
            aiCardParser: aiCardParser
        )
    }()
    
    private(set) lazy var businessCardParser: BusinessCardParser = {
        return BusinessCardParser()
    }()
    
    /// Settings 模組的服務
    private(set) lazy var exportService: ExportService = {
        return ExportService()
    }()
    
    /// AIProcessing 模組的服務
    private(set) lazy var openAIService: OpenAIService = {
        return OpenAIService(keychainService: keychainService)
    }()
    
    private(set) lazy var aiCardParser: AICardParser = {
        return AICardParser(openAIService: openAIService)
    }()
    
    // MARK: - Initialization
    
    private init() {
        setupServices()
    }
    
    // MARK: - Setup
    
    private func setupServices() {
        // 初始化設定，例如設定 Vision 語言
        #if DEBUG
        print("✅ ServiceContainer initialized")
        #endif
    }
    
    // MARK: - Reset (for testing)
    
    /// 重置所有服務（主要用於測試）
    func resetAllServices() {
        // 用於測試環境重置服務狀態
        #if DEBUG
        print("♻️ ServiceContainer reset")
        #endif
    }
}
