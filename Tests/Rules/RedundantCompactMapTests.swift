//
//  RedundantCompactMapTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 17/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantCompactMapTests: XCTestCase {
    func testUnsafeLoopDoesNotShadowFunctionNamedUnsafe() {
        let input = """
        func unsafe (_: Int) -> String {
            "value"
        }

        for unsafe element in elements {
            print(element)
        }

        let result = values.compactMap(unsafe)
        """
        let output = """
        func unsafe (_: Int) -> String {
            "value"
        }

        for unsafe element in elements {
            print(element)
        }

        let result = values.map(unsafe)
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testLiteral() {
        let input = """
        let result = values.compactMap { _ in "value" }
        """
        let output = """
        let result = values.map { _ in "value" }
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testLocalFunction() {
        let input = """
        func transform(_: Int) -> String {
            "value"
        }

        let result = values.compactMap { transform($0) }
        """
        let output = """
        func transform(_: Int) -> String {
            "value"
        }

        let result = values.map { transform($0) }
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testExplicitReturnType() {
        let input = """
        let result = values.compactMap { value -> String in
            if value.isEmpty { return "empty" }
            return value.description
        }
        """
        let output = """
        let result = values.map { value -> String in
            if value.isEmpty { return "empty" }
            return value.description
        }
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testOptionalAndUnknownResults() {
        let input = """
        func optional(_: Int) -> String? {
            nil
        }

        func generic<T>(_ value: T) -> T {
            value
        }

        typealias MaybeString = String?
        func alias(_: Int) -> MaybeString {
            nil
        }

        let a = values.compactMap { optional($0) }
        let b = values.compactMap { generic($0) }
        let c = values.compactMap { alias($0) }
        let d = values.compactMap { unknown($0) }
        let e = values.compactMap { _ -> Int? in 1 }
        let g = values.compactMap { $0 as? String }
        let h = values.compactMap { $0?.name }
        let i = values.compactMap { $0 }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testThrowingCall() {
        let input = """
        func transform(_: Int) throws -> String {
            "value"
        }

        let a = try values.compactMap { try transform($0) }
        let b = values.compactMap { try? transform($0) }
        """
        let output = """
        func transform(_: Int) throws -> String {
            "value"
        }

        let a = try values.map { try transform($0) }
        let b = values.compactMap { try? transform($0) }
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testProjectReturnTypes() throws {
        let declarations = """
        struct Name {}
        func name(_ value: Int) -> Name { Name() }
        func maybeName(_ value: Int) -> Name? { nil }
        func ambiguous(_ value: Int) -> Name { Name() }
        func ambiguous(_ value: String) -> Name? { nil }
        """
        let input = """
        let named = values.compactMap(name)
        let labeled = values.compactMap(name(_:))
        let optional = values.compactMap(maybeName)
        let overloaded = values.compactMap(ambiguous(_:))
        let a = values.compactMap { name($0) }
        let b = values.compactMap { maybeName($0) }
        let c = values.compactMap { ambiguous($0) }
        """
        let output = """
        let named = values.map(name)
        let labeled = values.map(name(_:))
        let optional = values.compactMap(maybeName)
        let overloaded = values.compactMap(ambiguous(_:))
        let a = values.map { name($0) }
        let b = values.compactMap { maybeName($0) }
        let c = values.compactMap { ambiguous($0) }
        """
        _ = FormatRules.all
        let fileURL = URL(fileURLWithPath: "/Project/Call.swift")
        let project = ProjectIndex(files: [
            "/Project/Declarations.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
            fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.redundantCompactMap], to: tokenize(input), with: .default,
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output)
    }

    func testParenthesizedClosureAndComments() {
        let input = """
        let result = values.compactMap({ _ in /* keep */ 42 })
        """
        let output = """
        let result = values.map({ _ in /* keep */ 42 })
        """
        testFormatting(for: input, output, rule: .redundantCompactMap, exclude: [.trailingClosures])
    }

    func testShadowedFunction() {
        let input = """
        func transform(_: Int) -> String {
            "value"
        }

        func process(transform: (Int) -> String?) {
            let result = values.compactMap { transform($0) }
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testLoopBindingsShadowFunctions() {
        let input = """
        func transform(_: Int) -> String {
            "value"
        }

        func process(_ callbacks: [(Int) -> String?]) {
            for transform in callbacks {
                let a = values.compactMap(transform)
                let b = values.compactMap { transform($0) }
            }
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testShadowedQualifiedReceiver() {
        let input = """
        enum Transform {
            static func convert(_: Int) -> String {
                "value"
            }
        }

        struct Transformer {
            func convert(_: Int) -> String? {
                nil
            }
        }

        func process(Transform: Transformer, _ values: [Int]) {
            let result = values.compactMap { Transform.convert($0) }
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testThrowingClosureWithOptionalExplicitReturnType() {
        let input = """
        let result = try values.compactMap { (_: Int) throws -> Int? in 1 }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testMemberTypeAfterArrayTypeIsNotAssumedNonOptional() {
        let input = """
        let result = values.compactMap { _ -> [String?].Element in nil }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testGenericExtensionReturnTypeIsUnresolved() {
        let input = """
        struct Value {}
        struct Box<Value> {}

        extension Box where Value == Int? {
            func transform(_: Int) -> Value {
                fatalError()
            }

            func process(_ values: [Int]) {
                let result = values.compactMap { transform($0) }
            }
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testMultipleStatementsAndNestedClosures() {
        let input = """
        let result = values.compactMap { value in
            let callback = { 42 }
            return value.optional
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testReturnTypeInvalidatesIndexFingerprint() {
        let input = """
        func transform(_: Int) -> String {
            "value"
        }

        """
        let changed = """
        func transform(_ value: Int) -> String? { "value" }
        """
        let file = makeSourceFileIndex(from: input, moduleIdentifiers: ["App"])
        let other = makeSourceFileIndex(from: changed, moduleIdentifiers: ["App"])
        XCTAssertEqual(file.functionDeclarations.first?.returnType, "String")
        XCTAssertEqual(other.functionDeclarations.first?.returnType, "String?")
        XCTAssertNotEqual(
            ProjectIndex(files: ["/Project/File.swift": file]).fingerprint(for: [.declarations]),
            ProjectIndex(files: ["/Project/File.swift": other]).fingerprint(for: [.declarations])
        )
    }

    func testExplicitOptionalGenericType() {
        let input = """
        let result = values.compactMap { _ -> Optional<Int> in 1 }
        """
        testFormatting(for: input, rule: .redundantCompactMap, exclude: [.typeSugar])
    }

    func testGenericParameterShadowsConcreteType() {
        let input = """
        struct Value {}
        func process<Value>(_ values: [Value]) {
            let result = values.compactMap { value -> Value in value }
            let parenthesized = values.compactMap { value -> (Value) in value }
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap, exclude: [.redundantParens])
    }

    func testInheritedMemberMayShadowGlobalFunction() {
        let input = """
        func transform(_: Int) -> String {
            "value"
        }

        class Worker: ExternalBase {
            func process(_ values: [Int]) {
                let result = values.compactMap { transform($0) }
            }
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testStaticMethodWithOptionalArrayElements() {
        let input = """
        enum Transform {
            static func values(_: Int) -> [String?] {
                []
            }
        }

        let result = values.compactMap { Transform.values($0) }
        let named = values.compactMap(Transform.values)
        let labeled = values.compactMap(Transform.values(_:))
        """
        let output = """
        enum Transform {
            static func values(_: Int) -> [String?] {
                []
            }
        }

        let result = values.map { Transform.values($0) }
        let named = values.map(Transform.values)
        let labeled = values.map(Transform.values(_:))
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testMissingFileInProjectIndexFallsBackToLocalDeclarations() throws {
        let input = """
        func transform(_: Int) -> String { "value" }
        let result = values.compactMap { transform($0) }
        """
        let output = """
        func transform(_: Int) -> String { "value" }
        let result = values.map { transform($0) }
        """
        let result = try applyRules(
            [.redundantCompactMap], to: tokenize(input), with: .default,
            trackChanges: false, range: nil,
            context: FormattingContext(
                currentFileURL: URL(fileURLWithPath: "/Project/File.swift"),
                projectIndex: ProjectIndex(files: [:])
            )
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output)
    }

    func testNamedFunctionReferences() {
        let input = """
        func transform(_: Int) -> String {
            "value"
        }

        let a = values.compactMap(transform)
        let b = values.compactMap(transform(_:))
        let c = values.compactMap( /* keep */ transform(_:))
        """
        let output = """
        func transform(_: Int) -> String {
            "value"
        }

        let a = values.map(transform)
        let b = values.map(transform(_:))
        let c = values.map( /* keep */ transform(_:))
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testLabelsDisambiguateFunctionReferences() {
        let input = """
        func transform(value _: Int) -> String {
            "value"
        }

        func transform(optional _: Int) -> String? {
            nil
        }

        let a = values.compactMap(transform(value:))
        let b = values.compactMap(transform(optional:))
        let c = values.compactMap(transform)
        """
        let output = """
        func transform(value _: Int) -> String {
            "value"
        }

        func transform(optional _: Int) -> String? {
            nil
        }

        let a = values.map(transform(value:))
        let b = values.compactMap(transform(optional:))
        let c = values.compactMap(transform)
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testNamedFunctionShadowedByParameter() {
        let input = """
        func transform(_: Int) -> String {
            "value"
        }

        func process(transform: (Int) -> String?) {
            let result = values.compactMap(transform)
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testFunctionReturningTransformIsNotAReference() {
        let input = """
        func transform() -> (Int) -> String? {
            { _ in nil }
        }

        let result = values.compactMap(transform())
        let unknown = values.compactMap(external)
        let factory = values.compactMap({ () -> (Int) -> String? in
            { _ in nil }
        }())
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testReferenceLabelsDoNotOmitDefaultArguments() {
        let input = """
        func transform(_: Int) -> String? {
            nil
        }

        func transform(_: Int, extra _: Bool = false) -> String {
            "value"
        }

        let result = values.compactMap(transform(_:))
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }

    func testNonGenericExtensionMethods() {
        let input = """
        struct Transform {}

        extension Transform {
            static func name(_: Int) -> String {
                "value"
            }

            static func maybeName(_: Int) -> String? {
                nil
            }

            func name(_: Int) -> String {
                "value"
            }

            func process(_ values: [Int]) {
                let result = values.compactMap { name($0) }
            }
        }

        let names = values.compactMap(Transform.name)
        let labeled = values.compactMap(Transform.name(_:))
        let optional = values.compactMap(Transform.maybeName)
        """
        let output = """
        struct Transform {}

        extension Transform {
            static func name(_: Int) -> String {
                "value"
            }

            static func maybeName(_: Int) -> String? {
                nil
            }

            func name(_: Int) -> String {
                "value"
            }

            func process(_ values: [Int]) {
                let result = values.map { name($0) }
            }
        }

        let names = values.map(Transform.name)
        let labeled = values.map(Transform.name(_:))
        let optional = values.compactMap(Transform.maybeName)
        """
        testFormatting(for: input, output, rule: .redundantCompactMap)
    }

    func testExtensionTargetResolvedAcrossFiles() throws {
        let input = """
        extension Transform {
            static func name(_: Int) -> String {
                "value"
            }
        }

        let names = values.compactMap(Transform.name)
        let called = values.compactMap { Transform.name($0) }
        """
        let output = """
        extension Transform {
            static func name(_: Int) -> String {
                "value"
            }
        }

        let names = values.map(Transform.name)
        let called = values.map { Transform.name($0) }
        """
        let concrete = """
        struct Transform {}
        """
        let generic = """
        struct Transform<String> {}
        """
        let unknown = """
        struct Unrelated {}
        """
        let ambiguous = """
        #if DEBUG
            struct Transform {}
        #else
            struct Transform {}
        #endif
        """
        _ = FormatRules.all
        let fileURL = URL(fileURLWithPath: "/Project/Call.swift")
        for (declarations, module, expected) in [
            (concrete, "App", output), (generic, "App", input), (unknown, "App", input),
            (ambiguous, "App", input), (concrete, "Library", input),
        ] {
            let project = ProjectIndex(files: [
                "/Project/Types.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: [module]),
                fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
            ])
            let result = try applyRules(
                [.redundantCompactMap], to: tokenize(input), with: .default,
                trackChanges: false, range: nil,
                context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
            )
            XCTAssertEqual(sourceCode(for: result.tokens), expected)
        }
    }

    func testNestedGenericExtensionTargetRemainsUnresolved() {
        let input = """
        struct Value {}
        enum Outer<Value> {
            struct Inner {}
        }

        extension Outer.Inner {
            func transform(_: Int) -> Value {
                fatalError()
            }

            func process(_ values: [Int]) {
                let result = values.compactMap { transform($0) }
            }
        }
        """
        testFormatting(for: input, rule: .redundantCompactMap)
    }
}
