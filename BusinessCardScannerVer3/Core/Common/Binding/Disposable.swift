//
//  Disposable.swift
//  BusinessCardScanner
//
//  資源管理物件，用於取消訂閱和清理資源
//

import Foundation

/// Disposable 協議
protocol DisposableProtocol {
    /// 釋放資源
    func dispose()
}

/// Disposable 實作
final class Disposable: DisposableProtocol {
    
    // MARK: - Properties
    
    /// 清理動作
    private var disposeAction: (() -> Void)?
    
    /// 是否已經釋放
    private var isDisposed = false
    
    /// 執行緒鎖
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    /// 初始化
    /// - Parameter action: 清理動作
    init(_ action: @escaping () -> Void) {
        self.disposeAction = action
    }
    
    // MARK: - DisposableProtocol
    
    /// 釋放資源
    func dispose() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isDisposed else { return }
        
        isDisposed = true
        disposeAction?()
        disposeAction = nil
    }
    
    // MARK: - Deinit
    
    deinit {
        dispose()
    }
}

/// Disposable 集合，用於批量管理
final class DisposeBag {
    
    // MARK: - Properties
    
    /// Disposable 列表
    private var disposables: [DisposableProtocol] = []
    
    /// 執行緒鎖
    private let lock = NSLock()
    
    // MARK: - Public Methods
    
    /// 添加 Disposable
    /// - Parameter disposable: 要管理的 Disposable
    func add(_ disposable: DisposableProtocol) {
        lock.lock()
        defer { lock.unlock() }
        
        disposables.append(disposable)
    }
    
    /// 釋放所有資源
    func dispose() {
        lock.lock()
        let disposablesToDispose = disposables
        disposables.removeAll()
        lock.unlock()
        
        disposablesToDispose.forEach { $0.dispose() }
    }
    
    // MARK: - Deinit
    
    deinit {
        dispose()
    }
}

// MARK: - Disposable Extension

extension DisposableProtocol {
    /// 將 Disposable 加入到 DisposeBag
    /// - Parameter bag: 目標 DisposeBag
    func disposed(by bag: DisposeBag) {
        bag.add(self)
    }
}
