//
//  SeparatorView.swift
//  BusinessCardScanner
//
//  分隔線視圖元件
//  位置：Core/Common/UI/Components/Base/SeparatorView.swift
//

import UIKit
import SnapKit

/// 分隔線視圖元件
/// 提供統一的分隔線樣式
class SeparatorView: ThemedView {
    
    // MARK: - Types
    
    /// 分隔線方向
    enum Orientation {
        case horizontal
        case vertical
    }
    
    // MARK: - Properties
    
    /// 分隔線方向
    var orientation: Orientation = .horizontal {
        didSet {
            // 僅在有父視圖時更新約束
            if superview != nil {
                updateSeparatorConstraints()
            }
        }
    }
    
    /// 分隔線厚度
    var thickness: CGFloat = AppTheme.Layout.separatorHeight {
        didSet {
            // 僅在有父視圖時更新約束
            if superview != nil {
                updateSeparatorConstraints()
            }
        }
    }
    
    /// 分隔線顏色
    override var backgroundColor: UIColor? {
        get { super.backgroundColor }
        set { super.backgroundColor = newValue }
    }
    
    /// 左右/上下邊距
    var insets: UIEdgeInsets = .zero {
        didSet {
            // 僅在有父視圖時更新約束
            if superview != nil {
                updateSeparatorConstraints()
            }
        }
    }
    
    // MARK: - Initialization
    
    /// 初始化分隔線
    /// - Parameters:
    ///   - orientation: 分隔線方向
    ///   - thickness: 分隔線厚度
    ///   - insets: 邊距
    convenience init(orientation: Orientation = .horizontal,
                     thickness: CGFloat = AppTheme.Layout.separatorHeight,
                     insets: UIEdgeInsets = .zero) {
        self.init(frame: .zero)
        self.orientation = orientation
        self.thickness = thickness
        self.insets = insets
    }
    
    // MARK: - Setup
    
    override func setupView() {
        super.setupView()
        backgroundColor = AppTheme.Colors.separator
        
        // 設定內在內容大小
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    override func setupConstraints() {
        // 初始化時不設定約束，等待加入父視圖後再設定
    }
    
    // MARK: - View Lifecycle
    
    /// 當視圖移動到父視圖時設定約束
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        // 只有在加入父視圖後才設定約束
        if superview != nil {
            updateSeparatorConstraints()
        }
    }
    
    // MARK: - Private Methods
    
    /// 更新分隔線約束
    /// 注意：此方法只應在視圖已加入父視圖後調用
    private func updateSeparatorConstraints() {
        // 確保有父視圖
        guard superview != nil else { return }
        
        // 移除舊約束並重建
        snp.remakeConstraints { make in
            switch orientation {
            case .horizontal:
                // 水平分隔線：固定高度，寬度填滿
                make.height.equalTo(thickness)
                // 如果在 StackView 中，讓 StackView 管理寬度；否則填滿父視圖
                if !(superview is UIStackView) {
                    make.left.equalToSuperview().inset(insets.left)
                    make.right.equalToSuperview().inset(insets.right)
                }
            
            case .vertical:
                // 垂直分隔線：固定寬度，高度取決於環境
                make.width.equalTo(thickness)
                
                // 智慧判斷：
                // 如果父視圖不是 UIStackView，我們就主動撐滿它的高度。
                // 如果是 UIStackView，我們就把高度的控制權交給 StackView 的 alignment 屬性，
                // 自己不再設定高度相關約束。
                if !(superview is UIStackView) {
                    make.top.equalToSuperview().inset(insets.top)
                    make.bottom.equalToSuperview().inset(insets.bottom)
                }
            }
        }
    }
    
    // MARK: - Override
    
    /// 覆寫內在內容大小，優化 StackView 中的表現
    override var intrinsicContentSize: CGSize {
        switch orientation {
        case .horizontal:
            return CGSize(width: UIView.noIntrinsicMetric, height: thickness)
        case .vertical:
            return CGSize(width: thickness, height: UIView.noIntrinsicMetric)
        }
    }
    
    // MARK: - Convenience Factory Methods
    
    /// 建立水平分隔線
    /// - Parameters:
    ///   - thickness: 線條厚度
    ///   - insets: 左右邊距
    /// - Returns: 設定好的分隔線
    static func horizontal(thickness: CGFloat = AppTheme.Layout.separatorHeight,
                          insets: UIEdgeInsets = .zero) -> SeparatorView {
        return SeparatorView(orientation: .horizontal, thickness: thickness, insets: insets)
    }
    
    /// 建立垂直分隔線
    /// - Parameters:
    ///   - thickness: 線條厚度
    ///   - insets: 上下邊距
    /// - Returns: 設定好的分隔線
    static func vertical(thickness: CGFloat = AppTheme.Layout.separatorHeight,
                        insets: UIEdgeInsets = .zero) -> SeparatorView {
        return SeparatorView(orientation: .vertical, thickness: thickness, insets: insets)
    }
    
    /// 建立列表分隔線（模擬 iOS 標準樣式）
    /// - Parameter leftInset: 左側縮排
    /// - Returns: 設定好的分隔線
    static func listSeparator(leftInset: CGFloat = AppTheme.Layout.separatorLeftInset) -> SeparatorView {
        return horizontal(insets: UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0))
    }
    
    /// 建立全寬分隔線
    /// - Returns: 設定好的分隔線
    static func fullWidth() -> SeparatorView {
        return horizontal()
    }
}

// MARK: - UIStackView Extension

extension UIStackView {
    
    /// 在排列視圖之間插入分隔線
    /// - Parameters:
    ///   - color: 分隔線顏色
    ///   - thickness: 分隔線厚度
    ///   - insets: 邊距
    func insertSeparators(color: UIColor = AppTheme.Colors.separator,
                         thickness: CGFloat = AppTheme.Layout.separatorHeight,
                         insets: UIEdgeInsets = .zero) {
        // 移除現有分隔線
        arrangedSubviews
            .filter { $0 is SeparatorView }
            .forEach { removeArrangedSubview($0); $0.removeFromSuperview() }
        
        // 在視圖之間插入分隔線
        let views = arrangedSubviews.filter { !($0 is SeparatorView) }
        
        for (index, view) in views.enumerated() {
            if index > 0 {
                let separator = axis == .vertical
                    ? SeparatorView.horizontal(thickness: thickness, insets: insets)
                    : SeparatorView.vertical(thickness: thickness, insets: insets)
                
                separator.backgroundColor = color
                
                if let targetIndex = arrangedSubviews.firstIndex(of: view) {
                    insertArrangedSubview(separator, at: targetIndex)
                }
            }
        }
    }
    
    /// 移除所有分隔線
    func removeSeparators() {
        arrangedSubviews
            .filter { $0 is SeparatorView }
            .forEach { removeArrangedSubview($0); $0.removeFromSuperview() }
    }
}
