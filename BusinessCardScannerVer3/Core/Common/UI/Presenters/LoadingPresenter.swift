//
//  LoadingPresenter.swift
//  BusinessCardScanner
//
//  統一的載入狀態管理器
//

import UIKit
import Combine

/// 統一的載入狀態管理器
/// 負責管理應用程式中所有的載入指示器顯示
final class LoadingPresenter {
    
    // MARK: - Singleton
    
    /// 共享實例
    static let shared = LoadingPresenter()
    
    // MARK: - Types
    
    /// 載入樣式
    enum LoadingStyle {
        case modal      // 模態顯示（預設）
        case fullScreen // 全螢幕顯示
        case inline     // 行內顯示（在指定視圖中）
    }
    
    /// 載入配置
    struct LoadingConfiguration {
        let message: String?
        let style: LoadingStyle
        let showProgress: Bool
        let timeout: TimeInterval?
        let containerView: UIView?
        
        init(
            message: String? = nil,
            style: LoadingStyle = .modal,
            showProgress: Bool = false,
            timeout: TimeInterval? = 30.0,
            containerView: UIView? = nil
        ) {
            self.message = message
            self.style = style
            self.showProgress = showProgress
            self.timeout = timeout
            self.containerView = containerView
        }
    }
    
    // MARK: - Properties
    
    /// 載入視窗
    private var loadingWindow: UIWindow?
    
    /// 載入視圖容器
    private var loadingContainer: LoadingContainerView?
    
    /// 當前配置
    private var currentConfiguration: LoadingConfiguration?
    
    /// 超時計時器
    private var timeoutTimer: Timer?
    
    /// 是否正在顯示
    private(set) var isShowing: Bool = false
    
    /// 操作佇列，確保線程安全
    private let operationQueue = DispatchQueue(label: "com.app.loadingpresenter", attributes: .concurrent)
    
    /// 私有初始化，確保單例
    private init() {}
    
    // MARK: - Public Methods
    
    /// 顯示載入指示器
    /// - Parameters:
    ///   - message: 載入訊息
    ///   - style: 顯示樣式
    ///   - timeout: 超時時間（秒），nil 表示不設超時
    func show(
        message: String? = nil,
        style: LoadingStyle = .modal,
        timeout: TimeInterval? = 30.0
    ) {
        let config = LoadingConfiguration(
            message: message,
            style: style,
            showProgress: false,
            timeout: timeout
        )
        show(configuration: config)
    }
    
    /// 顯示進度載入指示器
    /// - Parameters:
    ///   - message: 載入訊息
    ///   - style: 顯示樣式
    ///   - timeout: 超時時間（秒）
    func showProgress(
        message: String? = nil,
        style: LoadingStyle = .modal,
        timeout: TimeInterval? = 30.0
    ) {
        let config = LoadingConfiguration(
            message: message,
            style: style,
            showProgress: true,
            timeout: timeout
        )
        show(configuration: config)
    }
    
    /// 在指定視圖中顯示載入
    /// - Parameters:
    ///   - message: 載入訊息
    ///   - containerView: 容器視圖
    func showInline(
        message: String? = nil,
        in containerView: UIView
    ) {
        let config = LoadingConfiguration(
            message: message,
            style: .inline,
            showProgress: false,
            timeout: nil,
            containerView: containerView
        )
        show(configuration: config)
    }
    
    /// 更新載入訊息
    /// - Parameter message: 新的訊息
    func updateMessage(_ message: String?) {
        executeOnMainThread { [weak self] in
            self?.loadingContainer?.updateMessage(message)
        }
    }
    
    /// 更新進度
    /// - Parameter progress: 進度值 (0.0 - 1.0)
    func updateProgress(_ progress: Float) {
        executeOnMainThread { [weak self] in
            self?.loadingContainer?.updateProgress(progress)
        }
    }
    
