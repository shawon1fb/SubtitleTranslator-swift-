//
import Foundation
import ArgumentParser

@main
struct SubtitleTranslatorApp: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "SubtitleTranslator",
        abstract: "A tool for translating subtitle files from English to Bangla",
        subcommands: [TranslateCommand.self]
    )
}
