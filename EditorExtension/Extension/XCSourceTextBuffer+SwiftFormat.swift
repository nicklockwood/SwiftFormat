//
//  XCSourceTextBuffer+SwiftFormat.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 21/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import Foundation
import XcodeKit

extension XCSourceTextPosition {
    init(_ offset: SourceOffset) {
        self.init(line: offset.line - 1, column: offset.column - 1)
    }
}

extension SourceOffset {
    init(_ position: XCSourceTextPosition) {
        line = position.line + 1
        column = position.column + 1
    }
}

extension XCSourceTextBuffer {
    /// Calculates the indentation string representation for a given source text buffer
    var indentationString: String {
        if usesTabsForIndentation {
            let tabCount = indentationWidth / tabWidth
            if tabCount * tabWidth == indentationWidth {
                return String(repeating: "\t", count: tabCount)
            }
        }
        return String(repeating: " ", count: indentationWidth)
    }

    func newPosition(for position: XCSourceTextPosition,
                     in tokens: [Token]) -> XCSourceTextPosition
    {
        let offset = newOffset(for: SourceOffset(position), in: tokens, tabWidth: tabWidth)
        return XCSourceTextPosition(offset)
    }
}
