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
            let i = i - 1
            switch formatter.token(at: i) {
            case _ where formatter.shouldInsertSpaceAfterToken(at: i) == true:
                formatter.insert(.space(" "), at: i + 1)
            case .space where formatter.shouldInsertSpaceAfterToken(at: i - 1) == false:
                formatter.removeToken(at: i)
            default:
                break
            }
        }
        formatter.forEach(.endOfScope("]")) { i, _ in
            let i = i + 1
            switch formatter.token(at: i) {
            case .identifier, .keyword, .startOfScope("{"),
                 .startOfScope("(") where formatter.isInClosureArguments(at: i - 1):
                formatter.insert(.space(" "), at: i)
            case .space:
                switch formatter.token(at: i + 1) {
                case .startOfScope("(")? where !formatter.isInClosureArguments(at: i + 1), .startOfScope("[")?:
                    formatter.removeToken(at: i)
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
