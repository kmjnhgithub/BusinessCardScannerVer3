//
//  AISettingsViewController.swift
//  
//
//  Created by 2025/6/25.
//

import UIKit
import Combine
import SnapKit

/// AI 設定頁面視圖控制器
/// 負責 OpenAI API Key 的輸入、儲存和驗證
class AISettingsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()
    
    private lazy var contentView: ThemedView = {
        let view = ThemedView()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AI 智慧解析設定"
        label.font = AppTheme.Fonts.title2
        label.textColor = AppTheme.Colors.primaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "設定 OpenAI API Key 來啟用 AI 智慧名片解析功能，提升 OCR 識別準確度。"
        label.font = AppTheme.Fonts.body
        label.textColor = AppTheme.Colors.secondaryText
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var apiKeyFormField: FormFieldView = {
        return FormFieldView.makeAPIKey(required: true)
    }()
    
    private lazy var statusView: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.Colors.cardBackground
        view.layer.cornerRadius = AppTheme.Layout.cardCornerRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = AppTheme.Colors.separator.cgColor
        return view
    }()
    
    private lazy var statusIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppTheme.Colors.secondaryText
        return imageView
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = AppTheme.Fonts.caption
        label.textColor = AppTheme.Colors.secondaryText
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var saveButton: ThemedButton = {
        let button = ThemedButton(style: .primary)
        button.setTitle("儲存設定", for: .normal)
        return button
    }()
    
    private lazy var clearButton: ThemedButton = {
        let button = ThemedButton(style: .danger)
        button.setTitle("清除 API Key", for: .normal)
        return button
    }()
    
    private lazy var helpButton: ThemedButton = {
        let button = ThemedButton(style: .text)
        button.setTitle("如何取得 API Key？", for: .normal)
        return button
    }()
    
    // MARK: - Properties
    
    private let viewModel: AISettingsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewModel: AISettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupActions()
        
        // 載入現有設定
        viewModel.loadCurrentSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [titleLabel, descriptionLabel, apiKeyFormField, statusView, 
         saveButton, clearButton, helpButton].forEach { 
            contentView.addSubview($0) 
        }
        
        [statusIconImageView, statusLabel].forEach { 
            statusView.addSubview($0) 
        }
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppTheme.Layout.standardPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppTheme.Layout.standardPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
        
        apiKeyFormField.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(AppTheme.Layout.sectionPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
        
        statusView.snp.makeConstraints { make in
            make.top.equalTo(apiKeyFormField.snp.bottom).offset(AppTheme.Layout.standardPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.height.greaterThanOrEqualTo(60)
        }
        
        statusIconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(AppTheme.Layout.standardPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.left.equalTo(statusIconImageView.snp.right).offset(AppTheme.Layout.compactPadding)
            make.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.centerY.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(statusView.snp.bottom).offset(AppTheme.Layout.sectionPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.height.equalTo(AppTheme.Layout.buttonHeight)
        }
        
        clearButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(AppTheme.Layout.standardPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.height.equalTo(AppTheme.Layout.buttonHeight)
        }
        
        helpButton.snp.makeConstraints { make in
            make.top.equalTo(clearButton.snp.bottom).offset(AppTheme.Layout.standardPadding)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.height.equalTo(AppTheme.Layout.buttonHeight)
            make.bottom.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
    }
    
    private func setupNavigationBar() {
        title = "AI 設定"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 返回按鈕
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "返回",
            style: .plain,
            target: self,
            action: #selector(dismissButtonTapped)
        )
    }
    
    private func setupBindings() {
        // API Key 輸入綁定
        apiKeyFormField.textPublisher
            .sink { [weak self] text in
                self?.viewModel.updateAPIKey(text)
            }
            .store(in: &cancellables)
        
        // API Key 狀態綁定
        viewModel.$currentAPIKey
            .receive(on: DispatchQueue.main)
            .sink { [weak self] apiKey in
                self?.apiKeyFormField.text = apiKey ?? ""
            }
            .store(in: &cancellables)
        
        // 驗證狀態綁定
        viewModel.$validationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateValidationStatus(status)
            }
            .store(in: &cancellables)
        
        // 載入狀態綁定
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
        
        // 錯誤訊息綁定
        viewModel.errorMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showErrorAlert(message)
            }
            .store(in: &cancellables)
        
        // 成功訊息綁定
        viewModel.successMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showSuccessToast(message)
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        helpButton.addTarget(self, action: #selector(helpButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - UI Updates
    
    private func updateValidationStatus(_ status: APIKeyValidationStatus) {
        switch status {
        case .notSet:
            statusIconImageView.image = UIImage(systemName: "questionmark.circle")
            statusIconImageView.tintColor = AppTheme.Colors.secondaryText
            statusLabel.text = "尚未設定 API Key"
            statusLabel.textColor = AppTheme.Colors.secondaryText
            statusView.layer.borderColor = AppTheme.Colors.separator.cgColor
            
        case .invalid:
            statusIconImageView.image = UIImage(systemName: "xmark.circle")
            statusIconImageView.tintColor = AppTheme.Colors.error
            statusLabel.text = "API Key 格式無效（應以 'sk-' 開頭）"
            statusLabel.textColor = AppTheme.Colors.error
            statusView.layer.borderColor = AppTheme.Colors.error.cgColor
            
        case .valid:
            statusIconImageView.image = UIImage(systemName: "checkmark.circle")
            statusIconImageView.tintColor = AppTheme.Colors.success
            statusLabel.text = "API Key 格式正確，AI 功能已啟用"
            statusLabel.textColor = AppTheme.Colors.success
            statusView.layer.borderColor = AppTheme.Colors.success.cgColor
            
        case .validating:
            statusIconImageView.image = UIImage(systemName: "clock")
            statusIconImageView.tintColor = AppTheme.Colors.primary
            statusLabel.text = "正在驗證 API Key..."
            statusLabel.textColor = AppTheme.Colors.primary
            statusView.layer.borderColor = AppTheme.Colors.primary.cgColor
        }
    }
    
    private func updateLoadingState(_ isLoading: Bool) {
        saveButton.isEnabled = !isLoading
        clearButton.isEnabled = !isLoading
        apiKeyFormField.isUserInteractionEnabled = !isLoading
        
        if isLoading {
            saveButton.setTitle("儲存中...", for: .normal)
        } else {
            saveButton.setTitle("儲存設定", for: .normal)
        }
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
    
    private func showSuccessToast(_ message: String) {
        ToastPresenter.shared.showSuccess(message)
    }
    
    // MARK: - Actions
    
    @objc private func saveButtonTapped() {
        viewModel.saveAPIKey()
    }
    
    @objc private func clearButtonTapped() {
        let alertController = UIAlertController(
            title: "確認清除",
            message: "確定要清除 API Key 嗎？這將停用 AI 智慧解析功能。",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        alertController.addAction(UIAlertAction(title: "清除", style: .destructive) { [weak self] _ in
            self?.viewModel.clearAPIKey()
        })
        
        present(alertController, animated: true)
    }
    
    @objc private func helpButtonTapped() {
        let alertController = UIAlertController(
            title: "如何取得 OpenAI API Key",
            message: """
            1. 前往 OpenAI 官網 (platform.openai.com)
            2. 註冊或登入您的帳戶
            3. 進入 API Keys 頁面
            4. 點擊 "Create new secret key"
            5. 複製生成的 API Key (以 sk- 開頭)
            6. 回到此頁面貼上您的 API Key
            
            注意：請妥善保管您的 API Key，避免洩露給他人。
            """,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "確定", style: .default))
        present(alertController, animated: true)
    }
    
    @objc private func dismissButtonTapped() {
        dismiss(animated: true)
    }
}