//
//  CameraViewController.swift
//  BusinessCardScannerVer3
//
//  相機拍攝視圖控制器 - 純 UI 層，業務邏輯由 CameraViewModel 處理
//

import UIKit
import AVFoundation
import Combine
import SnapKit

/// 相機拍攝代理協議
protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
    func cameraViewControllerDidRequestGallery(_ controller: CameraViewController)
}

/// 相機拍攝視圖控制器
class CameraViewController: BaseViewController {
    
    // MARK: - Properties
    
    weak var delegate: CameraViewControllerDelegate?
    
    /// ViewModel
    private let viewModel: CameraViewModel
    
    /// 支援的螢幕方向 - 只支援直式
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    /// 視頻預覽層
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - UI Components
    
    /// 相機預覽容器
    private let previewContainer = UIView()
    
    /// 掃描引導視圖
    private let guideView = CameraGuideView()
    
    /// 控制面板容器
    private let controlsContainer = UIView()
    
    /// 拍照按鈕
    private let captureButton = UIButton(type: .custom)
    
    /// 取消按鈕
    private let cancelButton = UIButton(type: .system)
    
    /// 相簿按鈕
    private let galleryButton = UIButton(type: .system)
    
    /// 狀態指示器
    private let statusLabel = UILabel()
    
    // MARK: - Initialization
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "拍攝名片"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 隱藏導航列
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // 鎖定為直式方向
        AppDelegate.orientationLock = .portrait
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        if #available(iOS 16.0, *) {
            self.setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
        
        // 初始化相機（透過 ViewModel）
        viewModel.initializeCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 顯示導航列
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // 恢復螢幕方向設定
        AppDelegate.orientationLock = .all
        
