//
//  UnusedArgumentsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class UnusedArgumentsTests: XCTestCase {
    // closures

    func testUnusedTypedClosureArguments() {
        let input = "let foo = { (bar: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { (_: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedUntypedClosureArguments() {
        let input = "let foo = { bar, baz in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { _, baz in\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testNoRemoveClosureReturnType() {
        let input = "let foo = { () -> Foo.Bar in baz() }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testNoRemoveClosureThrows() {
        let input = "let foo = { () throws in }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testNoRemoveClosureTypedThrows() {
        let input = "let foo = { () throws(Foo) in }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testNoRemoveClosureGenericReturnTypes() {
        let input = "let foo = { () -> Promise<String> in bar }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testNoRemoveClosureTupleReturnTypes() {
        let input = "let foo = { () -> (Int, Int) in (5, 6) }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testNoRemoveClosureGenericArgumentTypes() {
        let input = "let foo = { (_: Foo<Bar, Baz>) in }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testNoRemoveFunctionNameBeforeForLoop() {
        let input = "{\n    func foo() -> Int {}\n    for a in b {}\n}"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testClosureTypeInClosureArgumentsIsNotMangled() {
        let input = "{ (foo: (Int) -> Void) in }"
        let output = "{ (_: (Int) -> Void) in }"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedUnnamedClosureArguments() {
        let input = "{ (_ foo: Int, _ bar: Int) in }"
        let output = "{ (_: Int, _: Int) in }"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedInoutClosureArgumentsNotMangled() {
        let input = "{ (foo: inout Foo, bar: inout Bar) in }"
        let output = "{ (_: inout Foo, _: inout Bar) in }"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testMalformedFunctionNotMisidentifiedAsClosure() {
        let input = "func foo() { bar(5) {} in }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedUsedArguments() {
        let input = """
        forEach { foo, bar in
            guard let foo = foo, let bar = bar else {
                return
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedPartUsedArguments() {
        let input = """
        forEach { foo, bar in
            guard let foo = baz, bar == baz else {
                return
            }
        }
        """
        let output = """
        forEach { _, bar in
            guard let foo = baz, bar == baz else {
                return
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testShadowedParameterUsedInSameGuard() {
        let input = """
        forEach { foo in
            guard let foo = bar, baz = foo else {
                return
            }
        }
        """
        let output = """
        forEach { _ in
            guard let foo = bar, baz = foo else {
                return
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testParameterUsedInForIn() {
        let input = """
        forEach { foos in
            for foo in foos {
                print(foo)
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testParameterUsedInWhereClause() {
        let input = """
        forEach { foo in
            if bar where foo {
                print(bar)
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testParameterUsedInSwitchCase() {
        let input = """
        forEach { foo in
            switch bar {
            case let baz:
                foo = baz
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testParameterUsedInStringInterpolation() {
        let input = """
        forEach { foo in
            print("\\(foo)")
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedClosureArgument() {
        let input = """
        _ = Parser<String, String> { input in
            let parser = Parser<String, String>.with(input)
            return parser
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty, .propertyType])
    }

    func testShadowedClosureArgument2() {
        let input = """
        _ = foo { input in
            let input = ["foo": "Foo", "bar": "Bar"][input]
            return input
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
    }

    func testUnusedPropertyWrapperArgument() {
        let input = """
        ForEach($list.notes) { $note in
            Text(note.foobar)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUnusedThrowingClosureArgument() {
        let input = "foo = { bar throws in \"\" }"
        let output = "foo = { _ throws in \"\" }"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedTypedThrowingClosureArgument() {
        let input = "foo = { bar throws(Foo) in \"\" }"
        let output = "foo = { _ throws(Foo) in \"\" }"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUsedThrowingClosureArgument() {
        let input = "let foo = { bar throws in bar + \"\" }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUsedTypedThrowingClosureArgument() {
        let input = "let foo = { bar throws(Foo) in bar + \"\" }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUnusedTrailingAsyncClosureArgument() {
        let input = """
        app.get { foo async in
            print("No foo")
        }
        """
        let output = """
        app.get { _ async in
            print("No foo")
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedTrailingAsyncClosureArgument2() {
        let input = """
        app.get { foo async -> String in
            "No foo"
        }
        """
        let output = """
        app.get { _ async -> String in
            "No foo"
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedTrailingAsyncClosureArgument3() {
        let input = """
        app.get { (foo: String) async -> String in
            "No foo"
        }
        """
        let output = """
        app.get { (_: String) async -> String in
            "No foo"
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUsedTrailingAsyncClosureArgument() {
        let input = """
        app.get { foo async -> String in
            "\\(foo)"
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testTrailingAsyncClosureArgumentAlreadyMarkedUnused() {
        let input = "app.get { _ async in 5 }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUnusedTrailingClosureArgumentCalledAsync() {
        let input = """
        app.get { async -> String in
            "No async"
        }
        """
        let output = """
        app.get { _ -> String in
            "No async"
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testClosureArgumentUsedInGuardNotRemoved() {
        let input = """
        bar(for: quux) { _, _, foo in
            guard
                let baz = quux.baz,
                foo.contains(where: { $0.baz == baz })
            else {
                return
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testClosureArgumentUsedInIfNotRemoved() {
        let input = """
        foo = { reservations, _ in
            if let reservations, eligibleToShow(
                reservations,
                accountService: accountService
            ) {
                coordinator.startFlow()
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    // init

    func testParameterUsedInInit() {
        let input = """
        init(m: Rotation) {
            let x = sqrt(max(0, m)) / 2
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUnusedParametersShadowedInTupleAssignment() {
        let input = """
        init(x: Int, y: Int, v: Vector) {
            let (x, y) = v
        }
        """
        let output = """
        init(x _: Int, y _: Int, v: Vector) {
            let (x, y) = v
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUsedParametersShadowedInAssignmentFromFunctionCall() {
        let input = """
        init(r: Double) {
            let r = max(abs(r), epsilon)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedUsedArgumentInSwitch() {
        let input = """
        init(_ action: Action, hub: Hub) {
            switch action {
            case let .get(hub, key):
                self = .get(key, hub)
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testParameterUsedInSwitchCaseAfterShadowing() {
        let input = """
        func issue(name: String) -> String {
            switch self {
            case .b(let name): return name
            case .a: return name
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments,
                       exclude: [.hoistPatternLet])
    }

    // functions

    func testMarkUnusedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testMarkUnusedArgumentsInNonVoidFunction() {
        let input = "func foo(bar: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        let output = "func foo(bar _: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testMarkUnusedArgumentsInThrowsFunction() {
        let input = "func foo(bar: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testMarkUnusedArgumentsInOptionalReturningFunction() {
        let input = "func foo(bar: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        let output = "func foo(bar _: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testNoMarkUnusedArgumentsInProtocolFunction() {
        let input = "protocol Foo {\n    func foo(bar: Int) -> Int\n    var bar: Int { get }\n}"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUnusedUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedInoutFunctionArgumentIsNotMangled() {
        let input = "func foo(_ foo: inout Foo) {}"
        let output = "func foo(_: inout Foo) {}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedInternallyRenamedFunctionArgument() {
        let input = "func foo(foo bar: Int) {}"
        let output = "func foo(foo _: Int) {}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testNoMarkProtocolFunctionArgument() {
        let input = "func foo(foo bar: Int)\nvar bar: Bool { get }"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testMembersAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        let output = "func foo(bar: Int, baz _: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testLabelsAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        testFormatting(for: input, output, rule: .unusedArguments, exclude: [.wrapLoopBodies])
    }

    func testDictionaryLiteralsRuinEverything() {
        let input = "func foo(bar: Int, baz: Int) {\n    let quux = [bar: 1, baz: 2]\n}"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testOperatorArgumentsAreUnnamed() {
        let input = "func == (lhs: Int, rhs: Int) { false }"
        let output = "func == (_: Int, _: Int) { false }"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedtFailableInitArgumentsAreNotMangled() {
        let input = "init?(foo: Bar) {}"
        let output = "init?(foo _: Bar) {}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testTreatEscapedArgumentsAsUsed() {
        let input = "func foo(default: Int) -> Int {\n    return `default`\n}"
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testPartiallyMarkedUnusedArguments() {
        let input = "func foo(bar: Bar, baz _: Baz) {}"
        let output = "func foo(bar _: Bar, baz _: Baz) {}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testPartiallyMarkedUnusedArguments2() {
        let input = "func foo(bar _: Bar, baz: Baz) {}"
        let output = "func foo(bar _: Bar, baz _: Baz) {}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnownedUnsafeNotStripped() {
        let input = """
        func foo() {
            var num = 0
            Just(1)
                .sink { [unowned(unsafe) self] in
                    num += $0
                }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedUnusedArguments() {
        let input = """
        func foo(bar: String, baz: Int) {
            let bar = "bar", baz = 5
            print(bar, baz)
        }
        """
        let output = """
        func foo(bar _: String, baz _: Int) {
            let bar = "bar", baz = 5
            print(bar, baz)
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testShadowedUsedArguments2() {
        let input = """
        func foo(things: [String], form: Form) {
            let form = FormRequest(
                things: things,
                form: form
            )
            print(form)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedUsedArguments3() {
        let input = """
        func zoomTo(locations: [Foo], count: Int) {
            let num = count
            guard num > 0, locations.count >= count else {
                return
            }
            print(locations)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedUsedArguments4() {
        let input = """
        func foo(bar: Int) {
            if let bar = baz {
                return
            }
            print(bar)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedUsedArguments5() {
        let input = """
        func doSomething(with number: Int) {
            if let number = Int?(123),
               number == 456
            {
                print("Not likely")
            }

            if number == 180 {
                print("Bullseye!")
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedUsedArgumentInSwitchCase() {
        let input = """
        func foo(bar baz: Foo) -> Foo? {
            switch (a, b) {
            case (0, _),
                 (_, nil):
                return .none
            case let (1, baz?):
                return .bar(baz)
            default:
                return baz
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments,
                       exclude: [.sortSwitchCases])
    }

    func testTryArgumentNotMarkedUnused() {
        let input = """
        func foo(bar: String) throws -> String? {
            let bar =
                try parse(bar)
            return bar
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
    }

    func testTryAwaitArgumentNotMarkedUnused() {
        let input = """
        func foo(bar: String) async throws -> String? {
            let bar = try
                await parse(bar)
            return bar
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
    }

    func testTypedTryAwaitArgumentNotMarkedUnused() {
        let input = """
        func foo(bar: String) async throws(Foo) -> String? {
            let bar = try
                await parse(bar)
            return bar
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
    }

    func testConditionalIfLetMarkedAsUnused() {
        let input = """
        func foo(bar: UIViewController) {
            if let bar = baz {
                bar.loadViewIfNeeded()
            }
        }
        """
        let output = """
        func foo(bar _: UIViewController) {
            if let bar = baz {
                bar.loadViewIfNeeded()
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testConditionAfterIfCaseHoistedLetNotMarkedUnused() {
        let input = """
        func isLoadingFirst(for tabID: String) -> Bool {
            if case let .loading(.first(loadingTabID, _)) = requestState.status, loadingTabID == tabID {
                return true
            } else {
                return false
            }

            print(tabID)
        }
        """
        let options = FormatOptions(hoistPatternLet: true)
        testFormatting(for: input, rule: .unusedArguments, options: options)
    }

    func testConditionAfterIfCaseInlineLetNotMarkedUnused2() {
        let input = """
        func isLoadingFirst(for tabID: String) -> Bool {
            if case .loading(.first(let loadingTabID, _)) = requestState.status, loadingTabID == tabID {
                return true
            } else {
                return false
            }

            print(tabID)
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .unusedArguments, options: options)
    }

    func testConditionAfterIfCaseInlineLetNotMarkedUnused3() {
        let input = """
        private func isFocusedView(formDataID: FormDataID) -> Bool {
            guard
                case .selected(let selectedFormDataID) = currentState.selectedFormItemAction,
                selectedFormDataID == formDataID
            else {
                return false
            }

            return true
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .unusedArguments, options: options)
    }

    func testConditionAfterIfCaseInlineLetNotMarkedUnused4() {
        let input = """
        private func totalRowContent(priceItemsCount: Int, priceBreakdownStyle: PriceBreakdownStyle) {
            if
                case .all(let shouldCollapseByDefault, _) = priceBreakdownStyle,
                priceItemsCount > 0
            {
                // ..
            }
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .unusedArguments, options: options)
    }

    func testConditionAfterIfCaseInlineLetNotMarkedUnused5() {
        let input = """
        private mutating func clearPendingRemovals(itemIDs: Set<String>) {
            for change in changes {
                if case .removal(itemID: let itemID) = change, !itemIDs.contains(itemID) {
                    // ..
                }
            }
        }
        """
        let options = FormatOptions(hoistPatternLet: false)
        testFormatting(for: input, rule: .unusedArguments, options: options)
    }

    func testSecondConditionAfterTupleMarkedUnused() {
        let input = """
        func foobar(bar: Int) {
            let (foo, baz) = (1, 2), bar = 3
            print(foo, bar, baz)
        }
        """
        let output = """
        func foobar(bar _: Int) {
            let (foo, baz) = (1, 2), bar = 3
            print(foo, bar, baz)
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedParamsInTupleAssignment() {
        let input = """
        func foobar(_ foo: Int, _ bar: Int, _ baz: Int, _ quux: Int) {
            let ((foo, bar), baz) = ((foo, quux), bar)
            print(foo, bar, baz, quux)
        }
        """
        let output = """
        func foobar(_ foo: Int, _ bar: Int, _: Int, _ quux: Int) {
            let ((foo, bar), baz) = ((foo, quux), bar)
            print(foo, bar, baz, quux)
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testShadowedIfLetNotMarkedAsUnused() {
        let input = """
        func method(_ foo: Int?, _ bar: String?) {
            if let foo = foo, let bar = bar {}
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShorthandIfLetNotMarkedAsUnused() {
        let input = """
        func method(_ foo: Int?, _ bar: String?) {
            if let foo, let bar {}
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShorthandLetMarkedAsUnused() {
        let input = """
        func method(_ foo: Int?, _ bar: Int?) {
            var foo, bar: Int?
        }
        """
        let output = """
        func method(_: Int?, _: Int?) {
            var foo, bar: Int?
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testShadowedClosureNotMarkedUnused() {
        let input = """
        func foo(bar: () -> Void) {
            let bar = {
                print("log")
                bar()
            }
            bar()
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testShadowedClosureMarkedUnused() {
        let input = """
        func foo(bar: () -> Void) {
            let bar = {
                print("log")
            }
            bar()
        }
        """
        let output = """
        func foo(bar _: () -> Void) {
            let bar = {
                print("log")
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testViewBuilderAnnotationDoesntBreakUnusedArgDetection() {
        let input = """
        struct Foo {
            let content: View

            public init(
                responsibleFileID: StaticString = #fileID,
                @ViewBuilder content: () -> View)
            {
                self.content = content()
            }
        }
        """
        let output = """
        struct Foo {
            let content: View

            public init(
                responsibleFileID _: StaticString = #fileID,
                @ViewBuilder content: () -> View)
            {
                self.content = content()
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments,
                       exclude: [.braces, .wrapArguments])
    }

    func testArgumentUsedInDictionaryLiteral() {
        let input = """
        class MyClass {
            func testMe(value: String) {
                let value = [
                    "key": value
                ]
                print(value)
            }
        }
        """
        testFormatting(for: input, rule: .unusedArguments,
                       exclude: [.trailingCommas])
    }

    func testArgumentUsedAfterIfDefInsideSwitchBlock() {
        let input = """
        func test(string: String) {
            let number = 5
            switch number {
            #if DEBUG
                case 1:
                    print("ONE")
            #endif
            default:
                print("NOT ONE")
            }
            print(string)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUsedConsumingArgument() {
        let input = """
        func close(file: consuming FileHandle) {
            file.close()
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.noExplicitOwnership])
    }

    func testUsedConsumingBorrowingArguments() {
        let input = """
        func foo(a: consuming Foo, b: borrowing Bar) {
            consume(a)
            borrow(b)
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.noExplicitOwnership])
    }

    func testUnusedConsumingArgument() {
        let input = """
        func close(file: consuming FileHandle) {
            print("no-op")
        }
        """
        let output = """
        func close(file _: consuming FileHandle) {
            print("no-op")
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments, exclude: [.noExplicitOwnership])
    }

    func testUnusedConsumingBorrowingArguments() {
        let input = """
        func foo(a: consuming Foo, b: borrowing Bar) {
            print("no-op")
        }
        """
        let output = """
        func foo(a _: consuming Foo, b _: borrowing Bar) {
            print("no-op")
        }
        """
        testFormatting(for: input, output, rule: .unusedArguments, exclude: [.noExplicitOwnership])
    }

    func testFunctionArgumentUsedInGuardNotRemoved() {
        let input = """
        func scrollViewDidEndDecelerating(_ visibleDayRange: DayRange) {
            guard
                store.state.request.isIdle,
                let nextDayToLoad = store.state.request.nextCursor?.lowerBound,
                visibleDayRange.upperBound.distance(to: nextDayToLoad) < 30
            else {
                return
            }

            store.handle(.loadNext)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testFunctionArgumentUsedInGuardNotRemoved2() {
        let input = """
        func convert(
            filter: Filter,
            accounts: [Account],
            outgoingTotal: MulticurrencyTotal?
        ) -> History? {
            guard
                let firstParameter = incomingTotal?.currency,
                let secondParameter = outgoingTotal?.currency,
                isFilter(filter, accounts: accounts)
            else {
                return nil
            }
            return History(firstParameter, secondParameter)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testFunctionArgumentUsedInGuardNotRemoved3() {
        let input = """
        public func flagMessage(_ message: Message) {
          model.withState { state in
            guard
              let flagMessageFeature,
              shouldAllowFlaggingMessage(
                message,
                thread: state.thread)
            else { return }
          }
        }
        """
        testFormatting(for: input, rule: .unusedArguments,
                       exclude: [.wrapArguments, .wrapConditionalBodies, .indent])
    }

    // functions (closure-only)

    func testNoMarkFunctionArgument() {
        let input = "func foo(_ bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .closureOnly)
        testFormatting(for: input, rule: .unusedArguments, options: options)
    }

    // functions (unnamed-only)

    func testNoMarkNamedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, rule: .unusedArguments, options: options)
    }

    func testRemoveUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, output, rule: .unusedArguments, options: options)
    }

    func testNoRemoveInternalFunctionArgumentName() {
        let input = "func foo(foo bar: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, rule: .unusedArguments, options: options)
    }

    // init

    func testMarkUnusedInitArgument() {
        let input = "init(bar: Int, baz: String) {\n    self.baz = baz\n}"
        let output = "init(bar _: Int, baz: String) {\n    self.baz = baz\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    // subscript

    func testMarkUnusedSubscriptArgument() {
        let input = "subscript(foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testMarkUnusedUnnamedSubscriptArgument() {
        let input = "subscript(_ foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testMarkUnusedNamedSubscriptArgument() {
        let input = "subscript(foo foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(foo _: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: .unusedArguments)
    }

    func testUnusedArgumentWithClosureShadowingParamName() {
        let input = """
        func test(foo: Foo) {
            let foo = {
                if foo.bar {
                    baaz
                } else {
                    bar
                }
            }()
            print(foo)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUnusedArgumentWithConditionalAssignmentShadowingParamName() {
        let input = """
        func test(foo: Foo) {
            let foo =
                if foo.bar {
                    baaz
                } else {
                    bar
                }
            print(foo)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUnusedArgumentWithSwitchAssignmentShadowingParamName() {
        let input = """
        func test(foo: Foo) {
            let foo =
                switch foo.bar {
                case true:
                    baaz
                case false:
                    bar
                }
            print(foo)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testUnusedArgumentWithConditionalAssignmentNotShadowingParamName() {
        let input = """
        func test(bar: Bar) {
            let quux =
                if foo {
                    bar
                } else {
                    baaz
                }
            print(quux)
        }
        """
        testFormatting(for: input, rule: .unusedArguments)
    }

    func testIssue1694() {
        let input = """
        listenForUpdates() { [weak self] update, error in
            guard let update, error == nil else {
                return
            }
            self?.configure(update)
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantParens])
    }

    func testIssue1696() {
        let input = """
        func someFunction(with parameter: Int) -> Int {
            let parameter = max(
                200,
                parameter
            )
            return parameter
        }
        """
        testFormatting(for: input, rule: .unusedArguments, exclude: [.redundantProperty])
    }
}
