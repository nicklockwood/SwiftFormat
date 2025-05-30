// Created by Andy Bartholomew on 5/30/25.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    static let throwingTests = FormatRule(
        help: "Write tests that use `throws` instead of using `try!`."
    ) { formatter in
        guard formatter.hasImport("Testing") else { return }

        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            guard formatter.modifiersForDeclaration(at: funcKeywordIndex, contains: "@Test") else { return }
            guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: funcKeywordIndex)
            else { return }

            guard let bodyRange = functionDecl.bodyRange else { return }

            // Find all `try!` and remove the `!`
            var foundAnyTryExclamationMarks = false
            for index in bodyRange.reversed() {
                guard formatter.tokens[index] == .keyword("try") else { continue }
                guard let nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index)
                else { return }
                let nextToken = formatter.tokens[nextTokenIndex]
                if nextToken != .operator("!", .postfix) { continue }

                // Only remove the `!` if we are not within a closure, where it's not safe to just remove the `!` and make our function throw.
                if formatter.isInClosure(at: index) { return }

                formatter.removeToken(at: nextTokenIndex)
                foundAnyTryExclamationMarks = true
            }

            // If we found any `!`s, add a `throws` if it doesn't already exist.
            guard foundAnyTryExclamationMarks else { return }

            if functionDecl.effects.contains("throws") { return }

            // If there are effects, just add it to the end of the effects range.
            if let effectsRange = functionDecl.effectsRange {
                formatter.insert([.keyword("throws"), .space(" ")], at: effectsRange.upperBound)
            } else {
                // If there are no effects, add after the arguments.
                formatter.insert([.space(" "), .keyword("throws")], at: functionDecl.argumentsRange.upperBound + 1)
            }
        }
    } examples: {
        """
        ```diff
        import Testing

        struct MyFeatureTests {
        - @Test func doSomething() {
        + @Test func doSomething() throws {
             - try! MyFeature().doSomething()
             + try MyFeature().doSomething()
            }
        }
        """
    }
}
