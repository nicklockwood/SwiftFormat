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
        help: "Sort and group import statements.",
        options: ["import-grouping"],
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
    } examples: {
        """
        ```diff
        - import Foo
        - import Bar
        + import Bar
        + import Foo
        ```

        ```diff
        - import B
        - import A
        - #if os(iOS)
        -   import Foo-iOS
        -   import Bar-iOS
        - #endif
        + import A
        + import B
        + #if os(iOS)
        +   import Bar-iOS
        +   import Foo-iOS
        + #endif
        ```
        """
    }
}

extension Formatter {
    func sortRanges(_ ranges: [Formatter.ImportRange]) -> [Formatter.ImportRange] {
        let grouping = options.importGrouping

        let partitions: [[Formatter.ImportRange]]
        if grouping.contains(.testableFirst) {
            partitions = [ranges.filter(\.isTestable), ranges.filter { !$0.isTestable }]
        } else if grouping.contains(.testableLast) {
            partitions = [ranges.filter { !$0.isTestable }, ranges.filter(\.isTestable)]
        } else {
            partitions = [ranges]
        }

        return partitions.flatMap { partition in
            partition.sorted { lhs, rhs in
                if grouping.contains(.accessControl) {
                    let lhsAccessOrder = accessLevelSortOrder(for: lhs)
                    let rhsAccessOrder = accessLevelSortOrder(for: rhs)
                    if lhsAccessOrder != rhsAccessOrder {
                        return lhsAccessOrder > rhsAccessOrder
                    }
                }

                if grouping.contains(.length) {
                    if lhs.module.count != rhs.module.count {
                        return lhs.module.count < rhs.module.count
                    }
                    if grouping.contains(.alpha) {
                        return lhs < rhs
                    }
                    return false
                }
                // Default to alphabetical
                return lhs < rhs
            }
        }
    }

    /// Sort order for import access level using aclModifiers (higher index = more visible).
    /// Unlabeled imports return -1 (sorted last).
    func accessLevelSortOrder(for range: Formatter.ImportRange) -> Int {
        guard let level = range.accessLevel else { return -1 }
        return _FormatRules.aclModifiers.firstIndex(of: level) ?? -1
    }
}
