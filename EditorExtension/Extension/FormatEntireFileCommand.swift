//
//  FormatEntireFileCommand.swift
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

class FormatEntireFileCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) -> Void {
        guard invocation.buffer.contentUTI == "public.swift-source" else {
            return completionHandler(FormatCommandError.notSwiftLanguage)
        }

        // Grab the selected source to format
        let sourceToFormat = invocation.buffer.completeBuffer

        // Remove all selections to avoid a crash when changing the contents of the buffer.
        invocation.buffer.selections.removeAllObjects()

        do {
            let indent = String(repeating: " ", count: invocation.buffer.indentationWidth)
            let options = FormatOptions(indent: indent)
            let output = try format(sourceToFormat, rules: defaultRules, options: options)
            invocation.buffer.completeBuffer = output
        } catch let error {
            return completionHandler(error)
        }

        // For the time being, set the selection back to the last character of the buffer
        guard let lastLine = invocation.buffer.lines.lastObject as? String else {
            return completionHandler(FormatCommandError.invalidSelection)
        }

        let position = XCSourceTextPosition(line: invocation.buffer.lines.count - 1, column: lastLine.characters.count)
        let updatedSelectionRange = XCSourceTextRange(
            start: position,
            end: position
        )

        invocation.buffer.selections.add(updatedSelectionRange)

        return completionHandler(nil)
    }
}
