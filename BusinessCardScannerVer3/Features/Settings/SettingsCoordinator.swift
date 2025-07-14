//
//  SettingsCoordinator.swift
//  BusinessCardScannerVer3
//
//  設定模組協調器
//  位置：Features/Settings/SettingsCoordinator.swift
//

import UIKit

/// 設定協調器
/// 負責管理設定模組的導航流程和子模組協調
final class SettingsCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private let repository: BusinessCardRepository
    private let exportService: ExportService
    private let aiProcessingModule: AIProcessingModulable?
    private let animationPreferences: AnimationPreferences
    private let moduleFactory: ModuleFactory
    
    /// 設定模組輸出代理
    weak var moduleOutput: SettingsModuleOutput?
    
    // MARK: - Initialization
    
    /// 初始化設定協調器
    /// - Parameters:
    ///   - navigationController: 導航控制器
    ///   - repository: 名片資料庫
    ///   - exportService: 匯出服務
    ///   - aiProcessingModule: AI 處理模組（可選）
    ///   - animationPreferences: 動畫偏好設定服務
    ///   - moduleFactory: 模組工廠
    init(
        navigationController: UINavigationController,
        repository: BusinessCardRepository,
        exportService: ExportService,
        aiProcessingModule: AIProcessingModulable?,
        animationPreferences: AnimationPreferences,
        moduleFactory: ModuleFactory
    ) {
        self.repository = repository
        self.exportService = exportService
        self.aiProcessingModule = aiProcessingModule
        self.animationPreferences = animationPreferences
        self.moduleFactory = moduleFactory
        super.init(navigationController: navigationController)
    }
    
    // MARK: - Coordinator Lifecycle
    
    /// 啟動設定協調器
    override func start() {
        print("🔧 SettingsCoordinator: 啟動設定頁面")
        showSettingsViewController()
    }
    
    // MARK: - Public Methods
    
    /// 準備設定頁面顯示（由上層 Coordinator 調用）
    /// - Note: 遵循 MVVM+C 架構，重新載入統計數據等狀態資訊
    func prepareForDisplay() {
        print("🔄 SettingsCoordinator: 準備設定頁面顯示")
        // 設定頁面通常需要重新載入統計數據
        // 可以在這裡添加必要的狀態刷新邏輯
    }
    
    // MARK: - Private Methods
    
    /// 顯示設定主頁面
    private func showSettingsViewController() {
        // 建立 ViewModel
        let viewModel = SettingsViewModel(
            repository: repository,
            exportService: exportService,
            aiProcessingModule: aiProcessingModule,
            animationPreferences: animationPreferences
        )
        
        // 建立 ViewController
        let viewController = SettingsViewController(viewModel: viewModel)
        viewController.coordinator = self
        
        // 推送到導航堆疊
        push(viewController)
        
        print("✅ SettingsCoordinator: 設定頁面顯示完成")
    }
}

// MARK: - SettingsCoordinatorProtocol

extension SettingsCoordinator: SettingsCoordinatorProtocol {
    
    /// 顯示 AI 設定頁面
    func showAISettings() {
        print("🤖 SettingsCoordinator: 顯示 AI 設定頁面")
        
        // 使用模組工廠建立 AI 設定模組
        let aiSettingsModule = moduleFactory.makeAISettingsModule()
        let aiSettingsViewController = aiSettingsModule.makeViewController()
        
        // 以 Modal 方式呈現 AI 設定頁面
        present(aiSettingsViewController, animated: true)
        
        print("✅ SettingsCoordinator: AI 設定頁面顯示完成")
    }
}

// MARK: - Factory Methods

extension SettingsCoordinator {
    
    /// 建立設定協調器
    /// - Parameters:
    ///   - navigationController: 導航控制器
    ///   - dependencies: 服務依賴
    /// - Returns: 設定協調器實例
    static func make(
        navigationController: UINavigationController,
        dependencies: ServiceContainer
    ) -> SettingsCoordinator {
        return SettingsCoordinator(
            navigationController: navigationController,
            repository: dependencies.businessCardRepository,
            exportService: dependencies.exportService,
            aiProcessingModule: ModuleFactory().makeAIProcessingModule(),
            animationPreferences: dependencies.animationPreferences,
            moduleFactory: ModuleFactory()
        )
    }
}