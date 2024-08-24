//
//  RedundantPattern.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/14/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant pattern in case statements
    static let redundantPattern = FormatRule(
        help: "Remove redundant pattern matching parameter syntax.",
        examples: """
        ```diff
        - if case .foo(_, _) = bar {}
        + if case .foo = bar {}
        ```

        ```diff
        - let (_, _) = bar
        + let _ = bar
        ```
        """
    ) { formatter in
        formatter.forEach(.startOfScope("(")) { i, _ in
            let prevIndex = formatter.index(of: .nonSpaceOrComment, before: i)
            if let prevIndex = prevIndex, let prevToken = formatter.token(at: prevIndex),
               [.keyword("case"), .endOfScope("case")].contains(prevToken)
            {
                // Not safe to remove
                return
            }
            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i),
                  let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: endIndex),
                  [.startOfScope(":"), .operator("=", .infix)].contains(nextToken),
                  formatter.redundantBindings(in: i + 1 ..< endIndex)
            else {
                return
            }
            formatter.removeTokens(in: i ... endIndex)
            if let prevIndex = prevIndex, formatter.tokens[prevIndex].isIdentifier,
               formatter.last(.nonSpaceOrComment, before: prevIndex)?.string == "."
            {
                if let endOfScopeIndex = formatter.index(
                    before: prevIndex,
                    where: { tkn in tkn == .endOfScope("case") || tkn == .keyword("case") }
                ),
                    let varOrLetIndex = formatter.index(after: endOfScopeIndex, where: { tkn in
                        tkn == .keyword("let") || tkn == .keyword("var")
                    }),
                    let operatorIndex = formatter.index(of: .operator, before: prevIndex),
                    varOrLetIndex < operatorIndex
                {
                    formatter.removeTokens(in: varOrLetIndex ..< operatorIndex)
                }
                return
            }

            // Was an assignment
            formatter.insert(.identifier("_"), at: i)
            if formatter.token(at: i - 1).map({ $0.isSpaceOrLinebreak }) != true {
                formatter.insert(.space(" "), at: i)
            }
        }
    }
}

extension Formatter {
    func redundantBindings(in range: Range<Int>) -> Bool {
        var isEmpty = true
        for token in tokens[range.lowerBound ..< range.upperBound] {
            switch token {
            case .identifier("_"):
                isEmpty = false
            case .space, .linebreak, .delimiter(","), .keyword("let"), .keyword("var"):
                break
            default:
                return false
            }
        }
        return !isEmpty
    }
}
