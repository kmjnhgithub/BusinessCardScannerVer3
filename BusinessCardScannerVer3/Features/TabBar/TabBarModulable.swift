//
//  TabBarModulable.swift
//  BusinessCardScannerVer3
//
//  TabBar 模組接口定義
//

import UIKit

// MARK: - TabBar Module Interface

/// TabBar 模組接口
protocol TabBarModulable {
    /// 創建 TabBar 協調器
    /// - Parameters:
    ///   - navigationController: 導航控制器
    ///   - moduleFactory: 模組工廠
    /// - Returns: TabBar 協調器
    func makeCoordinator(
        navigationController: UINavigationController,
        moduleFactory: ModuleFactory
    ) -> TabBarCoordinator
}

// MARK: - TabBar Module Implementation

/// TabBar 模組實現
struct TabBarModule: TabBarModulable {
    
    /// 創建 TabBar 協調器
    /// - Parameters:
    ///   - navigationController: 導航控制器
    ///   - moduleFactory: 模組工廠
    /// - Returns: TabBar 協調器
    func makeCoordinator(
        navigationController: UINavigationController,
        moduleFactory: ModuleFactory
    ) -> TabBarCoordinator {
        return TabBarCoordinator(
            navigationController: navigationController,
            moduleFactory: moduleFactory
        )
    }
}
