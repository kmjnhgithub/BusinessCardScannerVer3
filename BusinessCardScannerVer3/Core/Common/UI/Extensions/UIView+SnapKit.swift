//
//  UIView+SnapKit.swift
//  BusinessCardScanner
//
//  SnapKit 輔助方法擴展
//

import UIKit
import SnapKit

// MARK: - SnapKit Convenience Methods

extension UIView {
    
    // MARK: - Basic Constraints
    
    /// 填滿父視圖
    /// 等同於 make.edges.equalToSuperview()
    func snp_fillSuperview() {
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    /// 填滿父視圖（含邊距）
    /// - Parameter padding: 統一邊距值
    func snp_fillSuperview(padding: CGFloat) {
        snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(padding)
        }
    }
    
    /// 填滿父視圖（自定義邊距）
    /// - Parameter insets: 自定義邊距
    func snp_fillSuperview(insets: UIEdgeInsets) {
        snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(insets)
        }
    }
    
    /// 填滿安全區域
    func snp_fillSafeArea() {
        guard let superview = superview else { return }
        snp.makeConstraints { make in
            make.edges.equalTo(superview.safeAreaLayoutGuide)
        }
    }
    
    /// 填滿安全區域（含邊距）
    /// - Parameter padding: 統一邊距值
    func snp_fillSafeArea(padding: CGFloat) {
        guard let superview = superview else { return }
        snp.makeConstraints { make in
            make.edges.equalTo(superview.safeAreaLayoutGuide).inset(padding)
        }
    }
    
    // MARK: - Center Constraints
    
    /// 置中於父視圖
    func snp_centerInSuperview() {
        snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    /// 水平置中於父視圖
    func snp_centerXInSuperview() {
        snp.makeConstraints { make in
            make.centerX.equalToSuperview()
        }
    }
    
    /// 垂直置中於父視圖
    func snp_centerYInSuperview() {
        snp.makeConstraints { make in
            make.centerY.equalToSuperview()
        }
    }
    
    /// 置中於指定視圖
    /// - Parameter view: 目標視圖
    func snp_center(in view: UIView) {
        snp.makeConstraints { make in
            make.center.equalTo(view)
        }
    }
    
    // MARK: - Size Constraints
    
    /// 設定固定大小
    /// - Parameter size: 寬高尺寸
    func snp_size(_ size: CGSize) {
        snp.makeConstraints { make in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        }
    }
    
    /// 設定正方形大小
    /// - Parameter side: 邊長
    func snp_square(_ side: CGFloat) {
        snp.makeConstraints { make in
            make.width.height.equalTo(side)
        }
    }
    
    /// 設定寬高比
    /// - Parameter ratio: 寬高比（寬度/高度）
    func snp_aspectRatio(_ ratio: CGFloat) {
        snp.makeConstraints { make in
            make.width.equalTo(snp.height).multipliedBy(ratio)
        }
    }
    
    // MARK: - Edge Constraints
    
    /// 對齊頂部
    /// - Parameters:
    ///   - view: 參考視圖（nil 表示父視圖）
    ///   - offset: 偏移量
    func snp_alignTop(to view: UIView? = nil, offset: CGFloat = 0) {
        snp.makeConstraints { make in
            if let view = view {
                make.top.equalTo(view).offset(offset)
            } else {
                make.top.equalToSuperview().offset(offset)
            }
        }
    }
    
    /// 對齊底部
    /// - Parameters:
    ///   - view: 參考視圖（nil 表示父視圖）
    ///   - offset: 偏移量
    func snp_alignBottom(to view: UIView? = nil, offset: CGFloat = 0) {
        snp.makeConstraints { make in
            if let view = view {
                make.bottom.equalTo(view).offset(offset)
            } else {
                make.bottom.equalToSuperview().offset(offset)
            }
        }
    }
    
    /// 對齊左側
    /// - Parameters:
    ///   - view: 參考視圖（nil 表示父視圖）
    ///   - offset: 偏移量
    func snp_alignLeft(to view: UIView? = nil, offset: CGFloat = 0) {
        snp.makeConstraints { make in
            if let view = view {
                make.left.equalTo(view).offset(offset)
            } else {
                make.left.equalToSuperview().offset(offset)
            }
        }
    }
    
    /// 對齊右側
    /// - Parameters:
    ///   - view: 參考視圖（nil 表示父視圖）
    ///   - offset: 偏移量
    func snp_alignRight(to view: UIView? = nil, offset: CGFloat = 0) {
        snp.makeConstraints { make in
            if let view = view {
                make.right.equalTo(view).offset(offset)
            } else {
                make.right.equalToSuperview().offset(offset)
            }
        }
    }
    
    // MARK: - Relative Positioning
    
    /// 放置在視圖下方
    /// - Parameters:
    ///   - view: 參考視圖
    ///   - spacing: 間距
    func snp_below(_ view: UIView, spacing: CGFloat = 0) {
        snp.makeConstraints { make in
            make.top.equalTo(view.snp.bottom).offset(spacing)
        }
    }
    
    /// 放置在視圖上方
    /// - Parameters:
    ///   - view: 參考視圖
    ///   - spacing: 間距
    func snp_above(_ view: UIView, spacing: CGFloat = 0) {
        snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.top).offset(-spacing)
        }
    }
    
    /// 放置在視圖右側
    /// - Parameters:
    ///   - view: 參考視圖
    ///   - spacing: 間距
    func snp_trailing(_ view: UIView, spacing: CGFloat = 0) {
        snp.makeConstraints { make in
            make.left.equalTo(view.snp.right).offset(spacing)
        }
    }
    
    /// 放置在視圖左側
    /// - Parameters:
    ///   - view: 參考視圖
    ///   - spacing: 間距
    func snp_leading(_ view: UIView, spacing: CGFloat = 0) {
        snp.makeConstraints { make in
            make.right.equalTo(view.snp.left).offset(-spacing)
        }
    }
    
    // MARK: - Update Constraints
    
    /// 更新寬度約束
    /// - Parameter width: 新寬度
    func snp_updateWidth(_ width: CGFloat) {
        snp.updateConstraints { make in
            make.width.equalTo(width)
        }
    }
    
    /// 更新高度約束
    /// - Parameter height: 新高度
    func snp_updateHeight(_ height: CGFloat) {
        snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }
    
    /// 更新大小約束
    /// - Parameter size: 新尺寸
    func snp_updateSize(_ size: CGSize) {
        snp.updateConstraints { make in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        }
    }
    
    // MARK: - Priority Helpers
    
    /// 設定擁抱優先級
    /// - Parameters:
    ///   - priority: 優先級值
    ///   - axis: 軸向
    func snp_setHuggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
        setContentHuggingPriority(priority, for: axis)
    }
    
    /// 設定壓縮阻力優先級
    /// - Parameters:
    ///   - priority: 優先級值
    ///   - axis: 軸向
    func snp_setCompressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
        setContentCompressionResistancePriority(priority, for: axis)
    }
    
    // MARK: - Batch Operations
    
    /// 批次添加子視圖
    /// - Parameter views: 視圖陣列
    func addSubviews(_ views: [UIView]) {
        views.forEach { addSubview($0) }
    }
    
    /// 批次添加子視圖（可變參數）
    /// - Parameter views: 視圖列表
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
    
    /// 移除所有子視圖
    func removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// 添加除錯邊框
    /// - Parameter color: 邊框顏色
    func addDebugBorder(_ color: UIColor = .red) {
        layer.borderWidth = 1
        layer.borderColor = color.cgColor
    }
    
    /// 移除除錯邊框
    func removeDebugBorder() {
        layer.borderWidth = 0
        layer.borderColor = nil
    }
    
    /// 印出視圖層級
    /// - Parameter indent: 縮排層級
    func printViewHierarchy(indent: String = "") {
        print("\(indent)\(type(of: self)): \(frame)")
        subviews.forEach { $0.printViewHierarchy(indent: indent + "  ") }
    }
    #endif
}

// MARK: - Stack View Convenience

extension UIStackView {
    
    /// 批次添加排列視圖
    /// - Parameter views: 視圖陣列
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }
    
    /// 批次添加排列視圖（可變參數）
    /// - Parameter views: 視圖列表
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach { addArrangedSubview($0) }
    }
    
    /// 移除所有排列視圖
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    /// 插入分隔視圖
    /// - Parameters:
    ///   - height: 分隔視圖高度（垂直堆疊）或寬度（水平堆疊）
    ///   - color: 分隔視圖顏色
    func insertSeparator(size: CGFloat = AppTheme.Layout.separatorHeight,
                        color: UIColor = AppTheme.Colors.separator) {
        let separator = UIView()
        separator.backgroundColor = color
        
        addArrangedSubview(separator)
        
        separator.snp.makeConstraints { make in
            if axis == .vertical {
                make.height.equalTo(size)
            } else {
                make.width.equalTo(size)
            }
        }
    }
}

// MARK: - Safe Area Helpers

extension UIView {
    
    /// 獲取安全區域邊距
    var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
    
    /// 獲取安全區域佈局指南
    var safeArea: UILayoutGuide {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide
        } else {
            return layoutMarginsGuide
        }
    }
}
