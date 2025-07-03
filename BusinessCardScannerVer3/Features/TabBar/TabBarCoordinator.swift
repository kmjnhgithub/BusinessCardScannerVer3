//
//  TabBarCoordinator.swift
//  BusinessCardScannerVer3
//
//  TabBar 模組協調器，管理主要的標籤頁導航
//

import UIKit
import Combine

/// TabBar 協調器
/// 負責管理 TabBar 的創建、配置和子模組協調
final class TabBarCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private let moduleFactory: ModuleFactory
    private var tabBarController: MainTabBarController?
    
    /// TabBar 協調器代理
    weak var delegate: TabBarCoordinatorDelegate?
    
    // MARK: - Child Coordinators (internal for testing)
    var cardListCoordinator: CardListCoordinator?
    // Note: settingsCoordinator not implemented yet (placeholder used)
    
    // MARK: - Types
    
    /// Tab 索引枚舉
    enum TabIndex: Int, CaseIterable {
        case cardList = 0
        case camera = 1
        case settings = 2
        
        var title: String {
            switch self {
            case .cardList: return "名片"
            case .camera: return "拍照"
            case .settings: return "設定"
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .cardList: return UIImage(systemName: "rectangle.grid.1x2")
            case .camera: return UIImage(systemName: "camera.fill")
            case .settings: return UIImage(systemName: "gearshape.fill")
            }
        }
        
        var selectedIcon: UIImage? {
            switch self {
            case .cardList: return UIImage(systemName: "rectangle.grid.1x2.fill")
            case .camera: return UIImage(systemName: "camera.fill")
            case .settings: return UIImage(systemName: "gearshape.fill")
            }
        }
    }
    
    // MARK: - Initialization
    
    /// 初始化 TabBar 協調器
    /// - Parameters:
    ///   - navigationController: 導航控制器
    ///   - moduleFactory: 模組工廠
    init(navigationController: UINavigationController, moduleFactory: ModuleFactory) {
        self.moduleFactory = moduleFactory
        super.init(navigationController: navigationController)
    }
    
    // MARK: - Coordinator Lifecycle
    
    /// 啟動 TabBar 協調器
    override func start() {
        print("📱 TabBarCoordinator: 啟動 TabBar")
        
        // 創建 TabBar 控制器
        let tabBarController = MainTabBarController()
        self.tabBarController = tabBarController
        
        // 設定 TabBar 代理
        tabBarController.tabBarDelegate = self
        
        // 創建並配置所有 Tab
        setupTabs()
        
        // 顯示 TabBar
        navigationController.setViewControllers([tabBarController], animated: false)
        
        print("✅ TabBarCoordinator: TabBar 啟動完成")
    }
    
    // MARK: - Private Methods
    
    /// 設定所有標籤頁
    private func setupTabs() {
        print("🏗️ TabBarCoordinator: 設定標籤頁")
        
        var viewControllers: [UIViewController] = []
        
        for tabIndex in TabIndex.allCases {
            let viewController = createTabViewController(for: tabIndex)
            viewControllers.append(viewController)
        }
        
        tabBarController?.setViewControllers(viewControllers, animated: false)
        tabBarController?.selectedIndex = TabIndex.cardList.rawValue
        
        print("✅ TabBarCoordinator: 標籤頁設定完成")
    }
    
    /// 為指定的 Tab 創建視圖控制器
    /// - Parameter tabIndex: Tab 索引
    /// - Returns: 視圖控制器
    private func createTabViewController(for tabIndex: TabIndex) -> UIViewController {
        switch tabIndex {
        case .cardList:
            return createCardListTab()
        case .camera:
            return createCameraTab()
        case .settings:
            return createSettingsTab()
        }
    }
    
    /// 創建名片列表 Tab
    /// - Returns: 名片列表視圖控制器
    private func createCardListTab() -> UIViewController {
        print("📋 TabBarCoordinator: 創建名片列表 Tab")
        
        // 創建導航控制器
        let navigationController = UINavigationController()
        
        // 創建 CardList 協調器並啟動
        let coordinator = moduleFactory.makeCardListCoordinator(navigationController: navigationController)
        coordinator.start()
        
        // 將協調器添加到子協調器中管理生命週期
        addChild(coordinator)
        
        // 儲存協調器引用供測試使用
        cardListCoordinator = coordinator
        
        // 設定 Tab Bar Item
        setupTabBarItem(for: navigationController, tabIndex: .cardList)
        
        return navigationController
    }
    
    /// 創建相機 Tab
    /// - Returns: 相機占位視圖控制器
    private func createCameraTab() -> UIViewController {
        print("📸 TabBarCoordinator: 創建相機 Tab")
        
        // 相機 Tab 使用特殊處理，不顯示實際內容
        // 只是一個占位符，實際功能在 TabBar 代理中處理
        let placeholderVC = PlaceholderViewController(
            moduleTitle: "相機拍攝",
            description: "使用相機拍攝名片或從相簿選擇照片，透過 AI 智慧解析名片資訊。",
            phase: "Phase 4 (Task 4.1-4.4)",
            features: [
                "相機拍攝名片照片",
                "從相簿選擇名片圖片",
                "Vision Framework OCR 文字識別",
                "OpenAI AI 智慧解析",
                "本地規則解析（離線模式）",
                "照片預覽和編輯"
            ],
            icon: TabIndex.camera.icon
        )
        
        // 設定 Tab Bar Item
        setupTabBarItem(for: placeholderVC, tabIndex: .camera)
        
        return placeholderVC
    }
    
    /// 創建設定 Tab
    /// - Returns: 設定視圖控制器
    private func createSettingsTab() -> UIViewController {
        print("⚙️ TabBarCoordinator: 創建設定 Tab")
        
        // 創建導航控制器
        let navigationController = UINavigationController()
        
        // 未來實作：創建 Settings 協調器
        // let coordinator = moduleFactory.makeSettingsCoordinator(navigationController: navigationController)
        // coordinator.start()
        
        // 目前使用占位視圖控制器
        let placeholderVC = PlaceholderViewController(
            moduleTitle: "應用設定",
            description: "管理應用程式設定、資料匯出和儲存空間，以及 AI 服務配置。",
            phase: "Phase 7 (Task 7.2-7.3)",
            features: [
                "AI 服務設定（OpenAI API Key）",
                "資料匯出（CSV/vCard 格式）",
                "儲存空間管理",
                "清除所有資料",
                "應用程式關於資訊",
                "使用統計查看"
            ],
            icon: TabIndex.settings.icon
        )
        
        navigationController.setViewControllers([placeholderVC], animated: false)
        
        // 設定 Tab Bar Item
        setupTabBarItem(for: navigationController, tabIndex: .settings)
        
        return navigationController
    }
    
    
    /// 設定 TabBar Item
    /// - Parameters:
    ///   - viewController: 視圖控制器
    ///   - tabIndex: Tab 索引
    private func setupTabBarItem(for viewController: UIViewController, tabIndex: TabIndex) {
        let tabBarItem = UITabBarItem(
            title: tabIndex.title,
            image: tabIndex.icon,
            selectedImage: tabIndex.selectedIcon
        )
        viewController.tabBarItem = tabBarItem
    }
}

