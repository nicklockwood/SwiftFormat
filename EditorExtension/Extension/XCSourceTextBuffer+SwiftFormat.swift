//
//  XCSourceTextBuffer+SwiftFormat.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 21/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import Foundation
import XcodeKit

extension XCSourceTextBuffer {

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
    func indentationString() -> String {
        if usesTabsForIndentation {
            let tabCount = indentationWidth / tabWidth
            if tabCount * tabWidth == indentationWidth {
                return String(repeating: "\t", count: tabCount)
            }
        }
        return String(repeating: " ", count: indentationWidth)
    }
}
