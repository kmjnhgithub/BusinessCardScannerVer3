//
//  CardListAnimator.swift
//  BusinessCardScannerVer3
//
//  名片列表動畫處理器
//  負責實現名片依序浮現的動畫效果
//

import UIKit
import Combine

/// 名片列表動畫處理器
/// 專責處理名片列表的進場動畫，實現依序浮現效果
class CardListAnimator {
    
    // MARK: - Properties
    
    private let animationPreferences: AnimationPreferences
    private var animationCancellables = Set<AnyCancellable>()
    private var isAnimating = false
    
    // MARK: - Constants
    
    private enum AnimationConstants {
        static let duration: TimeInterval = 0.3          // 每張名片動畫時長 (遵循 UI 設計規範)
        static let staggerDelay: TimeInterval = 0.1      // 名片間隔時間
        static let translateYOffset: CGFloat = 20        // 垂直位移距離
        static let maxAnimatedCells: Int = 50           // 效能限制：最多動畫的 Cell 數量
        static let batchSize: Int = 10                  // 批次動畫大小，避免一次啟動太多動畫
    }
    
    // MARK: - Initialization
    
    init(animationPreferences: AnimationPreferences = AnimationPreferences.shared) {
        self.animationPreferences = animationPreferences
    }
    
    // MARK: - Public Methods
    
    /// 執行名片列表進場動畫
    /// - Parameters:
    ///   - tableView: 要執行動畫的 TableView
    ///   - cellCount: Cell 總數
    ///   - completion: 動畫完成回調
    func animateCardListAppearance(
        tableView: UITableView,
        cellCount: Int,
        completion: @escaping () -> Void = {}
    ) {
        // 防止重複動畫
        guard !isAnimating else {
            completion()
            return
        }
        
        // 檢查是否應該顯示動畫
        guard animationPreferences.shouldShowCardListAnimation() else {
            completion()
            return
        }
        
        // 效能考量：Cell 數量過多時停用動畫
        guard cellCount <= AnimationConstants.maxAnimatedCells else {
            print("📱 CardListAnimator: 名片數量 (\(cellCount)) 超過限制，停用動畫")
            completion()
            return
        }
        
        // 標記動畫開始
        isAnimating = true
        
        // 確保在主線程執行
        DispatchQueue.main.async { [weak self] in
            self?.performSequentialAnimation(
                tableView: tableView,
                cellCount: cellCount,
                completion: { [weak self] in
                    // 動畫完成，重置狀態
                    self?.isAnimating = false
                    completion()
                }
            )
        }
    }
    
    /// 立即停止所有動畫
    /// 用於快速切換或離開頁面時
    func stopAllAnimations() {
        animationCancellables.removeAll()
        isAnimating = false
    }
    
    // MARK: - Private Methods
    
    /// 執行依序動畫
    private func performSequentialAnimation(
        tableView: UITableView,
        cellCount: Int,
        completion: @escaping () -> Void
    ) {
        // 先隱藏所有可見的 Cell
        prepareVisibleCells(tableView)
        
        // 計算需要動畫的 Cell 數量
        let animatedCellCount = min(cellCount, AnimationConstants.maxAnimatedCells)
        
        // 使用批次動畫以提升效能
        animateCellsInBatches(
            tableView: tableView,
            totalCells: animatedCellCount,
            completion: completion
        )
    }
    
    /// 準備可見的 Cell（設為初始動畫狀態）
    private func prepareVisibleCells(_ tableView: UITableView) {
        for cell in tableView.visibleCells {
            // 設定初始狀態：向下位移且透明
            cell.transform = CGAffineTransform(translationX: 0, y: AnimationConstants.translateYOffset)
            cell.alpha = 0
        }
    }
    
    /// 批次執行 Cell 動畫
    private func animateCellsInBatches(
        tableView: UITableView,
        totalCells: Int,
        completion: @escaping () -> Void
    ) {
        let batches = Array(0..<totalCells).chunked(into: AnimationConstants.batchSize)
        var completedBatches = 0
        
        for (batchIndex, batch) in batches.enumerated() {
            // 計算批次延遲時間
            let batchDelay = TimeInterval(batchIndex) * AnimationConstants.staggerDelay * Double(AnimationConstants.batchSize)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + batchDelay) { [weak self] in
                self?.animateBatch(
                    tableView: tableView,
                    cellIndices: Array(batch),
                    completion: {
                        completedBatches += 1
                        // 所有批次完成時呼叫 completion
                        if completedBatches == batches.count {
                            completion()
                        }
                    }
                )
            }
        }
    }
    
    /// 執行單一批次的動畫
    private func animateBatch(
        tableView: UITableView,
        cellIndices: [Int],
        completion: @escaping () -> Void
    ) {
        var animatedCount = 0
        let totalCount = cellIndices.count
        
        for (index, cellIndex) in cellIndices.enumerated() {
            let delay = TimeInterval(index) * AnimationConstants.staggerDelay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.animateSingleCell(
                    tableView: tableView,
                    at: cellIndex,
                    completion: {
                        animatedCount += 1
                        if animatedCount == totalCount {
                            completion()
                        }
                    }
                )
            }
        }
    }
    
    /// 執行單一 Cell 的動畫
    private func animateSingleCell(
        tableView: UITableView,
        at index: Int,
        completion: @escaping () -> Void
    ) {
        let indexPath = IndexPath(row: index, section: 0)
        
        // 檢查 IndexPath 是否有效且 Cell 可見
        guard indexPath.row < tableView.numberOfRows(inSection: 0),
              let cell = tableView.cellForRow(at: indexPath) else {
            completion()
            return
        }
        
        // 執行動畫：從下方滑入並淡入
        UIView.animate(
            withDuration: AnimationConstants.duration,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                // 恢復正常位置和透明度
                cell.transform = .identity
                cell.alpha = 1.0
            },
            completion: { _ in
                completion()
            }
        )
    }
}

// MARK: - Utility Extensions

private extension Array {
    /// 將陣列分割為指定大小的子陣列
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension CardListAnimator {
    
    /// 測試用：執行簡化動畫（忽略偏好設定）
    func animateForTesting(
        tableView: UITableView,
        cellCount: Int,
        completion: @escaping () -> Void = {}
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.performSequentialAnimation(
                tableView: tableView,
                cellCount: min(cellCount, 10), // 測試時限制數量
                completion: completion
            )
        }
    }
    
    /// 測試用：取得動畫常數
    var testAnimationConstants: (duration: TimeInterval, delay: TimeInterval, maxCells: Int) {
        return (
            duration: AnimationConstants.duration,
            delay: AnimationConstants.staggerDelay,
            maxCells: AnimationConstants.maxAnimatedCells
        )
    }
}
#endif