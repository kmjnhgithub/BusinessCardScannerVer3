//
//  BaseCoordinator.swift
//  BusinessCardScanner
//
//  基礎 Coordinator，實現導航邏輯的基礎類別
//

import UIKit

/// Coordinator 協議
protocol Coordinator: AnyObject {
    /// 子 Coordinators
    var childCoordinators: [Coordinator] { get set }
    
    /// 導航控制器
    var navigationController: UINavigationController { get }
    
    /// 開始流程
    func start()
    
    /// 結束流程
    func finish()
}

/// 基礎 Coordinator 實作
class BaseCoordinator: Coordinator {
    
    // MARK: - Properties
    
    /// 子 Coordinators
    var childCoordinators: [Coordinator] = []
    
    /// 導航控制器
    let navigationController: UINavigationController
    
    /// 父 Coordinator (弱引用避免循環引用)
    weak var parentCoordinator: Coordinator?
    
    // MARK: - Initialization
    
    /// 初始化
    /// - Parameter navigationController: 導航控制器
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Coordinator Protocol
    
    /// 開始流程（子類別必須實作）
    func start() {
        fatalError("Start method must be implemented by subclass")
    }
    
    /// 結束流程
    func finish() {
        // 通知父 Coordinator 移除自己
        if let parent = parentCoordinator as? BaseCoordinator {
            parent.removeChild(self)
        }
    }
    
    // MARK: - Child Coordinator Management
    
    /// 添加子 Coordinator
    /// - Parameter coordinator: 子 Coordinator
    func addChild(_ coordinator: Coordinator) {
        // 避免重複添加
        guard !childCoordinators.contains(where: { $0 === coordinator }) else { return }
        
        childCoordinators.append(coordinator)
        
        // 設定父子關係
        if let childCoordinator = coordinator as? BaseCoordinator {
            childCoordinator.parentCoordinator = self
        }
    }
    
    /// 移除子 Coordinator
    /// - Parameter coordinator: 要移除的 Coordinator
    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
    
    /// 移除所有子 Coordinators
    func removeAllChildren() {
        childCoordinators.removeAll()
    }
    
    // MARK: - Navigation Helpers
    
    /// Push ViewController
    /// - Parameters:
    ///   - viewController: 要 push 的 ViewController
    ///   - animated: 是否動畫
    func push(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    /// Pop ViewController
    /// - Parameter animated: 是否動畫
    func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }
    
    /// Pop 到根 ViewController
    /// - Parameter animated: 是否動畫
    func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }
    
    /// Present ViewController
    /// - Parameters:
    ///   - viewController: 要 present 的 ViewController
    ///   - animated: 是否動畫
    ///   - completion: 完成回調
    func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController.present(viewController, animated: animated, completion: completion)
    }
    
    /// Dismiss ViewController
    /// - Parameters:
    ///   - animated: 是否動畫
    ///   - completion: 完成回調
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Alert Helpers
    
    /// 顯示 Alert
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息
    ///   - actions: 動作列表
    func showAlert(title: String?, message: String?, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        navigationController.present(alert, animated: true)
    }
    
    /// 顯示錯誤 Alert
    /// - Parameters:
    ///   - error: 錯誤
    ///   - completion: 完成回調
    func showError(_ error: Error, completion: (() -> Void)? = nil) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        showAlert(
            title: "錯誤",
            message: message,
            actions: [
                UIAlertAction(title: "確定", style: .default) { _ in
                    completion?()
                }
            ]
        )
    }
    
    // MARK: - Deinit
    
    deinit {
        print("\(String(describing: self)) deinit")
    }
}
