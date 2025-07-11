//
//  CameraCoordinator.swift
//  BusinessCardScannerVer3
//
//  相機模組協調器
//

import UIKit
import Combine

/// 相機模組輸出協議
protocol CameraModuleOutput: AnyObject {
    func cameraDidCaptureImage(_ image: UIImage)
    func cameraDidCancel()
}

/// 相機協調器
final class CameraCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private let moduleFactory: ModuleFactory
    private var cameraViewController: CameraViewController?
    
    /// 模組輸出代理
    weak var moduleOutput: CameraModuleOutput?
    
    // MARK: - Initialization
    
    init(navigationController: UINavigationController, moduleFactory: ModuleFactory) {
        self.moduleFactory = moduleFactory
        super.init(navigationController: navigationController)
    }
    
    // MARK: - Coordinator Lifecycle
    
    override func start() {
        setupCameraModule()
    }
    
    override func finish() {
        super.finish()
        cameraViewController = nil
        moduleOutput = nil
    }
    
    // MARK: - Private Methods
    
    private func setupCameraModule() {
        print("📸 CameraCoordinator: 啟動相機模組")
        
        // 建立 ViewModel
        let cameraViewModel = CameraViewModel()
        
        // 建立相機視圖控制器
        let cameraVC = CameraViewController(viewModel: cameraViewModel)
        cameraVC.delegate = self
        self.cameraViewController = cameraVC
        
        // 以 Modal 方式呈現
        cameraVC.modalPresentationStyle = .fullScreen
        navigationController.present(cameraVC, animated: true)
        
        print("✅ CameraCoordinator: 相機模組啟動完成")
    }
    
    private func dismissCamera() {
        guard let cameraVC = cameraViewController else { return }
        
        cameraVC.dismiss(animated: true) { [weak self] in
            self?.finish()
        }
    }
}

// MARK: - CameraViewControllerDelegate

extension CameraCoordinator: CameraViewControllerDelegate {
    
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage) {
        print("✅ CameraCoordinator: 收到拍攝的照片")
        
        // 通知模組輸出
        moduleOutput?.cameraDidCaptureImage(image)
        
        // 關閉相機
        dismissCamera()
    }
    
    func cameraViewControllerDidCancel(_ controller: CameraViewController) {
        print("❌ CameraCoordinator: 用戶取消拍攝")
        
        // 通知模組輸出
        moduleOutput?.cameraDidCancel()
        
        // 關閉相機
        dismissCamera()
    }
    
    func cameraViewControllerDidRequestGallery(_ controller: CameraViewController) {
        print("📁 CameraCoordinator: 用戶請求切換到相簿")
        
        // 關閉相機並通知取消（讓上層處理相簿選擇）
        moduleOutput?.cameraDidCancel()
        dismissCamera()
    }
}

// MARK: - Module Factory Extension

extension ModuleFactory {
    
    /// 建立相機模組協調器
    func makeCameraCoordinator(navigationController: UINavigationController) -> CameraCoordinator {
        return CameraCoordinator(navigationController: navigationController, moduleFactory: self)
    }
}