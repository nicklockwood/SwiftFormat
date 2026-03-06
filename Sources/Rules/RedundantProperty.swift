//
//  RedundantProperty.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 6/9/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Deprecated
    static let redundantProperty = FormatRule(
        help: "Simplifies redundant variable definitions that are immediately returned.",
        deprecationMessage: "Use redundantVariable instead."
    ) { formatter in
        FormatRule.redundantVariable.apply(with: formatter)
    } examples: {
        nil
    }
}
