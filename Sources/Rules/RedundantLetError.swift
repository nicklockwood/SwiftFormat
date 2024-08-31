//
//  RedundantLetError.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/16/18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant `let error` from `catch` statements
    static let redundantLetError = FormatRule(
        help: "Remove redundant `let error` from `catch` clause.",
        examples: """
        ```diff
        - do { ... } catch let error { log(error) }
        + do { ... } catch { log(error) }
        ```
        """

    ) { formatter in
        formatter.forEach(.keyword("catch")) { i, _ in
            if let letIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                $0 == .keyword("let")
            }), let errorIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: letIndex, if: {
                $0 == .identifier("error")
            }), let scopeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: errorIndex, if: {
                $0 == .startOfScope("{")
            }) {
                formatter.removeTokens(in: letIndex ..< scopeIndex)
            }
        }
    }
}
