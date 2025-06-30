//
//  Task33VerificationTest.swift
//  BusinessCardScannerVer3
//
//  Task 3.3: 列表互動功能驗證測試
//

import UIKit
import Combine

/// Task 3.3 列表互動功能驗證測試
/// 測試滑動刪除、下拉更新、點擊跳轉等功能
class Task33VerificationTest {
    
    // MARK: - Test Entry Point
    
    /// 執行 Task 3.3 驗證測試
    static func runVerification() {
        print("🧪 開始執行 Task 3.3 驗證測試...")
        
        // 1. 測試 CardListViewController 的互動功能
        testCardListInteractions()
        
        // 2. 測試 CardListViewModel 的資料操作
        testCardListDataOperations()
        
        // 3. 測試 Coordinator 委託功能
        testCoordinatorDelegate()
        
        // 4. 測試刪除同步性
        testDeleteSynchronization()
        
        print("✅ Task 3.3 驗證測試完成")
    }
    
    // MARK: - 測試方法
    
    /// 測試 CardListViewController 的互動功能
    private static func testCardListInteractions() {
        print("📋 測試 CardListViewController 互動功能...")
        
        // 創建測試環境
        let repository = ServiceContainer.shared.businessCardRepository
        let viewModel = CardListViewModel(repository: repository)
        let viewController = CardListViewController(viewModel: viewModel)
        
        // 模擬載入視圖
        viewController.loadViewIfNeeded()
        viewController.viewDidLoad()
        
        // 測試基本 UI 元素存在
        let tableView = viewController.view.subviews.first { $0 is UITableView } as? UITableView
        assert(tableView != nil, "❌ TableView 不存在")
        
        // 測試 tableView 設定
        assert(tableView?.delegate != nil, "❌ TableView delegate 未設定")
        assert(tableView?.dataSource != nil, "❌ TableView dataSource 未設定")
        assert(tableView?.refreshControl != nil, "❌ RefreshControl 未設定")
        
        // 測試滑動刪除功能
        let canEdit = viewController.tableView(tableView!, canEditRowAt: IndexPath(row: 0, section: 0))
        assert(canEdit, "❌ 滑動刪除功能未啟用")
        
        // 測試搜尋功能
        let searchController = viewController.navigationItem.searchController
        assert(searchController != nil, "❌ SearchController 未設定")
        
        print("✅ CardListViewController 互動功能測試通過")
    }
    
    /// 測試 CardListViewModel 的資料操作
    private static func testCardListDataOperations() {
        print("📊 測試 CardListViewModel 資料操作...")
        
        let repository = ServiceContainer.shared.businessCardRepository
        let viewModel = CardListViewModel(repository: repository)
        
        // 給足夠延遲確保 Combine 管道初始化完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 測試初始狀態
            assert(viewModel.cards.count > 0, "❌ 初始資料為空")
            assert(viewModel.filteredCards.count > 0, "❌ 過濾資料為空，cards: \(viewModel.cards.count), filtered: \(viewModel.filteredCards.count)")
            
            // 使用更可靠的搜尋測試方法
            testSearchFunctionality(viewModel: viewModel)
            
            // 確保搜尋測試後狀態重置
            Thread.sleep(forTimeInterval: 0.1) // 等待最後的 Combine 更新
            assert(viewModel.filteredCards.count == viewModel.cards.count, "❌ 搜尋測試後狀態異常")
            
            // 測試刪除功能
            let originalCardCount = viewModel.cards.count
            let cardToDelete = viewModel.filteredCards.first!
            let cardId = cardToDelete.id
            
            viewModel.deleteCard(cardToDelete)
            
            // 檢查立即刪除是否生效
            let newCardCount = viewModel.cards.count
            assert(newCardCount == originalCardCount - 1, "❌ 立即刪除功能失敗")
            
            let hasCard = viewModel.cards.contains { $0.id == cardId }
            assert(!hasCard, "❌ 刪除資料驗證失敗")
            
            print("✅ CardListViewModel 資料操作測試通過")
        }
    }
    
    /// 測試 Coordinator 委託功能
    private static func testCoordinatorDelegate() {
        print("🔗 測試 Coordinator 委託功能...")
        
        // 創建測試環境
        let navigationController = UINavigationController()
        let moduleFactory = ModuleFactory()
        let coordinator = CardListCoordinator(navigationController: navigationController, moduleFactory: moduleFactory)
        
        // 測試啟動功能
        coordinator.start()
        
        // 檢查是否正確設定了 ViewController
        assert(!navigationController.viewControllers.isEmpty, "❌ Coordinator 未正確設定 ViewController")
        
        let cardListVC = navigationController.viewControllers.first as? CardListViewController
        assert(cardListVC != nil, "❌ 未找到 CardListViewController")
        assert(cardListVC?.coordinatorDelegate != nil, "❌ CoordinatorDelegate 未設定")
        
        // 測試委託是否為 coordinator 本身
        let delegate = cardListVC?.coordinatorDelegate
        assert(delegate === coordinator, "❌ CoordinatorDelegate 設定錯誤")
        
        print("✅ Coordinator 委託功能測試通過")
    }
}

// MARK: - 模擬 Delegate 測試

