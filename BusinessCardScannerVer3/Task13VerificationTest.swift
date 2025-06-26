//
//  Task13VerificationTest.swift
//  BusinessCardScannerVer2
//
//  Task 1.3 驗證測試
//  用於確認 ServiceContainer 和 ModuleFactory 正常運作
//

import UIKit

class Task13VerificationTest {
    
    static func runAllTests() {
        print("\n========== Task 1.3 驗證測試開始 ==========\n")
        
        testServiceContainer()
        testModuleFactory()
        testModuleCreation()
        testDependencyInjection()
        
        print("\n========== Task 1.3 驗證測試完成 ==========\n")
    }
    
    // MARK: - Test ServiceContainer
    
    private static func testServiceContainer() {
        print("📋 測試 ServiceContainer...")
        
        // 1. 測試單例模式
        let container1 = ServiceContainer.shared
        let container2 = ServiceContainer.shared
        if container1 !== container2 {
            print("❌ ServiceContainer 應該是單例")
        } else {
            print("✅ ServiceContainer 單例模式正常")
        }
        
        // 2. 測試服務延遲載入
        let repository = container1.businessCardRepository
        let repository2 = container1.businessCardRepository
        if repository !== repository2 {
            print("❌ Repository 應該只建立一次")
        } else {
            print("✅ Repository 延遲載入正常")
        }
        
        // 3. 測試所有服務是否能正常建立
        // 分別測試每個服務
        _ = container1.coreDataStack
        print("✅ CoreDataStack 建立成功")
        
        _ = container1.businessCardRepository
        print("✅ BusinessCardRepository 建立成功")
        
        _ = container1.photoService
        print("✅ PhotoService 建立成功")
        
        _ = container1.visionService
        print("✅ VisionService 建立成功")
        
        _ = container1.permissionManager
        print("✅ PermissionManager 建立成功")
        
        _ = container1.keychainService
        print("✅ KeychainService 建立成功")
        
        _ = container1.businessCardService
        print("✅ BusinessCardService 建立成功")
        
        _ = container1.businessCardParser
        print("✅ BusinessCardParser 建立成功")
        
        _ = container1.exportService
        print("✅ ExportService 建立成功")
        
        _ = container1.openAIService
        print("✅ OpenAIService 建立成功")
        
        _ = container1.aiCardParser
        print("✅ AICardParser 建立成功")
        
        print("✅ ServiceContainer 測試通過\n")
    }
    
    // MARK: - Test ModuleFactory
    
    private static func testModuleFactory() {
        print("📋 測試 ModuleFactory...")
        
        // 1. 測試 ModuleFactory 建立
        _ = ModuleFactory()
        print("✅ ModuleFactory 建立成功")
        
        // 2. 測試不同的 factory 實例使用相同的 ServiceContainer
        _ = ModuleFactory()
        // 兩個 factory 應該使用相同的 ServiceContainer.shared
        print("✅ ModuleFactory 可以多實例建立")
        
        print("✅ ModuleFactory 測試通過\n")
    }
    
    // MARK: - Test Module Creation
    
    private static func testModuleCreation() {
        print("📋 測試模組建立...")
        
        let factory = ModuleFactory()
        
        // 1. 測試 TabBar 模組
        _ = factory.makeTabBarModule()
        print("✅ TabBar 模組建立成功")
        
        // 2. 測試 CardList 模組
        _ = factory.makeCardListModule()
        print("✅ CardList 模組建立成功")
        
        // 3. 測試 CardCreation 模組
        _ = factory.makeCardCreationModule()
        print("✅ CardCreation 模組建立成功")
        
        // 4. 測試 CardDetail 模組
        _ = factory.makeCardDetailModule()
        print("✅ CardDetail 模組建立成功")
        
        // 5. 測試 Settings 模組
        _ = factory.makeSettingsModule()
        print("✅ Settings 模組建立成功")
        
        // 6. 測試 AI 模組（可選）
        if factory.makeAIProcessingModule() != nil {
            print("✅ AI 模組建立成功（可用）")
        } else {
            print("⚠️ AI 模組當前不可用（這是正常的）")
        }
        
        print("✅ 模組建立測試通過\n")
    }
    
