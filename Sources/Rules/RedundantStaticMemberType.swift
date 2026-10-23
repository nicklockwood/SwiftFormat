//
//  RedundantStaticMemberType.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 22/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Removes static member type qualifiers supplied by the surrounding context.
    static let redundantStaticMemberType = FormatRule(
        help: "Remove redundant type qualifiers from static member references.",
        orderAfter: [.redundantType, .propertyTypes, .redundantReturn]
    ) { formatter in
        formatter.forEachContextualType { i, expectedType in
            formatter.removeStaticMemberType(at: i, expectedType: expectedType)
        }
    } examples: {
        """
        ```diff
          func foo() -> Bar {
        -     Bar.value
        +     .value
          }

          var foo: Bar
        - foo = Bar.value
        + foo = .value
        ```

        Uses explicit local types and unambiguous project-indexed property and parameter types.
        Unresolved types and overloaded function calls are preserved.
        """
    }
}

extension Formatter {
    func removeStaticMemberType(at start: Int, expectedType: String) {
        let typeTokens = tokenize(expectedType).filter { !$0.isSpaceOrLinebreak }
        // Optional promotion, generic substitutions and existential lookup need type checking.
        guard !typeTokens.isEmpty, typeTokens.allSatisfy({ $0.isIdentifier || $0.isOperator(".") }),
              !typeTokens.contains(.identifier("Self"))
        else { return }
        var cursor = start
        for token in typeTokens {
            guard tokens[cursor] == token,
                  let next = index(of: .nonSpace, after: cursor)
            else { return }
            cursor = next
        }
        guard tokens[cursor].isOperator("."),
              let member = index(of: .nonSpace, after: cursor), tokens[member].isIdentifier,
              tokens[member] != .identifier("self"),
              let expression = parseExpressionRange(startingAt: start)
        else { return }
        var end = member
        if let next = index(of: .nonSpaceOrCommentOrLinebreak, after: member),
           tokens[next] == .startOfScope("("), let close = endOfScope(at: next)
        {
            end = close
        }
        // Don't remove a qualifier from a subexpression whose context is different.
        guard expression.upperBound == end else { return }
        removeTokens(in: start ..< cursor)
    }
}
