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
        +     didSet {
        +         bar()
        +     }
        + }
        ```
        """
    }
}

extension Formatter {
    /// Wraps property observer blocks (didSet/willSet) within the given scope range
    func wrapPropertyObservers(in scopeRange: ClosedRange<Int>) {
        // First wrap the outer braces
        wrapStatementBody(at: scopeRange.lowerBound)

        // Then find and wrap each didSet/willSet block
        var searchIndex = scopeRange.lowerBound
        while let observerIndex = index(of: .nonSpaceOrCommentOrLinebreak, in: searchIndex ..< scopeRange.upperBound) {
            let token = tokens[observerIndex]
            if [.identifier("didSet"), .identifier("willSet")].contains(token),
               let openBrace = index(of: .startOfScope("{"), after: observerIndex)
            {
                wrapStatementBody(at: openBrace)
                searchIndex = openBrace + 1
            } else {
                searchIndex = observerIndex + 1
            }
        }
    }
}
