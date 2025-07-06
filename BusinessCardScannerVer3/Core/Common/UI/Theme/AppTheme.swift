//
//  AppTheme.swift
//  BusinessCardScanner
//
//  全域設計常數定義（根據 UI 設計規範文檔 v1.0）


import UIKit

/// App 全域設計常數
/// 集中管理所有設計相關的顏色、字型、間距等常數
enum AppTheme {
    
    // MARK: - Colors
    
    /// 顏色系統
    enum Colors {
        
        // MARK: 品牌色
        
        /// 主要品牌色 - 用於主要操作、連結、焦點狀態
        static let primary = UIColor(hex: "#007AFF")
        
        /// 次要品牌色 - 用於次要操作、輔助資訊
        static let secondary = UIColor(hex: "#5856D6")
        
        // MARK: 語義顏色
        
        /// 成功狀態色 - 用於成功狀態、完成提示
        static let success = UIColor(hex: "#34C759")
        
        /// 警告狀態色 - 用於警告資訊、需注意事項
        static let warning = UIColor(hex: "#FF9500")
        
        /// 錯誤狀態色 - 用於錯誤狀態、刪除操作
        static let error = UIColor(hex: "#FF3B30")
        
        /// 資訊提示色 - 用於資訊提示、說明文字
        static let info = UIColor(hex: "#007AFF")
        
        // MARK: 中性色
        
        /// 頁面背景色
        static let background = UIColor(hex: "#F2F2F7")
        
        /// 卡片背景色 - 用於卡片、輸入框背景
        static let cardBackground = UIColor.white
        
        /// 次要背景色 - 用於次要區域背景
        static let secondaryBackground = UIColor(hex: "#E5E5EA")
        
        /// 主要文字色 - 90% 黑色
        static let primaryText = UIColor.black.withAlphaComponent(0.9)
        
        /// 次要文字色 - 60% 黑色，用於次要文字、提示文字
        static let secondaryText = UIColor(hex: "#3C3C43").withAlphaComponent(0.6)
        
        /// 占位文字色
        static let placeholder = UIColor(hex: "#8E8E93")
        
        /// 分隔線顏色
        static let separator = UIColor(hex: "#C6C6C8")
        
        /// TabBar 選中狀態色
        static let tabBarTint = UIColor(hex: "#007AFF")
        
        // MARK: 特殊用途
        
        /// 相機掃描框顏色
        static let scannerFrame = UIColor(hex: "#FFCC00")
        
        /// 掃描遮罩顏色 - 40% 黑色
        static let scannerOverlay = UIColor.black.withAlphaComponent(0.4)
        
        /// 載入遮罩顏色 - 50% 黑色
        static let loadingOverlay = UIColor.black.withAlphaComponent(0.5)
    }
    
    // MARK: - Fonts
    
    /// 字型系統
    enum Fonts {
        
        // MARK: 基礎字型層級
        
        /// 導航列標題 - SF Pro Display, 17pt, Semibold
        static let navigationTitle = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        /// 頁面大標題 - SF Pro Display, 34pt, Bold
        static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .bold)
        
        /// 區塊標題 - SF Pro Display, 28pt, Regular
        static let title1 = UIFont.systemFont(ofSize: 28, weight: .regular)
        
        /// 子標題 - SF Pro Display, 22pt, Regular
        static let title2 = UIFont.systemFont(ofSize: 22, weight: .regular)
        
        /// 小標題 - SF Pro Display, 20pt, Regular
        static let title3 = UIFont.systemFont(ofSize: 20, weight: .regular)
        
        /// 正文 - SF Pro Text, 17pt, Regular
        static let body = UIFont.systemFont(ofSize: 17, weight: .regular)
        
        /// 強調正文 - SF Pro Text, 17pt, Semibold
        static let bodyBold = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        /// 標註文字 - SF Pro Text, 16pt, Regular
        static let callout = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        /// 註腳 - SF Pro Text, 13pt, Regular
        static let footnote = UIFont.systemFont(ofSize: 13, weight: .regular)
        
