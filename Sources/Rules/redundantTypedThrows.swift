//
//  redundantTypedThrows.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantTypedThrows = FormatRule(
        help: "Converts `throws(any Error)` to `throws`, and converts `throws(Never)` to non-throwing.")
    { formatter in
        formatter.forEach(.keyword("throws")) { throwsIndex, _ in
            guard // Typed throws was added in Swift 6.0: https://github.com/apple/swift-evolution/blob/main/proposals/0413-typed-throws.md
                formatter.options.swiftVersion >= "6.0",
                let startOfScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: throwsIndex),
                formatter.tokens[startOfScope] == .startOfScope("("),
                let endOfScope = formatter.endOfScope(at: startOfScope)
            else { return }

            let throwsTypeRange = (startOfScope + 1) ..< endOfScope
            let throwsType: String = formatter.tokens[throwsTypeRange].map { $0.string }.joined()

            if throwsType == "Never" {
                if formatter.tokens[endOfScope + 1].isSpace {
                    formatter.removeTokens(in: throwsIndex ... endOfScope + 1)
                } else {
                    formatter.removeTokens(in: throwsIndex ... endOfScope)
                }
            }

            // We don't remove `(Error)` because we can't guarantee it will reference the `Swift.Error` protocol
            // (it's relatively common to define a custom error like `enum Error: Swift.Error { ... }`).
            if throwsType == "any Error" || throwsType == "any Swift.Error" || throwsType == "Swift.Error" {
                formatter.removeTokens(in: startOfScope ... endOfScope)
            }
        }
    }
}
