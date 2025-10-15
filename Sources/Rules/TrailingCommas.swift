//
//  TrailingCommas.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let trailingCommas = FormatRule(
        help: "Add or remove trailing commas in comma-separated lists.",
        options: ["trailing-commas"]
    ) { formatter in
        formatter.forEach(.endOfScope) { i, token in
            guard let startOfScope = formatter.startOfScope(at: i) else { return }

            switch formatter.scopeType(at: startOfScope) {
            case .array, .dictionary:
                formatter.addOrRemoveTrailingComma(beforeEndOfScope: i, trailingCommaSupported: true, isCollection: true)
                return

            case .subscript, .captureList:
                let trailingCommaSupported = formatter.options.swiftVersion >= "6.1"
                formatter.addOrRemoveTrailingComma(beforeEndOfScope: i, trailingCommaSupported: trailingCommaSupported)
                return

            case .arrayType, .dictionaryType, .throwsType:
                return

            case .tuple, .tupleType, nil:
                break
            }

            // TODO: a lot of this logic could be moved into the scopeType() helper
            switch token {
            case .endOfScope(")"):
                var trailingCommaSupported: Bool?

                if formatter.options.swiftVersion < "6.1" {
                    trailingCommaSupported = false
                }

                // Trailing commas are supported in function calls, function definitions, initializers, and attributes.
                if formatter.options.swiftVersion >= "6.1",
                   let identifierIndex = formatter.parseFunctionIdentifier(beforeStartOfScope: startOfScope),
                   let identifierToken = formatter.token(at: identifierIndex),
                   identifierToken.isIdentifier || identifierToken.isAttribute || identifierToken.isKeyword,
                   // If the case of `@escaping` or `@Sendable`, this could be a closure type where trailing commas are not supported.
                   !formatter.isStartOfClosureType(at: startOfScope)
                {
                    // Built-in attributes like `@available`, `@backDeployed` don't support trailing commas.
                    // Assume any attribute with a lowercase first letter or a leading underscore is a built-in attribute.
                    // https://github.com/swiftlang/swift/issues/81475#issuecomment-2894879640
                    if identifierToken.isAttribute,
                       let firstCharacterInAttribute = identifierToken.string.dropFirst().first,
                       firstCharacterInAttribute.isLowercase || firstCharacterInAttribute == "_"
                    {
                        trailingCommaSupported = false
                    }

                    else {
                        trailingCommaSupported = true
                    }
                }

                // If the previous token is the closing `>` of a generic list, then this is a function declaration or initializer,
                // like `func foo<T>(args...)` or `Foo<Bar>(args...)`.
                else if formatter.options.swiftVersion >= "6.1",
                        let tokenBeforeStartOfScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope),
                        formatter.tokens[tokenBeforeStartOfScope] == .endOfScope(">")
                {
                    trailingCommaSupported = true
                }

                // In Swift 6.2 and later, trailing commas are supported in tuple values and tuple types.
                // If there are multiple values in the parens, and it's not one of the scope types we already handled above,
                // then we know it's a tuple.
                else if formatter.options.swiftVersion >= "6.2",
                        formatter.commaSeparatedElementsInScope(startOfScope: startOfScope).count > 1
                {
                    trailingCommaSupported = true

                    // However, this is a bug in Swift 6.2 where trailing commas are unexpectedly
                    // not allowed in tuple types within generic type argument lists.
                    // https://github.com/swiftlang/swift-syntax/pull/3153
                    if formatter.options.swiftVersion == "6.2" {
                        var startOfScope = startOfScope
                        while let outerScope = formatter.startOfScope(at: startOfScope) {
                            if formatter.tokens[outerScope] == .startOfScope("<") {
                                trailingCommaSupported = false
                                break
                            }

                            startOfScope = outerScope
                        }
                    }

                    // There is also a bug in Swift 6.2 where closure tuple return types don't support trailing commas.
                    if formatter.options.swiftVersion == "6.2",
                       let tokenBeforeStartOfScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope),
                       formatter.tokens[tokenBeforeStartOfScope] == .operator("->", .infix),
                       formatter.isInClosureArguments(at: tokenBeforeStartOfScope)
                    {
                        trailingCommaSupported = false
                    }
                }

                // In Swift 6.1, trailing commas are only supported in tuple values,
                // but not tuple or closure types: https://github.com/swiftlang/swift/issues/81485
                // If we know this is a tuple value, then trailing commas are supported.
                //
                // This also handles paren scopes with only a single element (so, not a tuple)
                // where trailing commas are allowed in Swift 6.2 and later.
                else if formatter.options.swiftVersion >= "6.1",
                        let tokenBeforeStartOfScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope)
                {
                    // `{ (...) }`, `return (...)` etc are always tuple values
                    // (except in the case of a typealias, where the rhs is a type)
                    let tokensPrecedingValuesNotTypes: Set<Token> = [.startOfScope("{"), .keyword("return"), .keyword("throw"), .keyword("switch"), .endOfScope("case")]
                    if tokensPrecedingValuesNotTypes.contains(formatter.tokens[tokenBeforeStartOfScope]) {
                        trailingCommaSupported = true
                    }

                    // `= (...)` is a tuple value, unless this is a typealias.
                    if formatter.tokens[tokenBeforeStartOfScope] == .operator("=", .infix),
                       formatter.lastSignificantKeyword(at: tokenBeforeStartOfScope) != "typealias"
                    {
                        trailingCommaSupported = true
                    }

                    // `function(...: (...))` is always a tuple value
                    if formatter.tokens[tokenBeforeStartOfScope] == .delimiter(":"),
                       let outerScope = formatter.startOfScope(at: tokenBeforeStartOfScope),
                       formatter.isFunctionCall(at: outerScope)
                    {
                        trailingCommaSupported = true
                    }
                }

                // In Swift 6.2 and later, trailing commas are always supported in closure argument lists.
                if formatter.options.swiftVersion >= "6.2",
                   let tokenAfterEndOfScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                   [.identifier("async"), .keyword("throws"), .operator("->", .infix)].contains(formatter.tokens[tokenAfterEndOfScope])
                {
                    trailingCommaSupported = true
                }

                formatter.addOrRemoveTrailingComma(beforeEndOfScope: i, trailingCommaSupported: trailingCommaSupported)

            case .endOfScope(">"):
                var trailingCommaSupported = false

                if formatter.options.swiftVersion >= "6.2" {
                    trailingCommaSupported = true
                } else if formatter.options.swiftVersion == "6.1" {
                    // In Swift 6.1, only generic lists in concrete type / function / typealias declarations are allowed.
                    // https://github.com/swiftlang/swift/issues/81474
                    // All of these cases have the form `keyword identifier<...>`, like `class Foo<...>` or `func foo<...>`.
                    if let identifierIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope),
                       formatter.tokens[identifierIndex].isIdentifier,
                       let keywordIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: identifierIndex),
                       let keyword = formatter.token(at: keywordIndex),
                       keyword.isKeyword,
                       ["class", "actor", "struct", "enum", "typealias", "func"].contains(keyword.string)
                    {
                        trailingCommaSupported = true
                    }
                }

                formatter.addOrRemoveTrailingComma(beforeEndOfScope: i, trailingCommaSupported: trailingCommaSupported)

            default:
                break
            }
        }
    } examples: {
        """
        ```diff
          let array = [
            foo,
            bar,
        -   baz
        +   baz,
          ]
        ```

        Swift 6.1 and later with `--trailing-commas always`:

        ```diff
          func foo(
              bar: Int,
        -     baaz: Int
        +     baaz: Int,
          ) {}
        ```

        ```diff
          foo(
              bar: 1,
        -     baaz: 2
        +     baaz: 2,
          )
        ```

        ```diff
          struct Foo<
              Bar,
              Baaz,
        -     Quux
        +     Quux,
          > {}
        ```

        `--trailing-commas multi-element-lists`

        ```diff
          let foo = [
        -     bar,
        +     bar
          ]

          foo(
        -     bar,
        +     bar
          )
        ```
        """
    }
}

