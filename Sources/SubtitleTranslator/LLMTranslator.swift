//
//  LLMTranslator.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//

import Foundation

// MARK: - LLMTranslator Protocol (Strategy Pattern)
protocol LLMTranslator {
    func translate(text: String) async throws -> String
    var name: String { get }
}
let systemPrompt = """
You are a translation assistant.
Your task is to translate the following English subtitles (in SRT format) into Bangla.

• Preserve the original SRT structure (numbering, timecodes, blank lines).
• Only replace the English text with its Bangla equivalent—do not alter times or sequence numbers.
• Keep line breaks as in the original.
• Ensure proper Bangla spelling and grammar.
• Keep each segment separated by "---" and maintain the same order.

Please output only the translated SRT content.
"""
