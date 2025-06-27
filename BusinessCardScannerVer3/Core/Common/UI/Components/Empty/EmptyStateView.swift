//
//  EmptyStateView.swift
//  BusinessCardScanner
//
//  空狀態視圖元件
//  位置：Core/Common/UI/Components/Empty/EmptyStateView.swift
//

import UIKit
import SnapKit
import Combine

/// 空狀態視圖元件
/// 用於顯示列表為空或無搜尋結果等狀態
class EmptyStateView: ThemedView {
    
    // MARK: - UI Components
    
    /// 圖示視圖
    private let imageView = UIImageView()
    
    /// 標題標籤
    private let titleLabel = UILabel()
    
    /// 描述訊息標籤
    private let messageLabel = UILabel()
    
    /// 操作按鈕
    private let actionButton = ThemedButton(style: .primary)
    
    /// 垂直堆疊視圖
    private let stackView = UIStackView()
    
    // MARK: - Properties
    
    /// 動作按鈕點擊回調
    var actionHandler: (() -> Void)?
    
    /// 是否顯示動作按鈕
    private var showActionButton: Bool = false {
        didSet {
            actionButton.isHidden = !showActionButton
        }
    }
    
    // MARK: - Setup
    
    override func setupView() {
        super.setupView()
        
        backgroundColor = .clear
        
        // 設定圖示
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppTheme.Colors.secondaryText
        
        // 設定標題
        titleLabel.font = AppTheme.Fonts.title3
        titleLabel.textColor = AppTheme.Colors.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // 設定訊息
        messageLabel.font = AppTheme.Fonts.body
        messageLabel.textColor = AppTheme.Colors.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // 設定按鈕
        actionButton.isHidden = true
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        // 設定堆疊視圖
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = AppTheme.Layout.standardPadding
        
        // 組合視圖
        [imageView, titleLabel, messageLabel, actionButton].forEach {
            stackView.addArrangedSubview($0)
        }
        
        // 設定間距
        stackView.setCustomSpacing(20, after: imageView)
        stackView.setCustomSpacing(12, after: titleLabel)
        stackView.setCustomSpacing(24, after: messageLabel)
        
        addSubview(stackView)
    }
    
    override func setupConstraints() {
        // 圖示大小約束
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(80)
        }
        
        // 堆疊視圖約束
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
        }
        
        // 標題和訊息寬度約束
        [titleLabel, messageLabel].forEach { label in
            label.snp.makeConstraints { make in
                make.width.equalTo(stackView)
            }
        }
        
        // 按鈕寬度約束
        actionButton.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(160)
        }
    }
    
    // MARK: - Configuration
    
    /// 設定空狀態內容
    /// - Parameters:
    ///   - image: 圖示圖片
    ///   - title: 標題文字
    ///   - message: 描述訊息
    ///   - actionTitle: 操作按鈕標題（可選）
    func configure(
        image: UIImage?,
        title: String,
        message: String,
        actionTitle: String? = nil
    ) {
        imageView.image = image
        titleLabel.text = title
        messageLabel.text = message
        
        if let actionTitle = actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
            showActionButton = true
        } else {
            showActionButton = false
        }
    }
    
    /// 設定自定義圖示大小
    /// - Parameter size: 圖示尺寸
    func setImageSize(_ size: CGFloat) {
        imageView.snp.updateConstraints { make in
            make.width.height.equalTo(size)
        }
    }
    
    /// 設定自定義間距
    /// - Parameter spacing: 元件間距
    func setSpacing(_ spacing: CGFloat) {
        stackView.spacing = spacing
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped() {
        actionHandler?()
    }
    
    // MARK: - Animation
    
    /// 顯示空狀態（帶動畫）
    /// - Parameter animated: 是否使用動畫
    func show(animated: Bool = true) {
        guard animated else {
            alpha = 1
            return
        }
        
        // 淡入動畫
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(
            withDuration: AppTheme.Animation.standardDuration,
            delay: 0,
            usingSpringWithDamping: AppTheme.Animation.springDamping,
            initialSpringVelocity: AppTheme.Animation.springVelocity,
            options: .curveEaseOut,
            animations: {
                self.alpha = 1
                self.transform = .identity
            }
        )
    }
    
    /// 隱藏空狀態（帶動畫）
    /// - Parameters:
    ///   - animated: 是否使用動畫
    ///   - completion: 完成回調
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard animated else {
            alpha = 0
            completion?()
            return
        }
        
        UIView.animate(
            withDuration: AppTheme.Animation.fastDuration,
            animations: {
                self.alpha = 0
            },
            completion: { _ in
                completion?()
            }
        )
    }
}

