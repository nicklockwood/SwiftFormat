//
//  XCSourceTextBuffer+SwiftFormat.swift
//  SwiftFormat
//
//  Version 0.14
//
//  Created by Nick Lockwood on 21/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import Foundation
import XcodeKit

/// Calculates the indentation string representation for a given source text buffer.
///
/// - Returns: Indentation represented as a string
///
/// NOTE: we cannot exactly replicate Xcode's indent logic in SwiftFormat because
/// SwiftFormat doesn't support the concept of mixed tabs/spaces that Xcode does.
///
/// But that's OK, because mixing tabs and spaces is really stupid.
///
/// So in the event that the user has chosen to use tabs, but their chosen indentation
/// width is not a multiple of the tab width, we'll just use spaces instead.
func indentationString(for buffer: XCSourceTextBuffer) -> String {
    if buffer.usesTabsForIndentation {
        let tabCount = buffer.indentationWidth / buffer.tabWidth
        if tabCount * buffer.tabWidth == buffer.indentationWidth {
            return String(repeating: "\t", count: tabCount)
        }
    }
    return String(repeating: " ", count: buffer.indentationWidth)
}
