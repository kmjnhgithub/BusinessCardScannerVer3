//
//  ModuleFactory.swift
//  BusinessCardScanner
//
//  模組工廠，建立各功能模組
//

import UIKit

/// 模組工廠
final class ModuleFactory {
    
    // MARK: - Properties
    
    private let container: ServiceContainer
    
    // MARK: - Initialization
    
    init(container: ServiceContainer = .shared) {
        self.container = container
    }
    
    // MARK: - Module Creation
    // 注意：實際的模組實作會在各自的 Feature 資料夾中
    // 這裡只是工廠方法的定義，具體實作會在對應的 Phase 中完成
    
    /// 創建 TabBar 模組
    /// - Returns: TabBar 模組的 Coordinator
    func makeTabBarCoordinator(navigationController: UINavigationController) -> Coordinator {
        // 將在 Phase 2 實作 TabBarCoordinator
        fatalError("TabBarCoordinator not implemented yet")
    }
    
    /// 創建名片列表模組
    /// - Returns: 名片列表模組的 Coordinator
    func makeCardListCoordinator(navigationController: UINavigationController) -> Coordinator {
        // 將在 Phase 3 實作 CardListCoordinator
        fatalError("CardListCoordinator not implemented yet")
    }
    
    /// 創建名片建立模組
    /// - Parameters:
    ///   - navigationController: 導航控制器
    ///   - sourceType: 建立來源類型
    ///   - editingCard: 編輯的名片（如果是編輯模式）
    /// - Returns: 名片建立模組的 Coordinator
    func makeCardCreationCoordinator(
        navigationController: UINavigationController,
        sourceType: CardCreationSourceType,
        editingCard: BusinessCard? = nil
    ) -> Coordinator {
        // 將在 Phase 4-5 實作 CardCreationCoordinator
        fatalError("CardCreationCoordinator not implemented yet")
    }
    
    /// 創建名片詳情模組
    /// - Parameters:
    ///   - navigationController: 導航控制器
    ///   - card: 要顯示的名片
    /// - Returns: 名片詳情模組的 Coordinator
    func makeCardDetailCoordinator(
        navigationController: UINavigationController,
        card: BusinessCard
    ) -> Coordinator {
        // 將在 Phase 7 實作 CardDetailCoordinator
        fatalError("CardDetailCoordinator not implemented yet")
    }
    
    /// 創建設定模組
    /// - Returns: 設定模組的 Coordinator
    func makeSettingsCoordinator(navigationController: UINavigationController) -> Coordinator {
        // 將在 Phase 7 實作 SettingsCoordinator
        fatalError("SettingsCoordinator not implemented yet")
    }
    
    // MARK: - AI Processing Module
    // AI 模組比較特殊，它不需要 Coordinator，直接提供服務
    
    /// 取得 AI 處理服務（如果可用）
    /// - Returns: AI 處理服務或 nil
    func getAIProcessingService() -> AIProcessingService? {
        // 將在 Phase 6 實作
        return nil
    }
}

// MARK: - Temporary Types
// 這些類型暫時定義在這裡，之後會移到正確的位置

enum CardCreationSourceType {
    case camera
    case photoLibrary
    case manual
}

struct BusinessCard {
    let id: UUID
    let name: String
}

protocol AIProcessingService {
    func processCard(ocrText: String, completion: @escaping (Result<ParsedCardData, Error>) -> Void)
    var isAvailable: Bool { get }
}

struct ParsedCardData {
    let name: String?
    let company: String?
    let jobTitle: String?
}
