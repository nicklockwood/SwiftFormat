//
//  sortedImports.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

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
