//
//  Untitled.swift
//  BusinessCardScannerVer3
//
//  Created by mike liu on 2025/6/25.
//
import Foundation
import CoreData

struct BusinessCard {
    let id: UUID = UUID()
    var name: String = ""
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
    let createdAt: Date = Date()
    var updatedAt: Date = Date()
    var parseSource: String = "manual"
    var parseConfidence: Double?
    var rawOCRText: String?
}
