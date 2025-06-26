//
//  BusinessCard.swift
//  BusinessCardScanner
//
//  名片領域模型
//

import Foundation

struct BusinessCard {
    let id: UUID
    var name: String
    var namePhonetic: String?
    var jobTitle: String?
    var company: String?
    var companyPhonetic: String?
    var department: String?
    var email: String?
    var phone: String?
    var mobile: String?
    var fax: String?
    var address: String?
    var website: String?
    var memo: String?
    var photoPath: String?
    let createdAt: Date
    var updatedAt: Date
    var parseSource: String
    var parseConfidence: Double?
    var rawOCRText: String?
    
    // MARK: - Initialization
    
    /// 預設初始化（新建名片）
    init() {
        self.id = UUID()
        self.name = ""
        self.namePhonetic = nil
        self.jobTitle = nil
        self.company = nil
        self.companyPhonetic = nil
        self.department = nil
        self.email = nil
        self.phone = nil
        self.mobile = nil
        self.fax = nil
        self.address = nil
        self.website = nil
        self.memo = nil
        self.photoPath = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.parseSource = "manual"
        self.parseConfidence = nil
        self.rawOCRText = nil
    }
    
    /// 完整初始化（從資料庫載入）
    init(
        id: UUID,
        name: String,
        namePhonetic: String? = nil,
        jobTitle: String? = nil,
        company: String? = nil,
        companyPhonetic: String? = nil,
        department: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        mobile: String? = nil,
        fax: String? = nil,
        address: String? = nil,
        website: String? = nil,
        memo: String? = nil,
        photoPath: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        parseSource: String = "manual",
        parseConfidence: Double? = nil,
        rawOCRText: String? = nil
    ) {
        self.id = id
        self.name = name
        self.namePhonetic = namePhonetic
        self.jobTitle = jobTitle
        self.company = company
        self.companyPhonetic = companyPhonetic
        self.department = department
        self.email = email
        self.phone = phone
        self.mobile = mobile
        self.fax = fax
        self.address = address
        self.website = website
        self.memo = memo
        self.photoPath = photoPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.parseSource = parseSource
        self.parseConfidence = parseConfidence
        self.rawOCRText = rawOCRText
    }
}

// MARK: - Computed Properties

extension BusinessCard {
    
    /// 完整的顯示名稱（包含拼音）
    var displayName: String {
        if let phonetic = namePhonetic, !phonetic.isEmpty {
            return "\(name) (\(phonetic))"
        }
        return name
    }
    
    /// 完整的公司名稱（包含拼音）
    var displayCompany: String? {
        guard let company = company else { return nil }
        if let phonetic = companyPhonetic, !phonetic.isEmpty {
            return "\(company) (\(phonetic))"
        }
        return company
    }
    
    /// 是否有照片
    var hasPhoto: Bool {
        return photoPath != nil
    }
    
    /// 解析來源的描述
    var parseSourceDescription: String {
        switch parseSource {
        case "ai":
            return "AI 解析"
        case "local":
            return "本地解析"
        case "manual":
            return "手動輸入"
        default:
            return "未知"
        }
    }
}

// MARK: - Equatable

extension BusinessCard: Equatable {
    static func == (lhs: BusinessCard, rhs: BusinessCard) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Identifiable

extension BusinessCard: Identifiable {
    // id 屬性已經存在，自動符合 Identifiable
}
