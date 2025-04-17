//
//  OllamaTranslator.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//
import Foundation

struct OllamaTranslator: LLMTranslator {
    var name: String = "Ollama"
    private let endpoint: String
    private let model: String

    init(endpoint: String, model: String = "llama3.2:latest") {
        self.endpoint = endpoint
        self.model = model
    }

    func translate(text: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(endpoint)/api/generate")!)
        request.timeoutInterval = 60
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // A clear “system” prompt to steer the model
     

        // Prepend the instructions to the user text
        let fullPrompt = systemPrompt + "\n\n" + text

        let requestBody: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": false
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        if let response = responseJSON["response"] as? String {
            return response
        } else {
            throw TranslationError.apiResponseParsingError
        }
    }
}
