//
//  DeepSeekTranslator.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//
import Foundation

struct DeepSeekTranslator: LLMTranslator {
    var name: String = "DeepSeek"
    private let apiKey: String
//    private let apiEndpoint = "https://api.deepseek.com/v1/chat/completions"
    private let apiEndpoint = "https://api.novita.ai/v3/openai/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func translate(text: String) async throws -> String {
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120
        
        // A more explicit “system” prompt to steer the model
       
        
        let requestBody: [String: Any] = [
//            "model": "deepseek-chat",
//            "model": "deepseek/deepseek-v3-0324",
//            "model": "meta-llama/llama-4-scout-17b-16e-instruct",
//            "model": "google/gemma-3-27b-it",
//            "model": "deepseek/deepseek-r1-turbo",
//            "model": "qwen/qwen2.5-vl-72b-instruct",
            "model": "deepseek/deepseek-v3-turbo",
            
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": text
                ]
            ],
            "response_format": [ "type": "text" ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        if let choices = responseJSON["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            throw TranslationError.apiResponseParsingError
        }
    }
}
