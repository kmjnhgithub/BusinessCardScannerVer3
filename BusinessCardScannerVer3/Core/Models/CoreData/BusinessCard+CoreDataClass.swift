//
//  BusinessCard+CoreDataClass.swift
//  BusinessCardScanner
//
//  Core Data Entity 類別定義與擴展
//

import Foundation
import CoreData

@objc(BusinessCardEntity)
public class BusinessCardEntity: NSManagedObject {

}

// MARK: - Entity Extensions

extension BusinessCardEntity {
    
    // MARK: - Entity to Domain Model Conversion
    
    /// 轉換為 Domain Model
    func toDomainModel() -> BusinessCard {
        // 直接建立 BusinessCard，因為 id 和 createdAt 是 let 常數
        let card = BusinessCard(
            id: id ?? UUID(),
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
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            parseSource: parseSource ?? "manual",
            parseConfidence: parseConfidence,
            rawOCRText: rawOCRText
        )
        
        return card
    }
    
    /// 從 Domain Model 更新 Entity
    func update(from card: BusinessCard) {
        // 基本資訊
        self.id = card.id
        self.name = card.name
        self.namePhonetic = card.namePhonetic
        self.jobTitle = card.jobTitle
        
        // 公司資訊
        self.company = card.company
        self.companyPhonetic = card.companyPhonetic
        self.department = card.department
        
        // 聯絡資訊
        self.email = card.email
        self.phone = card.phone
        self.mobile = card.mobile
        self.fax = card.fax
        self.website = card.website
        
        // 地址與備註
        self.address = card.address
        self.memo = card.memo
        
        // 系統資訊
        self.photoPath = card.photoPath
        self.createdAt = card.createdAt
        self.updatedAt = Date() // 更新時間設為現在
        
        // 解析資訊
        self.parseSource = card.parseSource
        self.parseConfidence = card.parseConfidence ?? 0.0
        self.rawOCRText = card.rawOCRText
    }
    
    // MARK: - Entity Factory
    
    /// 從 Domain Model 建立新的 Entity
    static func create(from card: BusinessCard, in context: NSManagedObjectContext) -> BusinessCardEntity {
        let entity = BusinessCardEntity(context: context)
        entity.update(from: card)
        return entity
    }
    
    // MARK: - Validation
    
    /// 驗證 Entity 資料完整性
    func validate() throws {
        // 名字是必填欄位
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("姓名")
        }
        
        // ID 必須存在
        guard id != nil else {
            throw ValidationError.missingRequiredField("ID")
        }
        
        // Email 格式驗證（如果有填寫）
        if let email = email, !email.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            guard emailPredicate.evaluate(with: email) else {
                throw ValidationError.invalidFormat("電子郵件格式不正確")
            }
        }
        
        // 電話號碼格式驗證（如果有填寫）
        if let phone = phone, !phone.isEmpty {
            let cleanPhone = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            guard cleanPhone.count >= 8 && cleanPhone.count <= 15 else {
                throw ValidationError.invalidFormat("電話號碼格式不正確")
            }
        }
        
        // 手機號碼格式驗證（如果有填寫）
        if let mobile = mobile, !mobile.isEmpty {
            let cleanMobile = mobile.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            guard cleanMobile.count >= 8 && cleanMobile.count <= 15 else {
                throw ValidationError.invalidFormat("手機號碼格式不正確")
            }
        }
        
        // 網址格式驗證（如果有填寫）
        if let website = website, !website.isEmpty {
            guard website.hasPrefix("http://") || website.hasPrefix("https://") || !website.contains("://") else {
                throw ValidationError.invalidFormat("網址格式不正確")
            }
        }
    }
    
    // MARK: - Debug Helper
    
    #if DEBUG
    /// 印出 Entity 資訊（除錯用）
    func printInfo() {
        print("""
        📇 BusinessCardEntity:
           ID: \(id?.uuidString ?? "nil")
           姓名: \(name ?? "nil")
           公司: \(company ?? "nil")
           職稱: \(jobTitle ?? "nil")
           電話: \(phone ?? "nil")
           Email: \(email ?? "nil")
           建立: \(createdAt?.description ?? "nil")
           更新: \(updatedAt?.description ?? "nil")
        """)
    }
    #endif
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidFormat(String)
    case dataIntegrityError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "\(field) 為必填欄位"
        case .invalidFormat(let message):
            return message
        case .dataIntegrityError(let message):
            return "資料完整性錯誤: \(message)"
        }
    }
}
