//
//  TestDIContainer.swift
//  BusinessCardScanner
//
//  測試 DI 容器和模組工廠
//

import UIKit

class TestDIContainerViewController: BaseViewController {
    
    // MARK: - UI Elements
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("測試 DI 容器", for: .normal)
        button.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        title = "DI 容器測試"
        
        view.addSubview(statusLabel)
        view.addSubview(testButton)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            testButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 30),
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 150),
            testButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func testButtonTapped() {
        testDIContainer()
    }
    
    private func testDIContainer() {
        var results: [String] = []
        
        do {
            // 1. 測試服務容器基本功能
            let container = ServiceContainer.shared
            results.append("✅ ServiceContainer 實例化成功")
            
            // 2. 測試服務註冊和解析
            // 註冊一個測試服務
            protocol TestService {
                func getMessage() -> String
            }
            
            class TestServiceImpl: TestService {
                func getMessage() -> String {
                    return "Hello from TestService"
                }
            }
            
            container.register(TestService.self) { _ in
                TestServiceImpl()
            }
            results.append("✅ 服務註冊成功")
            
            // 3. 解析服務
            let service = container.resolve(TestService.self)
            let message = service.getMessage()
            results.append("✅ 服務解析成功: \(message)")
            
            // 4. 測試單例模式
            let service1 = container.resolve(TestService.self)
            let service2 = container.resolve(TestService.self)
            if (service1 as AnyObject) === (service2 as AnyObject) {
                results.append("✅ 單例模式正常運作")
            }
            
            // 5. 測試模組工廠
            let moduleFactory = ModuleFactory(container: container)
            results.append("✅ ModuleFactory 創建成功")
            
            // 6. 測試瞬時服務
            container.register(TestService.self, name: "transient", lifetime: .transient) { _ in
                TestServiceImpl()
            }
            let t1 = container.resolve(TestService.self, name: "transient")
            let t2 = container.resolve(TestService.self, name: "transient")
            if (t1 as AnyObject) !== (t2 as AnyObject) {
                results.append("✅ 瞬時模式正常運作")
            }
            
            statusLabel.text = results.joined(separator: "\n")
            
        } catch {
            statusLabel.text = "❌ 測試失敗: \(error.localizedDescription)"
        }
    }
}
