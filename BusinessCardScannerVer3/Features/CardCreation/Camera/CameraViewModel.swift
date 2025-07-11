//
//  CameraViewModel.swift
//  BusinessCardScannerVer3
//
//  相機模組 ViewModel - 管理相機業務邏輯和狀態
//

import UIKit
import AVFoundation
import Combine

/// 相機狀態枚舉
enum CameraStatus {
    case initializing          // 初始化中
    case permissionDenied      // 權限被拒絕
    case configuring           // 配置相機中
    case ready                 // 準備就緒
    case error(String)         // 錯誤狀態
    case capturing             // 拍攝中
    case captured              // 已拍攝
}

/// 相機 ViewModel
final class CameraViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// 相機狀態
    @Published var cameraStatus: CameraStatus = .initializing
    
    /// 相機會話是否運行中
    @Published var isSessionRunning = false
    
    /// 拍攝的照片
    @Published var capturedImage: UIImage?
    
    /// 狀態訊息（用於顯示在 UI 上）
    @Published var statusMessage: String = "正在啟動相機..."
    
    /// 控制按鈕是否可用
    @Published var controlsEnabled = false
    
    // MARK: - Private Properties
    
    /// 相機會話
    private var captureSession: AVCaptureSession?
    
    /// 照片輸出
    private var photoOutput: AVCapturePhotoOutput?
    
    /// 當前設備
    private var currentDevice: AVCaptureDevice?
    
    /// 依賴服務
    private let permissionManager: PermissionManager
    
    /// Combine 訂閱集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(permissionManager: PermissionManager = ServiceContainer.shared.permissionManager) {
        self.permissionManager = permissionManager
        super.init()
    }
    
    deinit {
        #if DEBUG
        print("✅ \(String(describing: type(of: self))) deinit")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// 初始化相機
    func initializeCamera() {
        print("📸 CameraViewModel: 開始初始化相機")
        checkPermissionAndSetupCamera()
    }
    
    /// 開始相機會話
    func startCameraSession() {
        guard let session = captureSession, !session.isRunning else {
            print("⚠️ CameraViewModel: 相機會話已在運行或不存在")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            
            DispatchQueue.main.async {
                self?.isSessionRunning = session.isRunning
                if session.isRunning {
                    self?.cameraStatus = .ready
                    self?.statusMessage = ""
                    self?.controlsEnabled = true
                }
            }
        }
    }
    
    /// 停止相機會話
    func stopCameraSession() {
        guard let session = captureSession, session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.stopRunning()
            
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    /// 拍攝照片
    func capturePhoto() {
        guard let output = photoOutput else {
            handleCameraError("相機未就緒")
            return
        }
        
        guard cameraStatus == .ready else {
            print("⚠️ CameraViewModel: 相機狀態不正確，無法拍攝")
            return
        }
        
        cameraStatus = .capturing
        
        // 建立照片設定
        let settings: AVCapturePhotoSettings
        
        if output.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        // 拍攝照片
        output.capturePhoto(with: settings, delegate: self)
        
        print("📸 CameraViewModel: 開始拍攝照片")
    }
    
    /// 重置狀態
    func resetToReady() {
        guard captureSession != nil else { return }
        
        cameraStatus = .ready
        capturedImage = nil
        statusMessage = ""
        controlsEnabled = true
    }
    
    /// 取得相機會話（用於預覽層設定）
    func getCaptureSession() -> AVCaptureSession? {
        return captureSession
    }
    
    // MARK: - Private Methods
    
    /// 檢查權限並設定相機
    private func checkPermissionAndSetupCamera() {
        switch permissionManager.cameraPermissionStatus() {
        case .authorized:
            setupCamera()
        case .denied, .restricted:
            handlePermissionDenied()
        case .notDetermined:
            requestCameraPermission()
        }
    }
    
    /// 請求相機權限
    private func requestCameraPermission() {
        permissionManager.requestCameraPermission { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.setupCamera()
                default:
                    self?.handlePermissionDenied()
                }
            }
        }
    }
    
    /// 處理權限被拒絕
    private func handlePermissionDenied() {
        cameraStatus = .permissionDenied
        statusMessage = "需要相機權限才能拍攝名片\n請到設定中開啟相機權限"
        controlsEnabled = false
        
        print("❌ CameraViewModel: 相機權限被拒絕")
    }
    
    /// 設定相機
    private func setupCamera() {
        cameraStatus = .configuring
        statusMessage = "正在配置相機..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.configureCameraSession()
        }
    }
    
    /// 配置相機會話
    private func configureCameraSession() {
        guard captureSession == nil else { return }
        
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        // 設定相機輸入
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            DispatchQueue.main.async { [weak self] in
                self?.handleCameraError("無法存取相機設備")
            }
            return
        }
        
        currentDevice = device
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handleCameraError("無法配置相機輸入")
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
                self?.handleCameraError("無法配置照片輸出")
            }
            return
        }
        
        captureSession = session
        
        DispatchQueue.main.async { [weak self] in
            self?.cameraStatus = .ready
            self?.statusMessage = ""
            self?.controlsEnabled = true
            print("✅ CameraViewModel: 相機配置完成")
        }
    }
    
    /// 處理相機錯誤
    private func handleCameraError(_ message: String) {
        cameraStatus = .error(message)
        statusMessage = message
        controlsEnabled = false
        
        print("❌ CameraViewModel: 相機錯誤 - \(message)")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ CameraViewModel: 拍照失敗 - \(error.localizedDescription)")
            handleCameraError("拍照失敗，請重試")
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("❌ CameraViewModel: 無法處理照片數據")
            handleCameraError("照片處理失敗")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.cameraStatus = .captured
            print("✅ CameraViewModel: 照片拍攝成功")
        }
    }
}

// MARK: - Helper Extensions

extension CameraStatus: Equatable {
    static func == (lhs: CameraStatus, rhs: CameraStatus) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.permissionDenied, .permissionDenied),
             (.configuring, .configuring),
             (.ready, .ready),
             (.capturing, .capturing),
             (.captured, .captured):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

extension CameraStatus {
    
    /// 是否處於可用狀態
    var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }
    
    /// 是否有錯誤
    var hasError: Bool {
        switch self {
        case .error, .permissionDenied:
            return true
        default:
            return false
        }
    }
    
    /// 錯誤訊息
    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        case .permissionDenied:
            return "需要相機權限才能拍攝名片"
        default:
            return nil
        }
    }
}