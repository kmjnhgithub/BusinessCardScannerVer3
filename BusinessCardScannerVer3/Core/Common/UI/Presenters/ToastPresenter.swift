//
//  ToastPresenter.swift
//  BusinessCardScanner
//
//  輕量級通知訊息管理器 - 約束問題修復版本
//  位置：Core/Common/UI/Presenters/ToastPresenter.swift
//

import UIKit
import Combine

/// 輕量級通知訊息管理器
/// 負責顯示暫時性的提示訊息，不會阻擋使用者操作
final class ToastPresenter {
    
    // MARK: - Singleton
    
    /// 共享實例
    static let shared = ToastPresenter()
    
    // MARK: - Types
    
    /// Toast 類型
    enum ToastType {
        case success
        case error
        case warning
        case info
        case custom(backgroundColor: UIColor, textColor: UIColor, icon: UIImage?)
        
        /// 背景顏色
        var backgroundColor: UIColor {
            switch self {
            case .success:
                return AppTheme.Colors.success
            case .error:
                return AppTheme.Colors.error
            case .warning:
                return AppTheme.Colors.warning
            case .info:
                return AppTheme.Colors.info
            case .custom(let backgroundColor, _, _):
                return backgroundColor
            }
        }
        
        /// 文字顏色
        var textColor: UIColor {
            switch self {
            case .success, .error, .warning, .info:
                return .white
            case .custom(_, let textColor, _):
                return textColor
            }
        }
        
        /// 圖示
        var icon: UIImage? {
            switch self {
            case .success:
                return UIImage(systemName: "checkmark.circle.fill")
            case .error:
                return UIImage(systemName: "xmark.circle.fill")
            case .warning:
                return UIImage(systemName: "exclamationmark.triangle.fill")
            case .info:
                return UIImage(systemName: "info.circle.fill")
            case .custom(_, _, let icon):
                return icon
            }
        }
    }
    
    /// Toast 位置
    enum ToastPosition {
        case top(offset: CGFloat = 50)
        case bottom(offset: CGFloat = 50)
        case center
        
        /// 計算 Toast 的 Y 位置
        func calculateY(in view: UIView, toastHeight: CGFloat) -> CGFloat {
            switch self {
            case .top(let offset):
                return view.safeAreaInsets.top + offset
            case .bottom(let offset):
                return view.bounds.height - view.safeAreaInsets.bottom - toastHeight - offset
            case .center:
                return (view.bounds.height - toastHeight) / 2
            }
        }
    }
    
    /// Toast 配置
    struct ToastConfiguration {
        let message: String
        let type: ToastType
        let position: ToastPosition
        let duration: TimeInterval
        let hapticFeedback: UINotificationFeedbackGenerator.FeedbackType?
        
        init(
            message: String,
            type: ToastType = .info,
            position: ToastPosition = .bottom(),
            duration: TimeInterval = 3.0,
            hapticFeedback: UINotificationFeedbackGenerator.FeedbackType? = nil
        ) {
            self.message = message
            self.type = type
            self.position = position
            self.duration = duration
            self.hapticFeedback = hapticFeedback
        }
    }
    
    // MARK: - Properties
    
    /// Toast 視窗
    private var toastWindow: UIWindow?
    
    /// 當前顯示的 Toast 視圖陣列
    private var activeToasts: [ToastView] = []
    
    /// Toast 顯示計時器字典（用於管理自動隱藏）
    private var dismissTimers: [ToastView: Timer] = [:]
    
    /// 最大同時顯示數量
    private let maxConcurrentToasts = 3
    
    /// 操作佇列，確保線程安全
    private let operationQueue = DispatchQueue(label: "com.app.toastpresenter")
    
    /// 私有初始化，確保單例
    private init() {}
    
    // MARK: - Public Methods - Basic
    
