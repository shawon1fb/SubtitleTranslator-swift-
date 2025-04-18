//
//  ConfigCommand.swift
//  SubtitleTranslator
//
//  Created by Shahanul Haque on 4/18/25.
//

import Foundation
import ArgumentParser

struct ConfigCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Configure default settings for the subtitle translator"
    )
    
    @Flag(name: .long, help: "View current configuration")
    var view: Bool = false
    
    @Flag(name: .long, help: "Clear all configuration")
    var clear: Bool = false
    
    @Flag(name: .long, help: "Set configuration interactively")
    var interactive: Bool = false
    
    // Still allow direct setting for automation/scripting
    @Option(name: .shortAndLong, help: "Default LLM provider (claude, chatgpt, ollama, deepseek)")
    var llm: String?
    
    @Option(name: .shortAndLong, help: "Default API key for the selected LLM provider")
    var apiKey: String?
    
    @Option(name: .long, help: "Default Ollama API endpoint")
    var ollamaEndpoint: String?
    
    @Option(name: .long, help: "Default Ollama model to use")
    var ollamaModel: String?
    
    @Option(name: .long, help: "Default output directory")
    var outputDir: String?
    
    func run() throws {
        let configManager = ConfigurationManager()
        
        if view {
            displayCurrentConfig(configManager)
            return
        }
        
        if clear {
            try configManager.clearConfiguration()
            print("Configuration cleared successfully.")
            return
        }
        
        if interactive {
            try runInteractiveConfig(configManager)
            return
        }
        
        var updatedConfig = false
        
        if let llm = llm {
            try configManager.setValue(key: "llm", value: llm)
            print("Default LLM provider set to: \(llm)")
            updatedConfig = true
        }
        
        if let apiKey = apiKey {
            try configManager.setValue(key: "apiKey", value: apiKey)
            print("Default API key saved.")
            updatedConfig = true
        }
        
        if let ollamaEndpoint = ollamaEndpoint {
            try configManager.setValue(key: "ollamaEndpoint", value: ollamaEndpoint)
            print("Default Ollama endpoint set to: \(ollamaEndpoint)")
            updatedConfig = true
        }
        
        if let ollamaModel = ollamaModel {
            try configManager.setValue(key: "ollamaModel", value: ollamaModel)
            print("Default Ollama model set to: \(ollamaModel)")
            updatedConfig = true
        }
        
        if let outputDir = outputDir {
            try configManager.setValue(key: "outputDir", value: outputDir)
            print("Default output directory set to: \(outputDir)")
            updatedConfig = true
        }
        
        if !updatedConfig && !view && !clear && !interactive {
            print("No configuration changes made. Use --interactive for guided setup or --view to see current configuration.")
        }
    }
    
    private func runInteractiveConfig(_ configManager: ConfigurationManager) throws {
        print("Interactive Configuration Setup")
        print("=============================")
        
        // Configure LLM provider
        let llmOptions = ["ollama", "claude", "chatgpt", "deepseek"]
        let llmProvider = promptForChoice(
            prompt: "Select LLM provider:",
            options: llmOptions,
            defaultValue: configManager.getValue(key: "llm") ?? "ollama"
        )
        try configManager.setValue(key: "llm", value: llmProvider)
        
        // Configure API key if needed
        if llmProvider != "ollama" {
            let currentApiKey = configManager.getValue(key: "apiKey")
            let maskKey = currentApiKey != nil ? String(repeating: "*", count: min(currentApiKey!.count, 8)) : "not set"
            
            print("\nAPI key is required for \(llmProvider)")
            print("Current API key: \(maskKey)")
            if promptYesNo(prompt: "Do you want to update the API key?", defaultValue: currentApiKey == nil) {
                print("Enter API key for \(llmProvider):")
                if let apiKey = readSecureLine() {
                    try configManager.setValue(key: "apiKey", value: apiKey)
                    print("API key updated.")
                }
            }
        }
        
        // Configure Ollama settings if selected
        if llmProvider == "ollama" {
            let defaultEndpoint = configManager.getValue(key: "ollamaEndpoint") ?? "http://localhost:11434"
            print("\nConfigure Ollama settings:")
            print("Enter Ollama API endpoint (press Enter for \(defaultEndpoint)):")
            if let endpoint = readLine(), !endpoint.isEmpty {
                try configManager.setValue(key: "ollamaEndpoint", value: endpoint)
            } else if configManager.getValue(key: "ollamaEndpoint") == nil {
                try configManager.setValue(key: "ollamaEndpoint", value: defaultEndpoint)
            }
            
            let defaultModel = configManager.getValue(key: "ollamaModel") ?? "llama3.2:latest"
            print("Enter Ollama model (press Enter for \(defaultModel)):")
            if let model = readLine(), !model.isEmpty {
                try configManager.setValue(key: "ollamaModel", value: model)
            } else if configManager.getValue(key: "ollamaModel") == nil {
                try configManager.setValue(key: "ollamaModel", value: defaultModel)
            }
        }
        
        // Configure output directory
        let defaultOutputDir = configManager.getValue(key: "outputDir") ?? "Same as input file"
        print("\nEnter default output directory (press Enter for \(defaultOutputDir)):")
        if let outputDir = readLine(), !outputDir.isEmpty {
            // Expand ~ to home directory if present
            let expandedPath: String
            if outputDir.starts(with: "~") {
                let homePath = FileManager.default.homeDirectoryForCurrentUser.path
                expandedPath = outputDir.replacingOccurrences(of: "~", with: homePath)
            } else {
                expandedPath = outputDir
            }
            
            // Verify the directory exists or create it
            if !FileManager.default.fileExists(atPath: expandedPath) {
                if promptYesNo(prompt: "Directory doesn't exist. Create it?", defaultValue: true) {
                    try FileManager.default.createDirectory(
                        at: URL(fileURLWithPath: expandedPath),
                        withIntermediateDirectories: true
                    )
                    print("Directory created.")
                } else {
                    print("Directory not created. Configuration will still be saved.")
                }
            }
            
            try configManager.setValue(key: "outputDir", value: expandedPath)
        } else if configManager.getValue(key: "outputDir") == nil && defaultOutputDir != "Same as input file" {
            try configManager.setValue(key: "outputDir", value: defaultOutputDir)
        }
        
        print("\nConfiguration complete!")
        displayCurrentConfig(configManager)
    }
    
    private func displayCurrentConfig(_ configManager: ConfigurationManager) {
        print("Current Configuration:")
        print("---------------------")
        
        let llm = configManager.getValue(key: "llm") ?? "Not set (defaults to ollama)"
        print("LLM Provider: \(llm)")
        
        if let apiKey = configManager.getValue(key: "apiKey") {
            print("API Key: \(String(repeating: "*", count: min(apiKey.count, 8)))")
        } else {
            print("API Key: Not set")
        }
        
        let ollamaEndpoint = configManager.getValue(key: "ollamaEndpoint") ?? "Not set (defaults to http://localhost:11434)"
        print("Ollama Endpoint: \(ollamaEndpoint)")
        
        let ollamaModel = configManager.getValue(key: "ollamaModel") ?? "Not set (defaults to llama3.2:latest)"
        print("Ollama Model: \(ollamaModel)")
        
        let outputDir = configManager.getValue(key: "outputDir") ?? "Not set (defaults to same directory as input)"
        print("Output Directory: \(outputDir)")
    }
    
    // Helper functions for interactive prompts
    
    private func promptForChoice(prompt: String, options: [String], defaultValue: String? = nil) -> String {
        print(prompt)
        
        for (index, option) in options.enumerated() {
            let indicator = option == defaultValue ? " (default)" : ""
            print("\(index + 1). \(option)\(indicator)")
        }
        
        var selection: Int?
        repeat {
            print("Enter your choice (1-\(options.count)):")
            guard let input = readLine() else {
                if let defaultValue = defaultValue, options.contains(defaultValue) {
                    return defaultValue
                }
                continue
            }
            
            // Empty input means use default
            if input.isEmpty, let defaultValue = defaultValue, options.contains(defaultValue) {
                return defaultValue
            }
            
            // Parse numeric choice
            if let choice = Int(input), choice >= 1, choice <= options.count {
                selection = choice - 1
            } else {
                // Check if user typed the option name directly
                if options.contains(input.lowercased()) {
                    return input.lowercased()
                }
                print("Invalid selection. Please try again.")
            }
        } while selection == nil
        
        return options[selection!]
    }
    
    private func promptYesNo(prompt: String, defaultValue: Bool = true) -> Bool {
        let defaultOption = defaultValue ? "Y/n" : "y/N"
        repeat {
            print("\(prompt) [\(defaultOption)]:")
            guard let input = readLine()?.lowercased() else {
                return defaultValue
            }
            
            if input.isEmpty {
                return defaultValue
            }
            
            if input.starts(with: "y") {
                return true
            }
            
            if input.starts(with: "n") {
                return false
            }
            
            print("Please answer 'y' or 'n'.")
        } while true
    }
    
    private func readSecureLine() -> String? {
        // This is a simple implementation since Swift command-line tools
        // don't have a built-in secure input method
        // In a production app, you might want to use a C function like getpass()
        return readLine()
    }
}
class ConfigurationManager {
    private let configDirectory: URL
    private let configFile: URL
    private var configuration: [String: String] = [:]
    
    init() {
        let fileManager = FileManager.default
        
        // Get user's home directory
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        
        // Create .subtranslator directory if it doesn't exist
        configDirectory = homeDirectory.appendingPathComponent(".subtranslator")
        
        if !fileManager.fileExists(atPath: configDirectory.path) {
            try? fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        }
        
        configFile = configDirectory.appendingPathComponent("config.json")
        loadConfiguration()
    }
    
    private func loadConfiguration() {
        if FileManager.default.fileExists(atPath: configFile.path) {
            do {
                let data = try Data(contentsOf: configFile)
                configuration = try JSONDecoder().decode([String: String].self, from: data)
            } catch {
                print("Error loading configuration: \(error.localizedDescription)")
                configuration = [:]
            }
        }
    }
    
    private func saveConfiguration() throws {
        let data = try JSONEncoder().encode(configuration)
        try data.write(to: configFile)
    }
    
    func getValue(key: String) -> String? {
        return configuration[key]
    }
    
    func setValue(key: String, value: String) throws {
        configuration[key] = value
        try saveConfiguration()
    }
    
    func clearConfiguration() throws {
        configuration = [:]
        try saveConfiguration()
    }
}
