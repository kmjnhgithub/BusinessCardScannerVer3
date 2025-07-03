//
//  CardListCoordinator.swift
//  BusinessCardScannerVer3
//
//  名片列表協調器
//

import UIKit
import Combine

/// 新增名片的選項
enum AddCardOption {
    case camera        // 拍照
    case photoLibrary  // 從相簿選擇
    case manual        // 手動輸入
}

final class CardListCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private let moduleFactory: ModuleFactory
    private var viewModel: CardListViewModel?
    private var viewController: CardListViewController?
    private var cardCreationCoordinator: CardCreationCoordinator?
    
    // MARK: - Module Output
    
    weak var moduleOutput: CardListModuleOutput?
    
    // MARK: - Initialization
    
    init(navigationController: UINavigationController, moduleFactory: ModuleFactory) {
        self.moduleFactory = moduleFactory
        super.init(navigationController: navigationController)
    }
    
    // MARK: - Coordinator Lifecycle
    
    override func start() {
        setupCardListModule()
    }
    
    override func finish() {
        super.finish()
        viewModel = nil
        viewController = nil
        moduleOutput = nil
    }
    
    // MARK: - Private Methods
    
    private func setupCardListModule() {
        // 從 ServiceContainer 取得依賴
        let repository = ServiceContainer.shared.businessCardRepository
        
        // 建立 ViewModel
        let viewModel = CardListViewModel(repository: repository)
        self.viewModel = viewModel
        
        // 建立 ViewController
        let viewController = CardListViewController(viewModel: viewModel)
        viewController.coordinatorDelegate = self // 設定 delegate
        self.viewController = viewController
        
        // 設定 ViewController 為根視圖控制器
        if navigationController.viewControllers.isEmpty {
            navigationController.setViewControllers([viewController], animated: false)
        } else {
            navigationController.pushViewController(viewController, animated: true)
        }
        
        print("✅ CardListCoordinator: 名片列表模組已啟動")
    }
    
    // MARK: - Navigation Methods
    
    /// 導航到名片詳情
    private func showCardDetail(_ card: BusinessCard) {
        print("🔍 導航到名片編輯: \(card.name)")
        
        // 建立 CardCreationCoordinator 用於編輯現有名片
        let serviceContainer = ServiceContainer.shared
        cardCreationCoordinator = CardCreationCoordinator(
            navigationController: navigationController,
            dependencies: serviceContainer,
            sourceType: .manual, // 編輯現有名片使用手動輸入類型
            editingCard: card
        )
        cardCreationCoordinator?.moduleOutput = self
        
        // 顯示編輯現有名片表單
        cardCreationCoordinator?.showEditForm(for: card)
    }
    
    /// 顯示新增名片選項
    private func showAddCardOptions() {
        guard let viewController = self.viewController else { return }
        
        // 建立選項動作
        let actions: [AlertPresenter.AlertAction] = [
            .default("拍照") { [weak self] in
                self?.handleAddOption(.camera)
            },
            .default("從相簿選擇") { [weak self] in
                self?.handleAddOption(.photoLibrary)
            },
            .default("手動輸入") { [weak self] in
                self?.handleAddOption(.manual)
            },
            .cancel("取消", nil)
        ]
        
        // 顯示選項選單
        AlertPresenter.shared.showActionSheet(
            title: "新增名片",
            message: "選擇新增方式",
            actions: actions,
            sourceView: viewController.view
        )
    }
    
    /// 處理新增選項選擇
    private func handleAddOption(_ option: AddCardOption) {
        print("📸 選擇新增方式: \(option)")
        
        switch option {
        case .camera:
            checkCameraPermissionAndProceed()
        case .photoLibrary:
            checkPhotoLibraryPermissionAndProceed()
        case .manual:
            // 手動輸入不需要權限檢查
            moduleOutput?.cardListDidRequestNewCard(with: option)
        }
    }
    
    /// 檢查相機權限並繼續
    private func checkCameraPermissionAndProceed() {
        let permissionManager = ServiceContainer.shared.permissionManager
        
        permissionManager.requestCameraPermission { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    // 權限已授權，繼續拍照流程
                    print("✅ 相機權限已授權")
                    self?.moduleOutput?.cardListDidRequestNewCard(with: .camera)
                    
                case .denied, .restricted:
                    // 權限被拒絕，顯示設定提示
                    print("❌ 相機權限被拒絕")
                    self?.showPermissionDeniedAlert(for: .camera)
                    
                case .notDetermined:
                    // 這種情況理論上不應該發生，因為 requestCameraPermission 會處理
                    print("⚠️ 相機權限狀態未確定")
                    self?.showPermissionDeniedAlert(for: .camera)
                }
            }
        }
    }
    
    /// 檢查相簿權限並繼續
    private func checkPhotoLibraryPermissionAndProceed() {
        let permissionManager = ServiceContainer.shared.permissionManager
        
        permissionManager.requestPhotoLibraryPermission { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    // 權限已授權，繼續相簿選擇流程
                    print("✅ 相簿權限已授權")
                    self?.moduleOutput?.cardListDidRequestNewCard(with: .photoLibrary)
                    
                case .denied, .restricted:
                    // 權限被拒絕，顯示設定提示
                    print("❌ 相簿權限被拒絕")
                    self?.showPermissionDeniedAlert(for: .photoLibrary)
                    
                case .notDetermined:
                    // 這種情況理論上不應該發生，因為 requestPhotoLibraryPermission 會處理
                    print("⚠️ 相簿權限狀態未確定")
                    self?.showPermissionDeniedAlert(for: .photoLibrary)
                }
            }
        }
    }
    
    /// 顯示權限被拒絕的提示
    private func showPermissionDeniedAlert(for type: PermissionManager.PermissionType) {
        guard let viewController = self.viewController else { return }
        
        let permissionManager = ServiceContainer.shared.permissionManager
        permissionManager.showPermissionSettingsAlert(for: type, from: viewController)
    }
}

