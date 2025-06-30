//
//  CardListCoordinator.swift
//  BusinessCardScannerVer3
//
//  名片列表協調器
//

import UIKit
import Combine

final class CardListCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private let moduleFactory: ModuleFactory
    private var viewModel: CardListViewModel?
    private var viewController: CardListViewController?
    
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
        // TODO: Task 7.1 實作詳情頁導航
        print("🔍 導航到名片詳情: \(card.name)")
        moduleOutput?.cardListDidSelectCard(card)
    }
    
    /// 顯示新增名片選項
    private func showAddCardOptions() {
        // TODO: Task 3.4 實作新增選項 AlertPresenter
        print("➕ 顯示新增名片選項")
        moduleOutput?.cardListDidRequestNewCard()
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