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

            let bodyScope: ClosedRange<Int>?
            let isBodyMember: Bool

            // Parse the declaration to get body scope and check if it's a body member
            if declaration.keyword == "var" || declaration.keyword == "let",
               let property = declaration.parsePropertyDeclaration()
            {
                bodyScope = property.body?.scopeRange
                // A var named "body" is only the protocol body if it's on a View
                // (ViewModifier.body must be a function, not a property)
                isBodyMember = property.identifier == "body" && formatter.isViewType(declaration.parentType)
            } else if declaration.keyword == "func",
                      let function = formatter.parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
            {
                bodyScope = function.bodyRange
                // A func named "body" is only the protocol body if it's on a ViewModifier
                // (View.body must be a property, not a function)
                isBodyMember = function.name == "body" && formatter.isViewModifierType(declaration.parentType)
            } else {
                return
            }

            guard let bodyScope else { return }

            // @ViewBuilder is redundant if:
            // 1. It's the body protocol requirement of a View/ViewModifier, OR
            // 2. The body contains only a single non-conditional expression
            let isRedundant = isBodyMember
                || formatter.scopeBodyIsSingleNonConditionalExpression(at: bodyScope.lowerBound)

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
    /// Whether the given type conforms to View
    func isViewType(_ type: TypeDeclaration?) -> Bool {
        guard let type else { return false }
        return type.conformances.contains { conformance in
            conformance.conformance.string == "View"
        }
    }

    /// Whether the given type conforms to ViewModifier
    func isViewModifierType(_ type: TypeDeclaration?) -> Bool {
        guard let type else { return false }
        return type.conformances.contains { conformance in
            conformance.conformance.string == "ViewModifier"
        }
    }

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

        // Check if there's a leading space (between another attribute and this one)
        let hasLeadingSpace = attributeIndex > 0 && tokens[attributeIndex - 1].isSpace
        let leadingSpaceIsAfterAttribute = hasLeadingSpace && attributeIndex > 1 && !tokens[attributeIndex - 2].isLinebreak

        let nextNonSpaceIndex = index(of: .nonSpace, after: attributeIndex)
        let hasTrailingLinebreak = nextNonSpaceIndex != nil && tokens[nextNonSpaceIndex!].isLinebreak
        let hasTrailingSpace = attributeIndex + 1 < tokens.count && tokens[attributeIndex + 1].isSpace

        if leadingSpaceIsAfterAttribute {
            // Remove the space before @ViewBuilder (space between attributes)
            startIndex = attributeIndex - 1
            // Don't remove trailing linebreak - preserve the line structure
            // Don't remove trailing space - it separates from the next token
        } else {
            // @ViewBuilder is at the start of the line (possibly with indentation)
            if hasTrailingLinebreak, let nextIndex = nextNonSpaceIndex {
                endIndex = nextIndex
                // Also remove leading indentation
                if hasLeadingSpace, attributeIndex > 1, tokens[attributeIndex - 2].isLinebreak {
                    startIndex = attributeIndex - 1
                }
            } else if hasTrailingSpace {
                endIndex = attributeIndex + 1
            }
        }

        removeTokens(in: startIndex ... endIndex)
    }

    /// Whether the body is a single expression that is not a conditional (if/switch).
    /// Conditional expressions need @ViewBuilder when branches return different types.
    func scopeBodyIsSingleNonConditionalExpression(at startOfScopeIndex: Int) -> Bool {
        guard let firstTokenInBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfScopeIndex),
              tokens[firstTokenInBody] != .keyword("if"),
              tokens[firstTokenInBody] != .keyword("switch")
        else { return false }
        return scopeBodyIsSingleExpression(at: startOfScopeIndex)
    }
}
