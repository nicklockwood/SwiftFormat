//
//  RedundantType.swift
//  SwiftFormat
//
//  Created by Facundo Menzella on 8/20/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Removes explicit type declarations from initialization declarations
    static let redundantType = FormatRule(
        help: "Remove redundant type from variable declarations.",
        options: ["property-types"]
    ) { formatter in
        formatter.forEach(.operator("=", .infix)) { i, _ in
            guard let keyword = formatter.lastSignificantKeyword(at: i),
                  ["var", "let"].contains(keyword)
            else {
                return
            }

            let equalsIndex = i
            guard let colonIndex = formatter.index(before: i, where: {
                [.delimiter(":"), .operator("=", .infix)].contains($0)
            }), formatter.tokens[colonIndex] == .delimiter(":"),
            let typeEndIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: equalsIndex)
            else { return }

            // The implementation of RedundantType uses inferred or explicit,
            // potentially depending on the context.
            let isInferred: Bool
            let declarationKeywordIndex: Int?
            switch formatter.options.propertyTypes {
            case .inferred:
                isInferred = true
                declarationKeywordIndex = nil
            case .explicit:
                isInferred = false
                declarationKeywordIndex = formatter.declarationIndexAndScope(at: equalsIndex).index
            case .inferLocalsOnly:
                let (index, scope) = formatter.declarationIndexAndScope(at: equalsIndex)
                switch scope {
                case .global, .type:
                    isInferred = false
                    declarationKeywordIndex = index
                case .local:
                    isInferred = true
                    declarationKeywordIndex = nil
                }
            }

            // Explicit type can't be safely removed from @Model classes
            // https://github.com/nicklockwood/SwiftFormat/issues/1649
            if !isInferred,
               let declarationKeywordIndex,
               formatter.modifiersForDeclaration(at: declarationKeywordIndex, contains: "@Model")
            {
                return
            }

            // Removes a type already processed by `compare(typeStartingAfter:withTypeStartingAfter:)`
            func removeType(after indexBeforeStartOfType: Int, i: Int, j: Int, wasValue: Bool) {
                if isInferred {
                    formatter.removeTokens(in: colonIndex ... typeEndIndex)
                    if formatter.tokens[colonIndex - 1].isSpace {
                        formatter.removeToken(at: colonIndex - 1)
                    }
                } else if !wasValue, let valueStartIndex = formatter
                    .index(of: .nonSpaceOrCommentOrLinebreak, after: indexBeforeStartOfType),
                    !formatter.isConditionalStatement(at: i),
                    let endIndex = formatter.endOfExpression(at: j, upTo: []),
                    endIndex > j
                {
                    let allowChains = formatter.options.swiftVersion >= "5.4"
                    if formatter.next(.nonSpaceOrComment, after: j) == .startOfScope("(") {
                        if allowChains || formatter.index(
                            of: .operator(".", .infix),
                            in: j ..< endIndex
                        ) == nil {
                            formatter.replaceTokens(in: valueStartIndex ... j, with: [
                                .operator(".", .infix), .identifier("init"),
                            ])
                        }
                    } else if let nextIndex = formatter.index(
                        of: .nonSpaceOrCommentOrLinebreak,
                        after: j,
                        if: { $0 == .operator(".", .infix) }
                    ), allowChains || formatter.index(
                        of: .operator(".", .infix),
                        in: (nextIndex + 1) ..< endIndex
                    ) == nil {
                        formatter.removeTokens(in: valueStartIndex ... j)
                    }
                }
            }

            // In Swift 5.9+ (SE-0380) we need to handle if / switch expressions by checking each branch
            if let tokenAfterEquals = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
               let conditionalBranches = formatter.conditionalBranches(at: tokenAfterEquals),
               formatter.allRecursiveConditionalBranches(
                   in: conditionalBranches,
                   satisfy: { branch in
                       formatter.compare(typeStartingAfter: branch.startOfBranch, withTypeStartingAfter: colonIndex, typeEndIndex: typeEndIndex).matches
                   }
               )
            {
                if isInferred {
                    formatter.removeTokens(in: colonIndex ... typeEndIndex)
                    if formatter.tokens[colonIndex - 1].isSpace {
                        formatter.removeToken(at: colonIndex - 1)
                    }
                } else {
                    formatter.forEachRecursiveConditionalBranch(in: conditionalBranches) { branch in
                        let (_, i, j, wasValue) = formatter.compare(
                            typeStartingAfter: branch.startOfBranch,
                            withTypeStartingAfter: colonIndex,
                            typeEndIndex: typeEndIndex
                        )

                        removeType(after: branch.startOfBranch, i: i, j: j, wasValue: wasValue)
                    }
                }
            }

            // Otherwise this is just a simple assignment expression where the RHS is a single value
            else {
                let (matches, i, j, wasValue) = formatter.compare(typeStartingAfter: equalsIndex, withTypeStartingAfter: colonIndex, typeEndIndex: typeEndIndex)
                if matches {
                    removeType(after: equalsIndex, i: i, j: j, wasValue: wasValue)
                }
            }
        }
    } examples: {
        """
        ```diff
          // with --propertytypes inferred
        - let view: UIView = UIView()
        + let view = UIView()

          // with --propertytypes explicit
        - let view: UIView = UIView()
        + let view: UIView = .init()

          // with --propertytypes infer-locals-only
          class Foo {
        -     let view: UIView = UIView()
        +     let view: UIView = .init()

              func method() {
        -         let view: UIView = UIView()
        +         let view = UIView()
              }
          }

          // Swift 5.9+, with --propertytypes inferred (SE-0380)
        - let foo: Foo = if condition {
        + let foo = if condition {
              Foo("foo")
          } else {
              Foo("bar")
          }

          // Swift 5.9+, with --propertytypes explicit (SE-0380)
          let foo: Foo = if condition {
        -     Foo("foo")
        +     .init("foo")
          } else {
        -     Foo("bar")
        +     .init("foo")
          }
        ```
        """
    }
}

