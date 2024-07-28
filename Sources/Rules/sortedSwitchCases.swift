//
//  sortedSwitchCases.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

extension FormatRule {
    /// Deprecated
    public static let sortedSwitchCases = FormatRule(
        help: "Sort switch cases alphabetically.",
        deprecationMessage: "Use sortSwitchCases instead."
    ) { formatter in
        FormatRules.sortSwitchCases.apply(with: formatter)
    }
}
