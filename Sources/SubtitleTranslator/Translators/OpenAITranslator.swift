//
//  OpenAITranslator.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//
import Foundation

struct OpenAITranslator: LLMTranslator {
    var name: String = "ChatGPT"
    private let apiKey: String
    private let apiEndpoint = "https://api.openai.com/v1/chat/completions"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func translate(text: String) async throws -> String {
      

        // 2️⃣ Build the messages array
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user",   "content": text]
        ]

        // 3️⃣ Construct the HTTP request
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // 4️⃣ Send and parse
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