    /// 顯示成功訊息
    func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        show(
            message,
            type: .success,
            hapticFeedback: .success,
            duration: duration
        )
    }
    
    /// 顯示錯誤訊息
    func showError(_ message: String, duration: TimeInterval = 3.0) {
        show(
            message,
            type: .error,
            hapticFeedback: .error,
            duration: duration
        )
    }
    
    /// 顯示警告訊息
    func showWarning(_ message: String, duration: TimeInterval = 3.0) {
        show(
            message,
            type: .warning,
            hapticFeedback: .warning,
            duration: duration
        )
    }
    
    /// 顯示資訊訊息
    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .info, duration: duration)
    }
    
    /// 顯示自訂樣式的 Toast
    func showCustom(
        _ message: String,
        backgroundColor: UIColor,
        textColor: UIColor = .white,
        icon: UIImage? = nil,
        position: ToastPosition = .bottom(),
        duration: TimeInterval = 3.0
    ) {
        let config = ToastConfiguration(
            message: message,
            type: .custom(backgroundColor: backgroundColor, textColor: textColor, icon: icon),
            position: position,
            duration: duration
        )
        show(configuration: config)
    }
    
    /// 通用顯示方法
    func show(
        _ message: String,
        type: ToastType = .info,
        position: ToastPosition = .bottom(),
        hapticFeedback: UINotificationFeedbackGenerator.FeedbackType? = nil,
        duration: TimeInterval = 3.0
    ) {
        let config = ToastConfiguration(
            message: message,
            type: type,
            position: position,
            duration: duration,
            hapticFeedback: hapticFeedback
        )
        show(configuration: config)
    }
    
    /// 隱藏所有 Toast
    func hideAll() {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            
            // 取消所有計時器
            self.dismissTimers.forEach { $0.value.invalidate() }
            self.dismissTimers.removeAll()
            
            // 消失所有 Toast
            self.activeToasts.forEach { $0.dismiss() }
            self.activeToasts.removeAll()
        }
    }
    
    // MARK: - Public Methods - Convenience
    
    /// 顯示儲存成功
    func showSaveSuccess() {
        showSuccess("儲存成功")
    }
    
    /// 顯示刪除成功
    func showDeleteSuccess() {
        showSuccess("刪除成功")
    }
    
    /// 顯示複製成功
    func showCopySuccess() {
        showSuccess("已複製到剪貼簿")
    }
    
    /// 顯示網路錯誤
    func showNetworkError() {
        showError("網路連線失敗，請檢查網路設定")
    }
    
    /// 顯示權限錯誤
    func showPermissionError(_ feature: String) {
        showError("需要\(feature)權限才能使用此功能")
    }
    
    /// 顯示操作成功（通用）
    func showActionSuccess(_ action: String) {
        showSuccess("\(action)成功")
    }
    
    /// 顯示操作失敗（通用）
    func showActionError(_ action: String) {
        showError("\(action)失敗")
    }
    
    // MARK: - Private Methods
    
    /// 顯示 Toast
    private func show(configuration: ToastConfiguration) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            
            // 確保有視窗
            self.ensureToastWindow()
            
            // 檢查數量限制
            if self.activeToasts.count >= self.maxConcurrentToasts {
                // 移除最舊的 Toast
                if let oldestToast = self.activeToasts.first {
                    self.dismissToast(oldestToast, animated: false)
                }
            }
            
            // 建立新的 Toast
            let toastView = ToastView(configuration: configuration)
            toastView.onDismiss = { [weak self, weak toastView] in
                guard let self = self, let toast = toastView else { return }
                self.removeToast(toast)
            }
            
            // 加入視窗
            self.toastWindow?.addSubview(toastView)
            self.activeToasts.append(toastView)
            
            // 計算位置並顯示
            self.layoutToast(toastView, at: configuration.position)
            toastView.show()
            
            // 觸覺回饋
            if let hapticType = configuration.hapticFeedback {
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(hapticType)
            }
            
            // 設置自動隱藏計時器
            self.scheduleAutoDismiss(for: toastView, duration: configuration.duration)
        }
    }
    
    /// 確保 Toast 視窗存在
    private func ensureToastWindow() {
        guard toastWindow == nil else { return }
        
        let window: UIWindow
        
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        
        // 設定視窗屬性
        window.windowLevel = .alert - 1  // 低於 Alert，高於 normal
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false  // 不阻擋觸摸事件
        window.isHidden = false
        
        // 建立透明的根視圖控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        window.rootViewController = viewController
        
        self.toastWindow = window
    }
    
    /// 佈局 Toast
    private func layoutToast(_ toast: ToastView, at position: ToastPosition) {
        guard let window = toastWindow else { return }
        
        // 確保 toast 已經被加入到視圖層次中
        guard toast.superview != nil else {
            print("⚠️ ToastPresenter: Toast 尚未加入父視圖，延遲佈局")
            DispatchQueue.main.async { [weak self] in
                self?.layoutToast(toast, at: position)
            }
            return
        }
        
        // 先設置基本約束（不包含位置）
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(window.snp.width).multipliedBy(0.9)
            make.width.greaterThanOrEqualTo(200)
        }
        
        // 強制佈局以獲取實際高度
        window.layoutIfNeeded()
        
        // 計算目標位置
        let targetY = position.calculateY(in: window, toastHeight: toast.bounds.height)
        
        // 設定初始位置和變換
        let initialTransform: CGAffineTransform
        
        switch position {
        case .top:
            initialTransform = CGAffineTransform(translationX: 0, y: -100)
        case .bottom:
            initialTransform = CGAffineTransform(translationX: 0, y: 100)
        case .center:
            initialTransform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        
        toast.transform = initialTransform
        toast.alpha = 0
        
        // 【關鍵修復】統一使用 top 約束，始終相對於 window.top
        // 這確保了初始約束和後續更新使用相同的參考點
        toast.snp.makeConstraints { make in
            make.top.equalTo(window.snp.top).offset(targetY)
        }
        
        // 執行進入動畫
        UIView.animate(
            withDuration: AppTheme.Animation.standardDuration,
            delay: 0,
            usingSpringWithDamping: AppTheme.Animation.springDamping,
            initialSpringVelocity: AppTheme.Animation.springVelocity,
            options: .curveEaseOut,
            animations: {
                toast.transform = .identity
                toast.alpha = 1.0
            }
        )
        
        // 調整其他 Toast 位置
        adjustToastPositions()
    }
    
    /// 調整 Toast 位置避免重疊
    private func adjustToastPositions() {
        guard let window = toastWindow else { return }
        
        // 按位置分組
        var toastGroups: [ToastPosition: [ToastView]] = [:]
        
        for toast in activeToasts {
            let position = toast.configuration.position
            // 使用簡化的分組鍵
            let groupKey: ToastPosition
            switch position {
            case .top:
                groupKey = .top()
            case .bottom:
                groupKey = .bottom()
            case .center:
                groupKey = .center
            }
            
            if toastGroups[groupKey] == nil {
                toastGroups[groupKey] = []
            }
            toastGroups[groupKey]?.append(toast)
        }
        
        // 調整每組的位置
        for (position, toasts) in toastGroups {
            guard toasts.count > 1 else { continue }
            
            var accumulatedOffset: CGFloat = 0
            
            for (index, toast) in toasts.enumerated() {
                guard index > 0 else { continue } // 第一個保持原位
                
                let previousToast = toasts[index - 1]
                accumulatedOffset += previousToast.bounds.height + 10 // 10pt 間距
                
                UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
                    // 【關鍵修復】使用 remakeConstraints 而非 updateConstraints
                    // 這避免了約束不匹配的問題
                    toast.snp.remakeConstraints { make in
                        make.centerX.equalToSuperview()
                        make.width.lessThanOrEqualTo(window.snp.width).multipliedBy(0.9)
                        make.width.greaterThanOrEqualTo(200)
                        
                        // 計算新的 Y 位置，始終相對於 window.top
                        let baseY: CGFloat
                        switch position {
                        case .top(let baseOffset):
                            baseY = window.safeAreaInsets.top + baseOffset + accumulatedOffset
                        case .bottom(let baseOffset):
                            // 對於底部位置，從視窗底部向上計算
                            let totalHeight = toast.bounds.height + accumulatedOffset
                            baseY = window.bounds.height - window.safeAreaInsets.bottom - baseOffset - totalHeight
                        case .center:
                            // 中心位置垂直堆疊
                            baseY = (window.bounds.height - toast.bounds.height) / 2 + accumulatedOffset
                        }
                        
                        // 統一使用 top 約束
                        make.top.equalTo(window.snp.top).offset(baseY)
                    }
                    
                    window.layoutIfNeeded()
                }
            }
        }
    }
    
    /// 設置自動消失計時器
    private func scheduleAutoDismiss(for toast: ToastView, duration: TimeInterval) {
        // 取消舊的計時器（如果存在）
        dismissTimers[toast]?.invalidate()
        
        // 創建新的計時器
        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self, weak toast] _ in
            guard let self = self, let toast = toast else { return }
            self.dismissToast(toast, animated: true)
        }
        
        dismissTimers[toast] = timer
    }
    
    /// 消失 Toast
    private func dismissToast(_ toast: ToastView, animated: Bool) {
        // 取消計時器
        dismissTimers[toast]?.invalidate()
        dismissTimers.removeValue(forKey: toast)
        
        if animated {
            toast.dismiss()
        } else {
            toast.removeFromSuperview()
            removeToast(toast)
        }
    }
    
    /// 移除 Toast
    private func removeToast(_ toast: ToastView) {
        operationQueue.async { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 從陣列中移除
                self.activeToasts.removeAll { $0 === toast }
                
                // 清理計時器
                self.dismissTimers[toast]?.invalidate()
                self.dismissTimers.removeValue(forKey: toast)
                
                // 如果沒有活動的 Toast，隱藏視窗
                if self.activeToasts.isEmpty {
                    self.hideToastWindow()
                } else {
                    // 重新調整位置
                    self.adjustToastPositions()
                }
            }
        }
    }
    
    /// 隱藏 Toast 視窗
    private func hideToastWindow() {
        toastWindow?.isHidden = true
        toastWindow = nil
    }
    
    /// 確保在主線程執行
    private func executeOnMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}