// MARK: - CardListModulable

extension CardListCoordinator: CardListModulable {
    
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator {
        return CardListCoordinator(navigationController: navigationController, moduleFactory: moduleFactory)
    }
}

// MARK: - Module Factory Extension

extension ModuleFactory {
    
    /// 建立 CardList 模組協調器
    func makeCardListCoordinator(navigationController: UINavigationController) -> CardListCoordinator {
        return CardListCoordinator(navigationController: navigationController, moduleFactory: self)
    }
}

// MARK: - CardListCoordinatorDelegate

extension CardListCoordinator: CardListCoordinatorDelegate {
    
    func cardListDidSelectCard(_ card: BusinessCard) {
        showCardDetail(card)
    }
    
    func cardListDidRequestNewCard() {
        showAddCardOptions()
    }
    
    func cardListDidRequestEdit(_ card: BusinessCard) {
        print("✏️ 編輯名片: \(card.name)")
        // 直接呼叫編輯導航
        showCardDetail(card)
    }
}

// MARK: - CardCreationModuleOutput

extension CardListCoordinator: CardCreationModuleOutput {
    
    func cardCreationDidFinish(with card: BusinessCard) {
        print("✅ CardListCoordinator: 名片保存成功 - \(card.name)")
        
        // 清理 Coordinator
        cardCreationCoordinator = nil
        
        // 重新載入列表資料
        viewModel?.loadCards()
        
        // 顯示成功訊息
        AlertPresenter.shared.showMessage(
            "名片「\(card.name)」已成功更新",
            title: "保存成功"
        )
    }
    
    func cardCreationDidCancel() {
        print("❌ CardListCoordinator: 使用者取消編輯")
        
        // 清理 Coordinator
        cardCreationCoordinator = nil
    }
    
    func cardCreationRequestsContinue() {
        print("🔄 CardListCoordinator: 名片建立流程繼續")
        // 暫不實作
    }
}