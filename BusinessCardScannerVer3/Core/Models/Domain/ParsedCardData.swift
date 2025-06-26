//
//  Untitled.swift
//  BusinessCardScannerVer3
//
//  Created by mike liu on 2025/6/25.
//

import Foundation

struct ParsedCardData {
    var name: String?
    var namePhonetic: String?
    var jobTitle: String?
    var company: String?
    var department: String?
    var email: String?
    var phone: String?
    var mobile: String?
    var address: String?
    var website: String?
    var confidence: Double = 0.0
    var source: ParseSource = .manual
    
    enum ParseSource {
        case ai
        case local
        case manual
    }
}
