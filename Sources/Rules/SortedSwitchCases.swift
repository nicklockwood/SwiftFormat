//
//  SortedSwitchCases.swift
//  SwiftFormat
//
//  Created by Facundo Menzella on 9/22/20.
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
    } examples: {
        nil
    }
}
