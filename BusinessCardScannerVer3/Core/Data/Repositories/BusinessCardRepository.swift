//
//  BusinessCardRepository.swift
//  BusinessCardScanner
//
//  名片資料存取層
//

import CoreData
import UIKit

/// 名片資料存取協議
protocol BusinessCardRepository {
    func save(_ card: BusinessCardData) throws -> BusinessCard
    func update(_ card: BusinessCard, with data: BusinessCardData) throws
    func fetchAll() throws -> [BusinessCard]
    func fetch(id: UUID) throws -> BusinessCard?
    func delete(_ card: BusinessCard) throws
    func search(keyword: String) throws -> [BusinessCard]
    func deleteAll() throws
}

/// 名片資料傳輸物件
struct BusinessCardData {
    let name: String
    let namePhonetic: String?
    let jobTitle: String?
    let company: String?
    let companyPhonetic: String?
    let department: String?
    let email: String?
    let phone: String?
    let mobile: String?
    let fax: String?
    let address: String?
    let website: String?
    let memo: String?
    let photoPath: String?
    let parseSource: String?
    let parseConfidence: Double?
    let rawOCRText: String?
}

/// 名片資料存取實作
final class BusinessCardRepositoryImpl: BusinessCardRepository {
    
    // MARK: - Properties
    
    private let coreDataStack: CoreDataStack
    
    // MARK: - Initialization
    
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Create
    
    func save(_ card: BusinessCardData) throws -> BusinessCard {
        let context = coreDataStack.mainContext
        
        let businessCard = BusinessCard(context: context)
        businessCard.id = UUID()
        businessCard.createdAt = Date()
        businessCard.updatedAt = Date()
        
        // 更新資料
        updateBusinessCard(businessCard, with: card)
        
        try coreDataStack.save()
        
        return businessCard
    }
    
    // MARK: - Read
    
    func fetchAll() throws -> [BusinessCard] {
        let fetchRequest: NSFetchRequest<BusinessCard> = BusinessCard.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        do {
            return try coreDataStack.mainContext.fetch(fetchRequest)
        } catch {
            throw CoreDataError.fetchError(error)
        }
    }
    
    func fetch(id: UUID) throws -> BusinessCard? {
        let fetchRequest: NSFetchRequest<BusinessCard> = BusinessCard.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try coreDataStack.mainContext.fetch(fetchRequest)
            return results.first
        } catch {
            throw CoreDataError.fetchError(error)
        }
    }
    
    func search(keyword: String) throws -> [BusinessCard] {
        let fetchRequest: NSFetchRequest<BusinessCard> = BusinessCard.fetchRequest()
        
        // 搜尋多個欄位
        let predicates = [
            NSPredicate(format: "name CONTAINS[cd] %@", keyword),
            NSPredicate(format: "company CONTAINS[cd] %@", keyword),
            NSPredicate(format: "email CONTAINS[cd] %@", keyword),
            NSPredicate(format: "phone CONTAINS[cd] %@", keyword),
            NSPredicate(format: "mobile CONTAINS[cd] %@", keyword),
            NSPredicate(format: "jobTitle CONTAINS[cd] %@", keyword)
        ]
        
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        do {
            return try coreDataStack.mainContext.fetch(fetchRequest)
        } catch {
            throw CoreDataError.fetchError(error)
        }
    }
    
    // MARK: - Update
    
    func update(_ card: BusinessCard, with data: BusinessCardData) throws {
        updateBusinessCard(card, with: data)
        card.updatedAt = Date()
        
        try coreDataStack.save()
    }
    
    // MARK: - Delete
    
    func delete(_ card: BusinessCard) throws {
        let context = coreDataStack.mainContext
        context.delete(card)
        
        try coreDataStack.save()
    }
    
    func deleteAll() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = BusinessCard.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try coreDataStack.mainContext.execute(batchDeleteRequest)
            try coreDataStack.save()
        } catch {
            throw CoreDataError.deleteError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateBusinessCard(_ businessCard: BusinessCard, with data: BusinessCardData) {
        businessCard.name = data.name
        businessCard.namePhonetic = data.namePhonetic
        businessCard.jobTitle = data.jobTitle
        businessCard.company = data.company
        businessCard.companyPhonetic = data.companyPhonetic
        businessCard.department = data.department
        businessCard.email = data.email
        businessCard.phone = data.phone
        businessCard.mobile = data.mobile
        businessCard.fax = data.fax
        businessCard.address = data.address
        businessCard.website = data.website
        businessCard.memo = data.memo
        businessCard.photoPath = data.photoPath
        businessCard.parseSource = data.parseSource ?? "manual"
        businessCard.parseConfidence = data.parseConfidence ?? 0.0
        businessCard.rawOCRText = data.rawOCRText
    }
}

// MARK: - Convenience Extensions

extension BusinessCard {
    /// 轉換為資料傳輸物件
    func toData() -> BusinessCardData {
        return BusinessCardData(
            name: name ?? "",
            namePhonetic: namePhonetic,
            jobTitle: jobTitle,
            company: company,
            companyPhonetic: companyPhonetic,
            department: department,
            email: email,
            phone: phone,
            mobile: mobile,
            fax: fax,
            address: address,
            website: website,
            memo: memo,
            photoPath: photoPath,
            parseSource: parseSource,
            parseConfidence: parseConfidence,
            rawOCRText: rawOCRText
        )
    }
}
