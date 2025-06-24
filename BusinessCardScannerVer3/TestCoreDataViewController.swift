//
//  TestCoreDataViewController.swift
//  BusinessCardScanner
//
//  測試 Core Data 功能
//

import UIKit

class TestCoreDataViewController: BaseViewController {
    
    // MARK: - Properties
    
    private var coreDataStack: CoreDataStack!
    private var repository: BusinessCardRepository!
    
    // MARK: - UI Elements
    
    private lazy var resultTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 14)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private lazy var testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("測試 Core Data", for: .normal)
        button.addTarget(self, action: #selector(runTests), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化 Core Data
        coreDataStack = CoreDataStack()
        repository = BusinessCardRepositoryImpl(coreDataStack: coreDataStack)
    }
    
    // MARK: - Setup
    
    override func setupUI() {
        super.setupUI()
        
        title = "Core Data 測試"
        
        view.addSubview(resultTextView)
        view.addSubview(testButton)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        NSLayoutConstraint.activate([
            testButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 150),
            testButton.heightAnchor.constraint(equalToConstant: 44),
            
            resultTextView.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 20),
            resultTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func runTests() {
        var results: [String] = ["=== Core Data 測試開始 ===\n"]
        
        do {
            // 1. 測試儲存
            let cardData = BusinessCardData(
                name: "測試名片",
                namePhonetic: "Test Card",
                jobTitle: "iOS 開發工程師",
                company: "測試公司",
                companyPhonetic: nil,
                department: "技術部",
                email: "test@example.com",
                phone: "02-1234-5678",
                mobile: "0912-345-678",
                fax: nil,
                address: "台北市測試路123號",
                website: "https://example.com",
                memo: "這是測試資料",
                photoPath: nil,
                parseSource: "manual",
                parseConfidence: 1.0,
                rawOCRText: nil
            )
            
            let savedCard = try repository.save(cardData)
            results.append("✅ 儲存成功 - ID: \(savedCard.id?.uuidString ?? "無")")
            
            // 2. 測試讀取全部
            let allCards = try repository.fetchAll()
            results.append("✅ 讀取全部: 共 \(allCards.count) 筆資料")
            
            // 3. 測試根據 ID 讀取
            if let cardId = savedCard.id,
               let fetchedCard = try repository.fetch(id: cardId) {
                results.append("✅ 根據 ID 讀取成功: \(fetchedCard.name ?? "無名稱")")
            }
            
            // 4. 測試搜尋
            let searchResults = try repository.search(keyword: "測試")
            results.append("✅ 搜尋 '測試': 找到 \(searchResults.count) 筆")
            
            // 5. 測試更新
            if let cardToUpdate = allCards.first {
                let updatedData = BusinessCardData(
                    name: "更新後的名片",
                    namePhonetic: nil,
                    jobTitle: "資深工程師",
                    company: cardToUpdate.company,
                    companyPhonetic: nil,
                    department: cardToUpdate.department,
                    email: cardToUpdate.email,
                    phone: cardToUpdate.phone,
                    mobile: cardToUpdate.mobile,
                    fax: nil,
                    address: cardToUpdate.address,
                    website: cardToUpdate.website,
                    memo: "已更新",
                    photoPath: nil,
                    parseSource: "manual",
                    parseConfidence: 1.0,
                    rawOCRText: nil
                )
                
                try repository.update(cardToUpdate, with: updatedData)
                results.append("✅ 更新成功")
            }
            
            // 6. 測試刪除
            if let cardToDelete = allCards.last {
                try repository.delete(cardToDelete)
                results.append("✅ 刪除成功")
            }
            
            // 7. 最終確認
            let finalCount = try repository.fetchAll().count
            results.append("\n✅ 測試完成！目前資料庫有 \(finalCount) 筆資料")
            
        } catch {
            results.append("❌ 錯誤: \(error.localizedDescription)")
        }
        
        resultTextView.text = results.joined(separator: "\n")
    }
}
