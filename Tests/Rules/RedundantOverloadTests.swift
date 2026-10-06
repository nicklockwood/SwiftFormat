//
//  RedundantOverloadTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 10/6/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantOverloadTests: XCTestCase {
    private func testProjectFormatting(
        for input: String,
        _ output: String? = nil,
        references: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        _ = FormatRules.all
        let declarationsURL = URL(fileURLWithPath: "/Project/Sources/App/Declarations.swift")
        let referencesURL = URL(fileURLWithPath: "/Project/Sources/App/References.swift")
        let projectIndex = ProjectIndex(files: [
            declarationsURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
            referencesURL.path: makeSourceFileIndex(from: references, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.redundantOverload],
            to: tokenize(input),
            with: .default,
            trackChanges: false,
            range: nil,
            context: FormattingContext(currentFileURL: declarationsURL, projectIndex: projectIndex)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output ?? input, file: file, line: line)
    }

    func testReplacesForwardingOverloadWithDefaultArgument() {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: Defaults.timeout)
            }
        }
        """
        let output = """
        struct Loader {
            func load(path: String, timeout: Double = Defaults.timeout) {
                print(path, timeout)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantOverload)
    }

    func testReplacesOverloadDeclaredBeforeOriginalMethod() {
        let input = """
        struct Loader {
            func load(path: String) {
                load(path: path, timeout: 30)
            }

            func load(path: String, timeout: Double) {
                print(path, timeout)
            }
        }
        """
        let output = """
        struct Loader {
            func load(path: String, timeout: Double = 30) {
                print(path, timeout)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantOverload)
    }

    func testSupportsUnlabeledArguments() {
        let input = """
        struct Logger {
            func log(_ message: String, level: Level) {
                print(message, level)
            }

            func log(_ message: String) {
                log(message, level: .info)
            }
        }
        """
        let output = """
        struct Logger {
            func log(_ message: String, level: Level = .info) {
                print(message, level)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantOverload)
    }

    func testDoesNotRemoveOverloadReferencedAsFunctionValue() throws {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        let references = """
        func loadAll(_ loader: Loader, paths: [String]) {
            _ = paths.map(loader.load(path:))
        }
        """
        try testProjectFormatting(for: input, references: references)
    }

    func testDoesNotRemoveOverloadReferencedByBareName() throws {
        let input = """
        struct Example {
            func foo(bar _: Int, baz _: Int) -> Int {
                5
            }

            func foo(bar: Int) -> Int {
                foo(bar: bar, baz: 0)
            }

            func test() {
                let baz: Int? = 7
                _ = baz.map(foo)
            }
        }
        """
        try testProjectFormatting(for: input, references: "")
    }

    func testBareReferenceInAnotherFileDoesNotProtectPrivateOverload() throws {
        let input = """
        private struct Example {
            func foo(bar _: Int, baz _: Int) -> Int {
                5
            }

            func foo(bar: Int) -> Int {
                foo(bar: bar, baz: 0)
            }
        }
        """
        let output = """
        private struct Example {
            func foo(bar _: Int, baz _: Int = 0) -> Int {
                5
            }
        }
        """
        let references = """
        let value: Int? = 7
        _ = value.map(foo)
        """
        try testProjectFormatting(for: input, output, references: references)
    }

    func testBareReferenceOnAnotherTypeDoesNotProtectOverload() throws {
        let input = """
        struct Example {
            func foo(bar _: Int, baz _: Int) -> Int {
                5
            }

            func foo(bar: Int) -> Int {
                foo(bar: bar, baz: 0)
            }
        }
        """
        let output = """
        struct Example {
            func foo(bar _: Int, baz _: Int = 0) -> Int {
                5
            }
        }
        """
        let references = """
        struct Other {
            func foo(_ value: Int) -> Int { value }

            func test(_ value: Int?) {
                _ = value.map(foo)
            }
        }
        """
        try testProjectFormatting(for: input, output, references: references)
    }

    func testBareReferenceToShadowingLocalDoesNotProtectOverload() throws {
        let input = """
        struct Example {
            func foo(bar _: Int, baz _: Int) -> Int {
                5
            }

            func foo(bar: Int) -> Int {
                foo(bar: bar, baz: 0)
            }

            func test() {
                let foo: (Int) -> Int = { $0 }
                let value: Int? = 7
                _ = value.map(foo)
            }
        }
        """
        let output = """
        struct Example {
            func foo(bar _: Int, baz _: Int = 0) -> Int {
                5
            }

            func test() {
                let foo: (Int) -> Int = { $0 }
                let value: Int? = 7
                _ = value.map(foo)
            }
        }
        """
        try testProjectFormatting(for: input, output, references: "")
    }

    func testBareReferenceThroughUnknownReceiverProtectsOverload() throws {
        let input = """
        struct Example {
            func foo(bar _: Int, baz _: Int) -> Int {
                5
            }

            func foo(bar: Int) -> Int {
                foo(bar: bar, baz: 0)
            }
        }
        """
        let references = """
        func test(_ example: Example, value: Int?) {
            _ = value.map(example.foo)
        }
        """
        try testProjectFormatting(for: input, references: references)
    }

    func testBareReferenceInSubclassProtectsOverload() throws {
        let input = """
        class Example {
            func foo(bar _: Int, baz _: Int) -> Int {
                5
            }

            func foo(bar: Int) -> Int {
                foo(bar: bar, baz: 0)
            }
        }
        """
        let references = """
        class Child: Example {
            func test(_ value: Int?) {
                _ = value.map(foo)
            }
        }
        """
        try testProjectFormatting(for: input, references: references)
    }

    func testFunctionValueReferenceToDifferentSignatureDoesNotProtectOverload() throws {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        let output = """
        struct Loader {
            func load(path: String, timeout: Double = 30) {
                print(path, timeout)
            }
        }
        """
        let references = """
        let load = Loader.load(path:timeout:)
        """
        try testProjectFormatting(for: input, output, references: references)
    }

    func testDoesNotRemoveOverloadReferencedByKeyPath() throws {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        let references = """
        let load = \\Loader.load
        """
        try testProjectFormatting(for: input, references: references)
    }

    func testSupportsDefaultArgumentInMiddleOfParameterList() {
        let input = """
        struct Logger {
            func log(prefix: String, level: Level, message: String) {
                print(prefix, level, message)
            }

            func log(prefix: String, message: String) {
                log(prefix: prefix, level: .info, message: message)
            }
        }
        """
        let output = """
        struct Logger {
            func log(prefix: String, level: Level = .info, message: String) {
                print(prefix, level, message)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantOverload)
    }

    func testSupportsReturningAndThrowingMethod() {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) throws -> Data {
                _ = (path, timeout)
                return Data()
            }

            func load(path: String) throws -> Data {
                return try load(path: path, timeout: 30)
            }
        }
        """
        let output = """
        struct Loader {
            func load(path: String, timeout: Double = 30) throws -> Data {
                _ = (path, timeout)
                return Data()
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantOverload)
    }

    func testDoesNotReplaceOverloadThatDefaultsMultipleArguments() {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double, cached: Bool) {
                print(path, timeout, cached)
            }

            func load(path: String) {
                load(path: path, timeout: 30, cached: false)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceOverloadForInoutParameter() {
        let input = """
        struct Counter {
            func increment(value: inout Int, amount: Int) {
                value += amount
            }

            func increment(value: inout Int) {
                increment(value: &value, amount: 1)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceOverloadForVariadicParameter() {
        let input = """
        struct Logger {
            func log(prefix: String, values: String...) {
                print(prefix, values)
            }

            func log(prefix: String) {
                log(prefix: prefix, values: "default")
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceTwoOverloadsDefaultingDifferentArguments() {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: 30)
            }

            func load(timeout: Double) {
                load(path: "default", timeout: timeout)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceOverloadWithAdditionalBehavior() {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                print(path)
                load(path: path, timeout: 30)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceOverloadWithMismatchedParameterType() {
        let input = """
        struct Loader {
            func load(value: Int, timeout: Double) {
                print(value, timeout)
            }

            func load(value: String) {
                load(value: value, timeout: 30)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceOverloadWhenDefaultReferencesParameter() {
        let input = """
        struct Loader {
            func load(path: String, fallback: String) {
                print(path, fallback)
            }

            func load(path: String) {
                load(path: path, fallback: path)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceOverloadWhenDefaultReferencesInstanceMember() {
        let input = """
        struct Loader {
            var defaultTimeout: Double {
                30
            }

            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: defaultTimeout)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceObjcMethod() {
        let input = """
        class Loader: NSObject {
            @objc func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            @objc func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceOverloadMoreVisibleThanOriginalMethod() {
        let input = """
        public struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            public func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testReplacesOverloadLessVisibleThanOriginalMethod() {
        let input = """
        public struct Loader {
            public func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        let output = """
        public struct Loader {
            public func load(path: String, timeout: Double = 30) {
                print(path, timeout)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantOverload)
    }

    func testDoesNotReplacePublicOverloadByDefault() {
        let input = """
        public struct Loader {
            public func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            public func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testReplacesPublicOverloadWithPublicVisibilityOption() {
        let input = """
        public struct Loader {
            public func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            public func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        let output = """
        public struct Loader {
            public func load(path: String, timeout: Double = 30) {
                print(path, timeout)
            }
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .redundantOverload,
            options: FormatOptions(overloadVisibility: .public)
        )
    }

    func testFileprivateVisibilityOptionExcludesInternalOverload() {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .redundantOverload,
            options: FormatOptions(overloadVisibility: .fileprivate)
        )
    }

    func testPrivateVisibilityOptionIncludesPrivateOverload() {
        let input = """
        private struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        let output = """
        private struct Loader {
            func load(path: String, timeout: Double = 30) {
                print(path, timeout)
            }
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .redundantOverload,
            options: FormatOptions(overloadVisibility: .private)
        )
    }

    func testDoesNotReplaceImplicitlyPrivateOverloadWithExplicitlyPrivateMethod() {
        let input = """
        private extension Loader {
            func load(path: String) {
                load(path: path, timeout: 30)
            }

            private func load(path: String, timeout: Double) {
                print(path, timeout)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceMethodInObjcMembersType() {
        let input = """
        @objcMembers class Loader: NSObject {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testDoesNotReplaceProtocolMethod() {
        let input = """
        protocol Loader {
            func load(path: String, timeout: Double)
            func load(path: String)
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testPreservesOverloadWithComments() {
        let input = """
        struct Loader {
            func load(path: String, timeout: Double) {
                print(path, timeout)
            }

            /// Convenience overload used by legacy callers.
            func load(path: String) {
                load(path: path, timeout: 30)
            }
        }
        """
        testFormatting(for: input, rule: .redundantOverload)
    }

    func testReplacesStaticEnumFactoryWithCaseDefaultValue() {
        let input = """
        enum Result<Value> {
            case success(value: Value, cached: Bool)
        }

        extension Result {
            static func success(value: Value) -> Self {
                .success(value: value, cached: false)
            }
        }
        """
        let output = """
        enum Result<Value> {
            case success(value: Value, cached: Bool = false)
        }

        extension Result {
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .redundantOverload,
            options: FormatOptions(swiftVersion: "5.1"),
            exclude: [.emptyBraces, .emptyExtensions]
        )
    }

    func testDoesNotReplacePublicEnumFactoryByDefault() {
        let input = """
        public enum Result<Value> {
            case success(value: Value, cached: Bool)
        }

        public extension Result {
            static func success(value: Value) -> Self {
                .success(value: value, cached: false)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .redundantOverload,
            options: FormatOptions(swiftVersion: "5.1")
        )
    }

    func testDoesNotReplaceStaticEnumFactoryBeforeSwift51() {
        let input = """
        enum Result<Value> {
            case success(value: Value, cached: Bool)
        }

        extension Result {
            static func success(value: Value) -> Self {
                .success(value: value, cached: false)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .redundantOverload,
            options: FormatOptions(swiftVersion: "5.0")
        )
    }

    func testDoesNotReplaceEnumFactoryThatDefaultsMultipleValues() {
        let input = """
        enum Result<Value> {
            case success(value: Value, cached: Bool, source: Source)
        }

        extension Result {
            static func success(value: Value) -> Self {
                .success(value: value, cached: false, source: .network)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .redundantOverload,
            options: FormatOptions(swiftVersion: "5.1")
        )
    }

    func testDoesNotReplaceNonStaticEnumFactory() {
        let input = """
        enum Result<Value> {
            case success(value: Value, cached: Bool)
        }

        extension Result {
            func success(value: Value) -> Self {
                .success(value: value, cached: false)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .redundantOverload,
            options: FormatOptions(swiftVersion: "5.1")
        )
    }

    func testDoesNotReplaceEnumFactoryInConstrainedExtension() {
        let input = """
        enum Result<Value> {
            case success(value: Value, cached: Bool)
        }

        extension Result where Value: Equatable {
            static func success(value: Value) -> Self {
                .success(value: value, cached: false)
            }
        }
        """
        testFormatting(
            for: input,
            rule: .redundantOverload,
            options: FormatOptions(swiftVersion: "5.1")
        )
    }

    func testShapeScriptTypeMismatchOverload() {
        let input = """
        enum RuntimeErrorType {
            case unexpectedChild(ofType: String, in: String)
            case typeMismatch(for: String, index: Int, expected: String, got: String)
        }

        extension RuntimeErrorType {
            static func typeMismatch(
                for symbol: String,
                expected: String,
                got: String
            ) -> RuntimeErrorType {
                .typeMismatch(for: symbol, index: -1, expected: expected, got: got)
            }

            static func typeMismatch(
                for name: String,
                index: Int = -1,
                expected: ValueType,
                got: ValueType
            ) -> RuntimeErrorType {
                let typeDescription: String =
                    switch expected {
                    case let .list(type):
                        type.errorDescription
                    case let .tuple(types) where !types.isEmpty:
                        types[0].errorDescription
                    default:
                        expected.errorDescription
                    }
                return typeMismatch(
                    for: name,
                    index: index,
                    expected: typeDescription,
                    got: got.errorDescription
                )
            }
        }
        """
        let output = """
        enum RuntimeErrorType {
            case unexpectedChild(ofType: String, in: String)
            case typeMismatch(for: String, index: Int = -1, expected: String, got: String)
        }

        extension RuntimeErrorType {
            static func typeMismatch(
                for name: String,
                index: Int = -1,
                expected: ValueType,
                got: ValueType
            ) -> RuntimeErrorType {
                let typeDescription: String =
                    switch expected {
                    case let .list(type):
                        type.errorDescription
                    case let .tuple(types) where !types.isEmpty:
                        types[0].errorDescription
                    default:
                        expected.errorDescription
                    }
                return typeMismatch(
                    for: name,
                    index: index,
                    expected: typeDescription,
                    got: got.errorDescription
                )
            }
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .redundantOverload,
            options: FormatOptions(swiftVersion: "5.1")
        )
    }
}