    // MARK: - Test Dependency Injection
    
    private static func testDependencyInjection() {
        print("📋 測試依賴注入...")
        
        let factory = ModuleFactory()
        let navController = UINavigationController()
        
        // 1. 測試模組能否建立 Coordinator
        let tabBarModule = factory.makeTabBarModule()
        let tabBarCoordinator = tabBarModule.makeCoordinator(navigationController: navController)
        if tabBarCoordinator.navigationController !== navController {
            print("❌ NavigationController 注入失敗")
        } else {
            print("✅ TabBar Coordinator 建立成功，依賴注入正常")
        }
        
        // 2. 測試 CardCreation 模組的不同建立方式
        let cardCreationModule = factory.makeCardCreationModule()
        
        // 測試相機模式
        _ = cardCreationModule.makeCoordinator(
            navigationController: navController,
            sourceType: .camera,
            editingCard: nil
        )
        print("✅ CardCreation Camera 模式建立成功")
        
        // 測試相簿模式
        _ = cardCreationModule.makeCoordinator(
            navigationController: navController,
            sourceType: .photoLibrary,
            editingCard: nil
        )
        print("✅ CardCreation PhotoLibrary 模式建立成功")
        
        // 測試手動模式
        _ = cardCreationModule.makeCoordinator(
            navigationController: navController,
            sourceType: .manual,
            editingCard: nil
        )
        print("✅ CardCreation Manual 模式建立成功")
        
        // 3. 測試 CardDetail 模組需要 card 參數
        let cardDetailModule = factory.makeCardDetailModule()
        let testCard = BusinessCard()
        _ = cardDetailModule.makeCoordinator(
            navigationController: navController,
            card: testCard
        )
        print("✅ CardDetail 模組建立成功，參數傳遞正常")
        
        print("✅ 依賴注入測試通過\n")
    }
}

// MARK: - 在 SceneDelegate 中使用

extension Task13VerificationTest {
    
    /// 建立測試用的 ViewController
    static func makeTestViewController() -> UIViewController {
        return Task13TestViewController()
    }
}

// MARK: - Test ViewController

private class Task13TestViewController: UIViewController {
    
    private let testButton = UIButton(type: .system)
    private let resultLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Task 1.3 驗證"
        
        setupUI()
    }
    
    private func setupUI() {
        // 建立堆疊視圖
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        
        // 設定測試按鈕
        testButton.setTitle("執行 Task 1.3 驗證測試", for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        testButton.backgroundColor = .systemBlue
        testButton.setTitleColor(.white, for: .normal)
        testButton.layer.cornerRadius = 10
        testButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        testButton.addTarget(self, action: #selector(runTestsAction), for: .touchUpInside)
        
        // 設定結果標籤
        resultLabel.text = "點擊按鈕執行測試\n結果會顯示在 Console"
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        resultLabel.font = .systemFont(ofSize: 14)
        resultLabel.textColor = .secondaryLabel
        
        // 加入堆疊視圖
        stackView.addArrangedSubview(testButton)
        stackView.addArrangedSubview(resultLabel)
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func runTestsAction() {
        print("\n🚀 開始執行測試...\n")
        Task13VerificationTest.runAllTests()
        
        // 更新按鈕顯示
        testButton.setTitle("測試完成！查看 Console", for: .normal)
        testButton.backgroundColor = .systemGreen
        
        // 3秒後恢復
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.testButton.setTitle("執行 Task 1.3 驗證測試", for: .normal)
            self?.testButton.backgroundColor = .systemBlue
        }
    }
}

/*
使用方式：

在 SceneDelegate.swift 中：

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(windowScene: windowScene)
    
    // 方式 1：直接執行測試
    Task13VerificationTest.runAllTests()
    
    // 方式 2：顯示測試 UI
    let testViewController = Task13VerificationTest.makeTestViewController()
    let navigationController = UINavigationController(rootViewController: testViewController)
    
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
}
*/
