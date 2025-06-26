//
//  TestViewModel.swift

//
//  Created by mike liu on 2025/6/25.
//

import UIKit
import Combine
import SnapKit

// MARK: - 測試用 ViewModel

class TestViewModel: BaseViewModel {
    
    // 使用 @Published 發布狀態變化
    @Published var greeting = "Hello"
    @Published var counter = 0
    
    // 測試用的業務邏輯
    func incrementCounter() {
        counter += 1
    }
    
    func updateGreeting(_ name: String) {
        greeting = "Hello, \(name)!"
    }
    
    // 測試非同步操作
    func loadData() {
        performAsyncOperation(
            operation: {
                // 模擬網路請求
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
                return "資料載入完成"
            },
            onSuccess: { [weak self] result in
                self?.greeting = result
            }
        )
    }
}

// MARK: - 測試用 ViewController

class TestViewController: BaseViewController {
    
    // MARK: - UI Elements
    
    private let greetingLabel = UILabel()
    private let counterLabel = UILabel()
    private let incrementButton = UIButton(type: .system)
    private let loadButton = UIButton(type: .system)
    private let nameTextField = UITextField()
    
    // MARK: - Properties
    
    private let viewModel = TestViewModel()
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        title = "測試頁面"
        
        // 設定 Label
        greetingLabel.font = .systemFont(ofSize: 20, weight: .medium)
        greetingLabel.textAlignment = .center
        
        counterLabel.font = .systemFont(ofSize: 48, weight: .bold)
        counterLabel.textAlignment = .center
        
        // 設定按鈕
        incrementButton.setTitle("增加計數", for: .normal)
        incrementButton.titleLabel?.font = .systemFont(ofSize: 18)
        
        loadButton.setTitle("載入資料", for: .normal)
        loadButton.titleLabel?.font = .systemFont(ofSize: 18)
        
        // 設定輸入框
        nameTextField.placeholder = "輸入名字"
        nameTextField.borderStyle = .roundedRect
        
        // 加入視圖
        [greetingLabel, counterLabel, nameTextField, incrementButton, loadButton].forEach {
            view.addSubview($0)
        }
        
        // 設定按鈕動作
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        loadButton.addTarget(self, action: #selector(loadTapped), for: .touchUpInside)
        
        // 設定鍵盤處理
        setupDismissKeyboardGesture()
    }
    
    override func setupConstraints() {
        greetingLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.left.right.equalToSuperview().inset(20)
        }
        
        counterLabel.snp.makeConstraints { make in
            make.top.equalTo(greetingLabel.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
        }
        
        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(counterLabel.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        incrementButton.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
        
        loadButton.snp.makeConstraints { make in
            make.top.equalTo(incrementButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
    }
    
    override func setupBindings() {
        // 綁定 greeting
        viewModel.$greeting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] greeting in
                self?.greetingLabel.text = greeting
            }
            .store(in: &cancellables)
        
        // 綁定 counter
        viewModel.$counter
            .map { "計數: \($0)" }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.counterLabel.text = text
            }
            .store(in: &cancellables)
        
        // 綁定載入狀態
        viewModel.isLoadingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoading("載入中...")
                } else {
                    self?.hideLoading()
                }
                self?.loadButton.isEnabled = !isLoading
            }
            .store(in: &cancellables)
        
        // 綁定錯誤狀態
        viewModel.errorPublisher
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
        
        // 綁定文字輸入
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: nameTextField)
            .compactMap { ($0.object as? UITextField)?.text }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.viewModel.updateGreeting(text)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func incrementTapped() {
        viewModel.incrementCounter()
    }
    
    @objc private func loadTapped() {
        viewModel.loadData()
    }
}

// MARK: - 測試用 Coordinator

class TestCoordinator: BaseCoordinator {
    
    override func start() {
        let testViewController = TestViewController()
        push(testViewController)
    }
}
