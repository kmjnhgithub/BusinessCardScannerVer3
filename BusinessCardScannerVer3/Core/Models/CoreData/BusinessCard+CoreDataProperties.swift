//
//  BusinessCard+CoreDataProperties.swift

//
//  Core Data Entity 屬性定義
//

import Foundation
import CoreData

extension BusinessCardEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BusinessCardEntity> {
        return NSFetchRequest<BusinessCardEntity>(entityName: "BusinessCardEntity")
    }

    // MARK: - Core Properties
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var namePhonetic: String?
    @NSManaged public var jobTitle: String?
    @NSManaged public var company: String?
    @NSManaged public var companyPhonetic: String?
    @NSManaged public var department: String?
    
    // MARK: - Contact Properties
    
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var mobile: String?
    @NSManaged public var fax: String?
    @NSManaged public var website: String?
    
    // MARK: - Additional Properties
    
    @NSManaged public var address: String?
    @NSManaged public var memo: String?
    @NSManaged public var photoPath: String?
    
    // MARK: - System Properties
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var parseSource: String?
    @NSManaged public var parseConfidence: Double
    @NSManaged public var rawOCRText: String?

}

// MARK: - Core Data Generated Accessors

extension BusinessCardEntity: Identifiable {
    // 讓 Entity 符合 Identifiable protocol
}
