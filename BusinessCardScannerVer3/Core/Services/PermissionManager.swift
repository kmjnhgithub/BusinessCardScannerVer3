//
//  PermissionManager.swift
//  BusinessCardScannerVer3
//
//  Task 4.1: 權限管理服務
//  處理相機和相簿權限請求，提供統一的權限管理介面
//

import UIKit
import AVFoundation
import Photos

/// 權限管理服務
/// 負責處理相機和相簿權限的請求、檢查和狀態管理
class PermissionManager {
    
    // MARK: - Types
    
    /// 權限狀態枚舉
    enum PermissionStatus {
        case notDetermined  // 尚未決定
        case authorized     // 已授權
        case denied         // 拒絕
        case restricted     // 受限制（家長控制等）
    }
    
    /// 權限類型
    enum PermissionType {
        case camera
        case photoLibrary
    }
    
    // MARK: - Singleton
    
    static let shared = PermissionManager()
    private init() {}
    
    // MARK: - Public Interface
    
    /// 檢查相機權限狀態
    func cameraPermissionStatus() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return mapAVAuthorizationStatus(status)
    }
    
    /// 檢查相簿權限狀態
    func photoLibraryPermissionStatus() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        return mapPHAuthorizationStatus(status)
    }
    
    /// 請求相機權限
    /// - Parameter completion: 權限請求完成回調，返回最終權限狀態
    func requestCameraPermission(completion: @escaping (PermissionStatus) -> Void) {
        let currentStatus = cameraPermissionStatus()
        
        switch currentStatus {
        case .notDetermined:
            // 尚未決定，請求權限
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    let newStatus = self?.cameraPermissionStatus() ?? .denied
                    completion(newStatus)
                }
            }
        case .authorized, .denied, .restricted:
            // 已有決定，直接返回當前狀態
            completion(currentStatus)
        }
    }
    
    /// 請求相簿權限
    /// - Parameter completion: 權限請求完成回調，返回最終權限狀態
    func requestPhotoLibraryPermission(completion: @escaping (PermissionStatus) -> Void) {
        let currentStatus = photoLibraryPermissionStatus()
        
        switch currentStatus {
        case .notDetermined:
            // 尚未決定，請求權限
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    let newStatus = self?.mapPHAuthorizationStatus(status) ?? .denied
                    completion(newStatus)
                }
            }
        case .authorized, .denied, .restricted:
            // 已有決定，直接返回當前狀態
            completion(currentStatus)
        }
    }
    
    /// 檢查是否可以使用相機
    func canUseCamera() -> Bool {
        return cameraPermissionStatus() == .authorized
    }
    
    /// 檢查是否可以使用相簿
    func canUsePhotoLibrary() -> Bool {
        return photoLibraryPermissionStatus() == .authorized
    }
    
    // MARK: - Private Helpers
    
    /// 將 AVAuthorizationStatus 映射到內部 PermissionStatus
    private func mapAVAuthorizationStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
    
    /// 將 PHAuthorizationStatus 映射到內部 PermissionStatus
    private func mapPHAuthorizationStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .limited:
            // iOS 14+ 有限權限，視為已授權
            return .authorized
        @unknown default:
            return .denied
        }
    }
}

// MARK: - Permission Helper Extensions

extension PermissionManager {
    
    /// 顯示權限設定提示
    /// - Parameters:
    ///   - type: 權限類型
    ///   - from: 發起的視圖控制器
    func showPermissionSettingsAlert(for type: PermissionType, from viewController: UIViewController) {
        let permissionName = type == .camera ? "相機" : "照片"
        let title = "\(permissionName)權限被拒絕"
        let message = "請到設定中開啟\(permissionName)權限，以使用此功能。"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // 設定按鈕
        let settingsAction = UIAlertAction(title: "前往設定", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        viewController.present(alert, animated: true)
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension PermissionManager {
    
    /// 調試用：打印當前權限狀態
    func printCurrentPermissions() {
        print("📋 Permission Status:")
        print("📷 Camera: \(cameraPermissionStatus())")
        print("📁 Photo Library: \(photoLibraryPermissionStatus())")
    }
}
#endif
