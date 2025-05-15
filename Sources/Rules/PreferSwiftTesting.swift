//
//  PreferSwiftTesting.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 1/25/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let preferSwiftTesting = FormatRule(
        help: "Prefer the Swift Testing library over XCTest.",
        disabledByDefault: true,
        options: ["xctestsymbols"]
    ) { formatter in
        // Swift Testing was introduced in Xcode 16.0 with Swift 6.0
        guard formatter.options.swiftVersion >= "6.0" else { return }

        // Ensure there are no XCTest helpers that this rule doesn't support
        // before we start converting any test cases.
        guard !formatter.hasUnsupportedXCTestHelper() else { return }

        let declarations = formatter.parseDeclarations()

        let xcTestSuites = declarations
            .compactMap(\.asTypeDeclaration)
            .filter { $0.conformances.contains(where: { $0.conformance == "XCTestCase" }) }

        guard !xcTestSuites.isEmpty,
              !xcTestSuites.contains(where: { $0.hasUnsupportedXCTestFunctionality() })
        else { return }

        // Replace `import XCTest` with `import Testing`.
        // XCTest also exports Foundation, so add an explicit Foundation import for compatibility.
        formatter.addImports(["Testing", "Foundation"])
        formatter.removeImports(["XCTest"])

        // XCTest also exports UIKit. To maintain compatibility, add an explicit UIKit import
        // if the test case file references any symbols that appear to come from UIKit.
        if formatter.referencesUIKitSymbols() {
            formatter.addImports(["UIKit"])
        }

        for xcTestSuite in xcTestSuites {
            xcTestSuite.convertXCTestCaseToSwiftTestingSuite()
        }

        formatter.forEach(.identifier) { identifierIndex, token in
            if token.string.hasPrefix("XCT") {
                formatter.convertXCTestHelperToSwiftTestingExpectation(at: identifierIndex)
            }
        }
    } examples: {
        """
        ```diff
          @testable import MyFeatureLib
        - import XCTest
        + import Testing
        + import Foundation

        - final class MyFeatureTests: XCTestCase {
        -     func testMyFeatureHasNoBugs() {
        -         let myFeature = MyFeature()
        -         myFeature.runAction()
        -         XCTAssertFalse(myFeature.hasBugs, "My feature has no bugs")
        -         XCTAssertEqual(myFeature.crashes.count, 0, "My feature doesn't crash")
        -         XCTAssertNil(myFeature.crashReport)
        -     }
        - }
        + @MainActor @Suite(.serialized)
        + final class MyFeatureTests { 
        +     @Test func myFeatureHasNoBugs() {
        +         let myFeature = MyFeature()
        +         myFeature.runAction()
        +         #expect(!myFeature.hasBugs, "My feature has no bugs")
        +         #expect(myFeature.crashes.isEmpty, "My feature doesn't crash")
        +         #expect(myFeature.crashReport == nil)
        +     }
        + }

        - final class MyFeatureTests: XCTestCase {
        -     var myFeature: MyFeature!
        - 
        -     override func setUp() async throws {
        -         myFeature = try await MyFeature()
        -     }
        - 
        -     override func tearDown() {
        -         myFeature = nil
        -     }
        - 
        -     func testMyFeatureWorks() {
        -         myFeature.runAction()
        -         XCTAssertTrue(myFeature.worksProperly)
        -         XCTAssertEqual(myFeature.screens.count, 8)
        -     }
        - }
        + @MainActor
        + final class MyFeatureTests {
        +     var myFeature: MyFeature!
        + 
        +     init() async throws {
        +         myFeature = try await MyFeature()
        +     }
        + 
        +     deinit {
        +         myFeature = nil
        +     }
        + 
        +     @Test func myFeatureWorks() {
        +         myFeature.runAction()
        +         #expect(myFeature.worksProperly)
        +         #expect(myFeature.screens.count == 8)
        +     }
        + }
        ```
        """
    }
}

