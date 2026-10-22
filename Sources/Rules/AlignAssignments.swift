//
//  AlignAssignments.swift
//  SwiftFormat
//
//  Created by Ethan Pippin on 2026-10-20.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Align the `=` operators of neighboring property declarations and assignments
    static let alignAssignments = FormatRule(
        help: """
        Align the `=` of neighboring property declarations, enum case raw values, \
        and assignment statements.
        """,
        disabledByDefault: true,
        options: ["align-assignments"],
        sharedOptions: ["max-width", "indent", "tab-width", "asset-literals"]
    ) { formatter in
        formatter.alignAssignments()
    } examples: {
        """
        Assignments in the same scope are aligned until a blank line:

        ```diff
          struct DeathStar {
        -     let capacity = 25_000
        +     let capacity            = 25_000
              let commander: Person
        -     var isIndestructible = false
        +     var isIndestructible    = false
              var hasOnlyOneWeakPoint = true

              var shieldStrength = 1.0
        -     var crew = [Person]()
        +     var crew           = [Person]()
          }
        ```

        With `--align-assignments scope`, all assignments in the same scope are aligned,
        even when separated by blank lines:

        ```diff
          struct DeathStar {
        -     let capacity = 25_000
        +     let capacity         = 25_000
              let commander: Person

              var isIndestructible = false
          }
        ```

        Assignments are not aligned if doing so would exceed the `--max-width`.
        """
    }
}

extension Formatter {
    /// A group of assignments whose `=` operators are aligned to the same column
    struct AssignmentAlignmentGroup {
        /// The index of each `=` operator, and the width of its line up to the end of the left-hand side
        var assignments: [(equalsIndex: Int, lhsWidth: Int)]
        /// The column to align the operators to, one space after the longest left-hand side
        var column: Int
        /// The rightmost column the operators can be aligned to without exceeding the max width
        var maxColumn: Int

        init(equalsIndex: Int, lhsWidth: Int, maxColumn: Int) {
            assignments = [(equalsIndex, lhsWidth)]
            column = lhsWidth + 1
            self.maxColumn = maxColumn
        }

        /// Adds the assignment to the group, unless that would push a line past the max width
        mutating func add(equalsIndex: Int, lhsWidth: Int, maxColumn lineMaxColumn: Int) -> Bool {
            let newColumn = max(column, lhsWidth + 1)
            let newMaxColumn = min(maxColumn, lineMaxColumn)
            guard newColumn <= newMaxColumn else {
                return false
            }
            assignments.append((equalsIndex, lhsWidth))
            column = newColumn
            maxColumn = newMaxColumn
            return true
        }
    }

    /// Aligns the `=` operators of neighboring assignments in each scope
    func alignAssignments() {
        var groups = [AssignmentAlignmentGroup]()
        // The index of the group currently being built in each scope
        var groupIndexForScope = [Int: Int]()

        forEach(.operator("=", .infix)) { equalsIndex, _ in
            guard let startIndex = startOfAlignableAssignment(at: equalsIndex),
                  let lhsEndIndex = index(of: .nonSpace, before: equalsIndex)
            else { return }

            let lhsWidth = lineLength(upTo: lhsEndIndex + 1)
            var maxColumn = Int.max
            if options.maxWidth > 0 {
                maxColumn = options.maxWidth - lineLength(from: equalsIndex, upTo: endOfLine(at: equalsIndex))
            }

            let scopeIndex = startOfScope(at: startIndex) ?? -1
            if let groupIndex = groupIndexForScope[scopeIndex],
               let previousEqualsIndex = groups[groupIndex].assignments.last?.equalsIndex,
               options.alignAssignments == .scope || !containsBlankLine(between: previousEqualsIndex, and: startIndex),
               groups[groupIndex].add(equalsIndex: equalsIndex, lhsWidth: lhsWidth, maxColumn: maxColumn)
            {
                return
            }
            groupIndexForScope[scopeIndex] = groups.count
            groups.append(AssignmentAlignmentGroup(equalsIndex: equalsIndex, lhsWidth: lhsWidth, maxColumn: maxColumn))
        }

        // Update the spacing from the bottom up, so inserted tokens don't invalidate the remaining indices
        let spacing = groups.flatMap { group in
            group.assignments.map { (equalsIndex: $0.equalsIndex, width: group.column - $0.lhsWidth) }
        }
        for (equalsIndex, width) in spacing.sorted(by: { $0.equalsIndex > $1.equalsIndex }) {
            let space = String(repeating: " ", count: width)
            if tokens[equalsIndex - 1] != .space(space) {
                insertSpace(space, at: tokens[equalsIndex - 1].isSpace ? equalsIndex - 1 : equalsIndex)
            }
        }
    }

    /// Whether there is a blank line between the specified indices, ignoring any nested scopes
    func containsBlankLine(between startIndex: Int, and endIndex: Int) -> Bool {
        var index = startIndex
        while let linebreakIndex = self.index(of: .linebreak, in: index ..< endIndex) {
            if next(.nonSpace, after: linebreakIndex)?.isLinebreak == true {
                return true
            }
            index = linebreakIndex + 1
        }
        return false
    }
}
