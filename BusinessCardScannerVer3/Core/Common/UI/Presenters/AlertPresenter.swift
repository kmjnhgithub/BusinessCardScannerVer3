//
//  AlertPresenter.swift
//  BusinessCardScanner
//
//  統一的對話框呈現管理器 - 重構優化版本
//  位置：Core/Common/UI/Presenters/AlertPresenter.swift


import UIKit
import Combine

/// 統一的對話框呈現管理器
/// 負責管理應用程式中所有的 Alert 和 ActionSheet 顯示
/// 設計原則：
/// - 單例模式確保全域統一管理
/// - 線程安全的操作佇列
/// - 自動視窗層級管理
/// - 支援 Combine 響應式編程
final class AlertPresenter {
    
    // MARK: - Singleton
    
    /// 共享實例
    static let shared = AlertPresenter()
    
    // MARK: - Types
    
    /// Alert 動作類型
    enum AlertAction {
        case `default`(String, (() -> Void)?)
        case cancel(String = "取消", (() -> Void)?)
        case destructive(String, (() -> Void)?)
        
        /// 轉換為 UIAlertAction
        /// - Parameter dismissHandler: Alert 關閉時的額外處理
        func toUIAlertAction(dismissHandler: (() -> Void)? = nil) -> UIAlertAction {
            switch self {
            case .default(let title, let handler):
                return UIAlertAction(title: title, style: .default) { _ in
                    DispatchQueue.main.async {
                        handler?()
                        dismissHandler?()
                    }
                }
                
            case .cancel(let title, let handler):
                return UIAlertAction(title: title, style: .cancel) { _ in
                    DispatchQueue.main.async {
                        handler?()
                        dismissHandler?()
                    }
                }
                
            case .destructive(let title, let handler):
                return UIAlertAction(title: title, style: .destructive) { _ in
                    DispatchQueue.main.async {
                        handler?()
                        dismissHandler?()
                    }
                }
            }
        }
    }
    
    /// Alert 配置
    struct AlertConfiguration {
        let title: String?
        let message: String?
        let preferredStyle: UIAlertController.Style
        let actions: [AlertAction]
        let textFields: [(UITextField) -> Void]?
        let sourceView: UIView?
        let sourceRect: CGRect?
        let barButtonItem: UIBarButtonItem?
        
        init(
            title: String? = nil,
            message: String? = nil,
            preferredStyle: UIAlertController.Style = .alert,
            actions: [AlertAction] = [],
            textFields: [(UITextField) -> Void]? = nil,
            sourceView: UIView? = nil,
            sourceRect: CGRect? = nil,
            barButtonItem: UIBarButtonItem? = nil
        ) {
            self.title = title
            self.message = message
            self.preferredStyle = preferredStyle
            self.actions = actions
            self.textFields = textFields
            self.sourceView = sourceView
            self.sourceRect = sourceRect
            self.barButtonItem = barButtonItem
        }
    }
    
    // MARK: - Properties
    
    /// 當前顯示的 Alert Controller
    /// 使用 weak 引用避免循環引用
    private weak var currentAlertController: UIAlertController?
    
    /// 操作佇列，確保線程安全
    /// 使用 serial queue 避免競態條件
    private let operationQueue = DispatchQueue(label: "com.app.alertpresenter", qos: .userInteractive)
    
    /// Alert 顯示完成的回調佇列
    /// 用於處理連續顯示 Alert 的情況
    private var pendingAlerts: [AlertConfiguration] = []
    
    /// 是否正在顯示 Alert
    private var isPresenting = false
    
    /// 私有初始化，確保單例
    private init() {}
    
    // MARK: - Basic Alerts
    
    /// 顯示簡單訊息
    /// - Parameters:
    ///   - message: 訊息內容
    ///   - title: 標題（可選）
    ///   - buttonTitle: 按鈕標題，預設為"確定"
    ///   - completion: 關閉後的回調
    func showMessage(
        _ message: String,
        title: String? = nil,
        buttonTitle: String = "確定",
        completion: (() -> Void)? = nil
    ) {
        let config = AlertConfiguration(
            title: title,
            message: message,
            actions: [.default(buttonTitle, completion)]
        )
        enqueueAlert(config)
    }
    
    /// 顯示錯誤訊息
    /// - Parameters:
    ///   - error: 錯誤對象
    ///   - title: 標題，預設為"錯誤"
    ///   - completion: 關閉後的回調
    func showError(
        _ error: Error,
        title: String = "錯誤",
        completion: (() -> Void)? = nil
    ) {
        let message = extractErrorMessage(from: error)
        showMessage(message, title: title, completion: completion)
    }
    
