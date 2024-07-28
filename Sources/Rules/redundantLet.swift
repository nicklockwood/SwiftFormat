//
//  redundantLet.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant let/var for unnamed variables
    static let redundantLet = FormatRule(
        help: "Remove redundant `let`/`var` from ignored variables."
    ) { formatter in
        formatter.forEach(.identifier("_")) { i, _ in
            guard formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":"),
                  let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                      [.keyword("let"), .keyword("var")].contains($0)
                  }),
                  let nextNonSpaceIndex = formatter.index(of: .nonSpaceOrLinebreak, after: prevIndex)
            else {
                return
            }
            if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: prevIndex) {
                switch prevToken {
                case .keyword("if"), .keyword("guard"), .keyword("while"), .identifier("async"),
                     .keyword where prevToken.isAttribute,
                     .delimiter(",") where formatter.currentScope(at: i) != .startOfScope("("):
                    return
                default:
                    break
                }
            }
            // Crude check for Result Builder
            if formatter.isInResultBuilder(at: i) {
                return
            }
            formatter.removeTokens(in: prevIndex ..< nextNonSpaceIndex)
        }
    }
}
