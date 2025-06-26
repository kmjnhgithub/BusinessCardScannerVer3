//
//  PermissionManager.swift

//
//  Created by mike liu on 2025/6/25.
//
import UIKit


class PermissionManager {
    enum PermissionStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }
    
    func requestCameraPermission(completion: @escaping (PermissionStatus) -> Void) {
        // 實際實作會在 Task 4.1
        completion(.authorized)
    }
    
    func requestPhotoLibraryPermission(completion: @escaping (PermissionStatus) -> Void) {
        // 實際實作會在 Task 4.1
        completion(.authorized)
    }
}
