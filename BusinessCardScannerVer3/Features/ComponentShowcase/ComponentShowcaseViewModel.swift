//
//  ComponentShowcaseViewModel.swift
//  BusinessCardScannerVer3
//
//  元件展示頁面的 ViewModel
//  遵循 MVVM + Combine 架構模式
//

import Foundation
import Combine

/// 元件展示頁面的 ViewModel
final class ComponentShowcaseViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var testResult: String?
    @Published var cards: [BusinessCard] = []
    @Published var formData: ComponentFormData = ComponentFormData()
    
    // MARK: - Dependencies
    
    private let repository = ServiceContainer.shared.businessCardRepository
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    override func setupBindings() {
        // 監聽表單資料變化
        $formData
            .dropFirst()
            .sink { [weak self] formData in
                self?.validateFormData(formData)
            }
            .store(in: &cancellables)
    }
    
    private func validateFormData(_ formData: ComponentFormData) {
        // 表單驗證邏輯
        print("表單資料驗證 - 姓名: \(formData.name), Email: \(formData.email)")
    }
    
    // MARK: - Public Methods
    
    /// 更新表單資料
    func updateFormData(name: String? = nil, email: String? = nil, phone: String? = nil) {
        var updatedFormData = formData
        
        if let name = name {
            updatedFormData.name = name
        }
        if let email = email {
            updatedFormData.email = email
        }
        if let phone = phone {
            updatedFormData.phone = phone
        }
        
        formData = updatedFormData
    }
    
    /// 執行 Combine 測試
    func performCombineTest() -> AnyPublisher<String, Never> {
        return Future<String, Never> { promise in
            // 模擬非同步操作
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
                let result = "Combine 測試成功完成 - \(Date().timeIntervalSince1970)"
                promise(.success(result))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// 建立測試名片
    func createTestCard() {
        let timestamp = Date().timeIntervalSince1970
        let card = BusinessCard()
        var mutableCard = card
        mutableCard.name = "測試名片 \(Int(timestamp))"
        mutableCard.company = "測試公司"
        mutableCard.email = "test\(Int(timestamp))@example.com"
        mutableCard.phone = "0987654321"
        mutableCard.jobTitle = "測試職位"
        mutableCard.address = "測試地址"
        mutableCard.parseSource = "manual"
        
        performPublisherOperation(
            publisher: repository.create(mutableCard),
            onSuccess: { [weak self] card in
                self?.testResult = "名片建立成功: \(card.name)"
                print("✅ 名片建立成功: \(card.name)")
            },
            onError: { [weak self] error in
                self?.testResult = "建立失敗: \(error.localizedDescription)"
                print("❌ 名片建立失敗: \(error)")
            }
        )
    }
    
    /// 載入所有名片
    func fetchAllCards() {
        performPublisherOperation(
            publisher: repository.fetchAll(),
            onSuccess: { [weak self] cards in
                self?.cards = cards
                self?.testResult = "載入成功: \(cards.count) 張名片"
                print("✅ 載入名片成功: \(cards.count) 張")
            },
            onError: { [weak self] error in
                self?.testResult = "載入失敗: \(error.localizedDescription)"
                print("❌ 載入名片失敗: \(error)")
            }
        )
    }
    
    /// 執行完整測試流程
    func runCompleteTest() -> AnyPublisher<String, Never> {
        isLoading = true
        
        return performCombineTest()
            .flatMap { [weak self] _ -> AnyPublisher<String, Never> in
                guard let self = self else {
                    return Just("測試中斷").eraseToAnyPublisher()
                }
                
                // 建立測試名片
                self.createTestCard()
                
                // 等待一段時間後載入名片
                return Just("完整測試流程執行完成")
                    .delay(for: .seconds(2), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading = false
                }
            )
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Models

/// 元件展示表單資料模型
struct ComponentFormData {
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    
    var isValid: Bool {
        return !name.isEmpty && !email.isEmpty
    }
}
