//
//  SortedSwitchCases.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Deprecated
    static let sortedSwitchCases = FormatRule(
        help: "Sort switch cases alphabetically.",
        deprecationMessage: "Use sortSwitchCases instead."
    ) { formatter in
        FormatRule.sortSwitchCases.apply(with: formatter)
    }
}
