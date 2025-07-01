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
        
        // 開發驗證測試 - 只在 DEBUG 模式下執行
        #if DEBUG
        runDevelopmentVerificationTests()
        #endif
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
    
    /// 執行開發驗證測試 - 統一管理所有驗證測試
    private func runDevelopmentVerificationTests() {
        // 設定：是否啟用驗證測試
        let enableVerificationTests = true
        
        guard enableVerificationTests else {
            print("驗證測試已停用")
            return
        }
        
        print("開始執行開發驗證測試...")
        
        // 已完成的功能測試 - 可選擇性執行
        runCompletedFeatureTests()
        
        // 正在開發的功能測試 - 保持啟用
        runActiveFeatureTests()
    }
    
    /// 執行已完成功能的驗證測試（可選）
    private func runCompletedFeatureTests() {
        let testCompletedFeatures = false // 設為 false 來停用已完成功能的測試
        
        guard testCompletedFeatures else {
            print("⏭️  跳過已完成功能的驗證測試")
            return
        }
        
        // Phase 2 驗證測試
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task21VerificationTest.setupTestScene(in: self.window)
        }
        
        // Task 3.3 驗證測試
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task33VerificationTest.runVerification()
        }
        
        // Task 3.4 驗證測試
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task34VerificationTest.run()
        }
        
        // Task 4.1 驗證測試
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            Task41VerificationTest.run()
        }
        
        // Task 4.2 驗證測試
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            Task42VerificationTest.run()
        }
    }
    
    /// 執行正在開發功能的驗證測試
    private func runActiveFeatureTests() {
        // Task 4.3 驗證測試 - 正在開發中
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Task43VerificationTest.run() // 當Task 4.3完成時啟用
        }
        
        print("✅ 活躍功能驗證測試已設定")
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
