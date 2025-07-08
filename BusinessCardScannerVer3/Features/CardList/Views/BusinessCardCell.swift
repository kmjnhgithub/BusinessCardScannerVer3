//
//  BusinessCardCell.swift
//  BusinessCardScannerVer3
//
//  名片列表單元格
//

import UIKit
import SnapKit

class BusinessCardCell: UITableViewCell {
    
    // MARK: - UI Elements
    
    private let cardImageView = UIImageView()
    private let nameLabel = UILabel()
    private let companyLabel = UILabel()
    private let jobTitleLabel = UILabel()
    private let containerView = UIView()
    
    // MARK: - Properties
    
    static let reuseIdentifier = "BusinessCardCell"
    
    /// PhotoService 用於載入照片
    private var photoService: PhotoServiceProtocol?
    
    // MARK: - Static Methods
    
    /// 計算當前螢幕的最佳 Cell 高度
    static func calculateOptimalCellHeight() -> CGFloat {
        return AppTheme.Layout.ResponsiveLayout.CardList.calculateCellHeight()
    }
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = AppTheme.Colors.background
        selectionStyle = .none
        
        // 容器視圖 - 使用統一的卡片樣式
        containerView.applyCardStyle()
        
        // 名片圖片
        cardImageView.contentMode = .scaleAspectFill
        cardImageView.backgroundColor = AppTheme.Colors.secondaryBackground
        cardImageView.layer.cornerRadius = 8
        cardImageView.layer.masksToBounds = true
        cardImageView.clipsToBounds = true  // 確保圖片完全填滿容器
        
        // 設定內容抗壓優先級，防止圖片被壓縮
        cardImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        cardImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // 姓名標籤 - 使用專用名片姓名字型（18pt, Semibold）
        nameLabel.font = AppTheme.Fonts.cardName
        nameLabel.textColor = AppTheme.Colors.primaryText
        nameLabel.numberOfLines = 1
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        
        // 公司標籤 - 使用專用公司名稱字型（16pt, Regular）
        companyLabel.font = AppTheme.Fonts.companyName
        companyLabel.textColor = AppTheme.Colors.secondaryText
        companyLabel.numberOfLines = 0  // 允許多行顯示
        companyLabel.lineBreakMode = .byTruncatingTail
        companyLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        companyLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        // 職稱標籤 - 使用專用職稱字型（14pt, Regular）
        jobTitleLabel.font = AppTheme.Fonts.jobTitle
        jobTitleLabel.textColor = AppTheme.Colors.secondaryText
        jobTitleLabel.numberOfLines = 1
        
        // 添加子視圖
        contentView.addSubview(containerView)
        containerView.addSubview(cardImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(companyLabel)
        containerView.addSubview(jobTitleLabel)
    }
    
    private func setupConstraints() {
        // 計算響應式尺寸
        let cellHeight = AppTheme.Layout.ResponsiveLayout.CardList.calculateCellHeight()
        let verticalMargin: CGFloat = 8  // 縮短容器邊距
        let containerHeight = cellHeight - (verticalMargin * 2)
        let containerPadding: CGFloat = 2  // 縮短容器內邊距
        
        // 🎯 解決方案說明：
        // 根據 UI設計規範文檔v1.0.md 第 5.5 節，圖片應與 Cell 內容高度完全貼合
        // 使用 top + bottom 約束取代 centerY + height，避免圖片被壓縮或裁切
        
        // 獲取螢幕和容器尺寸資訊
        let screenWidth = UIScreen.main.bounds.width
        _ = screenWidth - (AppTheme.Layout.standardPadding * 2) // containerWidth not used in current implementation
        
        // 使用設計規範的圖片尺寸計算：圖片高度 = 容器高度，寬度按黃金比例計算
        let imageHeight = containerHeight  // 與容器高度完全貼合
        let imageWidth = imageHeight * AppTheme.Layout.ResponsiveLayout.CardList.imageWidthToHeightRatio  // 黃金比例寬度
        let imageSize = CGSize(width: imageWidth, height: imageHeight)
        
        // 容器視圖約束（響應式高度）
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(verticalMargin)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.bottom.equalToSuperview().offset(-verticalMargin)
            // height 由 top + bottom 約束自然決定，避免過度約束
        }
        
