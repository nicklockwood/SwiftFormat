//
//  RedundantExtendedLifetime.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 2026-08-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant `withExtendedLifetime` calls in test cases
    static let redundantExtendedLifetime = FormatRule(
        help: "Remove redundant withExtendedLifetime calls in tests.",
        disabledByDefault: true
    ) { formatter in
        guard let testFramework = formatter.detectTestingFramework() else { return }

        formatter.forEach(.identifier("withExtendedLifetime")) { callIndex, _ in
            guard let testCaseBodyRange = formatter.enclosingTestCaseBodyRange(at: callIndex, for: testFramework),
                  let call = formatter.parseExtendedLifetimeCall(at: callIndex),
                  formatter.isRedundantExtendedLifetimeCall(call, in: testCaseBodyRange)
            else { return }

            formatter.removeExtendedLifetimeCall(call)
        }
    } examples: {
        """
        ```diff
          import Testing

          struct MyFeatureTests {
              @Test
              func myFeature() {
                  let observer = Observer()
                  observer.start()
                  #expect(observer.isRunning)
        -         withExtendedLifetime(observer) {}
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// A `withExtendedLifetime(value) { ... }` statement
    struct ExtendedLifetimeCall {
        /// The full range of the call, from `withExtendedLifetime` to the closing brace of its closure
        let range: ClosedRange<Int>
        /// The name of the variable whose lifetime is extended
        let identifier: String
        /// The body of the trailing closure, which takes the place of the call, unless the closure is empty
        let closureBodyRange: ClosedRange<Int>?
        /// The indices where the closure body refers to the closure's own argument, like `value` or `$0`.
        /// These are renamed to `identifier` when the body takes the place of the call.
        let closureArgumentReferences: [Int]
    }

    /// Parses the `withExtendedLifetime(value) { ... }` statement at the given index, if there is one
    func parseExtendedLifetimeCall(at index: Int) -> ExtendedLifetimeCall? {
        guard tokens[index] == .identifier("withExtendedLifetime"),
              // The statement is removed line by line, so it has to start its own line
              startOfLine(at: index, excludingIndent: true) == index,
              // The result of the call has to be unused, so the call can't be part of a larger expression
              isStartOfStatement(at: index),
              // A single variable argument, like `withExtendedLifetime(observer)`
              let startOfArguments = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
              tokens[startOfArguments] == .startOfScope("("),
              let endOfArguments = endOfScope(at: startOfArguments),
              let identifierIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: startOfArguments),
              case let .identifier(identifier) = tokens[identifierIndex],
              self.index(of: .nonSpaceOrCommentOrLinebreak, after: identifierIndex) == endOfArguments,
              // Followed by a trailing closure whose body can take the place of the call
              let closureStartIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfArguments),
              tokens[closureStartIndex] == .startOfScope("{"),
              let closureEndIndex = endOfScope(at: closureStartIndex),
              let closure = parseExtendedLifetimeClosure(at: closureStartIndex, valueName: identifier)
        else { return nil }

        // Nothing can follow the call, since the closure body takes its place
        if let tokenAfterCall = self.index(of: .nonSpaceOrCommentOrLinebreak, after: closureEndIndex),
           tokens[tokenAfterCall].isOperator || tokens[tokenAfterCall].isStartOfScope || tokens[tokenAfterCall].isDelimiter
        {
            return nil
        }

        return ExtendedLifetimeCall(
            range: index ... closureEndIndex,
            identifier: identifier,
            closureBodyRange: closure.bodyRange,
            closureArgumentReferences: closure.argumentReferences
        )
    }

    /// The body of the given `withExtendedLifetime` closure, if the body can take the place of the call
    func parseExtendedLifetimeClosure(at closureStartIndex: Int, valueName: String)
        -> (bodyRange: ClosedRange<Int>?, argumentReferences: [Int])?
    {
        guard let closureEndIndex = endOfScope(at: closureStartIndex) else { return nil }

        // The closure can name the value it's passed, like `{ observer in ... }`.
        // Otherwise the body refers to the value using the `$0` shorthand.
        var startOfBody = closureStartIndex
        var closureValueName: String? = "$0"

        if let closureArguments = parseClosureArguments(at: closureStartIndex) {
            guard closureArguments.captureListRange == nil,
                  closureArguments.globalActorIndex == nil,
                  closureArguments.returnTypeRange == nil,
                  closureArguments.argumentIndices.count <= 1
            else { return nil }

            startOfBody = closureArguments.inKeywordIndex
            let argumentName = closureArguments.argumentIndices.first.map { tokens[$0].string }
            closureValueName = argumentName == "_" ? nil : argumentName
        }

        guard let firstBodyToken = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfBody),
              let lastBodyToken = index(of: .nonSpaceOrCommentOrLinebreak, before: closureEndIndex),
              firstBodyToken <= lastBodyToken
        else { return (bodyRange: nil, argumentReferences: []) }

        let bodyRange = firstBodyToken ... lastBodyToken

        // Once hoisted, a `return` would return from the enclosing function
        guard !bodyRange.contains(where: { tokens[$0] == .keyword("return") }) else { return nil }

        // A shorthand argument in a nested closure belongs to that closure instead
        let shorthandArguments = bodyRange.filter { index in
            tokens[index].isIdentifier
                && tokens[index].string.hasPrefix("$")
                && isInClosureScope(at: index, of: closureStartIndex)
        }

        guard shorthandArguments.allSatisfy({ tokens[$0] == .identifier("$0") }) else { return nil }

        var argumentReferences = [Int]()
        if closureValueName == "$0" {
            argumentReferences = shorthandArguments
        } else {
            // A closure with an argument clause can't use shorthand arguments
            guard shorthandArguments.isEmpty else { return nil }

            // `{ _ in ... }` discards the value, and `{ observer in ... }` already uses its name
            if let closureValueName, closureValueName != valueName {
                argumentReferences = indicesOfReferences(to: closureValueName, in: bodyRange)
            }
        }

        // Renaming the closure's argument isn't valid if the body declares either name itself
        if !argumentReferences.isEmpty {
            let namesToPreserve = [valueName, closureValueName].compactMap { $0 }
            guard !namesToPreserve.contains(where: { indexOfLocalDeclaration(of: $0, in: bodyRange) != nil }) else {
                return nil
            }
        }

        return (bodyRange: bodyRange, argumentReferences: argumentReferences)
    }

    /// Whether the given `withExtendedLifetime` call has no effect, so can be removed
    func isRedundantExtendedLifetimeCall(_ call: ExtendedLifetimeCall, in testCaseBodyRange: ClosedRange<Int>) -> Bool {
        // `withExtendedLifetime` only has no effect if the variable is declared in the same scope as the call
        guard let scopeIndex = startOfScope(at: call.range.lowerBound),
              let declarationIndex = indexOfLocalDeclaration(of: call.identifier, in: scopeIndex ... call.range.lowerBound),
              startOfScope(at: declarationIndex) == scopeIndex
        else { return false }

        // References to the closure's own argument become references to the variable
        if !call.closureArgumentReferences.isEmpty {
            return true
        }

        // If the variable isn't referenced anywhere else, the call is suppressing an
        // "initialization of immutable value was never used" warning. Only the references
        // that survive the removal count, so not the ones in the call's own arguments.
        return indicesOfReferences(to: call.identifier, in: testCaseBodyRange).contains(where: { index in
            !call.range.contains(index) || call.closureBodyRange?.contains(index) == true
        })
    }

    /// Removes the given `withExtendedLifetime` call, but keeps the body of its closure
    func removeExtendedLifetimeCall(_ call: ExtendedLifetimeCall) {
        // Renaming the closure's argument doesn't change any indices, so this is safe to do first
        for referenceIndex in call.closureArgumentReferences {
            replaceToken(at: referenceIndex, with: .identifier(call.identifier))
        }

        if let closureBodyRange = call.closureBodyRange {
            // The `indent` rule updates the indentation of the hoisted body.
            replaceTokens(in: call.range, with: Array(tokens[closureBodyRange]))
        } else {
            removeTokens(in: startOfLine(at: call.range.lowerBound) ... endOfLine(at: call.range.upperBound))
        }
    }

    /// The body range of the test case function containing the given index, if there is one
    func enclosingTestCaseBodyRange(at index: Int, for testFramework: TestingFramework) -> ClosedRange<Int>? {
        var scopeIndex = startOfScope(at: index)

        while let startOfScopeIndex = scopeIndex {
            if tokens[startOfScopeIndex] == .startOfScope("{"),
               let keywordIndex = indexOfLastSignificantKeyword(at: startOfScopeIndex, excluding: ["throws", "rethrows"]),
               tokens[keywordIndex] == .keyword("func"),
               let functionDecl = parseFunctionDeclaration(keywordIndex: keywordIndex),
               functionDecl.bodyRange?.lowerBound == startOfScopeIndex
            {
                guard isTestCase(at: keywordIndex, in: functionDecl, for: testFramework) else { return nil }
                return functionDecl.bodyRange
            }

            scopeIndex = startOfScope(at: startOfScopeIndex)
        }

        return nil
    }

    /// Whether the token at the given index is in the given closure itself,
    /// rather than in a closure nested inside it
    func isInClosureScope(at index: Int, of closureStartIndex: Int) -> Bool {
        var scopeIndex = startOfScope(at: index)

        while let currentScopeIndex = scopeIndex, currentScopeIndex != closureStartIndex {
            if isStartOfClosure(at: currentScopeIndex) {
                return false
            }
            scopeIndex = startOfScope(at: currentScopeIndex)
        }

        return scopeIndex == closureStartIndex
    }

    /// The index of the `let` or `var` keyword that declares the given variable, searching backwards through the given range
    func indexOfLocalDeclaration(of name: String, in range: ClosedRange<Int>) -> Int? {
        range.last(where: { index in
            guard tokens[index] == .keyword("let") || tokens[index] == .keyword("var"),
                  let nameIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index)
            else { return false }

            return tokens[nameIndex] == .identifier(name)
        })
    }

    /// The indices where the given variable is referenced within the given range,
    /// excluding its own declaration, member names, and argument labels
    func indicesOfReferences(to name: String, in range: ClosedRange<Int>) -> [Int] {
        range.filter { index in
            guard tokens[index] == .identifier(name),
                  let previousIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index)
            else { return false }

            // Not a declaration like `let name`, or a member name like `foo.name`
            if [.keyword("let"), .keyword("var"), .keyword("func")].contains(tokens[previousIndex]) {
                return false
            }
            if tokens[previousIndex].isOperator(".") {
                return false
            }

            // Not an argument label like `Foo(name: value)`
            if next(.nonSpaceOrCommentOrLinebreak, after: index) == .delimiter(":") {
                return false
            }

            return true
        }
    }
}
