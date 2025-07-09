//
//  ExportService.swift
//  BusinessCardScannerVer3
//
//  名片匯出服務
//  位置：Features/Settings/Services/ExportService.swift
//

import UIKit
import Combine

/// 匯出錯誤類型
enum ExportError: Error, LocalizedError {
    case noData
    case createFileFailed
    case writeFileFailed
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "沒有可匯出的資料"
        case .createFileFailed:
            return "建立檔案失敗"
        case .writeFileFailed:
            return "寫入檔案失敗"
        }
    }
}

/// 名片欄位定義 - 集中管理匯出欄位
struct BusinessCardExportFields {
    
    /// CSV 匯出欄位配置
    static let csvFields: [(key: String, displayName: String)] = [
        ("name", "姓名"),
        ("jobTitle", "職稱"),
        ("company", "公司"),
        ("department", "部門"),
        ("phone", "電話"),
        ("mobile", "手機"),
        ("fax", "傳真"),
        ("email", "Email"),
        ("address", "地址"),
        ("website", "網站"),
        ("memo", "備註"),
        ("createdAt", "建立時間")
    ]
    
    /// 取得指定欄位的值
    static func getValue(from card: BusinessCard, for key: String) -> String {
        switch key {
        case "name": return card.name
        case "jobTitle": return card.jobTitle ?? ""
        case "company": return card.company ?? ""
        case "department": return card.department ?? ""
        case "phone": return card.phone ?? ""
        case "mobile": return card.mobile ?? ""
        case "fax": return card.fax ?? ""
        case "email": return card.email ?? ""
        case "address": return card.address ?? ""
        case "website": return card.website ?? ""
        case "memo": return card.memo ?? ""
        case "createdAt": return formatDate(card.createdAt)
        default: return ""
        }
    }
    
    /// 格式化日期
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
}

/// 名片匯出服務
class ExportService {
    
    private let fileManager = FileManager.default
    
    /// 匯出名片為 CSV 格式
    func exportAsCSV(cards: [BusinessCard]) -> AnyPublisher<URL, ExportError> {
        return Future<URL, ExportError> { [weak self] promise in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let self = self else {
                    promise(.failure(.createFileFailed))
                    return
                }
                
                guard !cards.isEmpty else {
                    promise(.failure(.noData))
                    return
                }
                
                // 建立 CSV 內容
                let headers = BusinessCardExportFields.csvFields.map { $0.displayName }
                var csvContent = headers.joined(separator: ",") + "\n"
                
                for card in cards {
                    let row = BusinessCardExportFields.csvFields.map { fieldKey, _ in
                        self.csvEscape(BusinessCardExportFields.getValue(from: card, for: fieldKey))
                    }
                    csvContent += row.joined(separator: ",") + "\n"
                }
                
                // 儲存檔案
                let fileName = self.generateFileName(extension: "csv")
                guard let fileURL = self.getExportFileURL(fileName: fileName) else {
                    promise(.failure(.createFileFailed))
                    return
                }
                
                do {
                    try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
                    DispatchQueue.main.async {
                        promise(.success(fileURL))
                    }
                } catch {
                    DispatchQueue.main.async {
                        promise(.failure(.writeFileFailed))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 匯出名片為 VCF 格式
    func exportAsVCard(cards: [BusinessCard]) -> AnyPublisher<URL, ExportError> {
        return Future<URL, ExportError> { [weak self] promise in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let self = self else {
                    promise(.failure(.createFileFailed))
                    return
                }
                
                guard !cards.isEmpty else {
                    promise(.failure(.noData))
                    return
                }
                
                // 建立 VCF 內容
                var vcfContent = ""
                
                for card in cards {
                    vcfContent += "BEGIN:VCARD\n"
                    vcfContent += "VERSION:3.0\n"
                    vcfContent += "FN:\(card.name)\n"
                    vcfContent += "N:\(card.name);;;;\n"
                    
                    if let company = card.company, !company.isEmpty {
                        vcfContent += "ORG:\(company)\n"
                    }
                    
                    if let jobTitle = card.jobTitle, !jobTitle.isEmpty {
                        vcfContent += "TITLE:\(jobTitle)\n"
                    }
                    
                    if let phone = card.phone, !phone.isEmpty {
                        vcfContent += "TEL;TYPE=WORK:\(phone)\n"
                    }
                    
                    if let mobile = card.mobile, !mobile.isEmpty {
                        vcfContent += "TEL;TYPE=CELL:\(mobile)\n"
                    }
                    
                    if let email = card.email, !email.isEmpty {
                        vcfContent += "EMAIL:\(email)\n"
                    }
                    
                    if let address = card.address, !address.isEmpty {
                        vcfContent += "ADR;TYPE=WORK:;;\(address);;;;\n"
                    }
                    
                    if let website = card.website, !website.isEmpty {
                        vcfContent += "URL:\(website)\n"
                    }
                    
                    vcfContent += "END:VCARD\n\n"
                }
                
                // 儲存檔案
                let fileName = self.generateFileName(extension: "vcf")
                guard let fileURL = self.getExportFileURL(fileName: fileName) else {
                    promise(.failure(.createFileFailed))
                    return
                }
                
                do {
                    try vcfContent.write(to: fileURL, atomically: true, encoding: .utf8)
                    DispatchQueue.main.async {
                        promise(.success(fileURL))
                    }
                } catch {
                    DispatchQueue.main.async {
                        promise(.failure(.writeFileFailed))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
    
    
    private func generateFileName(extension ext: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        return "名片資料_\(dateString).\(ext)"
    }
    
    private func getExportFileURL(fileName: String) -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let exportsDirectory = documentsDirectory.appendingPathComponent("exports")
        
        do {
            try fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        
        return exportsDirectory.appendingPathComponent(fileName)
    }
}