        // 名片圖片約束（響應式尺寸，左貼齊，與容器高度完全貼合）
        cardImageView.snp.makeConstraints { make in
            make.left.equalToSuperview() // 左貼齊容器，無間距
            make.top.bottom.equalToSuperview() // 與容器高度完全貼合，避免裁切
            make.width.equalTo(imageSize.width) // 響應式計算的寬度
            // 移除 height 約束，讓圖片高度由 top + bottom 自然決定
        }
        
        // 姓名標籤約束（上半部 1/2 區域）
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(cardImageView.snp.right).offset(AppTheme.Layout.ResponsiveLayout.CardList.imageToTextSpacing)
            make.right.equalToSuperview().inset(containerPadding)
            make.top.equalToSuperview().offset(containerPadding)
            make.height.equalToSuperview().multipliedBy(0.5).offset(-containerPadding / 2)
        }
        
        // 公司標籤約束（下半部主要區域）
        companyLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(nameLabel)
            make.top.equalTo(containerView.snp.centerY).offset(containerPadding / 2)
            make.bottom.equalTo(jobTitleLabel.snp.top).offset(-2)
        }
        
        // 職稱標籤約束（下半部底部，固定高度）
        jobTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-containerPadding)
            make.height.equalTo(18) // 固定高度，確保顯示
        }
    }
    
    // MARK: - Configuration
    
    /// 設定 PhotoService
    func setPhotoService(_ photoService: PhotoServiceProtocol) {
        self.photoService = photoService
    }
    
    func configure(with businessCard: BusinessCard) {
        nameLabel.text = businessCard.name.isEmpty ? "未知姓名" : businessCard.name
        companyLabel.text = businessCard.company ?? "未知公司"
        jobTitleLabel.text = businessCard.jobTitle ?? "未知職稱"
        
        // 載入圖片
        loadImage(for: businessCard)
    }
    
    /// 載入名片照片
    private func loadImage(for businessCard: BusinessCard) {
        // 重置 ImageView
        cardImageView.image = nil
        cardImageView.tintColor = AppTheme.Colors.secondaryText
        
        // 檢查是否有照片路徑
        guard let photoPath = businessCard.photoPath, 
              !photoPath.isEmpty,
              let photoService = photoService else {
            // 沒有照片或沒有 PhotoService，顯示預設圖示
            setDefaultImage()
            return
        }
        
        // 使用 PhotoService 的標準縮圖載入流程（已包含舊縮圖檢測和自動重新生成）
        if let thumbnail = photoService.loadThumbnail(path: photoPath) {
            setBusinessCardImage(thumbnail)
        } else if let fullImage = photoService.loadPhoto(path: photoPath) {
            // 縮圖不存在但原圖存在，直接使用原圖
            setBusinessCardImage(fullImage)
        } else {
            // 圖片完全不存在，顯示預設圖示
            setDefaultImage()
        }
    }
    
    /// 設定預設圖示
    private func setDefaultImage() {
        cardImageView.image = UIImage(systemName: "person.crop.rectangle")
        cardImageView.tintColor = AppTheme.Colors.secondaryText
        cardImageView.contentMode = .scaleAspectFit  // 預設圖示使用 fit 模式
    }
    
    /// 設定實際名片圖片
    private func setBusinessCardImage(_ image: UIImage) {
        cardImageView.image = image
        // 🎯 現在縮圖已保持正確比例，可以使用 scaleAspectFill 完全填滿容器
        cardImageView.contentMode = .scaleAspectFill  
        cardImageView.tintColor = nil  // 清除 tint color
    }
    
    // 移除不必要的方法，讓 PhotoService 負責所有檔案操作
    
    // MARK: - Cell Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cardImageView.image = nil
        nameLabel.text = nil
        companyLabel.text = nil
        jobTitleLabel.text = nil
    }
    
    // MARK: - Touch Feedback
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = highlighted ? 
                CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            self.containerView.alpha = highlighted ? 0.8 : 1.0
        }
    }
}
