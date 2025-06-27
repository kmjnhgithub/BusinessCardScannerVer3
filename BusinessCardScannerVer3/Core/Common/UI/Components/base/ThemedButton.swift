//
//  ThemedButton.swift
//  BusinessCardScanner
//
//  統一樣式的按鈕元件
//

import UIKit
import SnapKit
import Combine

/// 統一樣式的按鈕元件
/// 支援多種預設樣式和載入狀態
class ThemedButton: UIButton {
    
    // MARK: - Types
    
    /// 按鈕樣式類型
    enum Style {
        case primary    // 主要按鈕
        case secondary  // 次要按鈕
        case text       // 文字按鈕
        case danger     // 危險操作按鈕
        
        /// 背景色
        var backgroundColor: UIColor {
            switch self {
            case .primary:
                return AppTheme.Colors.primary
            case .secondary:
                return AppTheme.Colors.secondary
            case .text:
                return .clear
            case .danger:
                return AppTheme.Colors.error
            }
        }
        
        /// 文字顏色
        var titleColor: UIColor {
            switch self {
            case .primary, .secondary, .danger:
                return .white
            case .text:
                return AppTheme.Colors.primary
            }
        }
        
        /// 是否需要邊框
        var needsBorder: Bool {
            return self == .text
        }
    }
    
    // MARK: - Properties
    
    private let style: Style
    private var activityIndicator: UIActivityIndicatorView?
    private var originalButtonText: String?
    
    /// 是否正在載入
    var isLoading: Bool = false {
        didSet {
            updateLoadingState()
        }
    }
    
    /// 按鈕最小寬度約束
    private var minWidthConstraint: Constraint?
    
    // MARK: - Initialization
    
    /// 初始化按鈕
    /// - Parameter style: 按鈕樣式，預設為 primary
    init(style: Style = .primary) {
        self.style = style
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        self.style = .primary
        super.init(coder: coder)
        setupButton()
    }
    
    // MARK: - Setup
    
    private func setupButton() {
        // 基本樣式設定
        backgroundColor = style.backgroundColor
        setTitleColor(style.titleColor, for: .normal)
        titleLabel?.font = AppTheme.Fonts.buttonTitle
        
        // 圓角設定
        layer.cornerRadius = AppTheme.Layout.buttonCornerRadius
        layer.masksToBounds = true
        
        // 邊框設定（僅文字按鈕）
        if style.needsBorder {
            layer.borderWidth = 1
            layer.borderColor = AppTheme.Colors.primary.cgColor
        }
        
        // 內容邊距設定
        contentEdgeInsets = UIEdgeInsets(
            top: 0,
            left: AppTheme.Layout.buttonHorizontalPadding,
            bottom: 0,
            right: AppTheme.Layout.buttonHorizontalPadding
        )
        
        // 高度和最小寬度約束
        snp.makeConstraints { make in
            make.height.equalTo(AppTheme.Layout.buttonHeight)
            self.minWidthConstraint = make.width.greaterThanOrEqualTo(AppTheme.Layout.buttonMinWidth).constraint
        }
        
        // 按下效果
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // 設定禁用狀態樣式
        adjustsImageWhenDisabled = false
    }
    
    // MARK: - Loading State
    
    private func updateLoadingState() {
        if isLoading {
            // 儲存原始文字
            originalButtonText = title(for: .normal)
            
            // 禁用按鈕
            isEnabled = false
            
            // 隱藏標題
            setTitle("", for: .normal)
            
            // 建立並顯示載入指示器
            if activityIndicator == nil {
                let indicator = UIActivityIndicatorView(style: .white)
                indicator.hidesWhenStopped = true
                addSubview(indicator)
                indicator.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                }
                activityIndicator = indicator
            }
            activityIndicator?.startAnimating()
            
        } else {
            // 恢復按鈕狀態
            isEnabled = true
            
            // 恢復原始文字
            if let originalText = originalButtonText {
                setTitle(originalText, for: .normal)
            }
            
            // 停止載入指示器
            activityIndicator?.stopAnimating()
        }
    }
    
    // MARK: - Touch Feedback
    
    @objc private func touchDown() {
        // 按下動畫效果
        UIView.animate(withDuration: AppTheme.Animation.fastDuration,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
            self.transform = CGAffineTransform(scaleX: AppTheme.Animation.buttonPressScale,
                                               y: AppTheme.Animation.buttonPressScale)
            self.alpha = AppTheme.Animation.buttonPressAlpha
        })
    }
    
    @objc private func touchUp() {
        // 釋放動畫效果
        UIView.animate(withDuration: AppTheme.Animation.fastDuration,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
            self.transform = .identity
            self.alpha = 1.0
        })
    }
    
    // MARK: - State Override
    
    override var isEnabled: Bool {
        didSet {
            // 更新禁用狀態的外觀
            alpha = isEnabled ? 1.0 : 0.5
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            // 高亮狀態已由 touchDown/touchUp 處理
        }
    }
    
    // MARK: - Public Methods
    
    /// 設定按鈕標題並自動調整寬度
    /// - Parameters:
    ///   - title: 按鈕標題
    ///   - state: 按鈕狀態
    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        
        // 如果文字較長，可以取消最小寬度限制
        if let title = title, title.count > 10 {
            minWidthConstraint?.deactivate()
        }
    }
}

// MARK: - Combine Extension

extension ThemedButton {
    
    /// 點擊事件 Publisher
    /// 提供響應式的點擊事件流
    var tapPublisher: AnyPublisher<Void, Never> {
        controlPublisher(for: .touchUpInside)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

// MARK: - UIControl Publisher Extension

extension UIControl {
    
    /// 將 UIControl 事件轉換為 Publisher
    /// - Parameter event: 控制事件
    /// - Returns: 事件 Publisher
    func controlPublisher(for event: UIControl.Event) -> UIControl.EventPublisher {
        return UIControl.EventPublisher(control: self, event: event)
    }
    
    /// UIControl 事件 Publisher
    struct EventPublisher: Publisher {
        typealias Output = UIControl
        typealias Failure = Never
        
        let control: UIControl
        let event: UIControl.Event
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, UIControl == S.Input {
            let subscription = EventSubscription(
                control: control,
                event: event,
                subscriber: subscriber
            )
            subscriber.receive(subscription: subscription)
        }
    }
    
    /// UIControl 事件訂閱
    fileprivate class EventSubscription<S: Subscriber>: Subscription where S.Input == UIControl, S.Failure == Never {
        
        private var subscriber: S?
        private weak var control: UIControl?
        private let event: UIControl.Event
        
        init(control: UIControl, event: UIControl.Event, subscriber: S) {
            self.control = control
            self.event = event
            self.subscriber = subscriber
            
            control.addTarget(self, action: #selector(handleEvent), for: event)
        }
        
        func request(_ demand: Subscribers.Demand) {
            // 無需處理背壓，UIControl 事件是用戶觸發的
        }
        
        func cancel() {
            control?.removeTarget(self, action: #selector(handleEvent), for: event)
            subscriber = nil
        }
        
        @objc private func handleEvent() {
            guard let control = control else { return }
            _ = subscriber?.receive(control)
        }
        
        deinit {
            cancel()
        }
    }
}