    /// 顯示成功訊息（可自動消失）
    /// - Parameters:
    ///   - message: 成功訊息
    ///   - title: 標題，預設為"成功"
    ///   - autoDismiss: 自動消失時間（秒），nil 表示不自動消失
    @discardableResult
    func showSuccess(
        _ message: String,
        title: String = "成功",
        autoDismiss: TimeInterval? = nil
    ) -> UIAlertController? {
        let config = AlertConfiguration(
            title: title,
            message: message,
            actions: [.default("確定", nil)]
        )
        
        let alertController = presentImmediately(config)
        
        // 自動消失機制
        if let autoDismiss = autoDismiss, let alert = alertController {
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismiss) { [weak alert] in
                alert?.dismiss(animated: true) { [weak self] in
                    self?.processNextAlert()
                }
            }
        }
        
        return alertController
    }
    
    // MARK: - Confirmation Dialogs
    
    /// 顯示確認對話框
    /// - Parameters:
    ///   - message: 確認訊息
    ///   - title: 標題
    ///   - confirmTitle: 確認按鈕標題，預設為"確定"
    ///   - cancelTitle: 取消按鈕標題，預設為"取消"
    ///   - onConfirm: 確認回調
    ///   - onCancel: 取消回調（可選）
    func showConfirmation(
        _ message: String,
        title: String? = nil,
        confirmTitle: String = "確定",
        cancelTitle: String = "取消",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let config = AlertConfiguration(
            title: title,
            message: message,
            actions: [
                .cancel(cancelTitle, onCancel),
                .default(confirmTitle, onConfirm)
            ]
        )
        enqueueAlert(config)
    }
    
    /// 顯示破壞性確認對話框（紅色按鈕）
    /// - Parameters:
    ///   - message: 確認訊息
    ///   - title: 標題
    ///   - destructiveTitle: 破壞性操作按鈕標題
    ///   - cancelTitle: 取消按鈕標題，預設為"取消"
    ///   - onConfirm: 確認回調
    ///   - onCancel: 取消回調（可選）
    func showDestructiveConfirmation(
        _ message: String,
        title: String? = nil,
        destructiveTitle: String,
        cancelTitle: String = "取消",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let config = AlertConfiguration(
            title: title,
            message: message,
            actions: [
                .cancel(cancelTitle, onCancel),
                .destructive(destructiveTitle, onConfirm)
            ]
        )
        enqueueAlert(config)
    }
    
    // MARK: - Action Sheets
    
    /// 顯示操作選單
    /// - Parameters:
    ///   - title: 標題（可選）
    ///   - message: 訊息（可選）
    ///   - actions: 動作列表
    ///   - sourceView: 來源視圖（iPad 必須）
    ///   - sourceRect: 來源矩形（可選）
    ///   - barButtonItem: 來源 Bar Button（可選）
    func showActionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [AlertAction],
        sourceView: UIView? = nil,
        sourceRect: CGRect? = nil,
        barButtonItem: UIBarButtonItem? = nil
    ) {
        let config = AlertConfiguration(
            title: title,
            message: message,
            preferredStyle: .actionSheet,
            actions: actions,
            sourceView: sourceView,
            sourceRect: sourceRect,
            barButtonItem: barButtonItem
        )
        enqueueAlert(config)
    }
    
    // MARK: - Input Dialogs (重構版本)
    
    /// 顯示輸入對話框 - 優化版本
    /// 移除實時監聽機制，僅在確認時獲取輸入值
    /// - Parameters:
    ///   - title: 標題
    ///   - message: 訊息（可選）
    ///   - placeholder: 輸入框占位文字
    ///   - defaultValue: 預設值（可選）
    ///   - keyboardType: 鍵盤類型
    ///   - autocapitalizationType: 自動大寫類型
    ///   - autocorrectionType: 自動修正類型
    ///   - isSecureTextEntry: 是否為密碼輸入
    ///   - onConfirm: 確認回調，返回輸入的文字
    ///   - onCancel: 取消回調（可選）
    func showInputDialog(
        title: String,
        message: String? = nil,
        placeholder: String? = nil,
        defaultValue: String? = nil,
        keyboardType: UIKeyboardType = .default,
        autocapitalizationType: UITextAutocapitalizationType = .sentences,
        autocorrectionType: UITextAutocorrectionType = .default,
        isSecureTextEntry: Bool = false,
        onConfirm: @escaping (String) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        // 使用 weak reference 避免循環引用
        weak var textFieldRef: UITextField?
        
        let config = AlertConfiguration(
            title: title,
            message: message,
            actions: [
                .cancel("取消", onCancel),
                .default("確定") { [weak textFieldRef] in
                    // 直接從 TextField 讀取最終值，避免閉包捕獲
                    let inputText = textFieldRef?.text ?? ""
                    onConfirm(inputText)
                }
            ],
            textFields: [
                { textField in
                    // 保存 TextField 的弱引用
                    textFieldRef = textField
                    
                    // 配置 TextField 屬性
                    textField.placeholder = placeholder
                    textField.text = defaultValue
                    textField.keyboardType = keyboardType
                    textField.autocapitalizationType = autocapitalizationType
                    textField.autocorrectionType = autocorrectionType
                    textField.isSecureTextEntry = isSecureTextEntry
                    textField.clearButtonMode = .whileEditing
                    
                    // 設定返回鍵類型
                    textField.returnKeyType = .done
                    
                    // 設定初始選中狀態（更好的用戶體驗）
                    if defaultValue != nil {
                        // 延遲執行以確保 TextField 已經顯示
                        DispatchQueue.main.async {
                            textField.selectAll(nil)
                        }
                    }
                }
            ]
        )
        enqueueAlert(config)
    }
    
    // MARK: - Combine Support
    
    /// 返回確認對話框的 Publisher
    /// - Parameters:
    ///   - message: 確認訊息
    ///   - title: 標題
    ///   - confirmTitle: 確認按鈕標題
    ///   - cancelTitle: 取消按鈕標題
    /// - Returns: 發送 true（確認）或 false（取消）的 Publisher
    func confirmationPublisher(
        _ message: String,
        title: String? = nil,
        confirmTitle: String = "確定",
        cancelTitle: String = "取消"
    ) -> AnyPublisher<Bool, Never> {
        // 建立新的 Subject
        let subject = PassthroughSubject<Bool, Never>()
        
        showConfirmation(
            message,
            title: title,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle,
            onConfirm: {
                subject.send(true)
                subject.send(completion: .finished)
            },
            onCancel: {
                subject.send(false)
                subject.send(completion: .finished)
            }
        )
        
        // 設定超時機制，避免永久等待
        return subject
            .timeout(.seconds(300), scheduler: DispatchQueue.main) // 5分鐘超時
            .replaceError(with: false) // 超時視為取消
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// 將 Alert 加入佇列
    /// 使用佇列機制避免多個 Alert 同時顯示
    private func enqueueAlert(_ configuration: AlertConfiguration) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.pendingAlerts.append(configuration)
            
            if !self.isPresenting {
                self.processNextAlert()
            }
        }
    }
    
    /// 處理下一個 Alert
    private func processNextAlert() {
        operationQueue.async { [weak self] in
            guard let self = self,
                  !self.pendingAlerts.isEmpty,
                  !self.isPresenting else { return }
            
            let configuration = self.pendingAlerts.removeFirst()
            self.isPresenting = true
            
            DispatchQueue.main.async {
                self.present(configuration)
            }
        }
    }
    
    /// 立即呈現 Alert（用於需要返回 controller 的情況）
    @discardableResult
    private func presentImmediately(_ configuration: AlertConfiguration) -> UIAlertController? {
        // 如果有正在顯示的 Alert，先關閉
        if let current = currentAlertController {
            current.dismiss(animated: false)
            currentAlertController = nil
        }
        
        return present(configuration)
    }
    
    /// 呈現 Alert
    /// - Parameter configuration: Alert 配置
    /// - Returns: 呈現的 UIAlertController
    @discardableResult
    private func present(_ configuration: AlertConfiguration) -> UIAlertController {
        // 確保在主線程執行
        assert(Thread.isMainThread, "Alert 必須在主線程呈現")
        
        // 建立 Alert Controller
        let alertController = UIAlertController(
            title: configuration.title,
            message: configuration.message,
            preferredStyle: configuration.preferredStyle
        )
        
        // 添加文字輸入框
        configuration.textFields?.forEach { configHandler in
            alertController.addTextField(configurationHandler: configHandler)
        }
        
        // 添加動作按鈕
        configuration.actions.forEach { action in
            let uiAction = action.toUIAlertAction { [weak self] in
                // 每個 action 執行後的統一處理
                self?.onAlertDismissed()
            }
            alertController.addAction(uiAction)
        }
        
        // 如果沒有動作，添加預設的確定按鈕
        if configuration.actions.isEmpty {
            let defaultAction = UIAlertAction(title: "確定", style: .default) { [weak self] _ in
                self?.onAlertDismissed()
            }
            alertController.addAction(defaultAction)
        }
        
        // 配置 iPad 的 popover 顯示
        if configuration.preferredStyle == .actionSheet,
           let popover = alertController.popoverPresentationController {
            
            // 優先使用 barButtonItem
            if let barButtonItem = configuration.barButtonItem {
                popover.barButtonItem = barButtonItem
            }
            // 其次使用 sourceView
            else if let sourceView = configuration.sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = configuration.sourceRect ?? sourceView.bounds
            }
            // 都沒有時使用預設位置（避免 iPad 崩潰）
            else if let topVC = getTopViewController() {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(
                    x: topVC.view.bounds.midX,
                    y: topVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
        }
        
        // 取得最上層的 ViewController
        guard let topViewController = getTopViewController() else {
            print("⚠️ AlertPresenter: 無法找到頂層 ViewController")
            return alertController
        }
        
        // 保存當前 Alert 的引用
        currentAlertController = alertController
        
        // 呈現 Alert
        topViewController.present(alertController, animated: true)
        
        return alertController
    }
    
    /// Alert 關閉時的處理
    private func onAlertDismissed() {
        operationQueue.async { [weak self] in
            self?.isPresenting = false
            self?.currentAlertController = nil
            
            // 處理下一個 Alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.processNextAlert()
            }
        }
    }
    
    /// 取得最上層的 ViewController
    private func getTopViewController() -> UIViewController? {
        // 取得當前活躍的 window scene
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        return getTopViewController(from: rootViewController)
    }
    
    /// 遞迴尋找最上層的 ViewController
    private func getTopViewController(from viewController: UIViewController) -> UIViewController {
        // 處理 presented view controller
        if let presented = viewController.presentedViewController {
            return getTopViewController(from: presented)
        }
        
        // 處理 UINavigationController
        if let navigationController = viewController as? UINavigationController,
           let topViewController = navigationController.topViewController {
            return getTopViewController(from: topViewController)
        }
        
        // 處理 UITabBarController
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return getTopViewController(from: selectedViewController)
        }
        
        // 處理 container view controllers
        if !viewController.children.isEmpty,
           let lastChild = viewController.children.last {
            return getTopViewController(from: lastChild)
        }
        
        return viewController
    }
    
    /// 從錯誤中提取友善的錯誤訊息
    private func extractErrorMessage(from error: Error) -> String {
        // 處理特定的錯誤類型
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "無網路連線，請檢查您的網路設定"
            case .timedOut:
                return "連線逾時，請稍後再試"
            case .cancelled:
                return "操作已取消"
            default:
                return "網路錯誤：\(urlError.localizedDescription)"
            }
        }
        
        // 處理 Core Data 錯誤
        if (error as NSError).domain == "NSCocoaErrorDomain" {
            switch (error as NSError).code {
            case 132001: // Core Data 模型版本錯誤
                return "資料格式錯誤，請重新安裝應用程式"
            case 134140: // 持久化儲存錯誤
                return "資料儲存錯誤，請重試"
            default:
                return "資料存取錯誤，請重新啟動應用程式"
            }
        }
        
        // 優先使用 localizedDescription
        return error.localizedDescription
    }
}

