//
//  FormatSelectedSourceCommand.swift
//  Swift Formatter
//
//  Version 0.17.2
//
//  Created by Tony Arnold on 5/10/16.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import Foundation
import XcodeKit

class FormatSelectedSourceCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation,
                 completionHandler: @escaping (Error?) -> Void) -> Void {

        guard ["public.swift-source", "com.apple.dt.playground"].contains(invocation.buffer.contentUTI) else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            return completionHandler(FormatCommandError.noSelection)
        }

        // Inspect the whole file to infer the format options
        var options = inferOptions(tokenize(invocation.buffer.completeBuffer))
        options.indent = indentationString(for: invocation.buffer)
        options.fragment = true

        // Grab the selected source to format using entire lines of text
        let selectionRange = selection.start.line ... min(selection.end.line, invocation.buffer.lines.count - 1)
        let sourceToFormat = selectionRange.flatMap { invocation.buffer.lines[$0] as? String }.joined()

        // Remove all selections to avoid a crash when changing the contents of the buffer.
        invocation.buffer.selections.removeAllObjects()

        do {
            let formattedSource = try format(sourceToFormat, options: options)
            invocation.buffer.lines.removeObjects(in: NSMakeRange(selection.start.line, selectionRange.count))
            invocation.buffer.lines.insert(formattedSource, at: selection.start.line)

            let updatedSelectionRange = rangeForDifferences(
                in: selection, between: sourceToFormat, and: formattedSource)

            invocation.buffer.selections.add(updatedSelectionRange)
        } catch let error {
            return completionHandler(error)
        }
        return completionHandler(nil)
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
                                     between sourceText: String, and targetText: String) -> XCSourceTextRange {

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
