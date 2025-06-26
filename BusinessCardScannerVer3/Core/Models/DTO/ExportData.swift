//
//  Untitled.swift
//  BusinessCardScannerVer3
//
//  Created by mike liu on 2025/6/25.
//

import Foundation

struct ExportData {
    let cards: [BusinessCard]
    let format: ExportFormat
    let includePhotos: Bool
}

enum ExportFormat {
    case csv
    case vCard
}
