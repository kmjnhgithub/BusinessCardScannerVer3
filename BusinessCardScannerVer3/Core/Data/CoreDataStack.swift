//
//  CoreDataStack.swift
//  BusinessCardScanner
//
//  Core Data 堆疊管理
//

import CoreData


class CoreDataStack {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BusinessCardScanner")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // 正式環境應該要有更好的錯誤處理
                fatalError("無法載入 Core Data: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    // MARK: - Core Data Context
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}
