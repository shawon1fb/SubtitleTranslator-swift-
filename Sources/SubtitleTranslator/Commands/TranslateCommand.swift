//
//  TranslateCommand.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//

import Foundation
import ArgumentParser

//@main
struct TranslateCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "translate",
        abstract: "Translate .srt subtitle files from English to Bangla"
    )
    
    static var _commandName = "translate"
    
    @Option(name: .shortAndLong, help: "Input .srt file path")
    var input: String
    
    @Option(name: .shortAndLong, help: "Output .srt file path")
    var output: String
    
    @Option(name: .shortAndLong, help: "LLM provider (claude, chatgpt, ollama, deepseek)")
    var llm: String
    
    @Option(name: .shortAndLong, help: "API key for the selected LLM provider")
    var apiKey: String?
    
    @Option(name: .long, help: "Ollama API endpoint (default: http://localhost:11434)")
    var ollamaEndpoint: String = "http://localhost:11434"
    
    @Option(name: .long, help: "Ollama model to use (default: llama3)")
    var ollamaModel: String = "llama3.2:latest"
    
    mutating func run() async throws {
        let translator: LLMTranslator
        
        print("started")
        
        switch llm.lowercased() {
        case "claude":
            guard let apiKey = apiKey else {
                fatalError("API key is required for Claude")
            }
            translator = ClaudeTranslator(apiKey: apiKey)
        case "chatgpt":
            guard let apiKey = apiKey else {
                fatalError("API key is required for ChatGPT")
            }
            translator = OpenAITranslator(apiKey: apiKey)
        case "ollama":
            translator = OllamaTranslator(endpoint: ollamaEndpoint, model: ollamaModel)
        case "deepseek":
//            guard let apiKey = apiKey else {
//                fatalError("API key is required for DeepSeek")
//            }
           
            translator = DeepSeekTranslator(apiKey: apiKey ?? "sk_gtZWT71UYEtG-7eM2OBtnZXGG5_XdLYNRfPEeiqMmZ8")
        default:
            fatalError("Unsupported LLM provider: \(llm). Supported providers: claude, chatgpt, ollama, deepseek")
        }
        
        print("Starting translation using \(translator.name)...")
        
        // Read input file
        guard let fileContent = try? String(contentsOfFile: input) else {
            throw TranslationError.fileNotFound
        }
        
        // Parse SRT
        let subtitleTranslator = SubtitleTranslator(translator: translator)
        let entries = try subtitleTranslator.parseSrt(content: fileContent)
        
        print("Found \(entries.count) subtitle entries.")
        
        // Translate
        let translatedEntries = try await subtitleTranslator.translateSubtitles(entries: entries)
        
        // Generate output SRT
        let outputContent = subtitleTranslator.generateSrt(entries: translatedEntries)
        
        // Write to output file
        do {
            try outputContent.write(toFile: output, atomically: true, encoding: .utf8)
            print("Translation complete! Output written to \(output)")
        } catch {
            throw TranslationError.fileWriteError
        }
    }
}
