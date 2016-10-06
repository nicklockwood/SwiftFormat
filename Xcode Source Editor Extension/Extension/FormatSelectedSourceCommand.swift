//
//  FormatSelectedSourceCommand.swift
//  Swift Formatter
//
//  Created by Tony Arnold on 5/10/16.
//  Copyright 2016 Charcoal Design
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

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping(Error?) -> Void) -> Void {
        guard invocation.buffer.contentUTI == "public.swift-source" else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        guard let selection = invocation.buffer.selections.firstObject as? XCSourceTextRange else {
            return completionHandler(FormatCommandError.noSelection)
        }

        // Ensure that we're not greedy about end selections — this can cause empty lines to be removed
        let selectionEndLine = (selection.end.column > 0) ? selection.end.line : selection.end.line - 1

        // Grab the selected source to format
        let selectionRange = selection.start.line ... selectionEndLine
        let sourceToFormat = selectionRange.flatMap { invocation.buffer.lines[$0] as? String }.joined()

        // Remove all selections to avoid a crash when changing the contents of the buffer.
        invocation.buffer.selections.removeAllObjects()

        do {
            let indent = String(repeating: " ", count: invocation.buffer.indentationWidth)
            let options = FormatOptions(indent: indent)
            let output = try format(sourceToFormat, rules: defaultRules, options: options)

            for line in selectionRange.reversed() {
                invocation.buffer.lines.removeObject(at: line)
            }

            invocation.buffer.lines.insert(output, at: selection.start.line)
        } catch let error {
            return completionHandler(error)
        }

        if (invocation.buffer.selections.count == 0) {
            // For the time being, set the selection back to the first character of the selected range
            let position = XCSourceTextPosition(line: selection.start.line, column: 0)
            let updatedSelectionRange = XCSourceTextRange(
                start: position,
                end: position
            )

            invocation.buffer.selections.add(updatedSelectionRange)
        }

        return completionHandler(nil)
    }
}
