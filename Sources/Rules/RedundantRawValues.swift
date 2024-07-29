//
//  RedundantRawValues.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant raw string values for case statements
    static let redundantRawValues = FormatRule(
        help: "Remove redundant raw string values for enum cases."
    ) { formatter in
        formatter.forEach(.keyword("enum")) { i, _ in
            guard let nameIndex = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak, after: i, if: { $0.isIdentifier }
            ), let colonIndex = formatter.index(
                of: .nonSpaceOrCommentOrLinebreak, after: nameIndex, if: { $0 == .delimiter(":") }
            ), formatter.next(.nonSpaceOrCommentOrLinebreak, after: colonIndex) == .identifier("String"),
            let braceIndex = formatter.index(of: .startOfScope("{"), after: colonIndex) else {
                return
            }
            var lastIndex = formatter.index(of: .keyword("case"), after: braceIndex)
            while var index = lastIndex {
                guard let nameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    $0.isIdentifier
                }) else { break }
                if let equalsIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nameIndex, if: {
                    $0 == .operator("=", .infix)
                }), let quoteIndex = formatter.index(of: .nonSpaceOrLinebreak, after: equalsIndex, if: {
                    $0 == .startOfScope("\"")
                }), formatter.token(at: quoteIndex + 2) == .endOfScope("\"") {
                    if formatter.tokens[nameIndex].unescaped() == formatter.token(at: quoteIndex + 1)?.string {
                        formatter.removeTokens(in: nameIndex + 1 ... quoteIndex + 2)
                        index = nameIndex
                    } else {
                        index = quoteIndex + 2
                    }
                } else {
                    index = nameIndex
                }
                lastIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    $0 == .delimiter(",")
                }) ?? formatter.index(of: .keyword("case"), after: index)
            }
        }
    }
}
