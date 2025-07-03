//
//  FormFieldView.swift
//  BusinessCardScanner
//
//  表單欄位容器元件
//  位置：Core/Common/UI/Components/Form/FormFieldView.swift
//

import UIKit
import SnapKit
import Combine

/// 表單欄位容器元件
/// 整合標籤、圖示和輸入框的統一表單欄位元件
class FormFieldView: ThemedView {
    
    // MARK: - UI Components
    
    /// 欄位標題標籤
    private let titleLabel = UILabel()
    
    /// 主要輸入框
    private let textField = ThemedTextField()
    
    /// 圖示視圖
    private let iconImageView = UIImageView()
    
    /// 必填標記
    private let requiredIndicator = UILabel()
    
    /// 輔助說明標籤
    private let helperLabel = UILabel()
    
    // MARK: - Properties
    
    /// 欄位標題
    var title: String? {
        get { titleLabel.text }
        set {
            titleLabel.text = newValue
            titleLabel.isHidden = newValue == nil
        }
    }
    
    /// 欄位值
    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    /// 占位文字
    var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }
    
    /// 圖示
    var icon: UIImage? {
        get { iconImageView.image }
        set {
            iconImageView.image = newValue
            iconImageView.isHidden = newValue == nil
            updateTextFieldPadding()
        }
    }
    
    /// 鍵盤類型
    var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }
    
    /// 自動大寫類型
    var autocapitalizationType: UITextAutocapitalizationType {
        get { textField.autocapitalizationType }
        set { textField.autocapitalizationType = newValue }
    }
    
    /// 自動更正類型
    var autocorrectionType: UITextAutocorrectionType {
        get { textField.autocorrectionType }
        set { textField.autocorrectionType = newValue }
    }
    
    /// Return 鍵類型
    var returnKeyType: UIReturnKeyType {
        get { textField.returnKeyType }
        set { textField.returnKeyType = newValue }
    }
    
    /// 是否安全輸入
    var isSecureTextEntry: Bool {
        get { textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }
    
    /// 錯誤訊息
    var errorMessage: String? {
        get { textField.errorMessage }
        set { textField.errorMessage = newValue }
    }
    
    /// 是否為必填欄位
    var isRequired: Bool = false {
        didSet {
            requiredIndicator.isHidden = !isRequired
        }
    }
    
    /// 輔助說明文字
    var helperText: String? {
        get { helperLabel.text }
        set {
            helperLabel.text = newValue
            helperLabel.isHidden = newValue == nil
        }
    }
    
    /// 是否可編輯
    var isEditable: Bool = true {
        didSet {
            textField.isUserInteractionEnabled = isEditable
            textField.alpha = isEditable ? 1.0 : 0.6
        }
    }
    
    // MARK: - Private Properties
    
    /// 圖示左側約束
    private var iconLeftConstraint: Constraint?
    
    // MARK: - Setup
    
    override func setupView() {
        super.setupView()
        
        backgroundColor = .clear
        
        // 設定標題標籤
        titleLabel.font = AppTheme.Fonts.inputLabel
        titleLabel.textColor = AppTheme.Colors.secondaryText
        titleLabel.isHidden = true
        
        // 設定必填標記
        requiredIndicator.text = "*"
        requiredIndicator.font = AppTheme.Fonts.inputLabel
        requiredIndicator.textColor = AppTheme.Colors.error
        requiredIndicator.isHidden = true
        
        // 設定圖示
        iconImageView.tintColor = AppTheme.Colors.secondaryText
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isHidden = true
        
        // 設定輔助說明
        helperLabel.font = AppTheme.Fonts.caption
        helperLabel.textColor = AppTheme.Colors.secondaryText
        helperLabel.numberOfLines = 0
        helperLabel.isHidden = true
        
        // 加入子視圖
        [titleLabel, requiredIndicator, iconImageView, textField, helperLabel].forEach {
            // 🔧 修復 Auto Layout 約束衝突：確保所有子視圖正確設置 translatesAutoresizingMaskIntoConstraints
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }
    
    override func setupConstraints() {
        // 標題標籤約束
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
        }
        
        // 必填標記約束
        requiredIndicator.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(4)
            make.centerY.equalTo(titleLabel)
        }
        
        // 圖示約束
        iconImageView.snp.makeConstraints { make in
            self.iconLeftConstraint = make.left.equalToSuperview().constraint
            make.top.equalTo(titleLabel.snp.bottom).offset(AppTheme.Layout.labelToFieldSpacing)
            make.width.height.equalTo(24)
        }
        
        // 輸入框約束
        textField.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.equalToSuperview()
            make.centerY.equalTo(iconImageView)
        }
        
        // 輔助說明約束
        helperLabel.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(AppTheme.Layout.errorMessageSpacing)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        // 初始更新
        updateTextFieldPadding()
    }
    
    // MARK: - Private Methods
    
    /// 更新輸入框左側間距
    private func updateTextFieldPadding() {
        if iconImageView.isHidden {
            // 無圖示時，輸入框靠左
            textField.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(titleLabel.isHidden ? self : titleLabel.snp.bottom).offset(
                    titleLabel.isHidden ? 0 : AppTheme.Layout.labelToFieldSpacing
                )
            }
        } else {
            // 有圖示時，輸入框在圖示右側
            textField.snp.remakeConstraints { make in
                make.left.equalTo(iconImageView.snp.right).offset(12)
                make.right.equalToSuperview()
                make.centerY.equalTo(iconImageView)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 開始編輯
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    /// 結束編輯
    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// 設定文字輸入過濾器
    /// - Parameter filter: 過濾器閉包，返回 true 允許輸入
    func setTextFilter(_ filter: @escaping (String) -> Bool) {
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        self.textFilter = filter
    }
    
    private var textFilter: ((String) -> Bool)?
    private var previousText: String = ""
    
    @objc private func textFieldChanged() {
        guard let filter = textFilter,
              let text = textField.text else { return }
        
        if !filter(text) {
            textField.text = previousText
        } else {
            previousText = text
        }
    }
    
    /// 驗證欄位內容
    /// - Returns: 驗證結果
    func validate() -> Bool {
        // 必填欄位驗證
        if isRequired {
            guard let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "此欄位為必填"
                return false
            }
        }
        
        // 清除錯誤狀態
        errorMessage = nil
        return true
    }
    
    /// 清除內容
    func clear() {
        text = nil
        errorMessage = nil
    }
}

