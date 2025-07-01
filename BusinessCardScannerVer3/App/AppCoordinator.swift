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
        
        // 取得目前的導航控制器
        guard let topViewController = getTopViewController(),
              let navigationController = topViewController.navigationController else {
            print("❌ AppCoordinator: 無法取得導航控制器")
            return
        }
        
        // 顯示新增名片選項
        showAddCardOptions(from: navigationController)
    }
    
    /// 顯示新增名片選項
    private func showAddCardOptions(from navigationController: UINavigationController) {
        guard let topViewController = getTopViewController() else { return }
        
        let actions: [AlertPresenter.AlertAction] = [
            .default("拍照") { [weak self] in
                self?.presentCameraModule(from: navigationController)
            },
            .default("從相簿選擇") { [weak self] in
                self?.presentPhotoPickerModule(from: navigationController)
            },
            .default("手動輸入") { [weak self] in
                self?.presentManualInputModule(from: navigationController)
            },
            .cancel("取消", nil)
        ]
        
        AlertPresenter.shared.showActionSheet(
            title: "新增名片",
            message: "選擇新增方式",
            actions: actions,
            sourceView: topViewController.view
        )
        
        print("✅ AppCoordinator: 顯示新增名片選項")
    }
    
    /// 呈現相機模組
    private func presentCameraModule(from navigationController: UINavigationController) {
        print("📸 AppCoordinator: 啟動相機模組")
        
        let cameraCoordinator = moduleFactory.makeCameraCoordinator(navigationController: navigationController)
        cameraCoordinator.moduleOutput = self
        
        childCoordinators.append(cameraCoordinator)
        cameraCoordinator.start()
    }
    
    /// 呈現相簿選擇模組
    private func presentPhotoPickerModule(from navigationController: UINavigationController) {
        print("📁 AppCoordinator: 啟動相簿選擇模組")
        
        let photoPickerCoordinator = moduleFactory.makePhotoPickerCoordinator(navigationController: navigationController)
        photoPickerCoordinator.moduleOutput = self
        
        childCoordinators.append(photoPickerCoordinator)
        photoPickerCoordinator.start()
    }
    
    /// 呈現手動輸入模組
    private func presentManualInputModule(from navigationController: UINavigationController) {
        print("✏️ AppCoordinator: 啟動手動輸入模組")
        
        // TODO: Task 5.1 實作手動輸入模組
        guard let topViewController = getTopViewController() else { return }
        
        AlertPresenter.shared.showMessage(
            "手動輸入功能將在 Task 5.1 中實作",
            title: "開發中"
        )
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

// MARK: - CameraModuleOutput

extension AppCoordinator: CameraModuleOutput {
    
    func cameraDidCaptureImage(_ image: UIImage) {
        print("✅ AppCoordinator: 收到拍攝的照片")
        
        // TODO: Task 4.3 實作 OCR 處理
        // 暫時顯示成功訊息
        guard let topViewController = getTopViewController() else { return }
        
        AlertPresenter.shared.showMessage(
            "照片拍攝成功！\nOCR 處理功能將在 Task 4.3 中實作",
            title: "拍攝完成"
        )
        
        // 清理協調器
        cleanupFinishedCoordinators()
    }
    
    func cameraDidCancel() {
        print("❌ AppCoordinator: 相機拍攝已取消")
        
        // 清理協調器
        cleanupFinishedCoordinators()
    }
}

// MARK: - PhotoPickerModuleOutput

extension AppCoordinator: PhotoPickerModuleOutput {
    
    func photoPickerDidSelectImage(_ image: UIImage) {
        print("✅ AppCoordinator: 收到選擇的照片")
        
        // TODO: Task 4.3 實作 OCR 處理
        // 暫時顯示成功訊息
        guard let topViewController = getTopViewController() else { return }
        
        AlertPresenter.shared.showMessage(
            "照片選擇成功！\nOCR 處理功能將在 Task 4.3 中實作",
            title: "選擇完成"
        )
        
        // 清理協調器
        cleanupFinishedCoordinators()
    }
    
    func photoPickerDidCancel() {
        print("❌ AppCoordinator: 相簿選擇已取消")
        
        // 清理協調器
        cleanupFinishedCoordinators()
    }
}

// MARK: - Helper Methods

extension AppCoordinator {
    
    /// 清理已完成的子協調器
    private func cleanupFinishedCoordinators() {
        // 移除已完成的相機和相簿選擇協調器
        childCoordinators.removeAll { coordinator in
            return coordinator is CameraCoordinator || coordinator is PhotoPickerCoordinator
        }
    }
}
