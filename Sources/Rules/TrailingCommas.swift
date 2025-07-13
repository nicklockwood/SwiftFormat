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
                    var trailingCommaSupported = true

                    // For multi-element-lists, only add trailing comma if there are multiple elements
                    if formatter.options.trailingCommas == .multiElementLists {
                        if let startIndex = formatter.startOfScope(at: i) {
                            let elementCount = formatter.countElementsInList(from: startIndex, to: i)
                            trailingCommaSupported = elementCount > 1
                        }
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
                            if let startIndex = formatter.startOfScope(at: i) {
                                let elementCount = formatter.countElementsInList(from: startIndex, to: i)
                                trailingCommaSupported = elementCount > 1
                            }
                        }
                    }

                    formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: trailingCommaSupported)
                default:
                    return
                }

            case .endOfScope(")"):
                var trailingCommaSupported = false

                // Trailing commas are supported in function calls, function definitions, and attributes.
                if formatter.options.swiftVersion >= "6.1",
                   let startOfScope = formatter.startOfScope(at: i),
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
                   let startOfScope = formatter.startOfScope(at: i),
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
                        if let startIndex = formatter.startOfScope(at: i) {
                            let elementCount = formatter.countElementsInList(from: startIndex, to: i)
                            trailingCommaSupported = elementCount > 1
                        }
                    }
                }

                formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: trailingCommaSupported)

            case .endOfScope(">"):
                var trailingCommaSupported = false

                // In Swift 6.1, only generic lists in concrete type / function / typealias declarations are allowed.
                // https://github.com/swiftlang/swift/issues/81474
                // All of these cases have the form `keyword identifier<...>`, like `class Foo<...>` or `func foo<...>`.
                if formatter.options.swiftVersion >= "6.1",
                   let startOfScope = formatter.startOfScope(at: i),
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
                        if let startIndex = formatter.startOfScope(at: i) {
                            let elementCount = formatter.countElementsInList(from: startIndex, to: i)
                            trailingCommaSupported = elementCount > 1
                        }
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
    /// Counts the number of elements in a comma-separated list
    /// Returns 0 if the list is empty, 1 if it contains only one element, 2+ for multiple elements
    func countElementsInList(from startIndex: Int, to endIndex: Int) -> Int {
        var count = 0
        var hasElement = false
        var depth = 0

        for i in (startIndex + 1) ..< endIndex {
            let token = tokens[i]

            switch token {
            case .startOfScope:
                depth += 1
            case .endOfScope:
                depth -= 1
            case .delimiter(","):
                if depth == 0 {
                    if hasElement {
                        count += 1
                    }
                    hasElement = false
                }
            case .space, .linebreak, .startOfScope("//"), .startOfScope("/*"):
                continue
            default:
                if depth == 0, !token.isComment {
                    hasElement = true
                }
            }
        }

        if hasElement {
            count += 1
        }

        return count
    }

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
