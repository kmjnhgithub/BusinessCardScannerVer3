//
//  MockAdapters.swift
//  BusinessCardScannerVer3Tests
//
//  已棄用：改用協議注入方式
//  此檔案包含實驗性的適配器實作，但由於 final 類別限制而不可行
//

import Foundation
import Combine
import UIKit
import CoreData
import Vision
@testable import BusinessCardScannerVer3

// 此檔案已棄用，因為：
// 1. BusinessCardRepository 等服務類別被標記為 final，無法繼承
// 2. 適配器模式在這種情況下變得過於複雜
// 3. 改用協議注入的方式更簡潔有效

// 保留此檔案以供參考，但不會被使用
// 實際的測試依賴注入在 TestBusinessCardService.swift 中實作