//
//  AISettingsViewModel.swift
//  
//
//  Created by 2025/6/25.
//

import Foundation
import Combine

/// API Key 驗證狀態
enum APIKeyValidationStatus {
    case notSet        // 未設定
    case invalid       // 格式無效
    case valid         // 格式正確
    case validating    // 驗證中
}

/// AI 設定頁面視圖模型
/// 負責 API Key 管理的業務邏輯
class AISettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentAPIKey: String? = nil
    @Published var validationStatus: APIKeyValidationStatus = .notSet
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private let openAIService: OpenAIService
    private var inputAPIKey: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Publishers
    
    private let errorMessageSubject = PassthroughSubject<String, Never>()
    private let successMessageSubject = PassthroughSubject<String, Never>()
    
    var errorMessagePublisher: AnyPublisher<String, Never> {
        errorMessageSubject.eraseToAnyPublisher()
    }
    
    var successMessagePublisher: AnyPublisher<String, Never> {
        successMessageSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 載入當前設定
    func loadCurrentSettings() {
        currentAPIKey = openAIService.getAPIKey()
        updateValidationStatus()
    }
    
    /// 更新 API Key 輸入
    /// - Parameter apiKey: 使用者輸入的 API Key
    func updateAPIKey(_ apiKey: String) {
        inputAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        updateValidationStatus()
    }
    
    /// 儲存 API Key
    func saveAPIKey() {
        guard !isLoading else { return }
        
        let trimmedKey = inputAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 驗證輸入
        guard !trimmedKey.isEmpty else {
            errorMessageSubject.send("請輸入 API Key")
            return
        }
        
        guard isValidAPIKeyFormat(trimmedKey) else {
            errorMessageSubject.send("API Key 格式錯誤，必須以 'sk-' 開頭且長度足夠")
            return
        }
        
        // 開始儲存流程
        isLoading = true
        validationStatus = .validating
        
        // 模擬網路驗證延遲
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.performSaveAPIKey(trimmedKey)
        }
    }
    
    /// 清除 API Key
    func clearAPIKey() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.openAIService.setAPIKey("")
            self.currentAPIKey = nil
            self.inputAPIKey = ""
            self.isLoading = false
            self.updateValidationStatus()
            
            self.successMessageSubject.send("API Key 已清除")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 監聽輸入變化，即時驗證格式
        $currentAPIKey
            .sink { [weak self] _ in
                self?.updateValidationStatus()
            }
            .store(in: &cancellables)
    }
    
    private func performSaveAPIKey(_ apiKey: String) {
        // 儲存到 Keychain
        openAIService.setAPIKey(apiKey)
        
        // 驗證儲存結果
        let savedKey = openAIService.getAPIKey()
        let isValid = openAIService.hasValidAPIKey()
        
        // 更新狀態
        currentAPIKey = savedKey
        isLoading = false
        
        if isValid && savedKey == apiKey {
            successMessageSubject.send("API Key 已成功儲存並驗證")
            updateValidationStatus()
        } else {
            errorMessageSubject.send("儲存失敗，請重試")
            validationStatus = .invalid
        }
    }
    
    private func updateValidationStatus() {
        let keyToValidate = inputAPIKey.isEmpty ? (currentAPIKey ?? "") : inputAPIKey
        
        if keyToValidate.isEmpty {
            validationStatus = .notSet
        } else if isValidAPIKeyFormat(keyToValidate) {
            validationStatus = .valid
        } else {
            validationStatus = .invalid
        }
    }
    
    private func isValidAPIKeyFormat(_ apiKey: String) -> Bool {
        // OpenAI API Key 格式驗證
        // 1. 必須以 'sk-' 開頭
        // 2. 長度至少 20 個字元
        // 3. 只包含字母、數字和某些特殊字符
        
        guard apiKey.hasPrefix("sk-") else { return false }
        guard apiKey.count >= 20 else { return false }
        
        // 簡單的字符驗證（A-Z, a-z, 0-9, -, _）
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        let keyCharacters = CharacterSet(charactersIn: apiKey)
        
        return allowedCharacters.isSuperset(of: keyCharacters)
    }
}

// MARK: - Helper Extensions

extension AISettingsViewModel {
    
    /// 取得當前 AI 服務可用狀態
    var isAIServiceAvailable: Bool {
        return openAIService.hasValidAPIKey()
    }
    
    /// 取得 API Key 顯示文字（隱藏部分字符）
    var maskedAPIKey: String? {
        guard let apiKey = currentAPIKey, !apiKey.isEmpty else { return nil }
        
        if apiKey.count <= 10 {
            return String(repeating: "*", count: apiKey.count)
        } else {
            let start = apiKey.prefix(6)
            let end = apiKey.suffix(4)
            let middle = String(repeating: "*", count: apiKey.count - 10)
            return "\(start)\(middle)\(end)"
        }
    }
}