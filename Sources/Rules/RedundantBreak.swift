//
//  RedundantBreak.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant `break` keyword from switch cases
    static let redundantBreak = FormatRule(
        help: "Remove redundant `break` in switch case."
    ) { formatter in
        formatter.forEach(.keyword("break")) { i, _ in
            guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .startOfScope(":"),
                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: i)?.isEndOfScope == true,
                  var startIndex = formatter.index(of: .nonSpace, before: i),
                  let endIndex = formatter.index(of: .nonSpace, after: i),
                  formatter.currentScope(at: i) == .startOfScope(":")
            else {
                return
            }
            if !formatter.tokens[startIndex].isLinebreak || !formatter.tokens[endIndex].isLinebreak {
                startIndex += 1
            }
            formatter.removeTokens(in: startIndex ..< endIndex)
        }
    }
}