extension Formatter {
    /// Adds or removes a trailing comma before the given index that marks the end of a comma-separated list.
    /// Trailing commas can always be removed.
    ///  - `trailingCommaSupported` indicates whether or not a trailing comma is allowed by the language at this position.
    ///  - `isCollection` indicates whether this is an array or dictionary literal.
    func addOrRemoveTrailingComma(
        beforeEndOfScope endOfListIndex: Int,
        trailingCommaSupported: Bool?,
        isCollection: Bool = false
    ) {
        guard let prevTokenIndex = index(of: .nonSpaceOrComment, before: endOfListIndex),
              let startOfScope = startOfScope(at: endOfListIndex)
        else { return }

        // Decide whether to insert or remove the comma in this context
        enum TrailingCommaMode {
            case insert
            case remove
            case preserve
        }

        let trailingCommaMode: TrailingCommaMode
        switch options.trailingCommas {
        case .never:
            trailingCommaMode = .remove

        case .always:
            switch trailingCommaSupported {
            case true?:
                trailingCommaMode = .insert
            case false?:
                trailingCommaMode = .remove
            case nil:
                trailingCommaMode = .preserve
            }

        case .collectionsOnly:
            if isCollection {
                trailingCommaMode = .insert
            } else {
                trailingCommaMode = .remove
            }

        case .multiElementLists:
            switch trailingCommaSupported {
            case _ where commaSeparatedElementsInScope(startOfScope: startOfScope).count <= 1, false?:
                trailingCommaMode = .remove
            case true?:
                trailingCommaMode = .insert
            case nil:
                trailingCommaMode = .preserve
            }
        }

        // Remove or insert the comma
        switch tokens[prevTokenIndex] {
        case .linebreak:
            guard let prevTokenIndex = index(
                of: .nonSpaceOrCommentOrLinebreak, before: prevTokenIndex + 1
            ) else {
                break
            }
            switch tokens[prevTokenIndex] {
            case .startOfScope("["), .delimiter(":"), .startOfScope("("):
                break // do nothing
            case .delimiter(","):
                if trailingCommaMode == .remove {
                    removeToken(at: prevTokenIndex)
                }
            default:
                if trailingCommaMode == .insert {
                    insert(.delimiter(","), at: prevTokenIndex + 1)
                }
            }

        case .delimiter(","):
            // Always remove a trailing comma that isn't followed by a linebreak
            removeToken(at: prevTokenIndex)

        default:
            break
        }
    }

