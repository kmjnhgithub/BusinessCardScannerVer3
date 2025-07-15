# 名片掃描器 Business Card Scanner

展示 iOS 開發技術應用程式，透過實用的名片管理功能展現 **MVVM+Coordinator**、**Combine** 和 **AI 驅動 OCR** 處理技術。

## 專案概述

透過實現真實商業解決方案來展示 iOS 開發專業能力：將名片數位化並使用 AI 增強準確度進行管理。

![CreateCardsDemo](https://github.com/user-attachments/assets/aaf04308-3583-4834-91c7-b1f0047c7f68)

### 專案數據
- **架構模式**: MVVM + Coordinator + Combine
- **UI 實作**: 100% 程式化 UI（無 Storyboard）
- **外部依賴**: 僅一個外部依賴（SnapKit）
- **支援平台**: iOS 15.0+, Swift 5.9+
- **AI 整合**: OpenAI API 智慧解析

## 技術點

### 1. **現代化架構設計**
- **MVVM+Coordinator 模式**: 清晰的關注點分離，導航邏輯獨立於協調器中
- **Combine 框架**: 使用 Apple 原生框架實現響應式資料綁定
- **依賴注入**: ServiceContainer + ModuleFactory 實現可測試的模組化程式碼
- **BaseViewModel 繼承模式**: 統一的 ViewModel 基礎架構，提供一致的狀態管理

### 2. **AI 驅動智慧解析**
```swift
// 雙引擎架構：本地 OCR + 雲端 AI
OCR (Vision) → AI Parser (OpenAI) → 結構化資料
             ↓ (降級機制)
         Local Parser → 基礎資料
```
- **智慧欄位識別**: AI 理解語境而非僅識別文字模式
- **優雅降級**: AI 不可用時自動降級到本地解析
- **安全 API 管理**: 使用 Keychain 儲存敏感憑證

### 3. **降低第三方依賴**
- **最小依賴**: 僅使用 SnapKit 作為 Auto Layout DSL
- **原生框架**: Combine、Vision、AVFoundation、Core Data
- **無第三方膨脹**: 驗證、網路、持久化全部使用原生處理

### 4. **生產級功能**
- **健全的權限處理**: 相機和照片庫具備完整錯誤狀態處理
- **智慧圖片管線**: 名片邊界偵測、透視校正、自動壓縮、縮圖生成
- **離線能力**: 無網路下完整功能（AI 為可選功能）
- **資料匯出**: CSV 和 vCard 格式，適合商業整合

## 架構設計

### 模組結構
```
Features/
├── CardList/          # 名片列表管理與搜尋
├── CardCreation/      # 相機/照片/手動輸入流程  
├── AIProcessing/      # OpenAI 整合（可插拔）
├── Settings/          # 設定與匯出功能
└── TabBar/           # 主要導航

Core/
├── Base/             # MVVM 基礎類別
├── DI/               # 依賴注入
├── Services/         # 技術服務層
├── Models/           # 資料層
└── Common/UI/        # 可重用元件
```

### 關鍵設計模式

#### BaseViewModel 繼承架構
```swift
class BaseViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    var cancellables = Set<AnyCancellable>()
    
    func setupBindings() { /* 子類別覆寫 */ }
}

// 所有 ViewModel 繼承統一基礎功能
```

#### 模組化設計
```swift
protocol CardListModulable {
    func makeCoordinator(navigationController: UINavigationController) -> Coordinator
}

// 每個功能都是自包含且可替換的
```

## 技術實作

### 核心技術
- **OCR 引擎**: Vision Framework 文字識別
- **AI 處理**: OpenAI GPT 智慧解析
- **資料持久化**: Core Data 自動遷移
- **圖片儲存**: 檔案系統儲存 + NSCache 記憶體快取
- **安全性**: Keychain Services API 金鑰管理

### 效能優化
- **圖片快取系統**: NSCache 記憶體快取 + 縮圖生成，限制 50MB 記憶體使用
- **搜尋防抖機制**: 300ms debounce 避免頻繁查詢
- **智慧圖片處理**: 自動壓縮至 1024px，JPEG 0.8 壓縮率
- **Core Data 優化**: 背景執行緒處理資料庫操作，主線程更新 UI

## 功能特色

### 名片掃描
- **多種輸入方式**: 相機、照片庫、手動輸入
- **智慧偵測與裁切**: Vision Framework 自動偵測名片邊界並透視校正
- **多語言 OCR**: 支援英文、中文及混合文字識別

### AI 增強
- **語境理解**: AI 區分相似欄位的語義差異
- **格式標準化**: 統一電話/郵件格式
- **信心評分**: 解析準確度透明化

### 資料管理
- **完整 CRUD 操作**: 建立、讀取、更新、刪除
- **進階搜尋**: 跨所有欄位搜尋
- **批次操作**: 匯出和批量管理
- **安全儲存**: 沙盒化資料保護

## 🔧 安裝與設定

### 系統需求
- Xcode 15.0+
- iOS 15.0+ 部署目標
- Swift 5.9+

### 設定
1. **API 金鑰設定**（AI 功能可選）:
   ```swift
   // 建立 APIKeys.swift（已在 .gitignore 中）
   struct APIKeys {
       static let openAI = "your-api-key-here"
   }
   ```


## UI/UX 設計

### 設計理念
- **商務專業風格**: 簡潔、極簡的介面
- **效率優先**: 核心操作 3 次點擊內可達成
- **一致體驗**: 全應用統一設計語言

### 自訂元件
- **主題化 UI 系統**: AppTheme 集中樣式管理
- **可重用元件**: 表單欄位、卡片、按鈕
- **響應式佈局**: 適應所有 iPhone 尺寸

## 程式碼品質

### 架構優勢
- **可測試性**: DI 和模組化設計實現單元測試
- **可維護性**: 清晰的模組邊界與一致的 BaseViewModel 模式
- **可擴展性**: 易於新增功能模組
- **AI 協作友好**: 清晰結構適合 AI 輔助開發

### 當前架構特色與未來規劃
- **BaseViewModel 繼承模式**: 目前採用繼承方式，學習曲線低且功能完整
- **已知技術債**: CameraViewModel 因 AVCapturePhotoCaptureDelegate 限制無法繼承 BaseViewModel
- **未來重構目標**: Protocol-Oriented Programming 以解決單一繼承限制
- **測試策略**: 由於相機/OCR 特性，採用手動測試方法

### 效能優化方向
1. **背景處理優化** - 進一步提升
   - Core Data 操作已在背景執行
   - OCR 處理和圖片壓縮可移至背景執行緒
   - 提升 UI 響應性，特別是處理大圖時

2. **資料庫索引優化** - 擴展查詢效能
   - 目前查詢效能適合中小型資料集
   - 可添加複合索引優化多欄位搜尋
   - 為常用查詢路徑建立專用索引

3. **分頁載入機制** - 支援大型資料集
   - 當前一次載入適合大多數使用場景
   - 實作懶載入支援數千筆名片
   - 添加無限滾動和預載入機制

## 🚦 為什麼選擇這個架構？

### 技術決策
1. **UIKit 而非 SwiftUI**: 展示對成熟技術的掌握
2. **Combine 而非 RxSwift**: 原生解決方案，無外部依賴
3. **Coordinator 模式**: 優雅解決巨大 ViewController 問題
4. **手動測試**: 相機/OCR 功能需要實機測試

### 商業價值
- **可維護**: 新開發者能快速理解
- **可擴展**: 易於新增匯出格式、雲端同步等
- **可靠**: 每個層級都有優雅降級
- **高效能**: 針對實際使用場景優化

## 📊 專案指標

```
Swift 檔案: 76
架構模式: MVVM+C
外部依賴: 1 個 (SnapKit)
程式碼覆蓋: 手動測試
最低 iOS: 15.0
Swift 版本: 5.9
```

## 協作設計

此專案設計適合團隊協作：
- **清晰模組邊界** 支援平行開發
- **完整文檔** 詳見 CLAUDE.md
- **一致模式** 貫穿整個程式碼庫
- **AI 友好結構** 適合工具輔助開發

## 授權

此為作品展示專案，僅供展示用途。

---

**說明**: 此專案代表我對 iOS 架構與乾淨程式碼的方法以及與AI協作的成果。這是我如何架構生產應用程式的實際展示，平衡實用主義與最佳實踐。
