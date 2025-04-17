//
//  SubtitleEntry.swift
//  SubtitleTranslatorTests
//
//  Created by Shahanul Haque on 4/17/25.
//

import Foundation

struct SubtitleEntry: Identifiable, Hashable {
    let index: Int
    let timeCode: String
    let text: String

    // Identifiable conformance
    var id: Int { index }
}
