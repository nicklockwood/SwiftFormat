//
//  WrapConditionalBodies.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/6/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Deprecated
    static let wrapConditionalBodies = FormatRule(
        help: "Wrap the bodies of inline conditional statements onto a new line.",
        deprecationMessage: "Use wrapIfStatementBodies, wrapGuardStatementBodies, or wrapIfExpressionBodies instead.",
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        FormatRule.wrapIfStatementBodies.apply(with: formatter)
        FormatRule.wrapGuardStatementBodies.apply(with: formatter)
        FormatRule.wrapIfExpressionBodies.apply(with: formatter)
    } examples: {
        nil
    }
}