// MARK: - Public Convenience Methods

extension AlertPresenter {
    
    /// 顯示網路錯誤
    func showNetworkError() {
        showMessage(
            "無法連接到網路，請檢查您的網路設定",
            title: "網路錯誤"
        )
    }
    
    /// 顯示權限錯誤
    /// - Parameter feature: 需要權限的功能名稱
    func showPermissionError(for feature: String) {
        showConfirmation(
            "需要\(feature)權限才能使用此功能，是否前往設定開啟？",
            title: "權限不足",
            confirmTitle: "前往設定",
            onConfirm: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        )
    }
    
    /// 顯示開發中提示
    func showComingSoon() {
        showMessage(
            "此功能正在開發中，敬請期待",
            title: "即將推出"
        )
    }
    
    /// 顯示 API Key 設定提示
    func showAPIKeyRequired() {
        showConfirmation(
            "需要設定 OpenAI API Key 才能使用 AI 解析功能",
            title: "需要 API Key",
            confirmTitle: "前往設定",
            onConfirm: {
                // 通知設定模組開啟 API Key 設定
                NotificationCenter.default.post(
                    name: .openAPIKeySettings,
                    object: nil
                )
            }
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openAPIKeySettings = Notification.Name("openAPIKeySettings")
}

// MARK: - Thread Safety Validation

#if DEBUG
extension AlertPresenter {
    /// 驗證線程安全性（僅用於測試）
    func validateThreadSafety() {
        let group = DispatchGroup()
        let iterations = 100
        
        // 模擬並發訪問
        for i in 0..<iterations {
            group.enter()
            DispatchQueue.global().async {
                self.showMessage("測試訊息 \(i)")
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("✅ AlertPresenter 線程安全性測試完成")
        }
    }
}
#endif
