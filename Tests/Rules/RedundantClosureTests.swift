//
//  RedundantClosureTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 9/28/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantClosureTests: XCTestCase {
    func testClosureAroundConditionalAssignmentNotRedundantForExplicitReturn() {
        let input = """
        let myEnum = MyEnum.a
        let test: Int = {
            switch myEnum {
            case .a:
                return 0
            case .b:
                return 1
            }
        }()
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options,
                       exclude: [.redundantReturn, .propertyTypes])
    }

    // MARK: redundantClosure

    func testRemoveRedundantClosureInSingleLinePropertyDeclaration() {
        let input = """
        let foo = { "Foo" }()
        let bar = { "Bar" }()

        let baaz = { "baaz" }()

        let quux = { "quux" }()
        """

        let output = """
        let foo = "Foo"
        let bar = "Bar"

        let baaz = "baaz"

        let quux = "quux"
        """

        testFormatting(for: input, output, rule: .redundantClosure)
    }

    func testRedundantClosureWithExplicitReturn() {
        let input = """
        let foo = { return "Foo" }()

        let bar = {
            return if Bool.random() {
                "Bar"
            } else {
                "Baaz"
            }
        }()
        """

        let output = """
        let foo = "Foo"

        let bar = if Bool.random() {
                "Bar"
            } else {
                "Baaz"
            }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output], rules: [.redundantReturn, .redundantClosure],
                       options: options, exclude: [.indent, .wrapMultilineConditionalAssignment])
    }

    func testRedundantClosureWithExplicitReturn2() {
        let input = """
        func foo() -> String {
            methodCall()
            return { return "Foo" }()
        }

        func bar() -> String {
            methodCall()
            return { "Bar" }()
        }

        func baaz() -> String {
            { return "Baaz" }()
        }
        """

        let output = """
        func foo() -> String {
            methodCall()
            return "Foo"
        }

        func bar() -> String {
            methodCall()
            return "Bar"
        }

        func baaz() -> String {
            "Baaz"
        }
        """

        testFormatting(for: input, [output], rules: [.redundantReturn, .redundantClosure])
    }

    func testKeepsClosureThatIsNotCalled() {
        let input = """
        let foo = { "Foo" }
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testKeepsEmptyClosures() {
        let input = """
        let foo = {}()
        let bar = { /* comment */ }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testRemoveRedundantClosureInMultiLinePropertyDeclaration() {
        let input = """
        lazy var bar = {
            Bar()
        }()
        """

        let output = """
        lazy var bar = Bar()
        """

        testFormatting(for: input, output, rule: .redundantClosure, exclude: [.propertyTypes])
    }

    func testRemoveRedundantClosureInMultiLinePropertyDeclarationWithString() {
        let input = #"""
        lazy var bar = {
            """
            Multiline string literal
            """
        }()
        """#

        let output = #"""
        lazy var bar = """
        Multiline string literal
        """
        """#

        testFormatting(for: input, [output], rules: [.redundantClosure, .indent])
    }

    func testRemoveRedundantClosureInMultiLinePropertyDeclarationInClass() {
        let input = """
        class Foo {
            lazy var bar = {
                return Bar();
            }()
        }
        """

        let output = """
        class Foo {
            lazy var bar = Bar()
        }
        """

        testFormatting(for: input, [output], rules: [.redundantReturn, .redundantClosure,
                                                     .semicolons], exclude: [.propertyTypes])
    }

    func testRemoveRedundantClosureInWrappedPropertyDeclaration_beforeFirst() {
        let input = """
        lazy var baaz = {
            Baaz(
                foo: foo,
                bar: bar)
        }()
        """

        let output = """
        lazy var baaz = Baaz(
            foo: foo,
            bar: bar)
        """

        let options = FormatOptions(wrapArguments: .beforeFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, [output],
                       rules: [.redundantClosure, .wrapArguments],
                       options: options, exclude: [.propertyTypes])
    }

    func testRemoveRedundantClosureInWrappedPropertyDeclaration_afterFirst() {
        let input = """
        lazy var baaz = {
            Baaz(foo: foo,
                 bar: bar)
        }()
        """

        let output = """
        lazy var baaz = Baaz(foo: foo,
                             bar: bar)
        """

        let options = FormatOptions(wrapArguments: .afterFirst, closingParenPosition: .sameLine)
        testFormatting(for: input, [output],
                       rules: [.redundantClosure, .wrapArguments],
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantClosureKeepsMultiStatementClosureThatSetsProperty() {
        let input = """
        lazy var baaz = {
            let baaz = Baaz(foo: foo, bar: bar)
            baaz.foo = foo2
            return baaz
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testRedundantClosureKeepsMultiStatementClosureWithMultipleStatements() {
        let input = """
        lazy var quux = {
            print("hello world")
            return "quux"
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testRedundantClosureKeepsClosureWithInToken() {
        let input = """
        lazy var double = { () -> Double in
            100
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testRedundantClosureKeepsMultiStatementClosureOnSameLine() {
        let input = """
        lazy var baaz = {
            print("Foo"); return baaz
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testRedundantClosureRemovesComplexMultilineClosure() {
        let input = """
        lazy var closureInClosure = {
            {
              print("Foo")
              print("Bar"); return baaz
            }
        }()
        """

        let output = """
        lazy var closureInClosure = {
            print("Foo")
            print("Bar"); return baaz
        }
        """

        testFormatting(for: input, [output], rules: [.redundantClosure, .indent])
    }

    func testKeepsClosureWithIfStatement() {
        let input = """
        lazy var baaz = {
            if let foo == foo {
                return foo
            } else {
                return Foo()
            }
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testKeepsClosureWithIfStatementOnSingleLine() {
        let input = """
        lazy var baaz = {
            if let foo == foo { return foo } else { return Foo() }
        }()
        """

        testFormatting(for: input, rule: .redundantClosure,
                       exclude: [.wrapConditionalBodies])
    }

    func testRemovesClosureWithIfStatementInsideOtherClosure() {
        let input = """
        lazy var baaz = {
            {
                if let foo == foo {
                    return foo
                } else {
                    return Foo()
                }
            }
        }()
        """

        let output = """
        lazy var baaz = {
            if let foo == foo {
                return foo
            } else {
                return Foo()
            }
        }
        """

        testFormatting(for: input, [output],
                       rules: [.redundantClosure, .indent])
    }

    func testKeepsClosureWithSwitchStatement() {
        let input = """
        lazy var baaz = {
            switch foo {
            case let .some(foo):
                return foo:
            case .none:
                return Foo()
            }
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testKeepsClosureWithIfDirective() {
        let input = """
        lazy var baaz = {
            #if DEBUG
                return DebugFoo()
            #else
                return Foo()
            #endif
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testKeepsClosureThatCallsMethodThatReturnsNever() {
        let input = """
        lazy var foo: String = { fatalError("no default value has been set") }()
        lazy var bar: String = { return preconditionFailure("no default value has been set") }()
        """

        testFormatting(for: input, rule: .redundantClosure,
                       exclude: [.redundantReturn])
    }

    func testRemovesClosureThatHasNestedFatalError() {
        let input = """
        lazy var foo = {
            Foo(handle: { fatalError() })
        }()
        """

        let output = """
        lazy var foo = Foo(handle: { fatalError() })
        """

        testFormatting(for: input, output, rule: .redundantClosure, exclude: [.propertyTypes])
    }

    func testPreservesClosureWithMultipleVoidMethodCalls() {
        let input = """
        lazy var triggerSomething: Void = {
            logger.trace("log some stuff before Triggering")
            TriggerClass.triggerTheThing()
            logger.trace("Finished triggering the thing")
        }()
        """

        testFormatting(for: input, rule: .redundantClosure)
    }

    func testRemovesClosureWithMultipleNestedVoidMethodCalls() {
        let input = """
        lazy var foo: Foo = {
            Foo(handle: {
                logger.trace("log some stuff before Triggering")
                TriggerClass.triggerTheThing()
                logger.trace("Finished triggering the thing")
            })
        }()
        """

        let output = """
        lazy var foo: Foo = Foo(handle: {
            logger.trace("log some stuff before Triggering")
            TriggerClass.triggerTheThing()
            logger.trace("Finished triggering the thing")
        })
        """

        testFormatting(for: input, [output], rules: [.redundantClosure, .indent], exclude: [.redundantType])
    }

    func testKeepsClosureThatThrowsError() {
        let input = "let foo = try bar ?? { throw NSError() }()"
        testFormatting(for: input, rule: .redundantClosure)
    }

    func testKeepsDiscardableResultClosure() {
        let input = """
        @discardableResult
        func discardableResult() -> String { "hello world" }

        /// We can't remove this closure, since the method called inline
        /// would return a String instead.
        let void: Void = { discardableResult() }()
        """
        testFormatting(for: input, rule: .redundantClosure)
    }

    func testKeepsDiscardableResultClosure2() {
        let input = """
        @discardableResult
        func discardableResult() -> String { "hello world" }

        /// We can't remove this closure, since the method called inline
        /// would return a String instead.
        let void: () = { discardableResult() }()
        """
        testFormatting(for: input, rule: .redundantClosure)
    }

    func testRedundantClosureDoesntLeaveStrayTry() {
        let input = """
        let user2: User? = try {
            if let data2 = defaults.data(forKey: defaultsKey) {
                return try PropertyListDecoder().decode(User.self, from: data2)
            } else {
                return nil
            }
        }()
        """
        let output = """
        let user2: User? = if let data2 = defaults.data(forKey: defaultsKey) {
                try PropertyListDecoder().decode(User.self, from: data2)
            } else {
                nil
            }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment,
                               .redundantClosure],
                       options: options, exclude: [.indent, .wrapMultilineConditionalAssignment])
    }

    func testRedundantClosureDoesntLeaveStrayTryAwait() {
        let input = """
        let user2: User? = try await {
            if let data2 = defaults.data(forKey: defaultsKey) {
                return try await PropertyListDecoder().decode(User.self, from: data2)
            } else {
                return nil
            }
        }()
        """
        let output = """
        let user2: User? = if let data2 = defaults.data(forKey: defaultsKey) {
                try await PropertyListDecoder().decode(User.self, from: data2)
            } else {
                nil
            }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment,
                               .redundantClosure],
                       options: options, exclude: [.indent, .wrapMultilineConditionalAssignment])
    }

    func testRedundantClosureDoesntLeaveInvalidSwitchExpressionInOperatorChain() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes: Int {
                {
                    switch self {
                    case .uint8: UInt8.bitWidth
                    case .uint16: UInt16.bitWidth
                    }
                }() / 8
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testRedundantClosureDoesntLeaveInvalidIfExpressionInOperatorChain() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes: Int {
                {
                    if self == .uint8 {
                        UInt8.bitWidth
                    } else {
                        UInt16.bitWidth
                    }
                }() / 8
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testRedundantClosureDoesntLeaveInvalidIfExpressionInOperatorChain2() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes: Int {
                8 / {
                    if self == .uint8 {
                        UInt8.bitWidth
                    } else {
                        UInt16.bitWidth
                    }
                }()
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testRedundantClosureDoesntLeaveInvalidIfExpressionInOperatorChain3() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes = 8 / {
                if self == .uint8 {
                    UInt8.bitWidth
                } else {
                    UInt16.bitWidth
                }
            }()
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testRedundantClosureDoesRemoveRedundantIfStatementClosureInAssignmentPosition() {
        let input = """
        private enum Format {
            case uint8
            case uint16

            var bytes = {
                if self == .uint8 {
                    UInt8.bitWidth
                } else {
                    UInt16.bitWidth
                }
            }()
        }
        """

        let output = """
        private enum Format {
            case uint8
            case uint16

            var bytes = if self == .uint8 {
                    UInt8.bitWidth
                } else {
                    UInt16.bitWidth
                }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantClosure, options: options, exclude: [.indent, .wrapMultilineConditionalAssignment])
    }

    func testRedundantClosureDoesntLeaveInvalidSwitchExpressionInArray() {
        let input = """
        private func constraint() -> [Int] {
            [
                1,
                2,
                {
                    if Bool.random() {
                        3
                    } else {
                        4
                    }
                }(),
            ]
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testRedundantClosureRemovesClosureAsReturnTryStatement() {
        let input = """
        func method() -> Int {
            return {
              return try! if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
            }()
        }
        """

        let output = """
        func method() -> Int {
            return try! if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantClosure, options: options, exclude: [.redundantReturn, .indent])
    }

    func testRedundantClosureRemovesClosureAsReturnTryStatement2() {
        let input = """
        func method() throws -> Int {
            return try {
              return try if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
            }()
        }
        """

        let output = """
        func method() throws -> Int {
            return try if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantClosure, options: options, exclude: [.redundantReturn, .indent])
    }

    func testRedundantClosureRemovesClosureAsReturnTryStatement3() {
        let input = """
        func method() async throws -> Int {
            return try await {
              return try await if Bool.random() {
                  randomAsyncThrows()
              } else {
                  randomAsyncThrows()
              }
            }()
        }
        """

        let output = """
        func method() async throws -> Int {
            return try await if Bool.random() {
                  randomAsyncThrows()
              } else {
                  randomAsyncThrows()
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantClosure, options: options, exclude: [.redundantReturn, .indent])
    }

    func testRedundantClosureRemovesClosureAsReturnTryStatement4() {
        let input = """
        func method() -> Int {
            return {
              return try! if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
            }()
        }
        """

        let output = """
        func method() -> Int {
            return try! if Bool.random() {
                  randomThrows()
              } else {
                  randomThrows()
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantClosure, options: options, exclude: [.redundantReturn, .indent])
    }

    func testRedundantClosureRemovesClosureAsReturnStatement() {
        let input = """
        func method() -> Int {
            return {
              return if Bool.random() {
                  42
              } else {
                  43
              }
            }()
        }
        """

        let output = """
        func method() -> Int {
            return if Bool.random() {
                  42
              } else {
                  43
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output], rules: [.redundantClosure],
                       options: options, exclude: [.redundantReturn, .indent])
    }

    func testRedundantClosureRemovesClosureAsImplicitReturnStatement() {
        let input = """
        func method() -> Int {
            {
              if Bool.random() {
                  42
              } else {
                  43
              }
            }()
        }
        """

        let output = """
        func method() -> Int {
            if Bool.random() {
                  42
              } else {
                  43
              }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantClosure, options: options, exclude: [.indent])
    }

    func testClosureNotRemovedAroundIfExpressionInGuard() {
        let input = """
        guard let foo = {
            if condition {
                bar()
            }
        }() else {
            return
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testClosureNotRemovedInMethodCall() {
        let input = """
        XCTAssert({
            if foo {
                bar
            } else {
                baaz
            }
        }())
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testClosureNotRemovedInMethodCall2() {
        let input = """
        method("foo", {
            if foo {
                bar
            } else {
                baaz
            }
        }())
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testClosureNotRemovedInMethodCall3() {
        let input = """
        XCTAssert({
            if foo {
                bar
            } else {
                baaz
            }
        }(), "message")
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testClosureNotRemovedInMethodCall4() {
        let input = """
        method(
            "foo",
            {
                if foo {
                    bar
                } else {
                    baaz
                }
            }(),
            "bar"
        )
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testDoesntRemoveClosureWithIfExpressionConditionalCastInSwift5_9() {
        // The following code doesn't compile in Swift 5.9 due to this issue:
        // https://github.com/apple/swift/issues/68764
        //
        //  let result = if condition {
        //    foo as? String
        //  } else {
        //    "bar"
        //  }
        //
        let input = """
        let result1: String? = {
            if condition {
                return foo as? String
            } else {
                return "bar"
            }
        }()

        let result1: String? = {
            switch condition {
            case true:
                return foo as! String
            case false:
                return "bar"
            }
        }()
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantClosure, options: options)
    }

    func testDoesRemoveClosureWithIfExpressionConditionalCastInSwift5_10() {
        let input = """
        let result1: String? = {
            if condition {
                foo as? String
            } else {
                "bar"
            }
        }()

        let result2: String? = {
            switch condition {
            case true:
                foo as? String
            case false:
                "bar"
            }
        }()
        """

        let output = """
        let result1: String? = if condition {
                foo as? String
            } else {
                "bar"
            }

        let result2: String? = switch condition {
            case true:
                foo as? String
            case false:
                "bar"
            }
        """

        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(for: input, output, rule: .redundantClosure, options: options, exclude: [.indent, .wrapMultilineConditionalAssignment])
    }

    func testRedundantClosureDoesntBreakBuildWithRedundantReturnRuleDisabled() {
        let input = """
        enum MyEnum {
            case a
            case b
        }
        let myEnum = MyEnum.a
        let test: Int = {
            return 0
        }()
        """

        let output = """
        enum MyEnum {
            case a
            case b
        }
        let myEnum = MyEnum.a
        let test: Int = 0
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantClosure, options: options,
                       exclude: [.redundantReturn, .blankLinesBetweenScopes, .propertyTypes])
    }

    func testRedundantClosureWithSwitchExpressionDoesntBreakBuildWithRedundantReturnRuleDisabled() {
        // From https://github.com/nicklockwood/SwiftFormat/issues/1565
        let input = """
        enum MyEnum {
            case a
            case b
        }
        let myEnum = MyEnum.a
        let test: Int = {
            switch myEnum {
            case .a:
                return 0
            case .b:
                return 1
            }
        }()
        """

        let output = """
        enum MyEnum {
            case a
            case b
        }
        let myEnum = MyEnum.a
        let test: Int = switch myEnum {
            case .a:
                0
            case .b:
                1
            }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment,
                               .redundantClosure],
                       options: options,
                       exclude: [.indent, .blankLinesBetweenScopes, .wrapMultilineConditionalAssignment,
                                 .propertyTypes])
    }

    func testRemovesRedundantClosureWithGenericExistentialTypes() {
        let input = """
        let foo: Foo<Bar> = { DefaultFoo<Bar>() }()
        let foo: any Foo = { DefaultFoo() }()
        let foo: any Foo<Bar> = { DefaultFoo<Bar>() }()
        """

        let output = """
        let foo: Foo<Bar> = DefaultFoo<Bar>()
        let foo: any Foo = DefaultFoo()
        let foo: any Foo<Bar> = DefaultFoo<Bar>()
        """

        testFormatting(for: input, output, rule: .redundantClosure)
    }
}
