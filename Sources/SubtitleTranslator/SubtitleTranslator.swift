import Foundation

class SubtitleTranslator {
    private let translator: LLMTranslator
    private let batchSize = 80
    private let maxRetries = 3
    private let checkpointFile: String
    
    init(translator: LLMTranslator, checkpointFile: String = "translation_checkpoint.json") {
        self.translator = translator
        self.checkpointFile = checkpointFile
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
        var lastSuccessfulBatchIndex = -1
        
        // Try to load checkpoint if exists
        if let checkpoint = loadCheckpoint() {
            translatedEntries = checkpoint.entries
            lastSuccessfulBatchIndex = checkpoint.lastBatchIndex
            print("Resuming translation from batch \(lastSuccessfulBatchIndex + 1)")
        }
        
        let totalBatches = Int(ceil(Double(entries.count) / Double(batchSize)))
        
        for batchIndex in (lastSuccessfulBatchIndex + 1)..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, entries.count)
            let batch = Array(entries[startIndex..<endIndex])
            
            print("Translating batch \(batchIndex + 1)/\(totalBatches) (entries \(startIndex + 1)-\(endIndex))...")
            
            // Retry logic
            var retryCount = 0
            var batchTranslated = false
            var batchTranslatedEntries: [SubtitleEntry] = []
            
            while !batchTranslated && retryCount <= maxRetries {
                do {
                    if retryCount > 0 {
                        print("Retry attempt \(retryCount)/\(maxRetries) for batch \(batchIndex + 1)...")
                    }
                    
                    let batchText = batch.map { $0.text }.joined(separator: "\n\n---\n\n")
                    let translatedBatchText = try await translator.translate(text: batchText)
                    
                    // Split the translated text back into individual entries
                    let translatedTexts = translatedBatchText.components(separatedBy: "\n\n---\n\n")
                    
                    guard translatedTexts.count == batch.count else {
                        print("Translation mismatch: expected \(batch.count) entries, received \(translatedTexts.count)")
                        print("Translated batch text sample: \(String(translatedBatchText.prefix(200)))...")
                        throw TranslationError.batchTranslationMismatch(
                            expected: batch.count,
                            received: translatedTexts.count
                        )
                    }
                    
                    batchTranslatedEntries = zip(batch, translatedTexts).map { entry, translatedText in
                        SubtitleEntry(
                            index: entry.index,
                            timeCode: entry.timeCode,
                            text: translatedText
                        )
                    }
                    
                    batchTranslated = true
                } catch {
                    retryCount += 1
                    if retryCount > maxRetries {
                        print("Failed to translate batch \(batchIndex + 1) after \(maxRetries) retries")
                        throw error
                    }
                    print("Translation error: \(error). Retrying...")
                    // Add a small delay before retrying
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                }
            }
            
            // Add successfully translated entries
            translatedEntries.append(contentsOf: batchTranslatedEntries)
            
            // Save checkpoint after each successful batch
            saveCheckpoint(entries: translatedEntries, lastBatchIndex: batchIndex)
            print("Checkpoint saved after batch \(batchIndex + 1)")
        }
        
        // Clear checkpoint file after successful completion
        try? FileManager.default.removeItem(atPath: checkpointFile)
        print("Translation completed successfully, checkpoint cleared")
        
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
    
    // MARK: - Checkpoint Management
    
    private struct TranslationCheckpoint: Codable {
        let entries: [SubtitleEntry]
        let lastBatchIndex: Int
    }
    
    private func saveCheckpoint(entries: [SubtitleEntry], lastBatchIndex: Int) {
        let checkpoint = TranslationCheckpoint(entries: entries, lastBatchIndex: lastBatchIndex)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(checkpoint)
            try data.write(to: URL(fileURLWithPath: checkpointFile))
        } catch {
            print("Warning: Failed to save checkpoint: \(error)")
        }
    }
    
    private func loadCheckpoint() -> TranslationCheckpoint? {
        guard FileManager.default.fileExists(atPath: checkpointFile) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: checkpointFile))
            let decoder = JSONDecoder()
            return try decoder.decode(TranslationCheckpoint.self, from: data)
        } catch {
            print("Warning: Failed to load checkpoint: \(error)")
            return nil
        }
    }
}
