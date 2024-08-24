//
//  ConditionalAssignment.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let conditionalAssignment = FormatRule(
        help: "Assign properties using if / switch expressions.",
        examples: """
        ```diff
        - let foo: String
        - if condition {
        + let foo = if condition {
        -     foo = "foo"
        +     "foo"
          } else {
        -     foo = "bar"
        +     "bar"
          }

        - let foo: String
        - switch condition {
        + let foo = switch condition {
          case true:
        -     foo = "foo"
        +     "foo"
          case false:
        -     foo = "bar"
        +     "bar"
          }

        // With --condassignment always (disabled by default)
        - switch condition {
        + foo.bar = switch condition {
          case true:
        -     foo.bar = "baaz"
        +     "baaz"
          case false:
        -     foo.bar = "quux"
        +     "quux"
          }
        ```
        """,
        orderAfter: [.redundantReturn],
        options: ["condassignment"]
    ) { formatter in
        // If / switch expressions were added in Swift 5.9 (SE-0380)
        guard formatter.options.swiftVersion >= "5.9" else {
            return
        }

        formatter.forEach(.keyword) { startOfConditional, keywordToken in
            // Look for an if/switch expression where the first branch starts with `identifier =`
            guard ["if", "switch"].contains(keywordToken.string),
                  let conditionalBranches = formatter.conditionalBranches(at: startOfConditional),
                  var startOfFirstBranch = conditionalBranches.first?.startOfBranch
            else { return }

            // Traverse any nested if/switch branches until we find the first code branch
            while let firstTokenInBranch = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: startOfFirstBranch),
                  ["if", "switch"].contains(formatter.tokens[firstTokenInBranch].string),
                  let nestedConditionalBranches = formatter.conditionalBranches(at: firstTokenInBranch),
                  let startOfNestedBranch = nestedConditionalBranches.first?.startOfBranch
            {
                startOfFirstBranch = startOfNestedBranch
            }

            // Check if the first branch starts with the pattern `lvalue =`.
            guard let firstTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: startOfFirstBranch),
                  let lvalueRange = formatter.parseExpressionRange(startingAt: firstTokenIndex),
                  let equalsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: lvalueRange.upperBound),
                  formatter.tokens[equalsIndex] == .operator("=", .infix)
            else { return }

            guard conditionalBranches.allSatisfy({ formatter.isExhaustiveSingleStatementAssignment($0, lvalueRange: lvalueRange) }),
                  formatter.conditionalBranchesAreExhaustive(conditionKeywordIndex: startOfConditional, branches: conditionalBranches)
            else {
                return
            }

            // If this expression follows a property like `let identifier: Type`, we just
            // have to insert an `=` between property and the conditional.
            //  - Find the introducer (let/var), parse the property, and verify that the identifier
            //    matches the identifier assigned on each conditional branch.
            if let introducerIndex = formatter.indexOfLastSignificantKeyword(at: startOfConditional, excluding: ["if", "switch"]),
               ["let", "var"].contains(formatter.tokens[introducerIndex].string),
               let property = formatter.parsePropertyDeclaration(atIntroducerIndex: introducerIndex),
               formatter.tokens[lvalueRange.lowerBound].string == property.identifier,
               property.value == nil,
               let typeRange = property.type?.range,
               let nextTokenAfterProperty = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: typeRange.upperBound),
               nextTokenAfterProperty == startOfConditional
            {
                formatter.removeAssignmentFromAllBranches(of: conditionalBranches)

                let rangeBetweenTypeAndConditional = (typeRange.upperBound + 1) ..< startOfConditional

                // If there are no comments between the type and conditional,
                // we reformat it from:
                //
                // let foo: Foo\n
                // if condition {
                //
                // to:
                //
                // let foo: Foo = if condition {
                //
                if formatter.tokens[rangeBetweenTypeAndConditional].allSatisfy(\.isSpaceOrLinebreak) {
                    formatter.replaceTokens(in: rangeBetweenTypeAndConditional, with: [
                        .space(" "),
                        .operator("=", .infix),
                        .space(" "),
                    ])
                }

                // But if there are comments, then we shouldn't just delete them.
                // Instead we just insert `= ` after the type.
                else {
                    formatter.insert([.operator("=", .infix), .space(" ")], at: startOfConditional)
                }
            }

            // Otherwise we insert an `identifier =` before the if/switch expression
            else if !formatter.options.conditionalAssignmentOnlyAfterNewProperties {
                // In this case we should only apply the conversion if this is a top-level condition,
                // and not nested in some parent condition. In large complex if/switch conditions
                // with multiple layers of nesting, for example, this prevents us from making any
                // changes unless the entire set of nested conditions can be converted as a unit.
                //  - First attempt to find and parse a parent if / switch condition.
                var startOfParentScope = formatter.startOfScope(at: startOfConditional)

                // If we're inside a switch case, expand to look at the whole switch statement
                while let currentStartOfParentScope = startOfParentScope,
                      formatter.tokens[currentStartOfParentScope] == .startOfScope(":"),
                      let caseToken = formatter.index(of: .endOfScope("case"), before: currentStartOfParentScope)
                {
                    startOfParentScope = formatter.startOfScope(at: caseToken)
                }

                if let startOfParentScope = startOfParentScope,
                   let mostRecentIfOrSwitch = formatter.index(of: .keyword, before: startOfParentScope, if: { ["if", "switch"].contains($0.string) }),
                   let conditionalBranches = formatter.conditionalBranches(at: mostRecentIfOrSwitch),
                   let startOfFirstParentBranch = conditionalBranches.first?.startOfBranch,
                   let endOfLastParentBranch = conditionalBranches.last?.endOfBranch,
                   // If this condition is contained within a parent condition, do nothing.
                   // We should only convert the entire set of nested conditions together as a unit.
                   (startOfFirstParentBranch ... endOfLastParentBranch).contains(startOfConditional)
                { return }

                let lvalueTokens = formatter.tokens[lvalueRange]

                // Now we can remove the `identifier =` from each branch,
                // and instead add it before the if / switch expression.
                formatter.removeAssignmentFromAllBranches(of: conditionalBranches)

                let identifierEqualsTokens = lvalueTokens + [
                    .space(" "),
                    .operator("=", .infix),
                    .space(" "),
                ]

                formatter.insert(identifierEqualsTokens, at: startOfConditional)
            }
        }
    }
}

