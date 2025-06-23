//
//  ServiceContainer.swift
//  BusinessCardScanner
//
//  服務容器，管理所有服務實例
//

import Foundation

/// 服務生命週期
enum ServiceLifetime {
    case singleton    // 單例，整個應用程式生命週期只有一個實例
    case transient    // 瞬時，每次請求都創建新實例
}

/// 服務容器
final class ServiceContainer {
    
    // MARK: - Singleton
    
    static let shared = ServiceContainer()
    
    // MARK: - Properties
    
    /// 服務註冊表
    private var services: [String: ServiceEntry] = [:]
    
    /// 單例實例快取
    private var singletons: [String: Any] = [:]
    
    /// 執行緒鎖
    private let lock = NSLock()
    
    // MARK: - Private Init
    
    private init() {}
    
    // MARK: - Service Registration
    
    /// 註冊服務
    /// - Parameters:
    ///   - type: 服務協議類型
    ///   - lifetime: 生命週期
    ///   - factory: 服務工廠閉包
    func register<T>(
        _ type: T.Type,
        lifetime: ServiceLifetime = .singleton,
        factory: @escaping (ServiceContainer) -> T
    ) {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        services[key] = ServiceEntry(
            lifetime: lifetime,
            factory: { container in
                factory(container)
            }
        )
    }
    
    /// 註冊服務（帶名稱）
    /// - Parameters:
    ///   - type: 服務協議類型
    ///   - name: 服務名稱
    ///   - lifetime: 生命週期
    ///   - factory: 服務工廠閉包
    func register<T>(
        _ type: T.Type,
        name: String,
        lifetime: ServiceLifetime = .singleton,
        factory: @escaping (ServiceContainer) -> T
    ) {
        let key = "\(String(describing: type))_\(name)"
        
        lock.lock()
        defer { lock.unlock() }
        
        services[key] = ServiceEntry(
            lifetime: lifetime,
            factory: { container in
                factory(container)
            }
        )
    }
    
    // MARK: - Service Resolution
    
    /// 解析服務
    /// - Parameter type: 服務協議類型
    /// - Returns: 服務實例
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        guard let entry = services[key] else {
            fatalError("Service of type \(type) is not registered")
        }
        
        return resolveService(key: key, entry: entry) as! T
    }
    
    /// 解析服務（帶名稱）
    /// - Parameters:
    ///   - type: 服務協議類型
    ///   - name: 服務名稱
    /// - Returns: 服務實例
    func resolve<T>(_ type: T.Type, name: String) -> T {
        let key = "\(String(describing: type))_\(name)"
        
        lock.lock()
        defer { lock.unlock() }
        
        guard let entry = services[key] else {
            fatalError("Service of type \(type) with name '\(name)' is not registered")
        }
        
        return resolveService(key: key, entry: entry) as! T
    }
    
    /// 解析服務（可選）
    /// - Parameter type: 服務協議類型
    /// - Returns: 服務實例或 nil
    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        guard let entry = services[key] else {
            return nil
        }
        
        return resolveService(key: key, entry: entry) as? T
    }
    
    // MARK: - Private Methods
    
    /// 解析服務實例
    private func resolveService(key: String, entry: ServiceEntry) -> Any {
        switch entry.lifetime {
        case .singleton:
            if let instance = singletons[key] {
                return instance
            }
            let instance = entry.factory(self)
            singletons[key] = instance
            return instance
            
        case .transient:
            return entry.factory(self)
        }
    }
    
    /// 清除所有服務
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        services.removeAll()
        singletons.removeAll()
    }
    
    /// 清除單例快取
    func resetSingletons() {
        lock.lock()
        defer { lock.unlock() }
        
        singletons.removeAll()
    }
}

// MARK: - Service Entry

/// 服務項目
private struct ServiceEntry {
    let lifetime: ServiceLifetime
    let factory: (ServiceContainer) -> Any
}

// MARK: - Convenience Methods

extension ServiceContainer {
    
    /// 註冊單例服務的便利方法
    func registerSingleton<T>(_ type: T.Type, instance: T) {
        register(type, lifetime: .singleton) { _ in instance }
    }
    
    /// 批量註冊服務
    func registerServices(_ registrations: [(ServiceContainer) -> Void]) {
        registrations.forEach { $0(self) }
    }
}

// MARK: - App Service Registration

extension ServiceContainer {
    
    /// 註冊所有應用程式服務
    /// 這個方法會在 App 啟動時被呼叫
    static func registerAppServices() {
        let container = ServiceContainer.shared
        
        // 註冊服務時使用 Mock 實作，之後會替換為真實實作
        
        // Core Services - 將在 Task 1.4 後實作
        // container.register(CoreDataStack.self) { _ in CoreDataStack() }
        // container.register(BusinessCardRepository.self) { container in
        //     BusinessCardRepositoryImpl(coreDataStack: container.resolve(CoreDataStack.self))
        // }
        
        // Technical Services - 將在各個 Phase 實作
        // container.register(PhotoService.self) { _ in PhotoServiceImpl() }
        // container.register(VisionService.self) { _ in VisionServiceImpl() }
        // container.register(PermissionManager.self) { _ in PermissionManagerImpl() }
        // container.register(KeychainService.self) { _ in KeychainServiceImpl() }
        // container.register(ExportService.self) { _ in ExportServiceImpl() }
    }
}
