//
//  PlaceholderViewController.swift
//  BusinessCardScannerVer3
//
//  占位視圖控制器，用於展示未實作的模組
//

import UIKit
import SnapKit

/// 占位視圖控制器
/// 用於展示尚未實作的功能模組
final class PlaceholderViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let moduleTitle: String
    private let moduleDescription: String
    private let phase: String
    private let features: [String]
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let phaseLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let featuresCardView = CardView()
    private let featuresStackView = UIStackView()
    private let statusCardView = CardView()
    private let statusLabel = UILabel()
    
    // MARK: - Initialization
    
    /// 初始化占位視圖控制器
    /// - Parameters:
    ///   - title: 模組標題
    ///   - description: 模組描述
    ///   - phase: 開發階段
    ///   - features: 功能列表
    ///   - icon: 模組圖示
    init(
        moduleTitle: String,
        description: String,
        phase: String,
        features: [String] = [],
        icon: UIImage? = nil
    ) {
        self.moduleTitle = moduleTitle
        self.moduleDescription = description
        self.phase = phase
        self.features = features
        super.init(nibName: nil, bundle: nil)
        
        self.title = moduleTitle
        iconImageView.image = icon
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📄 PlaceholderViewController: \(moduleTitle) 視圖已載入")
    }
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        view.backgroundColor = AppTheme.Colors.background
        
        // 滾動視圖
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        scrollView.addSubview(contentView)
        
        // 圖示
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = AppTheme.Colors.primary
        
        // 標題
        titleLabel.text = moduleTitle
        titleLabel.font = AppTheme.Fonts.largeTitle
        titleLabel.textColor = AppTheme.Colors.primaryText
        titleLabel.textAlignment = .center
        
        // 階段標籤
        phaseLabel.text = "📅 開發階段：\(phase)"
        phaseLabel.font = AppTheme.Fonts.callout
        phaseLabel.textColor = AppTheme.Colors.secondaryText
        phaseLabel.textAlignment = .center
        
        // 描述
        descriptionLabel.text = moduleDescription
        descriptionLabel.font = AppTheme.Fonts.body
        descriptionLabel.textColor = AppTheme.Colors.primaryText
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // 功能列表
        setupFeaturesCard()
        
        // 狀態卡片
        setupStatusCard()
        
        // 添加子視圖
        [iconImageView, titleLabel, phaseLabel, descriptionLabel, 
         featuresCardView, statusCardView].forEach {
            contentView.addSubview($0)
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
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
        }
        
        phaseLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(phaseLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
        }
        
        featuresCardView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.left.right.equalToSuperview().inset(20)
        }
        
        statusCardView.snp.makeConstraints { make in
            make.top.equalTo(featuresCardView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-40)
        }
    }
    
    // MARK: - Private Methods
    
    /// 設定功能列表卡片
    private func setupFeaturesCard() {
        guard !features.isEmpty else { return }
        
        // 標題
        let titleLabel = UILabel()
        titleLabel.text = "🚀 規劃功能"
        titleLabel.font = AppTheme.Fonts.title3
        titleLabel.textColor = AppTheme.Colors.primaryText
        
        // 功能 StackView
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 12
        featuresStackView.alignment = .leading
        
        // 添加功能項目
        for feature in features {
            let featureView = createFeatureView(feature)
            featuresStackView.addArrangedSubview(featureView)
        }
        
        // 容器 StackView
        let containerStackView = UIStackView(arrangedSubviews: [titleLabel, featuresStackView])
        containerStackView.axis = .vertical
        containerStackView.spacing = 16
        containerStackView.alignment = .leading
        
        featuresCardView.setContent(containerStackView)
    }
    
    /// 創建功能視圖
    /// - Parameter feature: 功能描述
    /// - Returns: 功能視圖
    private func createFeatureView(_ feature: String) -> UIView {
        let containerView = UIView()
        
        let bulletLabel = UILabel()
        bulletLabel.text = "•"
        bulletLabel.font = AppTheme.Fonts.body
        bulletLabel.textColor = AppTheme.Colors.primary
        
        let featureLabel = UILabel()
        featureLabel.text = feature
        featureLabel.font = AppTheme.Fonts.body
        featureLabel.textColor = AppTheme.Colors.primaryText
        featureLabel.numberOfLines = 0
        
        containerView.addSubview(bulletLabel)
        containerView.addSubview(featureLabel)
        
        bulletLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.width.equalTo(20)
        }
        
        featureLabel.snp.makeConstraints { make in
            make.left.equalTo(bulletLabel.snp.right)
            make.top.right.bottom.equalToSuperview()
        }
        
        return containerView
    }
    
    /// 設定狀態卡片
    private func setupStatusCard() {
        statusLabel.text = "⏳ 此模組正在開發中，敬請期待"
        statusLabel.font = AppTheme.Fonts.callout
        statusLabel.textColor = AppTheme.Colors.secondaryText
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        
        statusCardView.setContent(statusLabel)
        statusCardView.backgroundColor = AppTheme.Colors.secondaryBackground
    }
}