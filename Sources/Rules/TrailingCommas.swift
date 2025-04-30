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
    /// This is useful for preventing noise in commits when items are added to end of array.
    static let trailingCommas = FormatRule(
        help: "Add or remove trailing commas where applicable.",
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

            case .endOfScope(")"), .endOfScope(">"):
                formatter.addOrRemoveTrailingComma(before: i, trailingCommaSupported: formatter.options.swiftVersion >= "6.1")

            case .keyword("if"):
                guard let startOfConditions = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                      let startOfBody = formatter.startOfConditionalBranchBody(after: startOfConditions)
                else { return }

                formatter.addOrRemoveTrailingComma(before: startOfBody, trailingCommaSupported: formatter.options.swiftVersion >= "6.1")

            case .keyword("guard"):
                guard let startOfConditions = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                      let startOfBody = formatter.startOfConditionalBranchBody(after: startOfConditions),
                      let elseKeyword = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfBody),
                      formatter.tokens[elseKeyword] == .keyword("else")
                else { return }

                formatter.addOrRemoveTrailingComma(before: elseKeyword, trailingCommaSupported: formatter.options.swiftVersion >= "6.1")

            case .keyword("while"):
                guard let startOfConditions = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                      let startOfBody = formatter.startOfConditionalBranchBody(after: startOfConditions)
                else { return }

                // Ensure this isn't a `repeat { ... } while ...` condition where any `{` token after the while keyword would be unrelated
                if let previousToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                   formatter.tokens[previousToken] == .endOfScope("}"),
                   let startOfScope = formatter.startOfScope(at: previousToken),
                   let tokenBeforeStartOfScope = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startOfScope),
                   formatter.tokens[tokenBeforeStartOfScope] == .keyword("repeat")
                {
                    return
                }

                formatter.addOrRemoveTrailingComma(before: startOfBody, trailingCommaSupported: formatter.options.swiftVersion >= "6.1")

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

        ```diff
          func foo(
              bar _: Int,
        -     baaz _: Int
        +     baaz _: Int
          ) {}
        ```

        ```diff
          let foo = (
              bar: 0,
        -     baz: 1
        +     baz: 1,
          )
        ```

        ```diff
          if
              let foo,
        -     let baaz
        +     let baaz,
          { ... }
        ```

        ```diff
          guard
              let foo,
        -     let baaz
        +     let baaz,
          else { return }
        ```
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