// MARK: XCTestCase test suite convesaion

extension TypeDeclaration {
    /// Whether or not this declaration uses XCTest functionality that is
    /// not supported by the preferSwiftTesting rule.
    func hasUnsupportedXCTestFunctionality() -> Bool {
        let overriddenMethods = body.filter {
            $0.modifiers.contains("override")
        }

        let supportedOverrides = Set(["setUp", "setUpWithError", "tearDown"])

        for overriddenMethod in overriddenMethods {
            guard let methodName = overriddenMethod.name,
                  supportedOverrides.contains(methodName)
            else { return true }

            // async / throws `tearDown` can't be converted to a `deinit`
            if methodName == "tearDown",
               overriddenMethod.keyword == "func",
               let startOfArguments = formatter.index(of: .startOfScope("("), after: overriddenMethod.keywordIndex),
               let endOfArguments = formatter.endOfScope(at: startOfArguments),
               let effect = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfArguments),
               ["async", "throws"].contains(tokens[effect].string)
            {
                return true
            }
        }

        return false
    }

    /// Converts this XCTestCase implementation to a Swift Testing test suite
    func convertXCTestCaseToSwiftTestingSuite() {
        // Remove the XCTestCase conformance
        if let xcTestCaseConformance = conformances.first(where: { $0.conformance == "XCTestCase" }) {
            formatter.removeConformance(at: xcTestCaseConformance.index)
        }

        // XCTest runs test serially, but Swift Testing defaults to running tests concurrently.
        // For compatibility, have the generate Swift Testing suite default to running tests serially.
        //
        // Also from the XCTest to Swift Testing migration guide:
        // https://developer.apple.com/documentation/testing/migratingfromxctest
        // > XCTest runs synchronous test methods on the main actor by default,
        // > while the testing library runs all test functions on an arbitrary task.
        // > If a test function must run on the main thread, isolate it to the main actor
        // > with @MainActor, or run the thread-sensitive code inside a call to
        // > MainActor.run(resultType:body:).
        //
        // Moving test case to a background thread may cause failures, e.g. if
        // the test case accesses any UIKit APIs, so we mark the test suite
        // as @MainActor for maximum compatibility.
        let startOfModifiers = formatter.startOfModifiers(at: keywordIndex, includingAttributes: true)
        if !modifiers.contains("@MainActor") {
            formatter.insert(tokenize("@MainActor @Suite(.serialized)\n"), at: startOfModifiers)
        } else {
            formatter.insert(tokenize("@Suite(.serialized)\n"), at: startOfModifiers)
        }

        let instanceMethods = body.filter { $0.keyword == "func" && !$0.modifiers.contains("static") }

        for instanceMethod in instanceMethods {
            guard let methodName = instanceMethod.name,
                  let startOfParameters = formatter.index(of: .startOfScope("("), after: instanceMethod.keywordIndex),
                  let endOfParameters = formatter.endOfScope(at: startOfParameters),
                  let startOfFunctionBody = formatter.index(of: .startOfScope("{"), after: endOfParameters),
                  let endOfFunctionBody = formatter.endOfScope(at: startOfFunctionBody)
            else { continue }

            // Convert the setUp method to an initializer
            if methodName == "setUp" || methodName == "setUpWithError" {
                formatter.convertXCTestOverride(
                    at: instanceMethod.keywordIndex,
                    toLifecycleMethod: "init"
                )
            }

            // Convert the tearDown method to a deinit
            if methodName == "tearDown" {
                formatter.convertXCTestOverride(
                    at: instanceMethod.keywordIndex,
                    toLifecycleMethod: "deinit"
                )
            }

            // Convert any test case method to a @Test method
            if methodName.hasPrefix("test") {
                let arguments = formatter.parseFunctionDeclarationArguments(startOfScope: startOfParameters)
                guard arguments.isEmpty else { continue }

                // In Swift Testing, idiomatic test case names don't start with "test".
                formatter.removeTestPrefix(fromFunctionAt: instanceMethod.keywordIndex)

                // XCTest assertions have throwing autoclosures, so can include a `try`
                // without the test case being `throws`. If the test case method isn't `throws`
                // but has any `try`s in the method body, we have to add `throws`.
                if !tokens[endOfParameters ..< startOfFunctionBody].contains(.keyword("throws")),
                   tokens[startOfFunctionBody ... endOfFunctionBody].contains(.keyword("try")),
                   let indexBeforeStartOfFunctionBody = formatter.index(of: .nonSpaceOrComment, before: startOfFunctionBody)
                {
                    formatter.insert([.space(" "), .keyword("throws")], at: indexBeforeStartOfFunctionBody + 1)
                }

                // Add the @Test macro
                formatter.insert(tokenize("@Test "), at: formatter.startOfModifiers(at: instanceMethod.keywordIndex, includingAttributes: true))
            }
        }
    }
}

