import Foundation
import UIKit
@testable import BusinessCardScannerVer3

/// 測試用 Mock 資料集合
/// 提供各種測試場景的標準資料，確保測試的一致性和可重複性
/// 所有名片均為中英文混合格式，符合實際使用情況
struct MockData {
    
    // MARK: - Standard Business Cards
    
    /// 標準中英混合名片 - 科技業
    static let techBusinessCard = BusinessCard(
        id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174001")!,
        name: "王大明 David Wang",
        namePhonetic: "Wang Da Ming",
        jobTitle: "產品經理 Product Manager",
        company: "ABC科技股份有限公司 ABC Technology Co., Ltd.",
        companyPhonetic: "ABC Technology Company Limited",
        department: "產品部 Product Department",
        email: "david.wang@abc.com.tw",
        phone: "02-1234-5678",
        mobile: "0912-345-678",
        fax: "02-1234-5679",
        address: "台北市信義區信義路五段7號 No.7, Sec.5, Xinyi Rd., Xinyi Dist., Taipei City",
        website: "www.abc.com.tw",
        memo: "重要客戶",
        photoPath: "mock_photo_tech.jpg",
        createdAt: Date(timeIntervalSince1970: 1704067200), // 2024-01-01
        updatedAt: Date(timeIntervalSince1970: 1704153600), // 2024-01-02
        parseSource: "ai",
        parseConfidence: 0.92,
        rawOCRText: """
        王大明 David Wang
        ABC科技股份有限公司
        ABC Technology Co., Ltd.
        產品經理 Product Manager
        TEL: 02-1234-5678
        MOBILE: 0912-345-678
        EMAIL: david.wang@abc.com.tw
        """
    )
    
    /// 設計業名片
    static let designBusinessCard = BusinessCard(
        id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174002")!,
        name: "李小華 Lisa Lee",
        namePhonetic: "Lee Xiao Hua",
        jobTitle: "創意總監 Creative Director",
        company: "XYZ設計工作室 XYZ Design Studio",
        companyPhonetic: nil,
        department: "設計部 Design Department",
        email: "lisa.lee@xyz-design.com",
        phone: "02-8765-4321",
        mobile: "0987-654-321",
        fax: nil,
        address: "台北市大安區敦化南路二段123號8樓 8F, No.123, Sec.2, Dunhua S. Rd., Da'an Dist., Taipei",
        website: "www.xyz-design.com",
        memo: nil,
        photoPath: "mock_photo_design.jpg",
        createdAt: Date(timeIntervalSince1970: 1704153600), // 2024-01-02
        updatedAt: Date(timeIntervalSince1970: 1704240000), // 2024-01-03
        parseSource: "ai",
        parseConfidence: 0.95,
        rawOCRText: """
        李小華 Lisa Lee
        XYZ設計工作室 XYZ Design Studio
        創意總監 Creative Director
        Phone: 02-8765-4321
        Mobile: 0987-654-321
        Email: lisa.lee@xyz-design.com
        """
    )
    
    /// 簡單名片（最少資訊）
    static let minimalCard = BusinessCard(
        id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174004")!,
        name: "張三 Sam Chang",
        namePhonetic: nil,
        jobTitle: nil,
        company: "新創公司 Startup Inc.",
        companyPhonetic: nil,
        department: nil,
        email: "sam@startup.tw",
        phone: nil,
        mobile: "0911-222-333",
        fax: nil,
        address: nil,
        website: nil,
        memo: nil,
        photoPath: nil,
        createdAt: Date(timeIntervalSince1970: 1704326400), // 2024-01-04
        updatedAt: Date(timeIntervalSince1970: 1704326400), // 2024-01-04
        parseSource: "manual",
        parseConfidence: nil,
        rawOCRText: nil
    )
    
    // MARK: - Business Card Collections
    
    /// 標準測試名片集合
    static let standardCards: [BusinessCard] = [
        techBusinessCard,
        designBusinessCard,
        minimalCard
    ]
    
    // MARK: - OCR Results
    
