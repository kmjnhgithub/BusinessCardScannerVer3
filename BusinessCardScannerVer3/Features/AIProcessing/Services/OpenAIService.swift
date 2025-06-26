//
//  OpenAIService.swift

//
//  Created by mike liu on 2025/6/25.
//
import UIKit

class OpenAIService {
    private let keychainService: KeychainService
    
    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }
    
    func setAPIKey(_ key: String) {
        _ = keychainService.saveString(key, for: "openai_api_key")
    }
}