extension Formatter {
    // Whether or not the conditional statement that starts at the given index
    // has branches that are exhaustive
    func conditionalBranchesAreExhaustive(
        conditionKeywordIndex: Int,
        branches: [Formatter.ConditionalBranch]
    ) -> Bool {
        // Switch statements are compiler-guaranteed to be exhaustive
        if tokens[conditionKeywordIndex] == .keyword("switch") {
            return true
        }

        // If statements are only exhaustive if the last branch
        // is `else` (not `else if`).
        else if tokens[conditionKeywordIndex] == .keyword("if"),
                let lastCondition = branches.last,
                let tokenBeforeLastCondition = index(of: .nonSpaceOrCommentOrLinebreak, before: lastCondition.startOfBranch)
        {
            return tokens[tokenBeforeLastCondition] == .keyword("else")
        }

        return false
    }

    // Whether or not the given conditional branch body qualifies as a single statement
    // that assigns a value to `identifier`. This is either:
    //  1. a single assignment to `lvalue =`
    //  2. a single `if` or `switch` statement where each of the branches also qualify,
    //     and the statement is exhaustive.
    func isExhaustiveSingleStatementAssignment(_ branch: Formatter.ConditionalBranch, lvalueRange: ClosedRange<Int>) -> Bool {
        guard let firstTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch) else { return false }

        // If this is an if/switch statement, verify that all of the branches are also
        // single-statement assignments and that the statement is exhaustive.
        if let conditionalBranches = conditionalBranches(at: firstTokenIndex),
           let lastConditionalStatement = conditionalBranches.last
        {
            let allBranchesAreExhaustiveSingleStatement = conditionalBranches.allSatisfy { branch in
                isExhaustiveSingleStatementAssignment(branch, lvalueRange: lvalueRange)
            }

            let isOnlyStatementInScope = next(.nonSpaceOrCommentOrLinebreak, after: lastConditionalStatement.endOfBranch)?.isEndOfScope == true

            let isExhaustive = conditionalBranchesAreExhaustive(
                conditionKeywordIndex: firstTokenIndex,
                branches: conditionalBranches
            )

            return allBranchesAreExhaustiveSingleStatement
                && isOnlyStatementInScope
                && isExhaustive
        }

        // Otherwise we expect this to be of the pattern `lvalue = (statement)`
        else if let firstExpressionRange = parseExpressionRange(startingAt: firstTokenIndex),
                tokens[firstExpressionRange] == tokens[lvalueRange],
                let equalsIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: firstExpressionRange.upperBound),
                tokens[equalsIndex] == .operator("=", .infix),
                let valueStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex)
        {
            // We know this branch starts with `identifier =`, but have to check that the
            // remaining code in the branch is a single statement. To do that we can
            // create a temporary formatter with the branch body _excluding_ `identifier =`.
            let assignmentStatementRange = valueStartIndex ..< branch.endOfBranch
            var tempScopeTokens = [Token]()
            tempScopeTokens.append(.startOfScope("{"))
            tempScopeTokens.append(contentsOf: tokens[assignmentStatementRange])
            tempScopeTokens.append(.endOfScope("}"))

            let tempFormatter = Formatter(tempScopeTokens, options: options)
            guard tempFormatter.blockBodyHasSingleStatement(
                atStartOfScope: 0,
                includingConditionalStatements: true,
                includingReturnStatements: false
            ) else {
                return false
            }

            // In Swift 5.9, there's a bug that prevents you from writing an
            // if or switch expression using an `as?` on one of the branches:
            // https://github.com/apple/swift/issues/68764
            //
            //  let result = if condition {
            //    foo as? String
            //  } else {
            //    "bar"
            //  }
            //
            if tempFormatter.conditionalBranchHasUnsupportedCastOperator(startOfScopeIndex: 0) {
                return false
            }

            return true
        }

        return false
    }

    // Removes the `identifier =` from each conditional branch
    func removeAssignmentFromAllBranches(of conditionalBranches: [ConditionalBranch]) {
        forEachRecursiveConditionalBranch(in: conditionalBranches) { branch in
            guard let firstTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch),
                  let firstExpressionRange = parseExpressionRange(startingAt: firstTokenIndex),
                  let equalsIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: firstExpressionRange.upperBound),
                  tokens[equalsIndex] == .operator("=", .infix),
                  let valueStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex)
            else { return }

            removeTokens(in: firstTokenIndex ..< valueStartIndex)
        }
    }
}
