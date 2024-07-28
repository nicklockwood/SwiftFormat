//
//  spaceAroundBraces.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Ensure that there is space between an opening brace and the preceding
    /// identifier, and between a closing brace and the following identifier.
    static let spaceAroundBraces = FormatRule(
        help: "Add or remove space around curly braces."
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            if let prevToken = formatter.token(at: i - 1) {
                switch prevToken {
                case .space, .linebreak, .operator(_, .prefix), .operator(_, .infix),
                     .startOfScope where !prevToken.isStringDelimiter:
                    break
                default:
                    formatter.insert(.space(" "), at: i)
                }
            }
        }
        formatter.forEach(.endOfScope("}")) { i, _ in
            if let nextToken = formatter.token(at: i + 1) {
                switch nextToken {
                case .identifier, .keyword:
                    formatter.insert(.space(" "), at: i + 1)
                default:
                    break
                }
            }
        }
    }
}
