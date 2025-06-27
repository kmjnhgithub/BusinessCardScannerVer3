//
//  FormSectionView.swift
//  BusinessCardScanner
//
//  表單區塊容器元件
//  位置：Core/Common/UI/Components/Form/FormSectionView.swift
//

import UIKit
import SnapKit

/// 表單區塊容器元件
/// 用於組織和顯示相關的表單欄位群組
class FormSectionView: ThemedView {
    
    // MARK: - UI Components
    
    /// 區塊標題標籤
    private let titleLabel = UILabel()
    
    /// 內容容器視圖
    private let contentContainer = UIView()
    
    /// 內容堆疊視圖
    private let contentStackView = UIStackView()
    
    /// 底部分隔線
    private let bottomSeparator = UIView()
    
    // MARK: - Properties
    
    /// 區塊標題
    var title: String? {
        get { titleLabel.text }
        set {
            titleLabel.text = newValue?.uppercased()
            titleLabel.isHidden = newValue == nil
            updateTitleConstraints()
        }
    }
    
    /// 是否顯示底部分隔線
    var showBottomSeparator: Bool = false {
        didSet {
            bottomSeparator.isHidden = !showBottomSeparator
        }
    }
    
    /// 內容背景樣式
    enum BackgroundStyle {
        case none
        case card
        case grouped
    }
    
    /// 背景樣式
    var backgroundStyle: BackgroundStyle = .card {
        didSet {
            updateBackgroundStyle()
        }
    }
    
    /// 內容間距
    var contentSpacing: CGFloat {
        get { contentStackView.spacing }
        set { contentStackView.spacing = newValue }
    }
    
    // MARK: - Private Properties
    
    /// 標題頂部約束
    private var titleTopConstraint: Constraint?
    
    // MARK: - Setup
    
    override func setupView() {
        super.setupView()
        
        backgroundColor = .clear
        
        // 設定標題
        titleLabel.font = AppTheme.Fonts.footnote
        titleLabel.textColor = AppTheme.Colors.secondaryText
        titleLabel.isHidden = true
        
        // 設定內容容器
        contentContainer.backgroundColor = AppTheme.Colors.cardBackground
        contentContainer.layer.cornerRadius = AppTheme.Layout.formSectionCornerRadius
        contentContainer.layer.masksToBounds = true
        
        // 設定堆疊視圖
        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        contentStackView.distribution = .fill
        contentStackView.alignment = .fill
        
        // 設定分隔線
        bottomSeparator.backgroundColor = AppTheme.Colors.separator
        bottomSeparator.isHidden = true
        
        // 組裝視圖層次
        addSubview(titleLabel)
        addSubview(contentContainer)
        contentContainer.addSubview(contentStackView)
        addSubview(bottomSeparator)
        
        // 初始樣式
        updateBackgroundStyle()
    }
    
