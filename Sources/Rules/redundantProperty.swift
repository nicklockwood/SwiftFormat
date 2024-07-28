//
//  redundantProperty.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantProperty = FormatRule(
        help: "Simplifies redundant property definitions that are immediately returned.",
        disabledByDefault: true,
        orderAfter: ["propertyType"]
    ) { formatter in
        formatter.forEach(.keyword) { introducerIndex, introducerToken in
            // Find properties like `let identifier = value` followed by `return identifier`
            guard ["let", "var"].contains(introducerToken.string),
                  let property = formatter.parsePropertyDeclaration(atIntroducerIndex: introducerIndex),
                  let (assignmentIndex, expressionRange) = property.value,
                  let returnIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound),
                  formatter.tokens[returnIndex] == .keyword("return"),
                  let returnedValueIndex = formatter.index(of: .nonSpaceOrComment, after: returnIndex),
                  let returnedExpression = formatter.parseExpressionRange(startingAt: returnedValueIndex, allowConditionalExpressions: true),
                  formatter.tokens[returnedExpression] == [.identifier(property.identifier)]
            else { return }

            let returnRange = formatter.startOfLine(at: returnIndex) ... formatter.endOfLine(at: returnedExpression.upperBound)
            let propertyRange = introducerIndex ... expressionRange.upperBound

            guard !propertyRange.overlaps(returnRange) else { return }

            // Remove the line with the `return identifier` statement.
            formatter.removeTokens(in: returnRange)

            // If there's nothing but whitespace between the end of the expression
            // and the return statement, we can remove all of it. But if there's a comment,
            // we should preserve it.
            let rangeBetweenExpressionAndReturn = (expressionRange.upperBound + 1) ..< (returnRange.lowerBound - 1)
            if formatter.tokens[rangeBetweenExpressionAndReturn].allSatisfy(\.isSpaceOrLinebreak) {
                formatter.removeTokens(in: rangeBetweenExpressionAndReturn)
            }

            // Replace the `let identifier = value` with `return value`
            formatter.replaceTokens(
                in: introducerIndex ..< expressionRange.lowerBound,
                with: [.keyword("return"), .space(" ")]
            )
        }
    }
}