    /// 隱藏載入指示器
    /// - Parameter afterDelay: 延遲時間（秒），預設立即隱藏
    func hide(afterDelay delay: TimeInterval = 0) {
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.performHide()
            }
        } else {
            performHide()
        }
    }
    
    /// 隱藏載入指示器（如果是由指定物件顯示的）
    /// - Parameter owner: 顯示載入的物件
    func hideIfOwner(_ owner: AnyObject) {
        // 為了簡化實作，目前直接隱藏
        // 未來可以加入 owner 追蹤機制
        hide()
    }
    
    // MARK: - Private Methods
    
    /// 顯示載入指示器
    private func show(configuration: LoadingConfiguration) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            
            // 如果已經在顯示，更新配置
            if self.isShowing {
                self.updateConfiguration(configuration)
                return
            }
            
            self.isShowing = true
            self.currentConfiguration = configuration
            
            switch configuration.style {
            case .modal, .fullScreen:
                self.showWindowBasedLoading(configuration: configuration)
            case .inline:
                self.showInlineLoading(configuration: configuration)
            }
            
            // 設定超時
            if let timeout = configuration.timeout {
                self.startTimeoutTimer(timeout)
            }
        }
    }
    
    /// 顯示基於 Window 的載入（Modal 或 FullScreen）
    private func showWindowBasedLoading(configuration: LoadingConfiguration) {
        // 建立載入視窗
        let window = createLoadingWindow()
        self.loadingWindow = window
        
        // 建立載入容器
        let container = LoadingContainerView(configuration: configuration)
        self.loadingContainer = container
        
        // 設定視窗內容
        let viewController = UIViewController()
        viewController.view.backgroundColor = configuration.style == .fullScreen
            ? AppTheme.Colors.background
            : UIColor.black.withAlphaComponent(0.3)
        
        viewController.view.addSubview(container)
        container.snp.makeConstraints { make in
            if configuration.style == .fullScreen {
                make.edges.equalToSuperview()
            } else {
                make.center.equalToSuperview()
                make.width.equalTo(200)
                make.height.greaterThanOrEqualTo(120)
            }
        }
        
        window.rootViewController = viewController
        window.isHidden = false
        
        // 淡入動畫
        window.alpha = 0
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            window.alpha = 1.0
        }
    }
    
    /// 顯示行內載入
    private func showInlineLoading(configuration: LoadingConfiguration) {
        guard let containerView = configuration.containerView else { return }
        
        // 建立載入容器
        let container = LoadingContainerView(configuration: configuration)
        self.loadingContainer = container
        
        containerView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 淡入動畫
        container.alpha = 0
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            container.alpha = 1.0
        }
    }
    
    /// 更新配置
    private func updateConfiguration(_ configuration: LoadingConfiguration) {
        currentConfiguration = configuration
        loadingContainer?.update(configuration: configuration)
        
        // 重設超時
        timeoutTimer?.invalidate()
        if let timeout = configuration.timeout {
            startTimeoutTimer(timeout)
        }
    }
    
    /// 執行隱藏
    private func performHide() {
        executeOnMainThread { [weak self] in
            guard let self = self, self.isShowing else { return }
            
            self.isShowing = false
            self.timeoutTimer?.invalidate()
            self.timeoutTimer = nil
            
            // 淡出動畫
            UIView.animate(
                withDuration: AppTheme.Animation.fastDuration,
                animations: {
                    self.loadingWindow?.alpha = 0
                    self.loadingContainer?.alpha = 0
                },
                completion: { _ in
                    self.cleanup()
                }
            )
        }
    }
    
    /// 清理資源
    private func cleanup() {
        loadingContainer?.removeFromSuperview()
        loadingContainer = nil
        
        loadingWindow?.isHidden = true
        loadingWindow = nil
        
        currentConfiguration = nil
    }
    
    /// 建立載入視窗
    private func createLoadingWindow() -> UIWindow {
        let window: UIWindow
        
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        
        // 設定視窗層級高於一般視窗，但低於 Alert
        window.windowLevel = .normal + 1
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = true
        
        return window
    }
    
    /// 啟動超時計時器
    private func startTimeoutTimer(_ timeout: TimeInterval) {
        timeoutTimer?.invalidate()
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }
    }
    
    /// 處理超時
    private func handleTimeout() {
        hide()
        
        // 顯示超時提示
        DispatchQueue.main.async {
            ToastPresenter.shared.showWarning("操作超時，請稍後再試")
        }
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

extension LoadingPresenter {
    
    /// 執行操作並自動管理載入狀態
    /// - Parameters:
    ///   - message: 載入訊息
    ///   - operation: 要執行的操作 Publisher
    /// - Returns: 包裝後的 Publisher
    func performWithLoading<T>(
        message: String? = nil,
        operation: AnyPublisher<T, Error>
    ) -> AnyPublisher<T, Error> {
        return operation
            .handleEvents(
                receiveSubscription: { [weak self] _ in
                    self?.show(message: message)
                },
                receiveCompletion: { [weak self] _ in
                    self?.hide()
                },
                receiveCancel: { [weak self] in
                    self?.hide()
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// 執行異步操作並自動管理載入狀態
    /// - Parameters:
    ///   - message: 載入訊息
    ///   - operation: 異步操作
    /// - Returns: 操作結果
    @available(iOS 15.0, *)
    func performWithLoading<T>(
        message: String? = nil,
        operation: () async throws -> T
    ) async throws -> T {
        show(message: message)
        
        do {
            let result = try await operation()
            hide()
            return result
        } catch {
            hide()
            throw error
        }
    }
}

// MARK: - LoadingContainerView

/// 載入容器視圖
private class LoadingContainerView: ThemedView {
    
    // MARK: - UI Components
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let messageLabel = UILabel()
    private let containerStackView = UIStackView()
    
    // MARK: - Properties
    
    private var configuration: LoadingPresenter.LoadingConfiguration
    
    // MARK: - Initialization
    
    init(configuration: LoadingPresenter.LoadingConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    override func setupView() {
        super.setupView()
        
        // 根據樣式設定背景
        switch configuration.style {
        case .modal:
            backgroundColor = AppTheme.Colors.cardBackground
            applyCornerRadius(AppTheme.Layout.loadingCornerRadius)
            applyThemedShadow(style: AppTheme.Shadow.floating)
        case .fullScreen:
            backgroundColor = AppTheme.Colors.background
        case .inline:
            backgroundColor = AppTheme.Colors.background.withAlphaComponent(0.95)
        }
        
        // 設定活動指示器
        activityIndicator.color = AppTheme.Colors.primary
        activityIndicator.startAnimating()
        
        // 設定進度條
        progressView.progressTintColor = AppTheme.Colors.primary
        progressView.trackTintColor = AppTheme.Colors.separator
        progressView.isHidden = !configuration.showProgress
        
        // 設定訊息標籤
        messageLabel.font = AppTheme.Fonts.body
        messageLabel.textColor = AppTheme.Colors.primaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.text = configuration.message
        messageLabel.isHidden = configuration.message == nil
        
        // 設定堆疊視圖
        containerStackView.axis = .vertical
        containerStackView.alignment = .center
        containerStackView.distribution = .fill
        containerStackView.spacing = AppTheme.Layout.standardPadding
        
        // 組裝視圖
        containerStackView.addArrangedSubview(activityIndicator)
        if configuration.showProgress {
            containerStackView.addArrangedSubview(progressView)
        }
        if configuration.message != nil {
            containerStackView.addArrangedSubview(messageLabel)
        }
        
        addSubview(containerStackView)
    }
    
    override func setupConstraints() {
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppTheme.Layout.standardPadding * 2)
        }
        
        progressView.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.75)  // 父視圖寬度的 75%
            make.height.equalTo(4)
        }
    }
    
    // MARK: - Update Methods
    
    func update(configuration: LoadingPresenter.LoadingConfiguration) {
        self.configuration = configuration
        
        // 更新進度條顯示
        progressView.isHidden = !configuration.showProgress
        
        // 更新訊息
        updateMessage(configuration.message)
    }
    
    func updateMessage(_ message: String?) {
        messageLabel.text = message
        messageLabel.isHidden = message == nil
    }
    
    func updateProgress(_ progress: Float) {
        guard configuration.showProgress else { return }
        
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            self.progressView.setProgress(progress, animated: true)
        }
    }
}
