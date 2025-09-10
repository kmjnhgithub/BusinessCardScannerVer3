import Foundation
import Combine
import AVFoundation
@testable import BusinessCardScannerVer3

/// Mock 權限管理器，用於測試權限相關功能
final class MockPermissionManager: PermissionManagerProtocol {
    
    // MARK: - Mock Configuration
    
    /// 相機權限狀態
    var cameraPermissionStatus: AVAuthorizationStatus = .authorized
    
    /// 照片庫權限狀態
    var photoLibraryPermissionStatus: Bool = true
    
    /// 是否模擬權限請求延遲
    var simulateDelay: Bool = false
    
    /// 權限請求延遲時間
    var permissionDelay: TimeInterval = 0.2
    
    // MARK: - Analytics
    
    private(set) var cameraPermissionRequestCount: Int = 0
    private(set) var photoLibraryPermissionRequestCount: Int = 0
    private(set) var cameraPermissionCheckCount: Int = 0
    private(set) var photoLibraryPermissionCheckCount: Int = 0
    
    // MARK: - PermissionManagerProtocol Implementation
    
    func requestCameraPermission() -> AnyPublisher<AVAuthorizationStatus, Never> {
        cameraPermissionRequestCount += 1
        
        return Future<AVAuthorizationStatus, Never> { [weak self] promise in
            guard let self = self else {
                promise(.success(.denied))
                return
            }
            
            let delay = self.simulateDelay ? self.permissionDelay : 0.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                promise(.success(self.cameraPermissionStatus))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func requestPhotoLibraryPermission() -> AnyPublisher<Bool, Never> {
        photoLibraryPermissionRequestCount += 1
        
        return Future<Bool, Never> { [weak self] promise in
            guard let self = self else {
                promise(.success(false))
                return
            }
            
            let delay = self.simulateDelay ? self.permissionDelay : 0.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                promise(.success(self.photoLibraryPermissionStatus))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func checkCameraPermission() -> AVAuthorizationStatus {
        cameraPermissionCheckCount += 1
        return cameraPermissionStatus
    }
    
    func checkPhotoLibraryPermission() -> Bool {
        photoLibraryPermissionCheckCount += 1
        return photoLibraryPermissionStatus
    }
    
    // MARK: - Test Helpers
    
    /// 重置 Mock 狀態
    func reset() {
        cameraPermissionStatus = .authorized
        photoLibraryPermissionStatus = true
        simulateDelay = false
        permissionDelay = 0.2
        
        cameraPermissionRequestCount = 0
        photoLibraryPermissionRequestCount = 0
        cameraPermissionCheckCount = 0
        photoLibraryPermissionCheckCount = 0
    }
    
    /// 設定權限拒絕場景
    func setPermissionDeniedScenario() {
        cameraPermissionStatus = .denied
        photoLibraryPermissionStatus = false
    }
    
    /// 設定未決定權限場景
    func setPermissionNotDeterminedScenario() {
        cameraPermissionStatus = .notDetermined
        photoLibraryPermissionStatus = false
    }
    
    /// 設定受限權限場景  
    func setPermissionRestrictedScenario() {
        cameraPermissionStatus = .restricted
        photoLibraryPermissionStatus = false
    }
    
    /// 模擬權限從拒絕變為允許的場景
    func simulatePermissionGranted() {
        cameraPermissionStatus = .authorized
        photoLibraryPermissionStatus = true
    }
}