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
        options: ["import-grouping", "import-sort-by-access-control"],
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
        let sortByAccessThenAlpha: (Formatter.ImportRange, Formatter.ImportRange) -> Bool = { lhs, rhs in
            if lhs.accessLevelSortOrder != rhs.accessLevelSortOrder {
                return lhs.accessLevelSortOrder < rhs.accessLevelSortOrder
            }
            return lhs < rhs
        }

        let sortByAccessThenLength: (Formatter.ImportRange, Formatter.ImportRange) -> Bool = { lhs, rhs in
            if lhs.accessLevelSortOrder != rhs.accessLevelSortOrder {
                return lhs.accessLevelSortOrder < rhs.accessLevelSortOrder
            }
            return lhs.module.count < rhs.module.count
        }
        
        let partitions: [[Formatter.ImportRange]] =switch options.importGrouping {
        case .testableFirst:
            [ranges.filter(\.isTestable), ranges.filter { !$0.isTestable }]
        case .testableLast:
            [ranges.filter { !$0.isTestable }, ranges.filter(\.isTestable)]
        case .alpha, .length:
            [ranges]
        }

        return partitions.flatMap { partition in
            if options.importSortByAccessControl {
                return partition.sorted(by: options.importGrouping == .length ? sortByAccessThenLength : sortByAccessThenAlpha)
            }
            
            return switch options.importGrouping {
            case .alpha:
                partition.sorted(by: <)
            case .length:
                partition.sorted { $0.module.count < $1.module.count }
            case .testableFirst, .testableLast:
                partition.sorted(by: <)
            }
        }
    }
}
