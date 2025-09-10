//
//  TestBusinessCardService.swift
//  BusinessCardScannerVer3Tests
//
//  測試專用的 BusinessCardService，支援 Mock 依賴注入
//  暫時注釋掉，等待修復Mock類型問題
//

import Foundation
import Combine
import UIKit
@testable import BusinessCardScannerVer3

// 暫時注釋掉，因為Mock類型找不到的問題
// 需要確保所有Mock服務都正確編譯並包含在測試target中

/*
/// 測試專用的 BusinessCardService
/// 繼承真正的 BusinessCardService，但接受 Mock 依賴
final class TestBusinessCardService: BusinessCardService {
    // Mock 依賴和實作
}
*/