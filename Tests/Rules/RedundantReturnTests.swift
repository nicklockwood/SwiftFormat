//
//  RedundantReturnTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 3/7/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantReturnTests: XCTestCase {
    func testRemoveRedundantReturnInClosure() {
        let input = """
        foo(with: { return 5 })
        """
        let output = """
        foo(with: { 5 })
        """
        testFormatting(for: input, output, rule: .redundantReturn, exclude: [.trailingClosures])
    }

    func testRemoveRedundantReturnInClosureWithArgs() {
        let input = """
        foo(with: { foo in return foo })
        """
        let output = """
        foo(with: { foo in foo })
        """
        testFormatting(for: input, output, rule: .redundantReturn, exclude: [.trailingClosures])
    }

    func testRemoveRedundantReturnInMap() {
        let input = """
        let foo = bar.map { return 1 }
        """
        let output = """
        let foo = bar.map { 1 }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    func testNoRemoveReturnInComputedVar() {
        let input = """
        var foo: Int { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    func testRemoveReturnInComputedVar() {
        let input = """
        var foo: Int { return 5 }
        """
        let output = """
        var foo: Int { 5 }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInGet() {
        let input = """
        var foo: Int {
            get { return 5 }
            set { _foo = newValue }
        }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    func testRemoveReturnInGet() {
        let input = """
        var foo: Int {
            get { return 5 }
            set { _foo = newValue }
        }
        """
        let output = """
        var foo: Int {
            get { 5 }
            set { _foo = newValue }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInGetClosure() {
        let input = """
        let foo = get { return 5 }
        """
        let output = """
        let foo = get { 5 }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    func testRemoveReturnInVarClosure() {
        let input = """
        var foo = { return 5 }()
        """
        let output = """
        var foo = { 5 }()
        """
        testFormatting(for: input, output, rule: .redundantReturn, exclude: [.redundantClosure])
    }

    func testRemoveReturnInParenthesizedClosure() {
        let input = """
        var foo = ({ return 5 }())
        """
        let output = """
        var foo = ({ 5 }())
        """
        testFormatting(for: input, output, rule: .redundantReturn, exclude: [.redundantParens, .redundantClosure])
    }

    func testNoRemoveReturnInFunction() {
        let input = """
        func foo() -> Int { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    func testRemoveReturnInFunction() {
        let input = """
        func foo() -> Int { return 5 }
        """
        let output = """
        func foo() -> Int { 5 }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInOperatorFunction() {
        let input = """
        func + (lhs: Int, rhs: Int) -> Int { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.unusedArguments])
    }

    func testRemoveReturnInOperatorFunction() {
        let input = """
        func + (lhs: Int, rhs: Int) -> Int { return 5 }
        """
        let output = """
        func + (lhs: Int, rhs: Int) -> Int { 5 }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options,
                       exclude: [.unusedArguments])
    }

    func testNoRemoveReturnInFailableInit() {
        let input = """
        init?() { return nil }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    func testNoRemoveReturnInFailableInitWithConditional() {
        let input = """
        init?(optionalHex: String?) {
            if let optionalHex {
                self.init(hex: optionalHex)
            } else {
                return nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInFailableInitWithNestedConditional() {
        let input = """
        init?(optionalHex: String?) {
            if let optionalHex {
                self.init(hex: optionalHex)
            } else {
                switch foo {
                case .foo:
                    self.init()
                case .bar:
                    return nil
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRemoveReturnInFailableInit() {
        let input = """
        init?() { return nil }
        """
        let output = """
        init?() { nil }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInSubscript() {
        let input = """
        subscript(index: Int) -> String { return nil }
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.unusedArguments])
    }

    func testRemoveReturnInSubscript() {
        let input = """
        subscript(index: Int) -> String { return nil }
        """
        let output = """
        subscript(index: Int) -> String { nil }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options,
                       exclude: [.unusedArguments])
    }

    func testNoRemoveReturnInDoCatch() {
        let input = """
        func foo() -> Int {
            do {
                return try Bar()
            } catch {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInDoThrowsCatch() {
        let input = """
        func foo() -> Int {
            do throws(Foo) {
                return try Bar()
            } catch {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInDoCatchLet() {
        let input = """
        func foo() -> Int {
            do {
                return try Bar()
            } catch let e as Error {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInDoThrowsCatchLet() {
        let input = """
        func foo() -> Int {
            do throws(Foo) {
                return try Bar()
            } catch let e as Error {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInForIn() {
        let input = """
        for foo in bar { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.wrapLoopBodies])
    }

    func testNoRemoveReturnInForWhere() {
        let input = """
        for foo in bar where baz { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.wrapLoopBodies])
    }

    func testNoRemoveReturnInIfLetTry() {
        let input = """
        if let foo = try? bar() { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoRemoveReturnInMultiIfLetTry() {
        let input = """
        if let foo = bar, let bar = baz { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoRemoveReturnAfterMultipleAs() {
        let input = """
        if foo as? bar as? baz { return 5 }
        """
        testFormatting(for: input, rule: .redundantReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testRemoveVoidReturn() {
        let input = """
        { _ in return }
        """
        let output = """
        { _ in }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    func testNoRemoveReturnAfterKeyPath() {
        let input = """
        func foo() { if bar == #keyPath(baz) { return 5 } }
        """
        testFormatting(for: input, rule: .redundantReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoRemoveReturnAfterParentheses() {
        let input = """
        if let foo = (bar as? String) { return foo }
        """
        testFormatting(for: input, rule: .redundantReturn,
                       exclude: [.redundantParens, .wrapConditionalBodies])
    }

    func testRemoveReturnInTupleVarGetter() {
        let input = """
        var foo: (Int, Int) { return (1, 2) }
        """
        let output = """
        var foo: (Int, Int) { (1, 2) }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    func testNoRemoveReturnInIfLetWithNoSpaceAfterParen() {
        let input = """
        var foo: String? {
            if let bar = baz(){
                return bar
            } else {
                return nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options,
                       exclude: [.spaceAroundBraces, .spaceAroundParens])
    }

    func testNoRemoveReturnInIfWithUnParenthesizedClosure() {
        let input = """
        if foo { $0.bar } {
            return true
        }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    func testRemoveBlankLineWithReturn() {
        let input = """
        foo {
            return
                bar
        }
        """
        let output = """
        foo {
            bar
        }
        """
        testFormatting(for: input, output, rule: .redundantReturn,
                       exclude: [.indent])
    }

    func testRemoveRedundantReturnInFunctionWithWhereClause() {
        let input = """
        func foo<T>(_ name: String) -> T where T: Equatable {
            return name
        }
        """
        let output = """
        func foo<T>(_ name: String) -> T where T: Equatable {
            name
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn,
                       options: options)
    }

    func testRemoveRedundantReturnInSubscriptWithWhereClause() {
        let input = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            return name
        }
        """
        let output = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            name
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn,
                       options: options)
    }

    func testNoRemoveReturnFollowedByMoreCode() {
        let input = """
        var foo: Bar = {
            return foo
            let bar = baz
            return bar
        }()
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.redundantProperty])
    }

    func testNoRemoveReturnInForWhereLoop() {
        let input = """
        func foo() -> Bool {
            for bar in baz where !bar {
                return false
            }
            return true
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRedundantReturnInVoidFunction() {
        let input = """
        func foo() {
            return
        }
        """
        let output = """
        func foo() {
        }
        """
        testFormatting(for: input, output, rule: .redundantReturn,
                       exclude: [.emptyBraces])
    }

    func testRedundantReturnInVoidFunction2() {
        let input = """
        func foo() {
            print("")
            return
        }
        """
        let output = """
        func foo() {
            print("")
        }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    func testRedundantReturnInVoidFunction3() {
        let input = """
        func foo() {
            // empty
            return
        }
        """
        let output = """
        func foo() {
            // empty
        }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    func testRedundantReturnInVoidFunction4() {
        let input = """
        func foo() {
            return // empty
        }
        """
        let output = """
        func foo() {
            // empty
        }
        """
        testFormatting(for: input, output, rule: .redundantReturn)
    }

    func testNoRemoveVoidReturnInCatch() {
        let input = """
        func foo() {
            do {
                try Foo()
            } catch Feature.error {
                print("feature error")
                return
            }
            print("foo")
        }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    func testNoRemoveReturnInIfCase() {
        let input = """
        var isSessionDeinitializedError: Bool {
            if case .sessionDeinitialized = self { return true }
            return false
        }
        """
        testFormatting(for: input, rule: .redundantReturn,
                       options: FormatOptions(swiftVersion: "5.1"),
                       exclude: [.wrapConditionalBodies])
    }

    func testNoRemoveReturnInForCasewhere() {
        let input = """
        for case let .identifier(name) in formatter.tokens[startIndex ..< endIndex]
            where names.contains(name)
        {
            return true
        }
        """
        testFormatting(for: input, rule: .redundantReturn,
                       options: FormatOptions(swiftVersion: "5.1"))
    }

    func testNoRemoveRequiredReturnInFunctionInsideClosure() {
        let input = """
        foo {
            func bar() -> Bar {
                let bar = Bar()
                return bar
            }
        }
        """
        testFormatting(for: input, rule: .redundantReturn,
                       options: FormatOptions(swiftVersion: "5.1"), exclude: [.redundantProperty])
    }

    func testNoRemoveRequiredReturnInIfClosure() {
        let input = """
        func findButton() -> Button? {
            let btns = [top, content, bottom]
            if let btn = btns.first { !$0.isHidden && $0.alpha > 0.01 } {
                return btn
            }
            return btns.first
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testNoRemoveRequiredReturnInIfClosure2() {
        let input = """
        func findButton() -> Button? {
            let btns = [top, content, bottom]
            if let foo, let btn = btns.first { !$0.isHidden && $0.alpha > 0.01 } {
                return btn
            }
            return btns.first
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRemoveRedundantReturnInIfClosure() {
        let input = """
        func findButton() -> Button? {
            let btns = [top, content, bottom]
            if let btn = btns.first { return !$0.isHidden && $0.alpha > 0.01 } {
                print("hello")
            }
            return btns.first
        }
        """
        let output = """
        func findButton() -> Button? {
            let btns = [top, content, bottom]
            if let btn = btns.first { !$0.isHidden && $0.alpha > 0.01 } {
                print("hello")
            }
            return btns.first
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    func testDisableNextRedundantReturn() {
        let input = """
        func foo() -> Foo {
            // swiftformat:disable:next redundantReturn
            return Foo()
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRedundantIfStatementReturnSwift5_8() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition {
                return "foo"
            } else {
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: .redundantReturn,
                       options: options)
    }

    func testRedundantIfStatementWithClosureCondition() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition, { true }(), { false }() {
                return "foo"
            } else {
                return "bar"
            }
        }
        """

        let output = """
        func foo(condition: Bool) -> String {
            if condition, { true }(), { false }() {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output], rules: [.redundantReturn, .conditionalAssignment], options: options, exclude: [.redundantClosure])
    }

    func testNonRedundantIfStatementReturnSwift5_9() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition {
                return "foo"
            } else if !condition {
                return "bar"
            }
            return "baaz"
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRedundantIfStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition {
                return "foo"
            } else if otherCondition {
                if anotherCondition {
                    return "bar"
                } else {
                    return "baaz"
                }
            } else {
                return "quux"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            if condition {
                "foo"
            } else if otherCondition {
                if anotherCondition {
                    "bar"
                } else {
                    "baaz"
                }
            } else {
                "quux"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testNoRemoveRedundantIfStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            if condition {
                return "foo"
            } else if otherCondition {
                if anotherCondition {
                    return "bar"
                } else {
                    return "baaz"
                }
            } else {
                return "quux"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options,
                       exclude: [.conditionalAssignment])
    }

    func testRedundantIfStatementReturnInClosure() {
        let input = """
        let closure: (Bool) -> String = { condition in
            if condition {
                return "foo"
            } else {
                return "bar"
            }
        }
        """
        let output = """
        let closure: (Bool) -> String = { condition in
            if condition {
                "foo"
            } else {
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testNoRemoveRedundantIfStatementReturnInClosure() {
        let input = """
        let closure: (Bool) -> String = { condition in
            if condition {
                return "foo"
            } else {
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options,
                       exclude: [.conditionalAssignment])
    }

    func testNoRemoveReturnInConsecutiveIfStatements() {
        let input = """
        func foo() -> String? {
            if bar {
                return nil
            }
            if baz {
                return "baz"
            } else {
                return "quux"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRedundantIfStatementReturnInRedundantClosure() {
        let input = """
        let value = {
            if condition {
                return "foo"
            } else {
                return "bar"
            }
        }()
        """
        let output = """
        let value = if condition {
            "foo"
        } else {
            "bar"
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment,
                               .redundantClosure, .indent],
                       options: options, exclude: [.wrapMultilineConditionalAssignment])
    }

    func testRedundantSwitchStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            case false:
                return "bar"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                "foo"
            case false:
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testNoRemoveRedundantSwitchStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            case false:
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options,
                       exclude: [.conditionalAssignment])
    }

    func testNonRedundantSwitchStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            case false:
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRedundantSwitchStatementReturnInFunctionWithDefault() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            default:
                return "bar"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                "foo"
            default:
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testRedundantSwitchStatementReturnInFunctionWithComment() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                // foo
                return "foo"

            default:
                /* bar */
                return "bar"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                // foo
                "foo"

            default:
                /* bar */
                "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testNonRedundantSwitchStatementReturnInFunctionWithDefault() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                return "foo"
            default:
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.8")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testNonRedundantSwitchStatementReturnInFunctionWithFallthrough() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                fallthrough
            case false:
                return "bar"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testVoidReturnNotStrippedFromSwitch() {
        let input = """
        func foo(condition: Bool) {
            switch condition {
            case true:
                print("foo")
            case false:
                return
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRedundantNestedSwitchStatementReturnInFunction() {
        let input = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                switch condition {
                case true:
                    return "foo"
                case false:
                    if condition {
                        return "bar"
                    } else {
                        return "baaz"
                    }
                }

            case false:
                return "quux"
            }
        }
        """
        let output = """
        func foo(condition: Bool) -> String {
            switch condition {
            case true:
                switch condition {
                case true:
                    "foo"
                case false:
                    if condition {
                        "bar"
                    } else {
                        "baaz"
                    }
                }

            case false:
                "quux"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testRedundantSwitchStatementReturnWithAssociatedValueMatchingInFunction() {
        let input = """
        func test(_ value: SomeEnum) -> String {
            switch value {
            case let .first(str):
                return "first \\(str)"
            case .second("str"):
                return "second"
            default:
                return "default"
            }
        }
        """
        let output = """
        func test(_ value: SomeEnum) -> String {
            switch value {
            case let .first(str):
                "first \\(str)"
            case .second("str"):
                "second"
            default:
                "default"
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testRedundantReturnDoesntFailToTerminateOnLongSwitch() {
        let input = """
        func test(_ value: SomeEnum) -> String {
            switch value {
            case .one:
                return ""
            case .two:
                return ""
            case .three:
                return ""
            case .four:
                return ""
            case .five:
                return ""
            case .six:
                return ""
            case .seven:
                return ""
            case .eight:
                return ""
            case .nine:
                return ""
            case .ten:
                return ""
            case .eleven:
                return ""
            case .twelve:
                return ""
            case .thirteen:
                return ""
            case .fourteen:
                return ""
            case .fifteen:
                return ""
            case .sixteen:
                return ""
            case .seventeen:
                return ""
            case .eighteen:
                return ""
            case .nineteen:
                return ""
            }
        }
        """
        let output = """
        func test(_ value: SomeEnum) -> String {
            switch value {
            case .one:
                ""
            case .two:
                ""
            case .three:
                ""
            case .four:
                ""
            case .five:
                ""
            case .six:
                ""
            case .seven:
                ""
            case .eight:
                ""
            case .nine:
                ""
            case .ten:
                ""
            case .eleven:
                ""
            case .twelve:
                ""
            case .thirteen:
                ""
            case .fourteen:
                ""
            case .fifteen:
                ""
            case .sixteen:
                ""
            case .seventeen:
                ""
            case .eighteen:
                ""
            case .nineteen:
                ""
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testNoRemoveDebugReturnFollowedBySwitch() {
        let input = """
        func swiftFormatBug() -> Foo {
            return .foo

            switch state {
            case .foo, .bar:
                return state
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options,
                       exclude: [.wrapSwitchCases, .sortSwitchCases])
    }

    func testDoesntRemoveReturnFromIfExpressionConditionalCastInSwift5_9() {
        // The following code doesn't compile in Swift 5.9 due to this issue:
        // https://github.com/apple/swift/issues/68764
        //
        //  var result: String {
        //    if condition {
        //      foo as? String
        //    } else {
        //      "bar"
        //    }
        //  }
        //
        let input = """
        var result1: String {
            if condition {
                return foo as? String
            } else {
                return "bar"
            }
        }

        var result2: String {
            switch condition {
            case true:
                return foo as? String
            case false:
                return "bar"
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options)
    }

    func testRemovseReturnFromIfExpressionNestedConditionalCastInSwift5_9() {
        let input = """
        var result1: String {
            if condition {
                return method(foo as? String)
            } else {
                return "bar"
            }
        }
        """

        let output = """
        var result1: String {
            if condition {
                method(foo as? String)
            } else {
                "bar"
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testRemovesReturnFromIfExpressionConditionalCastInSwift5_10() {
        let input = """
        var result: String {
            if condition {
                return foo as? String
            } else {
                return "bar"
            }
        }
        """

        let output = """
        var result: String {
            if condition {
                foo as? String
            } else {
                "bar"
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testRemovesRedundantReturnBeforeIfExpression() {
        let input = """
        func foo() -> Foo {
            return if condition {
                Foo.foo()
            } else {
                Foo.bar()
            }
        }
        """

        let output = """
        func foo() -> Foo {
            if condition {
                Foo.foo()
            } else {
                Foo.bar()
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    func testRemovesRedundantReturnBeforeSwitchExpression() {
        let input = """
        func foo() -> Foo {
            return switch condition {
            case true:
                Foo.foo()
            case false:
                Foo.bar()
            }
        }
        """

        let output = """
        func foo() -> Foo {
            switch condition {
            case true:
                Foo.foo()
            case false:
                Foo.bar()
            }
        }
        """

        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantReturn, options: options)
    }

    func testRedundantSwitchStatementReturnInFunctionWithMultipleWhereClauses() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1554
        let input = """
        func foo(cases: FooCases, count: Int) -> String? {
            switch cases {
            case .fooCase1 where count == 0:
                return "foo"
            case .fooCase2 where count < 100,
                 .fooCase3 where count < 100,
                 .fooCase4:
                return "bar"
            default:
                return nil
            }
        }
        """
        let output = """
        func foo(cases: FooCases, count: Int) -> String? {
            switch cases {
            case .fooCase1 where count == 0:
                "foo"
            case .fooCase2 where count < 100,
                 .fooCase3 where count < 100,
                 .fooCase4:
                "bar"
            default:
                nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testRedundantSwitchStatementReturnInFunctionWithSingleWhereClause() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1554
        let input = """
        func anotherFoo(cases: FooCases, count: Int) -> String? {
            switch cases {
            case .fooCase1 where count == 0:
                return "foo"
            case .fooCase2 where count < 100,
                 .fooCase4:
                return "bar"
            default:
                return nil
            }
        }
        """
        let output = """
        func anotherFoo(cases: FooCases, count: Int) -> String? {
            switch cases {
            case .fooCase1 where count == 0:
                "foo"
            case .fooCase2 where count < 100,
                 .fooCase4:
                "bar"
            default:
                nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, [output],
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testReturnNotRemovedFromSwitchBodyWithOpaqueReturnType() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1819
        let input = """
        extension View {
            func foo() -> some View {
                if #available(iOS 16.0, *) {
                    return self.scrollIndicators(.hidden)
                } else {
                    return self
                }
            }

            func bar() -> (some View) {
                if #available(iOS 16.0, *) {
                    return self.scrollIndicators(.hidden)
                } else {
                    return self
                }
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input,
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options, exclude: [.redundantSelf])
    }

    func testReturnNotRemovedFromCatchWhere() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1843
        let input = """
        func decodeError(from data: Data, urlResponse: HTTPURLResponse) -> Error {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch where urlResponse.statusCode >= 400 {
                return CustomError() // <- return removed here, introducing a compile time error.
            } catch {
                return error
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input,
                       rules: [.redundantReturn, .conditionalAssignment],
                       options: options)
    }

    func testForLoopReturnAfterSwitch() {
        let input = """
        func foo() -> Bool {
            switch bar {
            case .baz:
                break
            }

            for i in quux where quux[i].foo {
                return i > 0
            }

            return false
        }
        """
        testFormatting(for: input, rule: .redundantReturn)
    }

    func testIssue1974() {
        let input = """
        func selectedRow() -> Int? {
            var selectedItem: NSManagedObjectID?

            guard let selection = selectedFilterSourceBlock?() as? UserDataSourceSelection else {
                return nil
            }

            switch selection {
            case .user(let managedObjectID):
                selectedItem = managedObjectID
            case .noValue:
                return nil
            }

            if includeEveryone && selectedItem == nil {
                return 0
            }

            for (i, item) in _items.enumerated() where item.objectID == selectedItem {
                return i >= _limit ? _limit : i + (includeEveryone ? 1 : 0)
            }

            return nil
        }
        """
        testFormatting(for: input, rule: .redundantReturn, exclude: [.hoistPatternLet, .andOperator])
    }

    func testIssue2263() {
        let input = """
        func firstNonNilValue<O>() async -> O where V == O? {
            var it = values.makeAsyncIterator()
            repeat {
                if let value = await it.next(), let value {
                    return value
                }
            }
            while true
        }
        """
        let options = FormatOptions(swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantReturn, options: options, exclude: [.elseOnSameLine])
    }
}
