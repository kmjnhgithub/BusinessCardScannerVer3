//
//  SettingsViewController.swift
//  BusinessCardScannerVer3
//
//  設定頁面視圖控制器
//  位置：Features/Settings/SettingsViewController.swift
//

import UIKit
import SnapKit
import Combine

/// 設定頁面視圖控制器
/// 提供應用程式設定選項，包括 AI 功能、資料匯出等
class SettingsViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: SettingsViewModel
    weak var coordinator: SettingsCoordinatorProtocol?
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    // AI 設定區塊
    private let aiSectionView = FormSectionView()
    private let aiToggleView = UIView()
    private let aiSwitch = UISwitch()
    private let aiStatusLabel = UILabel()
    private let aiSettingsButton = ThemedButton(style: .secondary)
    
    // 資料管理區塊
    private let dataSectionView = FormSectionView()
    private let dataStatsLabel = UILabel()
    
    // 設定項目
    private var settingItemViews: [SettingItemView] = []
    
    // MARK: - Initialization
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 載入初始資料
        viewModel.loadInitialData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次顯示時重新載入，以確保狀態同步
        viewModel.loadInitialData()
    }
    
    // MARK: - Setup Methods
    
    override func setupUI() {
        title = "設定"
        view.backgroundColor = AppTheme.Colors.background
        
        // 設定導航欄
        navigationItem.largeTitleDisplayMode = .automatic
        
        // 設定滾動視圖
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        
        // 設定內容視圖
        contentView.backgroundColor = .clear
        
        // 設定主堆疊視圖
        stackView.axis = .vertical
        stackView.spacing = 24 // Section spacing
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        // 設定 AI 區塊
        setupAISection()
        
        // 設定資料管理區塊
        setupDataSection()
        
        // 設定設定項目
        setupSettingItems()
        
        // 組裝視圖層次
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        // 添加各區塊到堆疊視圖
        stackView.addArrangedSubview(aiSectionView)
        stackView.addArrangedSubview(dataSectionView)
        
        // 添加設定項目
        settingItemViews.forEach { stackView.addArrangedSubview($0) }
    }
    
    private func setupAISection() {
        // 設定區塊標題
        aiSectionView.title = "AI 智慧解析"
        
        // AI 開關區塊
        aiToggleView.backgroundColor = AppTheme.Colors.cardBackground
        aiToggleView.layer.cornerRadius = AppTheme.Layout.cardCornerRadius
        
        // AI 開關
        aiSwitch.onTintColor = AppTheme.Colors.primary
        aiSwitch.addTarget(self, action: #selector(aiSwitchChanged(_:)), for: .valueChanged)
        
        // AI 狀態標籤
        aiStatusLabel.font = AppTheme.Fonts.footnote
        aiStatusLabel.textColor = AppTheme.Colors.placeholder
        aiStatusLabel.text = "載入中..."
        
        // AI 設定按鈕
        aiSettingsButton.setTitle("AI 設定", for: .normal)
        aiSettingsButton.addTarget(self, action: #selector(aiSettingsButtonTapped), for: .touchUpInside)
        
        // 建立 AI 開關標籤
        let aiTitleLabel = UILabel()
        aiTitleLabel.text = "啟用 AI 智慧解析"
        aiTitleLabel.font = AppTheme.Fonts.body
        aiTitleLabel.textColor = AppTheme.Colors.primaryText
        
        let aiDescriptionLabel = UILabel()
        aiDescriptionLabel.text = "使用 OpenAI 提升名片解析準確度"
        aiDescriptionLabel.font = AppTheme.Fonts.caption
        aiDescriptionLabel.textColor = AppTheme.Colors.secondaryText
        aiDescriptionLabel.numberOfLines = 0
        
        // 建立垂直堆疊
        let aiLabelsStack = UIStackView()
        aiLabelsStack.axis = .vertical
        aiLabelsStack.spacing = 4
        aiLabelsStack.addArrangedSubview(aiTitleLabel)
        aiLabelsStack.addArrangedSubview(aiDescriptionLabel)
        aiLabelsStack.addArrangedSubview(aiStatusLabel)
        
        // 建立水平堆疊
        let aiHorizontalStack = UIStackView()
        aiHorizontalStack.axis = .horizontal
        aiHorizontalStack.spacing = AppTheme.Layout.standardPadding
        aiHorizontalStack.alignment = .center
        aiHorizontalStack.addArrangedSubview(aiLabelsStack)
        aiHorizontalStack.addArrangedSubview(aiSwitch)
        
        // 添加到切換視圖
        aiToggleView.addSubview(aiHorizontalStack)
        aiToggleView.addSubview(aiSettingsButton)
        
        // 設定約束
        aiHorizontalStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
        
        aiSettingsButton.snp.makeConstraints { make in
            make.top.equalTo(aiHorizontalStack.snp.bottom).offset(AppTheme.Layout.compactPadding)
            make.leading.trailing.bottom.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.height.equalTo(AppTheme.Layout.buttonHeight)
        }
        
        // 添加到區塊
        aiSectionView.addCustomView(aiToggleView)
    }
    
    private func setupDataSection() {
        // 設定區塊標題
        dataSectionView.title = "資料管理"
        
        // 資料統計標籤
        dataStatsLabel.font = AppTheme.Fonts.body
        dataStatsLabel.textColor = AppTheme.Colors.secondaryText
        dataStatsLabel.text = "載入中..."
        
        // 建立資料統計視圖
        let dataStatsView = UIView()
        dataStatsView.backgroundColor = AppTheme.Colors.cardBackground
        dataStatsView.layer.cornerRadius = AppTheme.Layout.cardCornerRadius
        
        dataStatsView.addSubview(dataStatsLabel)
        dataStatsLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
        
        dataSectionView.addCustomView(dataStatsView)
    }
    
    private func setupSettingItems() {
        settingItemViews = viewModel.settingItems.map { item in
            let itemView = SettingItemView(item: item)
            itemView.onTap = { [weak self] in
                self?.viewModel.handleSettingItemTap(item)
            }
            return itemView
        }
    }
    
    override func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
    }
    
    override func setupBindings() {
        // AI 開關狀態綁定
        viewModel.$isAIEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.aiSwitch.setOn(enabled, animated: true)
                self?.aiSettingsButton.isEnabled = enabled
                self?.aiSettingsButton.alpha = enabled ? 1.0 : 0.6
            }
            .store(in: &cancellables)
        
        // AI 狀態文字綁定
        viewModel.$aiStatusText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statusText in
                self?.aiStatusLabel.text = "狀態：\(statusText)"
            }
            .store(in: &cancellables)
        
        // 名片數量綁定
        viewModel.$totalCardsCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.dataStatsLabel.text = "已儲存 \(count) 張名片"
            }
            .store(in: &cancellables)
        
        // 載入狀態綁定
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoading("處理中...")
                } else {
                    self?.hideLoading()
                }
            }
            .store(in: &cancellables)
        
        // 導航事件綁定
        viewModel.navigationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                self?.handleNavigationAction(action)
            }
            .store(in: &cancellables)
        
        // 警告事件綁定
        viewModel.alertPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alertType in
                self?.handleAlert(alertType)
            }
            .store(in: &cancellables)
        
        // Toast 事件綁定
        viewModel.toastPublisher
            .receive(on: DispatchQueue.main)
            .sink { message in
                ToastPresenter.shared.showSuccess(message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func aiSwitchChanged(_ sender: UISwitch) {
        viewModel.toggleAI(sender.isOn)
    }
    
    @objc private func aiSettingsButtonTapped() {
        coordinator?.showAISettings()
    }
    
    // MARK: - Private Methods
    
    private func handleNavigationAction(_ action: SettingsNavigationAction) {
        switch action {
        case .aiSettings:
            coordinator?.showAISettings()
        case .shareFile(let fileURL):
            showShareSheet(for: fileURL)
        }
    }
    
    private func handleAlert(_ alertType: SettingsAlertType) {
        switch alertType {
        case .confirmClearData:
            showClearDataConfirmation()
            
        case .noDataToExport:
            AlertPresenter.shared.showMessage(
                "沒有可匯出的資料",
                title: "無資料"
            )
            
        case .selectExportFormat:
            showExportFormatSelection()
            
        case .showAbout:
            showAboutInfo()
        }
    }
    
    private func showClearDataConfirmation() {
        let actions: [AlertPresenter.AlertAction] = [
            .destructive("清除") { [weak self] in
                self?.viewModel.confirmClearAllData()
            },
            .cancel("取消", nil)
        ]
        
        AlertPresenter.shared.showActionSheet(
            title: "確認清除所有資料",
            message: "此操作無法復原，將刪除所有已儲存的名片和照片。",
            actions: actions,
            sourceView: view
        )
    }
    
    private func showExportFormatSelection() {
        let actions: [AlertPresenter.AlertAction] = [
            .default("CSV 格式") { [weak self] in
                self?.viewModel.exportAsCSV()
            },
            .default("VCF 格式") { [weak self] in
                self?.viewModel.exportAsVCF()
            },
            .cancel("取消", nil)
        ]
        
        AlertPresenter.shared.showActionSheet(
            title: "選擇匯出格式",
            message: "請選擇要匯出的檔案格式",
            actions: actions,
            sourceView: view
        )
    }
    
    private func showAboutInfo() {
        AlertPresenter.shared.showMessage(
            """
            Business Card Scanner
            \(viewModel.appVersionInfo)
            
            一個現代化的 iOS 名片掃描應用程式
            採用先進的 OCR 和 AI 技術
            
            © 2025 開發團隊
            """,
            title: "關於我們"
        )
    }
    
    private func showShareSheet(for fileURL: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // iPad 支援
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
}

// MARK: - SettingItemView

/// 設定項目視圖
private class SettingItemView: ThemedView {
    
    private let item: SettingItemType
    var onTap: (() -> Void)?
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    init(item: SettingItemType) {
        self.item = item
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupView() {
        super.setupView()
        
        backgroundColor = AppTheme.Colors.cardBackground
        layer.cornerRadius = AppTheme.Layout.cardCornerRadius
        
        // 設定點擊手勢
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        
        // 設定圖示
        iconImageView.image = UIImage(systemName: item.icon)
        iconImageView.tintColor = item.isDestructive ? AppTheme.Colors.error : AppTheme.Colors.primary
        iconImageView.contentMode = .scaleAspectFit
        
        // 設定標題
        titleLabel.text = item.title
        titleLabel.font = AppTheme.Fonts.body
        titleLabel.textColor = item.isDestructive ? AppTheme.Colors.error : AppTheme.Colors.primaryText
        
        // 設定副標題
        subtitleLabel.text = item.subtitle
        subtitleLabel.font = AppTheme.Fonts.caption
        subtitleLabel.textColor = AppTheme.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        
        // 設定箭頭
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = AppTheme.Colors.placeholder
        chevronImageView.contentMode = .scaleAspectFit
        
        // 建立標籤堆疊
        let labelsStack = UIStackView()
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.addArrangedSubview(titleLabel)
        labelsStack.addArrangedSubview(subtitleLabel)
        
        // 建立主堆疊
        let mainStack = UIStackView()
        mainStack.axis = .horizontal
        mainStack.spacing = AppTheme.Layout.standardPadding
        mainStack.alignment = .center
        mainStack.addArrangedSubview(iconImageView)
        mainStack.addArrangedSubview(labelsStack)
        mainStack.addArrangedSubview(chevronImageView)
        
        addSubview(mainStack)
        
        // 設定約束
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }
        
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppTheme.Layout.standardPadding)
        }
    }
    
    @objc private func viewTapped() {
        // 添加點擊動畫
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.alpha = 1.0
            }
        }
        
        onTap?()
    }
}

// MARK: - SettingsCoordinatorProtocol

protocol SettingsCoordinatorProtocol: AnyObject {
    func showAISettings()
}