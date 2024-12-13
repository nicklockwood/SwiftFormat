//
//  NoCommentedAssertions.swift
//  SwiftFormat
//
// Created by manny_lopez on 12/12/24.
// Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let noCommentedAssertions = FormatRule(
        help: """
        Uncomments instances of `// assert()` or `assertionFailure() so that it's not merged in by mistake`
        """
    ) { formatter in
        let assertList = ["assert(", "assertionFailure("]

        formatter.forEachToken { i, token in
            switch token {
            case let .commentBody(comment):
                guard assertList.contains(where: { assert in
                    comment.hasPrefix(assert)
                }),
                    let commentStart = formatter.index(of: .comment, before: i)
                else { break }

                print("\n:::")
                print(formatter.tokens)
                formatter.removeTokens(in: commentStart ..< i)
                print(formatter.tokens)
            default:
                break
            }
        }
    } examples: {
        """
        ```diff
        - // assertionFailure()
        + assertionFailure()
        """
    }
}
