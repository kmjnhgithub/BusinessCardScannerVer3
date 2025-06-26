//
//  BaseCoordinator.swift
//  
//
//  Base class for all Coordinators
//

import UIKit

/// Coordinator 協議定義
protocol Coordinator: AnyObject {
    /// 子協調器集合
    var childCoordinators: [Coordinator] { get set }
    
    /// 父協調器（使用 weak 避免循環引用）
    var parentCoordinator: Coordinator? { get set }
    
    /// 導航控制器
    var navigationController: UINavigationController { get set }
    
    /// 啟動協調器
    func start()
    
    /// 協調器完成回調
    var onFinish: (() -> Void)? { get set }
    
    /// 移除子協調器
    func removeChild(_ coordinator: Coordinator)
}

/// 所有 Coordinator 的基礎類別
class BaseCoordinator: NSObject, Coordinator {
    
    // MARK: - Properties
    
    /// 子協調器集合
    var childCoordinators: [Coordinator] = []
    
    /// 父協調器（weak 避免循環引用）
    weak var parentCoordinator: Coordinator?
    
    /// 導航控制器
    var navigationController: UINavigationController
    
    /// 完成回調
    var onFinish: (() -> Void)?
    
    // MARK: - Initialization
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }
    
    deinit {
        #if DEBUG
        print("✅ \(String(describing: type(of: self))) deinit")
        #endif
    }
    
    // MARK: - Coordinator Protocol
    
    /// 啟動協調器（子類別必須實作）
    func start() {
        fatalError("Start method must be implemented by subclass")
    }
    
    // MARK: - Child Coordinator Management
    
    /// 添加子協調器
    func addChild(_ coordinator: Coordinator) {
        // 避免重複添加
        guard !childCoordinators.contains(where: { $0 === coordinator }) else {
            return
        }
        
        childCoordinators.append(coordinator)
        coordinator.parentCoordinator = self
    }
    
    /// 移除子協調器
    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
    
    /// 移除所有子協調器
    func removeAllChildren() {
        childCoordinators.removeAll()
    }
    
    /// 結束協調器
    func finish() {
        // 通知父協調器移除自己
        parentCoordinator?.removeChild(self)
        
        // 執行完成回調
        onFinish?()
    }
    
    // MARK: - Navigation Helpers
    
    /// Push ViewController
    func push(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    /// Pop ViewController
    func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }
    
    /// Pop 到根視圖
    func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }
    
    /// Present ViewController
    func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController.present(viewController, animated: animated, completion: completion)
    }
    
    /// Dismiss ViewController
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController.dismiss(animated: animated, completion: completion)
    }
    
    /// 設定根視圖控制器
    func setRootViewController(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.setViewControllers([viewController], animated: animated)
    }
}

// MARK: - UINavigationControllerDelegate

extension BaseCoordinator: UINavigationControllerDelegate {
    
    /// 設定為導航控制器代理
    func setupNavigationControllerDelegate() {
        navigationController.delegate = self
    }
    
    /// 移除導航控制器代理
    func removeNavigationControllerDelegate() {
        if navigationController.delegate === self {
            navigationController.delegate = nil
        }
    }
    
    /// 處理導航返回（子類別可覆寫）
    func handleNavigationBack(from viewController: UIViewController) {
        // 子類別實作具體的返回處理邏輯
    }
}

// MARK: - Module Communication

extension BaseCoordinator {
    
    /// 模組輸出協議基礎
    typealias ModuleOutput = AnyObject
    
    /// 設定模組輸出（用於模組間通訊）
    func setModuleOutput<T: ModuleOutput>(_ output: T) {
        // 子類別實作具體的輸出設定
    }
}

// MARK: - Alert & Loading Helpers

extension BaseCoordinator {
    
    /// 顯示錯誤訊息
    func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "錯誤",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        navigationController.present(alert, animated: true)
    }
    
    /// 顯示訊息
    func showMessage(_ message: String, title: String? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        navigationController.present(alert, animated: true)
    }
    
    /// 顯示確認對話框
    func showConfirmation(
        title: String,
        message: String?,
        confirmTitle: String = "確定",
        cancelTitle: String = "取消",
        onConfirm: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm()
        })
        
        navigationController.present(alert, animated: true)
    }
}
