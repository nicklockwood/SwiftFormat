//
//  Void.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/19/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Normalize the use of void in closure arguments and return values
    static let void = FormatRule(
        help: "Use `Void` for type declarations and `()` for values.",
        options: ["voidtype"]
    ) { formatter in
        let hasLocalVoid = formatter.hasLocalVoid()

        formatter.forEach(.identifier("Void")) { i, _ in
            if let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope(")")
            }), var prevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: i), {
                let token = formatter.tokens[prevIndex]
                if token == .delimiter(":"),
                   let prevPrevIndex = formatter.index(of: .nonSpaceOrLinebreak, before: prevIndex),
                   formatter.tokens[prevPrevIndex] == .identifier("_"),
                   let startIndex = formatter.index(of: .nonSpaceOrLinebreak, before: prevPrevIndex),
                   formatter.tokens[startIndex] == .startOfScope("(")
                {
                    prevIndex = startIndex
                    return true
                }
                return token == .startOfScope("(")
            }() {
                if formatter.isArgumentToken(at: nextIndex) || formatter.last(
                    .nonSpaceOrLinebreak,
                    before: prevIndex
                )?.isIdentifier == true {
                    if !formatter.options.useVoid, !hasLocalVoid {
                        // Convert to parens
                        formatter.replaceToken(at: i, with: .endOfScope(")"))
                        formatter.insert(.startOfScope("("), at: i)
                    }
                } else if formatter.options.useVoid {
                    // Strip parens
                    formatter.removeTokens(in: i + 1 ... nextIndex)
                    formatter.removeTokens(in: prevIndex ..< i)
                } else {
                    // Remove Void
                    formatter.removeTokens(in: prevIndex + 1 ..< nextIndex)
                }
            } else if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                      [.operator(".", .prefix), .operator(".", .infix),
                       .keyword("typealias")].contains(prevToken)
            {
                return
            } else if formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) ==
                .operator(".", .infix)
            {
                return
            } else if formatter.next(.nonSpace, after: i) == .startOfScope("(") {
                if !hasLocalVoid {
                    formatter.removeToken(at: i)
                }
            } else if !formatter.options.useVoid || formatter.isArgumentToken(at: i), !hasLocalVoid {
                // Convert to parens
                formatter.replaceToken(at: i, with: [.startOfScope("("), .endOfScope(")")])
            }
        }
        formatter.forEach(.startOfScope("(")) { i, _ in
            guard formatter.options.useVoid else {
                return
            }
            guard let endIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i, if: {
                $0 == .endOfScope(")")
            }), let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
            !formatter.isArgumentToken(at: endIndex) else {
                return
            }
            if formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) == .operator("->", .infix) {
                if !hasLocalVoid {
                    formatter.replaceTokens(in: i ... endIndex, with: .identifier("Void"))
                }
            } else if prevToken == .startOfScope("<") ||
                (prevToken == .delimiter(",") && formatter.currentScope(at: i) == .startOfScope("<")),
                !hasLocalVoid
            {
                formatter.replaceTokens(in: i ... endIndex, with: .identifier("Void"))
            } else if prevToken == .operator("=", .infix),
                      let equalIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                      let prevPrevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: equalIndex),
                      prevPrevToken.isIdentifier,
                      formatter.lastSignificantKeyword(at: i) == "typealias",
                      !hasLocalVoid
            {
                // Handle typealias cases like: typealias Dependencies = ()
                formatter.replaceTokens(in: i ... endIndex, with: .identifier("Void"))
            }
            // TODO: other cases
        }
    } examples: {
        """
        ```diff
        - let foo: () -> ()
        + let foo: () -> Void
        ```

        ```diff
        - let bar: Void -> Void
        + let bar: () -> Void
        ```

        ```diff
        - let baz: (Void) -> Void
        + let baz: () -> Void
        ```

        ```diff
        - func quux() -> (Void)
        + func quux() -> Void
        ```

        ```diff
        - callback = { _ in Void() }
        + callback = { _ in () }
        ```
        """
    }
}

extension Formatter {
    func isArgumentToken(at index: Int) -> Bool {
        guard let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: index) else {
            return false
        }
        switch nextToken {
        case .operator("->", .infix), .keyword("throws"), .keyword("rethrows"), .identifier("async"):
            return true
        case .startOfScope("{"):
            if tokens[index] == .endOfScope(")"),
               let index = self.index(of: .startOfScope("("), before: index),
               let nameIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index, if: {
                   $0.isIdentifier
               }), last(.nonSpaceOrCommentOrLinebreak, before: nameIndex) == .keyword("func")
            {
                return true
            }
            return false
        case .keyword("in"):
            if tokens[index] == .endOfScope(")"),
               let index = self.index(of: .startOfScope("("), before: index)
            {
                return last(.nonSpaceOrCommentOrLinebreak, before: index) == .startOfScope("{")
            }
            return false
        default:
            return false
        }
    }

    func hasLocalVoid() -> Bool {
        for (i, token) in tokens.enumerated() where token == .identifier("Void") {
            if let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: i) {
                switch prevToken {
                case .keyword("typealias"), .keyword("struct"), .keyword("class"), .keyword("enum"):
                    return true
                default:
                    break
                }
            }
        }
        return false
    }
}
