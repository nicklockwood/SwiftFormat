//
//  AssertionFailures.swift
//  SwiftFormat
//
//  Created by sanjanapruthi on 9/28/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let assertionFailures = FormatRule(
        help: """
        Changes all instances of assert(false, ...) to assertionFailure(...)
        and precondition(false, ...) to preconditionFailure(...).
        """
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .identifier("assert"), .identifier("precondition"):
                guard let scopeStart = formatter.index(of: .nonSpace, after: i, if: {
                    $0 == .startOfScope("(")
                }), let identifierIndex = formatter.index(of: .nonSpaceOrLinebreak, after: scopeStart, if: {
                    $0 == .identifier("false")
                }), var endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: identifierIndex) else {
                    return
                }

                // if there are more arguments, replace the comma and space as well
                if formatter.tokens[endIndex] == .delimiter(",") {
                    endIndex = formatter.index(of: .nonSpace, after: endIndex) ?? endIndex
                }

                let replacements = ["assert": "assertionFailure", "precondition": "preconditionFailure"]
                formatter.replaceTokens(in: i ..< endIndex, with: [
                    .identifier(replacements[token.string]!), .startOfScope("("),
                ])
            default:
                break
            }
        }
    } examples: {
        """
        ```diff
        - assert(false)
        + assertionFailure()
        ```

        ```diff
        - assert(false, "message", 2, 1)
        + assertionFailure("message", 2, 1)
        ```

        ```diff
        - precondition(false, "message", 2, 1)
        + preconditionFailure("message", 2, 1)
        ```
        """
    }
}
