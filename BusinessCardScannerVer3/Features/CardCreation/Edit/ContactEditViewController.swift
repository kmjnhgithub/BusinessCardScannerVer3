//
//  ContactEditViewController.swift
//  Contact editing form with validation and photo management
//
//  Created by Claude Code on 2025/7/2.
//

import UIKit
import SnapKit
import Combine

protocol ContactEditViewControllerDelegate: AnyObject {
    func contactEditViewController(_ controller: ContactEditViewController, didSaveCard card: BusinessCard)
    func contactEditViewControllerDidCancel(_ controller: ContactEditViewController)
    
    // 新增：支援儲存成功後的選項處理
    func contactEditViewController(_ controller: ContactEditViewController, didSaveCard card: BusinessCard, shouldShowContinueOptions: Bool)
    
    // 新增：照片選擇委託方法
    func contactEditViewControllerDidRequestCameraPhoto(_ controller: ContactEditViewController)
    func contactEditViewControllerDidRequestLibraryPhoto(_ controller: ContactEditViewController)
}

class ContactEditViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: ContactEditViewModel
    weak var delegate: ContactEditViewControllerDelegate?
    
    // 追蹤來源類型以決定儲存後的流程
    var sourceType: CardCreationSourceType = .manual
    
    // MARK: - UI Components
    
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    
    // Photo section
    private lazy var photoImageView = UIImageView()
    private lazy var changePhotoButton = ThemedButton(style: .secondary)
    
    // Form fields
    private lazy var nameField = FormFieldView.makeName(required: true)
    private lazy var jobTitleField = FormFieldView.makeJobTitle()
    private lazy var companyField = FormFieldView.makeCompany()
    private lazy var emailField = FormFieldView.makeEmail()
    private lazy var phoneField = FormFieldView.makePhone()
    private lazy var mobileField = FormFieldView.makePhone()
    private lazy var addressField = FormFieldView.makeAddress()
    private lazy var websiteField = FormFieldView()
    
    // Action buttons
    private lazy var saveButton = ThemedButton(style: .primary)
    private lazy var cancelButton = ThemedButton(style: .secondary)
    
    // MARK: - Initialization
    
    init(viewModel: ContactEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // NavigationBar 現在透過 Combine 響應式更新，不需要手動設置
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 確保約束在視圖完全載入後設置
        if scrollView.constraints.isEmpty {
            print("🔧 ContactEditViewController: 延遲設置約束")
            setupConstraints()
        }
    }
    
    // MARK: - Setup
    
    private func setupView() {
        view.backgroundColor = AppTheme.Colors.background
        
        setupScrollView()
        setupPhotoSection()
        setupFormFields()
        setupActionButtons()
        setupKeyboardDismiss()
        // 約束設置移到 viewDidAppear 以避免視圖層次結構問題
    }
    
    private func setupNavigationBar() {
        // 只設置標題，按鈕會透過 updateNavigationBarForState() 動態設置
        title = viewModel.isEditing ? "編輯名片" : "新增名片"
    }
    
    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupPhotoSection() {
        // Photo image view
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = AppTheme.Layout.cornerRadius
        photoImageView.backgroundColor = AppTheme.Colors.cardBackground
        photoImageView.image = UIImage(systemName: "person.fill")
        photoImageView.tintColor = AppTheme.Colors.placeholder
        
        // Change photo button
        changePhotoButton.setTitle("更換照片", for: .normal)
        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)
        
        [photoImageView, changePhotoButton].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupFormFields() {
        // Configure mobile field
        mobileField.title = "手機"
        mobileField.placeholder = "請輸入手機號碼"
        mobileField.icon = UIImage(systemName: "phone.fill")
        mobileField.keyboardType = .phonePad
        
        // Configure website field
        websiteField.title = "網站"
        websiteField.placeholder = "https://www.example.com"
        websiteField.icon = UIImage(systemName: "globe")
        websiteField.keyboardType = .URL
        websiteField.autocapitalizationType = .none
        websiteField.autocorrectionType = .no
        
        // Configure return key types for navigation
        nameField.returnKeyType = .next
        jobTitleField.returnKeyType = .next
        companyField.returnKeyType = .next
        emailField.returnKeyType = .next
        phoneField.returnKeyType = .next
        mobileField.returnKeyType = .next
        addressField.returnKeyType = .next
        websiteField.returnKeyType = .done
        
        let formFields = [
            nameField, jobTitleField, companyField,
            emailField, phoneField, mobileField,
            addressField, websiteField
        ]
        
        formFields.forEach { contentView.addSubview($0) }
    }
    
    private func setupActionButtons() {
        saveButton.setTitle("儲存", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        [saveButton, cancelButton].forEach { contentView.addSubview($0) }
    }
    
    override func setupConstraints() {
        // Ensure all views are in hierarchy before setting constraints
        guard scrollView.superview != nil,
              contentView.superview != nil else {
            print("⚠️ ContactEditViewController: Views not in hierarchy yet, deferring constraints")
            DispatchQueue.main.async { [weak self] in
                self?.setupConstraints()
            }
            return
        }
        
        // Scroll view
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // Content view
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // Photo section - 增大照片顯示區域
        photoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppTheme.Layout.standardPadding)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)  // 增加寬度以更好顯示名片
            make.height.equalTo(130) // 名片比例約 1.54:1，調整高度
        }
        
        changePhotoButton.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(AppTheme.Layout.standardPadding)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
        }
        
        // Form fields
        let formFields = [
            nameField, jobTitleField, companyField,
            emailField, phoneField, mobileField,
            addressField, websiteField
        ]
        
        for (index, field) in formFields.enumerated() {
            field.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
                
                if index == 0 {
                    make.top.equalTo(changePhotoButton.snp.bottom).offset(AppTheme.Layout.sectionPadding)
                } else {
                    make.top.equalTo(formFields[index - 1].snp.bottom).offset(AppTheme.Layout.standardPadding)
                }
            }
        }
        
        // Action buttons
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(websiteField.snp.bottom).offset(AppTheme.Layout.sectionPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.height.equalTo(AppTheme.Layout.buttonHeight)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(AppTheme.Layout.standardPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.height.equalTo(AppTheme.Layout.buttonHeight)
            make.bottom.equalToSuperview().offset(-AppTheme.Layout.standardPadding)
        }
    }
    
    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - ViewModel Binding
    
    private func bindViewModel() {
        // Input bindings
        nameField.textPublisher
            .sink { [weak self] in self?.viewModel.updateName($0) }
            .store(in: &cancellables)
        
        jobTitleField.textPublisher
            .sink { [weak self] in self?.viewModel.updateJobTitle($0) }
            .store(in: &cancellables)
        
        companyField.textPublisher
            .sink { [weak self] in self?.viewModel.updateCompany($0) }
            .store(in: &cancellables)
        
        emailField.textPublisher
            .sink { [weak self] in self?.viewModel.updateEmail($0) }
            .store(in: &cancellables)
        
        phoneField.textPublisher
            .sink { [weak self] in self?.viewModel.updatePhone($0) }
            .store(in: &cancellables)
        
        mobileField.textPublisher
            .sink { [weak self] in self?.viewModel.updateMobile($0) }
            .store(in: &cancellables)
        
        addressField.textPublisher
            .sink { [weak self] in self?.viewModel.updateAddress($0) }
            .store(in: &cancellables)
        
        websiteField.textPublisher
            .sink { [weak self] in self?.viewModel.updateWebsite($0) }
            .store(in: &cancellables)
        
        // Return key navigation
        setupReturnKeyNavigation()
        
        // Output bindings
        viewModel.$cardData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cardData in
                self?.updateUI(with: cardData)
            }
            .store(in: &cancellables)
        
        viewModel.$photo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photo in
                self?.updatePhotoUI(with: photo)
            }
            .store(in: &cancellables)
        
        viewModel.$validationErrors
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errors in
                self?.updateValidationErrors(errors)
            }
            .store(in: &cancellables)
        
        viewModel.$isSaveEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                guard let self = self else { return }
                self.saveButton.isEnabled = isEnabled
                
                // 只有在非檢視模式時才更新 NavigationBar 按鈕的啟用狀態
                // 檢視模式的編輯按鈕不應該受 isSaveEnabled 影響
                if !self.viewModel.isViewMode {
                    self.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
                }
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
            .store(in: &cancellables)
        
        // 新增：編輯狀態綁定
        viewModel.$isCurrentlyEditing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCurrentlyEditing in
                self?.updateUIForEditingState(isCurrentlyEditing)
            }
            .store(in: &cancellables)
        
        // 初始化NavigationBar狀態
        DispatchQueue.main.async { [weak self] in
            self?.updateNavigationBarForState()
        }
    }
    
    private func setupReturnKeyNavigation() {
        // 處理單行表單欄位
        let singleLineFields = [
            nameField, jobTitleField, companyField,
            emailField, phoneField, mobileField,
            websiteField
        ]
        
        for (index, field) in singleLineFields.enumerated() {
            field.returnPublisher
                .sink { [weak self] in
                    if index == singleLineFields.count - 2 {
                        // 在手機欄位後跳到地址欄位
                        _ = self?.addressField.becomeFirstResponder()
                    } else if index < singleLineFields.count - 1 {
                        _ = singleLineFields[index + 1].becomeFirstResponder()
                    } else {
                        _ = field.resignFirstResponder()
                        self?.saveTapped()
                    }
                }
                .store(in: &cancellables)
        }
        
        // 地址欄位沒有 returnPublisher，所以手動處理焦點跳轉
        // 從手機欄位（index 5）跳到地址欄位的邏輯已在上面處理
    }
    
    // MARK: - UI Updates
    
    private func updateUI(with cardData: ParsedCardData) {
        print("🔄 ContactEditViewController: 更新UI with cardData:")
        print("   Name: \(cardData.name ?? "nil")")
        print("   Company: \(cardData.company ?? "nil")")
        print("   Email: \(cardData.email ?? "nil")")
        print("   Phone: \(cardData.phone ?? "nil")")
        
        // 直接設定欄位值，並強制 UI 更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.nameField.text = cardData.name
            self.jobTitleField.text = cardData.jobTitle
            self.companyField.text = cardData.company
            self.emailField.text = cardData.email
            self.phoneField.text = cardData.phone
            self.mobileField.text = cardData.mobile
            self.addressField.text = cardData.address
            self.websiteField.text = cardData.website
            
            // 強制重新布局以確保 UI 更新
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            print("✅ ContactEditViewController: UI 更新完成")
            print("   Name field text: \(self.nameField.text ?? "nil")")
        }
    }
    
    private func updatePhotoUI(with photo: UIImage?) {
        print("📷 ContactEditViewController: 更新照片 UI")
        
        if let photo = photo {
            print("✅ 設置照片，尺寸: \(photo.size)")
            photoImageView.image = photo
            photoImageView.contentMode = .scaleAspectFill
            photoImageView.tintColor = nil  // 清除 tint color
        } else {
            print("⚠️ 設置預設照片圖示")
            photoImageView.image = UIImage(systemName: "person.fill")
            photoImageView.contentMode = .scaleAspectFit
            photoImageView.tintColor = AppTheme.Colors.placeholder
        }
        
        // 強制重新布局確保照片顯示正確
        photoImageView.setNeedsLayout()
        photoImageView.layoutIfNeeded()
    }
    
    private func updateValidationErrors(_ errors: [String: String]) {
        // Clear all errors first
        [nameField, jobTitleField, companyField, emailField, 
         phoneField, mobileField, websiteField].forEach {
            $0.errorMessage = nil
        }
        
        // Clear address field error separately
        addressField.errorMessage = nil
        
        // Set specific errors
        nameField.errorMessage = errors["name"]
        jobTitleField.errorMessage = errors["jobTitle"]
        companyField.errorMessage = errors["company"]
        emailField.errorMessage = errors["email"]
        phoneField.errorMessage = errors["phone"]
        mobileField.errorMessage = errors["mobile"]
        addressField.errorMessage = errors["address"]
        websiteField.errorMessage = errors["website"]
    }
    
    /// 根據編輯狀態更新UI
    private func updateUIForEditingState(_ isCurrentlyEditing: Bool) {
        let isFormEnabled = viewModel.isFormEnabled
        let isViewMode = viewModel.isViewMode
        
        print("🎨 ContactEditViewController: 更新編輯狀態 UI")
        print("   isCurrentlyEditing: \(isCurrentlyEditing)")
        print("   isFormEnabled: \(isFormEnabled)")
        print("   isViewMode: \(isViewMode)")
        
        // 更新表單欄位啟用狀態
        updateFormFieldsEnabled(isFormEnabled)
        
        // 更新照片操作按鈕顯示
        updatePhotoButtonsVisibility(isFormEnabled)
        
        // 更新 NavigationBar
        updateNavigationBarForState()
    }
    
    /// 更新表單欄位的啟用狀態
    private func updateFormFieldsEnabled(_ isEnabled: Bool) {
        let singleLineFields = [nameField, jobTitleField, companyField, emailField, 
                               phoneField, mobileField, websiteField]
        
        singleLineFields.forEach { field in
            field.isEditable = isEnabled
        }
        
        // 處理多行地址欄位
        addressField.isEditable = isEnabled
    }
    
    /// 更新照片操作按鈕的顯示狀態
    private func updatePhotoButtonsVisibility(_ isEnabled: Bool) {
        // 檢視模式：隱藏照片操作按鈕
        // 編輯模式：根據來源類型決定是否顯示（手動輸入顯示完整功能，其他限制更換）
        let shouldShowPhotoButtons = isEnabled
        
        changePhotoButton.isHidden = !shouldShowPhotoButtons
        
        // 如果是編輯既有名片且不是手動輸入，可以考慮限制照片更換功能
        if viewModel.isEditing && sourceType != .manual {
            // 您提到的照片更換功能缺失，這裡可以進一步限制
            changePhotoButton.isEnabled = false
            changePhotoButton.setTitle("照片功能暫不可用", for: .normal)
        } else {
            changePhotoButton.isEnabled = shouldShowPhotoButtons
            changePhotoButton.setTitle("更換照片", for: .normal)
        }
    }
    
    /// 更新 NavigationBar 按鈕
    private func updateNavigationBarForState() {
        print("🔄 ContactEditViewController: 更新 NavigationBar")
        print("   isViewMode: \(viewModel.isViewMode)")
        print("   isEditing: \(viewModel.isEditing)")
        print("   isCurrentlyEditing: \(viewModel.isCurrentlyEditing)")
        
        if viewModel.isViewMode {
            // 檢視模式：右上角顯示「編輯」按鈕
            let editButton = UIBarButtonItem(
                title: "編輯",
                style: .plain,
                target: self,
                action: #selector(editButtonTapped)
            )
            editButton.isEnabled = true // 確保編輯按鈕始終可用
            navigationItem.rightBarButtonItem = editButton
            navigationItem.leftBarButtonItem = nil // 清除左側按鈕
            print("✅ 設置編輯按鈕，isEnabled: \(editButton.isEnabled)")
            
        } else {
            // 編輯模式：右上角顯示「完成」，左上角顯示「取消」
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: viewModel.isEditing ? "完成" : "儲存",
                style: .done,
                target: self,
                action: #selector(saveTapped)
            )
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "取消",
                style: .plain,
                target: self,
                action: #selector(cancelTapped)
            )
            print("✅ 設置儲存/取消按鈕")
        }
    }
    
    // MARK: - Public Methods
    
    /// 更新照片（供外部調用）
    func updatePhoto(_ photo: UIImage) {
        print("📷 ContactEditViewController: 外部請求更新照片，尺寸: \(photo.size)")
        viewModel.updatePhoto(photo)
    }
    
    // MARK: - Actions
    
    @objc private func saveTapped() {
        viewModel.save { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let card):
                    // 根據架構文檔，判斷是否需要顯示「繼續/完成」選項
                    let shouldShowContinueOptions = (self.sourceType == .camera || self.sourceType == .photoLibrary)
                    
                    if shouldShowContinueOptions {
                        // 拍照/相簿來源：顯示「儲存成功對話框」
                        self.showSaveSuccessDialog(for: card)
                    } else {
                        // 手動輸入：直接完成
                        self.delegate?.contactEditViewController(self, didSaveCard: card)
                    }
                    
                case .failure(let error):
                    self.showErrorAlert(error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func cancelTapped() {
        if viewModel.isViewMode {
            // 檢視模式不應該有取消按鈕，但以防萬一
            return
        }
        
        if viewModel.isEditing && viewModel.isCurrentlyEditing {
            // 編輯既有名片時的取消：恢復原始資料並回到檢視模式
            if viewModel.hasUnsavedChanges {
                showCancelEditAlert()
            } else {
                viewModel.cancelEditingAndRestore()
            }
        } else {
            // 新增名片時的取消：退出整個流程
            if viewModel.hasUnsavedChanges {
                showUnsavedChangesAlert()
            } else {
                delegate?.contactEditViewControllerDidCancel(self)
            }
        }
    }
    
    @objc private func editButtonTapped() {
        guard viewModel.isViewMode else { return }
        
        print("✏️ ContactEditViewController: 點擊編輯按鈕")
        viewModel.enterEditMode()
    }
    
    @objc private func changePhotoTapped() {
        let alertController = UIAlertController(
            title: "選擇照片",
            message: "請選擇照片來源",
            preferredStyle: .actionSheet
        )
        
        alertController.addAction(UIAlertAction(title: "相機", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.contactEditViewControllerDidRequestCameraPhoto(self)
        })
        
        alertController.addAction(UIAlertAction(title: "相簿", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.contactEditViewControllerDidRequestLibraryPhoto(self)
        })
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // iPad support
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = changePhotoButton
            popover.sourceRect = changePhotoButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    @objc private func handleTapToDismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    
    private func showUnsavedChangesAlert() {
        let alertController = UIAlertController(
            title: "未儲存的變更",
            message: "您有未儲存的變更，確定要離開嗎？",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "離開", style: .destructive) { [weak self] _ in
            self?.delegate?.contactEditViewControllerDidCancel(self!)
        })
        
        alertController.addAction(UIAlertAction(title: "繼續編輯", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func showErrorAlert(_ message: String) {
        let alertController = UIAlertController(
            title: "錯誤",
            message: message,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "確定", style: .default))
        present(alertController, animated: true)
    }
    
    /// 顯示取消編輯確認對話框
    private func showCancelEditAlert() {
        let alertController = UIAlertController(
            title: "取消編輯",
            message: "您有未儲存的變更，確定要取消編輯嗎？",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "取消編輯", style: .destructive) { [weak self] _ in
            self?.viewModel.cancelEditingAndRestore()
        })
        
        alertController.addAction(UIAlertAction(title: "繼續編輯", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    /// 顯示儲存成功對話框（符合架構文檔設計）
    private func showSaveSuccessDialog(for card: BusinessCard) {
        let alertController = UIAlertController(
            title: "儲存成功",
            message: "名片「\(card.name)」已成功保存，您可以選擇繼續操作或完成。",
            preferredStyle: .alert
        )
        
        // 繼續拍攝/選擇按鈕
        let continueTitle = sourceType == .camera ? "繼續拍攝" : "繼續選擇"
        alertController.addAction(UIAlertAction(title: continueTitle, style: .default) { [weak self] _ in
            guard let self = self else { return }
            // 調用新的 delegate 方法，表示需要顯示繼續選項
            self.delegate?.contactEditViewController(self, didSaveCard: card, shouldShowContinueOptions: true)
        })
        
        // 完成按鈕
        alertController.addAction(UIAlertAction(title: "完成", style: .default) { [weak self] _ in
            guard let self = self else { return }
            // 調用新的 delegate 方法，表示不需要繼續選項
            self.delegate?.contactEditViewController(self, didSaveCard: card, shouldShowContinueOptions: false)
        })
        
        present(alertController, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Keyboard Handling

extension ContactEditViewController {
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func handleKeyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
}