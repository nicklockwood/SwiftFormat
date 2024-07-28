//
//  blankLinesAtStartOfScope.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Remove blank lines immediately after an opening brace, bracket, paren or chevron
    static let blankLinesAtStartOfScope = FormatRule(
        help: "Remove leading blank line at the start of a scope.",
        orderAfter: ["organizeDeclarations"],
        options: ["typeblanklines"]
    ) { formatter in
        formatter.forEach(.startOfScope) { i, token in
            guard ["{", "(", "[", "<"].contains(token.string),
                  let indexOfFirstLineBreak = formatter.index(of: .nonSpaceOrComment, after: i),
                  // If there is extra code on the same line, ignore it
                  formatter.tokens[indexOfFirstLineBreak].isLinebreak
            else { return }

            // Consumers can choose whether or not this rule should apply to type bodies
            if !formatter.options.removeStartOrEndBlankLinesFromTypes,
               ["class", "actor", "struct", "enum", "protocol", "extension"].contains(
                   formatter.lastSignificantKeyword(at: i, excluding: ["where"]))
            {
                return
            }

            // Find next non-space token
            var index = indexOfFirstLineBreak + 1
            var indexOfLastLineBreak = indexOfFirstLineBreak
            loop: while let token = formatter.token(at: index) {
                switch token {
                case .linebreak:
                    indexOfLastLineBreak = index
                case .space:
                    break
                default:
                    break loop
                }
                index += 1
            }
            if formatter.options.removeBlankLines, indexOfFirstLineBreak != indexOfLastLineBreak {
                formatter.removeTokens(in: indexOfFirstLineBreak ..< indexOfLastLineBreak)
                return
            }
        }
    }
}
