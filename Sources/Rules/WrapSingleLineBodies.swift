//
//  WrapSingleLineBodies.swift
//  SwiftFormat
//
//  Created by Manuel Lopez on 12/10/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Wrap single-line function, init, subscript, and computed property bodies onto multiple lines.
    static let wrapSingleLineBodies = FormatRule(
        help: "Wrap single-line function, init, subscript, and computed property bodies onto multiple lines.",
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        // Handle func, init, subscript declarations
        formatter.forEach(.keyword) { keywordIndex, keyword in
            guard ["func", "init", "subscript"].contains(keyword.string),
                  let declaration = formatter.parseFunctionDeclaration(keywordIndex: keywordIndex),
                  let bodyRange = declaration.bodyRange,
                  !formatter.isInsideProtocol(at: keywordIndex)
            else { return }

            formatter.wrapStatementBody(at: bodyRange.lowerBound)
        }

        // Handle computed properties
        formatter.forEach(.keyword("var")) { varIndex, _ in
            guard let property = formatter.parsePropertyDeclaration(atIntroducerIndex: varIndex),
                  let bodyScopeRange = property.body?.scopeRange,
                  !formatter.isStoredProperty(atIntroducerIndex: varIndex),
                  !formatter.isInsideProtocol(at: varIndex)
            else { return }

            formatter.wrapStatementBody(at: bodyScopeRange.lowerBound)
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

        - var bar: String { "bar" }
        + var bar: String {
        +     "bar"
        + }
        ```
        """
    }
}

extension Formatter {
    /// Returns true if the given index is inside a protocol declaration
    func isInsideProtocol(at index: Int) -> Bool {
        guard let scopeStart = startOfScope(at: index) else {
            return false
        }

        // Exclude "class" because `protocol Foo: class { }` uses class as a constraint, not a type keyword
        return lastSignificantKeyword(at: scopeStart, excluding: ["where", "class"]) == "protocol"
    }
}
