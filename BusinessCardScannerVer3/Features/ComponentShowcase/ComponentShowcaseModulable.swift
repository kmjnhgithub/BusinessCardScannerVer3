//
//  ComponentShowcaseModulable.swift
//  BusinessCardScannerVer3
//
//  元件展示模組介面定義
//  遵循架構文檔的模組化設計原則
//

import UIKit
import Combine

// MARK: - Module Interface

/// 元件展示模組介面
protocol ComponentShowcaseModulable {
    /// 建立元件展示視圖控制器
    func makeComponentShowcaseViewController() -> UIViewController
}

// MARK: - Dependencies

/// 元件展示模組依賴
protocol ComponentShowcaseDependencies {
    // 目前不需要外部依賴，所有依賴通過ServiceContainer取得
}

// MARK: - Coordinator Protocol

/// 元件展示導航協議
protocol ComponentShowcaseCoordinatorProtocol: AnyObject {
    /// 顯示元件展示頁面
    func showComponentShowcase()
    
    /// 關閉元件展示頁面
    func dismissComponentShowcase()
}

// MARK: - Module Implementation

/// 元件展示模組實作
final class ComponentShowcaseModule: ComponentShowcaseModulable {
    
    // MARK: - Properties
    
    private let dependencies: ComponentShowcaseDependencies
    
    // MARK: - Initialization
    
    init(dependencies: ComponentShowcaseDependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - ComponentShowcaseModulable
    
    func makeComponentShowcaseViewController() -> UIViewController {
        let viewModel = ComponentShowcaseViewModel()
        let viewController = ComponentShowcaseViewController(viewModel: viewModel)
        return viewController
    }
}

// MARK: - Dependencies Implementation

/// 元件展示模組依賴實作
struct ComponentShowcaseDependenciesImpl: ComponentShowcaseDependencies {
    // 空實作，所有依賴通過ServiceContainer管理
}