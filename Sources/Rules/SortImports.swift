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
        var allImportGroups = formatter.parseImports()
        guard !allImportGroups.isEmpty else { return }

        // Merge separate import groups into one and hoist stray imports to the top.
        if allImportGroups.count > 1 {
            formatter.mergeAndHoistImports(&allImportGroups)
        }

        // Sort each import group
        for var importRanges in allImportGroups.reversed() {
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

        ```diff
          import Foundation
        + import UIKit

          struct Foo {}
        -
        - import UIKit
        ```
        """
    }
}

extension Formatter {
    /// Merges all file-scope import groups into a single contiguous block at the
    /// top of the file, hoisting stray imports that appear after non-import code.
    func mergeAndHoistImports(_ allImportGroups: inout [[ImportRange]]) {
        guard allImportGroups.count > 1 else { return }

        // Pass 1: Collapse blank lines between adjacent import groups (no code between them).
        // Work bottom-to-top for stable indices.
        var didMerge = false
        for groupIndex in (1 ..< allImportGroups.count).reversed() {
            let group = allImportGroups[groupIndex]
            guard let firstImport = group.first else { continue }

            if isInsidePreprocessorCondition(at: firstImport.range.lowerBound) {
                continue
            }

            let previousGroup = allImportGroups[groupIndex - 1]
            guard let previousLast = previousGroup.last else { continue }

            let gapStart = previousLast.range.upperBound
            let gapEnd = firstImport.range.lowerBound

            // Only merge groups separated by whitespace-only gaps
            guard isOnlyWhitespaceBetween(from: gapStart, to: gapEnd) else {
                continue
            }

            // Find the end of whitespace in the current group's range
            var wsEnd = gapEnd
            while wsEnd < firstImport.range.upperBound,
                  tokens[wsEnd].isSpaceOrLinebreak
            {
                wsEnd += 1
            }

            // Only collapse if there's actually extra whitespace (blank line)
            let linebreakCount = tokens[gapStart ..< wsEnd].filter(\.isLinebreak).count
            guard linebreakCount > 1 else { continue }

            let linebreak = linebreakToken(for: gapStart)
            replaceTokens(in: gapStart ..< wsEnd, with: [linebreak])
            didMerge = true
        }

        if didMerge {
            allImportGroups = parseImports()
        }

        // Pass 2: Hoist stray imports (after non-import code) to the first file-scope group.
        guard allImportGroups.count > 1 else { return }

        // Find the first import group NOT inside a preprocessor condition
        guard let targetGroupIndex = allImportGroups.indices.first(where: {
            guard let firstImport = allImportGroups[$0].first else { return false }
            return !isInsidePreprocessorCondition(at: firstImport.range.lowerBound)
        }) else { return }

        var hoistedTokenArrays = [[Token]]()
        var removalRanges = [Range<Int>]()

        for groupIndex in ((targetGroupIndex + 1) ..< allImportGroups.count).reversed() {
            let group = allImportGroups[groupIndex]
            guard let firstImport = group.first, let lastImport = group.last else { continue }

            if isInsidePreprocessorCondition(at: firstImport.range.lowerBound) {
                continue
            }

            let previousGroup = allImportGroups[groupIndex - 1]
            guard let previousLast = previousGroup.last else { continue }

            let gapStart = previousLast.range.upperBound
            let gapEnd = firstImport.range.lowerBound

            // Only hoist if there's actual non-whitespace, non-import code between groups
            guard !isOnlyImportRelatedContent(from: gapStart, to: gapEnd) else {
                continue
            }

            for importRange in group {
                hoistedTokenArrays.append(extractImportStatementTokens(from: importRange))
            }

            var removeStart = firstImport.range.lowerBound
            let removeEnd = lastImport.range.upperBound

            while removeStart > 0, tokens[removeStart - 1].isSpaceOrLinebreak {
                removeStart -= 1
            }

            removalRanges.append(removeStart ..< removeEnd)
        }

        guard !hoistedTokenArrays.isEmpty,
              let lastExistingImport = allImportGroups[targetGroupIndex].last
        else { return }

        for range in removalRanges {
            removeTokens(in: range)
        }

        let insertionPoint = lastExistingImport.range.upperBound
        let linebreak = linebreakToken(for: insertionPoint)

        var insertTokens = [Token]()
        for importTokens in hoistedTokenArrays {
            insertTokens.append(linebreak)
            insertTokens.append(contentsOf: importTokens)
        }

        insert(insertTokens, at: insertionPoint)
        allImportGroups = parseImports()
    }

    /// Returns true if tokens between start and end are only whitespace
    private func isOnlyWhitespaceBetween(from start: Int, to end: Int) -> Bool {
        for i in start ..< end {
            if !tokens[i].isSpaceOrLinebreak {
                return false
            }
        }
        return true
    }

    /// Returns true if tokens between start and end contain only whitespace,
    /// comments, import-related attributes, and import statements (no real code)
    private func isOnlyImportRelatedContent(from start: Int, to end: Int) -> Bool {
        for i in start ..< end {
            let token = tokens[i]
            if token.isSpaceOrCommentOrLinebreak { continue }
            if token.isAttribute { continue }
            if token == .keyword("import") { continue }
            if case .keyword(let kw) = token, _FormatRules.aclModifiers.contains(kw) { continue }
            if case .identifier = token { continue }
            if case .operator(".", _) = token { continue }
            return false
        }
        return true
    }

    /// Whether the token at the given index is inside a `#if` / `#endif` block
    private func isInsidePreprocessorCondition(at index: Int) -> Bool {
        var depth = 0
        for i in 0 ..< index {
            if tokens[i] == .startOfScope("#if") {
                depth += 1
            } else if tokens[i] == .endOfScope("#endif") {
                depth -= 1
            }
        }
        return depth > 0
    }

    /// Extracts the core import statement tokens, stripping leading comment lines
    /// that parseImports may have attached.
    private func extractImportStatementTokens(from importRange: ImportRange) -> [Token] {
        let rangeTokens = Array(tokens[importRange.range])
        // Find the import keyword within the range
        guard let importKeywordOffset = rangeTokens.firstIndex(where: { $0 == .keyword("import") }) else {
            return rangeTokens
        }
        // Walk backwards from import to find start of this import line (attributes, access modifiers)
        var startOffset = importKeywordOffset
        for j in (0 ..< importKeywordOffset).reversed() {
            let token = rangeTokens[j]
            if token.isLinebreak {
                startOffset = j + 1
                break
            }
            if j == 0 {
                startOffset = 0
            }
        }
        // Skip leading whitespace
        while startOffset < importKeywordOffset, rangeTokens[startOffset].isSpace {
            startOffset += 1
        }
        return Array(rangeTokens[startOffset...])
    }

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