class MockCardListCoordinatorDelegate: CardListCoordinatorDelegate {
    
    var didSelectCardCalled = false
    var didRequestNewCardCalled = false
    var didRequestEditCalled = false
    
    func cardListDidSelectCard(_ card: BusinessCard) {
        didSelectCardCalled = true
        print("🔍 模擬選中名片: \(card.name)")
    }
    
    func cardListDidRequestNewCard() {
        didRequestNewCardCalled = true
        print("➕ 模擬請求新增名片")
    }
    
    func cardListDidRequestEdit(_ card: BusinessCard) {
        didRequestEditCalled = true
        print("✏️ 模擬請求編輯名片: \(card.name)")
    }
}

// MARK: - 使用範例

extension Task33VerificationTest {
    
    /// 展示如何測試委託功能
    static func testDelegateInteractions() {
        print("🧪 測試委託互動...")
        
        let repository = ServiceContainer.shared.businessCardRepository
        let viewModel = CardListViewModel(repository: repository)
        let viewController = CardListViewController(viewModel: viewModel)
        let mockDelegate = MockCardListCoordinatorDelegate()
        
        viewController.coordinatorDelegate = mockDelegate
        
        // 模擬選中名片
        if let firstCard = viewModel.filteredCards.first {
            viewController.coordinatorDelegate?.cardListDidSelectCard(firstCard)
            assert(mockDelegate.didSelectCardCalled, "❌ 選中名片委託未調用")
        }
        
        // 模擬請求新增
        viewController.coordinatorDelegate?.cardListDidRequestNewCard()
        assert(mockDelegate.didRequestNewCardCalled, "❌ 新增名片委託未調用")
        
        print("✅ 委託互動測試通過")
    }
    
    /// 測試刪除同步性（解決 TableView 錯誤）
    static func testDeleteSynchronization() {
        print("🔄 測試刪除同步性...")
        
        let repository = ServiceContainer.shared.businessCardRepository
        let viewModel = CardListViewModel(repository: repository)
        let viewController = CardListViewController(viewModel: viewModel)
        
        viewController.loadViewIfNeeded()
        viewController.viewDidLoad()
        
        // 等待初始資料載入和 Combine 管道初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 確保搜尋狀態已清除，避免前面測試的影響
            viewModel.updateSearchText("")
            Thread.sleep(forTimeInterval: 0.2) // 等待 Combine 更新
            
            let originalCount = viewModel.filteredCards.count
            print("🔄 刪除測試開始 - cards: \(viewModel.cards.count), filteredCards: \(originalCount)")
            assert(originalCount > 0, "❌ 沒有測試資料")
            assert(viewModel.filteredCards.count == viewModel.cards.count, "❌ 搜尋狀態未正確清除")
            
            // 模擬刪除第一個項目
            let indexPath = IndexPath(row: 0, section: 0)
            let cardToDelete = viewModel.filteredCards[indexPath.row]
            print("🔄 準備刪除卡片: \(cardToDelete.name), 索引: \(indexPath.row)")
            
            // 執行刪除
            viewModel.deleteCard(at: indexPath.row)
            
            // 檢查資料立即更新（現在是同步的）
            let newCount = viewModel.filteredCards.count
            print("🔄 刪除後 - cards: \(viewModel.cards.count), filteredCards: \(newCount), 期望: \(originalCount - 1)")
            assert(newCount == originalCount - 1, "❌ 刪除後資料計數錯誤")
            
            // 檢查該卡片確實被移除
            let stillExists = viewModel.filteredCards.contains { $0.id == cardToDelete.id }
            assert(!stillExists, "❌ 卡片仍然存在於列表中")
            
            print("✅ 刪除同步性測試通過")
        }
    }
    
    /// 可靠的搜尋功能測試（直接驗證結果）
    private static func testSearchFunctionality(viewModel: CardListViewModel) {
        print("🔍 測試搜尋功能（直接驗證結果）...")
        
        let originalCount = viewModel.filteredCards.count
        print("🔍 測試開始 - 當前filteredCards數量: \(originalCount)")
        
        // 第一階段：測試搜尋過濾
        print("🔍 執行搜尋: '張志明'")
        viewModel.updateSearchText("張志明")
        
        // 給予足夠時間讓 Combine 管道處理
        Thread.sleep(forTimeInterval: 0.1)
        
        let filteredCount = viewModel.filteredCards.count
        print("🔍 搜尋結果 - 原始: \(originalCount), 過濾後: \(filteredCount)")
        assert(filteredCount <= originalCount, "❌ 搜尋過濾功能異常")
        assert(filteredCount > 0, "❌ 搜尋應該找到'張志明'相關結果")
        
        // 第二階段：測試搜尋清除
        print("🔍 清除搜尋")
        viewModel.updateSearchText("")
        
        // 給予足夠時間讓 Combine 管道處理
        Thread.sleep(forTimeInterval: 0.1)
        
        let finalCount = viewModel.filteredCards.count
        print("🔍 清除搜尋結果 - 原始: \(originalCount), 清除後: \(finalCount)")
        assert(finalCount == originalCount, "❌ 搜尋清除功能異常 - 預期: \(originalCount), 實際: \(finalCount)")
        
        print("✅ 搜尋功能測試通過")
    }
}