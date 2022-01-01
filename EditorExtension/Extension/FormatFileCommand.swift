//
//  FormatFileCommand.swift
//  Swift Formatter
//
//  Created by Tony Arnold on 5/10/16.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import XcodeKit

class FormatFileCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard SupportedContentUTIs.contains(invocation.buffer.contentUTI) else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        // Grab the file source to format
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
                rules = FormatRules.named(RulesStore().rules.compactMap { $0.isEnabled ? $0.name : nil })

                // Get options
                let store = OptionsStore()
                formatOptions = store.inferOptions ? inferFormatOptions(from: input) : store.formatOptions
                formatOptions.indent = invocation.buffer.indentationString
                formatOptions.tabWidth = invocation.buffer.tabWidth
                formatOptions.swiftVersion = store.formatOptions.swiftVersion
            }
            if formatOptions.requiresFileInfo {
                formatOptions.fileHeader = .ignore
            }

            let output: [Token]
            do {
                output = try format(input, rules: rules, options: formatOptions)
            } catch {
                return completionHandler(error)
            }
            if output == input {
                // No changes needed
                return completionHandler(nil)
            }

            // Remove all selections to avoid a crash when changing the contents of the buffer.
            let selections = invocation.buffer.selections.compactMap { $0 as? XCSourceTextRange }
            invocation.buffer.selections.removeAllObjects()

            // Update buffer
            invocation.buffer.completeBuffer = sourceCode(for: output)

            // Restore selections
            for selection in selections {
                invocation.buffer.selections.add(XCSourceTextRange(
                    start: invocation.buffer.newPosition(for: selection.start, in: output),
                    end: invocation.buffer.newPosition(for: selection.end, in: output)
                ))
            }

            return completionHandler(nil)
        }
    }
}