// MARK: - Convenience Factory Methods

extension EmptyStateView {
    
    /// 建立「無資料」空狀態
    static func makeNoDataState(actionTitle: String? = nil) -> EmptyStateView {
        let view = EmptyStateView()
        view.configure(
            image: UIImage(systemName: "doc.text.magnifyingglass"),
            title: "還沒有資料",
            message: "開始新增您的第一筆資料",
            actionTitle: actionTitle
        )
        return view
    }
    
    /// 建立「無搜尋結果」空狀態
    static func makeNoSearchResultsState() -> EmptyStateView {
        let view = EmptyStateView()
        view.configure(
            image: UIImage(systemName: "magnifyingglass"),
            title: "找不到結果",
            message: "試試其他關鍵字"
        )
        return view
    }
    
    /// 建立「網路錯誤」空狀態
    static func makeNetworkErrorState(retryAction: (() -> Void)? = nil) -> EmptyStateView {
        let view = EmptyStateView()
        view.configure(
            image: UIImage(systemName: "wifi.exclamationmark"),
            title: "網路連線失敗",
            message: "請檢查您的網路連線",
            actionTitle: "重試"
        )
        view.actionHandler = retryAction
        return view
    }
    
    /// 建立「載入錯誤」空狀態
    static func makeLoadingErrorState(retryAction: (() -> Void)? = nil) -> EmptyStateView {
        let view = EmptyStateView()
        view.configure(
            image: UIImage(systemName: "exclamationmark.triangle"),
            title: "載入失敗",
            message: "發生錯誤，請稍後再試",
            actionTitle: "重試"
        )
        view.actionHandler = retryAction
        return view
    }
    
    /// 建立自定義空狀態
    /// - Parameters:
    ///   - config: 空狀態配置
    /// - Returns: 設定好的空狀態視圖
    static func makeCustomState(_ config: EmptyStateConfiguration) -> EmptyStateView {
        let view = EmptyStateView()
        view.configure(
            image: config.image,
            title: config.title,
            message: config.message,
            actionTitle: config.actionTitle
        )
        view.actionHandler = config.actionHandler
        
        if let imageSize = config.imageSize {
            view.setImageSize(imageSize)
        }
        
        if let spacing = config.spacing {
            view.setSpacing(spacing)
        }
        
        return view
    }
}

// MARK: - Configuration Model

/// 空狀態配置模型
struct EmptyStateConfiguration {
    let image: UIImage?
    let title: String
    let message: String
    let actionTitle: String?
    let actionHandler: (() -> Void)?
    let imageSize: CGFloat?
    let spacing: CGFloat?
    
    init(
        image: UIImage?,
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionHandler: (() -> Void)? = nil,
        imageSize: CGFloat? = nil,
        spacing: CGFloat? = nil
    ) {
        self.image = image
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionHandler = actionHandler
        self.imageSize = imageSize
        self.spacing = spacing
    }
}

// MARK: - Combine Extension

extension EmptyStateView {
    
    /// 動作按鈕點擊事件 Publisher
    var actionPublisher: AnyPublisher<Void, Never> {
        actionButton.tapPublisher
    }
}
