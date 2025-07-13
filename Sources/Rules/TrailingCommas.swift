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
        formatter.forEachToken { i, token in
            switch token {
            case .endOfScope("]"):
                switch formatter.scopeType(at: i) {
                case .array, .dictionary:
                    let trailingCommaSupported: Bool
                    switch formatter.options.trailingCommas {
                    case .always, .collectionsOnly:
                        trailingCommaSupported = true
                    case .multiElementLists:
                        if let startOfScope = formatter.startOfScope(at: i) {
                            let elementsInScope = formatter.commaSeparatedElementsInScope(startOfScope: startOfScope)
                            trailingCommaSupported = elementsInScope.count > 1
                        } else {
                            trailingCommaSupported = false
                        }
                    case .never:
                        trailingCommaSupported = false
                    }

                    formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: trailingCommaSupported)

                case .subscript, .captureList:
                    var trailingCommaSupported = false

                    if formatter.options.swiftVersion >= "6.1" {
                        switch formatter.options.trailingCommas {
                        case .always:
                            trailingCommaSupported = true
                        case .never, .collectionsOnly:
                            break
                        case .multiElementLists:
                            if let startOfScope = formatter.startOfScope(at: i) {
                                let elementsInScope = formatter.commaSeparatedElementsInScope(startOfScope: startOfScope)
                                trailingCommaSupported = elementsInScope.count > 1
                            }
                        }
                    }

                    formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: trailingCommaSupported)

                default:
                    return
                }

            case .endOfScope(")"):
                var trailingCommaSupported = false

                guard let startOfScope = formatter.startOfScope(at: i) else { return }

                // Trailing commas are supported in function calls, function definitions, and attributes.
                if formatter.options.swiftVersion >= "6.1",
                   let identifierBeforeStartOfScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope),
                   let identifierToken = formatter.token(at: identifierBeforeStartOfScope),
                   identifierToken.isIdentifier || identifierToken.isAttribute || (identifierToken.isKeyword && identifierToken.string.hasPrefix("#")),
                   // If the case of `@escaping` or `@Sendable`, this could be a closure type where trailing commas are not supported.
                   !formatter.isStartOfClosureType(at: startOfScope)
                {
                    // In Swift 6.1, built-in attributes unexpectedly don't support trailing commas.
                    // Other attributes like property wrappers and macros do support trailing commas.
                    // https://github.com/swiftlang/swift/issues/81475
                    // https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/
                    // Some attributes like `@objc`, `@inline` that have parens but not comma-separated lists don't support trailing commas.
                    let unsupportedBuiltInAttributes = ["@available", "@backDeployed", "@freestanding", "@attached", "@objc", "@inline"]
                    if identifierToken.isAttribute, unsupportedBuiltInAttributes.contains(identifierToken.string)
                        || identifierToken.string.hasPrefix("@_")
                    {
                        trailingCommaSupported = false
                    }

                    else {
                        trailingCommaSupported = true
                    }
                }

                // In Swift 6.1, trailing commas are also supported in tuple values,
                // but not tuple types: https://github.com/swiftlang/swift/issues/81485
                // If we know this is a tuple value, then trailing commas are supported.
                if formatter.options.swiftVersion >= "6.1",
                   let tokenBeforeStartOfScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope)
                {
                    // `{ (...) }`, `return (...)` etc are always tuple values
                    // (except in the case of a typealias, where the rhs is a type)
                    let tokensPreceedingValuesNotTypes: Set<Token> = [.startOfScope("{"), .keyword("return"), .keyword("throw"), .keyword("switch"), .endOfScope("case")]
                    if tokensPreceedingValuesNotTypes.contains(formatter.tokens[tokenBeforeStartOfScope]) {
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

                switch formatter.options.trailingCommas {
                case .always:
                    break
                case .never, .collectionsOnly:
                    trailingCommaSupported = false
                case .multiElementLists:
                    if trailingCommaSupported {
                        let elementsInScope = formatter.commaSeparatedElementsInScope(startOfScope: startOfScope)
                        trailingCommaSupported = elementsInScope.count > 1
                    }
                }

                formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: trailingCommaSupported)

            case .endOfScope(">"):
                var trailingCommaSupported = false

                guard let startOfScope = formatter.startOfScope(at: i) else { return }

                // In Swift 6.1, only generic lists in concrete type / function / typealias declarations are allowed.
                // https://github.com/swiftlang/swift/issues/81474
                // All of these cases have the form `keyword identifier<...>`, like `class Foo<...>` or `func foo<...>`.
                if formatter.options.swiftVersion >= "6.1",
                   let identifierIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope),
                   formatter.tokens[identifierIndex].isIdentifier,
                   let keywordIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: identifierIndex),
                   let keyword = formatter.token(at: keywordIndex),
                   keyword.isKeyword,
                   ["class", "actor", "struct", "enum", "typealias", "func"].contains(keyword.string)
                {
                    trailingCommaSupported = true
                }

                switch formatter.options.trailingCommas {
                case .always:
                    break
                case .never, .collectionsOnly:
                    trailingCommaSupported = false
                case .multiElementLists:
                    if trailingCommaSupported {
                        let elementsInScope = formatter.commaSeparatedElementsInScope(startOfScope: startOfScope)
                        trailingCommaSupported = elementsInScope.count > 1
                    }
                }

                formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: trailingCommaSupported)

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

        Swift 6.1 and later:

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
        """
    }
}

extension Formatter {
    /// Adds or removes a trailing comma before the given index that marks the end of a comma-separated list.
    /// Trailing commas can always be removed. `trailingCommaSupported` indicates whether or not a trailing
    /// comma is allowed at this position. A comma being supported is a combination of language support
    /// and enabled options.
    func addOrRemoveTrailingComma(before endOfListIndex: Int, trailingCommaSupported: Bool) {
        guard let prevTokenIndex = index(of: .nonSpaceOrComment, before: endOfListIndex) else { return }

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
                if !options.trailingCommas.enabled || !trailingCommaSupported {
                    removeToken(at: prevTokenIndex)
                }
            default:
                if options.trailingCommas.enabled, trailingCommaSupported {
                    insert(.delimiter(","), at: prevTokenIndex + 1)
                }
            }
        case .delimiter(","):
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
              firstTokenInScope != endOfScope
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
        if currentIndex < endOfScope, index(of: .nonSpaceOrCommentOrLinebreak, after: currentIndex) != endOfScope {
            commasSeparatedElements.append(currentIndex ... lastTokenInScope)
        }

        return commasSeparatedElements
    }
}

extension TrailingCommas {
    var enabled: Bool {
        switch self {
        case .never:
            return false
        case .always, .collectionsOnly, .multiElementLists:
            return true
        }
    }
}
