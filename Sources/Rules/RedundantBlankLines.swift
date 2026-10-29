//
//  RedundantBlankLines.swift
//  SwiftFormat
//
//  Created by Ethan Pippin on 2026-10-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove blank lines that separate tightly connected syntax
    static let redundantBlankLines = FormatRule(
        help: """
        Remove redundant blank lines within declaration and control-flow headers, \
        and between expression prefixes and their operands.
        """
    ) { formatter in
        formatter.forEach(.attribute) { i, _ in
            guard let endOfAttribute = formatter.endOfAttribute(at: i),
                  let linebreakIndex = formatter.index(of: .nonSpaceOrComment, after: endOfAttribute),
                  formatter.tokens[linebreakIndex].isLinebreak,
                  let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: linebreakIndex),
                  // Preserve blank lines before comments
                  !formatter.tokens[nextIndex].isComment,
                  let lastLinebreakIndex = formatter.index(of: .linebreak, before: nextIndex),
                  lastLinebreakIndex > linebreakIndex,
                  formatter.isDeclarationAttribute(at: i)
                  || formatter.isNonDeclarationAttribute(at: i, followedBy: nextIndex)
            else { return }

            formatter.removeTokens(in: linebreakIndex + 1 ... lastLinebreakIndex)
        }
        formatter.forEach(.linebreak) { i, _ in
            guard let previous = formatter.index(of: .nonSpace, before: i),
                  !formatter.tokens[previous].isLinebreak,
                  let next = formatter.index(of: .nonSpaceOrLinebreak, after: i),
                  let lastLinebreak = formatter.index(of: .linebreak, before: next),
                  lastLinebreak > i,
                  formatter.blankLineSeparatesConnectedSyntax(previous, next)
            else { return }
            formatter.removeTokens(in: i + 1 ... lastLinebreak)
        }
    } examples: {
        """
        ```diff
          @MainActor
        -
          struct Foo {
              @State
        -
              var bar = 0
          }
        ```

        ```diff
          public
        -
          final class Foo {}

          let value = try
        -
              await load()
        ```

        ```diff
          let value:
        -
              Int =
        -
              0

          func foo() -> some
        -
              View { content }
        ```

        Ordinary line wrapping is preserved. Blank lines between statements, arguments,
        collection elements, and at scope boundaries are left to other rules.
        """
    }
}

extension Formatter {
    /// Whether two tokens separated by whitespace belong to tightly connected syntax.
    /// Comments and conditional compilation boundaries deliberately prevent matching.
    func blankLineSeparatesConnectedSyntax(_ previous: Int, _ next: Int) -> Bool {
        let left = tokens[previous]
        let right = tokens[next]
        guard !left.isComment, !right.isComment,
              currentScope(at: previous)?.isMultilineStringDelimiter != true
        else { return false }

        // Declaration modifiers, including parenthesized modifiers such as private(set).
        // A standalone async may belong to a preceding bodyless function, not the following let.
        if left.isModifierKeyword || left == .endOfScope(")") || left.isAttribute,
           left.string != "async",
           right.isModifierKeyword || right.isDeclarationTypeKeyword || right.isAttribute,
           let keyword = index(after: previous, where: \.isDeclarationTypeKeyword),
           startOfModifiers(at: keyword, includingAttributes: true) <= previous,
           startOfScope(at: next) == startOfScope(at: keyword)
        {
            return true
        }

        // A declaration keyword and its name (not its body or argument list).
        if left.isDeclarationTypeKeyword,
           right.isIdentifier || (left == .keyword("func") || left == .keyword("operator")) && right.isOperator
        {
            return true
        }

        if [.keyword("let"), .keyword("var")].contains(left), right == .startOfScope("(") {
            return true
        }

        // Require a parsed operand rather than treating every occurrence of await as a prefix.
        var prefix = previous
        if left.isUnwrapOperator,
           let tryIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: previous),
           tokens[tryIndex] == .keyword("try")
        {
            prefix = tryIndex
        }
        if [Token.keyword("try"), .keyword("await")].contains(tokens[prefix]),
           let expression = parseExpressionRange(startingAt: prefix), expression.upperBound >= next
        {
            return true
        }

