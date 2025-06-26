//
//  AIResponse.swift
//  BusinessCardScannerVer3
//
//  Created by mike liu on 2025/6/25.
//

import Foundation

struct AIResponse {
    let id: String
    let model: String
    let choices: [Choice]
    let usage: TokenUsage
    
    struct Choice {
        let message: Message
        let finishReason: String
    }
    
    struct Message {
        let role: String
        let content: String
    }
}
