//
//  ExplicitTypesTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 22/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ExplicitTypesTests: XCTestCase {
    func testImplicitReturn() {
        let input = """
        func foo() -> Bar {
            Bar.value
        }
        """
        let output = """
        func foo() -> Bar {
            .value
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(swiftVersion: "5.1"))
    }

    func testComputedProperty() {
        let input = """
        var foo: Bar {
            Bar.value
        }
        """
        let output = """
        var foo: Bar {
            .value
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(swiftVersion: "5.1"))
    }

    func testExplicitReturns() {
        let input = """
        func foo(_ flag: Bool) -> Bar {
            if flag {
                return Bar.first
            }
            return Bar.second
        }
        """
        let output = """
        func foo(_ flag: Bool) -> Bar {
            if flag {
                return .first
            }
            return .second
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testAssignment() {
        let input = """
        var foo: Bar
        foo = Bar.value
        """
        let output = """
        var foo: Bar
        foo = .value
        """
        testFormatting(for: input, output, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testStaticFactoryAndQualifiedType() {
        let input = """
        func foo() -> Module.Bar {
            Module.Bar.make(value: 1)
        }
        """
        let output = """
        func foo() -> Module.Bar {
            .make(value: 1)
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testPreservesUnknownOrDifferentContext() {
        let input = """
        func optional() -> Bar? {
            Bar.value
        }

        func other() -> Other {
            Bar.value
        }

        func chain() -> Bar {
            Factory.value.bar
        }

        func nested() -> Bar {
            consume { Bar.value }
            return Bar.value + Bar.value
        }

        unknown = Bar.value
        consume(Bar.value)
        """
        testFormatting(for: input, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testPreservesCommentsInQualifier() {
        let input = """
        func foo() -> Bar {
            Bar /* explanation */ .value
        }
        """
        testFormatting(for: input, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testShadowedBinding() {
        let input = """
        var foo: Bar
        func update() {
            var foo: Other
            foo = Bar.value
        }
        """
        testFormatting(for: input, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testFunctionArgument() {
        let input = """
        func consume(_ bar: Bar) {
            print(bar)
        }

        consume(Bar.value)
        """
        let output = """
        func consume(_ bar: Bar) {
            print(bar)
        }

        consume(.value)
        """
        testFormatting(for: input, output, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testOverloadedArgumentIsPreserved() {
        let input = """
        func consume(_ bar: Bar) {
            print(bar)
        }

        func consume(_ other: Other) {
            print(other)
        }

        consume(Bar.value)
        """
        testFormatting(for: input, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testNestedClosureDoesNotUseEnclosingReturnType() {
        let input = """
        func foo() -> Bar {
            consume {
                print("value")
                return Bar.value
            }
            return .value
        }
        """
        testFormatting(for: input, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testLocalMemberAssignment() {
        let input = """
        struct Model {
            var value: Bar

            mutating func update() {
                self.value = Bar.value
            }
        }
        """
        let output = """
        struct Model {
            var value: Bar

            mutating func update() {
                self.value = .value
            }
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(explicitSelf: .insert, explicitTypes: .inferred))
    }

    func testGenericAndShadowedCallsArePreserved() {
        let input = """
        func consume<T>(_ value: T) {
            print(value)
        }

        consume(Bar.value)

        func use() {
            let callback: (Bar) -> Void = consume
            callback(Bar.value)
        }
        """
        testFormatting(for: input, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testPrivateOverloadIsPreserved() {
        let input = """
        func consume(_ value: Bar) {
            print(value)
        }

        private func consume(_ value: Other) {
            print(value)
        }

        consume(Bar.value)
        """
        testFormatting(for: input, rule: .explicitTypes, options: FormatOptions(explicitTypes: .inferred))
    }

    func testProjectPropertyAndParameterTypes() throws {
        let declarations = """
        struct Model {
            var value: Bar
        }
        func consume(label: Bar, count: Int = 0) {}
        """
        let input = """
        func update(_ model: inout Model) {
            model.value = Bar.value
            consume(label: Bar.value)
        }
        """
        let output = """
        func update(_ model: inout Model) {
            model.value = .value
            consume(label: .value)
        }
        """
        _ = FormatRules.all
        let fileURL = URL(fileURLWithPath: "/Project/Call.swift")
        let project = ProjectIndex(files: [
            "/Project/Declarations.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
            fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.explicitTypes], to: tokenize(input), with: FormatOptions(explicitTypes: .inferred),
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output)
    }

    func testAlwaysExpandsStaticMembers() {
        let input = """
        func value() -> Bar {
            .value
        }
        """
        let output = """
        func value() -> Bar {
            Bar.value
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(explicitTypes: .always))
    }

    func testAutoPreservesAssignmentsButShortensAnnotatedValues() {
        let input = """
        let value: Bar = Bar.value
        var other: Bar
        other = Bar.value
        """
        let output = """
        let value: Bar = .value
        var other: Bar
        other = Bar.value
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(explicitTypes: .auto, propertyTypes: .explicit))
    }

    func testDeclarationConstructorOptions() {
        let input = """
        let foo: Foo = Foo()
        let longer: LongName = LongName()
        """
        let output = """
        let foo: Foo = Foo()
        let longer: LongName = .init()
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(propertyTypes: .explicit))
    }

    func testPreservesUnknownShorthandAndOptionalContext() {
        let input = """
        func unknown() {
            consume(.value)
        }

        func optional() -> Bar? {
            .none
        }
        """
        testFormatting(for: input, rule: .explicitTypes,
                       options: FormatOptions(explicitTypes: .always))
    }

    func testInitializerDisabledRulePreservesConstructors() {
        let input = """
        // swiftformat:disable explicitTypes
        func foo() -> LongName {
            LongName()
        }
        """
        testFormatting(for: input, rule: .explicitTypes)
    }

    func testInitializerImplicitReturn() {
        let input = """
        func foo() -> LongName {
            LongName()
        }
        """
        let output = """
        func foo() -> LongName {
            .init()
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes)
    }

    func testInitializerExplicitReturnAndComputedProperty() {
        let input = """
        func foo(_ flag: Bool) -> LongName {
            if flag {
                return LongName(value: 1)
            }
            return LongName(value: 2)
        }

        var value: LongName {
            LongName()
        }
        """
        let output = """
        func foo(_ flag: Bool) -> LongName {
            if flag {
                return .init(value: 1)
            }
            return .init(value: 2)
        }

        var value: LongName {
            .init()
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes)
    }

    func testInitializerExpandConstructor() {
        let input = """
        func foo() -> Module.Foo {
            .init()
        }
        """
        let output = """
        func foo() -> Module.Foo {
            Module.Foo()
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(explicitTypes: .always))
    }

    func testInitializerShortTypeNames() {
        let input = """
        func foo() -> Four {
            Four()
        }

        func thing() -> Thing {
            Thing()
        }

        func longer() -> Longer {
            Longer()
        }
        """
        let output = """
        func foo() -> Four {
            Four()
        }

        func thing() -> Thing {
            .init()
        }

        func longer() -> Longer {
            .init()
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes)
    }

    func testCustomTypeNameThreshold() {
        let input = """
        func medium() -> Medium {
            Medium()
        }

        func longest() -> Longest {
            Longest()
        }
        """
        let output = """
        func medium() -> Medium {
            Medium()
        }

        func longest() -> Longest {
            .init()
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(initTypeMinLength: 7))
    }

    func testInitializerShortTypeNamesCanBeRemoved() {
        let input = """
        func foo() -> Foo {
            Foo()
        }
        """
        let output = """
        func foo() -> Foo {
            .init()
        }
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(initTypeMinLength: 0))
    }

    func testInitializerAssignmentsAndArguments() {
        let input = """
        func consume(_: LongName) {}
        var value: LongName
        value = LongName()
        consume(LongName())
        """
        let output = """
        func consume(_: LongName) {}
        var value: LongName
        value = .init()
        consume(.init())
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(explicitTypes: .inferred))
        testFormatting(for: input, rule: .explicitTypes)
    }

    func testInitializerPreservesUnsafeContexts() {
        let input = """
        func optional() -> LongName? {
            LongName()
        }

        func different() -> Parent {
            LongName()
        }

        func chained() -> LongName {
            LongName().value
        }

        func commented() -> LongName {
            LongName /* keep */ ()
        }

        func generic<T>() -> T {
            T()
        }

        func closure() -> LongName {
            build { LongName() }
        }

        func unknown() {
            consume(LongName())
        }
        """
        testFormatting(for: input, rule: .explicitTypes,
                       options: FormatOptions(explicitTypes: .inferred))
    }

    func testInitializerPreservesShadowedConstructorsAndOverloads() {
        let input = """
        func consume(_: LongName) {}
        func consume(_: OtherType) {}
        func foo(_ LongName: () -> LongName) -> LongName {
            LongName()
        }

        func bar() {
            consume(LongName())
        }

        struct Container<LongName> {
            func make() -> LongName {
                LongName()
            }
        }
        """
        testFormatting(for: input, rule: .explicitTypes,
                       options: FormatOptions(explicitTypes: .inferred))
    }

    func testInitializerExpandsResolvedAssignment() {
        let input = """
        var value: LongName
        value = .init()
        """
        let output = """
        var value: LongName
        value = LongName()
        """
        testFormatting(for: input, output, rule: .explicitTypes,
                       options: FormatOptions(explicitTypes: .always))
    }

    func testInitializerDeclarationStyleIsIndependent() {
        let input = """
        let value: LongName = LongName()
        func foo() -> LongName {
            LongName()
        }
        """
        let output = """
        let value = LongName()
        func foo() -> LongName {
            .init()
        }
        """
        testFormatting(for: input, [output], rules: [.redundantType, .explicitTypes],
                       options: FormatOptions(propertyTypes: .inferred))
    }

    func testInitializerIndexedPropertyAndParameter() throws {
        let declarations = """
        struct Model { var value: LongName }
        func consume(_: LongName) {}
        """
        let input = """
        func update(_ model: inout Model) {
            model.value = LongName()
            consume(LongName())
        }
        """
        let output = """
        func update(_ model: inout Model) {
            model.value = .init()
            consume(.init())
        }
        """
        _ = FormatRules.all
        let fileURL = URL(fileURLWithPath: "/Project/Call.swift")
        let project = ProjectIndex(files: [
            "/Project/Declarations.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
            fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.explicitTypes], to: tokenize(input), with: FormatOptions(explicitTypes: .inferred),
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output)
        let defaultResult = try applyRules(
            [.explicitTypes], to: tokenize(input), with: FormatOptions(),
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: defaultResult.tokens), input)
    }
}
