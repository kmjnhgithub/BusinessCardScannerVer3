//
//  BaseViewModel.swift
//  BusinessCardScanner
//
//  基礎 ViewModel，提供所有 ViewModel 共用功能
//

import Foundation

class BaseViewModel {
    
    // MARK: - Properties
    
    /// Loading 狀態
    let isLoading = Observable<Bool>(false)
    
    /// 錯誤訊息
    let errorMessage = Observable<String?>(nil)
    
    /// 成功訊息
    let successMessage = Observable<String?>(nil)
    
    /// Disposable 容器，用於管理訂閱
    private var disposables: [Disposable] = []
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    /// 設定內部綁定
    /// 子類別可覆寫此方法來設定自己的綁定
    func setupBindings() {
        // 子類別實作
    }
    
    // MARK: - Loading Management
    
    /// 開始 Loading
    func startLoading() {
        isLoading.value = true
    }
    
    /// 結束 Loading
    func stopLoading() {
        isLoading.value = false
    }
    
    // MARK: - Error Handling
    
    /// 處理錯誤
    /// - Parameter error: 錯誤物件
    func handleError(_ error: Error) {
        stopLoading()
        
        // 根據錯誤類型提供適當的錯誤訊息
        if let localizedError = error as? LocalizedError {
            errorMessage.value = localizedError.errorDescription ?? error.localizedDescription
        } else {
            errorMessage.value = error.localizedDescription
        }
    }
    
    /// 顯示錯誤訊息
    /// - Parameter message: 錯誤訊息
    func showError(_ message: String) {
        stopLoading()
        errorMessage.value = message
    }
    
    /// 顯示成功訊息
    /// - Parameter message: 成功訊息
    func showSuccess(_ message: String) {
        stopLoading()
        successMessage.value = message
    }
    
    /// 清除所有訊息
    func clearMessages() {
        errorMessage.value = nil
        successMessage.value = nil
    }
    
    // MARK: - Disposable Management
    
    /// 添加 Disposable
    /// - Parameter disposable: 要管理的 Disposable
    func addDisposable(_ disposable: Disposable) {
        disposables.append(disposable)
    }
    
    /// 清理所有 Disposables
    private func disposeAll() {
        disposables.forEach { $0.dispose() }
        disposables.removeAll()
    }
    
    // MARK: - Validation
    
    /// 驗證 Email 格式
    /// - Parameter email: 要驗證的 email
    /// - Returns: 是否為有效格式
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// 驗證電話號碼格式
    /// - Parameter phone: 要驗證的電話號碼
    /// - Returns: 是否為有效格式
    func isValidPhone(_ phone: String) -> Bool {
        // 移除所有非數字字元
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // 台灣手機號碼：09 開頭，共 10 碼
        // 台灣市話：區碼 + 號碼，總長度 9-10 碼
        return digitsOnly.count >= 9 && digitsOnly.count <= 10
    }
    
    /// 驗證網址格式
    /// - Parameter urlString: 要驗證的網址
    /// - Returns: 是否為有效格式
    func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    // MARK: - Deinit
    
    deinit {
        disposeAll()
        print("\(String(describing: self)) deinit")
    }
}