    /// Returns the range of each comma-separated element in the given range
    func commaSeparatedElementsInScope(startOfScope: Int) -> [ClosedRange<Int>] {
        guard let endOfScope = endOfScope(at: startOfScope),
              let firstTokenInScope = index(of: .nonSpaceOrLinebreak, after: startOfScope),
              let lastTokenInScope = index(of: .nonSpaceOrLinebreak, before: endOfScope),
              firstTokenInScope != endOfScope,
              firstTokenInScope < lastTokenInScope
        else { return [] }

        var currentIndex = firstTokenInScope
        var commasSeparatedElements = [ClosedRange<Int>]()

        while let nextCommaIndex = index(of: .delimiter(","), in: currentIndex ..< endOfScope),
              let tokenBeforeComma = index(of: .nonSpaceOrLinebreak, before: nextCommaIndex),
              let tokenAfterComma = index(of: .nonSpaceOrCommentOrLinebreak, after: nextCommaIndex)
        {
            commasSeparatedElements.append(currentIndex ... tokenBeforeComma)
            currentIndex = tokenAfterComma
        }

        // Add the final element, unless the final comma was a trailing comma
        if currentIndex < endOfScope, currentIndex <= lastTokenInScope {
            commasSeparatedElements.append(currentIndex ... lastTokenInScope)
        }

        return commasSeparatedElements
    }
}
