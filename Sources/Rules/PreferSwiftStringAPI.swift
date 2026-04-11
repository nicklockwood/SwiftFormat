//
//  PreferSwiftStringAPI.swift
//  SwiftFormat
//
//  Created by Sutheesh Sukumaran on 05/04/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace Objective-C bridged String methods with their Swift equivalents
    /// Disabled by default since `replacing(_:with:)` is only available in iOS 16+ / macOS 13+.
    static let preferSwiftStringAPI = FormatRule(
        help: "Replace Objective-C bridged String methods with Swift equivalents.",
        disabledByDefault: true
    ) { formatter in
        // replacing(_:with:) was introduced in Swift 5.7
        guard formatter.options.swiftVersion >= "5.7" else { return }

        formatter.forEach(.identifier("replacingOccurrences")) { i, _ in
            // Must be a method call (preceded by a dot)
            guard let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                  formatter.tokens[prevIndex] == .operator(".", .infix)
            else { return }

            // Must be followed immediately by a `(` argument list
            guard let openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                  formatter.tokens[openParenIndex] == .startOfScope("(")
            else { return }

            // Only transform the two-argument form: `replacingOccurrences(of:with:)`
            let args = formatter.parseFunctionCallArguments(startOfScope: openParenIndex)
            guard args.count == 2,
                  args[0].label == "of",
                  args[1].label == "with",
                  let ofLabelIndex = args[0].labelIndex
            else { return }

            // Remove the `of:` label and any whitespace up to the value.
            // Since ofLabelIndex > i, this does not invalidate index i.
            let valueStart = args[0].valueRange.lowerBound
            formatter.removeTokens(in: ofLabelIndex ..< valueStart)

            // Rename `replacingOccurrences` → `replacing`
            formatter.replaceToken(at: i, with: .identifier("replacing"))
        }
    } examples: {
        """
        ```diff
        - str.replacingOccurrences(of: "foo", with: "bar")
        + str.replacing("foo", with: "bar")
        ```
        """
    }
}
