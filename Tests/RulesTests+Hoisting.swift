//
//  RulesTests+Hoisting.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 25/03/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class HoistingTests: RulesTests {
    // MARK: - hoistTry

    func testHoistTry() {
        let input = "greet(try name(), try surname())"
        let output = "try greet(name(), surname())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryWithOptionalTry() {
        let input = "greet(try name(), try? surname())"
        let output = "try greet(name(), try? surname())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryInsideStringInterpolation() {
        let input = "\"\\(replace(regex: try something()))\""
        let output = "try \"\\(replace(regex: something()))\""
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryInsideArgument() {
        let input = """
        array.append(contentsOf: try await asyncFunction(param1: param1))
        """
        let output = """
        try array.append(contentsOf: await asyncFunction(param1: param1))
        """
        testFormatting(for: input, output, rule: FormatRules.hoistTry, exclude: ["hoistAwait"])
    }

    func testNoHoistTryInsideXCTAssert() {
        let input = "XCTAssertFalse(try foo())"
        testFormatting(for: input, rule: FormatRules.hoistTry)
    }

    func testNoMergeTrysInsideXCTAssert() {
        let input = "XCTAssertEqual(try foo(), try bar())"
        testFormatting(for: input, rule: FormatRules.hoistTry)
    }

    func testNoHoistTryInsideDo() {
        let input = "do { rg.box.seal(.fulfilled(try body(error))) }"
        let output = "do { try rg.box.seal(.fulfilled(body(error))) }"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testNoHoistTryInsideMultilineDo() {
        let input = """
        do {
            rg.box.seal(.fulfilled(try body(error)))
        }
        """
        let output = """
        do {
            try rg.box.seal(.fulfilled(body(error)))
        }
        """
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistedTryPlacedBeforeAwait() {
        let input = "let foo = await bar(contentsOf: try baz())"
        let output = "let foo = try await bar(contentsOf: baz())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryInExpressionWithNoSpaces() {
        let input = "let foo=bar(contentsOf:try baz())"
        let output = "let foo=try bar(contentsOf:baz())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry,
                       exclude: ["spaceAroundOperators"])
    }

    func testHoistTryInExpressionWithExcessSpaces() {
        let input = "let foo = bar ( contentsOf: try baz() )"
        let output = "let foo = try bar ( contentsOf: baz() )"
        testFormatting(for: input, output, rule: FormatRules.hoistTry,
                       exclude: ["spaceAroundParens", "spaceInsideParens"])
    }

    func testHoistTryWithReturn() {
        let input = "return .enumCase(try await service.greet())"
        let output = "return try .enumCase(await service.greet())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry,
                       exclude: ["hoistAwait"])
    }

    func testHoistDeeplyNestedTrys() {
        let input = "let foo = (bar: (5, (try quux(), 6)), baz: (7, quux: try quux()))"
        let output = "let foo = try (bar: (5, (quux(), 6)), baz: (7, quux: quux()))"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testTryNotHoistedOutOfClosure() {
        let input = "let foo = { (try bar(), 5) }"
        let output = "let foo = { try (bar(), 5) }"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testTryNotHoistedOutOfClosureWithArguments() {
        let input = "let foo = { bar in (try baz(bar), 5) }"
        let output = "let foo = { bar in try (baz(bar), 5) }"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testTryNotHoistedOutOfForCondition() {
        let input = "for foo in bar(try baz()) {}"
        let output = "for foo in try bar(baz()) {}"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryWithInitAssignment() {
        let input = "let variable = String(try await asyncFunction())"
        let output = "let variable = try String(await asyncFunction())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry,
                       exclude: ["hoistAwait"])
    }

    func testHoistTryWithAssignment() {
        let input = "let variable = (try await asyncFunction())"
        let output = "let variable = try (await asyncFunction())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry,
                       exclude: ["hoistAwait"])
    }

    func testHoistTryOnlyOne() {
        let input = "greet(name, try surname())"
        let output = "try greet(name, surname())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryRedundantTry() {
        let input = "try greet(try name(), try surname())"
        let output = "try greet(name(), surname())"
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryWithAwaitOnDifferentStatement() {
        let input = """
        let asyncVariable = try await performSomething()
        return Foo(param1: try param1())
        """
        let output = """
        let asyncVariable = try await performSomething()
        return try Foo(param1: param1())
        """
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryDoubleParens() {
        let input = """
        array.append((value: try compute()))
        """
        let output = """
        try array.append((value: compute()))
        """
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistTryDoesNothing() {
        let input = "try greet(name, surname)"
        testFormatting(for: input, rule: FormatRules.hoistTry)
    }

    func testHoistOptionalTryDoesNothing() {
        let input = "try? greet(name, surname)"
        testFormatting(for: input, rule: FormatRules.hoistTry)
    }

    func testHoistedTryOnLineBeginningWithInfixDot() {
        let input = """
        let foo = bar()
            .baz(try quux())
        """
        let output = """
        let foo = try bar()
            .baz(quux())
        """
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistedTryOnLineBeginningWithInfixPlus() {
        let input = """
        let foo = bar()
            + baz(try quux())
        """
        let output = """
        let foo = try bar()
            + baz(quux())
        """
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testHoistedTryOnLineBeginningWithPrefixOperator() {
        let input = """
        foo()
        !bar(try quux())
        """
        let output = """
        foo()
        try !bar(quux())
        """
        testFormatting(for: input, output, rule: FormatRules.hoistTry)
    }

    func testNoHoistTryInCapturingFunction() {
        let input = "foo(try bar)"
        testFormatting(for: input, rule: FormatRules.hoistAwait,
                       options: FormatOptions(throwCapturing: ["foo"]))
    }

    func testNoHoistSecondArgumentTryInCapturingFunction() {
        let input = "foo(bar, try baz)"
        testFormatting(for: input, rule: FormatRules.hoistAwait,
                       options: FormatOptions(throwCapturing: ["foo"]))
    }

    // MARK: - hoistAwait

    func testHoistAwait() {
        let input = "greet(await name, await surname)"
        let output = "await greet(name, surname)"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitInsideIf() {
        let input = "if !(await isSomething()) {}"
        let output = "if await !(isSomething()) {}"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"),
                       exclude: ["redundantParens"])
    }

    func testHoistAwaitInsideArgument() {
        let input = """
        array.append(contentsOf: try await asyncFunction(param1: param1))
        """
        let output = """
        await array.append(contentsOf: try asyncFunction(param1: param1))
        """
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: ["hoistTry"])
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
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitInExpressionWithNoSpaces() {
        let input = "let foo=bar(contentsOf:await baz())"
        let output = "let foo=await bar(contentsOf:baz())"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: ["spaceAroundOperators"])
    }

    func testHoistAwaitInExpressionWithExcessSpaces() {
        let input = "let foo = bar ( contentsOf: await baz() )"
        let output = "let foo = await bar ( contentsOf: baz() )"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"),
                       exclude: ["spaceAroundParens", "spaceInsideParens"])
    }

    func testHoistAwaitWithReturn() {
        let input = "return .enumCase(try await service.greet())"
        let output = "return await .enumCase(try service.greet())"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: ["hoistTry"])
    }

    func testHoistDeeplyNestedAwaits() {
        let input = "let foo = (bar: (5, (await quux(), 6)), baz: (7, quux: await quux()))"
        let output = "let foo = await (bar: (5, (quux(), 6)), baz: (7, quux: quux()))"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testAwaitNotHoistedOutOfClosure() {
        let input = "let foo = { (await bar(), 5) }"
        let output = "let foo = { await (bar(), 5) }"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testAwaitNotHoistedOutOfClosureWithArguments() {
        let input = "let foo = { bar in (await baz(bar), 5) }"
        let output = "let foo = { bar in await (baz(bar), 5) }"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testAwaitNotHoistedOutOfForCondition() {
        let input = "for foo in bar(await baz()) {}"
        let output = "for foo in await bar(baz()) {}"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testAwaitNotHoistedOutOfForIndex() {
        let input = "for await foo in asyncSequence() {}"
        testFormatting(for: input, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitWithInitAssignment() {
        let input = "let variable = String(try await asyncFunction())"
        let output = "let variable = await String(try asyncFunction())"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: ["hoistTry"])
    }

    func testHoistAwaitWithAssignment() {
        let input = "let variable = (try await asyncFunction())"
        let output = "let variable = await (try asyncFunction())"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"), exclude: ["hoistTry"])
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
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitOnlyOne() {
        let input = "greet(name, await surname)"
        let output = "await greet(name, surname)"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitRedundantAwait() {
        let input = "await greet(await name, await surname)"
        let output = "await greet(name, surname)"
        testFormatting(for: input, output, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testHoistAwaitDoesNothing() {
        let input = "await greet(name, surname)"
        testFormatting(for: input, rule: FormatRules.hoistAwait,
                       options: FormatOptions(swiftVersion: "5.5"))
    }

    func testNoHoistAwaitInCapturingFunction() {
        let input = "foo(await bar)"
        testFormatting(for: input, rule: FormatRules.hoistAwait,
                       options: FormatOptions(asyncCapturing: ["foo"]))
    }

    func testNoHoistSecondArgumentAwaitInCapturingFunction() {
        let input = "foo(bar, await baz)"
        testFormatting(for: input, rule: FormatRules.hoistAwait,
                       options: FormatOptions(asyncCapturing: ["foo"]))
    }

    // MARK: - hoistPatternLet

    // hoist = true

    func testHoistCaseLet() {
        let input = "if case .foo(let bar, let baz) = quux {}"
        let output = "if case let .foo(bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistLabelledCaseLet() {
        let input = "if case .foo(bar: let bar, baz: let baz) = quux {}"
        let output = "if case let .foo(bar: bar, baz: baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistCaseVar() {
        let input = "if case .foo(var bar, var baz) = quux {}"
        let output = "if case var .foo(bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistMixedCaseLetVar() {
        let input = "if case .foo(let bar, var baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistIfFirstArgSpecified() {
        let input = "if case .foo(bar, let baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistIfLastArgSpecified() {
        let input = "if case .foo(let bar, baz) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsNumericLiteral() {
        let input = "if case .foo(5, let baz) = quux {}"
        let output = "if case let .foo(5, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsEnumCaseLiteral() {
        let input = "if case .foo(.bar, let baz) = quux {}"
        let output = "if case let .foo(.bar, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let output = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, exclude: ["redundantParens"])
    }

    func testHoistIfFirstArgIsUnderscore() {
        let input = "if case .foo(_, let baz) = quux {}"
        let output = "if case let .foo(_, baz) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistIfSecondArgIsUnderscore() {
        let input = "if case .foo(let baz, _) = quux {}"
        let output = "if case let .foo(baz, _) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNestedHoistLet() {
        let input = "if case (.foo(let a, let b), .bar(let c, let d)) = quux {}"
        let output = "if case let (.foo(a, b), .bar(c, d)) = quux {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistCommaSeparatedSwitchCaseLets() {
        let input = "switch foo {\ncase .foo(let bar), .bar(let bar):\n}"
        let output = "switch foo {\ncase let .foo(bar), let .bar(bar):\n}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet,
                       exclude: ["wrapSwitchCases", "sortedSwitchCases"])
    }

    func testHoistNewlineSeparatedSwitchCaseLets() {
        let input = """
        switch foo {
        case .foo(let bar),
             .bar(let bar):
        }
        """

        let output = """
        switch foo {
        case let .foo(bar),
             let .bar(bar):
        }
        """

        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet,
                       exclude: ["wrapSwitchCases", "sortedSwitchCases"])
    }

    func testHoistCatchLet() {
        let input = "do {} catch Foo.foo(bar: let bar) {}"
        let output = "do {} catch let Foo.foo(bar: bar) {}"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoNestedHoistLetWithSpecifiedArgs() {
        let input = "if case (.foo(let a, b), .bar(let c, d)) = quux {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistClosureVariables() {
        let input = "foo({ let bar = 5 })"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, exclude: ["trailingClosures"])
    }

    // TODO: this should actually hoist the let, but that's tricky to implement without
    // breaking the `testNoOverHoistSwitchCaseWithNestedParens` case
    func testHoistSwitchCaseWithNestedParens() {
        let input = "import Foo\nswitch (foo, bar) {\ncase (.baz(let quux), Foo.bar): break\n}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet,
                       exclude: ["blankLineAfterImports"])
    }

    // TODO: this could actually hoist the let by one level, but that's tricky to implement
    func testNoOverHoistSwitchCaseWithNestedParens() {
        let input = "import Foo\nswitch (foo, bar) {\ncase (.baz(let quux), bar): break\n}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet,
                       exclude: ["blankLineAfterImports"])
    }

    func testNoHoistLetWithEmptArg() {
        let input = "if .foo(let _) = bar {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet,
                       exclude: ["redundantLet", "redundantPattern"])
    }

    func testHoistLetWithNoSpaceAfterCase() {
        let input = "switch x { case.some(let y): return y }"
        let output = "switch x { case let .some(y): return y }"
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testHoistWrappedGuardCaseLet() {
        let input = """
        guard case Foo
            .bar(let baz)
        else {
            return
        }
        """
        let output = """
        guard case let Foo
            .bar(baz)
        else {
            return
        }
        """
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet)
    }

    func testNoHoistCaseLetContainingGenerics() {
        // Hoisting in this case causes a compilation error as-of Swift 5.3
        // See: https://github.com/nicklockwood/SwiftFormat/issues/768
        let input = "if case .some(Optional<Any>.some(let foo)) = bar else {}"
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, exclude: ["typeSugar"])
    }

    // hoist = false

    func testUnhoistCaseLet() {
        let input = "if case let .foo(bar, baz) = quux {}"
        let output = "if case .foo(let bar, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistLabelledCaseLet() {
        let input = "if case let .foo(bar: bar, baz: baz) = quux {}"
        let output = "if case .foo(bar: let bar, baz: let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCaseVar() {
        let input = "if case var .foo(bar, baz) = quux {}"
        let output = "if case .foo(var bar, var baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistGuardCaseLetFollowedByFunction() {
        let input = """
        guard case let foo as Foo = bar { else return }
        foo.bar(foo: bar)
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistSwitchCaseLetFollowedByWhere() {
        let input = """
        switch foo {
        case let bar? where bar >= baz(quux):
            break
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistSwitchCaseLetFollowedByAs() {
        let input = """
        switch foo {
        case let bar as (String, String):
            break
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistSingleCaseLet() {
        let input = "if case let .foo(bar) = quux {}"
        let output = "if case .foo(let bar) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsEnumCaseLiteral() {
        let input = "if case let .foo(.bar, baz) = quux {}"
        let output = "if case .foo(.bar, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase let (.bar(baz)):\n}"
        let output = "switch foo {\ncase (.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteral() {
        let input = "switch foo {\ncase let Foo.bar(baz):\n}"
        let output = "switch foo {\ncase Foo.bar(let baz):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase let (Foo.bar(baz)):\n}"
        let output = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    func testUnhoistIfArgIsUnderscore() {
        let input = "if case let .foo(_, baz) = quux {}"
        let output = "if case .foo(_, let baz) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNestedUnhoistLet() {
        let input = "if case let (.foo(a, b), .bar(c, d)) = quux {}"
        let output = "if case (.foo(let a, let b), .bar(let c, let d)) = quux {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCommaSeparatedSwitchCaseLets() {
        let input = "switch foo {\ncase let .foo(bar), let .bar(bar):\n}"
        let output = "switch foo {\ncase .foo(let bar), .bar(let bar):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["wrapSwitchCases", "sortedSwitchCases"])
    }

    func testUnhoistCommaSeparatedSwitchCaseLets2() {
        let input = "switch foo {\ncase let Foo.foo(bar), let Foo.bar(bar):\n}"
        let output = "switch foo {\ncase Foo.foo(let bar), Foo.bar(let bar):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["wrapSwitchCases", "sortedSwitchCases"])
    }

    func testUnhoistCatchLet() {
        let input = "do {} catch let Foo.foo(bar: bar) {}"
        let output = "do {} catch Foo.foo(bar: let bar) {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistTupleLet() {
        let input = "let (bar, baz) = quux()"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfLetTuple() {
        let input = "if let x = y, let (_, a) = z {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfCaseFollowedByLetTuple() {
        let input = "if case .foo = bar, let (foo, bar) = baz {}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testNoUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = "switch foo {\ncase (Foo.bar(let baz)):\n}"
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options,
                       exclude: ["redundantParens"])
    }

    func testNoDeleteCommentWhenUnhoistingWrappedLet() {
        let input = """
        switch foo {
        case /* next */ let .bar(bar):
        }
        """

        let output = """
        switch foo {
        case /* next */ .bar(let bar):
        }
        """

        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet,
                       options: options, exclude: ["wrapSwitchCases", "sortedSwitchCases"])
    }

    func testMultilineGuardLet() {
        let input = """
        guard
            let first = response?.first,
            let last = response?.last,
            case .foo(token: let foo, provider: let bar) = first,
            case .foo(token: let baz, provider: let quux) = last
        else {
            return
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCaseWithNilValue() {
        let input = """
        switch (foo, bar) {
        case let (.some(unwrappedFoo), nil):
            print(unwrappedFoo)
        default:
            break
        }
        """
        let output = """
        switch (foo, bar) {
        case (.some(let unwrappedFoo), nil):
            print(unwrappedFoo)
        default:
            break
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }

    func testUnhoistCaseWithBoolValue() {
        let input = """
        switch (foo, bar) {
        case let (.some(unwrappedFoo), false):
            print(unwrappedFoo)
        default:
            break
        }
        """
        let output = """
        switch (foo, bar) {
        case (.some(let unwrappedFoo), false):
            print(unwrappedFoo)
        default:
            break
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: FormatRules.hoistPatternLet, options: options)
    }
}
