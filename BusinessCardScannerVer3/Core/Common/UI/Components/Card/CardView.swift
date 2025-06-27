//
//  CardView.swift
//  BusinessCardScanner
//
//  卡片容器視圖元件
//  位置：Core/Common/UI/Components/Card/CardView.swift
//

import UIKit
import SnapKit

/// 卡片容器視圖
/// 提供統一的卡片樣式，包含陰影、圓角和內容區域
class CardView: ThemedView {
    
    // MARK: - Properties
    
    /// 是否顯示陰影
    var showShadow: Bool = true {
        didSet {
            updateShadow()
        }
    }
    
    /// 內容容器視圖
    private let contentView = UIView()
    
    /// 內容邊距
    var contentInsets: UIEdgeInsets = UIEdgeInsets(
        top: AppTheme.Layout.cardPadding,
        left: AppTheme.Layout.cardPadding,
        bottom: AppTheme.Layout.cardPadding,
        right: AppTheme.Layout.cardPadding
    ) {
        didSet {
            updateContentConstraints()
        }
    }
    
    /// 內容視圖約束參考
    private var contentConstraints: [Constraint] = []
    
    // MARK: - Setup
    
    override func setupView() {
        super.setupView()
        
        // 設定卡片背景
        backgroundColor = AppTheme.Colors.cardBackground
        
        // 設定圓角
        applyCornerRadius(AppTheme.Layout.cardCornerRadius)
        
        // 加入內容容器
        addSubview(contentView)
        contentView.backgroundColor = .clear
        
        // 預設顯示陰影
        updateShadow()
    }
    
    override func setupConstraints() {
        // 設定內容容器約束
        updateContentConstraints()
    }
    
    // MARK: - Public Methods
    
    /// 設定卡片內容
    /// - Parameter view: 要顯示的內容視圖
    func setContent(_ view: UIView) {
        // 移除現有內容
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // 加入新內容
        contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    /// 設定多個內容視圖（垂直排列）
    /// - Parameters:
    ///   - views: 內容視圖陣列
    ///   - spacing: 視圖間距
    func setContentViews(_ views: [UIView], spacing: CGFloat = AppTheme.Layout.standardPadding) {
        // 移除現有內容
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // 建立垂直堆疊視圖
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.spacing = spacing
        stackView.distribution = .fill
        stackView.alignment = .fill
        
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    /// 添加分隔線
    /// - Parameter insets: 分隔線的左右邊距
    func addSeparator(insets: UIEdgeInsets = .zero) {
        let separator = UIView()
        separator.backgroundColor = AppTheme.Colors.separator
        
        addSubview(separator)
        separator.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(insets.left)
            make.right.equalToSuperview().inset(insets.right)
            make.bottom.equalToSuperview()
            make.height.equalTo(AppTheme.Layout.separatorHeight)
        }
    }
    
    /// 設定點擊高亮效果
    /// - Parameter enabled: 是否啟用高亮效果
    func setHighlightable(_ enabled: Bool) {
        if enabled {
            // 加入手勢識別器
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            addGestureRecognizer(tapGesture)
            
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            longPressGesture.minimumPressDuration = 0.0
            addGestureRecognizer(longPressGesture)
        } else {
            // 移除所有手勢識別器
            gestureRecognizers?.forEach { removeGestureRecognizer($0) }
        }
    }
    
    // MARK: - Private Methods
    
    /// 更新陰影顯示
    private func updateShadow() {
        if showShadow {
            applyShadow(AppTheme.Shadow.card)
        } else {
            layer.shadowOpacity = 0
        }
    }
    
    /// 更新內容約束
    private func updateContentConstraints() {
        // 移除舊約束
        contentConstraints.forEach { $0.deactivate() }
        contentConstraints.removeAll()
        
        // 設定新約束
        contentView.snp.makeConstraints { make in
            let topConstraint = make.top.equalToSuperview().inset(contentInsets.top).constraint
            let leftConstraint = make.left.equalToSuperview().inset(contentInsets.left).constraint
            let bottomConstraint = make.bottom.equalToSuperview().inset(contentInsets.bottom).constraint
            let rightConstraint = make.right.equalToSuperview().inset(contentInsets.right).constraint
            
            contentConstraints = [topConstraint, leftConstraint, bottomConstraint, rightConstraint]
        }
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleTap() {
        // 點擊效果已由 longPress 處理
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            // 按下效果
            UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
                self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                self.alpha = 0.9
            }
            
        case .ended, .cancelled, .failed:
            // 釋放效果
            UIView.animate(withDuration: AppTheme.Animation.fastDuration,
                          delay: 0,
                          usingSpringWithDamping: AppTheme.Animation.springDamping,
                          initialSpringVelocity: AppTheme.Animation.springVelocity,
                          options: .curveEaseOut,
                          animations: {
                self.transform = .identity
                self.alpha = 1.0
            })
            
        default:
            break
        }
    }
    
    // MARK: - Tap Handler Closure
    
    /// 點擊事件回調
    var onTap: (() -> Void)?
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        // 如果有設定點擊回調，執行它
        if let touch = touches.first,
           bounds.contains(touch.location(in: self)) {
            onTap?()
        }
    }
}

// MARK: - Convenience Initializers

extension CardView {
    
    /// 建立包含標題和內容的卡片
    /// - Parameters:
    ///   - title: 標題文字
    ///   - content: 內容視圖
    /// - Returns: 設定好的卡片視圖
    static func makeWithTitle(_ title: String, content: UIView) -> CardView {
        let card = CardView()
        
        // 建立標題標籤
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppTheme.Fonts.title3
        titleLabel.textColor = AppTheme.Colors.primaryText
        
        // 建立分隔線
        let separator = SeparatorView.fullWidth()
        
        // 組合內容
        card.setContentViews([titleLabel, separator, content])
        
        return card
    }
    
    /// 建立可點擊的卡片
    /// - Parameters:
    ///   - content: 內容視圖
    ///   - onTap: 點擊回調
    /// - Returns: 設定好的卡片視圖
    static func makeClickable(content: UIView, onTap: @escaping () -> Void) -> CardView {
        let card = CardView()
        card.setContent(content)
        card.setHighlightable(true)
        card.onTap = onTap
        return card
    }
}
