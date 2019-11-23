//
//  FormatSelectedSourceCommand.swift
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

class FormatSelectedSourceCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation,
                 completionHandler: @escaping (Error?) -> Void) {
        guard SupportedContentUTIs.contains(invocation.buffer.contentUTI) else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            return completionHandler(FormatCommandError.noSelection)
        }

        // Inspect the whole file to infer the format options
        let store = OptionsStore()
        let tokens = tokenize(invocation.buffer.completeBuffer)
        var formatOptions = store.inferOptions ? inferFormatOptions(from: tokens) : store.formatOptions
        formatOptions.indent = indentationString(for: invocation.buffer)
        formatOptions.tabWidth = invocation.buffer.tabWidth
        formatOptions.fragment = true

        // Grab the selected source to format using entire lines of text
        let selectionRange = selection.start.line ... min(selection.end.line, invocation.buffer.lines.count - 1)
        let sourceToFormat = selectionRange.flatMap {
            (invocation.buffer.lines[$0] as? String).map { [$0] } ?? []
        }.joined()

        do {
            let rules = FormatRules.named(RulesStore()
                .rules
                .filter { $0.isEnabled }
                .map { $0.name })

            let formattedSource = try format(sourceToFormat, rules: rules, options: formatOptions)
            if formattedSource == sourceToFormat {
                // No changes needed
                return completionHandler(nil)
            }

            // Remove all selections to avoid a crash when changing the contents of the buffer.
            invocation.buffer.selections.removeAllObjects()
            invocation.buffer.lines.removeObjects(in: NSMakeRange(selection.start.line, selectionRange.count))
            invocation.buffer.lines.insert(formattedSource, at: selection.start.line)

            let updatedSelectionRange = rangeForDifferences(
                in: selection, between: sourceToFormat, and: formattedSource
            )

            invocation.buffer.selections.add(updatedSelectionRange)

            return completionHandler(nil)
        } catch {
            return completionHandler(error)
        }
    }

    /// Given a source text range, an original source string and a modified target string this
    /// method will calculate the differences, and return a usable XCSourceTextRange based upon the original.
    ///
    /// - Parameters:
    ///   - textRange: Existing source text range
    ///   - sourceText: Original text
    ///   - targetText: Modified text
    /// - Returns: Source text range that should be usable with the passed modified text
    private func rangeForDifferences(in textRange: XCSourceTextRange,
                                     between _: String, and targetText: String) -> XCSourceTextRange {
        // Ensure that we're not greedy about end selections — this can cause empty lines to be removed
        let lineCountOfTarget = targetText.components(separatedBy: CharacterSet.newlines).count
        let finalLine = (textRange.end.column > 0) ? textRange.end.line : textRange.end.line - 1
        let range = textRange.start.line ... finalLine
        let difference = range.count - lineCountOfTarget
        let start = XCSourceTextPosition(line: textRange.start.line, column: 0)
        let end = XCSourceTextPosition(line: finalLine - difference, column: 0)

        return XCSourceTextRange(start: start, end: end)
    }
}
