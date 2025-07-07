//
//  AIResponse.swift

//
//  Created by mike liu on 2025/6/25.
//

import Foundation

struct AIResponse: Codable {
    let id: String
    let model: String
    let choices: [Choice]
    let usage: TokenUsage
    
    struct Choice: Codable {
        let message: Message
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}
