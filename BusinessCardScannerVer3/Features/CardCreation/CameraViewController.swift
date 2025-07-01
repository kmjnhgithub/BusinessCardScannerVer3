//
//  CameraViewController.swift
//  BusinessCardScannerVer3
//
//  相機拍攝視圖控制器
//

import UIKit
import AVFoundation
import Combine
import SnapKit

/// 相機拍攝代理協議
protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}

/// 相機拍攝視圖控制器
class CameraViewController: BaseViewController {
    
    // MARK: - Properties
    
    weak var delegate: CameraViewControllerDelegate?
    
    /// 支援的螢幕方向 - 只支援直式
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    /// 相機會話管理
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    /// 當前設備
    private var currentDevice: AVCaptureDevice?
    
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
        
        // 檢查權限並設定相機
        checkPermissionAndSetupCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 顯示導航列
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // 恢復螢幕方向設定
        AppDelegate.orientationLock = .all
        
        // 停止相機會話
        stopCameraSession()
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
    
    // MARK: - Camera Setup
    
    private func checkPermissionAndSetupCamera() {
        let permissionManager = ServiceContainer.shared.permissionManager
        
        // 檢查權限狀態
        switch permissionManager.cameraPermissionStatus() {
        case .authorized:
            setupCamera()
        case .denied, .restricted:
            showPermissionDeniedStatus()
        case .notDetermined:
            // 請求權限
            permissionManager.requestCameraPermission { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self?.setupCamera()
                    default:
                        self?.showPermissionDeniedStatus()
                    }
                }
            }
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.configureCameraSession()
        }
    }
    
    private func configureCameraSession() {
        guard captureSession == nil else { return }
        
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        // 設定相機輸入
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            DispatchQueue.main.async { [weak self] in
                self?.showCameraError("無法存取相機設備")
            }
            return
        }
        
        currentDevice = device
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showCameraError("無法配置相機輸入")
            }
            return
        }
        
        // 設定照片輸出
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            photoOutput = output
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showCameraError("無法配置照片輸出")
            }
            return
        }
        
        captureSession = session
        
        DispatchQueue.main.async { [weak self] in
            self?.setupPreviewLayer()
            self?.startCameraSession()
        }
    }
    
    private func setupPreviewLayer() {
        guard let session = captureSession else { return }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewContainer.bounds
        
        previewContainer.layer.addSublayer(previewLayer)
        videoPreviewLayer = previewLayer
        
        // 隱藏狀態標籤，顯示掃描引導
        statusLabel.isHidden = true
        guideView.isHidden = false
    }
    
    private func startCameraSession() {
        guard let session = captureSession, !session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    private func stopCameraSession() {
        guard let session = captureSession, session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 更新預覽層框架
        videoPreviewLayer?.frame = previewContainer.bounds
    }
    
    // MARK: - Button Actions
    
    @objc private func captureButtonTapped() {
        capturePhoto()
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.cameraViewControllerDidCancel(self)
    }
    
    @objc private func galleryButtonTapped() {
        // 切換到相簿選擇
        print("📁 切換到相簿選擇")
        // TODO: Task 4.3 - 實作PhotoPicker切換
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
    
    // MARK: - Photo Capture
    
    private func capturePhoto() {
        guard let output = photoOutput else {
            showCameraError("相機未就緒")
            return
        }
        
        // 建立照片設定
        let settings: AVCapturePhotoSettings
        
        // 設定照片格式
        if output.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        // 拍攝照片
        output.capturePhoto(with: settings, delegate: self)
        
        // 拍照動畫效果
        showCaptureAnimation()
    }
    
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
    
    // MARK: - Error Handling
    
    private func showPermissionDeniedStatus() {
        statusLabel.text = "需要相機權限才能拍攝名片\n請到設定中開啟相機權限"
        statusLabel.isHidden = false
        
        // 隱藏相機控制按鈕
        captureButton.isEnabled = false
        galleryButton.isEnabled = false
        
        // 隱藏掃描引導
        guideView.isHidden = true
    }
    
    private func showCameraError(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
        
        print("❌ 相機錯誤: \(message)")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ 拍照失敗: \(error.localizedDescription)")
            showCameraError("拍照失敗，請重試")
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("❌ 無法處理照片數據")
            showCameraError("照片處理失敗")
            return
        }
        
        print("✅ 照片拍攝成功")
        
        // 顯示成功狀態
        guideView.showSuccessState()
        
        // 延遲後通知代理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.delegate?.cameraViewController(self, didCaptureImage: image)
        }
    }
}
