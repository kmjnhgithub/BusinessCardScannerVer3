//
//  SettingsViewModel.swift
//  BusinessCardScannerVer3
//
//  設定頁面視圖模型
//  位置：Features/Settings/SettingsViewModel.swift
//

import Foundation
import Combine

/// 設定項目類型
enum SettingItemType {
    case aiConfiguration    // AI 功能設定
    case exportData        // 匯出資料
    case clearData         // 清除資料
    case about             // 關於我們
    
    var title: String {
        switch self {
        case .aiConfiguration: return "AI 智慧解析"
        case .exportData: return "匯出資料"
        case .clearData: return "清除所有資料"
        case .about: return "關於我們"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .aiConfiguration: return "使用 OpenAI 提升名片解析準確度"
        case .exportData: return "匯出為 CSV 或 VCF 格式"
        case .clearData: return "刪除所有已儲存的名片資料"
        case .about: return "版本資訊和開發者資料"
        }
    }
    
    var icon: String {
        switch self {
        case .aiConfiguration: return "brain.head.profile"
        case .exportData: return "square.and.arrow.up"
        case .clearData: return "trash"
        case .about: return "info.circle"
        }
    }
    
    var isDestructive: Bool {
        switch self {
        case .clearData: return true
        default: return false
        }
    }
}

/// 設定頁面視圖模型
/// 負責設定頁面的業務邏輯和狀態管理
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAIEnabled: Bool = false
    @Published var aiStatusText: String = "未設定"
    @Published var totalCardsCount: Int = 0
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private let repository: BusinessCardRepository
    private let exportService: ExportService
    private let aiProcessingModule: AIProcessingModulable?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Publishers
    
    private let navigationSubject = PassthroughSubject<SettingsNavigationAction, Never>()
    private let alertSubject = PassthroughSubject<SettingsAlertType, Never>()
    private let toastSubject = PassthroughSubject<String, Never>()
    
    var navigationPublisher: AnyPublisher<SettingsNavigationAction, Never> {
        navigationSubject.eraseToAnyPublisher()
    }
    
    var alertPublisher: AnyPublisher<SettingsAlertType, Never> {
        alertSubject.eraseToAnyPublisher()
    }
    
    var toastPublisher: AnyPublisher<String, Never> {
        toastSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(
        repository: BusinessCardRepository,
        exportService: ExportService,
        aiProcessingModule: AIProcessingModulable?
    ) {
        self.repository = repository
        self.exportService = exportService
        self.aiProcessingModule = aiProcessingModule
        
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 載入初始資料
    func loadInitialData() {
        loadAIConfiguration()
        loadCardsCount()
    }
    
    /// 處理設定項目點擊
    /// - Parameter item: 設定項目類型
    func handleSettingItemTap(_ item: SettingItemType) {
        switch item {
        case .aiConfiguration:
            navigationSubject.send(.aiSettings)
            
        case .exportData:
            handleExportData()
            
        case .clearData:
            alertSubject.send(.confirmClearData)
            
        case .about:
            alertSubject.send(.showAbout)
        }
    }
    
    /// 切換 AI 功能開關
    /// - Parameter enabled: 是否啟用
    func toggleAI(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "aiProcessingEnabled")
        isAIEnabled = enabled
        updateAIStatusText()
        
        let message = enabled ? "AI 智慧解析已啟用" : "AI 智慧解析已停用"
        toastSubject.send(message)
    }
    
    /// 確認清除所有資料
    func confirmClearAllData() {
        isLoading = true
        
        // 模擬清除操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // 實際實作會呼叫 repository.deleteAllCards()
            self.totalCardsCount = 0
            self.isLoading = false
            self.toastSubject.send("所有資料已清除")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 初始設定時不需要持續監聽，只在需要時更新
        // 如果需要即時更新，可以設置定時器或通知機制
    }
    
    private func loadAIConfiguration() {
        isAIEnabled = UserDefaults.standard.bool(forKey: "aiProcessingEnabled")
        updateAIStatusText()
    }
    
    private func loadCardsCount() {
        repository.fetchAll()
            .map { $0.count }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("⚠️ SettingsViewModel: 載入名片數量失敗 - \(error)")
                    }
                },
                receiveValue: { [weak self] count in
                    self?.totalCardsCount = count
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateAIStatusText() {
        if !isAIEnabled {
            aiStatusText = "已停用"
        } else if let aiModule = aiProcessingModule, aiModule.isAvailable {
            aiStatusText = "已啟用"
        } else {
            aiStatusText = "需要設定 API Key"
        }
    }
    
    private func handleExportData() {
        guard totalCardsCount > 0 else {
            alertSubject.send(.noDataToExport)
            return
        }
        
        alertSubject.send(.selectExportFormat)
    }
    
    /// 匯出為 CSV 格式
    func exportAsCSV() {
        isLoading = true
        
        // 模擬匯出操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.toastSubject.send("CSV 檔案匯出成功")
            // 實際實作會呼叫 exportService.exportAsCSV()
        }
    }
    
    /// 匯出為 VCF 格式
    func exportAsVCF() {
        isLoading = true
        
        // 模擬匯出操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.toastSubject.send("VCF 檔案匯出成功")
            // 實際實作會呼叫 exportService.exportAsVCF()
        }
    }
}

// MARK: - Supporting Types

/// 設定頁面導航動作
enum SettingsNavigationAction {
    case aiSettings
}

/// 設定頁面警告類型
enum SettingsAlertType {
    case confirmClearData
    case noDataToExport
    case selectExportFormat
    case showAbout
}

// MARK: - Helper Extensions

extension SettingsViewModel {
    
    /// 取得所有設定項目
    var settingItems: [SettingItemType] {
        return [.aiConfiguration, .exportData, .clearData, .about]
    }
    
    /// 取得應用程式版本資訊
    var appVersionInfo: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "版本 \(version) (\(build))"
    }
}