    override func setupConstraints() {
        // 標題約束
        titleLabel.snp.makeConstraints { make in
            self.titleTopConstraint = make.top.equalToSuperview().constraint
            make.left.right.equalToSuperview()
        }
        
        // 內容容器約束 - 初始設定
        contentContainer.snp.makeConstraints { make in
            if titleLabel.isHidden {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(AppTheme.Layout.titleToContentSpacing)
            }
            make.left.right.equalToSuperview()
        }
        
        // 堆疊視圖約束
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 分隔線約束
        bottomSeparator.snp.makeConstraints { make in
            make.top.equalTo(contentContainer.snp.bottom).offset(AppTheme.Layout.sectionPadding)
            make.left.right.equalToSuperview()
            make.height.equalTo(AppTheme.Layout.separatorHeight)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    /// 添加表單欄位
    /// - Parameter field: 要添加的表單欄位
    func addField(_ field: UIView) {
        // 如果不是第一個欄位，添加分隔線
        if !contentStackView.arrangedSubviews.isEmpty {
            let separator = createInternalSeparator()
            contentStackView.addArrangedSubview(separator)
        }
        
        // 為欄位創建容器以添加內邊距
        let fieldContainer = UIView()
        fieldContainer.addSubview(field)
        field.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
        
        contentStackView.addArrangedSubview(fieldContainer)
    }
    
    /// 添加多個表單欄位
    /// - Parameter fields: 表單欄位陣列
    func addFields(_ fields: [UIView]) {
        fields.forEach { addField($0) }
    }
    
    /// 添加自定義視圖（不含內邊距）
    /// - Parameter view: 要添加的視圖
    func addCustomView(_ view: UIView) {
        if !contentStackView.arrangedSubviews.isEmpty {
            let separator = createInternalSeparator()
            contentStackView.addArrangedSubview(separator)
        }
        contentStackView.addArrangedSubview(view)
    }
    
    /// 移除所有內容
    func removeAllFields() {
        contentStackView.arrangedSubviews.forEach {
            contentStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    /// 設定區塊間距（與下一個區塊的距離）
    /// - Parameter spacing: 間距值
    func setSectionSpacing(_ spacing: CGFloat) {
        bottomSeparator.snp.updateConstraints { make in
            make.top.equalTo(contentContainer.snp.bottom).offset(spacing)
        }
    }
    
    // MARK: - Private Methods
    
    /// 更新背景樣式
    private func updateBackgroundStyle() {
        switch backgroundStyle {
        case .none:
            contentContainer.backgroundColor = .clear
            contentContainer.layer.cornerRadius = 0
            
        case .card:
            contentContainer.backgroundColor = AppTheme.Colors.cardBackground
            contentContainer.layer.cornerRadius = AppTheme.Layout.formSectionCornerRadius
            
        case .grouped:
            contentContainer.backgroundColor = AppTheme.Colors.secondaryBackground
            contentContainer.layer.cornerRadius = AppTheme.Layout.formSectionCornerRadius
        }
    }
    
    /// 更新標題約束
    private func updateTitleConstraints() {
        // 移除舊約束並重新建立，避免更新不存在的約束
        contentContainer.snp.remakeConstraints { make in
            if titleLabel.isHidden {
                // 無標題時，內容容器直接貼頂
                make.top.equalToSuperview()
            } else {
                // 有標題時，保持正常間距
                make.top.equalTo(titleLabel.snp.bottom).offset(AppTheme.Layout.titleToContentSpacing)
            }
            make.left.right.equalToSuperview()
        }
    }
    
    /// 創建內部分隔線
    private func createInternalSeparator() -> UIView {
        return SeparatorView.fullWidth()
    }
}

// MARK: - Builder Pattern Extension

extension FormSectionView {
    
    /// FormSection 建構器
    class Builder {
        private let section = FormSectionView()
        
        /// 設定標題
        @discardableResult
        func title(_ title: String?) -> Builder {
            section.title = title
            return self
        }
        
        /// 設定背景樣式
        @discardableResult
        func backgroundStyle(_ style: BackgroundStyle) -> Builder {
            section.backgroundStyle = style
            return self
        }
        
        /// 添加欄位
        @discardableResult
        func addField(_ field: UIView) -> Builder {
            section.addField(field)
            return self
        }
        
        /// 添加多個欄位
        @discardableResult
        func addFields(_ fields: [UIView]) -> Builder {
            section.addFields(fields)
            return self
        }
        
        /// 設定內容間距
        @discardableResult
        func contentSpacing(_ spacing: CGFloat) -> Builder {
            section.contentSpacing = spacing
            return self
        }
        
        /// 顯示底部分隔線
        @discardableResult
        func showBottomSeparator(_ show: Bool = true) -> Builder {
            section.showBottomSeparator = show
            return self
        }
        
        /// 建構並返回 FormSectionView
        func build() -> FormSectionView {
            return section
        }
    }
    
    /// 創建建構器
    static func builder() -> Builder {
        return Builder()
    }
}

// MARK: - Convenience Factory Methods

extension FormSectionView {
    
    /// 創建基本資訊區塊
    static func makeBasicInfoSection() -> FormSectionView {
        return FormSectionView.builder()
            .title("基本資訊")
            .backgroundStyle(.card)
            .build()
    }
    
    /// 創建聯絡資訊區塊
    static func makeContactInfoSection() -> FormSectionView {
        return FormSectionView.builder()
            .title("聯絡資訊")
            .backgroundStyle(.card)
            .build()
    }
    
    /// 創建公司資訊區塊
    static func makeCompanyInfoSection() -> FormSectionView {
        return FormSectionView.builder()
            .title("公司資訊")
            .backgroundStyle(.card)
            .build()
    }
    
    /// 創建其他資訊區塊
    static func makeAdditionalInfoSection() -> FormSectionView {
        return FormSectionView.builder()
            .title("其他資訊")
            .backgroundStyle(.card)
            .build()
    }
    
    /// 創建無標題區塊
    static func makeUntitledSection(style: BackgroundStyle = .card) -> FormSectionView {
        return FormSectionView.builder()
            .backgroundStyle(style)
            .build()
    }
}
