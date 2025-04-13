//
//  TrailingCommas.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Ensure that the last item in a multi-line list is followed by a comma, where applicable.
    /// This includes:
    /// - array and dictionary literals
    /// - function and initializer parameters and arguments
    /// - enum case associated values
    /// - tuple literals
    /// - tuple expressions in `return`, `throw`, `switch`, `case let`, `if`, `guard`, `while`
    /// - macro and attribute argument lists (e.g. `#macro(...)`, `@Attribute(...)`)
    /// - string interpolation expressions
    ///
    /// Trailing commas help reduce version control noise when appending new elements to a list.
    ///
    /// Trailing commas will not be added in contexts where they are invalid:
    /// - empty parentheses `()`
    /// - type annotations (e.g. `let value: (Int, String)`)
    static let trailingCommas = FormatRule(
        help: "Add or remove trailing commas where applicable.",
        options: ["commas"]
    ) { formatter in
        formatter.forEach(.endOfScope("]")) { i, _ in
            guard let prevTokenIndex = formatter.index(of: .nonSpaceOrComment, before: i),
                  let scopeType = formatter.scopeType(at: i)
            else {
                return
            }
            switch scopeType {
            case .array, .dictionary:
                switch formatter.tokens[prevTokenIndex] {
                case .linebreak:
                    guard let prevTokenIndex = formatter.index(
                        of: .nonSpaceOrCommentOrLinebreak, before: prevTokenIndex + 1
                    ) else {
                        break
                    }
                    switch formatter.tokens[prevTokenIndex] {
                    case .startOfScope("["), .delimiter(":"):
                        break // do nothing
                    case .delimiter(","):
                        if !formatter.options.trailingCommas {
                            formatter.removeToken(at: prevTokenIndex)
                        }
                    default:
                        if formatter.options.trailingCommas {
                            formatter.insert(.delimiter(","), at: prevTokenIndex + 1)
                        }
                    }
                case .delimiter(","):
                    formatter.removeToken(at: prevTokenIndex)
                default:
                    break
                }
            default:
                return
            }
        }

        guard formatter.options.swiftVersion >= "6.1" else { return }

        formatter.forEach(.endOfScope(")")) { i, _ in
            guard let startIndex = formatter.startOfScope(at: i),
                  formatter.tokens[startIndex] == .startOfScope("(")
            else {
                return
            }

            guard let prevToStartTokenIndex = formatter.index(of: .nonSpaceOrComment, before: startIndex) else {
                return
            }

            guard formatter.tokens[prevToStartTokenIndex] != .delimiter(":") else {
                return
            }

            guard let prevToEndTokenIndex = formatter.index(of: .nonSpaceOrComment, before: i) else {
                return
            }

            switch formatter.tokens[prevToEndTokenIndex] {
            case .linebreak:
                guard let lastArgIndex = formatter.index(
                    of: .nonSpaceOrCommentOrLinebreak, before: prevToEndTokenIndex + 1
                ) else {
                    break
                }
                switch formatter.tokens[lastArgIndex] {
                case .delimiter(","):
                    if !formatter.options.trailingCommas {
                        formatter.removeToken(at: lastArgIndex)
                    }
                case .startOfScope("("):
                    break
                default:
                    if formatter.options.trailingCommas {
                        formatter.insert(.delimiter(","), at: lastArgIndex + 1)
                    }
                }
            case .delimiter(","):
                formatter.removeToken(at: prevToEndTokenIndex)
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
          ]

          let array = [
            foo,
            bar,
        +   baz,
          ]
        ```

        ```diff
        func foo(
        -   bar _: Int
        ) {}

        func foo(
        +   bar _: Int,
        ) {}
        ```

        ```diff
        let foo = (
            bar: 0,
        -   baz: 1
        )

        let foo = (
            bar: 0,
        +   baz: 1,
        )
        ```

        ```diff
        @Foo(
            "bar",
        -   "baz"
        )

        @Foo(
            "bar",
        +   "baz",
        )
        ```
        """
    }
}
