//
//  TrailingSpace.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/24/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove trailing space from the end of lines, as it has no semantic
    /// meaning and leads to noise in commits.
    static let trailingSpace = FormatRule(
        help: "Remove trailing space at end of a line.",
        orderAfter: [.wrap, .wrapArguments],
        options: ["trim-whitespace"]
    ) { formatter in
        formatter.forEach(.space) { i, _ in
            switch formatter.token(at: i + 1) {
            case nil, .linebreak:
                if formatter.options.truncateBlankLines || formatter.token(at: i - 1)?.isLinebreak == false {
                    formatter.removeToken(at: i)
                }
            case .stringBody("") where formatter.options.truncateBlankLines:
                formatter.removeTokens(in: i ... i + 1)
            default:
                break
            }
        }
    } examples: {
        """
        ```diff
        - let foo: Foo␣
        + let foo: Foo
        - ␣␣␣␣
        +
        - func bar() {␣␣
        + func bar() {
          ␣␣␣␣print("foo")
          }
        ```
        """
    }
}
