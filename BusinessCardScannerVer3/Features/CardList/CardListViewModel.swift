//
//  CardListViewModel.swift
//  BusinessCardScannerVer3
//
//  名片列表視圖模型
//

import Foundation
import Combine

class CardListViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    /// 所有名片資料
    @Published var cards: [BusinessCard] = []
    
    /// 過濾後的名片資料
    @Published var filteredCards: [BusinessCard] = []
    
    /// 搜尋文字
    @Published var searchText: String = ""
    
    // isLoading 繼承自 BaseViewModel，不需要重新宣告
    
    /// 是否應該顯示空狀態視圖 (考慮載入和錯誤狀態)
    @Published var shouldShowEmptyState: Bool = false
    
    // MARK: - Private Properties
    
    private let repository: BusinessCardRepository
    
    // MARK: - Initialization
    
    init(repository: BusinessCardRepository) {
        self.repository = repository
        super.init()
        
        setupBindings()
        loadCards() // 載入真實資料
    }
    
    // MARK: - Setup
    
    override func setupBindings() {
        // 監聽卡片資料變化，計算過濾結果
        // 移除 debounce，因為 ViewController 已經有 300ms debounce
        // 直接響應可避免測試中的時序問題
        Publishers.CombineLatest($cards, $searchText)
            .map { [weak self] cards, searchText in
                self?.filterCards(cards, with: searchText) ?? []
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$filteredCards)
        
        // 計算是否應該顯示空狀態：必須同時滿足 (!isLoading && !hasError && filteredCards.isEmpty)
        Publishers.CombineLatest3($isLoading, hasErrorPublisher, $filteredCards)
            .map(calculateEmptyState)
            .receive(on: DispatchQueue.main)
            .assign(to: &$shouldShowEmptyState)
        
        // 監聽資料清除通知 - 遵循 MVVM+C 架構的響應式數據流
        NotificationCenter.default.publisher(for: .businessCardDataDidClear)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("📢 CardListViewModel: 收到資料清除通知，清空本地資料")
                self?.cards = []
                // 清空搜尋文字，確保 UI 狀態一致
                self?.searchText = ""
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 載入名片資料（從資料庫）
    func loadCards() {
        startLoading() // 使用 BaseViewModel 的載入狀態管理
        
        repository.fetchAll()
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.stopLoading()
                        if case .failure(let error) = completion {
                            print("❌ 載入名片失敗: \(error.localizedDescription)")
                            self?.handleError(error)
                        } else {
                            self?.clearError()
                        }
                    }
                },
                receiveValue: { [weak self] cards in
                    DispatchQueue.main.async {
                        self?.cards = cards
                        print("✅ 已從 Repository 載入 \(cards.count) 筆名片資料")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 更新搜尋文字
    /// - Parameter text: 搜尋關鍵字
    func updateSearchText(_ text: String) {
        searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 刪除名片
    /// - Parameter card: 要刪除的名片
    func deleteCard(_ card: BusinessCard) {
        // 1. 立即從記憶體陣列中移除，讓 UI 馬上更新
        cards.removeAll { $0.id == card.id }
        
        // 立即同步更新 filteredCards，避免 TableView 崩潰
        filteredCards.removeAll { $0.id == card.id }
        
        // 2. 執行資料庫刪除（使用 Combine）
        repository.delete(card)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        // 刪除失敗時恢復資料並提示錯誤
                        print("❌ 刪除名片失敗: \(error.localizedDescription)")
                        // 重新載入資料以恢復正確狀態
                        DispatchQueue.main.async {
                            self?.loadCards()
                            // 可以在這裡添加錯誤提示給使用者
                        }
                    }
                },
                receiveValue: { _ in
                    // 3. 刪除成功後，刪除對應的照片檔案
                    if let photoPath = card.photoPath {
                        let photoService = ServiceContainer.shared.photoService
                        _ = photoService.deletePhoto(path: photoPath)
                        print("🗑️ 已刪除照片: \(photoPath)")
                    }
                    print("✅ 已成功刪除名片: \(card.name)")
                }
            )
            .store(in: &cancellables)
    }
    
    /// 刪除指定索引的名片（用於滑動刪除）
    /// - Parameter index: filteredCards 中的索引
    func deleteCard(at index: Int) {
        guard index >= 0 && index < filteredCards.count else { 
            print("⚠️ 刪除失敗：索引越界 (\(index))")
            return 
        }
        let cardToDelete = filteredCards[index]
        deleteCard(cardToDelete)
    }
    
    /// 重新載入資料（用於下拉刷新）
    func reloadData() {
        print("🔄 執行下拉刷新重新載入資料")
        
        // 修復：下拉刷新應該重新從資料庫載入，而不是生成 mock 資料
        // 這樣可以確保顯示用戶最新儲存的資料
        loadCards()
    }
    
    /// 處理新增名片請求
    /// - Note: 這個方法會被 ViewController 呼叫，通知 Coordinator 顯示新增選項
    func handleAddCard() {
        // ViewModel 本身不處理導航，直接通知 Coordinator
        print("📝 使用者請求新增名片")
    }
    
    // MARK: - Private Methods
    
    /// 計算空狀態顯示邏輯（可測試的純函數）
    /// - Parameters:
    ///   - isLoading: 是否正在載入
    ///   - hasError: 是否有錯誤
    ///   - filteredCards: 過濾後的名片陣列
    /// - Returns: 是否應該顯示空狀態
    private func calculateEmptyState(isLoading: Bool, hasError: Bool, filteredCards: [BusinessCard]) -> Bool {
        return !isLoading && !hasError && filteredCards.isEmpty
    }
    
    /// 過濾名片資料
    /// - Parameters:
    ///   - cards: 原始名片陣列
    ///   - searchText: 搜尋關鍵字
    /// - Returns: 過濾後的名片陣列
    private func filterCards(_ cards: [BusinessCard], with searchText: String) -> [BusinessCard] {
        guard !searchText.isEmpty else { return cards }
        
        let lowercasedSearchText = searchText.lowercased()
        
        return cards.filter { card in
            // 搜尋姓名
            if card.name.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            // 搜尋公司
            if let company = card.company, company.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            // 搜尋職稱
            if let jobTitle = card.jobTitle, jobTitle.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            // 搜尋電話
            if let phone = card.phone, phone.contains(searchText) {
                return true
            }
            
            // 搜尋手機
            if let mobile = card.mobile, mobile.contains(searchText) {
                return true
            }
            
            // 搜尋 Email
            if let email = card.email, email.lowercased().contains(lowercasedSearchText) {
                return true
            }
            
            return false
        }
    }
    
}

