//
//  MainTabBarController.swift
//  BusinessCardScannerVer3
//
//  主要的 TabBar 控制器，提供底部導航功能
//

import UIKit

/// TabBar 控制器代理協議
protocol MainTabBarControllerDelegate: AnyObject {
    func tabBarController(_ tabBarController: MainTabBarController, shouldSelectTabAt index: Int) -> Bool
    func tabBarController(_ tabBarController: MainTabBarController, didSelectTabAt index: Int)
}

/// 主要的 TabBar 控制器
final class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    
    /// TabBar 代理
    weak var tabBarDelegate: MainTabBarControllerDelegate?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        print("📱 MainTabBarController: 視圖已載入")
    }
    
    // MARK: - Setup
    
    /// 設定 TabBar 外觀
    private func setupTabBar() {
        print("🎨 MainTabBarController: 設定 TabBar 外觀")
        
        // 設定代理
        delegate = self
        
        // 設定 TabBar 外觀
        setupTabBarAppearance()
        
        print("✅ MainTabBarController: TabBar 外觀設定完成")
    }
    
    /// 設定 TabBar 外觀樣式
    private func setupTabBarAppearance() {
        // 背景顏色
        tabBar.backgroundColor = AppTheme.Colors.cardBackground
        tabBar.barTintColor = AppTheme.Colors.cardBackground
        
        // 選中和未選中的顏色
        tabBar.tintColor = AppTheme.Colors.primary
        tabBar.unselectedItemTintColor = AppTheme.Colors.secondaryText
        
        // iOS 15+ 外觀設定
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = AppTheme.Colors.cardBackground
            
            // 正常狀態
            let normalItemAppearance = UITabBarItemAppearance()
            normalItemAppearance.normal.iconColor = AppTheme.Colors.secondaryText
            normalItemAppearance.normal.titleTextAttributes = [
                .foregroundColor: AppTheme.Colors.secondaryText,
                .font: AppTheme.Fonts.caption
            ]
            
            // 選中狀態
            normalItemAppearance.selected.iconColor = AppTheme.Colors.primary
            normalItemAppearance.selected.titleTextAttributes = [
                .foregroundColor: AppTheme.Colors.primary,
                .font: AppTheme.Fonts.caption
            ]
            
            appearance.stackedLayoutAppearance = normalItemAppearance
            appearance.inlineLayoutAppearance = normalItemAppearance
            appearance.compactInlineLayoutAppearance = normalItemAppearance
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // 分隔線
        tabBar.layer.borderWidth = AppTheme.Layout.separatorHeight
        tabBar.layer.borderColor = AppTheme.Colors.separator.cgColor
        
        // 確保 TabBar 顯示在最上層
        tabBar.isTranslucent = false
    }
}

// MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {
    
    /// 即將選擇 Tab 時調用
    /// - Parameters:
    ///   - tabBarController: TabBar 控制器
    ///   - viewController: 即將選中的視圖控制器
    /// - Returns: 是否允許選擇
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let index = viewControllers?.firstIndex(of: viewController) else {
            return true
        }
        
        print("📱 MainTabBarController: shouldSelect index \(index)")
        
        // 詢問代理是否允許切換
        return tabBarDelegate?.tabBarController(self, shouldSelectTabAt: index) ?? true
    }
    
    /// 已選擇 Tab 時調用
    /// - Parameters:
    ///   - tabBarController: TabBar 控制器
    ///   - viewController: 已選中的視圖控制器
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let index = viewControllers?.firstIndex(of: viewController) else {
            return
        }
        
        print("✅ MainTabBarController: didSelect index \(index)")
        
        // 通知代理已完成切換
        tabBarDelegate?.tabBarController(self, didSelectTabAt: index)
        
        // 觸發選中動畫
        animateTabSelection(at: index)
    }
    
    // MARK: - Animation
    
    /// 播放 Tab 選中動畫
    /// - Parameter index: Tab 索引
    private func animateTabSelection(at index: Int) {
        guard let tabBarItems = tabBar.items,
              index < tabBarItems.count else { return }
        
        // 找到對應的 TabBar 按鈕視圖
        let tabBarButtons = tabBar.subviews.filter { $0 is UIControl }
        guard index < tabBarButtons.count else { return }
        
        let selectedButton = tabBarButtons[index]
        
        // 播放縮放動畫
        UIView.animate(
            withDuration: AppTheme.Animation.fastDuration,
            delay: 0,
            usingSpringWithDamping: AppTheme.Animation.springDamping,
            initialSpringVelocity: AppTheme.Animation.springVelocity,
            options: [.allowUserInteraction],
            animations: {
                selectedButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: AppTheme.Animation.fastDuration,
                    animations: {
                        selectedButton.transform = .identity
                    }
                )
            }
        )
    }
}