// MARK: - Combine Support

extension ToastPresenter {
    
    /// 執行操作並顯示結果 Toast
    /// - Parameters:
    ///   - loadingMessage: 載入訊息（可選）
    ///   - operation: 要執行的操作
    ///   - successMessage: 成功訊息
    ///   - errorHandler: 錯誤訊息處理
    /// - Returns: 操作結果 Publisher
    func performWithLoadingAndToast<T>(
        loadingMessage: String? = nil,
        operation: AnyPublisher<T, Error>,
        successMessage: String,
        errorHandler: @escaping (Error) -> String
    ) -> AnyPublisher<T, Error> {
        return operation
            .handleEvents(
                receiveSubscription: { _ in
                    if let message = loadingMessage {
                        LoadingPresenter.shared.show(message: message)
                    }
                },
                receiveOutput: { _ in
                    if loadingMessage != nil {
                        LoadingPresenter.shared.hide()
                    }
                    self.showSuccess(successMessage)
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        if loadingMessage != nil {
                            LoadingPresenter.shared.hide()
                        }
                        self.showError(errorHandler(error))
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}

// MARK: - ToastView

/// Toast 視圖
private class ToastView: ThemedView {
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let messageLabel = UILabel()
    private let stackView = UIStackView()
    
    // MARK: - Properties
    
    /// 配置資訊（供外部讀取）
    private(set) var configuration: ToastPresenter.ToastConfiguration
    
    /// 消失回調
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    
    init(configuration: ToastPresenter.ToastConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    override func setupView() {
        super.setupView()
        
        backgroundColor = .clear
        
        // 設定容器
        containerView.backgroundColor = configuration.type.backgroundColor
        containerView.layer.cornerRadius = AppTheme.Layout.toastCornerRadius
        containerView.layer.masksToBounds = true
        
        // 添加陰影（使用 AppTheme 定義的陰影樣式）
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        
        // 設定圖示
        if let icon = configuration.type.icon {
            iconImageView.image = icon
            iconImageView.tintColor = configuration.type.textColor
            iconImageView.contentMode = .scaleAspectFit
        }
        iconImageView.isHidden = configuration.type.icon == nil
        
        // 設定訊息標籤
        messageLabel.text = configuration.message
        messageLabel.textColor = configuration.type.textColor
        messageLabel.font = AppTheme.Fonts.callout
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        // 設定堆疊視圖
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = AppTheme.Layout.compactPadding
        
        // 組裝視圖
        if configuration.type.icon != nil {
            stackView.addArrangedSubview(iconImageView)
        }
        stackView.addArrangedSubview(messageLabel)
        
        containerView.addSubview(stackView)
        addSubview(containerView)
    }
    
    override func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(AppTheme.Layout.toastHeight)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppTheme.Layout.toastHorizontalPadding)
        }
        
        if configuration.type.icon != nil {
            iconImageView.snp.makeConstraints { make in
                make.width.height.equalTo(24)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 顯示 Toast
    func show() {
        // 動畫效果已在 ToastPresenter 中處理
    }
    
    /// 消失 Toast
    func dismiss() {
        UIView.animate(
            withDuration: AppTheme.Animation.fastDuration,
            animations: { [weak self] in
                self?.alpha = 0
                self?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            },
            completion: { [weak self] _ in
                self?.removeFromSuperview()
                self?.onDismiss?()
            }
        )
    }
}

// MARK: - Toast Position Equatable

extension ToastPresenter.ToastPosition: Equatable {
    static func == (lhs: ToastPresenter.ToastPosition, rhs: ToastPresenter.ToastPosition) -> Bool {
        switch (lhs, rhs) {
        case (.top, .top), (.bottom, .bottom), (.center, .center):
            return true
        default:
            return false
        }
    }
}

// MARK: - Toast Position Hashable

extension ToastPresenter.ToastPosition: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .top:
            hasher.combine(0)
        case .bottom:
            hasher.combine(1)
        case .center:
            hasher.combine(2)
        }
    }
}
