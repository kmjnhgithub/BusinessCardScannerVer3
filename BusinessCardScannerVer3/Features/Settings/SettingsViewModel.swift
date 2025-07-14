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
    case cardListAnimation // 名片列表動畫
    case exportData        // 匯出資料
    case clearData         // 清除資料
    case about             // 關於我們
    
    var title: String {
        switch self {
        case .cardListAnimation: return "名片列表動畫"
        case .exportData: return "匯出資料"
        case .clearData: return "清除所有資料"
        case .about: return "關於我們"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .cardListAnimation: return "進入名片列表時的依序浮現動畫"
        case .exportData: return "匯出為 CSV 或 VCF 格式"
        case .clearData: return "刪除所有已儲存的名片資料"
        case .about: return "版本資訊和開發者資料"
        }
    }
    
    var icon: String {
        switch self {
        case .cardListAnimation: return "sparkles"
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
class SettingsViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var isAIEnabled: Bool = false
    @Published var aiStatusText: String = "未設定"
    @Published var totalCardsCount: Int = 0
    @Published var isCardListAnimationEnabled: Bool = false
    // 移除: @Published var isLoading (使用繼承的)
    
    // MARK: - Private Properties
    
    private let repository: BusinessCardRepository
    private let exportService: ExportService
    private let aiProcessingModule: AIProcessingModulable?
    private let animationPreferences: AnimationPreferences
    // 移除: private var cancellables (使用繼承的)
    
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
        aiProcessingModule: AIProcessingModulable?,
        animationPreferences: AnimationPreferences = AnimationPreferences.shared
    ) {
        self.repository = repository
        self.exportService = exportService
        self.aiProcessingModule = aiProcessingModule
        self.animationPreferences = animationPreferences
        
        super.init()  // 自動呼叫 override setupBindings()
        // 移除: setupBindings()  ← 刪除重複呼叫
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 載入初始資料
    func loadInitialData() {
        loadAIConfiguration()
        loadCardsCount()
        loadAnimationConfiguration()
    }
    
    /// 處理設定項目點擊
    /// - Parameter item: 設定項目類型
    func handleSettingItemTap(_ item: SettingItemType) {
        switch item {
        case .cardListAnimation:
            alertSubject.send(.toggleCardListAnimation)
            
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
    
    /// 切換名片列表動畫開關
    func toggleCardListAnimation() {
        let newValue = !isCardListAnimationEnabled
        animationPreferences.toggleCardListAnimation(newValue)
        
        let message = newValue ? "名片列表動畫已啟用" : "名片列表動畫已停用"
        toastSubject.send(message)
    }
    
    /// 確認清除所有資料
    func confirmClearAllData() {
        isLoading = true
        
        // 真正刪除所有資料 - 遵循 MVVM+C 架構的單一職責原則
        repository.deleteAll()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch completion {
                    case .finished:
                        // 刪除成功，重新載入統計資料
                        self.totalCardsCount = 0
                        self.toastSubject.send("所有資料已清除")
                        
                        // 發送全域通知，讓其他 ViewModel 知道資料已清空
                        NotificationCenter.default.post(
                            name: .businessCardDataDidClear,
                            object: nil
                        )
                        
                    case .failure(let error):
                        // 刪除失敗，顯示錯誤訊息
                        print("⚠️ SettingsViewModel: 清除資料失敗 - \(error)")
                        self.toastSubject.send("清除失敗，請重試")
                    }
                },
                receiveValue: { _ in
                    // deleteAll() 返回 Void，這裡不需要處理
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    override func setupBindings() {
        // 監聽動畫偏好設定變化
        animationPreferences.$isCardListAnimationEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: &$isCardListAnimationEnabled)
    }
    
    private func loadAIConfiguration() {
        isAIEnabled = UserDefaults.standard.bool(forKey: "aiProcessingEnabled")
        updateAIStatusText()
    }
    
    private func loadAnimationConfiguration() {
        isCardListAnimationEnabled = animationPreferences.isCardListAnimationEnabled
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
        
        // 從 repository 取得所有名片資料
        repository.fetchAll()
            .mapError { _ in ExportError.createFileFailed }
            .flatMap { [weak self] cards -> AnyPublisher<URL, ExportError> in
                guard let self = self else {
                    return Fail(error: ExportError.createFileFailed)
                        .eraseToAnyPublisher()
                }
                
                return self.exportService.exportAsCSV(cards: cards)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.toastSubject.send("匯出失敗：\(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] fileURL in
                    guard let self = self else { return }
                    
                    self.toastSubject.send("CSV 檔案匯出成功")
                    
                    // 觸發分享功能
                    self.shareExportedFile(fileURL)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 匯出為 VCF 格式
    func exportAsVCF() {
        isLoading = true
        
        // 從 repository 取得所有名片資料
        repository.fetchAll()
            .mapError { _ in ExportError.createFileFailed }
            .flatMap { [weak self] cards -> AnyPublisher<URL, ExportError> in
                guard let self = self else {
                    return Fail(error: ExportError.createFileFailed)
                        .eraseToAnyPublisher()
                }
                
                return self.exportService.exportAsVCard(cards: cards)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.toastSubject.send("匯出失敗：\(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] fileURL in
                    guard let self = self else { return }
                    
                    self.toastSubject.send("VCF 檔案匯出成功")
                    
                    // 觸發分享功能
                    self.shareExportedFile(fileURL)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 分享匯出的檔案
    /// - Parameter fileURL: 檔案 URL
    private func shareExportedFile(_ fileURL: URL) {
        navigationSubject.send(.shareFile(fileURL))
    }
}

// MARK: - Supporting Types

/// 設定頁面導航動作
enum SettingsNavigationAction {
    case aiSettings
    case shareFile(URL)
}

/// 設定頁面警告類型
enum SettingsAlertType {
    case toggleCardListAnimation
    case confirmClearData
    case noDataToExport
    case selectExportFormat
    case showAbout
}

// MARK: - Helper Extensions

extension SettingsViewModel {
    
    /// 取得所有設定項目
    var settingItems: [SettingItemType] {
        return [.cardListAnimation, .exportData, .clearData, .about]
    }
    
    /// 取得應用程式版本資訊
    var appVersionInfo: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "版本 \(version) (\(build))"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// 名片資料已清空的通知
    static let businessCardDataDidClear = Notification.Name("businessCardDataDidClear")
}