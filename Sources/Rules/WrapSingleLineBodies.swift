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
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard formatter.isFunctionOrComputedPropertyBody(at: i) else { return }
            formatter.wrapStatementBody(at: i)
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
    /// Whether the brace at the given index is the start of a function, init, subscript,
    /// or computed property body (not a closure or control flow statement).
    func isFunctionOrComputedPropertyBody(at i: Int) -> Bool {
        guard tokens[i] == .startOfScope("{"),
              !isStartOfClosure(at: i),
              let keyword = last(.keyword, before: i)
        else { return false }

        switch keyword {
        case .keyword("func"), .keyword("init"), .keyword("subscript"):
            return true
        case .keyword("var"):
            // Must be a computed property, not a stored property with willSet/didSet
            if let varIndex = index(of: .keyword("var"), before: i) {
                return !isStoredProperty(atIntroducerIndex: varIndex)
            }
            return false
        default:
            return false
        }
    }
}
