//
//  RedundantStaticMemberTypeTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 22/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantStaticMemberTypeTests: XCTestCase {
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
        testFormatting(for: input, output, rule: .redundantStaticMemberType,
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
        testFormatting(for: input, output, rule: .redundantStaticMemberType,
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
        testFormatting(for: input, output, rule: .redundantStaticMemberType)
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
        testFormatting(for: input, output, rule: .redundantStaticMemberType)
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
        testFormatting(for: input, output, rule: .redundantStaticMemberType)
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
        testFormatting(for: input, rule: .redundantStaticMemberType)
    }

    func testPreservesCommentsInQualifier() {
        let input = """
        func foo() -> Bar {
            Bar /* explanation */ .value
        }
        """
        testFormatting(for: input, rule: .redundantStaticMemberType)
    }

    func testShadowedBinding() {
        let input = """
        var foo: Bar
        func update() {
            var foo: Other
            foo = Bar.value
        }
        """
        testFormatting(for: input, rule: .redundantStaticMemberType)
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
        testFormatting(for: input, output, rule: .redundantStaticMemberType)
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
        testFormatting(for: input, rule: .redundantStaticMemberType)
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
        testFormatting(for: input, rule: .redundantStaticMemberType)
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
        testFormatting(for: input, output, rule: .redundantStaticMemberType,
                       options: FormatOptions(explicitSelf: .insert))
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
        testFormatting(for: input, rule: .redundantStaticMemberType)
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
        testFormatting(for: input, rule: .redundantStaticMemberType)
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
            [.redundantStaticMemberType], to: tokenize(input), with: .default,
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output)
    }
}
