//
//  redundantType.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Removes explicit type declarations from initialization declarations
    static let redundantType = FormatRule(
        help: "Remove redundant type from variable declarations.",
        options: ["redundanttype"]
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

            // Compares whether or not two types are equivalent
            func compare(typeStartingAfter j: Int, withTypeStartingAfter i: Int)
                -> (matches: Bool, i: Int, j: Int, wasValue: Bool)
            {
                var i = i, j = j, wasValue = false

                while let typeIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                      typeIndex <= typeEndIndex,
                      let valueIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: j)
                {
                    let typeToken = formatter.tokens[typeIndex]
                    let valueToken = formatter.tokens[valueIndex]
                    if !wasValue {
                        switch valueToken {
                        case _ where valueToken.isStringDelimiter, .number,
                             .identifier("true"), .identifier("false"):
                            if formatter.options.redundantType == .explicit {
                                // We never remove the value in this case, so exit early
                                return (false, i, j, wasValue)
                            }
                            wasValue = true
                        default:
                            break
                        }
                    }
                    guard typeToken == formatter.typeToken(forValueToken: valueToken) else {
                        return (false, i, j, wasValue)
                    }
                    // Avoid introducing "inferred to have type 'Void'" warning
                    if formatter.options.redundantType == .inferred, typeToken == .identifier("Void") ||
                        typeToken == .endOfScope(")") && formatter.tokens[i] == .startOfScope("(")
                    {
                        return (false, i, j, wasValue)
                    }
                    i = typeIndex
                    j = valueIndex
                    if formatter.tokens[j].isStringDelimiter, let next = formatter.endOfScope(at: j) {
                        j = next
                    }
                }
                guard i == typeEndIndex else {
                    return (false, i, j, wasValue)
                }

                // Check for ternary
                if let endOfExpression = formatter.endOfExpression(at: j, upTo: [.operator("?", .infix)]),
                   formatter.next(.nonSpaceOrCommentOrLinebreak, after: endOfExpression) == .operator("?", .infix)
                {
                    return (false, i, j, wasValue)
                }

                return (true, i, j, wasValue)
            }

            // The implementation of RedundantType uses inferred or explicit,
            // potentially depending on the context.
            let isInferred: Bool
            let declarationKeywordIndex: Int?
            switch formatter.options.redundantType {
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
               let declarationKeywordIndex = declarationKeywordIndex,
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
            if formatter.options.swiftVersion >= "5.9",
               let tokenAfterEquals = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
               let conditionalBranches = formatter.conditionalBranches(at: tokenAfterEquals),
               formatter.allRecursiveConditionalBranches(
                   in: conditionalBranches,
                   satisfy: { branch in
                       compare(typeStartingAfter: branch.startOfBranch, withTypeStartingAfter: colonIndex).matches
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
                        let (_, i, j, wasValue) = compare(
                            typeStartingAfter: branch.startOfBranch,
                            withTypeStartingAfter: colonIndex
                        )

                        removeType(after: branch.startOfBranch, i: i, j: j, wasValue: wasValue)
                    }
                }
            }

            // Otherwise this is just a simple assignment expression where the RHS is a single value
            else {
                let (matches, i, j, wasValue) = compare(typeStartingAfter: equalsIndex, withTypeStartingAfter: colonIndex)
                if matches {
                    removeType(after: equalsIndex, i: i, j: j, wasValue: wasValue)
                }
            }
        }
    }
}
