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
        
        // 設定應用程式使用固定的 Light Mode，避免 Dark Mode 閃爍
        setupAppearance()
        
        // 這裡可以初始化需要在啟動時設定的服務
        // 例如：分析工具、推播通知等
        
        print("✅ AppCoordinator: 服務容器初始化完成")
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
        // 設定 Window 背景色，確保與設計規範一致，避免 Dark Mode 下的閃爍
        window.backgroundColor = AppTheme.Colors.background
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
        
        // 執行 OCR 處理
        processImageWithOCR(image)
        
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
        
        // 執行 OCR 處理
        processImageWithOCR(image)
        
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
    
    /// 使用 OCR 處理圖片
    /// - Parameter image: 要處理的圖片
    private func processImageWithOCR(_ image: UIImage) {
        print("🔍 AppCoordinator: 開始 OCR 處理")
        
        // 顯示處理中提示
        guard getTopViewController() != nil else { return }
        
        // 使用 AlertPresenter 顯示處理中狀態
        AlertPresenter.shared.showMessage(
            "正在識別名片內容，請稍候...",
            title: "處理中"
        )
        
        // 建立 OCR 處理器並執行
        let ocrProcessor = OCRProcessor()
        
        ocrProcessor.processImage(image) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleOCRResult(result, originalImage: image)
            }
        }
    }
    
    /// 處理 OCR 結果
    /// - Parameters:
    ///   - result: OCR 處理結果
    ///   - originalImage: 原始圖片
    private func handleOCRResult(_ result: Result<OCRProcessingResult, OCRError>, originalImage: UIImage) {
        guard let topViewController = getTopViewController() else { return }
        
        switch result {
        case .success(let processingResult):
            print("✅ AppCoordinator: OCR 處理成功")
            
            // 顯示識別結果
            showOCRResult(processingResult)
            
        case .failure(let error):
            print("❌ AppCoordinator: OCR 處理失敗 - \(error.localizedDescription)")
            
            // 顯示錯誤訊息
            AlertPresenter.shared.showMessage(
                "文字識別失敗：\(error.localizedDescription)\n\n請確保照片清晰且包含文字內容。",
                title: "識別失敗"
            )
        }
    }
    
    /// 顯示 OCR 識別結果
    /// - Parameter result: OCR 處理結果
    private func showOCRResult(_ result: OCRProcessingResult) {
        guard let topViewController = getTopViewController() else { return }
        
        // 建立結果摘要
        let ocrResult = result.ocrResult
        let extractedFields = result.extractedFields
        
        var message = "📊 識別統計:\n"
        message += "• 文字長度: \(ocrResult.recognizedText.count) 字元\n"
        message += "• 信心度: \(String(format: "%.1f", ocrResult.confidence * 100))%\n"
        message += "• 處理時間: \(String(format: "%.2f", ocrResult.processingTime)) 秒\n\n"
        
        message += "🏷️ 提取欄位 (\(extractedFields.count) 個):\n"
        
        if let name = extractedFields["name"] {
            message += "• 姓名: \(name)\n"
        }
        if let company = extractedFields["company"] {
            message += "• 公司: \(company)\n"
        }
        if let title = extractedFields["title"] {
            message += "• 職位: \(title)\n"
        }
        if let phone = extractedFields["phone"] {
            message += "• 電話: \(phone)\n"
        }
        if let email = extractedFields["email"] {
            message += "• 郵件: \(email)\n"
        }
        if let website = extractedFields["website"] {
            message += "• 網站: \(website)\n"
        }
        if let address = extractedFields["address"] {
            message += "• 地址: \(address)\n"
        }
        
        if extractedFields.isEmpty {
            message += "• 未自動識別到特定欄位\n"
        }
        
        message += "\n📝 原始識別文字:\n"
        message += result.preprocessedText.prefix(200)
        if result.preprocessedText.count > 200 {
            message += "..."
        }
        
        // 顯示結果 Alert
        let alert = UIAlertController(
            title: "✅ 識別完成",
            message: message,
            preferredStyle: .alert
        )
        
        // 保存按鈕 (未來實作)
        alert.addAction(UIAlertAction(title: "保存名片", style: .default) { _ in
            // TODO: Task 5.1 實作保存功能
            AlertPresenter.shared.showMessage(
                "保存功能將在後續任務中實作",
                title: "開發中"
            )
        })
        
        // 重新拍攝按鈕
        alert.addAction(UIAlertAction(title: "重新拍攝", style: .default) { [weak self] _ in
            self?.handleCameraModule()
        })
        
        // 關閉按鈕
        alert.addAction(UIAlertAction(title: "關閉", style: .cancel))
        
        topViewController.present(alert, animated: true)
        
        print("📋 AppCoordinator: OCR 結果已顯示")
    }
}