    /// 高品質 OCR 結果（中英混合）
    static let highQualityOCR = OCRResult(
        recognizedText: """
        王大明 David Wang
        ABC科技股份有限公司
        ABC Technology Co., Ltd.
        產品經理 Product Manager
        電話 TEL: 02-1234-5678
        手機 MOBILE: 0912-345-678
        信箱 EMAIL: david.wang@abc.com.tw
        """,
        confidence: 0.95,
        boundingBoxes: [
            TextBoundingBox(text: "王大明 David Wang", confidence: 0.95, boundingBox: CGRect(x: 10, y: 10, width: 150, height: 20), topCandidates: ["王大明 David Wang", "王大明David Wang"]),
            TextBoundingBox(text: "ABC科技股份有限公司", confidence: 0.92, boundingBox: CGRect(x: 10, y: 35, width: 200, height: 20), topCandidates: ["ABC科技股份有限公司", "ABC科技有限公司"]),
            TextBoundingBox(text: "ABC Technology Co., Ltd.", confidence: 0.90, boundingBox: CGRect(x: 10, y: 60, width: 180, height: 20), topCandidates: ["ABC Technology Co., Ltd.", "ABC Technology Co Ltd"]),
            TextBoundingBox(text: "產品經理 Product Manager", confidence: 0.88, boundingBox: CGRect(x: 10, y: 85, width: 160, height: 20), topCandidates: ["產品經理 Product Manager", "產品經理Product Manager"]),
            TextBoundingBox(text: "02-1234-5678", confidence: 0.95, boundingBox: CGRect(x: 10, y: 110, width: 140, height: 20), topCandidates: ["02-1234-5678", "02-12345678"]),
            TextBoundingBox(text: "0912-345-678", confidence: 0.93, boundingBox: CGRect(x: 10, y: 135, width: 150, height: 20), topCandidates: ["0912-345-678", "0912345678"]),
            TextBoundingBox(text: "david.wang@abc.com.tw", confidence: 0.96, boundingBox: CGRect(x: 10, y: 160, width: 180, height: 20), topCandidates: ["david.wang@abc.com.tw", "david.wang@abc.com"])
        ],
        processingTime: 1.2
    )
    
    /// 低品質 OCR 結果
    static let lowQualityOCR = OCRResult(
        recognizedText: """
        王?明 D?vid Wang
        ABC科?公司
        產品?理 Product Manager
        TEL: 02-12?4-5678
        """,
        confidence: 0.45,
        boundingBoxes: [
            TextBoundingBox(text: "王?明 D?vid Wang", confidence: 0.45, boundingBox: CGRect(x: 5, y: 8, width: 160, height: 25), topCandidates: ["王?明 D?vid Wang", "王大明 David Wang", "王小明 David Wang"]),
            TextBoundingBox(text: "ABC科?公司", confidence: 0.35, boundingBox: CGRect(x: 15, y: 40, width: 180, height: 28), topCandidates: ["ABC科?公司", "ABC科技公司", "ABC公司"])
        ],
        processingTime: 2.5
    )
    
    // MARK: - AI Responses
    
    /// 成功的 AI 回應
    static let successfulAIResponse = AIResponse(
        id: "chatcmpl-123",
        model: "gpt-3.5-turbo",
        choices: [
            AIResponse.Choice(
                message: AIResponse.Message(
                    role: "assistant",
                    content: """
                    {
                        "name": "王大明 David Wang",
                        "namePhonetic": "Wang Da Ming",
                        "company": "ABC科技股份有限公司",
                        "jobTitle": "產品經理 Product Manager",
                        "department": "產品部 Product Department",
                        "email": "david.wang@abc.com.tw",
                        "phone": "02-1234-5678",
                        "mobile": "0912-345-678",
                        "website": "www.abc.com.tw",
                        "address": "台北市信義區信義路五段7號"
                    }
                    """
                ),
                finishReason: "stop"
            )
        ],
        usage: TokenUsage(promptTokens: 180, completionTokens: 120, totalTokens: 300)
    )
    
    // MARK: - Parsed Card Data
    
    /// 來自 AI 的解析資料
    static let aiParsedData = ParsedCardData(
        name: "王大明 David Wang",
        namePhonetic: "Wang Da Ming",
        jobTitle: "產品經理 Product Manager",
        company: "ABC科技股份有限公司",
        department: "產品部 Product Department",
        email: "david.wang@abc.com.tw",
        phone: "02-1234-5678",
        mobile: "0912-345-678",
        address: "台北市信義區信義路五段7號",
        website: "www.abc.com.tw",
        confidence: 0.92,
        source: .ai
    )
    
