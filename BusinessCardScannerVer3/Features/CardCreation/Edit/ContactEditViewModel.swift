//
//  ContactEditViewModel.swift
//  Contact editing ViewModel with validation and business logic
//
//  Created by Claude Code on 2025/7/2.
//

import UIKit
import Foundation
import Combine

enum ContactEditError: LocalizedError {
    case invalidEmail
    case invalidPhone
    case invalidWebsite
    case requiredFieldMissing(field: String)
    case saveFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "電子郵件格式不正確"
        case .invalidPhone:
            return "電話號碼格式不正確"
        case .invalidWebsite:
            return "網站網址格式不正確"
        case .requiredFieldMissing(let field):
            return "\(field)為必填欄位"
        case .saveFailed(let underlying):
            return "儲存失敗：\(underlying.localizedDescription)"
        }
    }
}

class ContactEditViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    private let repository: BusinessCardRepository
    private let photoService: PhotoService
    private let businessCardService: BusinessCardService
    
    private let existingCard: BusinessCard?
    private var originalCardData: ParsedCardData
    private var currentPhoto: UIImage?
    private var photoPath: String?
    
    // MARK: - Published Properties
    
    @Published private(set) var cardData = ParsedCardData()
    @Published private(set) var photo: UIImage?
    @Published private(set) var validationErrors: [String: String] = [:]
    @Published private(set) var isSaveEnabled: Bool = false
    @Published private(set) var hasUnsavedChanges: Bool = false
    
    // MARK: - Computed Properties
    
    var isEditing: Bool {
        return existingCard != nil
    }
    
    // MARK: - Initialization
    
    init(repository: BusinessCardRepository,
         photoService: PhotoService,
         businessCardService: BusinessCardService,
         existingCard: BusinessCard? = nil,
         initialData: ParsedCardData? = nil,
         initialPhoto: UIImage? = nil) {
        
        self.repository = repository
        self.photoService = photoService
        self.businessCardService = businessCardService
        self.existingCard = existingCard
        
        // Initialize data
        if let existingCard = existingCard {
            self.originalCardData = ParsedCardData(
                name: existingCard.name,
                jobTitle: existingCard.jobTitle,
                company: existingCard.company,
                email: existingCard.email,
                phone: existingCard.phone,
                mobile: existingCard.mobile,
                address: existingCard.address,
                website: existingCard.website
            )
            self.cardData = self.originalCardData
            self.photoPath = existingCard.photoPath
        } else if let initialData = initialData {
            print("📝 ContactEditViewModel: 使用 initialData:")
            print("   Name: \(initialData.name ?? "nil")")
            print("   Company: \(initialData.company ?? "nil")")
            print("   Email: \(initialData.email ?? "nil")")
            
            self.originalCardData = ParsedCardData()
            self.cardData = initialData
        } else {
            print("📝 ContactEditViewModel: 使用空白資料")
            self.originalCardData = ParsedCardData()
            self.cardData = ParsedCardData()
        }
        
        self.currentPhoto = initialPhoto
        self.photo = initialPhoto
        
        super.init()
        
        setupBindings()
        loadPhotoIfNeeded()
        
        // 確保初始資料在 Combine 綁定建立後觸發 UI 更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            print("🔄 ContactEditViewModel: 延遲觸發 UI 更新")
            print("   Current cardData.name: \(self.cardData.name ?? "nil")")
            
            // 強制觸發 @Published 屬性更新
            let currentData = self.cardData
            self.cardData = ParsedCardData() // 暫時設為空
            
            DispatchQueue.main.async {
                self.cardData = currentData // 恢復正確資料
                print("✅ ContactEditViewModel: UI 更新觸發完成")
            }
        }
    }
    
    // MARK: - Setup
    
    override func setupBindings() {
        // Validate form whenever card data changes
        $cardData
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.validateForm()
                self?.updateHasUnsavedChanges()
            }
            .store(in: &cancellables)
        
        // Update save enabled state based on validation
        $validationErrors
            .combineLatest($hasUnsavedChanges)
            .map { errors, hasChanges in
                return errors.isEmpty && hasChanges
            }
            .assign(to: &$isSaveEnabled)
    }
    
    private func loadPhotoIfNeeded() {
        guard let photoPath = photoPath,
              photo == nil else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let loadedPhoto = self?.photoService.loadPhoto(path: photoPath)
            
            DispatchQueue.main.async {
                self?.photo = loadedPhoto
                self?.currentPhoto = loadedPhoto
            }
        }
    }
    
    // MARK: - Input Methods
    
    func updateName(_ name: String) {
        cardData.name = name.isEmpty ? nil : name
    }
    
    func updateJobTitle(_ jobTitle: String) {
        cardData.jobTitle = jobTitle.isEmpty ? nil : jobTitle
    }
    
    func updateCompany(_ company: String) {
        cardData.company = company.isEmpty ? nil : company
    }
    
    func updateEmail(_ email: String) {
        cardData.email = email.isEmpty ? nil : email
    }
    
    func updatePhone(_ phone: String) {
        cardData.phone = phone.isEmpty ? nil : phone
    }
    
    func updateMobile(_ mobile: String) {
        cardData.mobile = mobile.isEmpty ? nil : mobile
    }
    
    func updateAddress(_ address: String) {
        cardData.address = address.isEmpty ? nil : address
    }
    
    func updateWebsite(_ website: String) {
        cardData.website = website.isEmpty ? nil : website
    }
    
    // MARK: - Photo Management
    
    func selectPhotoFromCamera() {
        // In a real implementation, this would present camera interface
        // For now, we'll just log the action
        print("📸 ContactEditViewModel: 從相機選擇照片")
        // This would typically be handled by a coordinator or delegate
    }
    
    func selectPhotoFromLibrary() {
        // In a real implementation, this would present photo library
        // For now, we'll just log the action
        print("🖼️ ContactEditViewModel: 從相簿選擇照片")
        // This would typically be handled by a coordinator or delegate
    }
    
    func updatePhoto(_ newPhoto: UIImage?) {
        currentPhoto = newPhoto
        photo = newPhoto
        updateHasUnsavedChanges()
    }
    
    func removePhoto() {
        currentPhoto = nil
        photo = nil
        updateHasUnsavedChanges()
    }
    
    // MARK: - Validation
    
    private func validateForm() {
        var errors: [String: String] = [:]
        
        // Name validation (required)
        if let name = cardData.name {
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors["name"] = "姓名不能為空白"
            }
        } else {
            errors["name"] = "請輸入姓名"
        }
        
        // Email validation
        if let email = cardData.email, !email.isEmpty {
            if !isValidEmail(email) {
                errors["email"] = "電子郵件格式不正確"
            }
        }
        
        // Phone validation
        if let phone = cardData.phone, !phone.isEmpty {
            if !isValidPhone(phone) {
                errors["phone"] = "電話號碼格式不正確"
            }
        }
        
        // Mobile validation
        if let mobile = cardData.mobile, !mobile.isEmpty {
            if !isValidPhone(mobile) {
                errors["mobile"] = "手機號碼格式不正確"
            }
        }
        
        // Website validation
        if let website = cardData.website, !website.isEmpty {
            if !isValidWebsite(website) {
                errors["website"] = "網站網址格式不正確"
            }
        }
        
        validationErrors = errors
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        // 支援手機和電話號碼的驗證規則，包含分機號碼和國際格式
        let phoneRegex = "^[\\d\\s\\-\\+\\(\\)#]{8,25}$"  // 支援#分機號碼，增加長度限制
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    private func isValidWebsite(_ website: String) -> Bool {
        if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    // MARK: - Change Tracking
    
    private func updateHasUnsavedChanges() {
        let dataChanged = !cardData.isEqual(to: originalCardData)
        let photoChanged = hasPhotoChanged()
        
        hasUnsavedChanges = dataChanged || photoChanged
    }
    
    private func hasPhotoChanged() -> Bool {
        // Compare current photo with original
        if photoPath != nil {
            // Had original photo
            if currentPhoto == nil {
                return true // Photo was removed
            }
            // Photo might have been changed (simplified check)
            return false // In real implementation, compare image data
        } else {
            // No original photo
            return currentPhoto != nil // Photo was added
        }
    }
    
    // MARK: - Save Operation
    
    func save(completion: @escaping (Result<BusinessCard, ContactEditError>) -> Void) {
        // Validate before saving
        validateForm()
        
        guard validationErrors.isEmpty else {
            completion(.failure(.requiredFieldMissing(field: "必填欄位")))
            return
        }
        
        guard let name = cardData.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(.requiredFieldMissing(field: "姓名")))
            return
        }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performSave(completion: completion)
        }
    }
    
    private func performSave(completion: @escaping (Result<BusinessCard, ContactEditError>) -> Void) {
        if let existingCard = existingCard {
            // Update existing card
            updateExistingCard(existingCard, completion: completion)
        } else {
            // Create new card
            createNewCard(completion: completion)
        }
    }
    
    private func createNewCard(completion: @escaping (Result<BusinessCard, ContactEditError>) -> Void) {
        // Create new card with current data
        let newCard = BusinessCard(
            id: UUID(),
            name: cardData.name ?? "",
            namePhonetic: nil,
            jobTitle: cardData.jobTitle,
            company: cardData.company,
            companyPhonetic: nil,
            department: nil,
            email: cardData.email,
            phone: cardData.phone,
            mobile: cardData.mobile,
            fax: nil,
            address: cardData.address,
            website: cardData.website,
            memo: nil,
            photoPath: nil,
            createdAt: Date(),
            updatedAt: Date(),
            parseSource: "manual",
            parseConfidence: nil,
            rawOCRText: nil
        )
        
        repository.create(newCard)
            .sink(
                receiveCompletion: { [weak self] repositoryCompletion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = repositoryCompletion {
                            completion(.failure(.saveFailed(underlying: error)))
                        }
                    }
                },
                receiveValue: { [weak self] savedCard in
                    self?.handleCardSaved(savedCard, completion: completion)
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateExistingCard(_ card: BusinessCard, completion: @escaping (Result<BusinessCard, ContactEditError>) -> Void) {
        // Create updated card with current data
        let updatedCard = BusinessCard(
            id: card.id,
            name: cardData.name ?? "",
            namePhonetic: card.namePhonetic,
            jobTitle: cardData.jobTitle,
            company: cardData.company,
            companyPhonetic: card.companyPhonetic,
            department: card.department,
            email: cardData.email,
            phone: cardData.phone,
            mobile: cardData.mobile,
            fax: card.fax,
            address: cardData.address,
            website: cardData.website,
            memo: card.memo,
            photoPath: card.photoPath,
            createdAt: card.createdAt,
            updatedAt: Date(),
            parseSource: card.parseSource,
            parseConfidence: card.parseConfidence,
            rawOCRText: card.rawOCRText
        )
        
        repository.update(updatedCard)
            .sink(
                receiveCompletion: { [weak self] repositoryCompletion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = repositoryCompletion {
                            completion(.failure(.saveFailed(underlying: error)))
                        }
                    }
                },
                receiveValue: { [weak self] savedCard in
                    self?.handleCardSaved(savedCard, completion: completion)
                }
            )
            .store(in: &cancellables)
    }
    
    // Helper method removed - now using BusinessCard initializers directly
    
    private func handleCardSaved(_ savedCard: BusinessCard, completion: @escaping (Result<BusinessCard, ContactEditError>) -> Void) {
        // Handle photo saving if needed
        if let photo = currentPhoto {
            let photoPath = savePhoto(photo, for: savedCard)
            if let photoPath = photoPath {
                var cardWithPhoto = savedCard
                cardWithPhoto.photoPath = photoPath
                
                // Update card with photo path
                repository.update(cardWithPhoto)
                    .sink(
                        receiveCompletion: { repositoryCompletion in
                            DispatchQueue.main.async {
                                if case .failure(let error) = repositoryCompletion {
                                    completion(.failure(.saveFailed(underlying: error)))
                                }
                            }
                        },
                        receiveValue: { [weak self] finalCard in
                            DispatchQueue.main.async {
                                self?.completeSave(finalCard, completion: completion)
                            }
                        }
                    )
                    .store(in: &cancellables)
                return
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.completeSave(savedCard, completion: completion)
        }
    }
    
    private func completeSave(_ savedCard: BusinessCard, completion: @escaping (Result<BusinessCard, ContactEditError>) -> Void) {
        isLoading = false
        originalCardData = cardData
        hasUnsavedChanges = false
        completion(.success(savedCard))
    }
    
    private func savePhoto(_ photo: UIImage, for card: BusinessCard) -> String? {
        let cardId = card.id
        return photoService.savePhoto(photo, for: cardId)
    }
}

// MARK: - ParsedCardData Extension

private extension ParsedCardData {
    func isEqual(to other: ParsedCardData) -> Bool {
        return name == other.name &&
               jobTitle == other.jobTitle &&
               company == other.company &&
               email == other.email &&
               phone == other.phone &&
               mobile == other.mobile &&
               address == other.address &&
               website == other.website
    }
}