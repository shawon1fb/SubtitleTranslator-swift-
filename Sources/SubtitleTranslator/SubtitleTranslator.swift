//
//  SubtitleTranslator.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//

import Foundation
class SubtitleTranslator {
    private let translator: LLMTranslator
    private let batchSize = 80
    
    init(translator: LLMTranslator) {
        self.translator = translator
    }
    
    func parseSrt(content: String) throws -> [SubtitleEntry] {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let blocks = normalized.components(separatedBy: "\n\n")
        var entries: [SubtitleEntry] = []
        
        for block in blocks {
            let lines = block
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            guard lines.count >= 3,
                  let idx = Int(lines[0]) else {
                continue
            }
            
            let timeCode = lines[1]
            let textLines = lines[2...]
            let text = textLines.joined(separator: "\n")
            
            entries.append(SubtitleEntry(index: idx, timeCode: timeCode, text: text))
        }
        
        return entries
    }
    
    func translateSubtitles(entries: [SubtitleEntry]) async throws -> [SubtitleEntry] {
        var translatedEntries: [SubtitleEntry] = []
        let totalBatches = Int(ceil(Double(entries.count) / Double(batchSize)))
        
        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, entries.count)
            let batch = Array(entries[startIndex..<endIndex])
            
            print("Translating batch \(batchIndex + 1)/\(totalBatches) (entries \(startIndex + 1)-\(endIndex))...")
            
            let batchText = batch.map { $0.text }.joined(separator: "\n\n---\n\n")
            let translatedBatchText = try await translator.translate(text: batchText)
            
            // Split the translated text back into individual entries
            let translatedTexts = translatedBatchText.components(separatedBy: "\n\n---\n\n")
            
            guard translatedTexts.count == batch.count else {
                print("translatedBatchText is \n \(translatedBatchText)")
                throw TranslationError.batchTranslationMismatch(
                    expected: batch.count,
                    received: translatedTexts.count
                )
            }
            
            for (i, entry) in batch.enumerated() {
                translatedEntries.append(SubtitleEntry(
                    index: entry.index,
                    timeCode: entry.timeCode,
                    text: translatedTexts[i]
                ))
            }
        }
        
        return translatedEntries
    }
    
    func generateSrt(entries: [SubtitleEntry]) -> String {
        var result = ""
        
        for entry in entries {
            result += "\(entry.index)\n"
            result += "\(entry.timeCode)\n"
            result += "\(entry.text)\n\n"
        }
        
        return result
    }
}