    // MARK: - Card Creation Data
    
    /// 完整的名片建立資料
    static let completeCardCreationData = CardCreationData(
        name: "王大明 David Wang",
        namePhonetic: "Wang Da Ming",
        jobTitle: "產品經理 Product Manager",
        company: "ABC科技股份有限公司",
        companyPhonetic: "ABC Technology Company Limited",
        department: "產品部 Product Department",
        email: "david.wang@abc.com.tw",
        phone: "02-1234-5678",
        mobile: "0912-345-678",
        fax: "02-1234-5679",
        address: "台北市信義區信義路五段7號",
        website: "www.abc.com.tw",
        memo: "重要客戶",
        photoData: MockImages.standardImage.pngData()
    )
    
    /// 手動建立的資料
    static let manualCardCreationData = CardCreationData(
        name: "張三 Sam Chang",
        namePhonetic: nil,
        jobTitle: nil,
        company: "新創公司 Startup Inc.",
        companyPhonetic: nil,
        department: nil,
        email: "sam@startup.tw",
        phone: nil,
        mobile: "0911-222-333",
        fax: nil,
        address: nil,
        website: nil,
        memo: nil,
        photoData: nil
    )
    
    // MARK: - Large Data Sets
    
    /// 產生大量測試資料（用於效能測試）
    static func generateLargeDataSet(count: Int) -> [BusinessCard] {
        var cards: [BusinessCard] = []
        
        let companies = [
            "科技公司 Tech Corp",
            "設計工作室 Design Studio", 
            "貿易有限公司 Trading Co., Ltd."
        ]
        let titles = [
            "經理 Manager",
            "總監 Director", 
            "工程師 Engineer"
        ]
        let sources: [String] = ["ai", "local", "manual"]
        
        for i in 1...count {
            let card = BusinessCard(
                id: UUID(),
                name: "測試用戶\(i) User\(i)",
                namePhonetic: nil,
                jobTitle: titles[i % titles.count],
                company: companies[i % companies.count],
                companyPhonetic: nil,
                department: nil,
                email: "user\(i)@test\(i % 10).com.tw",
                phone: "02-\(String(format: "%04d", 1000 + i))-\(String(format: "%04d", i))",
                mobile: "09\(String(format: "%02d", i % 100))-\(String(format: "%03d", i % 1000))-\(String(format: "%03d", (i * 7) % 1000))",
                fax: nil,
                address: nil,
                website: nil,
                memo: nil,
                photoPath: nil,
                createdAt: Date().addingTimeInterval(-Double(i * 3600)),
                updatedAt: Date().addingTimeInterval(-Double(i * 3600)),
                parseSource: sources[i % sources.count],
                parseConfidence: Double.random(in: 0.7...0.95),
                rawOCRText: nil
            )
            cards.append(card)
        }
        
        return cards
    }
}

// MARK: - Mock Images

/// 測試用圖片資源（僅包含測試必需的三種圖片）
struct MockImages {
    
    /// 建立測試用名片圖片
    private static func createTestImage(size: CGSize, backgroundColor: UIColor = .white) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 模擬中英混合名片內容
            let cardContent = [
                "王大明 David Wang",
                "ABC科技股份有限公司",
                "ABC Technology Co., Ltd.",
                "產品經理 Product Manager",
                "TEL: 02-1234-5678"
            ]
            
            let font = UIFont.systemFont(ofSize: 14)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            var yOffset: CGFloat = 20
            for text in cardContent {
                let textRect = CGRect(x: 20, y: yOffset, width: size.width - 40, height: 20)
                text.draw(in: textRect, withAttributes: attributes)
                yOffset += 25
            }
        }
    }
    
    /// 標準名片圖片 (400x250)
    static let standardImage = createTestImage(size: CGSize(width: 400, height: 250))
    
    /// 低品質圖片 (100x60)
    static let lowQualityImage = createTestImage(size: CGSize(width: 100, height: 60), backgroundColor: .lightGray)
    
    /// 高解析圖片 (1200x800)
    static let highResolutionImage = createTestImage(size: CGSize(width: 1200, height: 800))
}