// MARK: - Combine Extension

extension FormFieldView {
    
    /// 文字變更 Publisher
    var textPublisher: AnyPublisher<String, Never> {
        textField.textPublisher
    }
    
    /// 開始編輯 Publisher
    var beginEditingPublisher: AnyPublisher<Void, Never> {
        textField.beginEditingPublisher
    }
    
    /// 結束編輯 Publisher
    var endEditingPublisher: AnyPublisher<Void, Never> {
        textField.endEditingPublisher
    }
    
    /// Return 鍵按下 Publisher
    var returnPublisher: AnyPublisher<Void, Never> {
        textField.returnPublisher
    }
}

// MARK: - Convenience Factory Methods

extension FormFieldView {
    
    /// 建立姓名欄位
    static func makeName(required: Bool = true) -> FormFieldView {
        let field = FormFieldView()
        field.title = "姓名"
        field.placeholder = "請輸入姓名"
        field.icon = UIImage(systemName: "person.fill")
        field.isRequired = required
        field.autocapitalizationType = .words
        field.returnKeyType = .next
        return field
    }
    
    /// 建立電子郵件欄位
    static func makeEmail(required: Bool = false) -> FormFieldView {
        let field = FormFieldView()
        field.title = "電子郵件"
        field.placeholder = "example@email.com"
        field.icon = UIImage(systemName: "envelope.fill")
        field.isRequired = required
        field.keyboardType = .emailAddress
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .next
        return field
    }
    
    /// 建立電話欄位
    static func makePhone(required: Bool = false) -> FormFieldView {
        let field = FormFieldView()
        field.title = "電話"
        field.placeholder = "請輸入電話號碼"
        field.icon = UIImage(systemName: "phone.fill")
        field.isRequired = required
        field.keyboardType = .phonePad
        return field
    }
    
    /// 建立公司欄位
    static func makeCompany(required: Bool = false) -> FormFieldView {
        let field = FormFieldView()
        field.title = "公司"
        field.placeholder = "請輸入公司名稱"
        field.icon = UIImage(systemName: "building.2.fill")
        field.isRequired = required
        field.autocapitalizationType = .words
        field.returnKeyType = .next
        return field
    }
    
    /// 建立職稱欄位
    static func makeJobTitle(required: Bool = false) -> FormFieldView {
        let field = FormFieldView()
        field.title = "職稱"
        field.placeholder = "請輸入職稱"
        field.icon = UIImage(systemName: "briefcase.fill")
        field.isRequired = required
        field.returnKeyType = .next
        return field
    }
    
    /// 建立地址欄位
    static func makeAddress(required: Bool = false) -> FormFieldView {
        let field = FormFieldView()
        field.title = "地址"
        field.placeholder = "請輸入地址"
        field.icon = UIImage(systemName: "location.fill")
        field.isRequired = required
        field.returnKeyType = .next
        return field
    }
    
    /// 建立密碼欄位
    static func makePassword(required: Bool = true) -> FormFieldView {
        let field = FormFieldView()
        field.title = "密碼"
        field.placeholder = "請輸入密碼"
        field.icon = UIImage(systemName: "lock.fill")
        field.isRequired = required
        field.isSecureTextEntry = true
        field.returnKeyType = .done
        return field
    }
}
