//
//  SortImports.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/13/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Sort import statements
    static let sortImports = FormatRule(
        help: "Sort import statements alphabetically.",
        options: ["importgrouping"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        for var importRanges in formatter.parseImports().reversed() {
            guard importRanges.count > 1 else { continue }
            let range: Range = importRanges.first!.range.lowerBound ..< importRanges.last!.range.upperBound
            let sortedRanges = formatter.sortRanges(importRanges)
            var insertedLinebreak = false
            var sortedTokens = sortedRanges.flatMap { inputRange -> [Token] in
                var tokens = Array(formatter.tokens[inputRange.range])
                if tokens.first?.isLinebreak == false {
                    insertedLinebreak = true
                    tokens.insert(formatter.linebreakToken(for: tokens.startIndex), at: tokens.startIndex)
                }
                return tokens
            }
            if insertedLinebreak {
                sortedTokens.removeFirst()
            }
            formatter.replaceTokens(in: range, with: sortedTokens)
        }
    }
}

extension Formatter {
    func sortRanges(_ ranges: [Formatter.ImportRange]) -> [Formatter.ImportRange] {
        if case .alpha = options.importGrouping {
            return ranges.sorted(by: <)
        } else if case .length = options.importGrouping {
            return ranges.sorted { $0.module.count < $1.module.count }
        }
        // Group @testable imports at the top or bottom
        // TODO: need more general solution for handling other import attributes
        return ranges.sorted {
            // If both have a @testable keyword, or neither has one, just sort alphabetically
            guard $0.isTestable != $1.isTestable else {
                return $0 < $1
            }
            return options.importGrouping == .testableFirst ? $0.isTestable : $1.isTestable
        }
    }
}
