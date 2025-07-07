//
//  OpenAIService.swift

//
//  Created by mike liu on 2025/6/25.
//
import Foundation
import Combine

class OpenAIService {
    private let keychainService: KeychainService
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session = URLSession.shared
    
    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }
    
    // MARK: - API Key Management
    
    func setAPIKey(_ key: String) {
        _ = keychainService.saveString(key, for: "openai_api_key")
    }
    
    func getAPIKey() -> String? {
        return keychainService.loadString(for: "openai_api_key")
    }
    
    func hasValidAPIKey() -> Bool {
        guard let key = getAPIKey(), !key.isEmpty else { return false }
        return key.hasPrefix("sk-") && key.count > 20
    }
    
    // MARK: - API Request
    
    func sendRequest(prompt: String, configuration: AIConfiguration = AIConfiguration()) -> AnyPublisher<AIResponse, Error> {
        guard let apiKey = getAPIKey(), hasValidAPIKey() else {
            return Fail(error: OpenAIError.missingAPIKey)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: baseURL) else {
            return Fail(error: OpenAIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        // 構建請求體
        let requestBody = OpenAIRequest(
            model: configuration.model,
            messages: [
                OpenAIMessage(role: "system", content: "你是一個專業的名片資訊解析助手。請將提供的OCR文字解析成結構化的JSON格式。"),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: configuration.temperature,
            maxTokens: configuration.maxTokens
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return Fail(error: OpenAIError.encodingError(error))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: AIResponse.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return OpenAIError.decodingError(error)
                } else if let urlError = error as? URLError {
                    return OpenAIError.networkError(urlError)
                } else {
                    return OpenAIError.unknownError(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Request Models

private struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Error Types

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case encodingError(Error)
    case decodingError(Error)
    case networkError(URLError)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API Key 未設定或格式不正確"
        case .invalidURL:
            return "無效的 API URL"
        case .encodingError(let error):
            return "請求編碼錯誤: \(error.localizedDescription)"
        case .decodingError(let error):
            return "回應解碼錯誤: \(error.localizedDescription)"
        case .networkError(let error):
            return "網路錯誤: \(error.localizedDescription)"
        case .unknownError(let error):
            return "未知錯誤: \(error.localizedDescription)"
        }
    }
}
