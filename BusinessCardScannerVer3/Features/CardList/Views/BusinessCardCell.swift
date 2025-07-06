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
        
        // 姓名標籤
        nameLabel.font = AppTheme.Fonts.bodyBold
        nameLabel.textColor = AppTheme.Colors.primaryText
        nameLabel.numberOfLines = 1
        
        // 公司標籤
        companyLabel.font = AppTheme.Fonts.callout
        companyLabel.textColor = AppTheme.Colors.secondaryText
        companyLabel.numberOfLines = 1
        
        // 職稱標籤
        jobTitleLabel.font = AppTheme.Fonts.footnote
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
        // 容器視圖約束
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(72) // 總高度88pt - 上下間距16pt = 72pt
        }
        
        // 名片圖片約束
        cardImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(AppTheme.Layout.standardPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(56)
        }
        
        // 姓名標籤約束
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(cardImageView.snp.right).offset(12)
            make.right.equalToSuperview().inset(AppTheme.Layout.standardPadding)
            make.top.equalToSuperview().offset(12)
        }
        
        // 公司標籤約束
        companyLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
        
        // 職稱標籤約束
        jobTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(nameLabel)
            make.top.equalTo(companyLabel.snp.bottom).offset(2)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
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
        
        // 嘗試載入縮圖
        if let thumbnail = photoService.loadThumbnail(path: photoPath) {
            cardImageView.image = thumbnail
            cardImageView.contentMode = .scaleAspectFill
        } else {
            // 縮圖載入失敗，嘗試載入原圖並產生縮圖
            if let fullImage = photoService.loadPhoto(path: photoPath) {
                // 產生縮圖並設定
                let thumbnailSize = CGSize(width: 168, height: 168) // @3x for 56pt
                if let thumbnail = photoService.generateThumbnail(from: fullImage, size: thumbnailSize) {
                    cardImageView.image = thumbnail
                    cardImageView.contentMode = .scaleAspectFill
                } else {
                    // 縮圖生成失敗，直接使用原圖
                    cardImageView.image = fullImage
                    cardImageView.contentMode = .scaleAspectFill
                }
            } else {
                // 圖片載入完全失敗，顯示預設圖示
                setDefaultImage()
            }
        }
    }
    
    /// 設定預設圖示
    private func setDefaultImage() {
        cardImageView.image = UIImage(systemName: "person.crop.rectangle")
        cardImageView.tintColor = AppTheme.Colors.secondaryText
        cardImageView.contentMode = .scaleAspectFit
    }
    
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