//
//  SpaceAroundBrackets.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Implement the following rules with respect to the spacing around square brackets:
    /// * There is no space between an opening bracket and the preceding identifier,
    ///   unless the identifier is one of the specified keywords
    /// * There is no space between an opening bracket and the preceding closing brace
    /// * There is no space between an opening bracket and the preceding closing square bracket
    /// * There is space between a closing bracket and following identifier
    /// * There is space between a closing bracket and following opening brace
    static let spaceAroundBrackets = FormatRule(
        help: "Add or remove space around square brackets."
    ) { formatter in
        formatter.forEach(.startOfScope("[")) { i, _ in
            let index = i - 1
            guard let prevToken = formatter.token(at: index) else {
                return
            }
            switch prevToken {
            case .keyword,
                 .identifier("borrowing") where formatter.isTypePosition(at: index),
                 .identifier("consuming") where formatter.isTypePosition(at: index),
                 .identifier("sending") where formatter.isTypePosition(at: index):
                formatter.insert(.space(" "), at: i)
            case .space:
                let index = i - 2
                if let token = formatter.token(at: index) {
                    switch token {
                    case .identifier("as"), .identifier("is"), // not treated as keywords inside macro
                         .identifier("borrowing") where formatter.isTypePosition(at: index),
                         .identifier("consuming") where formatter.isTypePosition(at: index),
                         .identifier("sending") where formatter.isTypePosition(at: index):
                        break
                    case .identifier, .number, .endOfScope("]"), .endOfScope("}"), .endOfScope(")"):
                        formatter.removeToken(at: i - 1)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        formatter.forEach(.endOfScope("]")) { i, _ in
            guard let nextToken = formatter.token(at: i + 1) else {
                return
            }
            switch nextToken {
            case .identifier, .keyword, .startOfScope("{"),
                 .startOfScope("(") where formatter.isInClosureArguments(at: i):
                formatter.insert(.space(" "), at: i + 1)
            case .space:
                switch formatter.token(at: i + 2) {
                case .startOfScope("(")? where !formatter.isInClosureArguments(at: i + 2), .startOfScope("[")?:
                    formatter.removeToken(at: i + 1)
                default:
                    break
                }
            default:
                break
            }
        }
    } examples: {
        """
        ```diff
        - foo as[String]
        + foo as [String]
        ```

        ```diff
        - foo = bar [5]
        + foo = bar[5]
        ```
        """
    }
}