// MARK: - MainTabBarControllerDelegate

extension TabBarCoordinator: MainTabBarControllerDelegate {
    
    /// 處理 Tab 選擇事件
    /// - Parameters:
    ///   - tabBarController: TabBar 控制器
    ///   - index: 選中的索引
    /// - Returns: 是否允許切換
    func tabBarController(_ tabBarController: MainTabBarController, shouldSelectTabAt index: Int) -> Bool {
        guard let tabIndex = TabIndex(rawValue: index) else { return true }
        
        print("📱 TabBarCoordinator: Tab 選擇事件 - \(tabIndex.title)")
        
        switch tabIndex {
        case .camera:
            // 攔截相機 Tab，不實際切換
            print("📸 TabBarCoordinator: 攔截相機 Tab，觸發相機功能")
            delegate?.tabBarCoordinator(self, didRequestModule: .camera)
            return false // 不切換到相機 Tab
            
        case .cardList, .settings:
            // 正常切換
            return true
        }
    }
    
    /// Tab 切換完成回調
    /// - Parameters:
    ///   - tabBarController: TabBar 控制器
    ///   - index: 當前索引
    func tabBarController(_ tabBarController: MainTabBarController, didSelectTabAt index: Int) {
        guard let tabIndex = TabIndex(rawValue: index) else { return }
        print("✅ TabBarCoordinator: 已切換到 \(tabIndex.title) Tab")
    }
}