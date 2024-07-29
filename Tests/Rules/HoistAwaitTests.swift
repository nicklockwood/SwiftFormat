//
//  HoistAwaitTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class HoistAwaitTests: XCTestCase {
    func testHoistAwait() {
        let input = "greet(await name, await surname)"
        let output = "await greet(name, surname)"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitInsideIf() {
        let input = "if !(await isSomething()) {}"
        let output = "if await !(isSomething()) {}"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"),
                       exclude: [.redundantParens])
    }

    func testHoistAwaitInsideArgument() {
        let input = """
        array.append(contentsOf: try await asyncFunction(param1: param1))
        """
        let output = """
        await array.append(contentsOf: try asyncFunction(param1: param1))
        """
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry])
    }

    func testHoistAwaitInsideStringInterpolation() {
        let input = "\"\\(replace(regex: await something()))\""
        let output = "await \"\\(replace(regex: something()))\""
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitInsideStringInterpolation2() {
        let input = """
        "Hello \\(try await someValue())"
        """
        let output = """
        await "Hello \\(try someValue())"
        """
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry])
    }

    func testNoHoistAwaitInsideDo() {
        let input = """
        do {
            rg.box.seal(.fulfilled(await body(error)))
        }
        """
        let output = """
        do {
            await rg.box.seal(.fulfilled(body(error)))
        }
        """
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testNoHoistAwaitInsideDoThrows() {
        let input = """
        do throws(Foo) {
            rg.box.seal(.fulfilled(await body(error)))
        }
        """
        let output = """
        do throws(Foo) {
            await rg.box.seal(.fulfilled(body(error)))
        }
        """
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitInExpressionWithNoSpaces() {
        let input = "let foo=bar(contentsOf:await baz())"
        let output = "let foo=await bar(contentsOf:baz())"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.spaceAroundOperators])
    }

    func testHoistAwaitInExpressionWithExcessSpaces() {
        let input = "let foo = bar ( contentsOf: await baz() )"
        let output = "let foo = await bar ( contentsOf: baz() )"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"),
                       exclude: [.spaceAroundParens, .spaceInsideParens])
    }

    func testHoistAwaitWithReturn() {
        let input = "return .enumCase(try await service.greet())"
        let output = "return await .enumCase(try service.greet())"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry])
    }

    func testHoistDeeplyNestedAwaits() {
        let input = "let foo = (bar: (5, (await quux(), 6)), baz: (7, quux: await quux()))"
        let output = "let foo = await (bar: (5, (quux(), 6)), baz: (7, quux: quux()))"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testAwaitNotHoistedOutOfClosure() {
        let input = "let foo = { (await bar(), 5) }"
        let output = "let foo = { await (bar(), 5) }"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testAwaitNotHoistedOutOfClosureWithArguments() {
        let input = "let foo = { bar in (await baz(bar), 5) }"
        let output = "let foo = { bar in await (baz(bar), 5) }"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testAwaitNotHoistedOutOfForCondition() {
        let input = "for foo in bar(await baz()) {}"
        let output = "for foo in await bar(baz()) {}"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testAwaitNotHoistedOutOfForIndex() {
        let input = "for await foo in asyncSequence() {}"
        testFormatting(for: input, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitWithInitAssignment() {
        let input = "let variable = String(try await asyncFunction())"
        let output = "let variable = await String(try asyncFunction())"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry])
    }

    func testHoistAwaitWithAssignment() {
        let input = "let variable = (try await asyncFunction())"
        let output = "let variable = await (try asyncFunction())"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.hoistTry])
    }

    func testHoistAwaitInRedundantScopePriorToNumber() {
        let input = """
        let identifiersTypes = 1
        (try? await asyncFunction(param1: param1))
        """
        let output = """
        let identifiersTypes = 1
        await (try? asyncFunction(param1: param1))
        """
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitOnlyOne() {
        let input = "greet(name, await surname)"
        let output = "await greet(name, surname)"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitRedundantAwait() {
        let input = "await greet(await name, await surname)"
        let output = "await greet(name, surname)"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitDoesNothing() {
        let input = "await greet(name, surname)"
        testFormatting(for: input, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testNoHoistAwaitBeforeTry() {
        let input = "try foo(await bar())"
        let output = "try await foo(bar())"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testNoHoistAwaitInCapturingFunction() {
        let input = "foo(await bar)"
        testFormatting(for: input, rule: .hoistAwait,
                       options: FormatOptions(asyncCapturing: ["foo"], swiftVersion: "5.5"))
    }

    func testNoHoistSecondArgumentAwaitInCapturingFunction() {
        let input = "foo(bar, await baz)"
        testFormatting(for: input, rule: .hoistAwait,
                       options: FormatOptions(asyncCapturing: ["foo"], swiftVersion: "5.5"))
    }

    func testHoistAwaitAfterOrdinaryOperator() {
        let input = "let foo = bar + (await baz)"
        let output = "let foo = await bar + (baz)"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.redundantParens])
    }

    func testHoistAwaitAfterUnknownOperator() {
        let input = "let foo = bar ??? (await baz)"
        let output = "let foo = await bar ??? (baz)"
        testFormatting(for: input, output, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.redundantParens])
    }

    func testNoHoistAwaitAfterCapturingOperator() {
        let input = "let foo = await bar ??? (await baz)"
        testFormatting(for: input, rule: .hoistAwait,
                       options: FormatOptions(asyncCapturing: ["???"], swiftVersion: "5.5"))
    }

    func testNoHoistAwaitInMacroArgument() {
        let input = "#expect (await monitor.isAvailable == false)"
        testFormatting(for: input, rule: .hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: [.spaceAroundParens])
    }
}
