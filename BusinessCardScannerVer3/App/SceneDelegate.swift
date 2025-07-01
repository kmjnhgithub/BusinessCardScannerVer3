//
//  SceneDelegate.swift
//  BusinessCardScannerVer3
//
//  Scene 生命週期管理，負責視窗設定和應用程式啟動
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Phase 2: 使用 AppCoordinator 啟動應用程式
        setupAppCoordinator()
        
        // Phase 2 驗證測試
        runPhase2VerificationTest()
        
        // Task 3.3 驗證測試
        runTask33VerificationTest()
        
        // Task 3.4 驗證測試
        runTask34VerificationTest()
        
        // Task 4.1 驗證測試
        runTask41VerificationTest()
        
        // Task 4.2 驗證測試
        runTask42VerificationTest()
        
        // Task 4.3 驗證測試
        runTask43VerificationTest()
        
        // 如果需要測試 ComponentShowcase，可以取消註解以下行
        // setupComponentShowcaseTest()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // 清理協調器
        appCoordinator = nil
    }

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
    
    // MARK: - App Setup
    
    /// 設定 AppCoordinator 並啟動應用程式
    private func setupAppCoordinator() {
        guard let window = window else { return }
        
        print("🚀 SceneDelegate: 設定 AppCoordinator")
        
        // 創建 AppCoordinator
        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator
        
        // 啟動應用程式
        coordinator.start()
        
        print("✅ SceneDelegate: AppCoordinator 設定完成")
    }
    
    /// 執行 Phase 2 驗證測試
    private func runPhase2VerificationTest() {
        // 延遲執行測試，確保 UI 已完全載入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task21VerificationTest.setupTestScene(in: self.window)
        }
    }
    
    /// 執行 Task 3.3 驗證測試
    private func runTask33VerificationTest() {
        // 延遲執行測試，確保應用完全啟動
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task33VerificationTest.runVerification()
        }
    }
    
    /// 執行 Task 3.4 驗證測試
    private func runTask34VerificationTest() {
        // 延遲執行測試，確保應用完全啟動
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task34VerificationTest.run()
        }
    }
    
    /// 執行 Task 4.1 驗證測試
    private func runTask41VerificationTest() {
        // 延遲執行測試，確保應用完全啟動
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            Task41VerificationTest.run()
        }
    }
    
    /// Task 4.2 驗證測試
    private func runTask42VerificationTest() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            Task42VerificationTest.run()
        }
    }
    
    /// Task 4.3 驗證測試
    private func runTask43VerificationTest() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            Task43VerificationTest.run()
        }
    }
    
    // MARK: - Task 1.8 ComponentShowcase Test (備用)
    
    /// ComponentShowcase 測試設定（開發測試用）
    private func setupComponentShowcaseTest() {
        let navigationController = UINavigationController()
        let moduleFactory = ModuleFactory()
        
        // 建立 ComponentShowcase Coordinator
        let coordinator = ComponentShowcaseCoordinator(
            navigationController: navigationController,
            moduleFactory: moduleFactory
        )
        
        // 啟動 ComponentShowcase
        coordinator.start()
        
        // 設定根視圖控制器
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        print("✅ Task 1.8: ComponentShowcase 測試應用已啟動")
    }
}
