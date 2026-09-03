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

        return partitionImports(ranges).flatMap { partition in
            partition.ranges.sorted { lhs, rhs in
                if partition.sortByAttributes {
                    let lhsAttributes = lhs.attributeSortKey
                    let rhsAttributes = rhs.attributeSortKey
                    let la = lhsAttributes.lowercased()
                    let lb = rhsAttributes.lowercased()
                    if la != lb {
                        return la < lb
                    }
                    if lhsAttributes != rhsAttributes {
                        return lhsAttributes < rhsAttributes
                    }
                }

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

    /// Splits the imports into the separately sorted groups defined by options like
    /// `testable-last` and `attributes-last`, in the order those groups should appear.
    /// Groups are ordered relative to each other by the order of the options themselves.
    func partitionImports(_ ranges: [Formatter.ImportRange]) -> [(
        ranges: [Formatter.ImportRange],
        sortByAttributes: Bool
    )] {
        var groupsBeforeOtherImports = [(
            ranges: [Formatter.ImportRange],
            sortByAttributes: Bool
        )]()
        var groupsAfterOtherImports = [(
            ranges: [Formatter.ImportRange],
            sortByAttributes: Bool
        )]()
        var otherImports = ranges

        for option in options.importGrouping {
            let isInGroup: (Formatter.ImportRange) -> Bool
            let groupedBeforeOtherImports: Bool
            let sortByAttributes: Bool
            switch option {
            case .testableFirst:
                isInGroup = { $0.isTestable }
                groupedBeforeOtherImports = true
                sortByAttributes = false
            case .testableLast:
                isInGroup = { $0.isTestable }
                groupedBeforeOtherImports = false
                sortByAttributes = false
            case .attributesLast:
                isInGroup = { $0.isAttributed }
                groupedBeforeOtherImports = false
                sortByAttributes = true
            case .alpha, .length, .accessControl:
                continue
            }

            // Each import joins the first group it matches, so an import that is both
            // `@testable` and `@_spi` is grouped using whichever option comes first.
            let group = otherImports.filter(isInGroup)
            otherImports.removeAll(where: isInGroup)

            if groupedBeforeOtherImports {
                groupsBeforeOtherImports.append((group, sortByAttributes))
            } else {
                groupsAfterOtherImports.append((group, sortByAttributes))
            }
        }

        return groupsBeforeOtherImports + [(otherImports, false)] + groupsAfterOtherImports
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
        // In a fragment the top of the file isn't necessarily present,
        // so hoisting imports could move them to an incorrect location.
        guard !options.fragment else { return }

        // Imports within a `#if` block are always left where they are.
        let groups = parseImports().filter { group in
            guard let first = group.first else { return false }
            return !isInsidePreprocessorCondition(at: first.range.lowerBound)
        }
        guard groups.count > 1 else { return }

        // Groups separated only by a blank line are preserved if each group can be
        // sorted individually without affecting the required sort order. Imports
        // below another declaration are always hoisted to the top of the file.
        let hasStrayImports = groups.indices.dropFirst().contains { i in
            hasCodeBetweenImportGroups(groups[i - 1], groups[i])
        }
        guard hasStrayImports || !canSortImportGroupsIndependently(groups) else { return }

        // Move the imports from the other groups into the first group
        let insertionIndex = groups[0].last!.range.upperBound
        let hoistedGroups = groups.dropFirst()
        let hoistedTokens = hoistedGroups.flatMap { group in
            group.flatMap { importRange -> [Token] in
                var rangeTokens = Array(tokens[importRange.range])
                while rangeTokens.first?.isLinebreak == true {
                    rangeTokens.removeFirst()
                }
                return [linebreakToken(for: insertionIndex)] + rangeTokens
            }
        }
        // Removing bottom-to-top keeps the earlier groups' indices valid
        for group in hoistedGroups.reversed() {
            removeImportGroupLines(group)
        }
        insert(hoistedTokens, at: insertionIndex)
    }

    /// Removes the lines containing the given import group, plus the blank line
    /// that preceded it, if any.
    func removeImportGroupLines(_ group: [Formatter.ImportRange]) {
        // An import's range starts at the linebreak that ends the previous line,
        // so the group's lines start at the following token.
        let startOfLine = group.first!.range.lowerBound
        let endOfLastLine = min(group.last!.range.upperBound + 1, tokens.count)
        let precededByBlankLine = last(.nonSpace, before: startOfLine)?.isLinebreak == true
        removeTokens(in: (precededByBlankLine ? startOfLine : startOfLine + 1) ..< endOfLastLine)
    }

    /// Whether the required sort order is satisfied by sorting each group individually,
    /// without any import having to move to a different group.
    func canSortImportGroupsIndependently(_ groups: [[Formatter.ImportRange]]) -> Bool {
        let sortedWithinGroups = groups.flatMap { sortRanges($0) }
        let sortedAcrossGroups = sortRanges(groups.flatMap { $0 })
        return sortedWithinGroups.map(\.range.lowerBound) == sortedAcrossGroups.map(\.range.lowerBound)
    }

    /// Whether there is any code between the end of the first import group and the start of the second
    func hasCodeBetweenImportGroups(_ group: [Formatter.ImportRange], _ nextGroup: [Formatter.ImportRange]) -> Bool {
        guard let start = group.last?.range.upperBound,
              let end = nextGroup.first?.range.lowerBound,
              start < end
        else { return false }
        return index(of: .nonSpaceOrCommentOrLinebreak, in: start ..< end) != nil
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
