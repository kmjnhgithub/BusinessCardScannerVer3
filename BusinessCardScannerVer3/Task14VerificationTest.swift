//
//  Task14VerificationTest.swift
//  BusinessCardScanner
//
//  Task 1.4 驗證測試
//  用於確認 Core Data 設定正常運作
//

import UIKit
import Combine

class Task14VerificationTest {
    
    private static var cancellables = Set<AnyCancellable>()
    
    static func runAllTests() {
        print("\n========== Task 1.4 驗證測試開始 ==========\n")
        
        // 清空訂閱
        cancellables.removeAll()
        
        // 執行測試
        testCoreDataStack()
        testBusinessCardRepository()
        
        print("\n========== Task 1.4 驗證測試進行中（非同步） ==========")
        print("請查看 Console 輸出以了解測試結果\n")
    }
    
    // MARK: - Test CoreDataStack
    
    private static func testCoreDataStack() {
        print("📋 測試 CoreDataStack...")
        
        let coreDataStack = ServiceContainer.shared.coreDataStack
        
        // 1. 測試 viewContext
        let viewContext = coreDataStack.viewContext
        if viewContext.concurrencyType == .mainQueueConcurrencyType {
            print("✅ ViewContext 在主線程")
        } else {
            print("❌ ViewContext 應該在主線程")
        }
        
        // 2. 測試 backgroundContext
        let backgroundContext = coreDataStack.newBackgroundContext()
        if backgroundContext.concurrencyType == .privateQueueConcurrencyType {
            print("✅ BackgroundContext 在背景線程")
        } else {
            print("❌ BackgroundContext 應該在背景線程")
        }
        
        // 3. 測試統計功能
        #if DEBUG
        coreDataStack.printStatistics()
        #endif
        
        print("✅ CoreDataStack 基本測試通過\n")
    }
    
    // MARK: - Test BusinessCardRepository
    
    private static func testBusinessCardRepository() {
        print("📋 測試 BusinessCardRepository...")
        
        let repository = ServiceContainer.shared.businessCardRepository
        
        // 測試流程：Create -> Read -> Update -> Search -> Delete
        testCreateCard(repository: repository)
    }
    
    // MARK: - CRUD Tests
    
