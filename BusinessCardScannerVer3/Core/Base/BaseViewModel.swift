//
//  BaseViewModel.swift
//  
//
//  Base class for all ViewModels with Combine support
//

import Foundation
import Combine

/// 所有 ViewModel 的基礎類別
class BaseViewModel: ObservableObject {
    
    // MARK: - Properties
    
    /// Combine 訂閱集合
    var cancellables = Set<AnyCancellable>()
    
    /// 載入狀態
    @Published var isLoading = false
    
    /// 錯誤狀態
    @Published var error: Error?
    
    /// 是否有錯誤
    var hasError: Bool {
        error != nil
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    deinit {
        #if DEBUG
        print("✅ \(String(describing: type(of: self))) deinit")
        #endif
    }
    
    // MARK: - Setup (子類別覆寫)
    
    /// 設定資料綁定
    func setupBindings() {
        // 子類別覆寫此方法來設定 Combine 綁定
    }
    
    // MARK: - Loading State Management
    
    /// 開始載入
    func startLoading() {
        isLoading = true
        error = nil
    }
    
    /// 結束載入
    func stopLoading() {
        isLoading = false
    }
    
    /// 處理錯誤
    func handleError(_ error: Error) {
        self.error = error
        stopLoading()
    }
    
    /// 清除錯誤
    func clearError() {
        error = nil
    }
    
    // MARK: - Async Operation Helpers
    
    /// 執行非同步操作並處理載入狀態
    func performAsyncOperation<T>(
        operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        startLoading()
        
        Task { @MainActor in
            do {
                let result = try await operation()
                stopLoading()
                onSuccess(result)
            } catch {
                handleError(error)
                onError?(error)
            }
        }
    }
    
    /// 執行 Combine Publisher 並處理載入狀態
    func performPublisherOperation<T>(
        publisher: AnyPublisher<T, Error>,
        onSuccess: @escaping (T) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        startLoading()
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.stopLoading()
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                        onError?(error)
                    }
                },
                receiveValue: { value in
                    onSuccess(value)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Common Publishers

extension BaseViewModel {
    
    /// 載入狀態變更 Publisher
    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        $isLoading
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    /// 錯誤狀態變更 Publisher
    var errorPublisher: AnyPublisher<Error?, Never> {
        $error
            .eraseToAnyPublisher()
    }
    
    /// 有錯誤時發送 true 的 Publisher
    var hasErrorPublisher: AnyPublisher<Bool, Never> {
        $error
            .map { $0 != nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

