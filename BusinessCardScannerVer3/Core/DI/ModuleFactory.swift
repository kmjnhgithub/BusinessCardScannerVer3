//
//  ModuleFactory.swift
//  
//
//  模組工廠：建立各功能模組
//  位置：Core/DI/ModuleFactory.swift
//

import UIKit

/// 模組工廠
final class ModuleFactory {
    
    // MARK: - Properties
    
    /// 服務容器參考
    private let serviceContainer: ServiceContainer
    
    // MARK: - Initialization
    
    init(serviceContainer: ServiceContainer = .shared) {
        self.serviceContainer = serviceContainer
    }
    
    // MARK: - TabBar Module
    
    /// 建立 TabBar 模組
    func makeTabBarModule() -> TabBarModulable {
        return TabBarModule(
            cardListModule: makeCardListModule(),
            cardCreationModule: makeCardCreationModule(),
            settingsModule: makeSettingsModule()
        )
    }
    
    // MARK: - Card List Module
    
    /// 建立名片列表模組
    func makeCardListModule() -> CardListModulable {
        return CardListModule(
            repository: serviceContainer.businessCardRepository,
            photoService: serviceContainer.photoService,
            moduleFactory: self
        )
    }
    
    // MARK: - Card Creation Module
    
    /// 建立名片建立模組
    func makeCardCreationModule() -> CardCreationModulable {
        return CardCreationModule(
            repository: serviceContainer.businessCardRepository,
            photoService: serviceContainer.photoService,
            visionService: serviceContainer.visionService,
            businessCardService: serviceContainer.businessCardService,
            permissionManager: serviceContainer.permissionManager,
            aiProcessingModule: makeAIProcessingModule()
        )
    }
    
    // MARK: - Card Detail Module
    
    /// 建立名片詳情模組
    func makeCardDetailModule() -> CardDetailModulable {
        return CardDetailModule(
            repository: serviceContainer.businessCardRepository,
            photoService: serviceContainer.photoService,
            exportService: serviceContainer.exportService,
            cardCreationModule: makeCardCreationModule()
        )
    }
    
    // MARK: - AI Processing Module
    
    /// 建立 AI 處理模組（可選）
    func makeAIProcessingModule() -> AIProcessingModulable? {
        // 檢查 AI 服務是否可用
        let aiCardParser = serviceContainer.aiCardParser
        guard aiCardParser.isAvailable else { return nil }
        
        return AIProcessingModule(
            openAIService: serviceContainer.openAIService,
            aiCardParser: aiCardParser,
            keychainService: serviceContainer.keychainService
        )
    }
    
    // MARK: - Settings Module
    
    /// 建立設定模組
    func makeSettingsModule() -> SettingsModulable {
        return SettingsModule(
            repository: serviceContainer.businessCardRepository,
            photoService: serviceContainer.photoService,
            exportService: serviceContainer.exportService,
            aiProcessingModule: makeAIProcessingModule()
        )
    }
    
    // MARK: - Component Showcase Module
    
    /// 建立 ComponentShowcase 模組
    func makeComponentShowcaseModule() -> ComponentShowcaseModulable {
        let dependencies = ComponentShowcaseDependenciesImpl()
        return ComponentShowcaseModule(dependencies: dependencies)
    }
}

// MARK: - Temporary Module Implementations
// 這些是暫時的實作，實際的模組會在各自的 Feature 資料夾中實作

private struct TabBarModule: TabBarModulable {
    let cardListModule: CardListModulable
    let cardCreationModule: CardCreationModulable
    let settingsModule: SettingsModulable
    
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator {
        // 實際實作會在 Features/TabBar/TabBarCoordinator.swift
        return PlaceholderCoordinator(navigationController: navigationController)
    }
}

private struct CardListModule: CardListModulable {
    let repository: BusinessCardRepository
    let photoService: PhotoService
    let moduleFactory: ModuleFactory
    
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator {
        // 實際實作會在 Features/CardList/CardListCoordinator.swift
        return PlaceholderCoordinator(navigationController: navigationController)
    }
}

private struct CardCreationModule: CardCreationModulable {
    let repository: BusinessCardRepository
    let photoService: PhotoService
    let visionService: VisionService
    let businessCardService: BusinessCardService
    let permissionManager: PermissionManager
    let aiProcessingModule: AIProcessingModulable?
    
    func makeCoordinator(navigationController: UINavigationController, sourceType: CardCreationSourceType, editingCard: BusinessCard?) -> Coordinator {
        // 實際實作會在 Features/CardCreation/CardCreationCoordinator.swift
        return PlaceholderCoordinator(navigationController: navigationController)
    }
}

private struct CardDetailModule: CardDetailModulable {
    let repository: BusinessCardRepository
    let photoService: PhotoService
    let exportService: ExportService
    let cardCreationModule: CardCreationModulable
    
    func makeCoordinator(navigationController: UINavigationController, card: BusinessCard) -> Coordinator {
        // 實際實作會在 Features/CardDetail/CardDetailCoordinator.swift
        return PlaceholderCoordinator(navigationController: navigationController)
    }
}

private struct AIProcessingModule: AIProcessingModulable {
    let openAIService: OpenAIService
    let aiCardParser: AICardParser
    let keychainService: KeychainService
    
    var isAvailable: Bool {
        aiCardParser.isAvailable
    }
    
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator {
        // 實際實作會在 Features/AIProcessing/AIProcessingCoordinator.swift
        return PlaceholderCoordinator(navigationController: navigationController)
    }
}

private struct SettingsModule: SettingsModulable {
    let repository: BusinessCardRepository
    let photoService: PhotoService
    let exportService: ExportService
    let aiProcessingModule: AIProcessingModulable?
    
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator {
        // 實際實作會在 Features/Settings/SettingsCoordinator.swift
        return PlaceholderCoordinator(navigationController: navigationController)
    }
}

// MARK: - Placeholder Coordinator

private class PlaceholderCoordinator: BaseCoordinator {
    override func start() {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        viewController.title = "Placeholder"
        push(viewController)
    }
}
