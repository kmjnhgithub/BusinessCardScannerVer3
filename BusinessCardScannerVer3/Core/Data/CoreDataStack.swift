//
//  CoreDataStack.swift
//  BusinessCardScanner
//
//  Core Data 堆疊管理 - 調試版本
//

import CoreData
import Combine

/// Core Data 堆疊管理器
final class CoreDataStack {
    
    // MARK: - Properties
    
    /// Core Data 模型名稱
    private let modelName = "BusinessCardScanner"
    
    /// Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        
        #if DEBUG
        print("🔍 嘗試載入 Core Data Model: \(modelName)")
        
        // 列出所有可用的模型
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") {
            print("✅ 找到模型檔案: \(modelURL)")
        } else {
            print("❌ 找不到模型檔案: \(modelName).momd")
            
            // 嘗試列出所有 .momd 檔案
            if let urls = Bundle.main.urls(forResourcesWithExtension: "momd", subdirectory: nil) {
                print("📁 Bundle 中的所有 .momd 檔案:")
                for url in urls {
                    print("   - \(url.lastPathComponent)")
                }
            }
            
            // 嘗試列出所有 .xcdatamodeld 檔案
            if let urls = Bundle.main.urls(forResourcesWithExtension: "xcdatamodeld", subdirectory: nil) {
                print("📁 Bundle 中的所有 .xcdatamodeld 檔案:")
                for url in urls {
                    print("   - \(url.lastPathComponent)")
                }
            }
        }
        #endif
        
        let container = NSPersistentContainer(name: modelName)
        
        // 設定 Core Data 選項
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        #if DEBUG
        print("📍 Persistent Store 位置: \(description?.url?.absoluteString ?? "Unknown")")
        #endif
        
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                #if DEBUG
                print("❌ Core Data 載入失敗:")
                print("   錯誤: \(error)")
                print("   詳細: \(error.userInfo)")
                #endif
                // 在正式環境應該要有更好的錯誤處理
                self?.handleCoreDataError(error)
            } else {
                #if DEBUG
                print("✅ Core Data loaded successfully")
                print("📁 Store URL: \(storeDescription.url?.absoluteString ?? "Unknown")")
                #endif
            }
        }
        
        // 設定自動合併變更
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // MARK: - Contexts
    
    /// 主要 Context (UI 使用)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// 建立背景 Context (寫入操作使用)
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Core Data Operations
    
    /// 儲存 Context
    func save(context: NSManagedObjectContext) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            // 如果沒有變更，直接成功
            guard context.hasChanges else {
                promise(.success(()))
                return
            }
            
            context.perform {
                do {
                    try context.save()
                    promise(.success(()))
                } catch {
                    promise(.failure(CoreDataError.saveFailed(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 儲存主要 Context
    func saveViewContext() -> AnyPublisher<Void, Error> {
        save(context: viewContext)
    }
    
    /// 執行批次操作
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) -> AnyPublisher<T, Error> {
        Future<T, Error> { promise in
            self.persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Data Migration
    
    /// 檢查是否需要資料遷移
    private func checkForMigration() {
        // 預留給未來的資料遷移邏輯
        // 目前使用輕量級遷移（Lightweight Migration）
    }
    
    // MARK: - Error Handling
    
    /// 處理 Core Data 錯誤
    private func handleCoreDataError(_ error: NSError) {
        #if DEBUG
        print("❌ Core Data Error: \(error)")
        print("📝 User Info: \(error.userInfo)")
        #endif
        
        // 在開發階段，不要 fatalError，讓我們可以看到更多資訊
        #if DEBUG
        // 嘗試使用記憶體儲存作為備用方案
        print("⚠️ 嘗試使用記憶體儲存作為備用方案...")
        #else
        // 在正式環境中，這裡應該：
        // 1. 記錄錯誤到分析服務
        // 2. 嘗試恢復
        // 3. 最壞情況下重置資料庫
        fatalError("無法載入 Core Data: \(error), \(error.userInfo)")
        #endif
    }
    
    // MARK: - Maintenance
    
    /// 清除所有資料（危險操作）
    func clearAllData() -> AnyPublisher<Void, Error> {
        performBackgroundTask { context in
            // 取得所有實體名稱
            let entityNames = self.persistentContainer.managedObjectModel.entities.compactMap { $0.name }
            
            // 刪除每個實體的所有資料
            for entityName in entityNames {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                try context.execute(deleteRequest)
            }
            
            try context.save()
        }
    }
    
    /// 重置 Core Data Stack（開發用）
    func resetCoreDataStack() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            guard let storeURL = self.persistentContainer.persistentStoreDescriptions.first?.url else {
                promise(.failure(CoreDataError.storeNotFound))
                return
            }
            
            let coordinator = self.persistentContainer.persistentStoreCoordinator
            
            do {
                // 移除現有的 store
                if let store = coordinator.persistentStores.first {
                    try coordinator.remove(store)
                }
                
                // 刪除檔案
                try FileManager.default.removeItem(at: storeURL)
                
                // 重新載入
                self.persistentContainer.loadPersistentStores { _, error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// 印出 Core Data 統計資訊
    func printStatistics() {
        print("\n📊 Core Data Statistics:")
        
        // 檢查 persistentContainer 是否正確初始化
        guard persistentContainer.persistentStoreCoordinator.persistentStores.count > 0 else {
            print("   ❌ No persistent stores loaded")
            return
        }
        
        let context = viewContext
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        
        if entityNames.isEmpty {
            print("   ❌ No entities found in the model")
        } else {
            for entityName in entityNames {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                do {
                    let count = try context.count(for: request)
                    print("   \(entityName): \(count) records")
                } catch {
                    print("   \(entityName): Error counting - \(error)")
                }
            }
        }
        print("")
    }
    #endif
}

// MARK: - Core Data Errors

/// Core Data 相關錯誤
enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case storeNotFound
    case invalidEntity
    case migrationFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "儲存失敗: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "載入失敗: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "刪除失敗: \(error.localizedDescription)"
        case .storeNotFound:
            return "找不到資料儲存"
        case .invalidEntity:
            return "無效的資料實體"
        case .migrationFailed:
            return "資料遷移失敗"
        }
    }
}

// MARK: - NSManagedObjectContext Extension

extension NSManagedObjectContext {
    
    /// 安全地執行儲存操作
    func safeSave() throws {
        guard hasChanges else { return }
        
        do {
            try save()
        } catch {
            rollback()
            throw CoreDataError.saveFailed(error)
        }
    }
}