// MARK: - Mock Data Helpers (Debug Only)

#if DEBUG
extension CardListViewModel {
    
    // MARK: - Testing Helpers
    
    /// 測試專用狀態重置
    func resetForTesting() {
        cards = []
        searchText = ""
        isLoading = false
        error = nil
    }
    
    /// 測試專用狀態設定
    func setTestState(cards: [BusinessCard], isLoading: Bool = false, error: Error? = nil) {
        self.cards = cards
        self.isLoading = isLoading
        self.error = error
    }
    
    /// 暴露私有方法供測試使用
    func testCalculateEmptyState(isLoading: Bool, hasError: Bool, filteredCards: [BusinessCard]) -> Bool {
        return calculateEmptyState(isLoading: isLoading, hasError: hasError, filteredCards: filteredCards)
    }
    
    /// 暴露私有方法供測試使用
    func testFilterCards(_ cards: [BusinessCard], with searchText: String) -> [BusinessCard] {
        return filterCards(cards, with: searchText)
    }
    
    /// 清除所有資料（測試用）
    func clearAllData() {
        cards.removeAll()
    }
    
    
    /// 添加單筆測試資料（測試用）
    func addMockCard() {
        let newCard = BusinessCard(
            id: UUID(),
            name: "測試使用者 \(cards.count + 1)",
            jobTitle: "測試職稱",
            company: "測試公司",
            email: "test\(cards.count + 1)@example.com",
            mobile: "09\(String(format: "%02d", cards.count + 1))-000-000",
            createdAt: Date(),
            updatedAt: Date(),
            parseSource: "manual"
        )
        
        cards.append(newCard)
    }
}
#endif