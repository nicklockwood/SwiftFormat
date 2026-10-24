//
//  InitStyleTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 23/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class InitStyleTests: XCTestCase {
    func testDisabledRulePreservesConstructors() {
        let input = """
        // swiftformat:disable initStyle
        func foo() -> LongName {
            LongName()
        }
        """
        testFormatting(for: input, rule: .initStyle)
    }

    func testImplicitReturn() {
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
        testFormatting(for: input, output, rule: .initStyle)
    }

    func testExplicitReturnAndComputedProperty() {
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
        testFormatting(for: input, output, rule: .initStyle)
    }

    func testExpandConstructor() {
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
        testFormatting(for: input, output, rule: .initStyle,
                       options: FormatOptions(explicitTypes: .always))
    }

    func testShortTypeNames() {
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
        testFormatting(for: input, output, rule: .initStyle)
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
        testFormatting(for: input, output, rule: .initStyle,
                       options: FormatOptions(initTypeMinLength: 7))
    }

    func testShortTypeNamesCanBeRemoved() {
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
        testFormatting(for: input, output, rule: .initStyle,
                       options: FormatOptions(initTypeMinLength: 0))
    }

    func testAssignmentsAndArguments() {
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
        testFormatting(for: input, output, rule: .initStyle,
                       options: FormatOptions(explicitTypes: .inferred))
        testFormatting(for: input, rule: .initStyle)
    }

    func testPreservesUnsafeContexts() {
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
        testFormatting(for: input, rule: .initStyle,
                       options: FormatOptions(explicitTypes: .inferred))
    }

    func testPreservesShadowedConstructorsAndOverloads() {
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
        testFormatting(for: input, rule: .initStyle,
                       options: FormatOptions(explicitTypes: .inferred))
    }

    func testExpandsResolvedAssignment() {
        let input = """
        var value: LongName
        value = .init()
        """
        let output = """
        var value: LongName
        value = LongName()
        """
        testFormatting(for: input, output, rule: .initStyle,
                       options: FormatOptions(explicitTypes: .always))
    }

    func testDeclarationStyleIsIndependent() {
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
        testFormatting(for: input, [output], rules: [.redundantType, .initStyle],
                       options: FormatOptions(propertyTypes: .inferred))
    }

    func testIndexedPropertyAndParameter() throws {
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
            [.initStyle], to: tokenize(input), with: FormatOptions(explicitTypes: .inferred),
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output)
        let defaultResult = try applyRules(
            [.initStyle], to: tokenize(input), with: FormatOptions(),
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: defaultResult.tokens), input)
    }
}
