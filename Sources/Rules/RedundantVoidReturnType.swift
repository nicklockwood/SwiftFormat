//
//  RedundantVoidReturnType.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 1/3/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant void return values for function and closure declarations
    static let redundantVoidReturnType = FormatRule(
        help: "Remove explicit `Void` return type.",
        options: ["closurevoid"]
    ) { formatter in
        formatter.forEach(.operator("->", .infix)) { i, _ in
            guard let startIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                  let endIndex = formatter.endOfVoidType(at: startIndex)
            else {
                return
            }

            // If this is the explicit return type of a closure, it should
            // always be safe to remove
            if formatter.options.closureVoidReturn == .remove,
               formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex) == .keyword("in")
            {
                formatter.removeTokens(in: i ..< formatter.index(of: .nonSpace, after: endIndex)!)
                return
            }

            guard let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex) else { return }

            let isInProtocol = nextToken == .endOfScope("}") || (nextToken.isKeywordOrAttribute && nextToken != .keyword("in"))

            // After a `Void` we could see the start of a function's body, or if the function is inside a protocol declaration
            // we can find a keyword related to other declarations or the end scope of the protocol definition.
            guard nextToken == .startOfScope("{") || isInProtocol else { return }

            guard let prevIndex = formatter.index(of: .endOfScope(")"), before: i),
                  let parenIndex = formatter.index(of: .startOfScope("("), before: prevIndex),
                  let startToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: parenIndex),
                  startToken.isIdentifier || [.startOfScope("{"), .endOfScope("]")].contains(startToken)
            else {
                return
            }

            let startRemoveIndex: Int
            if isInProtocol, formatter.token(at: i - 1)?.isSpace == true {
                startRemoveIndex = i - 1
            } else {
                startRemoveIndex = i
            }
            formatter.removeTokens(in: startRemoveIndex ..< formatter.index(of: .nonSpace, after: endIndex)!)
        }
    } examples: {
        """
        ```diff
        - func foo() -> Void {
            // returns nothing
          }

        + func foo() {
            // returns nothing
          }
        ```
        """
    }
}
