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
        
        // 容器視圖
        containerView.backgroundColor = AppTheme.Colors.cardBackground
        containerView.layer.cornerRadius = AppTheme.Layout.cardCornerRadius
        containerView.layer.shadowColor = AppTheme.Shadow.card.color
        containerView.layer.shadowOpacity = AppTheme.Shadow.card.opacity
        containerView.layer.shadowRadius = AppTheme.Shadow.card.radius
        containerView.layer.shadowOffset = AppTheme.Shadow.card.offset
        containerView.layer.masksToBounds = false
        
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
    
    func configure(with businessCard: BusinessCard) {
        nameLabel.text = businessCard.name ?? "未知姓名"
        companyLabel.text = businessCard.company ?? "未知公司"
        jobTitleLabel.text = businessCard.jobTitle ?? "未知職稱"
        
        // 載入圖片（暫時使用占位圖）
        if let photoPath = businessCard.photoPath, !photoPath.isEmpty {
            // TODO: 實作圖片載入邏輯
            cardImageView.image = UIImage(systemName: "person.crop.rectangle")
            cardImageView.tintColor = AppTheme.Colors.secondaryText
        } else {
            cardImageView.image = UIImage(systemName: "person.crop.rectangle")
            cardImageView.tintColor = AppTheme.Colors.secondaryText
        }
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