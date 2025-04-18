import Foundation
import ArgumentParser

@main
struct SubtitleTranslatorApp: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "SubtitleTranslator",
        abstract: "A tool for translating subtitle files from English to Bangla",
        subcommands: [TranslateCommand.self, ConfigCommand.self],
        defaultSubcommand: TranslateCommand.self
    )
    
//    static func main() {
//        let args = CommandLine.arguments
//        
//        // If only the command itself is provided with no arguments, run interactive config
//        if args.count == 1 {
//            do {
//                var configCommand = ConfigCommand()
//                configCommand.interactive = true
//                try configCommand.run()
//            } catch {
//                print("Error running configuration: \(error.localizedDescription)")
//                // Use exit(withError:) from the ArgumentParser itself
//                SubtitleTranslatorApp.exit(withError: error)
//            }
//        } else {
//            // Otherwise, proceed with normal argument parsing
//            do {
//                var command = try SubtitleTranslatorApp.parseAsRoot()
//                try command.run()
//            } catch {
//                SubtitleTranslatorApp.exit(withError: error)
//            }
//        }
//    }
}
