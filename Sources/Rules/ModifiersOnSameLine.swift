//
//  ModifiersOnSameLine.swift
//  SwiftFormat
//
//  Created by cal_stephens on 5/29/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Ensure all modifiers are on the same line as the declaration keyword
    static let modifiersOnSameLine = FormatRule(
        help: "Ensure that all modifiers are on the same line as the declaration keyword."
    ) { formatter in
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            // Find the start of modifiers (excluding attributes)
            let modifierStart = declaration.startOfModifiersIndex(includingAttributes: false)

            // If there are no modifiers before the declaration, nothing to do
            guard modifierStart < declaration.keywordIndex else { return }

            // Check if modifiers and declaration are already on the same line
            if formatter.onSameLine(modifierStart, declaration.keywordIndex) {
                return
            }

            // Check if there are any comments between modifiers and declaration
            // If there are, we should preserve the existing formatting
            var hasComment = false
            for index in modifierStart ..< declaration.keywordIndex {
                if formatter.tokens[index].isComment {
                    hasComment = true
                    break
                }
            }

            if hasComment {
                return
            }

            // Unwrap all lines between modifiers and the declaration
            var currentIndex = declaration.keywordIndex
            while currentIndex > modifierStart {
                guard let prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: currentIndex) else {
                    break
                }

                // If there's a linebreak between previous and current token, unwrap it
                if formatter.tokens[prevIndex + 1 ..< currentIndex].contains(where: \.isLinebreak) {
                    formatter.unwrapLine(before: currentIndex, preservingComments: true)
                }

                currentIndex = prevIndex
            }
        }
    } examples: {
        """
        ```diff
        - @MainActor
        - public
        - private(set)
        - var foo: Foo

        + @MainActor
        + public private(set) var foo: Foo
        ```

        ```diff
        - nonisolated
        - func bar() {}

        + nonisolated func bar() {}
        ```
        """
    }
}
