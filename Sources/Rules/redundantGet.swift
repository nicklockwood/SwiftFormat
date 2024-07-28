//
//  redundantGet.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

extension FormatRule {
    /// Remove redundant `get {}` clause inside read-only computed property
    public static let redundantGet = FormatRule(
        help: "Remove unneeded `get` clause inside computed properties."
    ) { formatter in
        formatter.forEach(.identifier("get")) { i, _ in
            if formatter.isAccessorKeyword(at: i, checkKeyword: false),
               let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                   $0 == .startOfScope("{")
               }), let openIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                   $0 == .startOfScope("{")
               }),
               let closeIndex = formatter.index(of: .endOfScope("}"), after: openIndex),
               let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closeIndex, if: {
                   $0 == .endOfScope("}")
               })
            {
                formatter.removeTokens(in: closeIndex ..< nextIndex)
                formatter.removeTokens(in: prevIndex + 1 ... openIndex)
                // TODO: fix-up indenting of lines in between removed braces
            }
        }
    }
}
