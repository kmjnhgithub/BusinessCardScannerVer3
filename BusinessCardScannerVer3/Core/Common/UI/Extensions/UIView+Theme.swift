//
//  UIView+Theme.swift
//  BusinessCardScanner
//
//  UIView 主題相關擴展
//

import UIKit
import SnapKit

// MARK: - Theme Extensions

extension UIView {
    
    // MARK: - Layout Helpers
    
    /// 套用標準內間距
    /// 使用 AppTheme 定義的 standardPadding 值
    func applyStandardPadding() {
        layoutMargins = UIEdgeInsets(
            top: AppTheme.Layout.standardPadding,
            left: AppTheme.Layout.standardPadding,
            bottom: AppTheme.Layout.standardPadding,
            right: AppTheme.Layout.standardPadding
        )
    }
    
    /// 套用自定義內間距
    /// - Parameter insets: 自定義邊距值
    func applyPadding(_ insets: UIEdgeInsets) {
        layoutMargins = insets
    }
    
    /// 套用統一內間距
    /// - Parameter padding: 四邊統一的間距值
    func applyPadding(_ padding: CGFloat) {
        layoutMargins = UIEdgeInsets(
            top: padding,
            left: padding,
            bottom: padding,
            right: padding
        )
    }
    
    // MARK: - Style Helpers
    
    /// 套用卡片樣式
    /// 包含背景色、圓角和陰影
    func applyCardStyle() {
        backgroundColor = AppTheme.Colors.cardBackground
        layer.cornerRadius = AppTheme.Layout.cardCornerRadius
        
        // 套用陰影
        let shadow = AppTheme.Shadow.card
        layer.shadowColor = shadow.color
        layer.shadowOpacity = shadow.opacity
        layer.shadowRadius = shadow.radius
        layer.shadowOffset = shadow.offset
        layer.masksToBounds = false
    }
    
    /// 套用按鈕樣式
    /// - Parameter style: 按鈕樣式類型
    func applyButtonStyle(_ style: ThemedButton.Style) {
        backgroundColor = style.backgroundColor
        layer.cornerRadius = AppTheme.Layout.buttonCornerRadius
        layer.masksToBounds = true
        
        if style.needsBorder {
            layer.borderWidth = 1
            layer.borderColor = AppTheme.Colors.primary.cgColor
        }
    }
    
    /// 套用輸入框樣式
    func applyTextFieldStyle() {
        backgroundColor = AppTheme.Colors.cardBackground
        layer.cornerRadius = AppTheme.Layout.smallCornerRadius
        layer.borderWidth = 1
        layer.borderColor = AppTheme.Colors.separator.cgColor
    }
    
    // MARK: - Border & Separator
    
    /// 添加邊框
    /// - Parameters:
    ///   - width: 邊框寬度，預設 1pt
    ///   - color: 邊框顏色，預設分隔線顏色
    ///   - cornerRadius: 圓角半徑，預設 0
    func addBorder(width: CGFloat = 1,
                   color: UIColor = AppTheme.Colors.separator,
                   cornerRadius: CGFloat = 0) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = cornerRadius > 0
    }
    
    /// 移除邊框
    func removeBorder() {
        layer.borderWidth = 0
        layer.borderColor = nil
    }
    
    /// 添加分隔線
    /// - Parameters:
    ///   - position: 分隔線位置
    ///   - color: 分隔線顏色，預設使用主題分隔線顏色
    ///   - thickness: 分隔線厚度，預設使用主題定義值
    ///   - insets: 左右邊距
    @discardableResult
    func addSeparator(at position: SeparatorPosition = .bottom,
                      color: UIColor = AppTheme.Colors.separator,
                      thickness: CGFloat = AppTheme.Layout.separatorHeight,
                      insets: UIEdgeInsets = .zero) -> UIView {
        let separator = UIView()
        separator.backgroundColor = color
        separator.tag = position.rawValue // 用於識別
        addSubview(separator)
        
        separator.snp.makeConstraints { make in
            switch position {
            case .top:
                make.top.equalToSuperview()
                make.left.equalToSuperview().inset(insets.left)
                make.right.equalToSuperview().inset(insets.right)
                make.height.equalTo(thickness)
                
            case .bottom:
                make.bottom.equalToSuperview()
                make.left.equalToSuperview().inset(insets.left)
                make.right.equalToSuperview().inset(insets.right)
                make.height.equalTo(thickness)
                
            case .left:
                make.left.equalToSuperview()
                make.top.equalToSuperview().inset(insets.top)
                make.bottom.equalToSuperview().inset(insets.bottom)
                make.width.equalTo(thickness)
                
            case .right:
                make.right.equalToSuperview()
                make.top.equalToSuperview().inset(insets.top)
                make.bottom.equalToSuperview().inset(insets.bottom)
                make.width.equalTo(thickness)
            }
        }
        
        return separator
    }
    
    /// 移除分隔線
    /// - Parameter position: 要移除的分隔線位置
    func removeSeparator(at position: SeparatorPosition) {
        subviews.first { $0.tag == position.rawValue }?.removeFromSuperview()
    }
    
    /// 移除所有分隔線
    func removeAllSeparators() {
        SeparatorPosition.allCases.forEach { position in
            removeSeparator(at: position)
        }
    }
    
    // MARK: - Shadow Helpers
    
    /// 套用陰影
    /// - Parameter style: 陰影樣式，預設使用卡片陰影
    func applyShadow(_ style: AppTheme.Shadow.ShadowStyle = AppTheme.Shadow.card) {
        layer.shadowColor = style.color
        layer.shadowOpacity = style.opacity
        layer.shadowRadius = style.radius
        layer.shadowOffset = style.offset
        layer.masksToBounds = false
    }
    
    /// 移除陰影
    func removeShadow() {
        layer.shadowOpacity = 0
    }
    
    /// 更新陰影路徑（優化效能）
    func updateShadowPath() {
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: layer.cornerRadius
        ).cgPath
    }
    
    // MARK: - Corner Radius
    
    /// 設定圓角
    /// - Parameters:
    ///   - radius: 圓角半徑
    ///   - corners: 指定圓角的位置，預設所有角
    func setCornerRadius(_ radius: CGFloat,
                        corners: UIRectCorner = .allCorners) {
        if corners == .allCorners {
            layer.cornerRadius = radius
            layer.masksToBounds = true
        } else {
            // 部分圓角需要使用 mask
            let path = UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }
    
    /// 設定圓形（寬高相等時）
    func makeCircular() {
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        layer.masksToBounds = true
    }
    
    // MARK: - Animation Helpers
    
    /// 添加脈衝動畫
    /// - Parameters:
    ///   - scale: 縮放比例
    ///   - duration: 動畫時長
    func addPulseAnimation(scale: CGFloat = 1.1,
                          duration: TimeInterval = 1.0) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = duration
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = scale
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        layer.add(pulseAnimation, forKey: "pulse")
    }
    
    /// 移除脈衝動畫
    func removePulseAnimation() {
        layer.removeAnimation(forKey: "pulse")
    }
    
    /// 添加震動動畫
    /// - Parameters:
    ///   - intensity: 震動強度
    ///   - duration: 動畫時長
    func shake(intensity: CGFloat = 10,
               duration: TimeInterval = 0.6) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = duration
        
        let values = stride(from: 0, to: 10, by: 1).map { i -> CGFloat in
            let multiplier = (10 - CGFloat(i)) / 10
            return i.truncatingRemainder(dividingBy: 2) == 0 ? intensity * multiplier : -intensity * multiplier
        }
        animation.values = values + [0]
        
        layer.add(animation, forKey: "shake")
    }
}

