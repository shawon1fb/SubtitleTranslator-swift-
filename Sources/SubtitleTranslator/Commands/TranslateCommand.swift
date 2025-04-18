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
    
    @Option(name: .shortAndLong, help: "Output .srt file path (optional, defaults to [input-name].bn.srt)")
    var output: String?
    
    @Option(name: .shortAndLong, help: "LLM provider (claude, chatgpt, ollama, deepseek)")
    var llm: String?
    
    @Option(name: .shortAndLong, help: "API key for the selected LLM provider")
    var apiKey: String?
    
    @Option(name: .long, help: "Ollama API endpoint (default: http://localhost:11434)")
    var ollamaEndpoint: String?
    
    @Option(name: .long, help: "Ollama model to use (default: llama3)")
    var ollamaModel: String?
    
    mutating func run() async throws {
        // Load configuration
        let configManager = ConfigurationManager()
        
        // Apply configuration values as defaults
        let llmProvider = llm ?? configManager.getValue(key: "llm") ?? "ollama"
        let apiKeyValue = apiKey ?? configManager.getValue(key: "apiKey")
        let ollamaEndpointValue = ollamaEndpoint ?? configManager.getValue(key: "ollamaEndpoint") ?? "http://localhost:11434"
        let ollamaModelValue = ollamaModel ?? configManager.getValue(key: "ollamaModel") ?? "llama3.2:latest"
        
        let translator: LLMTranslator
        
        print("Started translation with \(llmProvider)")
        
        switch llmProvider.lowercased() {
        case "claude":
            guard let apiKey = apiKeyValue else {
                fatalError("API key is required for Claude. Set it with --api-key or using the config command.")
            }
            translator = ClaudeTranslator(apiKey: apiKey)
        case "chatgpt":
            guard let apiKey = apiKeyValue else {
                fatalError("API key is required for ChatGPT. Set it with --api-key or using the config command.")
            }
            translator = OpenAITranslator(apiKey: apiKey)
        case "ollama":
            translator = OllamaTranslator(endpoint: ollamaEndpointValue, model: ollamaModelValue)
        case "deepseek":
            guard let apiKey = apiKeyValue else {
                fatalError("API key is required for DeepSeek. Set it with --api-key or using the config command.")
            }
            translator = DeepSeekTranslator(apiKey: apiKey)
        default:
            fatalError("Unsupported LLM provider: \(llmProvider). Supported providers: claude, chatgpt, ollama, deepseek")
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
        
        // Determine the output file path
        let outputPath: String
        if let outputSpecified = output {
            outputPath = outputSpecified
        } else {
            // Get the input file name without extension
            let inputURL = URL(fileURLWithPath: input)
            let fileName = inputURL.deletingPathExtension().lastPathComponent
            
            // Check if there's a default output directory configured
            if let outputDir = configManager.getValue(key: "outputDir") {
                outputPath = "\(outputDir)/\(fileName).bn.srt"
            } else {
                let directory = inputURL.deletingLastPathComponent().path
                outputPath = "\(directory)/\(fileName).bn.srt"
            }
        }
        
        // Write to output file
        do {
            // Create directory if it doesn't exist
            let outputURL = URL(fileURLWithPath: outputPath)
            try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            
            try outputContent.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Translation complete! Output written to \(outputPath)")
        } catch {
            throw TranslationError.fileWriteError
        }
    }
}
