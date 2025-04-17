//
//  TranslationError.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//

import Foundation

// MARK: - Errors
enum TranslationError: Error {
    case apiResponseParsingError
    case invalidSrtFormat
    case fileNotFound
    case fileWriteError
    case batchTranslationMismatch(expected: Int, received: Int)
    case custom(String)
}
struct MissingAPIKeyError: Error, CustomStringConvertible {
    let provider: String
    var description: String { "🔴 API key required for \(provider). Use --api-key option" }
}

struct FileNotFoundError: Error, CustomStringConvertible {
    let filename: String
    var description: String { "🔴 File not found: \(filename)" }
}
