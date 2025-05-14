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
        options: ["commas"]
    ) { formatter in
        formatter.forEachToken { i, token in
            switch token {
            case .endOfScope("]"):
                switch formatter.scopeType(at: i) {
                case .array, .dictionary:
                    formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: true)
                case .subscript, .captureList:
                    formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: formatter.options.swiftVersion >= "6.1")
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
                   identifierToken.isIdentifier || identifierToken.isAttribute || (identifierToken.isKeyword && identifierToken.string.hasPrefix("#"))
                {
                    // In Swift 6.1, built-in attributes unexpectedly don't support trailing commas.
                    // Other attributes like property wrappers and macros do support trailing commas.
                    // https://github.com/swiftlang/swift/issues/81475
                    // https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/
                    let unsupportedBuiltInAttributes = ["@available", "@backDeployed", "@objc", "@freestanding", "@attached"]
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
                    // `= (...)`, `{ (...) }`, `return (...)` etc are always tuple values
                    let tokensPreceedingValuesNotTypes: Set<Token> = [.operator("=", .infix), .startOfScope("{"), .keyword("return"), .keyword("throw"), .keyword("switch"), .endOfScope("case")]
                    if tokensPreceedingValuesNotTypes.contains(formatter.tokens[tokenBeforeStartOfScope]) {
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

                formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: trailingCommaSupported)

            case .endOfScope(">"):
                var trailingCommaSupported = false

                // In Swift 6.1, only generic lists in type / function / typealias declarations are allowed.
                // https://github.com/swiftlang/swift/issues/81474
                // All of these cases have the form `keyword identifier<...>`, like `class Foo<...>` or `func foo<...>`.
                if formatter.options.swiftVersion >= "6.1",
                   let startOfScope = formatter.startOfScope(at: i),
                   let identifierIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope),
                   formatter.tokens[identifierIndex].isIdentifier,
                   let keywordIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: identifierIndex),
                   let keyword = formatter.token(at: keywordIndex),
                   keyword.isKeyword,
                   ["class", "actor", "struct", "enum", "protocol", "extension", "typealias", "func"].contains(keyword.string)
                {
                    trailingCommaSupported = true
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
        """
    }
}

extension Formatter {
    /// Adds or removes a trailing comma before the given index that marks the end of a comma-separated list.
    /// Trailing commas can always be removed. `trailingCommaSupported` indicates whether or not a trailing
    /// comma is allowed at this position.
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
                if !options.trailingCommas {
                    removeToken(at: prevTokenIndex)
                }
            default:
                if options.trailingCommas, trailingCommaSupported {
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
