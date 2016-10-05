//
//  SourceEditorCommand.swift
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

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping(Error?) -> Void) -> Void {
        guard invocation.buffer.contentUTI == "public.swift-source" else {
            // Ignore non-Swift source code
            completionHandler(nil)
            return
        }

        var options = FormatOptions()
        options.indent = String(repeating: " ", count: invocation.buffer.indentationWidth)

        // Remove all selections, to avoid a crash. This is not ideal.
        invocation.buffer.selections.removeAllObjects()

        let buffer = invocation.buffer.completeBuffer

        do {
            let output = try format(buffer, rules: defaultRules, options: options)

            // Update the entire buffer with the formatted result
            invocation.buffer.completeBuffer = output
        } catch let error {
            completionHandler(error)
            return
        }

        // For the time being, set the selection back to the first character of the buffer
        if (invocation.buffer.selections.count == 0) {
            let defaultSelection = XCSourceTextRange(
                start: XCSourceTextPosition(line: 0, column: 0),
                end: XCSourceTextPosition(line: 0, column: 0)
            )
            invocation.buffer.selections.add(defaultSelection)
        }

        completionHandler(nil)
    }
}
