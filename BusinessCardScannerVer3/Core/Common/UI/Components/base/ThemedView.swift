//
//  ThemedView.swift
//  BusinessCardScanner
//
//  基礎視圖類，提供主題化支援
//  位置：Core/Common/UI/Components/Base/ThemedView.swift
//

import UIKit
import SnapKit

/// 基礎視圖類，提供主題化支援
/// 所有自定義視圖元件應繼承此類以獲得統一的設定方法和主題支援
class ThemedView: UIView {
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 🔧 修復 Auto Layout 約束衝突：確保使用 SnapKit 約束而非 AutoresizingMask
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // 🔧 修復 Auto Layout 約束衝突：確保使用 SnapKit 約束而非 AutoresizingMask
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    /// 設定視圖屬性，子類別覆寫此方法來設定外觀
    /// 預設設定背景色為 AppTheme 定義的背景色
    func setupView() {
        backgroundColor = AppTheme.Colors.background
    }
    
    /// 設定 Auto Layout 約束，子類別覆寫此方法來設定佈局
    /// 使用 SnapKit 進行約束設定
    func setupConstraints() {
        // 子類別實作具體約束
    }
    
    // MARK: - Theme Support
    
    /// 套用圓角樣式
    /// - Parameter radius: 圓角半徑，預設使用 AppTheme 定義的標準圓角
    func applyCornerRadius(_ radius: CGFloat = AppTheme.Layout.cornerRadius) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
    
    /// 套用陰影樣式
    /// - Parameter style: 陰影樣式，預設使用卡片陰影
    /// - Note: 設定陰影時會自動將 masksToBounds 設為 false
    func applyThemedShadow(style: AppTheme.Shadow.ShadowStyle = AppTheme.Shadow.card) {
        layer.shadowColor = style.color
        layer.shadowOpacity = style.opacity
        layer.shadowRadius = style.radius
        layer.shadowOffset = style.offset
        layer.masksToBounds = false
    }
    
    /// 套用邊框樣式
    /// - Parameters:
    ///   - width: 邊框寬度
    ///   - color: 邊框顏色
    func applyBorder(width: CGFloat = 1, color: UIColor = AppTheme.Colors.separator) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    // MARK: - Animation Helpers
    
    /// 執行淡入動畫
    /// - Parameters:
    ///   - duration: 動畫時長，預設使用標準時長
    ///   - completion: 動畫完成回調
    func fadeIn(duration: TimeInterval = AppTheme.Animation.standardDuration,
                completion: (() -> Void)? = nil) {
        alpha = 0
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: AppTheme.Animation.standardCurve,
                       animations: { self.alpha = 1 },
                       completion: { _ in completion?() })
    }
    
    /// 執行淡出動畫
    /// - Parameters:
    ///   - duration: 動畫時長，預設使用標準時長
    ///   - completion: 動畫完成回調
    func fadeOut(duration: TimeInterval = AppTheme.Animation.standardDuration,
                 completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: AppTheme.Animation.standardCurve,
                       animations: { self.alpha = 0 },
                       completion: { _ in completion?() })
    }
    
    /// 執行縮放動畫
    /// - Parameters:
    ///   - scale: 縮放比例
    ///   - duration: 動畫時長
    ///   - completion: 動畫完成回調
    func animateScale(to scale: CGFloat,
                      duration: TimeInterval = AppTheme.Animation.fastDuration,
                      completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: AppTheme.Animation.springDamping,
                       initialSpringVelocity: AppTheme.Animation.springVelocity,
                       options: .curveEaseInOut,
                       animations: { self.transform = CGAffineTransform(scaleX: scale, y: scale) },
                       completion: { _ in completion?() })
    }
    
    // MARK: - Layout Helpers
    
    // 移除重複定義的方法，使用 UIView+Theme 擴展中的實作
}
