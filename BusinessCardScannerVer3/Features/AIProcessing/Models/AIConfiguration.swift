//
//  AIConfiguration.swift
//  
//
//

import Foundation

struct AIConfiguration {
    var apiKey: String?
    var model: String = "gpt-3.5-turbo"
    var temperature: Double = 0.3
    var maxTokens: Int = 500
}
