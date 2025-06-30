//
//  AppCoordinator.swift
//  BusinessCardScannerVer3
//
//  最高層級協調器，管理應用程式的啟動流程
//

import UIKit

/// 應用程式主協調器
/// 負責管理整個應用程式的導航流程和模組協調
final class AppCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private let window: UIWindow
    private let serviceContainer: ServiceContainer
    private let moduleFactory: ModuleFactory
    private var tabBarCoordinator: TabBarCoordinator?
    
    // MARK: - Initialization
    
    /// 初始化 AppCoordinator
    /// - Parameter window: 主視窗
    init(window: UIWindow) {
        self.window = window
        self.serviceContainer = ServiceContainer.shared
        self.moduleFactory = ModuleFactory()
        super.init(navigationController: UINavigationController())
    }
    
    // MARK: - Coordinator Lifecycle
    
    /// 啟動應用程式
    override func start() {
        print("🚀 AppCoordinator: 啟動應用程式")
        
        // 初始化服務容器
        setupServices()
        
        // 啟動 TabBar 流程
        startTabBarFlow()
        
        // 設定主視窗
        setupWindow()
    }
    
    // MARK: - Private Methods
    
    /// 設定服務容器
    private func setupServices() {
        print("⚙️ AppCoordinator: 初始化服務容器")
        
        // 這裡可以初始化需要在啟動時設定的服務
        // 例如：主題設定、分析工具、推播通知等
        
        // 設定主題（如果有暗色模式切換）
        // ThemeManager.shared.applyTheme()
        
        print("✅ AppCoordinator: 服務容器初始化完成")
    }
    
    /// 啟動 TabBar 流程
    private func startTabBarFlow() {
        print("📱 AppCoordinator: 啟動 TabBar 流程")
        
        // 創建 TabBar 導航控制器
        let tabBarNavigationController = UINavigationController()
        tabBarNavigationController.isNavigationBarHidden = true
        
        // 創建 TabBar 協調器
        let coordinator = moduleFactory.makeTabBarCoordinator(
            navigationController: tabBarNavigationController
        )
        
        // 設定代理以處理 TabBar 事件
        coordinator.delegate = self
        
        // 儲存引用
        tabBarCoordinator = coordinator
        childCoordinators.append(coordinator)
        
        // 啟動 TabBar
        coordinator.start()
        
        // 更新主導航控制器
        navigationController = tabBarNavigationController
    }
    
    /// 設定主視窗
    private func setupWindow() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        print("✅ AppCoordinator: 應用程式啟動完成")
    }
}

// MARK: - TabBarCoordinatorDelegate

extension AppCoordinator: TabBarCoordinatorDelegate {
    
    /// TabBar 協調器請求顯示模組
    /// - Parameters:
    ///   - coordinator: TabBar 協調器
    ///   - moduleType: 要顯示的模組類型
    func tabBarCoordinator(_ coordinator: TabBarCoordinator, didRequestModule moduleType: AppModule) {
        print("📋 AppCoordinator: 處理模組請求 - \(moduleType)")
        
        switch moduleType {
        case .camera:
            // 處理相機模組請求
            handleCameraModule()
        case .settings:
            // TODO: 未來可能需要特殊的設定模組處理邏輯
            print("⚙️ AppCoordinator: 設定模組無需特殊處理")
        }
    }
    
    /// 處理相機模組請求
    private func handleCameraModule() {
        print("📸 AppCoordinator: 處理相機模組請求")
        
        // 目前顯示相機功能的演示 Alert
        showCameraFeatureDemo()
        
        // 未來實作 (Phase 4)：
        // let cardCreationCoordinator = moduleFactory.makeCardCreationCoordinator(...)
        // cardCreationCoordinator.start()
    }
    
    /// 顯示相機功能演示
    private func showCameraFeatureDemo() {
        guard let topViewController = getTopViewController() else { return }
        
        let alert = UIAlertController(
            title: "📸 相機功能",
            message: "相機模組將在 Phase 4 實作\n\n支援功能：\n• 拍攝名片照片\n• 從相簿選擇照片\n• 手動輸入名片資訊",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "了解", style: .default))
        
        topViewController.present(alert, animated: true)
        print("✅ AppCoordinator: 顯示相機功能演示")
    }
    
    /// 取得目前最上層的視圖控制器
    /// - Returns: 最上層的視圖控制器
    private func getTopViewController() -> UIViewController? {
        guard let rootViewController = window.rootViewController else { return nil }
        return findTopMostViewController(from: rootViewController)
    }
    
    /// 從指定視圖控制器開始尋找最上層的視圖控制器
    /// - Parameter viewController: 起始視圖控制器
    /// - Returns: 最上層的視圖控制器
    private func findTopMostViewController(from viewController: UIViewController) -> UIViewController {
        // 處理 presented 視圖控制器
        if let presentedViewController = viewController.presentedViewController {
            return findTopMostViewController(from: presentedViewController)
        }
        
        // 處理 TabBar 控制器
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return findTopMostViewController(from: selectedViewController)
        }
        
        // 處理導航控制器
        if let navigationController = viewController as? UINavigationController,
           let topViewController = navigationController.topViewController {
            return findTopMostViewController(from: topViewController)
        }
        
        return viewController
    }
}

// MARK: - AppModule

/// 應用程式模組類型
enum AppModule {
    case camera
    case settings
}

// MARK: - TabBarCoordinatorDelegate Protocol

/// TabBar 協調器代理協議
protocol TabBarCoordinatorDelegate: AnyObject {
    func tabBarCoordinator(_ coordinator: TabBarCoordinator, didRequestModule moduleType: AppModule)
}
