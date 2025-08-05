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
class MockValidationService {
    
    // MARK: - Mock Configuration
    
    private var emailValidationOverride: Bool?
    private var phoneValidationOverride: Bool?
    private var websiteValidationOverride: Bool?
    private var nameValidationOverride: ValidationResult?
    private var requiredFieldOverride: ValidationResult?
    
    private var shouldSimulateDelay = false
    private var validationDelay: TimeInterval = 0.1
    
    // MARK: - Mock Configuration Methods
    
    /// Configure email validation to return specific result
    /// - Parameter result: Override result for email validation
    func configureEmailValidation(result: Bool?) {
        emailValidationOverride = result
    }
    
    /// Configure phone validation to return specific result
    /// - Parameter result: Override result for phone validation
    func configurePhoneValidation(result: Bool?) {
        phoneValidationOverride = result
    }
    
    /// Configure website validation to return specific result
    /// - Parameter result: Override result for website validation
    func configureWebsiteValidation(result: Bool?) {
        websiteValidationOverride = result
    }
    
    /// Configure name validation to return specific result
    /// - Parameter result: Override result for name validation
    func configureNameValidation(result: ValidationResult?) {
        nameValidationOverride = result
    }
    
    /// Configure required field validation to return specific result
    /// - Parameter result: Override result for required field validation
    func configureRequiredFieldValidation(result: ValidationResult?) {
        requiredFieldOverride = result
    }
    
    /// Configure validation delay simulation
    /// - Parameters:
    ///   - shouldDelay: Whether to simulate delay
    ///   - delay: Delay duration in seconds
    func configureValidationDelay(shouldDelay: Bool, delay: TimeInterval = 0.1) {
        shouldSimulateDelay = shouldDelay
        validationDelay = delay
    }
    
    /// Reset all mock configurations to default
    func resetMockState() {
        emailValidationOverride = nil
        phoneValidationOverride = nil
        websiteValidationOverride = nil
        nameValidationOverride = nil
        requiredFieldOverride = nil
        shouldSimulateDelay = false
        validationDelay = 0.1
    }
    
    // MARK: - Validation Methods (Mirroring ValidationService)
    
    /// Validate email format with mock configuration
    /// - Parameter email: Email to validate
    /// - Returns: Validation result
    func validateEmail(_ email: String) -> Bool {
        if shouldSimulateDelay {
            Thread.sleep(forTimeInterval: validationDelay)
        }
        
        // Return override if configured
        if let override = emailValidationOverride {
            return override
        }
        
        // Use actual ValidationService logic
        return ValidationService.shared.validateEmail(email)
    }
    
    /// Validate phone format with mock configuration
    /// - Parameter phone: Phone to validate
    /// - Returns: Validation result
    func validatePhone(_ phone: String) -> Bool {
        if shouldSimulateDelay {
            Thread.sleep(forTimeInterval: validationDelay)
        }
        
        // Return override if configured
        if let override = phoneValidationOverride {
            return override
        }
        
        // Use actual ValidationService logic
        return ValidationService.shared.validatePhone(phone)
    }
    
    /// Validate website format with mock configuration
    /// - Parameter website: Website to validate
    /// - Returns: Validation result
    func validateWebsite(_ website: String) -> Bool {
        if shouldSimulateDelay {
            Thread.sleep(forTimeInterval: validationDelay)
        }
        
        // Return override if configured
        if let override = websiteValidationOverride {
            return override
        }
        
        // Use actual ValidationService logic
        return ValidationService.shared.validateWebsite(website)
    }
    
    /// Validate required field with mock configuration
    /// - Parameters:
    ///   - value: Value to validate
    ///   - fieldName: Field name for error message
    /// - Returns: Validation result
    func validateRequired(_ value: String?, fieldName: String) -> ValidationResult {
        if shouldSimulateDelay {
            Thread.sleep(forTimeInterval: validationDelay)
        }
        
        // Return override if configured
        if let override = requiredFieldOverride {
            return override
        }
        
        // Use actual ValidationService logic
        return ValidationService.shared.validateRequired(value, fieldName: fieldName)
    }
    
    /// Validate name with mock configuration
    /// - Parameter name: Name to validate
    /// - Returns: Validation result
    func validateName(_ name: String?) -> ValidationResult {
        if shouldSimulateDelay {
            Thread.sleep(forTimeInterval: validationDelay)
        }
        
        // Return override if configured
        if let override = nameValidationOverride {
            return override
        }
        
        // Use actual ValidationService logic
        return ValidationService.shared.validateName(name)
    }
    
    // MARK: - Test Utilities
    
    /// Setup common test scenarios
    func setupCommonTestScenarios() {
        // Reset to default state
        resetMockState()
    }
    
    /// Setup edge case scenarios for testing
    func setupEdgeCaseScenarios() {
        // Configure to fail all validations
        configureEmailValidation(result: false)
        configurePhoneValidation(result: false)
        configureWebsiteValidation(result: false)
        configureNameValidation(result: .invalid("Mock validation error"))
        configureRequiredFieldValidation(result: .invalid("Mock required field error"))
    }
    
    /// Setup performance test scenarios
    func setupPerformanceTestScenarios() {
        configureValidationDelay(shouldDelay: true, delay: 0.05)
    }
    
    /// Get validation statistics (for testing purposes)
    /// - Returns: Dictionary of validation call counts
    func getValidationStats() -> [String: Int] {
        // This could be enhanced to track actual call counts if needed
        return [
            "email_validations": 0,
            "phone_validations": 0,
            "website_validations": 0,
            "name_validations": 0,
            "required_validations": 0
        ]
    }
}