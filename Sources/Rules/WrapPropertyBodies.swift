//
//  WrapPropertyBodies.swift
//  SwiftFormat
//
//  Created by Manuel Lopez on 12/15/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Wrap single-line property bodies onto multiple lines.
    static let wrapPropertyBodies = FormatRule(
        help: "Wrap single-line property bodies onto multiple lines.",
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEach(.keyword("var")) { varIndex, _ in
            guard let property = formatter.parsePropertyDeclaration(atIntroducerIndex: varIndex),
                  let bodyScopeRange = property.body?.scopeRange,
                  !formatter.isInsideProtocol(at: varIndex)
            else { return }

            if formatter.isStoredProperty(atIntroducerIndex: varIndex) {
                // For stored properties with observers, wrap each didSet/willSet block
                formatter.wrapPropertyObservers(in: bodyScopeRange)
            } else {
                // For computed properties, wrap the body
                formatter.wrapStatementBody(at: bodyScopeRange.lowerBound)
            }
        }
    } examples: {
        """
        ```diff
        - var bar: String { "bar" }
        + var bar: String {
        +     "bar"
        + }

        - var foo: Int { didSet { bar() } }
        + var foo: Int {
        +     didSet { bar() }
        + }
        ```
        """
    }
}

extension Formatter {
    /// Wraps property observer blocks (didSet/willSet) within the given scope range
    func wrapPropertyObservers(in scopeRange: ClosedRange<Int>) {
        // Only wrap the outer braces, keeping didSet/willSet bodies on single lines
        wrapStatementBody(at: scopeRange.lowerBound)
    }
}
