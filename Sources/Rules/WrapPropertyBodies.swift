//
//  WrapPropertyBodies.swift
//  SwiftFormat
//
//  Created by Manuel Lopez on 12/15/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Wrap single-line computed property bodies onto multiple lines.
    static let wrapPropertyBodies = FormatRule(
        help: "Wrap single-line computed property bodies onto multiple lines.",
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
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
        - var bar: String { "bar" }
        + var bar: String {
        +     "bar"
        + }
        ```
        """
    }
}
