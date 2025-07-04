//
//  CameraGuideView.swift
//  BusinessCardScannerVer3
//
//  名片掃描引導視圖 - 顯示黃色掃描框和引導提示
//

import UIKit
import SnapKit

/// 名片掃描引導視圖
/// 顯示黃色掃描框、四角標記和引導提示文字
class CameraGuideView: UIView {
    
    // MARK: - UI Components
    
    /// 掃描框視圖
    private let scanFrameView = UIView()
    
    /// 四個角落標記
    private let topLeftCorner = UIView()
    private let topRightCorner = UIView()
    private let bottomLeftCorner = UIView()
    private let bottomRightCorner = UIView()
    
    /// 引導提示標籤
    private let guideLabel = UILabel()
    
    /// 遮罩層（掃描框外的半透明區域）
    private let overlayView = UIView()
    
    // MARK: - Properties
    
    /// 掃描框尺寸（根據UI設計規範）
    private let frameSize = CGSize(width: 300, height: 200)
    
    /// 角標記尺寸
    private let cornerSize: CGFloat = 20
    
    /// 角標記線寬
    private let cornerLineWidth: CGFloat = 3
    
    /// 動畫是否正在執行
    private var isAnimating = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        startCornerAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        startCornerAnimation()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 設定遮罩層
        setupOverlay()
        
        // 設定掃描框
        setupScanFrame()
        
        // 設定四角標記
        setupCorners()
        
        // 設定引導標籤
        setupGuideLabel()
        
        // 添加子視圖
        addSubview(overlayView)
        addSubview(scanFrameView)
        addSubview(topLeftCorner)
        addSubview(topRightCorner)
        addSubview(bottomLeftCorner)
        addSubview(bottomRightCorner)
        addSubview(guideLabel)
    }
    
    private func setupOverlay() {
        overlayView.backgroundColor = AppTheme.Colors.scannerOverlay
        overlayView.isUserInteractionEnabled = false
    }
    
    private func setupScanFrame() {
        scanFrameView.backgroundColor = .clear
        scanFrameView.addBorder(width: 3, color: AppTheme.Colors.scannerFrame, cornerRadius: AppTheme.Layout.cornerRadius)
        scanFrameView.isUserInteractionEnabled = false
    }
    
    private func setupCorners() {
        let corners = [topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner]
        
        corners.forEach { corner in
            corner.backgroundColor = .clear
            corner.addBorder(width: cornerLineWidth, color: AppTheme.Colors.scannerFrame, cornerRadius: 4)
        }
    }
    
    private func setupGuideLabel() {
        guideLabel.text = "將名片放入框內"
        guideLabel.textColor = .white
        guideLabel.font = AppTheme.Fonts.callout
        guideLabel.textAlignment = .center
        guideLabel.numberOfLines = 1
        
        // 添加陰影效果 - 使用 UIView+Theme 擴展
        guideLabel.applyShadow()
    }
    
    private func setupConstraints() {
        // 遮罩層約束
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 掃描框約束
        scanFrameView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(frameSize.width)
            make.height.equalTo(frameSize.height)
        }
        
        // 四角標記約束
        topLeftCorner.snp.makeConstraints { make in
            make.top.leading.equalTo(scanFrameView).inset(-cornerLineWidth)
            make.width.height.equalTo(cornerSize)
        }
        
        topRightCorner.snp.makeConstraints { make in
            make.top.trailing.equalTo(scanFrameView).inset(-cornerLineWidth)
            make.width.height.equalTo(cornerSize)
        }
        
        bottomLeftCorner.snp.makeConstraints { make in
            make.bottom.leading.equalTo(scanFrameView).inset(-cornerLineWidth)
            make.width.height.equalTo(cornerSize)
        }
        
        bottomRightCorner.snp.makeConstraints { make in
            make.bottom.trailing.equalTo(scanFrameView).inset(-cornerLineWidth)
            make.width.height.equalTo(cornerSize)
        }
        
        // 引導標籤約束
        guideLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(scanFrameView.snp.top).offset(-20)
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 創建掃描框遮罩路徑
        createOverlayMask()
    }
    
    /// 創建遮罩層，讓掃描框區域透明
    private func createOverlayMask() {
        let maskPath = UIBezierPath(rect: bounds)
        
        // 計算掃描框在當前視圖中的實際frame
        let scanFrameRect = CGRect(
            x: bounds.width / 2 - frameSize.width / 2,
            y: bounds.height / 2 - frameSize.height / 2,
            width: frameSize.width,
            height: frameSize.height
        )
        
        let scanFramePath = UIBezierPath(roundedRect: scanFrameRect, cornerRadius: AppTheme.Layout.cornerRadius)
        maskPath.append(scanFramePath.reversing())
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        overlayView.layer.mask = maskLayer
    }
    
    // MARK: - Animation
    
    /// 開始四角標記動畫
    private func startCornerAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        let corners = [topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner]
        
        // 呼吸動畫效果
        UIView.animateKeyframes(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                corners.forEach { corner in
                    corner.alpha = 0.3
                    corner.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                corners.forEach { corner in
                    corner.alpha = 1.0
                    corner.transform = .identity
                }
            }
        }, completion: nil)
    }
    
    /// 停止動畫
    func stopAnimation() {
        isAnimating = false
        layer.removeAllAnimations()
        
        let corners = [topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner]
        corners.forEach { corner in
            corner.layer.removeAllAnimations()
            corner.alpha = 1.0
            corner.transform = .identity
        }
    }
    
    // MARK: - Public Methods
    
    /// 更新引導文字
    /// - Parameter text: 新的引導文字
    func updateGuideText(_ text: String) {
        guideLabel.text = text
    }
    
    /// 顯示成功狀態
    func showSuccessState() {
        UIView.animate(withDuration: 0.3) {
            self.scanFrameView.layer.borderColor = AppTheme.Colors.success.cgColor
            self.topLeftCorner.layer.borderColor = AppTheme.Colors.success.cgColor
            self.topRightCorner.layer.borderColor = AppTheme.Colors.success.cgColor
            self.bottomLeftCorner.layer.borderColor = AppTheme.Colors.success.cgColor
            self.bottomRightCorner.layer.borderColor = AppTheme.Colors.success.cgColor
        }
        
        updateGuideText("名片識別成功！")
    }
    
    /// 重置為預設狀態
    func resetToDefault() {
        UIView.animate(withDuration: 0.3) {
            self.scanFrameView.layer.borderColor = AppTheme.Colors.scannerFrame.cgColor
            self.topLeftCorner.layer.borderColor = AppTheme.Colors.scannerFrame.cgColor
            self.topRightCorner.layer.borderColor = AppTheme.Colors.scannerFrame.cgColor
            self.bottomLeftCorner.layer.borderColor = AppTheme.Colors.scannerFrame.cgColor
            self.bottomRightCorner.layer.borderColor = AppTheme.Colors.scannerFrame.cgColor
        }
        
        updateGuideText("將名片放入框內")
    }
}