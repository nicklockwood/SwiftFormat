//
//  RedundantClosure.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/28/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantClosure = FormatRule(
        help: """
        Removes redundant closures bodies, containing a single statement,
        which are called immediately.
        """,
        orderAfter: [.redundantReturn]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { closureStartIndex, _ in
            var startIndex = closureStartIndex
            if formatter.isStartOfClosure(at: closureStartIndex),
               var closureEndIndex = formatter.endOfScope(at: closureStartIndex),
               // Closures that are called immediately are redundant
               // (as long as there's exactly one statement inside them)
               var closureCallOpenParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureEndIndex),
               var closureCallCloseParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureCallOpenParenIndex),
               formatter.token(at: closureCallOpenParenIndex) == .startOfScope("("),
               formatter.token(at: closureCallCloseParenIndex) == .endOfScope(")"),
               // Make sure to exclude closures that are completely empty,
               // because removing them could break the build.
               formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureStartIndex) != closureEndIndex
            {
                /// Whether or not this closure has a single, simple expression in its body.
                /// These closures can always be simplified / removed regardless of the context.
                let hasSingleSimpleExpression = formatter.blockBodyHasSingleStatement(
                    atStartOfScope: closureStartIndex,
                    includingConditionalStatements: false,
                    includingReturnStatements: true
                )

                /// Whether or not this closure has a single if/switch expression in its body.
                /// Since if/switch expressions are only valid in the `return` position or as an `=` assignment,
                /// these closures can only sometimes be simplified / removed.
                let hasSingleConditionalExpression = !hasSingleSimpleExpression &&
                    formatter.blockBodyHasSingleStatement(
                        atStartOfScope: closureStartIndex,
                        includingConditionalStatements: true,
                        includingReturnStatements: true,
                        includingReturnInConditionalStatements: false
                    )

                guard hasSingleSimpleExpression || hasSingleConditionalExpression else {
                    return
                }

                // This rule also doesn't support closures with an `in` token.
                //  - We can't just remove this, because it could have important type information.
                //    For example, `let double = { () -> Double in 100 }()` and `let double = 100` have different types.
                //  - We could theoretically support more sophisticated checks / transforms here,
                //    but this seems like an edge case so we choose not to handle it.
                for inIndex in closureStartIndex ... closureEndIndex
                    where formatter.token(at: inIndex) == .keyword("in")
                {
                    if !formatter.indexIsWithinNestedClosure(inIndex, startOfScopeIndex: closureStartIndex) {
                        return
                    }
                }

                // If the closure calls a single function, which throws or returns `Never`,
                // then removing the closure will cause a compilation failure.
                //  - We maintain a list of known functions that return `Never`.
                //    We could expand this to be user-provided if necessary.
                for i in closureStartIndex ... closureEndIndex {
                    switch formatter.tokens[i] {
                    case .identifier("fatalError"), .identifier("preconditionFailure"), .keyword("throw"):
                        if !formatter.indexIsWithinNestedClosure(i, startOfScopeIndex: closureStartIndex) {
                            return
                        }
                    default:
                        break
                    }
                }

                // If closure is preceded by try and/or await then remove those too
                if let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex, if: {
                    $0 == .keyword("await")
                }) {
                    startIndex = prevIndex
                }
                if let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex, if: {
                    $0 == .keyword("try")
                }) {
                    startIndex = prevIndex
                }

                // Since if/switch expressions are only valid in the `return` position or as an `=` assignment,
                // these closures can only sometimes be simplified / removed.
                if hasSingleConditionalExpression {
                    // Find the `{` start of scope or `=` and verify that the entire following expression consists of just this closure.
                    var startOfScopeContainingClosure = formatter.startOfScope(at: startIndex)
                    var assignmentBeforeClosure = formatter.index(of: .operator("=", .infix), before: startIndex)

                    if let assignmentBeforeClosure, formatter.isConditionalStatement(at: assignmentBeforeClosure) {
                        // Not valid to use conditional expression directly in condition body
                        return
                    }

                    let potentialStartOfExpressionContainingClosure: Int?
                    switch (startOfScopeContainingClosure, assignmentBeforeClosure) {
                    case (nil, nil):
                        potentialStartOfExpressionContainingClosure = nil
                    case (.some(let startOfScope), nil):
                        guard formatter.tokens[startOfScope] == .startOfScope("{") else { return }
                        potentialStartOfExpressionContainingClosure = startOfScope
                    case (nil, let .some(assignmentBeforeClosure)):
                        potentialStartOfExpressionContainingClosure = assignmentBeforeClosure
                    case let (.some(startOfScope), .some(assignmentBeforeClosure)):
                        potentialStartOfExpressionContainingClosure = max(startOfScope, assignmentBeforeClosure)
                    }

                    if let potentialStartOfExpressionContainingClosure {
                        guard var startOfExpressionIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: potentialStartOfExpressionContainingClosure)
                        else { return }

                        // Skip over any return token that may be present
                        if formatter.tokens[startOfExpressionIndex] == .keyword("return"),
                           let nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: startOfExpressionIndex)
                        {
                            startOfExpressionIndex = nextTokenIndex
                        }

                        // Parse the expression and require that entire expression is simply just this closure.
                        guard let expressionRange = formatter.parseExpressionRange(startingAt: startOfExpressionIndex),
                              expressionRange == startIndex ... closureCallCloseParenIndex
                        else { return }
                    }
                }

                // If the closure is a property with an explicit `Void` type,
                // we can't remove the closure since the build would break
                // if the method is `@discardableResult`
                // https://github.com/nicklockwood/SwiftFormat/issues/1236
                if let equalsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex),
                   formatter.token(at: equalsIndex) == .operator("=", .infix),
                   let colonIndex = formatter.index(of: .delimiter(":"), before: equalsIndex),
                   let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                   formatter.endOfVoidType(at: nextIndex) != nil
                {
                    return
                }

                // First we remove the spaces and linebreaks between the { } and the remainder of the closure body
                //  - This requires a bit of bookkeeping, but makes sure we don't remove any
                //    whitespace characters outside of the closure itself
                while formatter.token(at: closureStartIndex + 1)?.isSpaceOrLinebreak == true {
                    formatter.removeToken(at: closureStartIndex + 1)

                    closureCallOpenParenIndex -= 1
                    closureCallCloseParenIndex -= 1
                    closureEndIndex -= 1
                }

                while formatter.token(at: closureEndIndex - 1)?.isSpaceOrLinebreak == true {
                    formatter.removeToken(at: closureEndIndex - 1)

                    closureCallOpenParenIndex -= 1
                    closureCallCloseParenIndex -= 1
                    closureEndIndex -= 1
                }

                // remove the trailing }() tokens, working backwards to not invalidate any indices
                formatter.removeToken(at: closureCallCloseParenIndex)
                formatter.removeToken(at: closureCallOpenParenIndex)
                formatter.removeToken(at: closureEndIndex)

                // Remove the initial return token, and any trailing space, if present.
                if let returnIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureStartIndex),
                   formatter.token(at: returnIndex)?.string == "return"
                {
                    while formatter.token(at: returnIndex + 1)?.isSpaceOrLinebreak == true {
                        formatter.removeToken(at: returnIndex + 1)
                    }

                    formatter.removeToken(at: returnIndex)
                }

                // Finally, remove then open `{` token
                formatter.removeTokens(in: startIndex ... closureStartIndex)
            }
        }
    } examples: {
        """
        ```diff
        - let foo = { Foo() }()
        + let foo = Foo()
        ```

        ```diff
        - lazy var bar = {
        -     Bar(baaz: baaz,
        -         quux: quux)
        - }()
        + lazy var bar = Bar(baaz: baaz,
        +                    quux: quux)
        ```
        """
    }
}
