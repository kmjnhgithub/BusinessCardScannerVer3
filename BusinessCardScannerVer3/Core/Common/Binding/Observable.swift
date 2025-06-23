//
//  Observable.swift
//  BusinessCardScanner
//
//  資料綁定機制，實現 MVVM 的核心元件
//

import Foundation

/// 可觀察的值包裝器
final class Observable<T> {
    
    // MARK: - Typealias
    
    typealias Observer = (T) -> Void
    
    // MARK: - Properties
    
    /// 當前值
    var value: T {
        didSet {
            notifyObservers()
        }
    }
    
    /// 觀察者列表
    private var observers: [(id: UUID, observer: Observer)] = []
    
    /// 執行緒鎖，確保執行緒安全
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    /// 初始化
    /// - Parameter value: 初始值
    init(_ value: T) {
        self.value = value
    }
    
    // MARK: - Observer Management
    
    /// 綁定觀察者
    /// - Parameters:
    ///   - observer: 觀察者閉包
    ///   - fireImmediately: 是否立即觸發一次
    /// - Returns: Disposable 物件，用於取消訂閱
    @discardableResult
    func bind(_ observer: @escaping Observer, fireImmediately: Bool = true) -> Disposable {
        lock.lock()
        defer { lock.unlock() }
        
        let id = UUID()
        observers.append((id: id, observer: observer))
        
        // 如果需要立即觸發
        if fireImmediately {
            observer(value)
        }
        
        // 返回 Disposable
        return Disposable { [weak self] in
            self?.removeObserver(id: id)
        }
    }
    
    /// 綁定到另一個 Observable
    /// - Parameter observable: 目標 Observable
    /// - Returns: Disposable 物件
    @discardableResult
    func bind(to observable: Observable<T>) -> Disposable {
        return bind { value in
            observable.value = value
        }
    }
    
    /// 映射到另一種類型
    /// - Parameter transform: 轉換函數
    /// - Returns: 新的 Observable
    func map<U>(_ transform: @escaping (T) -> U) -> Observable<U> {
        let mapped = Observable<U>(transform(value))
        
        bind { value in
            mapped.value = transform(value)
        }
        
        return mapped
    }
    
    /// 過濾值
    /// - Parameter predicate: 過濾條件
    /// - Returns: 新的 Observable（Optional）
    func filter(_ predicate: @escaping (T) -> Bool) -> Observable<T?> {
        let filtered = Observable<T?>(predicate(value) ? value : nil)
        
        bind { value in
            filtered.value = predicate(value) ? value : nil
        }
        
        return filtered
    }
    
    // MARK: - Private Methods
    
    /// 通知所有觀察者
    private func notifyObservers() {
        lock.lock()
        let observersCopy = observers
        lock.unlock()
        
        observersCopy.forEach { $0.observer(value) }
    }
    
    /// 移除觀察者
    /// - Parameter id: 觀察者 ID
    private func removeObserver(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        
        observers.removeAll { $0.id == id }
    }
    
    // MARK: - Deinit
    
    deinit {
        observers.removeAll()
    }
}
