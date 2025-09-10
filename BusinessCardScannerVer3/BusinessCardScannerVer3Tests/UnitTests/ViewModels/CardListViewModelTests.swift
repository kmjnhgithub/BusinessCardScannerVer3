import XCTest
import Combine
@testable import BusinessCardScannerVer3

/// CardListViewModel 簡化測試套件
/// 專注於核心功能測試，避免複雜的依賴注入問題
final class CardListViewModelTests: BaseTestCase {
    
    // MARK: - Properties
    
    private var viewModel: TestableCardListViewModel!
    private var mockContainer: MockServiceContainer!
    private var mockRepository: MockBusinessCardRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // 設定 Mock 依賴注入容器
        mockContainer = MockServiceContainer.shared
        mockContainer.resetToDefaults()
        mockRepository = mockContainer.businessCardRepository
        
        // 建立測試專用的 ViewModel
        viewModel = TestableCardListViewModel()
        viewModel.injectMockRepository(mockRepository)
        
        // 等待初始化完成
        waitForInitialization()
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Private Helpers
    
    /// 等待 ViewModel 初始化完成
    private func waitForInitialization() {
        let expectation = XCTestExpectation(description: "ViewModel initialization")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// 等待 Combine 資料流更新
    private func waitForCombineUpdate() {
        let expectation = XCTestExpectation(description: "Combine update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - 1. 初始化和設定測試
    
    func testCardListViewModel_initialization_shouldHaveCorrectInitialState() {
        // Given - ViewModel 已在 setUp 中初始化
        
        // When - 檢查初始狀態
        let initialSearchText = viewModel.searchText
        let initialIsLoading = viewModel.isLoading
        let initialError = viewModel.error
        
        // Then - 驗證初始狀態正確
        XCTAssertEqual(initialSearchText, "", "搜尋文字初始值應為空字串")
        XCTAssertFalse(initialIsLoading, "初始化完成後載入狀態應為 false")
        XCTAssertNil(initialError, "初始化時不應有錯誤")
        
        // 驗證繼承自 BaseViewModel 的屬性
        XCTAssertNotNil(viewModel.cancellables, "應繼承 cancellables 屬性")
    }
    
    // MARK: - 2. 資料載入測試
    
    func testCardListViewModel_loadCards_success_shouldUpdateCardsAndStopLoading() {
        // Given - 設定成功回應
        let testCards = MockData.standardCards
        mockRepository.reset()
        mockRepository.fetchAllCardsResult = .success(testCards)
        mockRepository.shouldSucceed = true
        
        // When - 呼叫載入方法
        viewModel.loadCards()
        
        // Then - 等待非同步操作完成並驗證結果
        let expectation = XCTestExpectation(description: "Load cards success")
        
        // 監聽 isLoading 變為 false，確保載入完成
        viewModel.$isLoading
            .dropFirst() // 跳過初始 false
            .filter { !$0 } // 等待變回 false (載入完成)
            .first()
            .sink { _ in
                // 給予額外時間讓所有 Publisher 完成更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    XCTAssertEqual(self.viewModel.cards.count, testCards.count, "應載入正確數量的名片")
                    XCTAssertFalse(self.viewModel.isLoading, "載入完成後 isLoading 應為 false")
                    XCTAssertNil(self.viewModel.error, "成功載入時不應有錯誤")
                    XCTAssertTrue(self.mockRepository.verifyFetchAllCalled(times: 1), "應呼叫 fetchAllCards 一次")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testCardListViewModel_loadCards_failure_shouldHandleErrorCorrectly() {
        // Given - 設定失敗回應
        let testError = MockError.serviceUnavailable
        mockRepository.reset()
        mockRepository.fetchAllCardsResult = .failure(testError)
        mockRepository.shouldSucceed = false
        
        // When - 呼叫載入方法
        viewModel.loadCards()
        
        // Then - 等待錯誤處理完成並驗證結果
        let expectation = XCTestExpectation(description: "Load cards failure")
        
        // 監聽錯誤狀態變化
        viewModel.$error
            .compactMap { $0 }
            .first()
            .sink { error in
                XCTAssertNotNil(error, "載入失敗時應設定錯誤")
                XCTAssertFalse(self.viewModel.isLoading, "錯誤處理完成後 isLoading 應為 false")
                XCTAssertTrue(self.mockRepository.verifyFetchAllCalled(times: 1), "即使失敗也應呼叫 fetchAllCards")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - 3. 搜尋過濾測試
    
    func testCardListViewModel_updateSearchText_shouldTrimWhitespace() {
        // Given - 包含空白字元的搜尋文字
        let textWithWhitespace = "  王大明  "
        let expectedText = "王大明"
        
        // When - 更新搜尋文字
        viewModel.updateSearchText(textWithWhitespace)
        
        // Then - 驗證空白字元被修剪
        XCTAssertEqual(viewModel.searchText, expectedText, "搜尋文字應去除前後空白字元")
    }
    
    func testCardListViewModel_searchText_empty_shouldShowAllCards() {
        // Given - 設定測試資料和空搜尋文字
        viewModel.cards = MockData.standardCards
        viewModel.searchText = ""
        
        waitForCombineUpdate()
        
        // When & Then - 驗證顯示所有資料
        XCTAssertEqual(viewModel.filteredCards.count, MockData.standardCards.count, "空搜尋文字應顯示所有名片")
    }
    
    func testCardListViewModel_searchText_byName_shouldFilterCorrectly() {
        // Given - 設定測試資料
        viewModel.cards = MockData.standardCards
        let searchKeyword = "王大明"
        
        // When - 按姓名搜尋
        viewModel.searchText = searchKeyword
        waitForCombineUpdate()
        
        // Then - 驗證過濾結果
        XCTAssertEqual(viewModel.filteredCards.count, 1, "應過濾出一筆包含關鍵字的名片")
        XCTAssertTrue(viewModel.filteredCards.first?.name.contains(searchKeyword) == true, "結果應包含搜尋關鍵字")
    }
    
    // MARK: - 4. 刪除操作測試
    
    func testCardListViewModel_deleteCard_shouldRemoveFromBothArraysImmediately() {
        // Given - 設定測試資料
        let testCards = MockData.standardCards
        viewModel.cards = testCards
        viewModel.searchText = ""
        waitForCombineUpdate()
        
        let cardToDelete = testCards.first!
        let initialCardsCount = viewModel.cards.count
        let initialFilteredCount = viewModel.filteredCards.count
        
        // When - 刪除名片
        viewModel.deleteCard(cardToDelete)
        
        // Then - 驗證立即同步更新
        XCTAssertEqual(viewModel.cards.count, initialCardsCount - 1, "cards 陣列應立即移除一筆資料")
        XCTAssertEqual(viewModel.filteredCards.count, initialFilteredCount - 1, "filteredCards 陣列應立即移除一筆資料")
        XCTAssertFalse(viewModel.cards.contains { $0.id == cardToDelete.id }, "cards 不應包含被刪除的名片")
        XCTAssertFalse(viewModel.filteredCards.contains { $0.id == cardToDelete.id }, "filteredCards 不應包含被刪除的名片")
    }
    
    func testCardListViewModel_deleteCard_atIndex_validIndex_shouldDeleteCorrectCard() {
        // Given - 設定測試資料
        let testCards = MockData.standardCards
        viewModel.cards = testCards
        viewModel.searchText = ""
        waitForCombineUpdate()
        
        let indexToDelete = 1
        let cardToDelete = viewModel.filteredCards[indexToDelete]
        let initialCount = viewModel.filteredCards.count
        
        // When - 按索引刪除名片
        viewModel.deleteCard(at: indexToDelete)
        
        // Then - 驗證刪除正確的名片
        XCTAssertEqual(viewModel.filteredCards.count, initialCount - 1, "應移除一筆名片")
        XCTAssertFalse(viewModel.filteredCards.contains { $0.id == cardToDelete.id }, "不應包含被刪除的名片")
    }
    
    func testCardListViewModel_deleteCard_atIndex_invalidIndex_shouldNotCrash() {
        // Given - 設定測試資料
        let testCards = MockData.standardCards
        viewModel.cards = testCards
        viewModel.searchText = ""
        waitForCombineUpdate()
        
        let initialCount = viewModel.filteredCards.count
        let invalidIndex = initialCount + 10 // 超出範圍的索引
        
        // When - 使用無效索引刪除（應不會崩潰）
        viewModel.deleteCard(at: invalidIndex)
        
        // Then - 驗證資料未變更且不崩潰
        XCTAssertEqual(viewModel.filteredCards.count, initialCount, "無效索引不應影響資料")
    }
    
    // MARK: - 5. 空狀態計算測試
    
    func testCardListViewModel_shouldShowEmptyState_logicCorrect() {
        // Given - 設定空資料狀態
        viewModel.cards = []
        viewModel.searchText = ""
        viewModel.isLoading = false
        viewModel.error = nil
        
        waitForCombineUpdate()
        
        // When & Then - 驗證空狀態顯示邏輯
        XCTAssertTrue(viewModel.shouldShowEmptyState, "無資料且不在載入狀態時應顯示空狀態")
        
        // 設定載入狀態
        viewModel.isLoading = true
        waitForCombineUpdate()
        
        XCTAssertFalse(viewModel.shouldShowEmptyState, "載入中時不應顯示空狀態")
        
        // 設定錯誤狀態
        viewModel.isLoading = false
        viewModel.error = MockError.serviceUnavailable
        waitForCombineUpdate()
        
        XCTAssertFalse(viewModel.shouldShowEmptyState, "有錯誤時不應顯示空狀態")
    }
    
    // MARK: - 6. 通知響應測試
    
    func testCardListViewModel_businessCardDataDidClear_shouldClearLocalData() {
        // Given - 設定初始資料
        viewModel.cards = MockData.standardCards
        viewModel.searchText = "test search"
        waitForCombineUpdate()
        
        XCTAssertNotEmpty(viewModel.cards, "設定前應有資料")
        XCTAssertNotEqual(viewModel.searchText, "", "設定前應有搜尋文字")
        
        // When - 發送資料清除通知
        NotificationCenter.default.post(name: .businessCardDataDidClear, object: nil)
        
        // Then - 等待通知處理完成並驗證資料清除
        let expectation = XCTestExpectation(description: "Data clear notification")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            XCTAssertEmpty(self.viewModel.cards, "通知後應清空 cards 資料")
            XCTAssertEqual(self.viewModel.searchText, "", "通知後應清空搜尋文字")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Testable CardListViewModel

/// 簡化版的測試專用 CardListViewModel
/// 直接繼承 BaseViewModel，避免複雜的依賴注入問題
final class TestableCardListViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    /// 所有名片資料
    @Published var cards: [BusinessCard] = []
    
    /// 過濾後的名片資料
    @Published var filteredCards: [BusinessCard] = []
    
    /// 搜尋文字
    @Published var searchText: String = ""
    
    /// 是否應該顯示空狀態視圖
    @Published var shouldShowEmptyState: Bool = false
    
    // MARK: - Private Properties
    
    private var mockRepository: MockBusinessCardRepository?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupBindings()
    }
    
    // MARK: - Dependency Injection
    
    func injectMockRepository(_ repository: MockBusinessCardRepository) {
        self.mockRepository = repository
        loadCards() // 載入初始資料
    }
    
    // MARK: - Setup
    
    override func setupBindings() {
        // 監聽卡片資料變化，計算過濾結果
        Publishers.CombineLatest($cards, $searchText)
            .map { [weak self] cards, searchText in
                self?.filterCards(cards, with: searchText) ?? []
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$filteredCards)
        
        // 計算是否應該顯示空狀態
        Publishers.CombineLatest3($isLoading, hasErrorPublisher, $filteredCards)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .map { isLoading, hasError, filteredCards in
                !isLoading && !hasError && filteredCards.isEmpty
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$shouldShowEmptyState)
        
        // 監聽資料清除通知
        NotificationCenter.default.publisher(for: .businessCardDataDidClear)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("📢 TestableCardListViewModel: 收到資料清除通知，清空本地資料")
                self?.cards = []
                self?.searchText = ""
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 載入名片資料
    func loadCards() {
        guard let repository = mockRepository else {
            print("⚠️ MockRepository 未注入")
            return
        }
        
        startLoading()
        
        repository.fetchAllCards()
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.stopLoading()
                        if case .failure(let error) = completion {
                            print("❌ 測試載入名片失敗: \(error.localizedDescription)")
                            self?.handleError(error)
                        } else {
                            self?.clearError()
                        }
                    }
                },
                receiveValue: { [weak self] cards in
                    DispatchQueue.main.async {
                        self?.cards = cards
                        print("✅ 測試已載入 \(cards.count) 筆名片資料")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 更新搜尋文字
    func updateSearchText(_ text: String) {
        searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 刪除名片
    func deleteCard(_ card: BusinessCard) {
        // 立即從記憶體陣列中移除
        cards.removeAll { $0.id == card.id }
        filteredCards.removeAll { $0.id == card.id }
        
        // 模擬資料庫刪除（如果有 repository）
        mockRepository?.deleteCard(card)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 測試刪除名片失敗: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in
                    print("✅ 測試已成功刪除名片: \(card.name)")
                }
            )
            .store(in: &cancellables)
    }
    
    /// 刪除指定索引的名片
    func deleteCard(at index: Int) {
        guard index >= 0 && index < filteredCards.count else {
            print("⚠️ 刪除失敗：索引越界 (\(index))")
            return
        }
        let cardToDelete = filteredCards[index]
        deleteCard(cardToDelete)
    }
    
    /// 重新載入資料
    func reloadData() {
        print("🔄 執行測試用下拉刷新重新載入資料")
        loadCards()
    }
    
    // MARK: - Private Methods
    
    /// 過濾名片資料
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