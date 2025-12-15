//
//  RedundantViewBuilder.swift
//  SwiftFormat
//
//  Created by Miguel Jimenez on 2025-12-14.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant @ViewBuilder attributes
    static let redundantViewBuilder = FormatRule(
        help: "Remove redundant @ViewBuilder attribute when it's not needed."
    ) { formatter in
        // Collect all @ViewBuilder attributes to remove first (to avoid re-entrancy issues)
        var attributeIndicesToRemove = [Int]()

        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard let viewBuilderIndex = formatter.indexOfViewBuilderAttribute(for: declaration)
            else { return }

            var bodyScope: ClosedRange<Int>?
            var isBodyOnViewOrModifier = false

            // Try parsing as a property
            if declaration.keyword == "var" || declaration.keyword == "let",
               let property = declaration.parsePropertyDeclaration()
            {
                bodyScope = property.body?.scopeRange

                // Check if this is a `body` property on a View or ViewModifier type
                if property.identifier == "body",
                   let parentType = declaration.parentType,
                   parentType.conformances.contains(where: { conformance in
                       conformance.conformance.string == "View" || conformance.conformance.string == "ViewModifier"
                   })
                {
                    isBodyOnViewOrModifier = true
                }
            }
            // Try parsing as a function
            else if declaration.keyword == "func",
                    let function = formatter.parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
            {
                bodyScope = function.bodyRange

                // Check if this is a `body` function on a ViewModifier type
                if function.name == "body",
                   let parentType = declaration.parentType,
                   parentType.conformances.contains(where: { conformance in
                       conformance.conformance.string == "ViewModifier"
                   })
                {
                    isBodyOnViewOrModifier = true
                }
            }

            guard let bodyScope else { return }

            // Determine if @ViewBuilder is redundant
            let isRedundant: Bool

            if isBodyOnViewOrModifier {
                // Always redundant on View/ViewModifier body properties/methods
                isRedundant = true
            } else {
                // @ViewBuilder is redundant only if the body contains a single expression
                // and that expression is NOT an if/switch statement (which needs @ViewBuilder)
                isRedundant = formatter.scopeBodyIsSingleNonConditionalExpression(at: bodyScope.lowerBound)
            }

            if isRedundant {
                attributeIndicesToRemove.append(viewBuilderIndex)
            }
        }

        // Remove the attributes in reverse order to not invalidate indices
        for attributeIndex in attributeIndicesToRemove.reversed() {
            formatter.removeViewBuilderAttribute(at: attributeIndex)
        }
    } examples: {
        """
        ```diff
          struct MyView: View {
        -   @ViewBuilder
            var body: some View {
              Text("foo")
              Text("bar")
            }

        -   @ViewBuilder
            var helper: some View {
              VStack {
                Text("baaz")
                Text("quux")
              }
            }

            // Not redundant - multiple top-level views
            @ViewBuilder
            var helper2: some View {
              Text("foo")
              Text("bar")
            }
          }
        ```
        """
    }
}

extension Formatter {
    /// Finds the index of a @ViewBuilder attribute for the given declaration, if present
    func indexOfViewBuilderAttribute(for declaration: Declaration) -> Int? {
        let startOfModifiers = declaration.startOfModifiersIndex(includingAttributes: true)
        let keywordIndex = declaration.keywordIndex

        var index = startOfModifiers
        while index < keywordIndex {
            if tokens[index].string == "@ViewBuilder" {
                return index
            }
            index += 1
        }
        return nil
    }

    /// Removes a @ViewBuilder attribute at the given index, including the trailing linebreak if on its own line
    func removeViewBuilderAttribute(at attributeIndex: Int) {
        var startIndex = attributeIndex
        var endIndex = attributeIndex

        let nextNonSpaceIndex = index(of: .nonSpace, after: attributeIndex)
        let hasTrailingLinebreak = nextNonSpaceIndex != nil && tokens[nextNonSpaceIndex!].isLinebreak
        let hasTrailingSpace = attributeIndex + 1 < tokens.count && tokens[attributeIndex + 1].isSpace

        if hasTrailingLinebreak, let nextIndex = nextNonSpaceIndex {
            endIndex = nextIndex
        } else if hasTrailingSpace {
            endIndex = attributeIndex + 1
        }

        if hasTrailingLinebreak, attributeIndex > 0 {
            let prevIndex = attributeIndex - 1
            if tokens[prevIndex].isSpace,
               prevIndex > 0,
               tokens[prevIndex - 1].isLinebreak
            {
                startIndex = prevIndex
            }
        }

        removeTokens(in: startIndex ... endIndex)
    }

    /// Whether the body within this scope is a single expression that is NOT a conditional expression (if/switch)
    func scopeBodyIsSingleNonConditionalExpression(at startOfScopeIndex: Int) -> Bool {
        guard let endOfScopeIndex = endOfScope(at: startOfScopeIndex),
              startOfScopeIndex + 1 != endOfScopeIndex,
              let firstTokenInBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfScopeIndex + 1)
        else { return false }

        if tokens[firstTokenInBody] == .keyword("if") || tokens[firstTokenInBody] == .keyword("switch") {
            return false
        }

        guard let expressionRange = parseExpressionRange(startingAt: firstTokenInBody, allowConditionalExpressions: false)
        else { return false }

        return index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound) == endOfScopeIndex
    }
}
