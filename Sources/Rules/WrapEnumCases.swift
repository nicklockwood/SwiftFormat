//
//  WrapEnumCases.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/28/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Formats enum cases declaration into one case per line
    static let wrapEnumCases = FormatRule(
        help: "Rewrite comma-delimited enum cases to one case per line.",
        disabledByDefault: true,
        options: ["wrap-enum-cases", "wrap-single-line-enum-cases"],
        sharedOptions: ["linebreaks", "indent", "wrap-string-interpolation"]
    ) { formatter in
        formatter.forEach(.keyword("case")) { i, _ in
            formatter.wrapEnumCaseDeclaration(at: i)
        }
    } examples: {
        """
        ```diff
          enum Foo {
        -   case bar, baz
          }

          enum Foo {
        +   case bar
        +   case baz
          }
        ```

        With `--wrap-single-line-enum-cases true`:

        ```diff
        - package enum Action { case delete, suspend, resume }
        + package enum Action {
        +     case delete
        +     case suspend
        +     case resume
        + }
        ```
        """
    }
}

extension Formatter {
    func wrapEnumCaseDeclaration(at i: Int) {
        guard isEnumCaseDeclaration(at: i),
              isEnumCase(at: i) || options.wrapSingleLineEnumCases,
              !isInStringLiteralWithWrappingDisabled(at: i),
              // Attributes and modifiers apply to every case in the original declaration.
              // Keep it intact rather than changing availability or recursive case semantics.
              startOfModifiers(at: i, includingAttributes: true) == i,
              let scopeStart = startOfScope(at: i)
        else { return }

        let caseIndex = i.autoUpdating(in: self)
        if options.wrapSingleLineEnumCases {
            wrapEnumCaseAfterSemicolon(at: caseIndex.index)
        }
        let ranges = enumCaseRanges(at: caseIndex.index)
        guard ranges.count > 1,
              let firstIndex = ranges.first?.lowerBound,
              options.wrapSingleLineEnumCases || tokens[scopeStart ..< firstIndex].contains(where: \.isLinebreak),
              options.wrapEnumCases == .always || ranges.contains(where: {
                  tokens[$0].contains { $0 == .startOfScope("(") || $0 == .operator("=", .infix) }
              })
        else { return }

        if options.wrapSingleLineEnumCases {
            if token(at: scopeStart) == .startOfScope("{"), onSameLine(scopeStart, caseIndex.index),
               var closingBrace = endOfScope(at: scopeStart)
            {
                if let previous = index(of: .nonSpaceOrComment, before: closingBrace),
                   !tokens[previous].isLinebreak
                {
                    if token(at: closingBrace - 1)?.isSpace == true {
                        removeToken(at: closingBrace - 1)
                        closingBrace -= 1
                    }
                    insertLinebreak(at: closingBrace)
                    insertSpace(currentIndentForLine(at: scopeStart), at: closingBrace + 1)
                }
                wrapStatementBody(at: scopeStart)
            }
            wrapEnumCaseAfterSemicolon(at: caseIndex.index)
        }

        let indent = currentIndentForLine(at: caseIndex.index)
        for range in enumCaseRanges(at: caseIndex.index).dropLast().reversed() {
            let commaIndex = range.upperBound
            guard var nextNonSpaceIndex = index(of: .nonSpace, after: commaIndex) else { continue }

            if tokens[nextNonSpaceIndex] == .startOfScope("//") {
                removeToken(at: commaIndex)
                if token(at: commaIndex)?.isSpace == true,
                   token(at: commaIndex - 1)?.isSpace == true
                {
                    removeToken(at: commaIndex - 1)
                }
                nextNonSpaceIndex = index(of: .linebreak, after: commaIndex) ?? nextNonSpaceIndex
            } else {
                removeTokens(in: commaIndex ..< nextNonSpaceIndex)
                nextNonSpaceIndex = commaIndex
            }

            if !tokens[nextNonSpaceIndex].isLinebreak {
                insertLinebreak(at: nextNonSpaceIndex)
            }

            let offset = indent.isEmpty ? 0 : 1
            insertSpace(indent, at: nextNonSpaceIndex + 1)
            insert(.keyword("case"), at: nextNonSpaceIndex + 1 + offset)
            insertSpace(" ", at: nextNonSpaceIndex + 2 + offset)
        }
    }

    /// Place a semicolon-separated declaration on its own line once the enum body is multiline.
    func wrapEnumCaseAfterSemicolon(at index: Int) {
        guard let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
              tokens[previous] == .delimiter(";"), onSameLine(previous, index),
              let scopeStart = startOfScope(at: index),
              tokens[scopeStart ..< index].contains(where: \.isLinebreak)
        else { return }
        _ = wrapLine(before: index)
    }

    /// Enum cases may be inside conditional compilation scopes within the enum body.
    func isEnumCaseDeclaration(at index: Int) -> Bool {
        var searchIndex = index
        while let scopeStart = startOfScope(at: searchIndex) {
            if token(at: scopeStart) != .startOfScope("#if") {
                return token(at: scopeStart) == .startOfScope("{")
                    && lastSignificantKeyword(at: scopeStart, excluding: ["where"]) == "enum"
            }
            searchIndex = scopeStart
        }
        return false
    }

    /// Parses the case values in a single declaration, skipping commas inside associated values.
    func enumCaseRanges(at caseIndex: Int) -> [Range<Int>] {
        guard let scopeEnd = endOfScope(at: caseIndex),
              var currentStart = index(of: .nonSpaceOrCommentOrLinebreak, after: caseIndex)
        else { return [] }

        var result: [Range<Int>] = []
        var searchIndex = caseIndex
        while let boundary = index(after: searchIndex, where: {
            $0 == .delimiter(",") || $0 == .delimiter(";") || $0.isDeclarationTypeKeyword
                || $0.isAttribute || $0 == .startOfScope("#if")
                || $0 == .keyword("#else") || $0 == .keyword("#elseif")
        }), boundary < scopeEnd {
            if tokens[boundary] != .delimiter(",") {
                if currentStart < boundary {
                    result.append(currentStart ..< boundary)
                }
                return result
            }
            result.append(currentStart ..< boundary)
            currentStart = index(of: .nonSpaceOrCommentOrLinebreak, after: boundary) ?? boundary
            searchIndex = boundary
        }
        if currentStart < scopeEnd {
            result.append(currentStart ..< scopeEnd)
        }
        return result
    }
}
