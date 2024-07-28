//
//  redundantVoidReturnType.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

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

            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex) == .startOfScope("{")
            else { return }

            guard let prevIndex = formatter.index(of: .endOfScope(")"), before: i),
                  let parenIndex = formatter.index(of: .startOfScope("("), before: prevIndex),
                  let startToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: parenIndex),
                  startToken.isIdentifier || [.startOfScope("{"), .endOfScope("]")].contains(startToken)
            else {
                return
            }
            formatter.removeTokens(in: i ..< formatter.index(of: .nonSpace, after: endIndex)!)
        }
    }
}
