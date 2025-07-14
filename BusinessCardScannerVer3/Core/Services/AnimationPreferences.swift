//
//  AnimationPreferences.swift
//  BusinessCardScannerVer3
//
//  動畫偏好設定服務
//  管理應用程式中各種動畫效果的用戶設定
//

import Foundation
import Combine
import UIKit

/// 動畫偏好設定服務
/// 負責管理用戶的動畫偏好設定，提供響應式的設定狀態管理
class AnimationPreferences: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 名片列表動畫是否啟用
    @Published var isCardListAnimationEnabled: Bool {
        didSet {
            userDefaults.set(isCardListAnimationEnabled, forKey: Keys.cardListAnimation)
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Keys
    
    private enum Keys {
        static let cardListAnimation = "cardListAnimationEnabled"
    }
    
    // MARK: - Singleton
    
    static let shared = AnimationPreferences()
    
    // MARK: - Initialization
    
    private init() {
        // 載入儲存的設定，預設啟用動畫
        self.isCardListAnimationEnabled = userDefaults.object(forKey: Keys.cardListAnimation) as? Bool ?? true
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // 監聽系統動畫設定變化
        NotificationCenter.default
            .publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.handleAccessibilityChange()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 切換名片列表動畫開關
    /// - Parameter enabled: 是否啟用動畫
    func toggleCardListAnimation(_ enabled: Bool) {
        isCardListAnimationEnabled = enabled
    }
    
    /// 檢查是否應該顯示動畫
    /// 考慮用戶設定和系統無障礙設定
    /// - Returns: 是否應該顯示動畫
    func shouldShowCardListAnimation() -> Bool {
        // 尊重系統的減少動畫設定
        guard !UIAccessibility.isReduceMotionEnabled else {
            return false
        }
        
        return isCardListAnimationEnabled
    }
    
    /// 重置所有動畫設定為預設值
    func resetToDefaults() {
        isCardListAnimationEnabled = true
    }
    
    // MARK: - TODO: 未來優化計劃
    
    // TODO: 情境感知動畫系統
    // 實作不同場景的動畫類型：
    // - 首次進入名片列表：依序浮現動畫
    // - 新增名片後返回：新名片高亮動畫（金色邊框 + 彈跳效果）
    // - 編輯名片後返回：輕微更新動畫或無動畫
    // - 搜尋結果變更：過濾動畫
    // - 刪除名片：移除動畫
    //
    // enum CardListAnimationContext {
    //     case firstEntry
    //     case returnFromCreation(newCardId: String)
    //     case returnFromEdit
    //     case dataRefresh
    //     case search
    // }
    
    // TODO: 新名片特殊動畫設定
    // 支援新名片的特殊視覺效果：
    // - 金色邊框閃爍（使用 AppTheme.Colors.scannerFrame #FFCC00）
    // - Spring 彈跳動畫（damping: 0.6, velocity: 0.8）
    // - 自動清理機制（3秒後移除高亮狀態）
    //
    // @Published var newCardHighlightEnabled: Bool = true
    // private var recentlyAddedCardIds: Set<String> = []
    
    // TODO: Coordinator 情境傳遞
    // 與 CardListCoordinator 整合，傳遞動畫情境：
    // - func showCardListWithContext(_ context: CardListAnimationContext)
    // - 在 ModuleFactory 中注入動畫情境資訊
    
    // TODO: 多種動畫類型控制
    // 允許用戶分別控制不同類型的動畫：
    // - 列表進場動畫開關
    // - 新名片高亮動畫開關  
    // - 刪除/編輯動畫開關
    // - 搜尋過濾動畫開關
    
    // TODO: 效能優化
    // - 限制同時動畫的 Cell 數量（建議最多 20 個）
    // - 使用 AppTheme.Animation 統一動畫參數
    // - 簡化批次動畫邏輯，改用漸進式淡入
    // - 縮短動畫間隔（0.05秒而非 0.1秒）
    
    // MARK: - Private Methods
    
    /// 處理無障礙設定變化
    private func handleAccessibilityChange() {
        DispatchQueue.main.async { [weak self] in
            // 當系統啟用減少動畫時，通知 UI 更新
            // 這裡使用 objectWillChange 來觸發 UI 重新渲染
            self?.objectWillChange.send()
        }
    }
}

// MARK: - Extensions

extension AnimationPreferences {
    
    /// 取得所有動畫設定的摘要
    var animationSettingsSummary: String {
        let cardListStatus = shouldShowCardListAnimation() ? "啟用" : "停用"
        let accessibilityNote = UIAccessibility.isReduceMotionEnabled ? " (系統減少動畫)" : ""
        
        return "名片列表動畫：\(cardListStatus)\(accessibilityNote)"
    }
    
    /// 檢查是否有任何動畫被系統無障礙設定覆蓋
    var hasAccessibilityOverride: Bool {
        return UIAccessibility.isReduceMotionEnabled && isCardListAnimationEnabled
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension AnimationPreferences {
    
    /// 測試用：強制設定動畫狀態
    func setCardListAnimationForTesting(_ enabled: Bool) {
        isCardListAnimationEnabled = enabled
    }
    
    /// 測試用：清除所有設定
    func clearAllSettingsForTesting() {
        userDefaults.removeObject(forKey: Keys.cardListAnimation)
        resetToDefaults()
    }
}
#endif