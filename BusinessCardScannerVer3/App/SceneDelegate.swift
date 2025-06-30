//
//  SceneDelegate.swift
//  BusinessCardScanner
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    //
    //  在 SceneDelegate.swift 中加入以下程式碼來驗證 Task 1.3
    //

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Task 1.8 ComponentShowcase 測試
        setupComponentShowcaseTest()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
    
    // MARK: - Task 1.8 ComponentShowcase Test
    
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
