//
//  PreferForLoop.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 8/12/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferForLoop = FormatRule(
        help: "Convert functional `forEach` calls to for loops.",
        examples: """
        ```diff
          let strings = ["foo", "bar", "baaz"]
        - strings.forEach { placeholder in
        + for placeholder in strings {
              print(placeholder)
          }

          // Supports anonymous closures
        - strings.forEach {
        + for string in strings {
        -     print($0)
        +     print(string)
          }

        - foo.item().bar[2].baazValues(option: true).forEach {
        + for baazValue in foo.item().bar[2].baazValues(option: true) {
        -     print($0)
        +     print(baazValue)
          }

          // Doesn't affect long multiline functional chains
          placeholderStrings
              .filter { $0.style == .fooBar }
              .map { $0.uppercased() }
              .forEach { print($0) }
        ```
        """,
        options: ["anonymousforeach", "onelineforeach"]
    ) { formatter in
        formatter.forEach(.identifier("forEach")) { forEachIndex, _ in
            // Make sure this is a function call preceded by a `.`
            guard let functionCallDotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: forEachIndex),
                  formatter.tokens[functionCallDotIndex] == .operator(".", .infix),
                  let indexAfterForEach = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: forEachIndex),
                  let indexBeforeFunctionCallDot = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: functionCallDotIndex)
            else { return }

            // Parse either `{ ... }` or `({ ... })`
            let forEachCallOpenParenIndex: Int?
            let closureOpenBraceIndex: Int
            let closureCloseBraceIndex: Int
            let forEachCallCloseParenIndex: Int?

            switch formatter.tokens[indexAfterForEach] {
            case .startOfScope("{"):
                guard let endOfClosureScope = formatter.endOfScope(at: indexAfterForEach) else { return }

                forEachCallOpenParenIndex = nil
                closureOpenBraceIndex = indexAfterForEach
                closureCloseBraceIndex = endOfClosureScope
                forEachCallCloseParenIndex = nil

            case .startOfScope("("):
                guard let endOfFunctionCall = formatter.endOfScope(at: indexAfterForEach),
                      let indexAfterOpenParen = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: indexAfterForEach),
                      formatter.tokens[indexAfterOpenParen] == .startOfScope("{"),
                      let endOfClosureScope = formatter.endOfScope(at: indexAfterOpenParen)
                else { return }

                forEachCallOpenParenIndex = indexAfterForEach
                closureOpenBraceIndex = indexAfterOpenParen
                closureCloseBraceIndex = endOfClosureScope
                forEachCallCloseParenIndex = endOfFunctionCall

            default:
                return
            }

            // Abort early for single-line loops
            guard !formatter.options.preserveSingleLineForEach || formatter
                .tokens[closureOpenBraceIndex ..< closureCloseBraceIndex].contains(where: { $0.isLinebreak })
            else { return }

            // Ignore closures with capture lists for now since they're rare
            // in this context and add complexity
            guard let firstIndexInClosureBody = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closureOpenBraceIndex),
                  formatter.tokens[firstIndexInClosureBody] != .startOfScope("[")
            else { return }

            // Parse the value that `forEach` is being called on
            let forLoopSubjectRange: ClosedRange<Int>
            var forLoopSubjectIdentifier: String?

            // Parse a functional chain backwards from the `forEach` token
            var currentIndex = forEachIndex

            while let previousDotIndex = formatter.index(of: .nonSpaceOrLinebreak, before: currentIndex),
                  formatter.tokens[previousDotIndex] == .operator(".", .infix),
                  let tokenBeforeDotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: previousDotIndex)
            {
                guard let startOfChainComponent = formatter.startOfChainComponent(at: tokenBeforeDotIndex, forLoopSubjectIdentifier: &forLoopSubjectIdentifier) else {
                    // If we parse a dot we expect to parse at least one additional component in the chain.
                    // Otherwise we'd have a malformed chain that starts with a dot, so abort.
                    return
                }

                currentIndex = startOfChainComponent
            }

            guard currentIndex != forEachIndex else { return }
            forLoopSubjectRange = currentIndex ... indexBeforeFunctionCallDot

            // If there is a `try` before the `forEach` we cannot know if the subject is async/throwing or the body,
            // which makes it impossible to know if we should move it or *remove* it, so we must abort (same for await).
            if let tokenIndexBeforeForLoop = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: currentIndex),
               var prevToken = formatter.token(at: tokenIndexBeforeForLoop)
            {
                if prevToken.isUnwrapOperator {
                    prevToken = formatter.last(.nonSpaceOrComment, before: tokenIndexBeforeForLoop) ?? .space("")
                }
                if [.keyword("try"), .keyword("await")].contains(prevToken) {
                    return
                }
            }

            // If the chain includes linebreaks, don't convert it to a for loop.
            //
            // In this case converting something like:
            //
            //  placeholderStrings
            //    .filter { $0.style == .fooBar }
            //    .map { $0.uppercased() }
            //    .forEach { print($0) }
            //
            // to:
            //
            //  for placeholderString in placeholderStrings
            //    .filter { $0.style == .fooBar }
            //    .map { $0.uppercased() } { print($0) }
            //
            // would be a pretty obvious downgrade.
            if formatter.tokens[forLoopSubjectRange].contains(where: \.isLinebreak) {
                return
            }

            /// The names of the argument to the `forEach` closure.
            /// e.g. `["foo"]` in `forEach { foo in ... }`
            /// or `["foo, bar"]` in `forEach { (foo: Foo, bar: Bar) in ... }`
            let forEachValueNames: [String]
            let inKeywordIndex: Int?
            let isAnonymousClosure: Bool

            if let argumentList = formatter.parseClosureArgumentList(at: closureOpenBraceIndex) {
                isAnonymousClosure = false
                forEachValueNames = argumentList.argumentNames
                inKeywordIndex = argumentList.inKeywordIndex
            } else {
                isAnonymousClosure = true
                inKeywordIndex = nil

                if formatter.options.preserveAnonymousForEach {
                    return
                }

                // We can't introduce an identifier that matches a keyword or already exists in
                // the loop body so choose the first eligible option from a set of potential names
                var eligibleValueNames = ["item", "element", "value"]
                if var identifier = forLoopSubjectIdentifier?.singularized(), !identifier.isSwiftKeyword {
                    eligibleValueNames = [identifier] + eligibleValueNames
                }

                // The chosen name shouldn't already exist in the closure body
                guard let chosenValueName = eligibleValueNames.first(where: { name in
                    !formatter.tokens[closureOpenBraceIndex ... closureCloseBraceIndex].contains(where: { $0.string == name })
                }) else { return }

                forEachValueNames = [chosenValueName]
            }

            // Validate that the closure body is eligible to be converted to a for loop
            for closureBodyIndex in closureOpenBraceIndex ... closureCloseBraceIndex {
                guard !formatter.indexIsWithinNestedClosure(closureBodyIndex, startOfScopeIndex: closureOpenBraceIndex) else { continue }

                // We can only handle anonymous closures that just use $0, since we don't have good names to
                // use for other arguments like $1, $2, etc. If the closure has an anonymous argument
                // other than just $0 then we have to ignore it.
                if formatter.tokens[closureBodyIndex].string.hasPrefix("$"),
                   let intValue = Int(formatter.tokens[closureBodyIndex].string.dropFirst()),
                   intValue != 0
                {
                    return
                }

                // We can convert `return`s to `continue`, but only when `return` is the last token in the scope.
                // It's legal to write something like `return print("foo")` in a `forEach` as long as
                // you're still returning a `Void` value. Since `continue print("foo")` isn't legal,
                // we should just ignore this closure.
                if formatter.tokens[closureBodyIndex] == .keyword("return"),
                   let tokenAfterReturnKeyword = formatter.next(.nonSpaceOrComment, after: closureBodyIndex),
                   !(tokenAfterReturnKeyword.isLinebreak || tokenAfterReturnKeyword == .endOfScope("}"))
                {
                    return
                }
            }

            // Start updating the `forEach` call to a `for .. in .. {` loop
            for closureBodyIndex in closureOpenBraceIndex ... closureCloseBraceIndex {
                guard !formatter.indexIsWithinNestedClosure(closureBodyIndex, startOfScopeIndex: closureOpenBraceIndex) else { continue }

                // The for loop won't have any `$0` identifiers anymore, so we have to
                // update those to the value at the current loop index
                if isAnonymousClosure, formatter.tokens[closureBodyIndex].string == "$0" {
                    formatter.replaceToken(at: closureBodyIndex, with: .identifier(forEachValueNames[0]))
                }

                // In a `forEach` closure, `return` continues to the next loop iteration.
                // To get the same behavior in a for loop we convert `return`s to `continue`s.
                if formatter.tokens[closureBodyIndex] == .keyword("return") {
                    formatter.replaceToken(at: closureBodyIndex, with: .keyword("continue"))
                }
            }

            if let forEachCallCloseParenIndex = forEachCallCloseParenIndex {
                formatter.removeToken(at: forEachCallCloseParenIndex)
            }

            // Construct the new for loop
            var newTokens: [Token] = [
                .keyword("for"),
                .space(" "),
            ]

            let forEachValueNameTokens: [Token]
            if forEachValueNames.count == 1 {
                newTokens.append(.identifier(forEachValueNames[0]))
            } else {
                newTokens.append(contentsOf: tokenize("(\(forEachValueNames.joined(separator: ", ")))"))
            }

            newTokens.append(contentsOf: [
                .space(" "),
                .keyword("in"),
                .space(" "),
            ])

            newTokens.append(contentsOf: formatter.tokens[forLoopSubjectRange])

            newTokens.append(contentsOf: [
                .space(" "),
                .startOfScope("{"),
            ])

            formatter.replaceTokens(
                in: (forLoopSubjectRange.lowerBound) ... (inKeywordIndex ?? closureOpenBraceIndex),
                with: newTokens
            )
        }
    }
}

