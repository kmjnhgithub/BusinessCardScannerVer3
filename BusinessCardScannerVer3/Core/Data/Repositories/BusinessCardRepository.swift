//
//  BusinessCardRepository.swift
//  名片資料存取層
//

import CoreData
import Combine
import UIKit

/// 名片資料存取層
final class BusinessCardRepository {
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    
    // MARK: - Initialization
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Create
    
    /// 建立新名片
    func create(_ card: BusinessCard) -> AnyPublisher<BusinessCard, Error> {
        coreDataStack.performBackgroundTask { context in
            // 建立新的 Entity
            let entity = BusinessCardEntity.create(from: card, in: context)
            
            // 驗證資料
            try entity.validate()
            
            // 儲存
            try context.safeSave()
            
            // 返回更新後的 Domain Model
            return entity.toDomainModel()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Read
    
    /// 取得所有名片（按建立時間倒序）
    func fetchAll() -> AnyPublisher<[BusinessCard], Error> {
        Future<[BusinessCard], Error> { promise in
            let context = self.coreDataStack.viewContext
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            
            // 按建立時間倒序排序（最新的在前）
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let cards = entities.map { $0.toDomainModel() }
                    promise(.success(cards))
                } catch {
                    promise(.failure(CoreDataError.fetchFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// 根據 ID 取得單張名片
    func fetch(by id: UUID) -> AnyPublisher<BusinessCard?, Error> {
        Future<BusinessCard?, Error> { promise in
            let context = self.coreDataStack.viewContext
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let card = entities.first?.toDomainModel()
                    promise(.success(card))
                } catch {
                    promise(.failure(CoreDataError.fetchFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// 搜尋名片（支援姓名、公司、電話、Email）
    func search(keyword: String) -> AnyPublisher<[BusinessCard], Error> {
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // 如果關鍵字為空，返回所有名片
            return fetchAll()
        }
        
        return Future<[BusinessCard], Error> { promise in
            let context = self.coreDataStack.viewContext
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            
            // 建立複合搜尋條件（OR 條件）
            let predicates = [
                NSPredicate(format: "name CONTAINS[cd] %@", keyword),
                NSPredicate(format: "namePhonetic CONTAINS[cd] %@", keyword),
                NSPredicate(format: "company CONTAINS[cd] %@", keyword),
                NSPredicate(format: "companyPhonetic CONTAINS[cd] %@", keyword),
                NSPredicate(format: "phone CONTAINS[cd] %@", keyword),
                NSPredicate(format: "mobile CONTAINS[cd] %@", keyword),
                NSPredicate(format: "email CONTAINS[cd] %@", keyword),
                NSPredicate(format: "department CONTAINS[cd] %@", keyword),
                NSPredicate(format: "jobTitle CONTAINS[cd] %@", keyword)
            ]
            
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let cards = entities.map { $0.toDomainModel() }
                    promise(.success(cards))
                } catch {
                    promise(.failure(CoreDataError.fetchFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Update
    
    /// 更新名片
    func update(_ card: BusinessCard) -> AnyPublisher<BusinessCard, Error> {
        coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)
            request.fetchLimit = 1
            
            guard let entity = try context.fetch(request).first else {
                throw CoreDataError.invalidEntity
            }
            
            // 更新 Entity
            entity.update(from: card)
            
            // 驗證資料
            try entity.validate()
            
            // 儲存
            try context.safeSave()
            
            // 返回更新後的 Domain Model
            return entity.toDomainModel()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Delete
    
    /// 刪除名片
    func delete(_ card: BusinessCard) -> AnyPublisher<Void, Error> {
        deleteById(card.id)
    }
    
    /// 根據 ID 刪除名片
    func deleteById(_ id: UUID) -> AnyPublisher<Void, Error> {
        coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let entities = try context.fetch(request)
            
            // 刪除所有符合的 Entity（理論上只有一個）
            entities.forEach { context.delete($0) }
            
            // 儲存變更
            try context.safeSave()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// 批次刪除多張名片
    func deleteMultiple(ids: [UUID]) -> AnyPublisher<Void, Error> {
        guard !ids.isEmpty else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            
            let entities = try context.fetch(request)
            
            // 批次刪除
            entities.forEach { context.delete($0) }
            
            // 儲存變更
            try context.safeSave()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// 刪除所有名片（危險操作）
    func deleteAll() -> AnyPublisher<Void, Error> {
        coreDataStack.performBackgroundTask { context in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "BusinessCardEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            try context.execute(deleteRequest)
            try context.safeSave()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Statistics
    
    /// 取得名片總數
    func count() -> AnyPublisher<Int, Error> {
        Future<Int, Error> { promise in
            let context = self.coreDataStack.viewContext
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            
            context.perform {
                do {
                    let count = try context.count(for: request)
                    promise(.success(count))
                } catch {
                    promise(.failure(CoreDataError.fetchFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// 檢查名片是否存在
    func exists(id: UUID) -> AnyPublisher<Bool, Error> {
        Future<Bool, Error> { promise in
            let context = self.coreDataStack.viewContext
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            context.perform {
                do {
                    let count = try context.count(for: request)
                    promise(.success(count > 0))
                } catch {
                    promise(.failure(CoreDataError.fetchFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Batch Operations
    
    /// 批次建立名片
    func createMultiple(_ cards: [BusinessCard]) -> AnyPublisher<[BusinessCard], Error> {
        guard !cards.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return coreDataStack.performBackgroundTask { context in
            var createdCards: [BusinessCard] = []
            
            for card in cards {
                let entity = BusinessCardEntity.create(from: card, in: context)
                try entity.validate()
                createdCards.append(entity.toDomainModel())
            }
            
            // 批次儲存
            try context.safeSave()
            
            return createdCards
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Advanced Queries
    
    /// 取得最近建立的名片
    func fetchRecent(limit: Int = 10) -> AnyPublisher<[BusinessCard], Error> {
        Future<[BusinessCard], Error> { promise in
            let context = self.coreDataStack.viewContext
            let request: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            request.fetchLimit = limit
            
            context.perform {
                do {
                    let entities = try context.fetch(request)
                    let cards = entities.map { $0.toDomainModel() }
                    promise(.success(cards))
                } catch {
                    promise(.failure(CoreDataError.fetchFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// 根據公司分組取得名片
    func fetchGroupedByCompany() -> AnyPublisher<[String: [BusinessCard]], Error> {
        fetchAll()
            .map { cards in
                // 按公司名稱分組
                Dictionary(grouping: cards) { card in
                    card.company ?? "未分類"
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Pagination Support (預留介面)
    
    /// 分頁載入名片
    func fetchPaged(page: Int, pageSize: Int = 20) -> AnyPublisher<PagedResult<BusinessCard>, Error> {
        Future<PagedResult<BusinessCard>, Error> { promise in
            let context = self.coreDataStack.viewContext
            
            // 先取得總數
            let countRequest: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
            
            context.perform {
                do {
                    let totalCount = try context.count(for: countRequest)
                    
                    // 取得分頁資料
                    let fetchRequest: NSFetchRequest<BusinessCardEntity> = BusinessCardEntity.fetchRequest()
                    fetchRequest.sortDescriptors = [
                        NSSortDescriptor(key: "createdAt", ascending: false)
                    ]
                    fetchRequest.fetchLimit = pageSize
                    fetchRequest.fetchOffset = page * pageSize
                    
                    let entities = try context.fetch(fetchRequest)
                    let cards = entities.map { $0.toDomainModel() }
                    
                    let result = PagedResult(
                        items: cards,
                        page: page,
                        pageSize: pageSize,
                        totalCount: totalCount
                    )
                    
                    promise(.success(result))
                } catch {
                    promise(.failure(CoreDataError.fetchFailed(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

/// 分頁結果
struct PagedResult<T> {
    let items: [T]
    let page: Int
    let pageSize: Int
    let totalCount: Int
    
    var totalPages: Int {
        return (totalCount + pageSize - 1) / pageSize
    }
    
    var hasNextPage: Bool {
        return page < totalPages - 1
    }
    
    var hasPreviousPage: Bool {
        return page > 0
    }
}
