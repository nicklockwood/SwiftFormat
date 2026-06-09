//
//  RedundantSwiftUIGroup.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 2025-12-19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant SwiftUI Group wrapper views in favor of @ViewBuilder
    static let redundantSwiftUIGroup = FormatRule(
        help: "Remove redundant SwiftUI Group wrapper views in favor of @ViewBuilder.",
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            let bodyScope: ClosedRange<Int>?
            let isBodyMember: Bool
            let isInsideViewType: Bool

            // Parse the declaration to get body scope and check if it's a body member
            if declaration.keyword == "var" || declaration.keyword == "let",
               let property = declaration.parsePropertyDeclaration()
            {
                bodyScope = property.body?.scopeRange
                // A var named "body" is only the protocol body if it's on a View
                // (ViewModifier.body must be a function, not a property)
                let isViewType = formatter.isViewType(declaration.parentType)
                let isViewModifierType = formatter.isViewModifierType(declaration.parentType)
                isBodyMember = property.identifier == "body" && isViewType
                isInsideViewType = isViewType || isViewModifierType
            } else if declaration.keyword == "func",
                      let function = formatter.parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
            {
                bodyScope = function.bodyRange
                // A func named "body" is only the protocol body if it's on a ViewModifier
                // (View.body must be a property, not a function)
                let isViewType = formatter.isViewType(declaration.parentType)
                let isViewModifierType = formatter.isViewModifierType(declaration.parentType)
                isBodyMember = function.name == "body" && isViewModifierType
                isInsideViewType = isViewType || isViewModifierType
            } else {
                return
            }

            guard let bodyScope else { return }

            // Only process declarations inside View/ViewModifier types
            // (we need @ViewBuilder to be valid for the replacement)
            guard isInsideViewType else { return }

            // Check if the body contains a top-level Group { } expression that can be removed
            guard let groupInfo = formatter.topLevelRedundantGroup(in: bodyScope) else { return }

            // Determine if we need @ViewBuilder after removing the Group
            // - If it's the body protocol requirement, @ViewBuilder is implied
            // - If the Group body is a single non-conditional expression, @ViewBuilder is not needed
            let hasExistingViewBuilder = formatter.indexOfViewBuilderAttribute(for: declaration) != nil
            let needsViewBuilder = !isBodyMember
                && !formatter.scopeBodyIsSingleNonConditionalExpression(at: groupInfo.closureStartIndex)

            // Determine where to add @ViewBuilder if needed, before performing any mutations.
            // This is before the modifiers (a lower index than the Group in the body), so it
            // stays valid after the Group is removed below.
            let addViewBuilderAt = needsViewBuilder && !hasExistingViewBuilder
                ? formatter.startOfModifiers(at: declaration.keywordIndex, includingAttributes: true)
                : nil

            // Remove the Group first so the @ViewBuilder insertion index above remains valid.
            formatter.removeRedundantGroup(
                groupStartIndex: groupInfo.groupStartIndex,
                groupEndIndex: groupInfo.groupEndIndex,
                closureBodyRange: groupInfo.closureBodyRange
            )

            if let addViewBuilderAt {
                formatter.insertViewBuilderAttribute(at: addViewBuilderAt)
            }
        }
    } examples: {
        """
        ```diff
          struct MyView: View {
            var body: some View {
        -     Group {
                Text("foo")
                Text("bar")
        -     }
            }
          }
        ```

        ```diff
          struct MyView: View {
        +   @ViewBuilder
            var content: some View {
        -     Group {
                Text("foo")
                Text("bar")
        -     }
            }
          }
        ```

        ```diff
          struct MyView: View {
            var body: some View {
        -     Group {
                Text(status)
        -     }
              .padding(.horizontal, 8)
            }
          }
        ```
        """
    }
}

extension Formatter {
    /// Information about a top-level redundant Group
    struct GroupInfo {
        let groupStartIndex: Int
        let groupEndIndex: Int
        let closureStartIndex: Int
        let closureBodyRange: ClosedRange<Int>
    }

    /// Finds a top-level Group { } call in the given scope that can be safely removed
    func topLevelRedundantGroup(in bodyScope: ClosedRange<Int>) -> GroupInfo? {
        // Find the first non-space/comment/linebreak token in the body
        guard let firstTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: bodyScope.lowerBound),
              firstTokenIndex < bodyScope.upperBound
        else { return nil }

        // Check if it's "Group"
        guard tokens[firstTokenIndex] == .identifier("Group") else { return nil }

        // Find the Group call structure and closure
        guard let groupCallInfo = parseGroupCall(startingAt: firstTokenIndex) else { return nil }

        // Get the body range inside the closure
        guard let closureBodyRange = closureBodyRange(closureStartIndex: groupCallInfo.closureStartIndex) else { return nil }

