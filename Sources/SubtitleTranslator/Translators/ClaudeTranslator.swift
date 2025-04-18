//
//  ClaudeTranslator.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//
import Foundation
struct ClaudeTranslator: LLMTranslator {
    var name: String = "Claude"
    private let apiKey: String
    private let apiEndpoint = "https://api.anthropic.com/v1/messages"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func translate(text: String) async throws -> String {
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let requestBody: [String: Any] = [
//            "model": "claude-3-7-sonnet-20250219",
            "model": "claude-3-haiku-20240307",
            "max_tokens": 4000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Claude returns the content in the response object
        if let content = responseJSON["content"] as? [[String: Any]],
           let firstContent = content.first,
           let text = firstContent["text"] as? String {
            return text
        } else {
            throw TranslationError.apiResponseParsingError
        }
    }
}
