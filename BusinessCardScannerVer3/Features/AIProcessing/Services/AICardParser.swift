//
//  AICardParser.swift

//
//  Created by mike liu on 2025/6/25.
//

class AICardParser {
    private let openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    var isAvailable: Bool {
        // 實際實作會在 Task 6.2
        return false
    }
}
