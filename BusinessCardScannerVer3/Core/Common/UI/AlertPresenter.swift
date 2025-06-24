//
//  AlertPresenter.swift
//  BusinessCardScanner
//
//  統一管理所有 Alert 顯示邏輯
//

import UIKit

/// Alert 按鈕配置
struct AlertAction {
    let title: String
    let style: UIAlertAction.Style
    let handler: (() -> Void)?
    
    init(title: String, style: UIAlertAction.Style = .default, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

/// Alert 顯示器
final class AlertPresenter {
    
    // MARK: - Singleton (可選用)
    
    static let shared = AlertPresenter()
    
    // MARK: - Basic Alerts
    
    /// 顯示基本 Alert
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息
    ///   - actions: 按鈕動作陣列
    ///   - presenter: 顯示的 ViewController
    @discardableResult
    func showAlert(
        title: String?,
        message: String?,
        actions: [AlertAction],
        from presenter: UIViewController
    ) -> UIAlertController {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        // 添加動作按鈕
        for action in actions {
            let alertAction = UIAlertAction(
                title: action.title,
                style: action.style
            ) { _ in
                action.handler?()
            }
            alertController.addAction(alertAction)
        }
        
        // 如果沒有動作，添加預設的確定按鈕
        if actions.isEmpty {
            alertController.addAction(UIAlertAction(title: "確定", style: .default))
        }
        
        presenter.present(alertController, animated: true)
        
        return alertController
    }
    
    /// 顯示確認 Alert
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息
    ///   - confirmTitle: 確認按鈕標題
    ///   - cancelTitle: 取消按鈕標題
    ///   - confirmHandler: 確認處理
    ///   - presenter: 顯示的 ViewController
    func showConfirmation(
        title: String?,
        message: String?,
        confirmTitle: String = "確定",
        cancelTitle: String = "取消",
        confirmHandler: @escaping () -> Void,
        from presenter: UIViewController
    ) {
        let actions = [
            AlertAction(title: cancelTitle, style: .cancel),
            AlertAction(title: confirmTitle, style: .default, handler: confirmHandler)
        ]
        
        showAlert(title: title, message: message, actions: actions, from: presenter)
    }
    
    /// 顯示刪除確認 Alert
    /// - Parameters:
    ///   - itemName: 要刪除的項目名稱
    ///   - deleteHandler: 刪除處理
    ///   - presenter: 顯示的 ViewController
    func showDeleteConfirmation(
        itemName: String,
        deleteHandler: @escaping () -> Void,
        from presenter: UIViewController
    ) {
        let actions = [
            AlertAction(title: "取消", style: .cancel),
            AlertAction(title: "刪除", style: .destructive, handler: deleteHandler)
        ]
        
        showAlert(
            title: "確認刪除",
            message: "確定要刪除「\(itemName)」嗎？此操作無法復原。",
            actions: actions,
            from: presenter
        )
    }
    
    // MARK: - Error Alerts
    
    /// 顯示錯誤 Alert
    /// - Parameters:
    ///   - error: 錯誤物件
    ///   - presenter: 顯示的 ViewController
    ///   - completion: 完成回調
    func showError(
        _ error: Error,
        from presenter: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        
        showAlert(
            title: "錯誤",
            message: message,
            actions: [AlertAction(title: "確定", handler: completion)],
            from: presenter
        )
    }
    
    /// 顯示錯誤訊息
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 錯誤訊息
    ///   - presenter: 顯示的 ViewController
    ///   - completion: 完成回調
    func showError(
        title: String = "錯誤",
        message: String,
        from presenter: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        showAlert(
            title: title,
            message: message,
            actions: [AlertAction(title: "確定", handler: completion)],
            from: presenter
        )
    }
    
    // MARK: - Success Alerts
    
    /// 顯示成功訊息
    /// - Parameters:
    ///   - message: 成功訊息
    ///   - presenter: 顯示的 ViewController
    ///   - completion: 完成回調
    func showSuccess(
        message: String,
        from presenter: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        showAlert(
            title: "成功",
            message: message,
            actions: [AlertAction(title: "確定", handler: completion)],
            from: presenter
        )
    }
    
    // MARK: - Action Sheets
    
    /// 顯示選項選單
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息
    ///   - actions: 動作陣列
    ///   - sourceView: 來源視圖（iPad 需要）
    ///   - presenter: 顯示的 ViewController
    @discardableResult
    func showActionSheet(
        title: String?,
        message: String?,
        actions: [AlertAction],
        sourceView: UIView? = nil,
        from presenter: UIViewController
    ) -> UIAlertController {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .actionSheet
        )
        
        // 添加動作
        for action in actions {
            let alertAction = UIAlertAction(
                title: action.title,
                style: action.style
            ) { _ in
                action.handler?()
            }
            alertController.addAction(alertAction)
        }
        
        // 添加取消按鈕
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // iPad 需要設定 popover
        if let popover = alertController.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                popover.sourceView = presenter.view
                popover.sourceRect = CGRect(
                    x: presenter.view.bounds.midX,
                    y: presenter.view.bounds.midY,
                    width: 0,
                    height: 0
                )
            }
        }
        
        presenter.present(alertController, animated: true)
        
        return alertController
    }
    
    // MARK: - Input Alerts
    
    /// 顯示輸入對話框
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息
    ///   - placeholder: 占位文字
    ///   - defaultValue: 預設值
    ///   - keyboardType: 鍵盤類型
    ///   - confirmHandler: 確認處理（傳入輸入的文字）
    ///   - presenter: 顯示的 ViewController
    func showTextInput(
        title: String?,
        message: String?,
        placeholder: String? = nil,
        defaultValue: String? = nil,
        keyboardType: UIKeyboardType = .default,
        confirmHandler: @escaping (String?) -> Void,
        from presenter: UIViewController
    ) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        // 添加文字輸入框
        alertController.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = defaultValue
            textField.keyboardType = keyboardType
        }
        
        // 添加取消按鈕
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 添加確定按鈕
        let confirmAction = UIAlertAction(title: "確定", style: .default) { _ in
            let text = alertController.textFields?.first?.text
            confirmHandler(text)
        }
        alertController.addAction(confirmAction)
        
        presenter.present(alertController, animated: true)
    }
}
