//
//  ComponentShowcaseCoordinator.swift
//  BusinessCardScannerVer3
//
//  元件展示模組的 Coordinator
//  遵循 Coordinator Pattern 設計原則
//

import UIKit

/// 元件展示模組的 Coordinator
final class ComponentShowcaseCoordinator: BaseCoordinator, ComponentShowcaseCoordinatorProtocol {
    
    // MARK: - Properties
    
    private let moduleFactory: ModuleFactory
    
    // MARK: - Initialization
    
    init(navigationController: UINavigationController, moduleFactory: ModuleFactory) {
        self.moduleFactory = moduleFactory
        super.init(navigationController: navigationController)
    }
    
    // MARK: - BaseCoordinator
    
    override func start() {
        showComponentShowcase()
    }
    
    // MARK: - ComponentShowcaseCoordinatorProtocol
    
    func showComponentShowcase() {
        let module = moduleFactory.makeComponentShowcaseModule()
        let viewController = module.makeComponentShowcaseViewController()
        
        if let componentShowcaseVC = viewController as? ComponentShowcaseViewController {
            componentShowcaseVC.coordinator = self
        }
        
        push(viewController)
    }
    
    func dismissComponentShowcase() {
        pop()
        finish()
    }
}