        if right.isPropertyAccessorKeyword, left.isModifierKeyword,
           isAccessorKeyword(at: startOfModifiers(at: next, includingAttributes: true), checkKeyword: false)
        {
            return true
        }
        if left == .identifier("async"), right == .keyword("let") {
            // A bodyless function can end in async immediately before a new declaration.
            if let functionKeyword = index(before: previous, where: \.isFunctionDeclarationKeyword),
               let function = parseFunctionDeclaration(keywordIndex: functionKeyword),
               function.effectsRange?.contains(previous) == true
            {
                return false
            }
            return true
        }
        if [.keyword("if"), .keyword("guard"), .keyword("while"), .keyword("switch"), .keyword("throw")].contains(left),
           parseExpressionRange(startingAt: next) != nil || [.keyword("let"), .keyword("var"), .keyword("case")].contains(right)
        {
            return true
        }
        if left == .keyword("catch"), right == .keyword("let") || parseExpressionRange(startingAt: next) != nil {
            return true
        }
        if left == .delimiter(":"), ["for", "while", "repeat", "if", "switch", "do"].contains(right.string),
           let label = index(of: .nonSpaceOrCommentOrLinebreak, before: previous), tokens[label].isIdentifier
        {
            return true
        }
        if left == .keyword("else"), right == .keyword("if") {
            return true
        }
        if left == .keyword("in"), lastSignificantKeyword(at: previous, excluding: ["in"]) == "for",
           parseExpressionRange(startingAt: next) != nil
        {
            return true
        }
        if right == .keyword("in"), lastSignificantKeyword(at: previous, excluding: ["let", "var", "case"]) == "for" {
            return true
        }
        if left == .keyword("let") || left == .keyword("var"), right == .operator(".", .prefix),
           isConditionalStatement(at: previous) || last(.nonSpaceOrCommentOrLinebreak, before: previous) == .endOfScope("case")
        {
            return true
        }
        return blankLineIsInDeclarationHeader(previous, next)
    }

    /// Classify gaps using parsed headers, never an entire declaration (which can include
    /// grouped initializer expressions, trailing comments, or unrelated local statements).
    func blankLineIsInDeclarationHeader(_ previous: Int, _ next: Int) -> Bool {
        let left = tokens[previous]
        let right = tokens[next]
        // Scope padding and comma-separated grouping belong to independent rules.
        guard !left.isStartOfScope, !right.isEndOfScope, left != .delimiter(","),
              right != .startOfScope("{"), right != .keyword("else"),
              !left.isComment, !right.isComment
        else { return false }

        // Avoid parsing declarations for ordinary gaps between statements or expressions.
        let headerSyntax: Set = [
            ":", "=", "->", "where", "in", "...", "async", "throws", "rethrows",
            "some", "any", "inout", "borrowing", "consuming", "sending", "repeat", "each",
        ]
        guard left.isIdentifier && right.isIdentifier || left.isAttribute || left.isModifierKeyword
            || headerSyntax.contains(left.string) || headerSyntax.contains(right.string)
            || right == .startOfScope("(") || right == .startOfScope("<")
        else { return false }

        // Property annotations and the edges of their initializer, not its interior.
        if let keyword = index(before: next, where: { [.keyword("let"), .keyword("var")].contains($0) }),
           let property = parsePropertyDeclaration(atIntroducerIndex: keyword),
           let end = property.value?.expressionRange.lowerBound ?? property.type?.range.upperBound,
           previous >= keyword, next <= end
        {
            return true
        }

        if let keyword = index(before: next, where: \.isFunctionDeclarationKeyword),
           let function = parseFunctionDeclaration(keywordIndex: keyword)
        {
            if previous >= keyword, next <= function.argumentsRange.lowerBound {
                return true
            }
            let end = function.whereClauseRange?.upperBound ?? function.returnType?.range.upperBound
                ?? function.effectsRange?.upperBound ?? function.argumentsRange.upperBound
            if previous >= function.argumentsRange.upperBound, next <= end {
                return true
            }
        }

        // Each parameter has its own header. Stop at the first token of its default value.
        if let scope = startOfScope(at: next), tokens[scope] == .startOfScope("("),
           isBlankLineParameterScope(scope),
           let parameter = commaSeparatedElementsInScope(startOfScope: scope).first(where: {
               $0.contains(previous) && $0.contains(next)
           }),
           let colon = index(of: .delimiter(":"), in: parameter),
           let typeStart = index(of: .nonSpaceOrCommentOrLinebreak, after: colon),
           let type = parseType(at: typeStart)
        {
            var end = type.range.upperBound
            if let suffix = index(of: .nonSpaceOrCommentOrLinebreak, after: end), tokens[suffix].string == "..." {
                end = suffix
            }
            if let equals = index(of: .nonSpaceOrCommentOrLinebreak, after: end),
               tokens[equals] == .operator("=", .infix),
               let value = index(of: .nonSpaceOrCommentOrLinebreak, after: equals),
               parseExpressionRange(startingAt: value) != nil
            {
                end = value
            }
            if next <= end {
                return true
            }
        }

        // Type inheritance and where clauses, including generic constraints.
        if let keyword = index(before: next, where: { $0.isKeyword && Token.swiftTypeKeywords.contains($0.string) }),
           let name = index(of: .nonSpaceOrCommentOrLinebreak, after: keyword),
           let type = parseType(at: name),
           let body = index(of: .startOfScope("{"), after: type.range.upperBound),
           previous >= keyword, next < body,
           startOfScope(at: next) == startOfScope(at: keyword)
        {
            return true
        }
        if currentScope(at: next) == .startOfScope("<"), left == .delimiter(":") || right == .delimiter(":") {
            return true
        }

        // Type aliases, associated types, and enum raw values.
        if let keyword = indexOfLastSignificantKeyword(at: previous),
           ["typealias", "associatedtype", "case"].contains(tokens[keyword].string),
           let name = index(of: .nonSpaceOrCommentOrLinebreak, after: keyword), tokens[name].isIdentifier,
           let separator = index(of: .nonSpaceOrCommentOrLinebreak, after: name),
           [.operator("=", .infix), .delimiter(":")].contains(tokens[separator]),
           let value = index(of: .nonSpaceOrCommentOrLinebreak, after: separator),
           let end = tokens[keyword] == .keyword("case") ? value : parseType(at: value)?.range.upperBound,
           previous >= keyword, next <= end
        {
            return true
        }

        // A closure's signature is separate from its body, even though both use the same braces.
        if let scope = startOfScope(at: next), tokens[scope] == .startOfScope("{"),
           isStartOfClosure(at: scope), let closure = parseClosureArguments(at: scope),
           let parameters = closure.parametersRange,
           previous >= parameters.upperBound, next <= closure.inKeywordIndex
        {
            return true
        }

        // Accessor effects are not declarations in the declaration tree.
        if let accessor = index(before: next, where: \.isPropertyAccessorKeyword),
           isAccessorKeyword(at: accessor),
           let effects = parseFunctionDeclarationEffectsClause(at: accessor),
           previous >= accessor, next <= effects.range.upperBound
        {
            return true
        }
        return false
    }

    /// Parameters in declarations and closure signatures, excluding calls and tuple values.
    func isBlankLineParameterScope(_ scope: Int) -> Bool {
        if isInClosureArguments(at: scope) {
            return true
        }
        guard let keyword = index(before: scope, where: \.isFunctionDeclarationKeyword) else { return false }
        return parseFunctionDeclaration(keywordIndex: keyword)?.argumentsRange.lowerBound == scope
    }

    func isNonDeclarationAttribute(at attribute: Int, followedBy next: Int) -> Bool {
        if tokens[attribute].string == "@unknown", tokens[next] == .endOfScope("default") {
            return true
        }
        if tokens[next].string.hasPrefix("#"), !["#if", "#elseif", "#else", "#endif"].contains(tokens[next].string) {
            return true
        }
        return tokens[next].isPropertyAccessorKeyword && isAccessorKeyword(
            at: startOfModifiers(at: next, includingAttributes: true), checkKeyword: false
        )
    }

    /// Whether the attribute at the given index applies to a declaration
    func isDeclarationAttribute(at attributeIndex: Int) -> Bool {
        guard let keywordIndex = index(after: attributeIndex, where: \.isDeclarationTypeKeyword) else {
            return false
        }
        return startOfModifiers(at: keywordIndex, includingAttributes: true) <= attributeIndex
    }
}
