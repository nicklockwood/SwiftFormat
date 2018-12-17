//
//  FormatEntireFileCommand.swift
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

class FormatEntireFileCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard ["public.swift-source", "com.apple.dt.playground", "com.apple.dt.playgroundpage"].contains(invocation.buffer.contentUTI) else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        // Grab the selected source to format
        let sourceToFormat = invocation.buffer.completeBuffer
        let tokens = tokenize(sourceToFormat)

        let store = OptionsStore()
        var formatOptions = store.inferOptions ? inferFormatOptions(from: tokens) : store.formatOptions
        formatOptions.indent = indentationString(for: invocation.buffer)
        do {
            let rules = FormatRules.all(named: RulesStore().rules.compactMap { $0.isEnabled ? $0.name : nil })
            let output = try format(tokens, rules: rules, options: formatOptions)
            if output == tokens {
                // No changes needed
                return completionHandler(nil)
            }

            // Remove all selections to avoid a crash when changing the contents of the buffer.
            invocation.buffer.selections.removeAllObjects()

            // Update buffer
            invocation.buffer.completeBuffer = sourceCode(for: output)

            // For the time being, set the selection back to the last character of the buffer
            guard let lastLine = invocation.buffer.lines.lastObject as? String else {
                return completionHandler(FormatCommandError.invalidSelection)
            }
            let position = XCSourceTextPosition(line: invocation.buffer.lines.count - 1, column: lastLine.count)
            let updatedSelectionRange = XCSourceTextRange(start: position, end: position)
            invocation.buffer.selections.add(updatedSelectionRange)

            return completionHandler(nil)
        } catch {
            return completionHandler(error)
        }
    }
}