    private static func testCreateCard(repository: BusinessCardRepository) {
        print("\n1️⃣ 測試建立名片...")
        
        // 建立測試資料
        var testCard = BusinessCard()
        testCard.name = "測試用戶 \(Date().timeIntervalSince1970)"
        testCard.company = "測試公司"
        testCard.jobTitle = "iOS 工程師"
        testCard.email = "test@example.com"
        testCard.phone = "02-12345678"
        testCard.mobile = "0912-345678"
        
        repository.create(testCard)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 建立失敗: \(error)")
                    }
                },
                receiveValue: { createdCard in
                    print("✅ 建立成功:")
                    print("   ID: \(createdCard.id)")
                    print("   姓名: \(createdCard.name)")
                    print("   公司: \(createdCard.company ?? "")")
                    
                    // 繼續測試讀取
                    testFetchAll(repository: repository, expectedId: createdCard.id)
                }
            )
            .store(in: &cancellables)
    }
    
    private static func testFetchAll(repository: BusinessCardRepository, expectedId: UUID) {
        print("\n2️⃣ 測試讀取所有名片...")
        
        repository.fetchAll()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 讀取失敗: \(error)")
                    }
                },
                receiveValue: { cards in
                    print("✅ 讀取成功，共 \(cards.count) 張名片")
                    
                    if let foundCard = cards.first(where: { $0.id == expectedId }) {
                        print("✅ 找到剛建立的名片")
                        
                        // 繼續測試更新
                        testUpdateCard(repository: repository, card: foundCard)
                    } else {
                        print("❌ 找不到剛建立的名片")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private static func testUpdateCard(repository: BusinessCardRepository, card: BusinessCard) {
        print("\n3️⃣ 測試更新名片...")
        
        var updatedCard = card
        updatedCard.jobTitle = "資深 iOS 工程師"
        updatedCard.memo = "已更新於 \(Date())"
        
        repository.update(updatedCard)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 更新失敗: \(error)")
                    }
                },
                receiveValue: { resultCard in
                    print("✅ 更新成功:")
                    print("   職稱: \(resultCard.jobTitle ?? "")")
                    print("   備註: \(resultCard.memo ?? "")")
                    
                    // 繼續測試搜尋
                    testSearchCard(repository: repository, keyword: card.name)
                }
            )
            .store(in: &cancellables)
    }
    
    private static func testSearchCard(repository: BusinessCardRepository, keyword: String) {
        print("\n4️⃣ 測試搜尋功能...")
        print("   搜尋關鍵字: \(keyword)")
        
        repository.search(keyword: keyword)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 搜尋失敗: \(error)")
                    }
                },
                receiveValue: { cards in
                    print("✅ 搜尋成功，找到 \(cards.count) 筆結果")
                    
                    if let firstCard = cards.first {
                        print("   第一筆: \(firstCard.name)")
                        
                        // 繼續測試刪除
                        testDeleteCard(repository: repository, card: firstCard)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private static func testDeleteCard(repository: BusinessCardRepository, card: BusinessCard) {
        print("\n5️⃣ 測試刪除名片...")
        
        repository.delete(card)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 刪除失敗: \(error)")
                    }
                },
                receiveValue: { _ in
                    print("✅ 刪除成功")
                    
                    // 驗證刪除
                    verifyDeletion(repository: repository, id: card.id)
                }
            )
            .store(in: &cancellables)
    }
    
    private static func verifyDeletion(repository: BusinessCardRepository, id: UUID) {
        print("\n6️⃣ 驗證刪除結果...")
        
        repository.exists(id: id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ 驗證失敗: \(error)")
                    }
                },
                receiveValue: { exists in
                    if exists {
                        print("❌ 名片仍然存在，刪除失敗")
                    } else {
                        print("✅ 名片已刪除")
                    }
                    
                    // 測試其他功能
                    testAdditionalFeatures(repository: repository)
                }
            )
            .store(in: &cancellables)
    }
    
    private static func testAdditionalFeatures(repository: BusinessCardRepository) {
        print("\n7️⃣ 測試其他功能...")
        
        // 測試計數
        repository.count()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { count in
                    print("✅ 目前共有 \(count) 張名片")
                }
            )
            .store(in: &cancellables)
        
        // 測試最近建立
        repository.fetchRecent(limit: 5)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { cards in
                    print("✅ 最近建立的 \(cards.count) 張名片")
                }
            )
            .store(in: &cancellables)
        
        // 測試分頁
        repository.fetchPaged(page: 0, pageSize: 10)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { pagedResult in
                    print("✅ 分頁測試: 第 \(pagedResult.page + 1) 頁，共 \(pagedResult.totalPages) 頁")
                }
            )
            .store(in: &cancellables)
        
        print("\n✅ BusinessCardRepository 測試完成")
    }
}

// MARK: - Test ViewController

class Task14TestViewController: UIViewController {
    
    private let runTestButton = UIButton(type: .system)
    private let createSampleButton = UIButton(type: .system)
    private let clearDataButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Task 1.4 Core Data 測試"
        
