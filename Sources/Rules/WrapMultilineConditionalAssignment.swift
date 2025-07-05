//
//  WrapMultilineConditionalAssignment.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/18/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapMultilineConditionalAssignment = FormatRule(
        help: "Wrap multiline conditional assignment expressions after the assignment operator.",
        disabledByDefault: true,
        orderAfter: [.conditionalAssignment],
        sharedOptions: ["line-breaks"]
    ) { formatter in
        formatter.forEach(.keyword) { startOfCondition, keywordToken in
            guard [.keyword("if"), .keyword("switch")].contains(keywordToken),
                  let assignmentIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfCondition),
                  formatter.tokens[assignmentIndex] == .operator("=", .infix),
                  let endOfPropertyDefinition = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: assignmentIndex)
            else { return }

            // Verify the RHS of the assignment is an if/switch expression
            guard let startOfConditionalExpression = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: assignmentIndex),
                  ["if", "switch"].contains(formatter.tokens[startOfConditionalExpression].string),
                  let conditionalBranches = formatter.conditionalBranches(at: startOfConditionalExpression),
                  let lastBranch = conditionalBranches.last
            else { return }

            // If the entire expression is on a single line, we leave the formatting as-is
            guard !formatter.onSameLine(startOfConditionalExpression, lastBranch.endOfBranch) else {
                return
            }

            // The `=` should be on the same line as the rest of the property
            if !formatter.onSameLine(endOfPropertyDefinition, assignmentIndex),
               formatter.last(.nonSpaceOrComment, before: assignmentIndex)?.isLinebreak == true,
               let previousToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: assignmentIndex),
               formatter.onSameLine(endOfPropertyDefinition, previousToken)
            {
                // Move the assignment operator to follow the previous token.
                // Also remove any trailing space after the previous position
                // of the assignment operator.
                if formatter.tokens[assignmentIndex + 1].isSpaceOrLinebreak {
                    formatter.removeToken(at: assignmentIndex + 1)
                }

                formatter.removeToken(at: assignmentIndex)
                formatter.insert([.space(" "), .operator("=", .infix)], at: previousToken + 1)
            }

            // And there should be a line break between the `=` and the `if` / `switch` keyword
            else if !formatter.tokens[(assignmentIndex + 1) ..< startOfConditionalExpression].contains(where: \.isLinebreak) {
                formatter.insertLinebreak(at: startOfConditionalExpression - 1)
            }
        }
    } examples: {
        #"""
        ```diff
        - let planetLocation = if let star = planet.star {
        -     "The \(star.name) system"
        - } else {
        -     "Rogue planet"
        - }
        + let planetLocation =
        +     if let star = planet.star {
        +         "The \(star.name) system"
        +     } else {
        +         "Rogue planet"
        +     }
        ```
        """#
    }
}
