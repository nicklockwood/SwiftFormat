//
//  WrapFunctionBodies.swift
//  SwiftFormat
//
//  Created by Manuel Lopez on 12/15/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Wrap single-line function, init, and subscript bodies onto multiple lines.
    static let wrapFunctionBodies = FormatRule(
        help: "Wrap single-line function, init, and subscript bodies onto multiple lines.",
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEach(.keyword) { keywordIndex, keyword in
            guard ["func", "init", "subscript"].contains(keyword.string),
                  let declaration = formatter.parseFunctionDeclaration(keywordIndex: keywordIndex),
                  let bodyRange = declaration.bodyRange,
                  !formatter.isInsideProtocol(at: keywordIndex)
            else { return }

            formatter.wrapStatementBody(at: bodyRange.lowerBound)
        }
    } examples: {
        """
        ```diff
        - func foo() { print("bar") }
        + func foo() {
        +     print("bar")
        + }

        - init() { self.value = 0 }
        + init() {
        +     self.value = 0
        + }

        - subscript(index: Int) -> Int { array[index] }
        + subscript(index: Int) -> Int {
        +     array[index]
        + }
        ```
        """
    }
}
