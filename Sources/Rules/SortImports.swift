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
        options: ["import-grouping", "hoist-imports"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        if formatter.options.hoistImports {
            formatter.hoistStrayImports()
        }
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

          #if os(iOS)
        -   import Foo-iOS
        -   import Bar-iOS
        +   import Bar-iOS
        +   import Foo-iOS
          #endif
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

    /// Move file-scope imports that appear after non-import declarations
    /// up to the first import group at the top of the file.
    func hoistStrayImports() {
        let groups = parseImports()
        // Find groups not inside #if blocks
        var nonConditionalIndices = [Int]()
        for (i, group) in groups.enumerated() {
            guard let first = group.first else { continue }
            if !isInsidePreprocessorCondition(at: first.range.lowerBound) {
                nonConditionalIndices.append(i)
            }
        }
        guard nonConditionalIndices.count > 1 else { return }
        let insertionIndex = groups[nonConditionalIndices[0]].last!.range.upperBound
        // Collect import tokens from stray groups, remove bottom-to-top
        // (removing bottom-to-top keeps earlier indices valid)
        var collectedTokens = [Token]()
        for i in nonConditionalIndices.dropFirst().reversed() {
            let group = groups[i]
            for importRange in group {
                var rangeTokens = Array(tokens[importRange.range])
                while rangeTokens.first?.isLinebreak == true {
                    rangeTokens.removeFirst()
                }
                collectedTokens.append(linebreakToken(for: insertionIndex))
                collectedTokens.append(contentsOf: rangeTokens)
            }
            // Remove the group range plus one trailing linebreak
            let groupStart = group.first!.range.lowerBound
            let groupEnd = group.last!.range.upperBound
            let removeEnd = min(groupEnd + 1, tokens.count)
            removeTokens(in: groupStart ..< removeEnd)
        }
        // Insert all collected imports at the first group's end
        insert(collectedTokens, at: insertionIndex)
    }

    /// Check if a token index is inside a `#if` / `#endif` block.
    func isInsidePreprocessorCondition(at index: Int) -> Bool {
        var i = index
        while let ifIndex = self.index(of: .startOfScope("#if"), before: i) {
            if let endIndex = endOfScope(at: ifIndex), endIndex > index {
                return true
            }
            i = ifIndex
        }
        return false
    }
}
