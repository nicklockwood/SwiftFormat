//
//  SpaceAroundParens.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Implement the following rules with respect to the spacing around parens:
    /// * There is no space between an opening paren and the preceding identifier,
    ///   unless the identifier is one of the specified keywords
    /// * There is no space between an opening paren and the preceding closing brace
    /// * There is no space between an opening paren and the preceding closing square bracket
    /// * There is space between a closing paren and following identifier
    /// * There is space between a closing paren and following opening brace
    /// * There is no space between a closing paren and following opening square bracket
    static let spaceAroundParens = FormatRule(
        help: "Add or remove space around parentheses."
    ) { formatter in
        formatter.forEach(.startOfScope("(")) { i, _ in
            let i = i - 1
            switch formatter.token(at: i) {
            case _ where formatter.shouldInsertSpaceAfterToken(at: i) == true:
                formatter.insertSpace(" ", at: i + 1)
            case .space where formatter.shouldInsertSpaceAfterToken(at: i - 1) == false:
                formatter.removeToken(at: i)
            default:
                break
            }
        }
        formatter.forEach(.endOfScope(")")) { i, _ in
            let i = i + 1
            switch formatter.token(at: i) {
            case .identifier, .keyword, .startOfScope("{"):
                formatter.insertSpace(" ", at: i)
            case .space where formatter.token(at: i + 1) == .startOfScope("["):
                formatter.removeToken(at: i)
            default:
                break
            }
        }
    } examples: {
        """
        ```diff
        - init (foo)
        + init(foo)
        ```

        ```diff
        - switch(x){
        + switch (x) {
        ```
        """
    }
}
