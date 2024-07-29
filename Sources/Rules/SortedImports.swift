//
//  SortedImports.swift
//  SwiftFormat
//
//  Created by Pablo Carcelén on 11/22/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Deprecated
    static let sortedImports = FormatRule(
        help: "Sort import statements alphabetically.",
        deprecationMessage: "Use sortImports instead.",
        options: ["importgrouping"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        _ = formatter.options.importGrouping
        _ = formatter.options.linebreak
        FormatRule.sortImports.apply(with: formatter)
    }
}