        // 停止相機會話（透過 ViewModel）
        viewModel.stopCameraSession()
    }
    
    // MARK: - Setup Methods
    
    override func setupUI() {
        view.backgroundColor = .black
        
        // 設定預覽容器
        previewContainer.backgroundColor = .black
        view.addSubview(previewContainer)
        
        // 設定掃描引導視圖
        view.addSubview(guideView)
        
        // 設定控制面板
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(controlsContainer)
        
        // 設定拍照按鈕
        setupCaptureButton()
        
        // 設定控制按鈕
        setupControlButtons()
        
        // 設定狀態標籤
        setupStatusLabel()
    }
    
    override func setupConstraints() {
        // 預覽容器約束
        previewContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(controlsContainer.snp.top)
        }
        
        // 掃描引導視圖約束
        guideView.snp.makeConstraints { make in
            make.edges.equalTo(previewContainer)
        }
        
        // 控制面板約束 - 調整高度和底部間距
        controlsContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(0) // 往上移30pt
            make.height.equalTo(150) // 增加高度以容納調整後的按鈕
        }
        
        // 拍照按鈕約束（中央）
        captureButton.snp.makeConstraints { make in
            make.centerX.equalTo(controlsContainer)
            make.centerY.equalTo(controlsContainer).offset(-20) // 往上偏移
            make.width.height.equalTo(AppTheme.Layout.cameraShutterSize)
        }
        
        // 相簿按鈕約束（左側）
        galleryButton.snp.makeConstraints { make in
            make.leading.equalTo(controlsContainer).offset(AppTheme.Layout.largePadding)
            make.centerY.equalTo(captureButton)
            make.width.height.equalTo(44)
        }
        
        // 取消按鈕約束（右側）
        cancelButton.snp.makeConstraints { make in
            make.trailing.equalTo(controlsContainer).offset(-AppTheme.Layout.largePadding)
            make.centerY.equalTo(captureButton)
            make.width.height.equalTo(44)
        }
        
        // 狀態標籤約束
        statusLabel.snp.makeConstraints { make in
            make.center.equalTo(previewContainer)
            make.leading.trailing.equalTo(previewContainer).inset(20)
        }
    }
    
    override func setupBindings() {
        // 設定按鈕動作
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(galleryButtonTapped), for: .touchUpInside)
        
        // 綁定 ViewModel 狀態
        setupViewModelBindings()
    }
    
    // MARK: - ViewModel Bindings
    
    private func setupViewModelBindings() {
        // 綁定相機狀態
        viewModel.$cameraStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateCameraStatus(status)
            }
            .store(in: &cancellables)
        
        // 綁定狀態訊息
        viewModel.$statusMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.updateStatusMessage(message)
            }
            .store(in: &cancellables)
        
        // 綁定控制按鈕狀態
        viewModel.$controlsEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.updateControlsEnabled(enabled)
            }
            .store(in: &cancellables)
        
        // 綁定拍攝的照片
        viewModel.$capturedImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                if let image = image {
                    self?.handleCapturedImage(image)
                }
            }
            .store(in: &cancellables)
        
        // 當相機狀態變為 ready 時設定預覽層
        viewModel.$cameraStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if case .ready = status {
                    self?.setupPreviewLayerIfNeeded()
                    self?.viewModel.startCameraSession()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Status Update Methods
    
    private func updateCameraStatus(_ status: CameraStatus) {
        switch status {
        case .initializing:
            statusLabel.isHidden = false
            guideView.isHidden = true
            
        case .permissionDenied:
            statusLabel.isHidden = false
            guideView.isHidden = true
            
        case .configuring:
            statusLabel.isHidden = false
            guideView.isHidden = true
            
        case .ready:
            statusLabel.isHidden = true
            guideView.isHidden = false
            guideView.resetToDefault()
            
        case .error:
            statusLabel.isHidden = false
            guideView.isHidden = true
            
        case .capturing:
            // 拍照動畫將在按鈕動作中處理
            break
            
        case .captured:
            guideView.showSuccessState()
        }
    }
    
    private func updateStatusMessage(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = message.isEmpty
    }
    
    private func updateControlsEnabled(_ enabled: Bool) {
        captureButton.isEnabled = enabled
        galleryButton.isEnabled = enabled
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        // 延遲後通知代理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.delegate?.cameraViewController(self, didCaptureImage: image)
        }
    }
    
    // MARK: - UI Setup Helpers
    
    private func setupCaptureButton() {
        // 根據UI設計規範：白色圓形按鈕，70pt直徑，2pt白色邊框
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = AppTheme.Layout.cameraShutterSize / 2
        captureButton.layer.borderWidth = 2
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.setTitle("", for: .normal)
        
        // 按下效果
        captureButton.addTarget(self, action: #selector(captureButtonTouchDown), for: .touchDown)
        captureButton.addTarget(self, action: #selector(captureButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        controlsContainer.addSubview(captureButton)
    }
    
    private func setupControlButtons() {
        // 相簿按鈕（左側）
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.backgroundColor = .clear
        galleryButton.layer.cornerRadius = 22
        controlsContainer.addSubview(galleryButton)
        
        // 取消按鈕（右側）
        cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.backgroundColor = .clear
        cancelButton.layer.cornerRadius = 22
        controlsContainer.addSubview(cancelButton)
    }
    
    private func setupStatusLabel() {
        statusLabel.text = "正在啟動相機..."
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = false
        previewContainer.addSubview(statusLabel)
    }
    
    // MARK: - Preview Layer Setup
    
    private func setupPreviewLayerIfNeeded() {
        guard videoPreviewLayer == nil,
              let session = viewModel.getCaptureSession() else { return }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewContainer.bounds
        
        previewContainer.layer.addSublayer(previewLayer)
        videoPreviewLayer = previewLayer
        
        print("✅ CameraViewController: 預覽層設定完成")
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 更新預覽層框架
        videoPreviewLayer?.frame = previewContainer.bounds
    }
    
    // MARK: - Button Actions
    
    @objc private func captureButtonTapped() {
        // 顯示拍照動畫
        showCaptureAnimation()
        
        // 透過 ViewModel 拍攝照片
        viewModel.capturePhoto()
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.cameraViewControllerDidCancel(self)
    }
    
    @objc private func galleryButtonTapped() {
        // 切換到相簿選擇
        print("📁 切換到相簿選擇")
        
        // 停止相機會話（透過 ViewModel）
        viewModel.stopCameraSession()
        
        // 通知 delegate 請求切換到相簿選擇
        delegate?.cameraViewControllerDidRequestGallery(self)
    }
    
    @objc private func captureButtonTouchDown() {
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            self.captureButton.transform = CGAffineTransform(scaleX: AppTheme.Animation.buttonPressScale, y: AppTheme.Animation.buttonPressScale)
        }
    }
    
    @objc private func captureButtonTouchUp() {
        UIView.animate(withDuration: AppTheme.Animation.fastDuration) {
            self.captureButton.transform = .identity
        }
    }
    
    // MARK: - Animation
    
    private func showCaptureAnimation() {
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = .white
        flashView.alpha = 0
        view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.1, animations: {
            flashView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                flashView.alpha = 0
            }) { _ in
                flashView.removeFromSuperview()
            }
        }
    }
    
}