// MARK: - Separator Position Enum

/// 分隔線位置枚舉
enum SeparatorPosition: Int, CaseIterable {
    case top = 1001
    case bottom = 1002
    case left = 1003
    case right = 1004
}

// MARK: - Gradient Extension

extension UIView {
    
    /// 添加漸層背景
    /// - Parameters:
    ///   - colors: 漸層顏色陣列
    ///   - startPoint: 起始點（0-1）
    ///   - endPoint: 結束點（0-1）
    ///   - type: 漸層類型
    @discardableResult
    func addGradient(colors: [UIColor],
                     startPoint: CGPoint = CGPoint(x: 0, y: 0),
                     endPoint: CGPoint = CGPoint(x: 1, y: 1),
                     type: CAGradientLayerType = .axial) -> CAGradientLayer {
        // 移除舊的漸層
        layer.sublayers?.first { $0 is CAGradientLayer }?.removeFromSuperlayer()
        
        // 建立新漸層
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.type = type
        gradientLayer.frame = bounds
        
        layer.insertSublayer(gradientLayer, at: 0)
        return gradientLayer
    }
    
    /// 移除漸層背景
    func removeGradient() {
        layer.sublayers?.first { $0 is CAGradientLayer }?.removeFromSuperlayer()
    }
}

// MARK: - Loading State Extension

extension UIView {
    
    private struct AssociatedKeys {
        static var loadingView = "loadingView"
    }
    
    /// 顯示載入狀態
    /// - Parameters:
    ///   - message: 載入訊息（可選）
    ///   - style: 活動指示器樣式
    func showLoading(message: String? = nil,
                     style: UIActivityIndicatorView.Style = .medium) {
        hideLoading() // 先移除舊的
        
        // 建立載入視圖
        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loadingView.layer.cornerRadius = 8
        
        // 活動指示器
        let activityIndicator = UIActivityIndicatorView(style: style)
        activityIndicator.startAnimating()
        
        loadingView.addSubview(activityIndicator)
        
        // 如果有訊息，添加標籤
        if let message = message {
            let label = UILabel()
            label.text = message
            label.font = AppTheme.Fonts.footnote
            label.textColor = .white
            loadingView.addSubview(label)
            
            // 佈局
            activityIndicator.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(16)
            }
            
            label.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(activityIndicator.snp.bottom).offset(8)
                make.bottom.equalToSuperview().offset(-16)
                make.left.right.equalToSuperview().inset(16)
            }
        } else {
            activityIndicator.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.edges.equalToSuperview().inset(16)
            }
        }
        
        // 添加到當前視圖
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // 保存參考
        objc_setAssociatedObject(self, &AssociatedKeys.loadingView, loadingView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 淡入動畫
        loadingView.alpha = 0
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            loadingView.alpha = 1
        }
    }
    
    /// 隱藏載入狀態
    func hideLoading() {
        guard let loadingView = objc_getAssociatedObject(self, &AssociatedKeys.loadingView) as? UIView else { return }
        
        UIView.animate(withDuration: AppTheme.Animation.fastDuration,
                      animations: {
            loadingView.alpha = 0
        }, completion: { _ in
            loadingView.removeFromSuperview()
            objc_setAssociatedObject(self, &AssociatedKeys.loadingView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        })
    }
}

