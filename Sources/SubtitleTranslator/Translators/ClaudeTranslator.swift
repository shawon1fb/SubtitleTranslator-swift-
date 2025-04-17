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
        // (Make sure to set anthropic-version to the correct API version string.)


        let requestBody: [String: Any] = [
            "model": "claude-3-7-sonnet-20250219",
            "max_tokens": 1000,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": text]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Claude returns a list of messages under "messages"
        if let messages = responseJSON["messages"] as? [[String: Any]],
           let last = messages.last,
           let content = last["content"] as? String {
            return content
        } else {
            throw TranslationError.apiResponseParsingError
        }
    }
}

