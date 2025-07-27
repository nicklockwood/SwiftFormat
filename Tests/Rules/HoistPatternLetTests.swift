//
//  HoistPatternLetTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 3/6/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class HoistPatternLetTests: XCTestCase {
    // hoist = true

    func testHoistCaseLet() {
        let input = """
        if case .foo(let bar, let baz) = quux {}
        """
        let output = """
        if case let .foo(bar, baz) = quux {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testHoistLabelledCaseLet() {
        let input = """
        if case .foo(bar: let bar, baz: let baz) = quux {}
        """
        let output = """
        if case let .foo(bar: bar, baz: baz) = quux {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testHoistCaseVar() {
        let input = """
        if case .foo(var bar, var baz) = quux {}
        """
        let output = """
        if case var .foo(bar, baz) = quux {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testNoHoistMixedCaseLetVar() {
        let input = """
        if case .foo(let bar, var baz) = quux {}
        """
        testFormatting(for: input, rule: .hoistPatternLet)
    }

    func testNoHoistIfFirstArgSpecified() {
        let input = """
        if case .foo(bar, let baz) = quux {}
        """
        testFormatting(for: input, rule: .hoistPatternLet)
    }

    func testNoHoistIfLastArgSpecified() {
        let input = """
        if case .foo(let bar, baz) = quux {}
        """
        testFormatting(for: input, rule: .hoistPatternLet)
    }

    func testHoistIfArgIsNumericLiteral() {
        let input = """
        if case .foo(5, let baz) = quux {}
        """
        let output = """
        if case let .foo(5, baz) = quux {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testHoistIfArgIsEnumCaseLiteral() {
        let input = """
        if case .foo(.bar, let baz) = quux {}
        """
        let output = """
        if case let .foo(.bar, baz) = quux {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testHoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = """
        switch foo {
        case (Foo.bar(let baz)):
        }
        """
        let output = """
        switch foo {
        case let (Foo.bar(baz)):
        }
        """
        testFormatting(for: input, output, rule: .hoistPatternLet, exclude: [.redundantParens])
    }

    func testHoistIfFirstArgIsUnderscore() {
        let input = """
        if case .foo(_, let baz) = quux {}
        """
        let output = """
        if case let .foo(_, baz) = quux {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testHoistIfSecondArgIsUnderscore() {
        let input = """
        if case .foo(let baz, _) = quux {}
        """
        let output = """
        if case let .foo(baz, _) = quux {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testNestedHoistLet() {
        let input = """
        if case (.foo(let a, let b), .bar(let c, let d)) = quux {}
        """
        let output = """
        if case let (.foo(a, b), .bar(c, d)) = quux {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testHoistCommaSeparatedSwitchCaseLets() {
        let input = """
        switch foo {
        case .foo(let bar), .bar(let bar):
        }
        """
        let output = """
        switch foo {
        case let .foo(bar), let .bar(bar):
        }
        """
        testFormatting(for: input, output, rule: .hoistPatternLet,
                       exclude: [.wrapSwitchCases, .sortSwitchCases])
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

        testFormatting(for: input, output, rule: .hoistPatternLet,
                       exclude: [.wrapSwitchCases, .sortSwitchCases])
    }

    func testHoistCatchLet() {
        let input = """
        do {} catch Foo.foo(bar: let bar) {}
        """
        let output = """
        do {} catch let Foo.foo(bar: bar) {}
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testNoNestedHoistLetWithSpecifiedArgs() {
        let input = """
        if case (.foo(let a, b), .bar(let c, d)) = quux {}
        """
        testFormatting(for: input, rule: .hoistPatternLet)
    }

    func testNoHoistClosureVariables() {
        let input = """
        foo({ let bar = 5 })
        """
        testFormatting(for: input, rule: .hoistPatternLet, exclude: [.trailingClosures])
    }

    // TODO: this should actually hoist the let, but that's tricky to implement without
    // breaking the `testNoOverHoistSwitchCaseWithNestedParens` case
    func testHoistSwitchCaseWithNestedParens() {
        let input = """
        import Foo
        switch (foo, bar) {
        case (.baz(let quux), Foo.bar): break
        }
        """
        testFormatting(for: input, rule: .hoistPatternLet,
                       exclude: [.blankLineAfterImports])
    }

    // TODO: this could actually hoist the let by one level, but that's tricky to implement
    func testNoOverHoistSwitchCaseWithNestedParens() {
        let input = """
        import Foo
        switch (foo, bar) {
        case (.baz(let quux), bar): break
        }
        """
        testFormatting(for: input, rule: .hoistPatternLet,
                       exclude: [.blankLineAfterImports])
    }

    func testNoHoistLetWithEmptArg() {
        let input = """
        if .foo(let _) = bar {}
        """
        testFormatting(for: input, rule: .hoistPatternLet,
                       exclude: [.redundantLet, .redundantPattern])
    }

    func testHoistLetWithNoSpaceAfterCase() {
        let input = """
        switch x { case.some(let y): return y }
        """
        let output = """
        switch x { case let .some(y): return y }
        """
        testFormatting(for: input, output, rule: .hoistPatternLet)
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
        testFormatting(for: input, output, rule: .hoistPatternLet)
    }

    func testNoHoistCaseLetContainingGenerics() {
        // Hoisting in this case causes a compilation error as-of Swift 5.3
        // See: https://github.com/nicklockwood/SwiftFormat/issues/768
        let input = """
        if case .some(Optional<Any>.some(let foo)) = bar else {}
        """
        testFormatting(for: input, rule: .hoistPatternLet, exclude: [.typeSugar])
    }

    // hoist = false

    func testUnhoistCaseLet() {
        let input = """
        if case let .foo(bar, baz) = quux {}
        """
        let output = """
        if case .foo(let bar, let baz) = quux {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testUnhoistCaseLetDictionaryTuple() {
        let input = """
        switch (a, b) {
        case let (c as [String: Any], d as [String: Any]):
            break
        }
        """
        let output = """
        switch (a, b) {
        case (let c as [String: Any], let d as [String: Any]):
            break
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testUnhoistLabelledCaseLet() {
        let input = """
        if case let .foo(bar: bar, baz: baz) = quux {}
        """
        let output = """
        if case .foo(bar: let bar, baz: let baz) = quux {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testUnhoistCaseVar() {
        let input = """
        if case var .foo(bar, baz) = quux {}
        """
        let output = """
        if case .foo(var bar, var baz) = quux {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testNoUnhoistGuardCaseLetFollowedByFunction() {
        let input = """
        guard case let foo as Foo = bar else { return }

        foo.bar(foo: bar)
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .hoistPatternLet, options: options,
                       exclude: [.wrapConditionalBodies])
    }

    func testNoUnhoistSwitchCaseLetFollowedByWhere() {
        let input = """
        switch foo {
        case let bar? where bar >= baz(quux):
            break
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .hoistPatternLet, options: options)
    }

    func testNoUnhoistSwitchCaseLetFollowedByAs() {
        let input = """
        switch foo {
        case let bar as (String, String):
            break
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .hoistPatternLet, options: options)
    }

    func testUnhoistSingleCaseLet() {
        let input = """
        if case let .foo(bar) = quux {}
        """
        let output = """
        if case .foo(let bar) = quux {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsEnumCaseLiteral() {
        let input = """
        if case let .foo(.bar, baz) = quux {}
        """
        let output = """
        if case .foo(.bar, let baz) = quux {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsEnumCaseLiteralInParens() {
        let input = """
        switch foo {
        case let (.bar(baz)):
        }
        """
        let output = """
        switch foo {
        case (.bar(let baz)):
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options,
                       exclude: [.redundantParens])
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteral() {
        let input = """
        switch foo {
        case let Foo.bar(baz):
        }
        """
        let output = """
        switch foo {
        case Foo.bar(let baz):
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = """
        switch foo {
        case let (Foo.bar(baz)):
        }
        """
        let output = """
        switch foo {
        case (Foo.bar(let baz)):
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options,
                       exclude: [.redundantParens])
    }

    func testUnhoistIfArgIsUnderscore() {
        let input = """
        if case let .foo(_, baz) = quux {}
        """
        let output = """
        if case .foo(_, let baz) = quux {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testNestedUnhoistLet() {
        let input = """
        if case let (.foo(a, b), .bar(c, d)) = quux {}
        """
        let output = """
        if case (.foo(let a, let b), .bar(let c, let d)) = quux {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testUnhoistCommaSeparatedSwitchCaseLets() {
        let input = """
        switch foo {
        case let .foo(bar), let .bar(bar):
        }
        """
        let output = """
        switch foo {
        case .foo(let bar), .bar(let bar):
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options,
                       exclude: [.wrapSwitchCases, .sortSwitchCases])
    }

    func testUnhoistCommaSeparatedSwitchCaseLets2() {
        let input = """
        switch foo {
        case let Foo.foo(bar), let Foo.bar(bar):
        }
        """
        let output = """
        switch foo {
        case Foo.foo(let bar), Foo.bar(let bar):
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options,
                       exclude: [.wrapSwitchCases, .sortSwitchCases])
    }

    func testUnhoistCatchLet() {
        let input = """
        do {} catch let Foo.foo(bar: bar) {}
        """
        let output = """
        do {} catch Foo.foo(bar: let bar) {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }

    func testNoUnhoistTupleLet() {
        let input = """
        let (bar, baz) = quux()
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .hoistPatternLet, options: options)
    }

    func testNoUnhoistIfLetTuple() {
        let input = """
        if let x = y, let (_, a) = z {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .hoistPatternLet, options: options)
    }

    func testNoUnhoistIfCaseFollowedByLetTuple() {
        let input = """
        if case .foo = bar, let (foo, bar) = baz {}
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .hoistPatternLet, options: options)
    }

    func testNoUnhoistIfArgIsNamespacedEnumCaseLiteralInParens() {
        let input = """
        switch foo {
        case (Foo.bar(let baz)):
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .hoistPatternLet, options: options,
                       exclude: [.redundantParens])
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
        testFormatting(for: input, output, rule: .hoistPatternLet,
                       options: options, exclude: [.wrapSwitchCases, .sortSwitchCases])
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
        testFormatting(for: input, rule: .hoistPatternLet, options: options)
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
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
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
        testFormatting(for: input, output, rule: .hoistPatternLet, options: options)
    }
}