extension Formatter {
    // Returns the start index of the chain component ending at the given index
    func startOfChainComponent(at index: Int, forLoopSubjectIdentifier: inout String?) -> Int? {
        // The previous item in a dot chain can either be:
        //  1. an identifier like `foo.`
        //  2. a function call like `foo(...).`
        //  3. a subscript like `foo[...].
        //  4. a trailing closure like `map { ... }`
        //  5. Some other combination of parens / subscript like `(foo).`
        //     or even `foo["bar"]()()`.
        // And any of these can be preceded by one of the others
        switch tokens[index] {
        case let .identifier(identifierName):
            // Allowlist certain dot chain elements that should be ignored.
            // For example, in `foos.reversed().forEach { ... }` we want
            // `forLoopSubjectIdentifier` to be `foos` rather than `reversed`.
            let chainElementsToIgnore = Set([
                "reversed", "sorted", "shuffled", "enumerated", "dropFirst", "dropLast",
                "map", "flatMap", "compactMap", "filter", "reduce", "lazy",
            ])

            if forLoopSubjectIdentifier == nil || chainElementsToIgnore.contains(forLoopSubjectIdentifier ?? "") {
                // Since we have to pick a single identifier to represent the subject of the for loop,
                // just use the last identifier in the chain
                forLoopSubjectIdentifier = identifierName
            }

            return index

        case .endOfScope(")"), .endOfScope("]"):
            let closingParenIndex = index
            guard let startOfScopeIndex = startOfScope(at: closingParenIndex),
                  let previousNonSpaceNonCommentIndex = self.index(of: .nonSpaceOrComment, before: startOfScopeIndex)
            else { return nil }

            // When we find parens for a function call or braces for a subscript,
            // continue parsing at the previous non-space non-comment token.
            //  - If the previous token is a newline then this isn't a function call
            //    and we'd stop parsing. `foo   ()` is a function call but `foo\n()` isn't.
            return startOfChainComponent(at: previousNonSpaceNonCommentIndex, forLoopSubjectIdentifier: &forLoopSubjectIdentifier) ?? startOfScopeIndex

        case .endOfScope("}"):
            // Stop parsing if we reach a trailing closure.
            // Converting this to a for loop would result in unusual looking syntax like
            // `for string in strings.map { $0.uppercased() } { print(string) }`
            // which causes a warning to be emitted: "trailing closure in this context is
            // confusable with the body of the statement; pass as a parenthesized argument
            // to silence this warning".
            return nil

        default:
            return nil
        }
    }
}
