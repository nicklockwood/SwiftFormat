//
//  RedundantProperty.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/9/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantProperty = FormatRule(
        help: "Simplifies redundant property definitions that are immediately returned.",
        orderAfter: [.propertyTypes]
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

            // If the property has an explicit type annotation, only simplify if the type
            // matches the return type of the enclosing function or computed property.
            // Otherwise, removing the property would lose meaningful type information.
            if let propertyType = property.type {
                guard let enclosingReturnType = formatter.returnTypeOfEnclosingScope(at: introducerIndex),
                      enclosingReturnType == propertyType
                else { return }
            }

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
    } examples: {
        """
        ```diff
          func foo() -> Foo {
        -   let foo = Foo()
        -   return foo
        +   return Foo()
          }
        ```
        """
    }
}

extension Formatter {
    /// Returns the return type of the enclosing function, subscript, or computed property
    /// for the scope containing the given index.
    func returnTypeOfEnclosingScope(at index: Int) -> TypeName? {
        guard let startOfBody = startOfScope(at: index),
              tokens[startOfBody] == .startOfScope("{"),
              let keywordIndex = indexOfLastSignificantKeyword(
                  at: startOfBody, excluding: ["throws", "rethrows"]
              )
        else { return nil }

        let keyword = tokens[keywordIndex].string

        // For func/subscript, find `->` and parse the return type
        if ["func", "subscript"].contains(keyword),
           let arrowIndex = self.index(of: .operator("->", .infix), in: keywordIndex + 1 ..< startOfBody),
           let returnTypeIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: arrowIndex),
           let returnType = parseType(at: returnTypeIndex)
        {
            return returnType
        }

        // For var (computed property), the return type is the property's declared type
        if keyword == "var",
           let property = parsePropertyDeclaration(atIntroducerIndex: keywordIndex),
           let type = property.type
        {
            return type
        }

        return nil
    }
}
