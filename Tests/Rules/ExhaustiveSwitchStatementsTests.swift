//
//  ExhaustiveSwitchStatementsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/05/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ExhaustiveSwitchStatementsTests: XCTestCase {
    func testCrossFileEnumWithGroupedAndRawValueCases() throws {
        let declarations = """
        enum State: String {
            case idle = "idle", loading = "loading"
            case loaded, failed
        }
        """
        let input = """
        func render(_ state: State) {
            switch state {
            case .loaded: showContent()
            default /* keep this */: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ state: State) {
            switch state {
            case .loaded: showContent()
            case .idle, .loading, .failed /* keep this */: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: declarations)
    }

    func testAssociatedValuesAndPartialPatterns() throws {
        let declarations = """
        enum State {
            case idle, loaded(String), failed(Int), other(Int, String)
        }
        """
        let input = """
        func render(_ state: State) {
            switch state {
            case let .loaded(value): print(value)
            case .failed(0): print("zero")
            case .other(_, let text): print(text)
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State) {
            switch state {
            case let .loaded(value): print(value)
            case .failed(0): print("zero")
            case .other(_, let text): print(text)
            case .idle, .failed: fallback()
            }
        }
        """
        try check(input, output, declarations: declarations)
    }

    func testGuardedCaseIsStillIncludedInDefault() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle where condition: first()
            case .loaded, .failed: second()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State) {
            switch state {
            case .idle where condition: first()
            case .loaded, .failed: second()
            case .idle: fallback()
            }
        }
        """
        try check(input, output)
    }

    func testNestedSwitchAndSwitchExpression() throws {
        let input = """
        func render(_ state: State, _ inner: Inner) -> String {
            switch state {
            case .idle:
                switch inner {
                case .a: return "a"
                default: return "b"
                }
            default: return "other"
            }
        }
        func title(_ value: Inner) -> String {
            switch value {
            case .a: "a"
            default: "b"
            }
        }
        """
        let output = """
        func render(_ state: State, _ inner: Inner) -> String {
            switch state {
            case .idle:
                switch inner {
                case .a: return "a"
                case .b: return "b"
                }
            case .loaded, .failed: return "other"
            }
        }
        func title(_ value: Inner) -> String {
            switch value {
            case .a: "a"
            case .b: "b"
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        enum Inner { case a, b }
        """)
    }

    func testSelfAndQualifiedNestedEnum() throws {
        let input = """
        enum Namespace {
            enum State {
                case idle, loaded, failed
                func render() {
                    switch self {
                    case .idle: first()
                    default: second()
                    }
                }
            }
        }
        func render(_ state: Namespace.State) {
            switch state {
            case Namespace.State.loaded: first()
            default: second()
            }
        }
        """
        let output = """
        enum Namespace {
            enum State {
                case idle, loaded, failed
                func render() {
                    switch self {
                    case .idle: first()
                    case .loaded, .failed: second()
                    }
                }
            }
        }
        func render(_ state: Namespace.State) {
            switch state {
            case Namespace.State.loaded: first()
            case .idle, .failed: second()
            }
        }
        """
        try check(input, output, declarations: "")
    }

    func testUnknownDefaultIsPreserved() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle: first()
            @unknown default: second()
            }
        }
        """
        try check(input)
    }

    func testConditionalSwitchIsPreserved() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            #if DEBUG
            case .idle: first()
            #endif
            default: second()
            }
        }
        """
        try check(input)
    }

    func testConditionalAndUnavailableCasesArePreserved() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle: first()
            default: second()
            }
        }
        """
        try check(input, declarations: """
        enum State {
            case idle
            #if DEBUG
            case loaded
            #endif
            case failed
        }
        """)
        try check(input, declarations: """
        enum State {
            case idle
            @available(iOS 100, *) case loaded
            case failed
        }
        """)
    }

    func testAmbiguousEnumDeclarationsArePreserved() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle: first()
            default: second()
            }
        }
        """
        try check(input, declarations: """
        enum State { case idle, loaded }
        enum State { case idle, failed }
        """)
    }

    func testOptionalUnknownAndShadowedBindingsArePreserved() throws {
        let input = """
        func render(_ state: State?) {
            switch state {
            case .idle?: first()
            default: second()
            }
        }
        func other(_ value: Unknown) {
            switch value {
            default: fallback()
            }
        }
        func shadowed(_ item: State) {
            let item = somethingElse()
            switch item {
            default: fallback()
            }
        }
        """
        try check(input)
    }

    func testAlreadyExhaustiveSwitchPreservesUnreachableDefault() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle, .loaded, .failed: first()
            default: fallback()
            }
        }
        """
        try check(input)
    }

    func testDisabledDirectiveIsRespected() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle: first()
            // swiftformat:disable:next exhaustiveSwitchStatements
            default: fallback()
            }
        }
        """
        try check(input)
    }

    func testNoProjectIndexDoesNotChangeDefaults() {
        let input = """
        enum State { case idle, loaded }
        func render(_ state: State) {
            switch state {
            case .idle: first()
            default: fallback()
            }
        }
        """
        testFormatting(for: input, rule: .exhaustiveSwitchStatements)
    }

    func testEnumCaseChangesInvalidateDeclarationFingerprint() {
        let before = ProjectIndex(files: ["/Project/State.swift": makeSourceFileIndex(
            from: "enum State { case idle, loaded }", moduleIdentifiers: ["App"]
        )])
        let after = ProjectIndex(files: ["/Project/State.swift": makeSourceFileIndex(
            from: "enum State { case idle, loaded, failed }", moduleIdentifiers: ["App"]
        )])
        XCTAssertNotEqual(before.fingerprint(for: [.declarations]), after.fingerprint(for: [.declarations]))
    }

    func testLiteralPayloadsDoNotCoverEntireCases() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case let .flag(true, value), let .otherFlag(false, value), let .optional(nil, value): print(value)
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State) {
            switch state {
            case let .flag(true, value), let .otherFlag(false, value), let .optional(nil, value): print(value)
            case .flag, .otherFlag, .optional: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case flag(Bool, Int), otherFlag(Bool, Int), optional(Int?, Int) }
        """)
    }

    func testNestedTypeShadowsGlobalEnum() throws {
        let input = """
        struct Container {
            enum State { case idle, failed }
            func render(_ state: State) {
                switch state {
                case .idle: first()
                default: fallback()
                }
            }
        }
        """
        let output = """
        struct Container {
            enum State { case idle, failed }
            func render(_ state: State) {
                switch state {
                case .idle: first()
                case .failed: fallback()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        """)
    }

    func testTypeAliasAndGenericShadowsArePreserved() throws {
        let input = """
        struct Container {
            typealias State = External
            func render(_ state: State) {
                switch state {
                default: fallback()
                }
            }
        }
        func render<State>(_ value: State) {
            switch value {
            default: fallback()
            }
        }
        """
        try check(input)
    }

    func testDefaultOnlySwitchEnumeratesAllCases() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State) {
            switch state {
            case .idle, .loaded, .failed: fallback()
            }
        }
        """
        try check(input, output)
    }

    func testConditionalAndAvailableEnumDeclarationsArePreserved() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle: first()
            default: fallback()
            }
        }
        """
        try check(input, declarations: """
        #if DEBUG
        enum State { case idle, loaded }
        #endif
        """)
        try check(input, declarations: """
        @available(iOS 100, *)
        enum State { case idle, loaded }
        """)
    }

    func testCasesMustAgreeAcrossEveryContainingModule() {
        let fileURL = URL(fileURLWithPath: "/Project/Calls.swift")
        func project(second: String?, modules: Set<String> = ["App", "Other"]) -> ProjectIndex {
            var files = [
                fileURL.path: makeSourceFileIndex(from: "", moduleIdentifiers: modules),
                "/Project/First.swift": makeSourceFileIndex(
                    from: "enum State { case idle, loaded }", moduleIdentifiers: ["App"]
                ),
            ]
            if let second {
                files["/Project/Second.swift"] = makeSourceFileIndex(from: second, moduleIdentifiers: ["Other"])
            }
            return ProjectIndex(files: files)
        }
        XCTAssertEqual(
            project(second: "enum State { case idle, loaded }").enumCases(named: "State", visibleFrom: fileURL),
            ["idle", "loaded"]
        )
        XCTAssertNil(project(second: "enum State { case idle, failed }").enumCases(named: "State", visibleFrom: fileURL))
        XCTAssertNil(project(second: nil).enumCases(named: "State", visibleFrom: fileURL))
        XCTAssertNil(project(second: nil, modules: []).enumCases(named: "State", visibleFrom: fileURL))
    }

    func testEnumCaseOrderSurvivesPersistentIndexRoundTrip() throws {
        let source = """
        enum State { case idle, loaded(String), failed }
        """
        let index = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"])
        let decoded = try JSONDecoder().decode(SourceFileIndex.self, from: JSONEncoder().encode(index))
        XCTAssertEqual(decoded.typeDeclarations.first?.enumCases, ["idle", "loaded", "failed"])
    }

    func testFilePrivateEnumsAreOnlyUsedInTheirOwnFile() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle: first()
            default: fallback()
            }
        }
        """
        try check(input, declarations: """
        private enum State { case idle, loaded }
        """)
        let localInput = """
        private enum State { case idle, loaded }
        func render(_ state: State) {
            switch state {
            case .idle: first()
            default: fallback()
            }
        }
        """
        let localOutput = """
        private enum State { case idle, loaded }
        func render(_ state: State) {
            switch state {
            case .idle: first()
            case .loaded: fallback()
            }
        }
        """
        try check(localInput, localOutput, declarations: "")
    }

    func testBindingTypeIsResolvedWhereItWasDeclared() throws {
        let input = """
        enum State { case idle, loaded }
        let state: State = .loaded
        struct Container {
            enum State { case idle, failed }
            func render() {
                switch state {
                default: print(state)
                }
            }
        }
        """
        let output = """
        enum State { case idle, loaded }
        let state: State = .loaded
        struct Container {
            enum State { case idle, failed }
            func render() {
                switch state {
                case .idle, .loaded: print(state)
                }
            }
        }
        """
        try check(input, output, declarations: "")
    }

    func testOverloadedEnumCaseNamesPreserveDefault() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .idle: first()
            default: fallback()
            }
        }
        """
        try check(input, declarations: """
        enum State { case foo(x: Int), foo(y: String), idle }
        """)
    }

    func testInheritedNestedTypeDoesNotResolveToGlobalEnum() throws {
        let input = """
        enum State { case idle, loaded }
        class Base {
            enum State { case idle, failed }
        }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                case .idle: first()
                default: fallback()
                }
            }
        }
        """
        try check(input, declarations: "")
    }

    private func check(
        _ input: String, _ output: String? = nil,
        declarations: String = "enum State { case idle, loaded, failed }",
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        _ = FormatRules.all
        let fileURL = URL(fileURLWithPath: "/Project/Calls.swift")
        let project = ProjectIndex(files: [
            fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
            "/Project/State.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.exhaustiveSwitchStatements], to: tokenize(input), with: .default,
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output ?? input, file: file, line: line)
        let second = try applyRules(
            [.exhaustiveSwitchStatements], to: result.tokens, with: .default,
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: second.tokens), output ?? input, file: file, line: line)
    }
}
