//
//  ValidationService.swift
//  BusinessCardScannerVer3
//
//  Created on 2025/7/8.
//
//  統一的驗證服務，提供各種格式驗證功能
//  符合 MVVM 架構規範，不依賴 UIKit
//

import Foundation

/// 驗證服務，提供各種資料格式驗證功能
final class ValidationService {
    
    // MARK: - Singleton
    
    static let shared = ValidationService()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Email Validation
    
    /// 驗證電子郵件格式
    /// - Parameter email: 要驗證的電子郵件
    /// - Returns: 是否為有效格式
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Phone Validation
    
    /// 驗證電話號碼格式（支援手機、市話、分機號碼）
    /// - Parameter phone: 要驗證的電話號碼
    /// - Returns: 是否為有效格式
    func validatePhone(_ phone: String) -> Bool {
        // 支援手機和電話號碼的驗證規則，包含分機號碼和國際格式
        let phoneRegex = "^[\\d\\s\\-\\+\\(\\)#]{8,25}$"  // 支援#分機號碼，增加長度限制
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    // MARK: - Website Validation
    
    /// 驗證網站 URL 格式（不使用 UIApplication.canOpenURL）
    /// - Parameter website: 要驗證的網站網址
    /// - Returns: 是否為有效格式
    func validateWebsite(_ website: String) -> Bool {
        // 處理網址前綴
        let urlString = website.hasPrefix("http") ? website : "https://\(website)"
        
        // 基本 URL 格式驗證
        guard let url = URL(string: urlString) else { 
            return false 
        }
        
        // 檢查是否有 host
        guard let host = url.host, !host.isEmpty else { 
            return false 
        }
        
        // 驗證 host 格式
        // 支援標準域名格式：example.com, sub.example.com, example.co.tw
        let hostRegex = "^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$|^localhost$|^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$"
        let hostPredicate = NSPredicate(format: "SELF MATCHES %@", hostRegex)
        
        // 如果是 www. 開頭但沒有 http/https，也接受
        if website.hasPrefix("www.") && !website.hasPrefix("http") {
            return hostPredicate.evaluate(with: host)
        }
        
        return hostPredicate.evaluate(with: host)
    }
    
    // MARK: - Required Field Validation
    
    /// 驗證必填欄位
    /// - Parameters:
    ///   - value: 要驗證的值
    ///   - fieldName: 欄位名稱（用於錯誤訊息）
    /// - Returns: 驗證結果
    func validateRequired(_ value: String?, fieldName: String) -> ValidationResult {
        guard let value = value, 
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid("\(fieldName)為必填欄位")
        }
        return .valid
    }
    
    // MARK: - Name Validation
    
    /// 驗證姓名格式
    /// - Parameter name: 要驗證的姓名
    /// - Returns: 驗證結果
    func validateName(_ name: String?) -> ValidationResult {
        guard let name = name else {
            return .invalid("請輸入姓名")
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .invalid("姓名不能為空白")
        }
        
        // 名字長度限制（1-50字元）
        if trimmedName.count > 50 {
            return .invalid("姓名長度不能超過50個字元")
        }
        
        return .valid
    }
}

// MARK: - ValidationResult

/// 驗證結果
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static var valid: ValidationResult {
        ValidationResult(isValid: true, errorMessage: nil)
    }
    
    static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: message)
    }
}