        /// 說明文字 - SF Pro Text, 12pt, Regular
        static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        // MARK: 特定場景字型
        
        /// 名片姓名 - 18pt, Semibold，用於列表和詳情頁
        static let cardName = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        /// 公司名稱 - 16pt, Regular
        static let companyName = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        /// 職稱 - 14pt, Regular
        static let jobTitle = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        /// 按鈕文字 - 17pt, Medium
        static let buttonTitle = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        /// 輸入框標籤 - 15pt, Regular
        static let inputLabel = UIFont.systemFont(ofSize: 15, weight: .regular)
        
        /// 錯誤提示 - 12pt, Regular
        static let errorMessage = UIFont.systemFont(ofSize: 12, weight: .regular)
    }
    
    // MARK: - Layout
    
    /// 間距與佈局系統
    enum Layout {
        
        // MARK: 基礎間距
        
        /// 元件內部間距 - 8pt
        static let compactPadding: CGFloat = 8
        
        /// 標準元件間距 - 16pt
        static let standardPadding: CGFloat = 16
        
        /// 區塊間距 - 24pt
        static let largePadding: CGFloat = 24
        
        /// 章節間距 - 32pt
        static let sectionPadding: CGFloat = 32
        
        // MARK: 邊距規範
        
        /// 螢幕左右邊距 - 16pt
        static let screenHorizontalPadding: CGFloat = 16
        
        /// 卡片內邊距 - 16pt
        static let cardPadding: CGFloat = 16
        
        /// 列表項目左右邊距 - 16pt
        static let cellHorizontalPadding: CGFloat = 16
        
        /// 導航列按鈕邊距 - 16pt
        static let navigationBarPadding: CGFloat = 16
        
        // MARK: 元件尺寸
        
        /// 按鈕高度 - 50pt
        static let buttonHeight: CGFloat = 50
        
        /// 按鈕圓角 - 10pt
        static let buttonCornerRadius: CGFloat = 10
        
        /// 按鈕內邊距（左右）- 16pt
        static let buttonHorizontalPadding: CGFloat = 16
        
        /// 按鈕最小寬度 - 100pt
        static let buttonMinWidth: CGFloat = 100
        
        /// 輸入框高度 - 48pt
        static let textFieldHeight: CGFloat = 48
        
        /// 輸入框底線高度 - 1pt
        static let textFieldUnderlineHeight: CGFloat = 1
        
        /// 標籤與輸入框間距 - 8pt
        static let labelToFieldSpacing: CGFloat = 8
        
        /// 錯誤訊息間距 - 4pt
        static let errorMessageSpacing: CGFloat = 4
        
        /// 卡片圓角 - 16pt
        static let cardCornerRadius: CGFloat = 16
        
        /// 列表項目高度 - 88pt
        static let cellHeight: CGFloat = 88
        
        /// 列表圖片大小 - 56x56pt
        static let cellImageSize: CGFloat = 56
        
        /// 列表圖片圓角 - 8pt
        static let cellImageCornerRadius: CGFloat = 8
        
        /// 分隔線高度 - 0.5pt
        static let separatorHeight: CGFloat = 0.5
        
        /// 分隔線左邊距 - 88pt
        static let separatorLeftInset: CGFloat = 88
        
        /// 表單區塊間距 - 32pt
        static let formSectionSpacing: CGFloat = 32
        
        /// 表單區塊圓角 - 12pt
        static let formSectionCornerRadius: CGFloat = 12
        
        /// 標題與內容間距 - 8pt
        static let titleToContentSpacing: CGFloat = 8
        
        /// Loading 容器大小 - 120x120pt
        static let loadingContainerSize: CGFloat = 120
        
        /// Loading 容器圓角 - 12pt
        static let loadingCornerRadius: CGFloat = 12
        
        /// Toast 高度 - 50pt
        static let toastHeight: CGFloat = 50
        
        /// Toast 圓角 - 25pt
        static let toastCornerRadius: CGFloat = 25
        
        /// Toast 內邊距（左右）- 20pt
        static let toastHorizontalPadding: CGFloat = 20
        
        /// Toast 邊距 - 20pt
        static let toastMargin: CGFloat = 20
        
        /// 相機快門按鈕大小 - 70pt
        static let cameraShutterSize: CGFloat = 70
        
        /// 導航圖示大小 - 24pt
        static let navigationIconSize: CGFloat = 24
        
        /// TabBar 圖示大小 - 24pt
        static let tabBarIconSize: CGFloat = 24
        
        /// 功能圖示大小 - 20pt
        static let actionIconSize: CGFloat = 20
        
        /// 新增按鈕圖示大小 - 22pt
        static let addButtonIconSize: CGFloat = 22
        
        /// 相簿圖示大小 - 22pt
        static let galleryIconSize: CGFloat = 22
        
        /// 關閉按鈕圖示大小 - 22pt
        static let closeButtonIconSize: CGFloat = 22
        
        // MARK: 通用圓角
        
        /// 預設圓角半徑 - 12pt
        static let cornerRadius: CGFloat = 12
        
        /// 小圓角半徑 - 8pt
        static let smallCornerRadius: CGFloat = 8
        
        /// 大圓角半徑 - 16pt
        static let largeCornerRadius: CGFloat = 16
        
        // MARK: - Responsive Layout System
        
        /// 響應式佈局系統（基於 UI 設計規範文檔 v1.0 第 5.5 節）
        enum ResponsiveLayout {
            
            /// 名片列表響應式規範
            enum CardList {
                /// Cell 高度比例（螢幕高度的 12%）
                static let cellHeightRatio: CGFloat = 0.12
                
                /// 圖片黃金比例（寬:高 = 1:0.618，即寬度 = 高度 × 1.618）
                static let imageAspectRatio: CGFloat = 0.618  // 高度相對於寬度的比例
                static let imageWidthToHeightRatio: CGFloat = 1.618  // 寬度相對於高度的比例（1 ÷ 0.618）
                
                /// 圖片與文字間距
                static let imageToTextSpacing: CGFloat = 12
                
                /// 文字行間距
                static let nameToCompanySpacing: CGFloat = 6
                static let companyToJobTitleSpacing: CGFloat = 4
                
                // MARK: - 響應式圖片占比優化
                
                /// 預設圖片區域占 Cell 內容寬度的比例
                static let defaultImageAreaWidthRatio: CGFloat = 0.45
                
                /// 根據螢幕尺寸獲取最佳圖片寬度占比
                static func getImageWidthRatio(for screenWidth: CGFloat) -> CGFloat {
                    switch screenWidth {
                    case 0..<375:     // 小螢幕 (iPhone SE, Mini)
                        return 0.42   // 42% - 給文字更多空間
                    case 375..<430:   // 標準螢幕 (iPhone 14, 15)
                        return 0.45   // 45% - 平衡占比
                    default:          // 大螢幕 (iPhone Pro Max)
                        return 0.48   // 48% - 圖片可以稍大
                    }
                }
                
                /// 計算當前螢幕的最佳 Cell 高度
                static func calculateCellHeight() -> CGFloat {
                    let screenHeight = UIScreen.main.bounds.height
                    return screenHeight * cellHeightRatio
                }
                
                /// 計算圖片尺寸（基於 Cell 內容高度）- 舊版方法，保持向後相容
                static func calculateImageSize(cellContentHeight: CGFloat) -> CGSize {
                    let imageHeight = cellContentHeight
                    let imageWidth = imageHeight * imageWidthToHeightRatio  // 寬度 = 高度 × 1.618
                    return CGSize(width: imageWidth, height: imageHeight)
                }
                
                /// 計算響應式優化的圖片尺寸（新版方法）
                /// 基於螢幕尺寸和 Cell 寬度，提供更好的名片顯示效果
                static func calculateResponsiveImageSize(
                    cellContentHeight: CGFloat,
                    cellContentWidth: CGFloat,
                    screenWidth: CGFloat
                ) -> CGSize {
                    // 根據螢幕尺寸獲取最佳圖片寬度占比
                    let widthRatio = getImageWidthRatio(for: screenWidth)
                    
                    // 計算目標圖片寬度
                    let targetImageWidth = cellContentWidth * widthRatio
                    
                    // 根據黃金比例計算對應的高度（寬:高 = 1:0.618）
                    let imageHeightFromWidth = targetImageWidth * imageAspectRatio
                    
                    // 確保不超過 Cell 高度（遵循設計規範）
                    let maxImageHeight = cellContentHeight
                    let finalImageHeight = min(imageHeightFromWidth, maxImageHeight)
                    
                    // 重新計算寬度，確保比例正確（寬度 = 高度 × 1.618）
                    let finalImageWidth = finalImageHeight * imageWidthToHeightRatio
                    
                    return CGSize(width: finalImageWidth, height: finalImageHeight)
                }
                
                /// 計算文字區域可用寬度
                static func calculateTextAreaWidth(
                    cellContentWidth: CGFloat,
                    imageWidth: CGFloat
                ) -> CGFloat {
                    return cellContentWidth - imageWidth - imageToTextSpacing
                }
            }
        }
    }
    
    // MARK: - Shadow
    
    /// 陰影系統
    enum Shadow {
        
        /// 陰影樣式
        struct ShadowStyle {
            let color: CGColor
            let opacity: Float
            let radius: CGFloat
            let offset: CGSize
        }
        
        /// 卡片陰影
        static let card = ShadowStyle(
            color: UIColor.black.withAlphaComponent(0.08).cgColor,
            opacity: 1.0,
            radius: 12,
            offset: CGSize(width: 0, height: 4)
        )
        
        /// 按鈕陰影（可選）
        static let button = ShadowStyle(
            color: UIColor.black.withAlphaComponent(0.15).cgColor,
            opacity: 1.0,
            radius: 4,
            offset: CGSize(width: 0, height: 2)
        )
        
        /// 浮動元件陰影
        static let floating = ShadowStyle(
            color: UIColor.black.withAlphaComponent(0.2).cgColor,
            opacity: 1.0,
            radius: 16,
            offset: CGSize(width: 0, height: 8)
        )
    }
    
    // MARK: - Animation
    
    /// 動畫系統
    enum Animation {
        
        // MARK: 時長定義
        
        /// 快速動畫 - 0.2s，用於按鈕按下、小型狀態變化
        static let fastDuration: TimeInterval = 0.2
        
        /// 標準動畫 - 0.3s，用於頁面轉場、內容切換
        static let standardDuration: TimeInterval = 0.3
        
        /// 緩慢動畫 - 0.5s，用於複雜動畫、首次載入
        static let slowDuration: TimeInterval = 0.5
        
        // MARK: 緩動函數
        
        /// 標準緩動曲線
        static let standardCurve = UIView.AnimationOptions.curveEaseInOut
        
        /// 彈性動畫參數
        static let springDamping: CGFloat = 0.8
        static let springVelocity: CGFloat = 0.5
        
        /// 線性動畫（進度條等）
        static let linearCurve = UIView.AnimationOptions.curveLinear
        
        // MARK: 常用動畫參數
        
        /// 按鈕按下縮放比例
        static let buttonPressScale: CGFloat = 0.95
        
        /// 按鈕按下透明度
        static let buttonPressAlpha: CGFloat = 0.8
        
        /// 頁面進入位移
        static let pageEnterTranslation: CGFloat = 20
        
        /// Toast 顯示時長
        static let toastDisplayDuration: TimeInterval = 2.0
        
        /// Toast 動畫縮放起始值
        static let toastStartScale: CGFloat = 0.8
        
        /// 載入動畫旋轉時長
        static let loadingRotationDuration: TimeInterval = 1.0
        
        /// 相機快門動畫時長
        static let shutterFlashDuration: TimeInterval = 0.2
    }
}

// MARK: - UIColor Extension

private extension UIColor {
    
    /// 從 Hex 字串建立 UIColor
    /// - Parameter hex: 顏色的十六進位字串（支援 #RRGGBB 格式）
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
