//
//  CoreDataStack.swift
//  BusinessCardScanner
//
//  Core Data 堆疊管理
//

import CoreData

/// Core Data 堆疊錯誤
enum CoreDataError: LocalizedError {
    case saveError(Error)
    case fetchError(Error)
    case deleteError(Error)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .saveError(let error):
            return "儲存失敗: \(error.localizedDescription)"
        case .fetchError(let error):
            return "讀取失敗: \(error.localizedDescription)"
        case .deleteError(let error):
            return "刪除失敗: \(error.localizedDescription)"
        case .notFound:
            return "找不到資料"
        }
    }
}

/// Core Data 堆疊管理器
final class CoreDataStack {
    
    // MARK: - Properties
    
    /// 模型名稱
    private let modelName: String
    
    /// Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // 在正式環境中應該要有更好的錯誤處理
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // 設定自動合併衝突
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
        
        return container
    }()
    
    /// 主要 Context (UI 用)
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    
    /// 初始化
    /// - Parameter modelName: Core Data 模型檔案名稱
    init(modelName: String = "BusinessCardScanner") {
        self.modelName = modelName
    }
    
    // MARK: - Core Data Operations
    
    /// 儲存 Context
    /// - Parameter context: 要儲存的 context
    func save(context: NSManagedObjectContext? = nil) throws {
        let contextToSave = context ?? mainContext
        
        guard contextToSave.hasChanges else { return }
        
        do {
            try contextToSave.save()
        } catch {
            throw CoreDataError.saveError(error)
        }
    }
    
    /// 建立背景 Context
    /// - Returns: 新的背景 context
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    /// 執行批次刪除
    /// - Parameter fetchRequest: 刪除請求
    func batchDelete<T: NSManagedObject>(_ fetchRequest: NSFetchRequest<T>) throws {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try mainContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
            
            let changes = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes,
                into: [mainContext]
            )
        } catch {
            throw CoreDataError.deleteError(error)
        }
    }
    
    /// 清除所有資料（危險操作）
    func clearAllData() throws {
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            guard let entityName = entity.name else { continue }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try mainContext.execute(deleteRequest)
            } catch {
                throw CoreDataError.deleteError(error)
            }
        }
        
        try save()
    }
    
    // MARK: - Helper Methods
    
    /// 在主線程執行
    /// - Parameter block: 要執行的程式碼
    func performOnMainContext(_ block: @escaping (NSManagedObjectContext) -> Void) {
        mainContext.perform {
            block(self.mainContext)
        }
    }
    
    /// 在背景執行
    /// - Parameter block: 要執行的程式碼
    func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}
