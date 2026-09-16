//
//  Wrap.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/17/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrap = FormatRule(
        help: "Wrap lines that exceed the specified maximum width.",
        options: ["max-width", "list-wrap-threshold", "no-wrap-operators", "asset-literals", "wrap-ternary", "wrap-string-interpolation"],
        sharedOptions: ["wrap-arguments", "wrap-parameters", "wrap-collections", "closing-paren", "call-site-paren", "indent",
                        "trim-whitespace", "linebreaks", "tab-width", "max-width", "smart-tabs",
                        "wrap-return-type", "wrap-conditions", "wrap-type-aliases", "wrap-ternary", "wrap-effects",
                        "allow-partial-wrapping"]
    ) { formatter in
        guard formatter.options.maxWidth > 0 else { return }

        formatter.wrapGenericRequirements()

        // Wrap collections first to avoid conflict
        formatter.wrapCollectionsAndArguments(completePartialWrapping: false,
                                              wrapSingleArguments: false)

        // Wrap other line types
        var currentIndex = 0
        var indent = ""
        var alreadyLinewrapped = false

        func isLinewrapToken(_ token: Token?) -> Bool {
            switch token {
            case .delimiter?, .operator(_, .infix)?:
                return true
            default:
                return false
            }
        }

        formatter.forEachToken(onlyWhereEnabled: false) { i, token in
            if i < currentIndex {
                return
            }
            if token.isLinebreak {
                indent = formatter.currentIndentForLine(at: i + 1)
                alreadyLinewrapped = isLinewrapToken(formatter.last(.nonSpaceOrComment, before: i))
                currentIndex = i + 1
            } else if let breakPoint = formatter.indexWhereLineShouldWrapInLine(at: i) {
                if !alreadyLinewrapped {
                    indent += formatter.linewrapIndent(at: breakPoint)
                }
                alreadyLinewrapped = true
                if formatter.isEnabled {
                    let spaceAdded = formatter.insertSpace(indent, at: breakPoint + 1)
                    formatter.insertLinebreak(at: breakPoint + 1)
                    currentIndex = breakPoint + spaceAdded + 2
                } else {
                    currentIndex = breakPoint + 1
                }
            } else {
                currentIndex = formatter.endOfLine(at: i)
            }
        }

        formatter.wrapCollectionsAndArguments(completePartialWrapping: true,
                                              wrapSingleArguments: true)
    } examples: {
        """
        `--max-width 40`

        ```diff
        - let foo = bar(baz: 1, quux: 2) + bar(baz: 3, quux: 4)
        + let foo = bar(baz: 1, quux: 2) +
        +     bar(baz: 3, quux: 4)
        ```

        ```diff
        - extension Foo where Bar: Baaz, Quux: Quuz {}
        + extension Foo where
        +     Bar: Baaz,
        +     Quux: Quuz {}
        ```
        """
    }
}

extension Formatter {
    func wrapGenericRequirements() {
        let declarations = withPreservedRuleState {
            let formattingRange = range
            range = nil
            defer { range = formattingRange }
            return parseDeclarations()
        }
        let functionLikeDeclarationKeywords = ["func", "init", "subscript"]

        withPreservedRuleState {
            forEach(.keyword("where")) { whereIndex, _ in
                let maxWidth = options.maxWidth
                guard maxWidth > 0 else { return }

                let declarationKeywordIndex: Int
                let whereClauseRange: ClosedRange<Int>
                if let functionKeywordIndex = index(before: whereIndex, where: { token in
                    functionLikeDeclarationKeywords.contains(token.string)
                }), tokens[functionKeywordIndex].string != "init"
                    || last(.nonSpaceOrCommentOrLinebreak, before: functionKeywordIndex)?.string != ".",
                    let parsedRange = parseFunctionDeclaration(keywordIndex: functionKeywordIndex)?.whereClauseRange,
                    parsedRange.lowerBound == whereIndex
                {
                    declarationKeywordIndex = functionKeywordIndex
                    whereClauseRange = parsedRange
                } else {
                    guard let declaration = declarations.declaration(containing: whereIndex),
                          whereIndex > declaration.keywordIndex,
                          Token.swiftTypeKeywords.contains(declaration.keyword)
                          || declaration.keyword == "associatedtype"
                    else { return }
                    if let typeDeclaration = declaration as? TypeDeclaration,
                       whereIndex > typeDeclaration.openBraceIndex
                    {
                        return
                    }
                    declarationKeywordIndex = declaration.keywordIndex
                    whereClauseRange = parseGenericTypes(from: whereIndex).range
                }

                guard !tokens[whereClauseRange].contains(where: { token in
                    if case let .commentBody(comment) = token {
                        guard let directiveRange = comment.range(of: "swiftformat:") else { return false }
                        return comment[directiveRange.upperBound...]
                            .trimmingCharacters(in: .whitespaces)
                            .hasPrefix("options")
                    }
                    return false
                }) else { return }

                guard let firstRequirementIndex = index(
                    of: .nonSpaceOrCommentOrLinebreak,
                    after: whereIndex
                ), firstRequirementIndex <= whereClauseRange.upperBound else { return }

                var requirementIndices = [firstRequirementIndex]
                var commaIndices = [Int]()
                var searchIndex = firstRequirementIndex
                while let commaIndex = index(
                    of: .delimiter(","),
                    in: searchIndex ..< whereClauseRange.upperBound
                ), let nextRequirementIndex = index(
                    of: .nonSpaceOrCommentOrLinebreak,
                    after: commaIndex
                ), nextRequirementIndex <= whereClauseRange.upperBound {
                    commaIndices.append(commaIndex)
                    requirementIndices.append(nextRequirementIndex)
                    searchIndex = nextRequirementIndex
                }

                guard requirementIndices.allSatisfy({ isEnabled(at: $0) }) else { return }

                var lineIndex = whereIndex
                var isOverMaximumWidth = false
                while lineIndex <= whereClauseRange.upperBound {
                    let lineEnd = min(endOfLine(at: lineIndex), whereClauseRange.upperBound + 1)
                    if lineLength(from: startOfLine(at: lineIndex), upTo: lineEnd) > maxWidth {
                        isOverMaximumWidth = true
                        break
                    }
                    lineIndex = lineEnd + 1
                }
                let isPartiallyWrapped = (requirementIndices + commaIndices).contains { index in
                    last(.nonSpaceOrComment, before: index)?.isLinebreak == true
                        || next(.nonSpaceOrComment, after: index)?.isLinebreak == true
                }
                guard isOverMaximumWidth || isPartiallyWrapped else { return }

                wrapMultilineStatement(
                    startIndex: declarationKeywordIndex,
                    delimiterIndices: requirementIndices,
                    endIndex: whereClauseRange.upperBound,
                    forceWrap: true,
                    leadingDelimiter: .delimiter(","),
                    normalizeSpaceAfterDelimiter: false
                )
            }
        }
    }
}
