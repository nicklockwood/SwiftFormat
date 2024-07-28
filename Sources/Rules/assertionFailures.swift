//
//  assertionFailures.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

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
    }
}