// MARK: XCTest function helpers

extension Formatter {
    /// Whether or not the file contains an XCTest helper function that
    /// isn't supported by the preferSwiftTesting rule.
    func hasUnsupportedXCTestHelper() -> Bool {
        // https://developer.apple.com/documentation/xctest/xctestcase
        let xcTestCaseInstanceMethods = Set(["expectation", "wait", "measure", "measureMetrics", "addTeardownBlock", "runsForEachTargetApplicationUIConfiguration", "continueAfterFailure", "executionTimeAllowance", "startMeasuring", "stopMeasuring", "defaultPerformanceMetrics", "defaultMetrics", "defaultMeasureOptions", "fulfillment", "addUIInterruptionMonitor", "keyValueObservingExpectation", "removeUIInterruptionMonitor"])
            .union(options.additionalXCTestSymbols)

        for index in tokens.indices where tokens[index].isIdentifier {
            let identifier = tokens[index].string

            if xcTestCaseInstanceMethods.contains(identifier) {
                return true
            }

            // We know how to handle XCTestCase, XCTest, and any XCTAssert variant implemented in `swiftTestingExpectationForXCTestHelper`.
            if tokens[index].string.hasPrefix("XC") {
                let previousToken = lastToken(before: index, where: { !$0.isSpaceOrCommentOrLinebreak })
                switch identifier {
                case "XCTestCase":
                    if previousToken != .delimiter(":") {
                        return true
                    }

                case "XCTest":
                    if previousToken != .keyword("import") {
                        return true
                    }

                default:
                    if swiftTestingExpectationForXCTestHelper(at: index) == nil {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Whether or not this file includes a symbol starting with the UI prefix, which indicates that it probably comes from the UIKit library.
    func referencesUIKitSymbols() -> Bool {
        let allIdentifiersInFile = Set(tokens.lazy.filter(\.isIdentifier).map(\.string))
        return allIdentifiersInFile.contains(where: { $0.hasPrefix("UI") })
    }

    /// Converts the XCTest helper function (e.g. `XCTAssert(...)`) at the given index
    /// to a Swift Testng expectation (e.g. `#expect(...)`).
    func convertXCTestHelperToSwiftTestingExpectation(at identifierIndex: Int) {
        guard let swiftTestingExpectation = swiftTestingExpectationForXCTestHelper(at: identifierIndex),
              let startOfFunctionCall = index(of: .startOfScope("("), after: identifierIndex),
              let endOfFunctionCall = endOfScope(at: startOfFunctionCall)
        else { return }

        replaceTokens(in: identifierIndex ... endOfFunctionCall, with: swiftTestingExpectation)
    }

    /// Computes the Swift Testing expectation (e.g. `#expect(...)`)
    /// for the XCTest helper function (e.g. `XCTAssert(...)`) at the given index.
    /// Returns `nil` if this XCTest helper function is unsupported.
    func swiftTestingExpectationForXCTestHelper(at identifierIndex: Int) -> [Token]? {
        guard tokens[identifierIndex].isIdentifier,
              tokens[identifierIndex].string.hasPrefix("XCT"),
              let startOfFunctionCall = index(of: .nonSpaceOrComment, after: identifierIndex)
        else { return nil }

        switch tokens[identifierIndex].string {
        case "XCTAssert":
            return convertXCTAssertToTestingExpectation(at: identifierIndex) { value in
                value
            }

        case "XCTAssertTrue":
            return convertXCTAssertToTestingExpectation(at: identifierIndex) { value in
                value
            }

        case "XCTAssertFalse":
            return convertXCTAssertToTestingExpectation(at: identifierIndex) { value in
                // Unlike other operators which are whitespace insensitive, the ! token has to come immediately before the first
                // non-space/non-comment token in the rhs value, and after any effect like `try await`.
                // ! also has stronger associativity than other operators, (for example, `!foo == bar` would be incorrect),
                // so we have to wrap the value in parens if it includes any infix operators.
                var tokens = tokenize(value.wrappedInParensIfContainsOperatorOrTry())
                if let firstTokenIndex = tokens.firstIndex(where: { !$0.isSpaceOrCommentOrLinebreak }) {
                    tokens.insert(.operator("!", .prefix), at: firstTokenIndex)
                }

                return tokens.string
            }

        case "XCTAssertNil":
            return convertXCTAssertToTestingExpectation(at: identifierIndex) { value in
                "\(value.wrappedInParensIfContainsOperatorOrTry()) == nil"
            }

        case "XCTAssertNotNil":
            return convertXCTAssertToTestingExpectation(at: identifierIndex) { value in
                "\(value.wrappedInParensIfContainsOperatorOrTry()) != nil"
            }

        case "XCTAssertEqual":
            return convertXCTComparisonToTestingExpectation(
                at: identifierIndex,
                operator: "=="
            )

        case "XCTAssertNotEqual":
            return convertXCTComparisonToTestingExpectation(
                at: identifierIndex,
                operator: "!="
            )

        case "XCTAssertIdentical":
            return convertXCTComparisonToTestingExpectation(
                at: identifierIndex,
                operator: "==="
            )

        case "XCTAssertNotIdentical":
            return convertXCTComparisonToTestingExpectation(
                at: identifierIndex,
                operator: "!=="
            )

        case "XCTAssertGreaterThan":
            return convertXCTComparisonToTestingExpectation(
                at: identifierIndex,
                operator: ">"
            )

        case "XCTAssertGreaterThanOrEqual":
            return convertXCTComparisonToTestingExpectation(
                at: identifierIndex,
                operator: ">="
            )

        case "XCTAssertLessThan":
            return convertXCTComparisonToTestingExpectation(
                at: identifierIndex,
                operator: "<"
            )

        case "XCTAssertLessThanOrEqual":
            return convertXCTComparisonToTestingExpectation(
                at: identifierIndex,
                operator: "<="
            )

        case "XCTFail":
            let functionParams = parseFunctionCallArguments(startOfScope: startOfFunctionCall)
            switch functionParams.count {
            case 0:
                return tokenize("Issue.record()")
            case 1:
                return tokenize("Issue.record(\(functionParams[0].value.asSwiftTestingComment()))")
            default:
                return nil
            }

        case "XCTUnwrap":
            let functionParams = parseFunctionCallArguments(startOfScope: startOfFunctionCall)
            switch functionParams.count {
            case 1:
                return tokenize("#require(\(functionParams[0].value))")
            case 2:
                return tokenize("#require(\(functionParams[0].value),\(functionParams[1].value.asSwiftTestingComment()))")
            default:
                return nil
            }

        case "XCTAssertNoThrow":
            let functionParams = parseFunctionCallArguments(startOfScope: startOfFunctionCall)
            switch functionParams.count {
            case 1:
                return tokenize("#expect(throws: Never.self) { \(functionParams[0].value) }")
            case 2:
                return tokenize("#expect(throws: Never.self,\(functionParams[1].value.asSwiftTestingComment())) { \(functionParams[0].value) }")
            default:
                return nil
            }

        case "XCTAssertThrowsError":
            let functionParams = parseFunctionCallArguments(startOfScope: startOfFunctionCall)

            // Trailing closure variant is unsupported for now
            if let endOfFunctionCall = endOfScope(at: startOfFunctionCall),
               let startOfTrailingClosure = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfFunctionCall),
               tokens[startOfTrailingClosure] == .startOfScope("{")
            { return nil }

            switch functionParams.count {
            case 1:
                return tokenize("#expect(throws: Error.self) { \(functionParams[0].value) }")
            case 2:
                return tokenize("#expect(throws: Error.self,\(functionParams[1].value.asSwiftTestingComment())) { \(functionParams[0].value) }")
            default:
                return nil
            }

        default:
            return nil
        }
    }

    /// Converts a single-value XCTest assertion like XCTAssertTrue or XCTAssertNil
    /// to a Swift Testing expectation. Supports an optional message.
    func convertXCTAssertToTestingExpectation(
        at identifierIndex: Int,
        makeAssertion: (_ value: String) -> String
    ) -> [Token]? {
        guard let startOfFunctionCall = index(of: .nonSpaceOrComment, after: identifierIndex) else { return nil }
        let functionParams = parseFunctionCallArguments(startOfScope: startOfFunctionCall)

        // All of the function params should be unlabeled
        guard functionParams.allSatisfy({ $0.label == nil }) else { return nil }

        let value: String
        let message: String?
        switch functionParams.count {
        case 1:
            value = functionParams[0].value
            message = nil
        case 2:
            value = functionParams[0].value
            message = functionParams[1].value.asSwiftTestingComment()
        default:
            return nil
        }

        if let message {
            return tokenize("#expect(\(makeAssertion(value)),\(message))")
        } else {
            return tokenize("#expect(\(makeAssertion(value)))")
        }
    }

    /// Converts a single-value XCTest assertion like XCTAssertTrue or XCTAssertNil
    /// to a Swift Testing expectation. Supports an optional message.
    func convertXCTComparisonToTestingExpectation(
        at identifierIndex: Int,
        operator operatorToken: String
    ) -> [Token]? {
        guard let startOfFunctionCall = index(of: .nonSpaceOrComment, after: identifierIndex) else { return nil }
        let functionParams = parseFunctionCallArguments(startOfScope: startOfFunctionCall)

        // All of the function params should be unlabeled
        guard functionParams.allSatisfy({ $0.label == nil }) else { return nil }

        let lhs: String
        let rhs: String
        let message: String?
        switch functionParams.count {
        case 2:
            lhs = functionParams[0].value.wrappedInParensIfContainsOperatorOrTry()
            rhs = functionParams[1].value.wrappedInParensIfContainsOperatorOrTry()
            message = nil
        case 3:
            lhs = functionParams[0].value.wrappedInParensIfContainsOperatorOrTry()
            rhs = functionParams[1].value.wrappedInParensIfContainsOperatorOrTry()
            message = functionParams[2].value.asSwiftTestingComment()
        default:
            return nil
        }

        if let message {
            return tokenize("#expect(\(lhs) \(operatorToken)\(rhs),\(message))")
        } else {
            return tokenize("#expect(\(lhs) \(operatorToken)\(rhs))")
        }
    }

    /// Converts the XCTest override method `setUp` or `tearDown` to the given lifecycle method
    func convertXCTestOverride(at keywordIndex: Int, toLifecycleMethod lifecycleMethodName: String) {
        guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex),
              let startOfArgumentsIndex = index(of: .startOfScope("("), after: nameIndex),
              let endOfArgumentsIndex = endOfScope(at: startOfArgumentsIndex),
              let startOfFunctionBody = index(of: .startOfScope("{"), after: endOfArgumentsIndex),
              let endOfFunctionBody = endOfScope(at: startOfFunctionBody)
        else { return }

        // Remove `super.setUp()` / `super.tearDown()` if present
        if let superCall = index(of: .identifier("super"), in: startOfFunctionBody + 1 ..< endOfFunctionBody),
           let dotIndex = index(of: .nonSpaceOrLinebreak, after: superCall),
           tokens[dotIndex] == .operator(".", .infix),
           let methodName = index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
           tokens[methodName] == tokens[nameIndex],
           let startOfCall = index(of: .nonSpaceOrCommentOrLinebreak, after: methodName),
           tokens[startOfCall] == .startOfScope("("),
           let endOfCall = endOfScope(at: startOfCall)
        {
            removeTokens(in: startOfLine(at: superCall) ... endOfCall + 1)
        }

        // Replace `func setUp` with `init`, or `func tearDown` with `deinit`.
        // For `deinit`, we also have to remove the parens from the `tearDown()` method.
        if lifecycleMethodName == "deinit" {
            replaceTokens(in: keywordIndex ... endOfArgumentsIndex, with: [.keyword(lifecycleMethodName)])
        } else {
            replaceTokens(in: keywordIndex ... nameIndex, with: [.keyword(lifecycleMethodName)])
        }

        // Remove the `override` modifier
        if let overrideModifier = indexOfModifier("override", forDeclarationAt: keywordIndex) {
            removeTokens(in: overrideModifier ... overrideModifier + 1)
        }
    }
}

extension String {
    /// Converts this value to a comment that can be used as a Swift Testing `Comment` value,
    /// which is `ExpressibleByStringLiteral` but not a `String` itself.
    func asSwiftTestingComment() -> String {
        let formatter = Formatter(tokenize(self))

        // If the entire value is a string literal, we can use it directly as
        // a Swift Testing comment literal.
        if let startOfString = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: -1),
           formatter.tokens[startOfString].isStringDelimiter,
           let endOfString = formatter.endOfScope(at: startOfString),
           formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endOfString) == nil
        {
            return self
        }

        else {
            let leadingSpaces = formatter.currentIndentForLine(at: 0)
            return leadingSpaces + "Comment(rawValue: \(trimmingCharacters(in: .whitespaces)))"
        }
    }

    /// Wraps this value in parens if the value contains an infix operator or leading try keyword.
    /// For example, `!foo == bar` and `!(foo == bar)` have different meanings,
    /// and `try? foo() == bar` and (`(try? foo()) == bar` have different meanings.
    func wrappedInParensIfContainsOperatorOrTry() -> String {
        let formatter = Formatter(tokenize(self))

        guard let firstTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: -1),
              let lastTokenIndex = formatter.lastIndex(of: .nonSpaceOrCommentOrLinebreak, in: formatter.tokens.indices)
        else { return formatter.tokens.string }

        // If the operator if nested in parens or a closure, then we don't need extra parens.
        // If we find a startOfScope, skip the the end of that scope.
        var index = firstTokenIndex
        var hasInfixOperatorOrTry = false

        if formatter.tokens[firstTokenIndex] == .keyword("try") {
            hasInfixOperatorOrTry = true
        }

        while index < formatter.tokens.indices.last! {
            let token = formatter.tokens[index]

            if token.isStartOfScope, let endOfScope = formatter.endOfScope(at: index) {
                index = endOfScope
                continue
            }

            if (token.isOperator(ofType: .infix) && !token.isOperator("."))
                || token == .keyword("is") // the is keyword acts like an infix operator
            {
                hasInfixOperatorOrTry = true
                break
            }

            index += 1
        }

        if hasInfixOperatorOrTry {
            formatter.insert(.endOfScope(")"), at: lastTokenIndex + 1)
            formatter.insert(.startOfScope("("), at: firstTokenIndex)
        }

        return formatter.tokens.string
    }
}
