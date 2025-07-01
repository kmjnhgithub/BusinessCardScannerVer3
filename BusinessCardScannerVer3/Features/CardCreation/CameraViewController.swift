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
    
    /// 相機會話管理
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    /// 當前設備
    private var currentDevice: AVCaptureDevice?
    
    // MARK: - UI Components
    
    /// 相機預覽容器
    private let previewContainer = UIView()
    
    /// 控制面板容器
    private let controlsContainer = UIView()
    
    /// 拍照按鈕
    private let captureButton = UIButton(type: .custom)
    
    /// 取消按鈕
    private let cancelButton = UIButton(type: .system)
    
    /// 切換相機按鈕（前/後鏡頭）
    private let switchCameraButton = UIButton(type: .system)
    
    /// 閃光燈按鈕
    private let flashButton = UIButton(type: .system)
    
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
        
        // 檢查權限並設定相機
        checkPermissionAndSetupCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 顯示導航列
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // 停止相機會話
        stopCameraSession()
    }
    
    // MARK: - Setup Methods
    
    override func setupUI() {
        view.backgroundColor = .black
        
        // 設定預覽容器
        previewContainer.backgroundColor = .black
        view.addSubview(previewContainer)
        
        // 設定控制面板
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
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
        
        // 控制面板約束
        controlsContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(120 + view.safeAreaInsets.bottom)
        }
        
        // 拍照按鈕約束
        captureButton.snp.makeConstraints { make in
            make.center.equalTo(controlsContainer)
            make.width.height.equalTo(80)
        }
        
        // 取消按鈕約束
        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(controlsContainer).offset(20)
            make.centerY.equalTo(captureButton)
            make.width.height.equalTo(50)
        }
        
        // 切換相機按鈕約束
        switchCameraButton.snp.makeConstraints { make in
            make.trailing.equalTo(controlsContainer).offset(-20)
            make.centerY.equalTo(captureButton)
            make.width.height.equalTo(50)
        }
        
        // 閃光燈按鈕約束
        flashButton.snp.makeConstraints { make in
            make.top.equalTo(controlsContainer).offset(10)
            make.trailing.equalTo(controlsContainer).offset(-20)
            make.width.height.equalTo(40)
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
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - UI Setup Helpers
    
    private func setupCaptureButton() {
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 40
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.lightGray.cgColor
        captureButton.setTitle("", for: .normal)
        
        // 添加拍照圖標
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.tintColor = .black
        cameraIcon.contentMode = .scaleAspectFit
        captureButton.addSubview(cameraIcon)
        
        cameraIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        controlsContainer.addSubview(captureButton)
    }
    
    private func setupControlButtons() {
        // 取消按鈕
        cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cancelButton.layer.cornerRadius = 25
        controlsContainer.addSubview(cancelButton)
        
        // 切換相機按鈕
        switchCameraButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        switchCameraButton.layer.cornerRadius = 25
        controlsContainer.addSubview(switchCameraButton)
        
        // 閃光燈按鈕
        flashButton.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        flashButton.tintColor = .white
        flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        flashButton.layer.cornerRadius = 20
        controlsContainer.addSubview(flashButton)
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
        
        // 隱藏狀態標籤
        statusLabel.isHidden = true
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
    
    @objc private func switchCameraButtonTapped() {
        // TODO: Task 4.2.3 實作相機切換
        print("🔄 切換相機（待實作）")
    }
    
    @objc private func flashButtonTapped() {
        // TODO: Task 4.2.3 實作閃光燈控制
        print("⚡ 閃光燈控制（待實作）")
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
        switchCameraButton.isEnabled = false
        flashButton.isEnabled = false
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
        
        // 通知代理
        delegate?.cameraViewController(self, didCaptureImage: image)
    }
}
