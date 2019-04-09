//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation
import XcodeKit

class FormatXMLCommand: NSObject, XCSourceEditorCommand {
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        guard ["public.xml"].contains(invocation.buffer.contentUTI) else {
            return completionHandler(NSError(
                domain: "Layout",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "File is not XML"]
            ))
        }

        // Grab the selected source to format
        let sourceToFormat = invocation.buffer.completeBuffer
        do {
            let output = try format(sourceToFormat)
            if output == sourceToFormat {
                // No changes needed
                return completionHandler(nil)
            }

            // Remove all selections to avoid a crash when changing the contents of the buffer.
            invocation.buffer.selections.removeAllObjects()

            // Update buffer
            invocation.buffer.completeBuffer = output

            // For the time being, set the selection back to the last character of the buffer
            guard let lastLine = invocation.buffer.lines.lastObject as? String else {
                return completionHandler(nil)
            }
            let position = XCSourceTextPosition(line: invocation.buffer.lines.count - 1, column: lastLine.count)
            let updatedSelectionRange = XCSourceTextRange(start: position, end: position)
            invocation.buffer.selections.add(updatedSelectionRange)

            return completionHandler(nil)
        } catch {
            return completionHandler(NSError(
                domain: "Layout",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "\(error)"]
            ))
        }
    }
}
