//
//  PhotoPickerCoordinator.swift
//  BusinessCardScannerVer3
//
//  相簿選擇協調器
//

import UIKit
import PhotosUI
import Combine

/// 相簿選擇模組輸出協議
protocol PhotoPickerModuleOutput: AnyObject {
    func photoPickerDidSelectImage(_ image: UIImage)
    func photoPickerDidCancel()
}

/// 相簿選擇協調器
final class PhotoPickerCoordinator: BaseCoordinator {
    
    // MARK: - Properties
    
    private let moduleFactory: ModuleFactory
    private var pickerViewController: PHPickerViewController?
    
    /// 模組輸出代理
    weak var moduleOutput: PhotoPickerModuleOutput?
    
    // MARK: - Initialization
    
    init(navigationController: UINavigationController, moduleFactory: ModuleFactory) {
        self.moduleFactory = moduleFactory
        super.init(navigationController: navigationController)
    }
    
    // MARK: - Coordinator Lifecycle
    
    override func start() {
        setupPhotoPickerModule()
    }
    
    override func finish() {
        super.finish()
        pickerViewController = nil
        moduleOutput = nil
    }
    
    // MARK: - Private Methods
    
    private func setupPhotoPickerModule() {
        print("📁 PhotoPickerCoordinator: 啟動相簿選擇模組")
        
        // 檢查相簿權限
        let permissionManager = ServiceContainer.shared.permissionManager
        permissionManager.requestPhotoLibraryPermission { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.presentPhotoPicker()
                default:
                    self?.handlePermissionDenied()
                }
            }
        }
    }
    
    private func presentPhotoPicker() {
        // 配置 PHPicker
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        // 建立選擇器
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        
        self.pickerViewController = picker
        
        // 呈現選擇器
        navigationController.present(picker, animated: true)
        
        print("✅ PhotoPickerCoordinator: 相簿選擇器啟動完成")
    }
    
    private func handlePermissionDenied() {
        print("❌ PhotoPickerCoordinator: 相簿權限被拒絕")
        
        // 通知權限被拒絕
        moduleOutput?.photoPickerDidCancel()
        finish()
    }
    
    private func dismissPicker() {
        guard let picker = pickerViewController else { return }
        
        picker.dismiss(animated: true) { [weak self] in
            self?.finish()
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PhotoPickerCoordinator: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        guard let result = results.first else {
            print("❌ PhotoPickerCoordinator: 用戶取消選擇")
            moduleOutput?.photoPickerDidCancel()
            dismissPicker()
            return
        }
        
        // 載入選中的圖片
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ PhotoPickerCoordinator: 圖片載入失敗 - \(error.localizedDescription)")
                    self?.moduleOutput?.photoPickerDidCancel()
                    self?.dismissPicker()
                    return
                }
                
                guard let image = object as? UIImage else {
                    print("❌ PhotoPickerCoordinator: 無法轉換為 UIImage")
                    self?.moduleOutput?.photoPickerDidCancel()
                    self?.dismissPicker()
                    return
                }
                
                print("✅ PhotoPickerCoordinator: 成功選擇圖片")
                
                // 通知模組輸出
                self?.moduleOutput?.photoPickerDidSelectImage(image)
                
                // 關閉選擇器
                self?.dismissPicker()
            }
        }
    }
}

// MARK: - Module Factory Extension

extension ModuleFactory {
    
    /// 建立相簿選擇模組協調器
    func makePhotoPickerCoordinator(navigationController: UINavigationController) -> PhotoPickerCoordinator {
        return PhotoPickerCoordinator(navigationController: navigationController, moduleFactory: self)
    }
}