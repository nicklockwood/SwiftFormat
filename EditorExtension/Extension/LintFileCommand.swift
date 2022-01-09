//
//  LintFileCommand.swift
//  Editor Extension
//
//  Created by Nick Lockwood on 06/01/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation
import XcodeKit

class LintFileCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard SupportedContentUTIs.contains(invocation.buffer.contentUTI) else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        // Grab the selected source to format
        let sourceToFormat = invocation.buffer.completeBuffer
        let input = tokenize(sourceToFormat)

        let projectConfigurationFinder = ProjectConfigurationFinder()
        projectConfigurationFinder.findProjectOptions { projectSpecificOptions in
            let rules: [FormatRule]
            var formatOptions: FormatOptions

            if let options = projectSpecificOptions {
                rules = (options.rules).map(Array.init).flatMap(FormatRules.named) ?? FormatRules.default
                formatOptions = options.formatOptions ?? .default
            } else {
                // Get rules
                rules = FormatRules.named(RulesStore().rules.compactMap {
                    $0.isEnabled ? $0.name : nil
                })

                // Get options
                let store = OptionsStore()
                formatOptions = store.inferOptions ? inferFormatOptions(from: input) : store.formatOptions
                formatOptions.indent = invocation.buffer.indentationString
                formatOptions.tabWidth = invocation.buffer.tabWidth
                formatOptions.swiftVersion = store.formatOptions.swiftVersion
            }

            // Apply linting
            do {
                let changes = try lint(input, rules: rules, options: formatOptions)
                if !changes.isEmpty {
                    return completionHandler(FormatCommandError.lintWarnings(changes))
                }
                return completionHandler(nil)
            } catch {
                return completionHandler(error)
            }
        }
    }
}