extension Formatter {
    /// Compares whether or not two types are equivalent
    func compare(typeStartingAfter j: Int, withTypeStartingAfter i: Int, typeEndIndex: Int)
        -> (matches: Bool, i: Int, j: Int, wasValue: Bool)
    {
        var i = i, j = j, wasValue = false

        while let typeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
              typeIndex <= typeEndIndex,
              let valueIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: j)
        {
            let typeToken = tokens[typeIndex]
            let valueToken = tokens[valueIndex]
            if !wasValue {
                switch valueToken {
                case _ where valueToken.isStringDelimiter, .number,
                     .identifier("true"), .identifier("false"):
                    if options.propertyTypes == .explicit {
                        // We never remove the value in this case, so exit early
                        return (false, i, j, wasValue)
                    }
                    wasValue = true
                default:
                    break
                }
            }
            guard typeToken == self.typeToken(forValueToken: valueToken) else {
                return (false, i, j, wasValue)
            }
            // Avoid introducing "inferred to have type 'Void'" warning
            if options.propertyTypes == .inferred, typeToken == .identifier("Void") ||
                typeToken == .endOfScope(")") && tokens[i] == .startOfScope("(")
            {
                return (false, i, j, wasValue)
            }
            i = typeIndex
            j = valueIndex
            if tokens[j].isStringDelimiter, let next = endOfScope(at: j) {
                j = next
            }
        }
        guard i == typeEndIndex else {
            return (false, i, j, wasValue)
        }

        // Check for ternary
        if let endOfExpression = endOfExpression(at: j, upTo: [.operator("?", .infix)]),
           next(.nonSpaceOrCommentOrLinebreak, after: endOfExpression) == .operator("?", .infix)
        {
            return (false, i, j, wasValue)
        }

        return (true, i, j, wasValue)
    }

    /// Returns the equivalent type token for a given value token
    func typeToken(forValueToken token: Token) -> Token {
        switch token {
        case let .number(_, type):
            switch type {
            case .decimal:
                return .identifier("Double")
            default:
                return .identifier("Int")
            }
        case let .identifier(name):
            return ["true", "false"].contains(name) ? .identifier("Bool") : .identifier(name)
        case let token:
            return token.isStringDelimiter ? .identifier("String") : token
        }
    }
}
