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
    
    /// 是否為空狀態
    @Published var isEmpty: Bool = true
    
    // MARK: - Private Properties
    
    private let repository: BusinessCardRepository
    
    // MARK: - Initialization
    
    init(repository: BusinessCardRepository) {
        self.repository = repository
        super.init()
        
        setupBindings()
        generateMockData() // Task 3.1 測試用假資料
    }
    
    // MARK: - Setup
    
    override func setupBindings() {
        // 監聽卡片資料變化，計算過濾結果
        Publishers.CombineLatest($cards, $searchText)
            .map { [weak self] cards, searchText in
                self?.filterCards(cards, with: searchText) ?? []
            }
            .assign(to: &$filteredCards)
        
        // 監聽過濾結果變化，更新空狀態
        $filteredCards
            .map { $0.isEmpty }
            .assign(to: &$isEmpty)
    }
    
    // MARK: - Public Methods
    
    /// 載入名片資料
    func loadCards() {
        isLoading = true
        
        // TODO: Task 3.2 實作真實的資料庫載入
        // 目前使用假資料，延遲模擬網路請求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.generateMockData()
            self?.isLoading = false
        }
    }
    
    /// 更新搜尋文字
    /// - Parameter text: 搜尋關鍵字
    func updateSearchText(_ text: String) {
        searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 刪除名片
    /// - Parameter card: 要刪除的名片
    func deleteCard(_ card: BusinessCard) {
        cards.removeAll { $0.id == card.id }
    }
    
    /// 刪除指定索引的名片
    /// - Parameter index: 索引
    func deleteCard(at index: Int) {
        guard index >= 0 && index < filteredCards.count else { return }
        let cardToDelete = filteredCards[index]
        deleteCard(cardToDelete)
    }
    
    // MARK: - Private Methods
    
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
    
    /// 生成測試用假資料
    private func generateMockData() {
        let mockCards = [
            BusinessCard(
                id: UUID(),
                name: "張志明",
                namePhonetic: "Zhang Zhiming",
                jobTitle: "資深軟體工程師",
                company: "科技創新有限公司",
                companyPhonetic: "Tech Innovation Ltd.",
                department: "產品研發部",
                email: "zhiming.zhang@techinnovation.com",
                phone: "02-2345-6789",
                mobile: "0912-345-678",
                address: "台北市信義區信義路五段7號",
                website: "https://www.techinnovation.com",
                createdAt: Date().addingTimeInterval(-86400 * 7), // 7天前
                updatedAt: Date().addingTimeInterval(-86400 * 3), // 3天前
                parseSource: "ai",
                parseConfidence: 0.95
            ),
            
            BusinessCard(
                id: UUID(),
                name: "李美慧",
                jobTitle: "行銷總監",
                company: "品牌行銷策略公司",
                department: "策略企劃部",
                email: "meihui.li@brandmarketing.com.tw",
                phone: "02-8765-4321",
                mobile: "0987-654-321",
                address: "台北市大安區敦化南路二段201號12樓",
                createdAt: Date().addingTimeInterval(-86400 * 5), // 5天前
                updatedAt: Date().addingTimeInterval(-86400 * 1), // 1天前
                parseSource: "local",
                parseConfidence: 0.82
            ),
            
            BusinessCard(
                id: UUID(),
                name: "王建國",
                namePhonetic: "David Wang",
                jobTitle: "業務經理",
                company: "國際貿易股份有限公司",
                department: "海外業務部",
                email: "david.wang@international-trade.com",
                phone: "04-2234-5678",
                mobile: "0923-456-789",
                fax: "04-2234-5679",
                address: "台中市西屯區台灣大道三段99號",
                website: "https://www.international-trade.com",
                memo: "專精亞太地區業務拓展",
                createdAt: Date().addingTimeInterval(-86400 * 3), // 3天前
                updatedAt: Date().addingTimeInterval(-86400 * 2), // 2天前
                parseSource: "ai",
                parseConfidence: 0.88
            ),
            
            BusinessCard(
                id: UUID(),
                name: "陳雅婷",
                jobTitle: "UI/UX 設計師",
                company: "數位創意設計工作室",
                email: "yating.chen@digital-creative.studio",
                mobile: "0956-789-012",
                address: "高雄市前鎮區中山二路777號8樓",
                website: "https://www.yating-design.portfolio.com",
                memo: "擅長行動應用程式介面設計",
                createdAt: Date().addingTimeInterval(-86400 * 2), // 2天前
                updatedAt: Date().addingTimeInterval(-86400 * 1), // 1天前
                parseSource: "manual"
            ),
            
            BusinessCard(
                id: UUID(),
                name: "林志偉",
                namePhonetic: "Kevin Lin",
                jobTitle: "專案經理",
                company: "系統整合科技公司",
                companyPhonetic: "System Integration Tech Co.",
                department: "專案管理部",
                email: "kevin.lin@si-tech.com.tw",
                phone: "07-321-6789",
                mobile: "0934-567-890",
                address: "高雄市苓雅區四維三路6號15樓",
                website: "https://www.si-tech.com.tw",
                createdAt: Date().addingTimeInterval(-86400 * 1), // 1天前
                updatedAt: Date(),
                parseSource: "ai",
                parseConfidence: 0.91
            ),
            
            BusinessCard(
                id: UUID(),
                name: "黃淑芬",
                jobTitle: "財務主管",
                company: "會計師事務所",
                email: "shufen.huang@accounting-firm.com",
                phone: "02-2987-6543",
                mobile: "0945-678-901",
                address: "台北市中山區南京東路三段287號6樓",
                memo: "CPA 執業會計師，專精稅務規劃",
                createdAt: Date().addingTimeInterval(-3600), // 1小時前
                updatedAt: Date(),
                parseSource: "local",
                parseConfidence: 0.76
            )
        ]
        
        // 模擬非同步載入
        self.cards = mockCards
        
        print("✅ 已載入 \(mockCards.count) 筆測試名片資料")
    }
}

// MARK: - Mock Data Helpers

extension CardListViewModel {
    
    /// 清除所有資料（測試用）
    func clearAllData() {
        cards.removeAll()
    }
    
    /// 重新生成測試資料（測試用）
    func regenerateMockData() {
        generateMockData()
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