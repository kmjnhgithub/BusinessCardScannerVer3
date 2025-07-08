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
    
    // MARK: - Child Coordinators (internal for testing)
    var tabBarCoordinator: TabBarCoordinator?
    
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
        // 設定應用程式使用固定的 Light Mode，避免 Dark Mode 閃爍
        setupAppearance()
        
        // 這裡可以初始化需要在啟動時設定的服務
        // 例如：分析工具、推播通知等
        
    }
    
    /// 設定應用程式外觀，強制使用 Light Mode
    private func setupAppearance() {
        // 強制整個應用程式使用 Light Mode，避免 Dark Mode 閃爍
        if #available(iOS 13.0, *) {
            window.overrideUserInterfaceStyle = .light
        }
    }
    
    /// 啟動 TabBar 流程
    private func startTabBarFlow() {
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
        // 設定 Window 背景色，確保與設計規範一致，避免 Dark Mode 下的閃爍
        window.backgroundColor = AppTheme.Colors.background
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

// MARK: - TabBarCoordinatorDelegate

extension AppCoordinator: TabBarCoordinatorDelegate {
    
    /// TabBar 協調器請求顯示模組
    /// - Parameters:
    ///   - coordinator: TabBar 協調器
    ///   - moduleType: 要顯示的模組類型
    func tabBarCoordinator(_ coordinator: TabBarCoordinator, didRequestModule moduleType: AppModule) {
        switch moduleType {
        case .camera:
            // 處理相機模組請求（拍照 Tab 點擊）
            handleCameraModule()
        case .settings:
            // Settings 模組透過 TabBar 正常運作，無需特殊處理
            break
        case .cardDetail(let card):
            // 處理名片詳情模組請求
            handleCardDetailModule(card: card)
        case .cardCreation(let option):
            // 處理名片建立模組請求（+ 按鈕選單選項）
            handleCardCreationModule(with: option)
        }
    }
    
    /// 處理相機模組請求
    private func handleCameraModule() {
        // 取得當前選中 Tab 的導航控制器
        guard let currentNavigationController = getCurrentTabNavigationController() else {
            return
        }
        
        // 顯示新增名片選項
        showAddCardOptions(from: currentNavigationController)
    }
    
    /// 處理名片詳情模組請求
    private func handleCardDetailModule(card: BusinessCard) {
        print("📋 AppCoordinator: 顯示名片詳情 - \(card.name)")
        
        guard let currentNavigationController = getCurrentTabNavigationController() else {
            return
        }
        
        // 這裡應該啟動 CardDetail 模組，目前先使用 CardCreation 的編輯模式
        presentCardCreationModule(from: currentNavigationController, sourceType: .manual, editingCard: card)
    }
    
    /// 處理名片建立模組請求（帶選項）
    private func handleCardCreationModule(with option: AddCardOption) {
        print("🚀 AppCoordinator: 處理名片建立請求，選項: \(option)")
        
        guard let currentNavigationController = getCurrentTabNavigationController() else {
            return
        }
        
        // 將 AddCardOption 轉換為 CardCreationSourceType
        let sourceType: CardCreationSourceType
        switch option {
        case .camera:
            sourceType = .camera
        case .photoLibrary:
            sourceType = .photoLibrary
        case .manual:
            sourceType = .manual
        }
        
        presentCardCreationModule(from: currentNavigationController, sourceType: sourceType)
    }
    
    /// 顯示新增名片選項
    private func showAddCardOptions(from navigationController: UINavigationController) {
        guard let topViewController = getTopViewController() else { return }
        
        let actions: [AlertPresenter.AlertAction] = [
            .default("拍照") { [weak self] in
                self?.presentCardCreationModule(from: navigationController, sourceType: .camera)
            },
            .default("從相簿選擇") { [weak self] in
                self?.presentCardCreationModule(from: navigationController, sourceType: .photoLibrary)
            },
            .default("手動輸入") { [weak self] in
                self?.presentCardCreationModule(from: navigationController, sourceType: .manual)
            },
            .cancel("取消", nil)
        ]
        
        AlertPresenter.shared.showActionSheet(
            title: "新增名片",
            message: "選擇新增方式",
            actions: actions,
            sourceView: topViewController.view
        )
    }
    
    /// 呈現名片建立模組（統一入口）
    private func presentCardCreationModule(from navigationController: UINavigationController, sourceType: CardCreationSourceType, editingCard: BusinessCard? = nil) {
        print("📱 AppCoordinator: 呈現名片建立模組，來源類型: \(sourceType)，編輯卡片: \(editingCard?.name ?? "無")")
        
        // 使用標準模組工廠創建 CardCreation 模組
        let cardCreationModule = moduleFactory.makeCardCreationModule()
        let cardCreationCoordinator = cardCreationModule.makeCoordinator(
            navigationController: navigationController,
            sourceType: sourceType,
            editingCard: editingCard
        )
        
        // 設置委託以處理模組輸出
        if let coordinator = cardCreationCoordinator as? CardCreationCoordinator {
            coordinator.moduleOutput = self
        }
        
        // 添加到子協調器並啟動
        childCoordinators.append(cardCreationCoordinator)
        cardCreationCoordinator.start()
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
    
    /// 取得當前選中 Tab 的導航控制器
    /// - Returns: 當前 Tab 的導航控制器
    private func getCurrentTabNavigationController() -> UINavigationController? {
        guard let rootViewController = window.rootViewController as? UINavigationController,
              let tabBarController = rootViewController.topViewController as? UITabBarController,
              let selectedViewController = tabBarController.selectedViewController else {
            return nil
        }
        
        // 如果選中的是導航控制器，直接返回
        if let navigationController = selectedViewController as? UINavigationController {
            return navigationController
        }
        
        // 如果選中的不是導航控制器，可能是占位視圖控制器
        // 在這種情況下，我們使用 CardList Tab 的導航控制器作為預設
        if let cardListNavigationController = tabBarController.viewControllers?.first as? UINavigationController {
            return cardListNavigationController
        }
        
        return nil
    }
}

// MARK: - AppModule

/// 應用程式模組類型
enum AppModule {
    case camera
    case settings
    case cardDetail(BusinessCard)
    case cardCreation(AddCardOption)
}

// MARK: - TabBarCoordinatorDelegate Protocol

/// TabBar 協調器代理協議
protocol TabBarCoordinatorDelegate: AnyObject {
    func tabBarCoordinator(_ coordinator: TabBarCoordinator, didRequestModule moduleType: AppModule)
}


// MARK: - Helper Methods

extension AppCoordinator {
    
    /// 清理已完成的子協調器
    private func cleanupFinishedCoordinators() {
        // 移除已完成的名片建立協調器
        childCoordinators.removeAll { coordinator in
            return coordinator is CardCreationCoordinator
        }
    }
    
    /// 通知 CardList 重新載入資料
    private func notifyCardListToRefresh() {
        print("🔄 AppCoordinator: 通知 CardList 重新載入資料")
        
        // 找到 CardList 的 ViewController 和 ViewModel
        guard let tabBarController = navigationController.topViewController as? UITabBarController,
              let cardListNavController = tabBarController.viewControllers?.first as? UINavigationController,
              let cardListViewController = cardListNavController.topViewController as? CardListViewController else {
            print("⚠️ AppCoordinator: 無法找到 CardListViewController")
            return
        }
        
        // 通知 CardList 重新載入
        cardListViewController.refreshDataFromRepository()
        print("✅ AppCoordinator: 已通知 CardList 重新載入")
    }
}

// MARK: - CardCreationModuleOutput

extension AppCoordinator: CardCreationModuleOutput {
    
    func cardCreationDidFinish(with card: BusinessCard) {
        print("✅ AppCoordinator: 名片建立完成 - \(card.name)")
        
        // 通知 CardList 重新載入資料
        notifyCardListToRefresh()
        
        // 清理協調器
        cleanupFinishedCoordinators()
        
        // 顯示成功訊息
        AlertPresenter.shared.showMessage(
            "名片「\(card.name)」已成功保存",
            title: "保存成功"
        )
    }
    
    func cardCreationDidCancel() {
        print("❌ AppCoordinator: 名片建立被取消")
        
        // 清理協調器
        cleanupFinishedCoordinators()
    }
    
    func cardCreationRequestsContinue() {
        print("🔄 AppCoordinator: 收到繼續請求")
        // 這個方法可能在未來用於特殊的繼續流程，目前暫不需要實作
    }
}
