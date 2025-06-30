//
//  Task17VerificationTest.swift
//  BusinessCardScanner
//
//  Task 1.7 UI Presenter 元件驗證測試
//  技術驗證重點：基本功能、線程安全、並發操作
//

import UIKit
import Combine

/// Task 1.7 驗證測試控制器
/// 提供 UI Presenter 基本功能驗證和技術特性測試
final class Task17VerificationTest {
    
    // MARK: - Test Execution Entry Point
    
    /// 設置測試場景
    /// - Parameter window: 應用程式主視窗
    static func setupTestScene(in window: UIWindow?) {
        guard let window = window else { return }
        
        let testViewController = PresenterTestViewController()
        let navigationController = UINavigationController(rootViewController: testViewController)
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        #if DEBUG
        print("🧪 Task 1.7 UI Presenter 測試環境已啟動")
        print("📍 測試項目：AlertPresenter、LoadingPresenter、ToastPresenter")
        print("⚡ 包含：基本功能、線程安全、並發測試")
        #endif
    }
}

// MARK: - Main Test View Controller

/// Presenter 測試視圖控制器
/// 實作 UI Presenter 基本功能驗證
final class PresenterTestViewController: BaseViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    
    // Alert 測試區
    private let alertSection = TestSectionView(title: "AlertPresenter 測試")
    
    // Loading 測試區
    private let loadingSection = TestSectionView(title: "LoadingPresenter 測試")
    
    // Toast 測試區
    private let toastSection = TestSectionView(title: "ToastPresenter 測試")
    
    // 技術驗證區
    private let technicalSection = TestSectionView(title: "技術驗證測試")
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Task 1.7 Presenter 測試"
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        view.backgroundColor = AppTheme.Colors.background
        
        // 設置滾動視圖
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        
        // 設置內容堆疊視圖
        contentStackView.axis = .vertical
        contentStackView.spacing = AppTheme.Layout.sectionPadding
        contentStackView.distribution = .fill
        
        // 組裝視圖層次
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // 添加測試區塊
        [alertSection, loadingSection, toastSection, technicalSection].forEach {
            contentStackView.addArrangedSubview($0)
        }
        
        // 設置測試按鈕
        setupAlertTests()
        setupLoadingTests()
        setupToastTests()
        setupTechnicalTests()
    }
    
    override func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView).inset(AppTheme.Layout.screenHorizontalPadding)
        }
    }
    
    // MARK: - Alert Tests Setup
    
    private func setupAlertTests() {
        alertSection.addTests([
            TestButton(title: "基本訊息") {
                AlertPresenter.shared.showMessage("這是基本訊息測試", title: "測試")
            },
            TestButton(title: "錯誤訊息") {
                let error = NSError(domain: "TestError", code: 500, 
                                   userInfo: [NSLocalizedDescriptionKey: "模擬錯誤"])
                AlertPresenter.shared.showError(error)
            },
            TestButton(title: "成功訊息（自動消失）") {
                AlertPresenter.shared.showSuccess("操作成功！2秒後自動關閉", autoDismiss: 2.0)
            },
            TestButton(title: "確認對話框") { [weak self] in
                self?.testConfirmationAlert()
            },
            TestButton(title: "選項選單") { [weak self] in
                self?.testActionSheet()
            },
            TestButton(title: "Combine Publisher") { [weak self] in
                self?.testAlertPublisher()
            }
        ])
    }
    
    // MARK: - Loading Tests Setup
    
    private func setupLoadingTests() {
        loadingSection.addTests([
            TestButton(title: "基本載入（3秒）") {
                LoadingPresenter.shared.show(message: "載入中...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    LoadingPresenter.shared.hide()
                    ToastPresenter.shared.showSuccess("載入完成")
                }
            },
            TestButton(title: "進度條載入") { [weak self] in
                self?.testProgressLoading()
            },
            TestButton(title: "訊息更新") { [weak self] in
                self?.testLoadingMessageUpdate()
            },
            TestButton(title: "Combine 自動管理") { [weak self] in
                self?.testLoadingWithCombine()
            }
        ])
    }
    
    // MARK: - Toast Tests Setup
    
    private func setupToastTests() {
        toastSection.addTests([
            TestButton(title: "成功 Toast") {
                ToastPresenter.shared.showSuccess("這是成功訊息")
            },
            TestButton(title: "錯誤 Toast") {
                ToastPresenter.shared.showError("這是錯誤訊息")
            },
            TestButton(title: "警告 Toast") {
                ToastPresenter.shared.showWarning("這是警告訊息")
            },
            TestButton(title: "資訊 Toast") {
                ToastPresenter.shared.showInfo("這是資訊訊息")
            },
            TestButton(title: "多個 Toast") { [weak self] in
                self?.testMultipleToasts()
            },
            TestButton(title: "便利方法") { [weak self] in
                self?.testToastConvenience()
            }
        ])
    }
    
    // MARK: - Technical Tests Setup
    
    private func setupTechnicalTests() {
        technicalSection.addTests([
            TestButton(title: "線程安全測試") { [weak self] in
                self?.testThreadSafety()
            },
            TestButton(title: "快速連續操作") { [weak self] in
                self?.testRapidOperations()
            },
            TestButton(title: "並發 Toast 測試") { [weak self] in
                self?.testConcurrentToasts()
            }
        ])
    }
    
    // MARK: - Test Methods
    
    private func testConfirmationAlert() {
        AlertPresenter.shared.showConfirmation(
            "確定要執行這個操作嗎？",
            title: "操作確認",
            onConfirm: {
                ToastPresenter.shared.showSuccess("已確認")
            },
            onCancel: {
                ToastPresenter.shared.showInfo("已取消")
            }
        )
    }
    
    private func testActionSheet() {
        let actions = [
            AlertPresenter.AlertAction.default("拍照") {
                ToastPresenter.shared.showInfo("選擇了拍照")
            },
            AlertPresenter.AlertAction.default("從相簿選擇") {
                ToastPresenter.shared.showInfo("選擇了相簿")
            },
            AlertPresenter.AlertAction.default("手動輸入") {
                ToastPresenter.shared.showInfo("選擇了手動輸入")
            },
            AlertPresenter.AlertAction.cancel("取消", nil)
        ]
        
        AlertPresenter.shared.showActionSheet(
            title: "新增名片",
            message: "請選擇名片來源",
            actions: actions,
            sourceView: view
        )
    }
    
    private func testAlertPublisher() {
        AlertPresenter.shared.confirmationPublisher(
            "測試 Combine Publisher 整合",
            title: "Publisher 測試"
        )
        .sink { confirmed in
            let result = confirmed ? "確認" : "取消"
            ToastPresenter.shared.showInfo("Publisher 結果：\(result)")
        }
        .store(in: &cancellables)
    }
    
    private func testProgressLoading() {
        LoadingPresenter.shared.showProgress(message: "上傳中...")
        
        var progress: Float = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.05
            LoadingPresenter.shared.updateProgress(progress)
            
            if progress >= 1.0 {
                timer.invalidate()
                LoadingPresenter.shared.hide(afterDelay: 0.5)
                ToastPresenter.shared.showSuccess("上傳完成")
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func testLoadingMessageUpdate() {
        LoadingPresenter.shared.show(message: "步驟 1/3...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            LoadingPresenter.shared.updateMessage("步驟 2/3...")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            LoadingPresenter.shared.updateMessage("步驟 3/3...")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            LoadingPresenter.shared.hide()
            ToastPresenter.shared.showSuccess("所有步驟完成")
        }
    }
    
    private func testLoadingWithCombine() {
        let mockRequest = Future<String, Error> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                promise(.success("資料載入成功"))
            }
        }
        .eraseToAnyPublisher()
        
        LoadingPresenter.shared.performWithLoading(
            message: "使用 Combine 載入資料...",
            operation: mockRequest
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("載入失敗：\(error)")
                }
            },
            receiveValue: { value in
                ToastPresenter.shared.showSuccess(value)
            }
        )
        .store(in: &cancellables)
    }
    
    private func testMultipleToasts() {
        ToastPresenter.shared.showSuccess("Toast 1")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ToastPresenter.shared.showError("Toast 2")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ToastPresenter.shared.showWarning("Toast 3")
        }
    }
    
    private func testToastConvenience() {
        ToastPresenter.shared.showSaveSuccess()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ToastPresenter.shared.showCopySuccess()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ToastPresenter.shared.showNetworkError()
        }
    }
    
    private func testThreadSafety() {
        let group = DispatchGroup()
        
        for i in 1...5 {
            group.enter()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    ToastPresenter.shared.showInfo("線程測試 \(i)")
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            ToastPresenter.shared.showSuccess("線程安全測試完成")
        }
    }
    
    private func testRapidOperations() {
        for i in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                ToastPresenter.shared.showInfo("快速操作 \(i)")
            }
        }
    }
    
    private func testConcurrentToasts() {
        let toastMethods = [
            { (message: String) in ToastPresenter.shared.showSuccess(message) },
            { (message: String) in ToastPresenter.shared.showError(message) },
            { (message: String) in ToastPresenter.shared.showWarning(message) },
            { (message: String) in ToastPresenter.shared.showInfo(message) }
        ]
        
        for i in 1...10 {
            let delay = TimeInterval(i) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let randomMethod = toastMethods.randomElement()!
                randomMethod("並發測試 \(i)")
            }
        }
    }
}

// MARK: - TestSectionView

/// 測試區塊視圖
private class TestSectionView: ThemedView {
    
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupView() {
        super.setupView()
        
        backgroundColor = AppTheme.Colors.cardBackground
        applyCornerRadius(AppTheme.Layout.cardCornerRadius)
        
        titleLabel.font = AppTheme.Fonts.title3
        titleLabel.textColor = AppTheme.Colors.primaryText
        
        stackView.axis = .vertical
        stackView.spacing = AppTheme.Layout.compactPadding
        stackView.distribution = .fill
        
        addSubview(titleLabel)
        addSubview(stackView)
    }
    
    override func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppTheme.Layout.compactPadding)
            make.left.right.bottom.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
    }
    
    func addTests(_ buttons: [TestButton]) {
        buttons.forEach { stackView.addArrangedSubview($0) }
    }
}

// MARK: - TestButton

/// 測試按鈕
private class TestButton: ThemedButton {
    
    init(title: String, action: @escaping () -> Void) {
        super.init(style: .secondary)
        setTitle(title, for: .normal)
        
        tapPublisher
            .sink { action() }
            .store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var cancellables = Set<AnyCancellable>()
}