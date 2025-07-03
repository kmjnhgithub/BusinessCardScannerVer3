//
//  ThemedTextField.swift
//  BusinessCardScanner
//
//  統一樣式的輸入框元件
//  位置：Core/Common/UI/Components/Base/ThemedTextField.swift
//

import UIKit
import SnapKit
import Combine

/// 統一樣式的輸入框元件
/// 支援錯誤狀態顯示、底線樣式和 Combine 綁定
class ThemedTextField: UITextField {
    
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
    
    /// 占位文字顏色
    override var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 🔧 修復 Auto Layout 約束衝突：確保使用 SnapKit 約束而非 AutoresizingMask
        translatesAutoresizingMaskIntoConstraints = false
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // 🔧 修復 Auto Layout 約束衝突：確保使用 SnapKit 約束而非 AutoresizingMask
        translatesAutoresizingMaskIntoConstraints = false
        setupTextField()
    }
    
    // MARK: - Setup
    
    private func setupTextField() {
        // 基本樣式設定
        font = AppTheme.Fonts.body
        textColor = AppTheme.Colors.primaryText
        tintColor = AppTheme.Colors.primary
        
        // 清除預設邊框樣式
        borderStyle = .none
        
        // 設定底線
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(underlineView)
        underlineView.backgroundColor = AppTheme.Colors.separator
        underlineView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(AppTheme.Layout.textFieldUnderlineHeight)
        }
        
        // 設定錯誤標籤
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = AppTheme.Fonts.errorMessage
        errorLabel.textColor = AppTheme.Colors.error
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        
        // 將錯誤標籤加到父視圖（在 layoutSubviews 中處理）
        
        // 設定高度
        snp.makeConstraints { make in
            make.height.equalTo(AppTheme.Layout.textFieldHeight)
        }
        
        // 監聽焦點變化
        addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        
        // 設定內間距
        setLeftPadding(8)
        setRightPadding(8)
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
        
        // 震動效果（僅在新增錯誤時）
//        if hasError && oldValue == nil {
//            shake()
//        }
    }
    
    /// 更新占位文字樣式
    private func updatePlaceholder() {
        guard let placeholder = placeholder else { return }
        
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: AppTheme.Colors.placeholder,
                .font: AppTheme.Fonts.body
            ]
        )
    }
    
    // MARK: - Focus Handling
    
    @objc private func editingDidBegin() {
        // 清除錯誤狀態
        if showError {
            errorMessage = nil
        }
        
        // 更新底線顏色
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            self.underlineView.backgroundColor = AppTheme.Colors.primary
        }
    }
    
    @objc private func editingDidEnd() {
        // 恢復底線顏色（如果沒有錯誤）
        guard !showError else { return }
        
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            self.underlineView.backgroundColor = AppTheme.Colors.separator
        }
    }
    
    @objc private func textDidChange() {
        // 文字變更時清除錯誤
        if showError {
            errorMessage = nil
        }
    }
    
    // MARK: - Animation
    
    /// 震動動畫（錯誤提示）
    private func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        layer.add(animation, forKey: "shake")
    }
    
    // MARK: - Padding
    
    /// 設定左側內間距
    private func setLeftPadding(_ padding: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: frame.height))
        leftView = paddingView
        leftViewMode = .always
    }
    
    /// 設定右側內間距
    private func setRightPadding(_ padding: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: frame.height))
        rightView = paddingView
        rightViewMode = .always
    }
    
    // MARK: - Public Methods
    
    /// 設定輸入框圖示
    /// - Parameters:
    ///   - image: 圖示圖片
    ///   - position: 圖示位置（.left 或 .right）
    func setIcon(_ image: UIImage?, position: IconPosition = .left) {
        guard let image = image else {
            if position == .left {
                leftView = nil
                leftViewMode = .never
            } else {
                rightView = nil
                rightViewMode = .never
            }
            return
        }
        
        let iconView = UIImageView(image: image)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = AppTheme.Colors.secondaryText
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        containerView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        if position == .left {
            leftView = containerView
            leftViewMode = .always
        } else {
            rightView = containerView
            rightViewMode = .always
        }
    }
    
    /// 圖示位置
    enum IconPosition {
        case left
        case right
    }
}

// MARK: - Combine Extension

extension ThemedTextField {
    
    /// 文字變更 Publisher
    /// 提供響應式的文字變更事件流
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: self)
            .map { _ in self.text ?? "" }
            .eraseToAnyPublisher()
    }
    
    /// 開始編輯 Publisher
    var beginEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidBeginEditingNotification, object: self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// 結束編輯 Publisher
    var endEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidEndEditingNotification, object: self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// Return 鍵按下 Publisher
    var returnPublisher: AnyPublisher<Void, Never> {
        controlPublisher(for: .editingDidEndOnExit)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