        setupUI()
    }
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        
        // 執行測試按鈕
        runTestButton.setTitle("執行 CRUD 測試", for: .normal)
        runTestButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        runTestButton.backgroundColor = .systemBlue
        runTestButton.setTitleColor(.white, for: .normal)
        runTestButton.layer.cornerRadius = 10
        runTestButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        runTestButton.addTarget(self, action: #selector(runTests), for: .touchUpInside)
        
        // 建立範例資料按鈕
        createSampleButton.setTitle("建立 10 筆範例資料", for: .normal)
        createSampleButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        createSampleButton.backgroundColor = .systemGreen
        createSampleButton.setTitleColor(.white, for: .normal)
        createSampleButton.layer.cornerRadius = 10
        createSampleButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        createSampleButton.addTarget(self, action: #selector(createSampleData), for: .touchUpInside)
        
        // 清除資料按鈕
        clearDataButton.setTitle("清除所有資料", for: .normal)
        clearDataButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        clearDataButton.backgroundColor = .systemRed
        clearDataButton.setTitleColor(.white, for: .normal)
        clearDataButton.layer.cornerRadius = 10
        clearDataButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        clearDataButton.addTarget(self, action: #selector(clearAllData), for: .touchUpInside)
        
        // 狀態標籤
        statusLabel.text = "點擊按鈕開始測試"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        
        // 加入堆疊視圖
        stackView.addArrangedSubview(runTestButton)
        stackView.addArrangedSubview(createSampleButton)
        stackView.addArrangedSubview(clearDataButton)
        stackView.addArrangedSubview(statusLabel)
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func runTests() {
        statusLabel.text = "測試執行中...\n請查看 Console"
        Task14VerificationTest.runAllTests()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.updateStatus()
        }
    }
    
    @objc private func createSampleData() {
        statusLabel.text = "建立範例資料中..."
        
        let repository = ServiceContainer.shared.businessCardRepository
        var cards: [BusinessCard] = []
        
        // 建立範例資料
        let sampleData = [
            ("張三", "ABC 科技", "工程師", "zhang@abc.com", "02-12345678"),
            ("李四", "XYZ 公司", "經理", "li@xyz.com", "03-87654321"),
            ("王五", "123 企業", "總監", "wang@123.com", "04-11223344"),
            ("陳六", "創新科技", "設計師", "chen@innovation.com", "02-99887766"),
            ("林七", "未來公司", "行銷", "lin@future.com", "03-55443322"),
            ("黃八", "智慧產業", "業務", "huang@smart.com", "04-66778899"),
            ("吳九", "數位時代", "分析師", "wu@digital.com", "02-33445566"),
            ("劉十", "雲端服務", "架構師", "liu@cloud.com", "03-77889900"),
            ("楊一", "行動科技", "產品經理", "yang@mobile.com", "04-22334455"),
            ("趙二", "新創團隊", "執行長", "zhao@startup.com", "02-88776655")
        ]
        
        for (name, company, title, email, phone) in sampleData {
            var card = BusinessCard()
            card.name = name
            card.company = company
            card.jobTitle = title
            card.email = email
            card.phone = phone
            card.mobile = "0912-\(Int.random(in: 100000...999999))"
            cards.append(card)
        }
        
        repository.createMultiple(cards)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.statusLabel.text = "建立失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] createdCards in
                    self?.statusLabel.text = "成功建立 \(createdCards.count) 筆資料"
                    self?.updateStatus()
                }
            )
            .store(in: &cancellables)
    }
    
    @objc private func clearAllData() {
        let alert = UIAlertController(
            title: "確認清除",
            message: "確定要清除所有名片資料嗎？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清除", style: .destructive) { [weak self] _ in
            self?.performClearData()
        })
        
        present(alert, animated: true)
    }
    
    private func performClearData() {
        statusLabel.text = "清除資料中..."
        
        let repository = ServiceContainer.shared.businessCardRepository
        repository.deleteAll()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.statusLabel.text = "清除失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.statusLabel.text = "已清除所有資料"
                    self?.updateStatus()
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateStatus() {
        let repository = ServiceContainer.shared.businessCardRepository
        repository.count()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] count in
                    self?.statusLabel.text = "目前資料庫有 \(count) 張名片"
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - 使用方式

extension Task14VerificationTest {
    
    /// 建立測試用的 ViewController
    static func makeTestViewController() -> UIViewController {
        return Task14TestViewController()
    }
}

/*
使用方式：

在 SceneDelegate.swift 中：

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(windowScene: windowScene)
    
    // 方式 1：直接執行測試
    Task14VerificationTest.runAllTests()
    
    // 方式 2：顯示測試 UI
    let testViewController = Task14VerificationTest.makeTestViewController()
    let navigationController = UINavigationController(rootViewController: testViewController)
    
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
}
*/
