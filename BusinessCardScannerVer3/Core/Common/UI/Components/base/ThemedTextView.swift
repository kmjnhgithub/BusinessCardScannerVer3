//
//  ThemedTextView.swift
//  BusinessCardScanner
//
//  統一樣式的多行文字輸入元件
//

import UIKit
import SnapKit
import Combine

/// 統一樣式的多行文字輸入元件
/// 支援錯誤狀態顯示、底線樣式、自動高度調整和 Combine 綁定
class ThemedTextView: UITextView {
    
    // MARK: - Properties
    
    /// 錯誤訊息
    var errorMessage: String? {
        didSet {
            updateErrorState()
        }
    }
    
    /// 是否顯示錯誤狀態
    private var showError: Bool {
        return errorMessage != nil && !errorMessage!.isEmpty
    }
    
    /// 底線視圖
    private let underlineView = UIView()
    
    /// 錯誤訊息標籤
    private let errorLabel = UILabel()
    
    /// 占位文字標籤
    private let placeholderLabel = UILabel()
    
    /// 占位文字
    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            updatePlaceholderVisibility()
        }
    }
    
    /// 最小高度
    var minimumHeight: CGFloat = 44 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    /// 最大高度（0 表示無限制）
    var maximumHeight: CGFloat = 120 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    
    /// 是否可編輯（覆寫以支援樣式更新）
    override var isEditable: Bool {
        didSet {
            updateEditableState()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        translatesAutoresizingMaskIntoConstraints = false
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
        setupTextView()
    }
    
    // MARK: - Setup
    
    private func setupTextView() {
        // 基本樣式設定
        font = AppTheme.Fonts.body
        textColor = AppTheme.Colors.primaryText
        tintColor = AppTheme.Colors.primary
        backgroundColor = .clear
        
        // 設定內間距
        textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textContainer.lineFragmentPadding = 0
        
        // 關閉滾動（讓高度自動調整）
        isScrollEnabled = false
        
        // 確保文字自動換行
        textContainer.widthTracksTextView = true
        textContainer.maximumNumberOfLines = 0
        
        // 設定底線
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(underlineView)
        underlineView.backgroundColor = AppTheme.Colors.separator
        underlineView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(AppTheme.Layout.textFieldUnderlineHeight)
        }
        
        // 設定占位文字標籤
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.font = AppTheme.Fonts.body
        placeholderLabel.textColor = AppTheme.Colors.placeholder
        placeholderLabel.numberOfLines = 0
        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
        }
        
        // 設定錯誤標籤
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = AppTheme.Fonts.errorMessage
        errorLabel.textColor = AppTheme.Colors.error
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        
        // 監聽文字變更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        
        // 設定預設高度約束
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(minimumHeight).priority(.high)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Layout
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        // 將錯誤標籤加到父視圖
        if let superview = superview, errorLabel.superview == nil {
            superview.addSubview(errorLabel)
            errorLabel.snp.makeConstraints { make in
                make.left.right.equalTo(self)
                make.top.equalTo(underlineView.snp.bottom).offset(AppTheme.Layout.errorMessageSpacing)
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        let contentHeight = sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
        
        // 考慮最小和最大高度限制
        var height = max(contentHeight, minimumHeight)
        if maximumHeight > 0 {
            height = min(height, maximumHeight)
        }
        
        
        return CGSize(width: size.width, height: height)
    }
    
    // MARK: - State Updates
    
    /// 更新錯誤狀態顯示
    private func updateErrorState() {
        let hasError = showError
        
        // 更新錯誤標籤
        errorLabel.text = errorMessage
        errorLabel.isHidden = !hasError
        
        // 更新底線顏色（帶動畫）
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            self.underlineView.backgroundColor = hasError
                ? AppTheme.Colors.error
                : (self.isFirstResponder ? AppTheme.Colors.primary : AppTheme.Colors.separator)
        }
    }
    
    /// 更新占位文字可見性
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    /// 更新可編輯狀態
    private func updateEditableState() {
        textColor = isEditable ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText
        backgroundColor = isEditable ? .clear : AppTheme.Colors.background
        isUserInteractionEnabled = isEditable
    }
    
    
    // MARK: - Text Change Handling
    
    @objc private func textDidChange() {
        // 更新占位文字
        updatePlaceholderVisibility()
        
        // 清除錯誤狀態
        if showError {
            errorMessage = nil
        }
        
        // 觸發高度重新計算
        invalidateIntrinsicContentSize()
        
        // 通知父視圖更新佈局
        superview?.setNeedsLayout()
        
    }
    
    // MARK: - Layout
    
    
    // MARK: - Focus Handling
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        
        if result {
            // 清除錯誤狀態
            if showError {
                errorMessage = nil
            }
            
            // 更新底線顏色
            UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
                self.underlineView.backgroundColor = AppTheme.Colors.primary
            }
        }
        
        return result
    }
    
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        
        if result {
            // 恢復底線顏色（如果沒有錯誤）
            guard !showError else { return result }
            
            UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
                self.underlineView.backgroundColor = AppTheme.Colors.separator
            }
        }
        
        return result
    }
    
    
    // MARK: - Public Methods
    
    /// 設定文字並更新UI
    func setText(_ text: String?) {
        self.text = text
        textDidChange()
    }
    
}

// MARK: - Combine Extension

extension ThemedTextView {
    
    /// 文字變更 Publisher
    /// 提供響應式的文字變更事件流
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification, object: self)
            .map { _ in self.text ?? "" }
            .eraseToAnyPublisher()
    }
    
    /// 開始編輯 Publisher
    var beginEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UITextView.textDidBeginEditingNotification, object: self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// 結束編輯 Publisher
    var endEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UITextView.textDidEndEditingNotification, object: self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