        // Check whether the Group has trailing modifiers (e.g. `.padding()`)
        let hasModifiers = index(of: .nonSpaceOrCommentOrLinebreak, after: groupCallInfo.groupEndIndex) != bodyScope.upperBound

        // A Group with modifiers can only be removed when it wraps a single view,
        // since the modifiers would otherwise apply to each view individually.
        if hasModifiers {
            // The modifiers must be the last thing in the body
            guard let modifierRange = parseExpressionRange(startingAt: firstTokenIndex),
                  index(of: .nonSpaceOrCommentOrLinebreak, after: modifierRange.upperBound) == bodyScope.upperBound
            else { return nil }

            // Only remove the Group if its body is a single, non-conditional view.
            // Conditional expressions and multiple views rely on the Group to combine
            // them into a single view that the modifiers can apply to.
            guard scopeBodyIsSingleNonConditionalExpression(at: groupCallInfo.closureStartIndex) else { return nil }
        }

        return GroupInfo(
            groupStartIndex: firstTokenIndex,
            groupEndIndex: groupCallInfo.groupEndIndex,
            closureStartIndex: groupCallInfo.closureStartIndex,
            closureBodyRange: closureBodyRange
        )
    }

    /// Parses a Group call and returns information about its structure
    func parseGroupCall(startingAt groupIndex: Int) -> (groupEndIndex: Int, closureStartIndex: Int)? {
        guard let nextToken = index(of: .nonSpaceOrCommentOrLinebreak, after: groupIndex) else { return nil }

        // Case 1: Group { } - trailing closure directly after identifier
        if tokens[nextToken] == .startOfScope("{"),
           let endOfClosure = endOfScope(at: nextToken)
        {
            return (groupEndIndex: endOfClosure, closureStartIndex: nextToken)
        }

        // Case 2: Group() { } or Group(content: { }) - parentheses first
        if tokens[nextToken] == .startOfScope("("),
           let endOfParens = endOfScope(at: nextToken)
        {
            // Check for trailing closure after parentheses: Group() { }
            if let afterParens = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfParens),
               tokens[afterParens] == .startOfScope("{"),
               let endOfClosure = endOfScope(at: afterParens)
            {
                return (groupEndIndex: endOfClosure, closureStartIndex: afterParens)
            }

            // Check for content closure inside parentheses: Group(content: { })
            if let contentLabel = index(of: .nonSpaceOrCommentOrLinebreak, after: nextToken),
               tokens[contentLabel] == .identifier("content"),
               let colon = index(of: .nonSpaceOrCommentOrLinebreak, after: contentLabel),
               tokens[colon] == .delimiter(":"),
               let closureStart = index(of: .nonSpaceOrCommentOrLinebreak, after: colon),
               tokens[closureStart] == .startOfScope("{")
            {
                // The end of the group expression is the closing paren
                return (groupEndIndex: endOfParens, closureStartIndex: closureStart)
            }
        }

        return nil
    }

    /// Gets the range of the body inside a closure (excluding braces)
    func closureBodyRange(closureStartIndex: Int) -> ClosedRange<Int>? {
        guard let closureEndIndex = endOfScope(at: closureStartIndex),
              closureStartIndex + 1 < closureEndIndex
        else { return nil }

        guard let firstToken = index(of: .nonSpaceOrCommentOrLinebreak, after: closureStartIndex),
              let lastToken = index(of: .nonSpaceOrCommentOrLinebreak, before: closureEndIndex),
              firstToken <= lastToken
        else { return nil }

        return firstToken ... lastToken
    }

    /// Removes a redundant Group, replacing it with its closure body contents
    func removeRedundantGroup(
        groupStartIndex: Int,
        groupEndIndex: Int,
        closureBodyRange: ClosedRange<Int>
    ) {
        // Extract the closure body tokens
        let bodyTokens = Array(tokens[closureBodyRange])

        // Remove the entire Group expression
        removeTokens(in: groupStartIndex ... groupEndIndex)

        // Insert the body tokens (indent rule will fix indentation)
        insert(bodyTokens, at: groupStartIndex)
    }

    /// Inserts an `@ViewBuilder` attribute on its own line before the declaration at the given index
    func insertViewBuilderAttribute(at index: Int) {
        // Any existing indentation before the insertion point now indents `@ViewBuilder`,
        // so the declaration that follows needs its own copy of the indentation.
        let currentIndent = currentIndentForLine(at: index)

        // Attributes are represented as `.keyword` tokens (e.g. `@objc`, `@main`). Inserting an
        // `.identifier` instead causes other rules like `organizeDeclarations` to misparse the
        // declaration and insert a spurious blank line after the attribute.
        var tokensToInsert: [Token] = [.keyword("@ViewBuilder"), linebreakToken(for: index)]
        if !currentIndent.isEmpty {
            tokensToInsert.append(.space(currentIndent))
        }
        insert(tokensToInsert, at: index)
    }
}
