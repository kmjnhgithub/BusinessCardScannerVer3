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
        
//        // 方式 1：直接執行測試（推薦先用這個）
        Task13VerificationTest.runAllTests()
        
        // 方式 2：顯示測試 UI
        let testTask13ViewController = Task13VerificationTest.makeTestViewController()
        let navigationController = UINavigationController(rootViewController: testTask13ViewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}
