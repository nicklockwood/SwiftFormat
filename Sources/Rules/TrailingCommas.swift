//
//  TrailingCommas.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Ensure that the last item in a multi-line array literal is followed by a comma.
    /// This is useful for preventing noise in commits when items are added to end of array.
    static let trailingCommas = FormatRule(
        help: "Add or remove trailing comma from the last item in a collection literal.",
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

            guard let functionStartIndex = formatter.index(of: .nonSpaceOrComment, before: startIndex),
                  case .identifier = formatter.token(at: functionStartIndex)
            else {
                return
            }

            guard let prevTokenIndex = formatter.index(of: .nonSpaceOrComment, before: i) else {
                return
            }

            switch formatter.tokens[prevTokenIndex] {
            case .linebreak:
                guard let lastArgIndex = formatter.index(
                    of: .nonSpaceOrCommentOrLinebreak, before: prevTokenIndex + 1
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
                formatter.removeToken(at: prevTokenIndex)
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
        """
    }
}
