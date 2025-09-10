//
//  MockValidationService.swift
//  BusinessCardScannerVer3Tests
//
//  Mock implementation of ValidationService for testing
//  Provides configurable validation behaviors for comprehensive testing
//

import Foundation
@testable import BusinessCardScannerVer3

/// Mock implementation of ValidationService for testing purposes
/// Allows configurable validation behaviors and edge case simulation
final class MockValidationService: ValidationServiceProtocol {
    
    // MARK: - Mock Configuration
    
    /// 是否模擬嚴格驗證
    var strictValidation: Bool = false
    
    // MARK: - Analytics
    
    private(set) var emailValidationCount: Int = 0
    private(set) var phoneValidationCount: Int = 0
    private(set) var websiteValidationCount: Int = 0
    
    // MARK: - ValidationServiceProtocol Implementation
    
    func validateEmail(_ email: String) -> Bool {
        emailValidationCount += 1
        
        if strictValidation {
            // 嚴格驗證
            let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: email)
        } else {
            // 寬鬆驗證
            return email.contains("@") && email.contains(".")
        }
    }
    
    func validatePhone(_ phone: String) -> Bool {
        phoneValidationCount += 1
        
        if strictValidation {
            // 嚴格的台灣電話格式驗證
            let phoneRegex = "^(02|03|04|05|06|07|08|09)[0-9-]{7,}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            return phonePredicate.evaluate(with: phone)
        } else {
            // 寬鬆驗證
            return phone.count >= 8 && phone.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        }
    }
    
    func validateWebsite(_ website: String) -> Bool {
        websiteValidationCount += 1
        
        if strictValidation {
            // 嚴格的網址驗證
            let urlString = website.hasPrefix("http") ? website : "https://\(website)"
            guard let url = URL(string: urlString),
                  let host = url.host, !host.isEmpty else { return false }
            
            let hostRegex = "^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$"
            let hostPredicate = NSPredicate(format: "SELF MATCHES %@", hostRegex)
            return hostPredicate.evaluate(with: host)
        } else {
            // 寬鬆驗證
            return website.contains(".") && website.count > 3
        }
    }
    
    func validateRequiredField(_ text: String) -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func validateName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= 1 && trimmedName.count <= 50
    }
    
    // MARK: - Test Helpers
    
    /// 重置 Mock 狀態
    func resetMockState() {
        strictValidation = false
        emailValidationCount = 0
        phoneValidationCount = 0
        websiteValidationCount = 0
    }
    
    /// 設定嚴格驗證模式
    func setStrictValidation(_ strict: Bool) {
        strictValidation = strict
    }
}