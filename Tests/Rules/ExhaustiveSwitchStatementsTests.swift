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

    func testOptionalEnumIsExpandedWhileUnknownAndShadowedBindingsArePreserved() throws {
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
        let output = """
        func render(_ state: State?) {
            switch state {
            case .idle?: first()
            case .some(.loaded), .some(.failed), nil: second()
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
        try check(input, output)
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

    func testInheritedNestedTypeResolvesToItsDeclaration() throws {
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
        let output = """
        enum State { case idle, loaded }
        class Base {
            enum State { case idle, failed }
        }
        class Child: Base {
            func render(_ state: State) {
                switch state {
                case .idle: first()
                case .failed: fallback()
                }
            }
        }
        """
        try check(input, output, declarations: "")
    }

    func testRepeatedParameterNamesUseTheirOwnScopes() throws {
        let input = """
        func first(_ state: State) {
            switch state {
            case .idle: first()
            default: fallback()
            }
        }
        func second(_ state: Other) {
            switch state {
            case .one: first()
            default: fallback()
            }
        }
        """
        let output = """
        func first(_ state: State) {
            switch state {
            case .idle: first()
            case .loaded, .failed: fallback()
            }
        }
        func second(_ state: Other) {
            switch state {
            case .one: first()
            case .two: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        enum Other { case one, two }
        """)
    }

    func testCrossFilePropertyChainAndInferredLocal() throws {
        let input = """
        func render(_ model: Model) {
            switch model.snapshot.state {
            case .idle: first()
            default: fallback()
            }
            let selected = model.snapshot.state
            switch selected {
            case .failed: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            switch model.snapshot.state {
            case .idle: first()
            case .loaded, .failed: fallback()
            }
            let selected = model.snapshot.state
            switch selected {
            case .failed: first()
            case .idle, .loaded: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Snapshot { let state: State }
        struct Model { let snapshot: Snapshot }
        """)
    }

    func testCrossFileFunctionAndMethodReturnTypes() throws {
        let input = """
        func render(_ model: Model) {
            switch loadState() {
            case .idle: first()
            default: fallback()
            }
            let selected = model.readState()
            switch selected {
            case .failed: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            switch loadState() {
            case .idle: first()
            case .loaded, .failed: fallback()
            }
            let selected = model.readState()
            switch selected {
            case .failed: first()
            case .idle, .loaded: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        func loadState() -> State { .idle }
        struct Model { func readState() -> State { .loaded } }
        """)
    }

    func testPropertyTypeUsesDeclaringNamespaceAcrossFiles() throws {
        let input = """
        func render(_ model: Model) {
            switch model.state {
            case .idle: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            switch model.state {
            case .idle: first()
            case .loaded: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, failed }
        struct Model {
            enum State { case idle, loaded }
            let state: State
        }
        """)
    }

    func testUnknownInnerBindingDoesNotHideOuterBindingAfterScope() throws {
        let input = """
        func render(_ state: State) {
            do {
                let state = unknown()
                switch state {
                default: fallback()
                }
            }
            switch state {
            case .idle: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State) {
            do {
                let state = unknown()
                switch state {
                default: fallback()
                }
            }
            switch state {
            case .idle: first()
            case .loaded, .failed: fallback()
            }
        }
        """
        try check(input, output)
    }

    func testOptionalCrossFilePropertiesAndCalls() throws {
        let input = """
        func render(_ model: Model) {
            switch model.state {
            case .idle?: first()
            default: fallback()
            }
            switch loadState() {
            case .idle?: first()
            default: fallback()
            }
        }
        func optional(_ model: Model?) {
            switch model?.state {
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            switch model.state {
            case .idle?: first()
            case .some(.loaded), nil: fallback()
            }
            switch loadState() {
            case .idle?: first()
            case .some(.loaded), nil: fallback()
            }
        }
        func optional(_ model: Model?) {
            switch model?.state {
            case _?, nil: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State? }
        func loadState() -> State? { nil }
        """)
    }

    func testOptionalBindingUnwrapsIndexedPropertyInItsScope() throws {
        let input = """
        func render(_ model: Model) {
            if let state = model.state {
                switch state {
                case .idle: first()
                default: fallback()
                }
            }
            switch model.state {
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            if let state = model.state {
                switch state {
                case .idle: first()
                case .loaded: fallback()
                }
            }
            switch model.state {
            case _?, nil: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State? }
        """)
    }

    func testRepeatedSelfSwitchesWithMultiplePayloads() throws {
        let input = """
        enum State {
            case stays(Int)
            case activity(Int, Int)
            var first: Int? {
                switch self {
                case .stays(let value): value
                default: nil
                }
            }
            var second: Int? {
                switch self {
                case .activity(let value, _): value
                default: nil
                }
            }
        }
        """
        let output = """
        enum State {
            case stays(Int)
            case activity(Int, Int)
            var first: Int? {
                switch self {
                case .stays(let value): value
                case .activity: nil
                }
            }
            var second: Int? {
                switch self {
                case .activity(let value, _): value
                case .stays: nil
                }
            }
        }
        """
        try check(input, output, declarations: "")
    }

    func testUnknownClosureArgumentOnlyShadowsInsideClosure() throws {
        let input = """
        func render(_ state: State) {
            items.forEach { state in
                switch state {
                default: fallback()
                }
            }
            switch state {
            case .idle: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State) {
            items.forEach { state in
                switch state {
                default: fallback()
                }
            }
            switch state {
            case .idle: first()
            case .loaded, .failed: fallback()
            }
        }
        """
        try check(input, output)
    }

    func testShadowedCallsPreserveDefaults() throws {
        let input = """
        func first() {
            let loadState = { Other.one }
            switch loadState() {
            case .one: break
            default: break
            }
        }
        func second() {
            func loadState() -> Other { .one }
            switch loadState() {
            case .one: break
            default: break
            }
        }
        """
        try check(input, declarations: """
        enum State { case idle, loaded, failed }
        enum Other { case one, two }
        func loadState() -> State { .idle }
        """)
    }

    func testStaticAndInstanceMembersResolveSeparately() throws {
        let input = """
        func render(_ model: Model) {
            switch Model.state {
            case .one: break
            default: break
            }
            switch model.readState() {
            case .idle: break
            default: break
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            switch Model.state {
            case .one: break
            case .two: break
            }
            switch model.readState() {
            case .idle: break
            case .loaded, .failed: break
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        enum Other { case one, two }
        struct Model {
            static let state: Other = .one
            func readState() -> State { .idle }
            static func readState() -> Other { .one }
        }
        """)
    }

    func testPatternBindingDoesNotInferTheContainerType() throws {
        let input = """
        func render(_ container: Container) {
            if case let .value(state) = container {
                switch state {
                case .one: break
                default: break
                }
            }
        }
        """
        let output = """
        func render(_ container: Container) {
            if case let .value(state) = container {
                switch state {
                case .one: break
                case .two: break
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum Other { case one, two }
        enum Container { case value(Other), empty }
        """)
    }

    func testLocalTypeShadowDoesNotResolveToIndexedEnum() throws {
        let input = """
        func render() {
            enum State { case one, two }
            let state: State = .one
            switch state {
            case .one: break
            default: break
            }
        }
        """
        try check(input)
    }

    func testAssociatedPatternAndCatchBindingsShadowOuterVariables() throws {
        let input = """
        func render(_ state: State, _ error: State, _ value: Wrapped) {
            switch value {
            case .item(let state):
                switch state {
                default: break
                }
            default: break
            }
            do { try perform() } catch {
                switch error {
                default: break
                }
            }
            switch state {
            default: break
            }
        }
        """
        let output = """
        func render(_ state: State, _ error: State, _ value: Wrapped) {
            switch value {
            case .item(let state):
                switch state {
                default: break
                }
            case .other: break
            }
            do { try perform() } catch {
                switch error {
                default: break
                }
            }
            switch state {
            case .idle, .loaded: break
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        enum Wrapped { case item(Int), other }
        """)
    }

    func testLocalBindingShadowsParameterInTheSameScope() throws {
        let input = """
        func render(_ state: State) {
            let state: Other = .one
            switch state {
            case .one: break
            default: break
            }
        }
        """
        let output = """
        func render(_ state: State) {
            let state: Other = .one
            switch state {
            case .one: break
            case .two: break
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        enum Other { case one, two }
        """)
    }

    func testIndexedMemberTakesPrecedenceOverFileGlobalBinding() throws {
        let input = """
        let state: State = .idle
        extension Model {
            func render() {
                switch state {
                case .one: break
                default: break
                }
            }
        }
        """
        let output = """
        let state: State = .idle
        extension Model {
            func render() {
                switch state {
                case .one: break
                case .two: break
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        enum Other { case one, two }
        struct Model { let state: Other }
        """)
    }

    func testIndexedFunctionValuedMemberShadowsGlobalFunction() throws {
        let input = """
        extension Model {
            func render() {
                switch loadState() {
                case .one: break
                default: break
                }
            }
        }
        """
        let output = """
        extension Model {
            func render() {
                switch loadState() {
                case .one: break
                case .two: break
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        enum Other { case one, two }
        struct Model { let loadState: () -> Other }
        func loadState() -> State { .idle }
        """)
    }

    func testMemberInAnyContainingModuleBlocksGlobalCallResolution() throws {
        let input = """
        extension Model {
            func render() {
                switch loadState() {
                default: break
                }
            }
        }
        """
        let fileURL = URL(fileURLWithPath: "/Project/Calls.swift")
        let project = ProjectIndex(files: [
            fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App", "Other"]),
            "/Project/Shared.swift": makeSourceFileIndex(from: """
            enum State { case idle, loaded }
            func loadState() -> State { .idle }
            """, moduleIdentifiers: ["App", "Other"]),
            "/Project/App.swift": makeSourceFileIndex(from: """
            struct Model { let loadState: () -> Int }
            """, moduleIdentifiers: ["App"]),
            "/Project/Other.swift": makeSourceFileIndex(from: """
            struct Model {}
            """, moduleIdentifiers: ["Other"]),
        ])
        let result = try applyRules(
            [.exhaustiveSwitchStatements], to: tokenize(input), with: .default,
            trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), input)
    }

    func testEscapedCaseDeclarationsMatchUnescapedPatterns() throws {
        let input = """
        func render(_ state: State) {
            switch state {
            case .switch: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State) {
            switch state {
            case .switch: first()
            case .`default`, .loaded: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case `switch`, `default`, loaded }
        """)
    }

    func testQualifiedCasePatternsOnInferredPropertyTypes() throws {
        let input = """
        func render(_ model: Model) {
            let state = model.state
            switch state {
            case Model.State.idle: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            let state = model.state
            switch state {
            case Model.State.idle: first()
            case .loaded: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        struct Model {
            enum State { case idle, loaded }
            let state: State
        }
        """)
    }

    func testQualifiedExpressionPatternDoesNotCoverAnUnrelatedEnumCase() throws {
        let input = """
        func render(_ model: Model) {
            let state = model.state
            switch state {
            case State.idle: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            let state = model.state
            switch state {
            case State.idle: first()
            case .idle, .loaded: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        struct Model {
            enum State { case idle, loaded }
            let state: State
        }
        struct State { static let idle = State() }
        func ~= (_ pattern: State, _ value: Model.State) -> Bool { false }
        """)
    }

    func testOptionalPatternsAndNilOnlySubtractTheCasesTheyCover() throws {
        let input = """
        func render(_ state: State?) {
            switch state {
            case .some(.idle), .loaded?: first()
            case nil: second()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State?) {
            switch state {
            case .some(.idle), .loaded?: first()
            case nil: second()
            case .some(.failed): fallback()
            }
        }
        """
        try check(input, output)
    }

    func testWholeOptionalPayloadLeavesOnlyNil() throws {
        let input = """
        func render(_ state: State?) {
            switch state {
            case .some(let value): print(value)
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State?) {
            switch state {
            case .some(let value): print(value)
            case nil: fallback()
            }
        }
        """
        try check(input, output)
    }

    func testOptionalEnumCaseNamedNoneDoesNotCollideWithOptionalNone() throws {
        let input = """
        func render(_ state: State?) {
            switch state {
            case .none: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State?) {
            switch state {
            case .none: first()
            case .some(.none), .some(.some), .some(.loaded): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case none, some, loaded }")
    }

    func testForceUnwrapWithinAndOutsideOptionalChain() throws {
        let input = """
        func render(_ model: Model?) {
            switch model?.state! {
            default: fallback()
            }
            switch (model?.state)! {
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ model: Model?) {
            switch model?.state! {
            case _?, nil: fallback()
            }
            switch (model?.state)! {
            case .idle, .loaded: fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State? }
        """)
    }

    func testExplicitOptionalBindingAnnotationsRetainNilCoverage() throws {
        for keyword in ["if", "while", "guard"] {
            let binding = keyword == "guard" ? "guard let state: State? = source else { return }" : "\(keyword) let state: State? = source {"
            let closing = keyword == "guard" ? "" : "}"
            let input = """
            func render(_ source: State??) {
                \(binding)
                switch state {
                case .idle: first()
                default: fallback()
                }
                \(closing)
            }
            """
            let output = """
            func render(_ source: State??) {
                \(binding)
                switch state {
                case .idle: first()
                case .some(.loaded), nil: fallback()
                }
                \(closing)
            }
            """
            try check(input, output, declarations: "enum State { case idle, loaded }")
        }
    }

    func testNestedSwitchResolvesGenericEnumPayloadFromAnotherFile() throws {
        let input = """
        func render(_ event: Event<State>) {
            switch event {
            case .value(let state):
                switch state {
                case .idle: first()
                default: fallback()
                }
            case .finished: break
            }
        }
        """
        let output = """
        func render(_ event: Event<State>) {
            switch event {
            case .value(let state):
                switch state {
                case .idle: first()
                case .loaded: fallback()
                }
            case .finished: break
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        enum Event<Value> { case value(Value), finished }
        """)
    }

    func testDefaultOnlyOptionalSwitchDoesNotExpandThousandsOfNestedPatterns() throws {
        let input = """
        func render(_ state: State?) {
            switch state {
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State?) {
            switch state {
            case _?, nil: fallback()
            }
        }
        """
        let cases = (0 ..< 1500).map { "value\($0)" }.joined(separator: ", ")
        try check(input, output, declarations: "enum State { case \(cases) }")
    }

    func testOptionalPatternsAvoidWrappedNoneAndSomeCollisions() throws {
        let input = """
        func render(_ state: State?) {
            switch state {
            case .loaded?: first()
            default: fallback()
            }
        }
        func renderAll(_ state: State?) {
            switch state {
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State?) {
            switch state {
            case .loaded?: first()
            case .some(.none), .some(.some), nil: fallback()
            }
        }
        func renderAll(_ state: State?) {
            switch state {
            case _?, nil: fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case none, some, loaded }")
    }

    func testNestedOptionalPatternsAvoidWrappedCaseNameCollisions() throws {
        let input = """
        func render(_ state: State??) {
            switch state {
            case nil: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State??) {
            switch state {
            case nil: first()
            case .some(.some(.none)), .some(.some(.some)), .some(.some(.loaded)), .some(nil): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case none, some, loaded }")
    }

    func testSDKEnumDefaultsRequireAFrozenDeclaration() throws {
        let input = """
        import SDK
        func render(_ value: State) {
            switch value {
            case .idle: first()
            default: fallback()
            }
        }
        func renderOptional(_ value: State?) {
            switch value {
            case .idle?: first()
            default: fallback()
            }
        }
        """
        let output = """
        import SDK
        func render(_ value: State) {
            switch value {
            case .idle: first()
            case .loaded: fallback()
            }
        }
        func renderOptional(_ value: State?) {
            switch value {
            case .idle?: first()
            case .some(.loaded), nil: fallback()
            }
        }
        """
        let url = URL(fileURLWithPath: "/Project/Calls.swift")
        for frozen in [false, true] {
            let index = makeSourceFileIndex(
                from: (frozen ? "@frozen " : "") + "public enum State { case idle, loaded }",
                moduleIdentifiers: ["SDK"], moduleNames: ["SDK": "SDK"], isSwiftInterface: true
            )
            let persisted = try JSONDecoder().decode(SourceFileIndex.self, from: JSONEncoder().encode(index))
            let project = ProjectIndex(files: [
                url.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
                "/SDK/SDK.swiftinterface": persisted,
            ])
            let result = try applyRules(
                [.exhaustiveSwitchStatements], to: tokenize(input), with: .default,
                trackChanges: false, range: nil,
                context: FormattingContext(currentFileURL: url, projectIndex: project)
            )
            XCTAssertEqual(sourceCode(for: result.tokens), frozen ? output : input)
        }
    }

    func testTupleOfCrossFileEnumsSubtractsWildcardsAndGroupedPatterns() throws {
        let input = """
        func render(_ state: State, _ mode: Mode) {
            switch (state, mode) {
            case (.idle, _), (.loaded, .first): first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ state: State, _ mode: Mode) {
            switch (state, mode) {
            case (.idle, _), (.loaded, .first): first()
            case (.loaded, .second): fallback()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        enum Mode { case first, second }
        """)
    }

    func testTupleSubtractsUnqualifiedEnumCaseInItsDeclarationScope() throws {
        let input = """
        extension State {
            static func same(_ lhs: State, _ rhs: State) -> Bool {
                switch (lhs, rhs) {
                case (.idle, idle), (.loaded, .loaded): true
                default: false
                }
            }
        }
        """
        let output = """
        extension State {
            static func same(_ lhs: State, _ rhs: State) -> Bool {
                switch (lhs, rhs) {
                case (.idle, idle), (.loaded, .loaded): true
                case (.idle, .loaded), (.loaded, .idle): false
                }
            }
        }
        """
        try check(input, output, declarations: "enum State: Equatable { case idle, loaded }")
    }

    func testTupleDoesNotSubtractLocalValueNamedAfterEnumCase() throws {
        let input = """
        extension State {
            static func same(_ lhs: State, _ rhs: State, idle: State) -> Bool {
                switch (lhs, rhs) {
                case (.idle, idle), (.loaded, .loaded): true
                default: false
                }
            }
        }
        """
        let output = """
        extension State {
            static func same(_ lhs: State, _ rhs: State, idle: State) -> Bool {
                switch (lhs, rhs) {
                case (.idle, idle), (.loaded, .loaded): true
                case (.idle, .idle), (.idle, .loaded), (.loaded, .idle): false
                }
            }
        }
        """
        try check(input, output, declarations: "enum State: Equatable { case idle, loaded }")
    }

    func testLocalFunctionNamedAfterEnumCaseDoesNotInferAnEnumSubject() throws {
        try check("""
        extension State {
            static func render() {
                func idle() {}
                let callback = idle
                switch callback {
                default: break
                }
            }
        }
        """, declarations: "enum State { case idle, loaded }")
    }

    func testEscapedParameterNamedAfterEnumCaseDoesNotInferAnEnumSubject() throws {
        try check("""
        extension State {
            static func render(_ `idle`: String) {
                switch `idle` {
                default: break
                }
            }
        }
        """, declarations: "enum State { case idle, loaded }")
    }

    func testInstanceMethodNamedAfterEnumCaseDoesNotInferAnEnumSubject() throws {
        try check("""
        extension State {
            func idle() -> String { "idle" }
            func render() {
                let callback = idle
                switch callback {
                default: break
                }
            }
        }
        """, declarations: "enum State { case idle, loaded }")
    }

    func testAssociatedValueCaseReferenceDoesNotInferAnEnumSubject() throws {
        try check("""
        extension State {
            static func render() {
                let constructor = loaded
                switch constructor {
                default: break
                }
            }
        }
        """, declarations: "enum State { case idle, loaded(Int) }")
    }

    func testEscapedLocalFunctionNamedAfterEnumCaseDoesNotInferAnEnumSubject() throws {
        try check("""
        extension State {
            static func render() {
                func `idle`() {}
                let callback = idle
                switch callback {
                default: break
                }
            }
        }
        """, declarations: "enum State { case idle, loaded }")
    }

    func testBareAssociatedValueCaseCoversItsWholePayload() throws {
        let input = """
        extension State {
            static func same(_ lhs: State, _ rhs: State) -> Bool {
                switch (lhs, rhs) {
                case (.error, error): true
                case (loaded(let left), loaded(let right)): left == right
                default: false
                }
            }
        }
        """
        let output = """
        extension State {
            static func same(_ lhs: State, _ rhs: State) -> Bool {
                switch (lhs, rhs) {
                case (.error, error): true
                case (loaded(let left), loaded(let right)): left == right
                case (.error, .loaded), (.loaded, .error): false
                }
            }
        }
        """
        try check(input, output, declarations: "enum State: Equatable { case error(Int), loaded(Int) }")
    }

    func testTuplePayloadPatternsKeepPartiallyMatchedCases() throws {
        let input = """
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            case let (.loaded(first), .loaded(second)): compare(first, second)
            case (.idle, .loaded(0)): special()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            case let (.loaded(first), .loaded(second)): compare(first, second)
            case (.idle, .loaded(0)): special()
            case (.idle, .idle), (.idle, .loaded), (.loaded, .idle): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case idle, loaded(Int) }")
    }

    func testTupleWhereClauseDoesNotCoverUnguardedValues() throws {
        let input = """
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            case (.idle, _) where allowed(): first()
            case (.loaded, .loaded): second()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            case (.idle, _) where allowed(): first()
            case (.loaded, .loaded): second()
            case (.idle, .idle), (.idle, .loaded), (.loaded, .idle): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case idle, loaded }")
    }

    func testTupleWithUnresolvedComponentRemainsUnchanged() throws {
        try check("""
        func render(_ state: State) {
            switch (state, opaque()) {
            case (.idle, _): first()
            default: fallback()
            }
        }
        """)
    }

    func testAliasedCallbackExpandsItsProjectEnum() throws {
        let input = """
        func render(_ model: Model) {
            model.observe { state in
                switch state {
                case .idle: first()
                default: fallback()
                }
            }
        }
        """
        let output = """
        func render(_ model: Model) {
            model.observe { state in
                switch state {
                case .idle: first()
                case .loaded: fallback()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        typealias Observer = (State) -> Void
        struct Model { func observe(_ callback: Observer) {} }
        """)
    }

    func testTupleOfOptionalEnumsSubtractsSomeAndNilPatterns() throws {
        let input = """
        func render(_ lhs: State?, _ rhs: State?) {
            switch (lhs, rhs) {
            case (.some(.idle), _): first()
            case (_, nil): second()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ lhs: State?, _ rhs: State?) {
            switch (lhs, rhs) {
            case (.some(.idle), _): first()
            case (_, nil): second()
            case (.some(.loaded), .some(.idle)), (.some(.loaded), .some(.loaded)), (nil, .some(.idle)), (nil, .some(.loaded)): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case idle, loaded }")
    }

    func testOptionalTuplePreservesNestedPayloadBindings() throws {
        let input = """
        func render(_ pair: (State, State)?) {
            switch pair {
            case let .some((.loaded(first), .loaded(second))): compare(first, second)
            case nil: empty()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ pair: (State, State)?) {
            switch pair {
            case let .some((.loaded(first), .loaded(second))): compare(first, second)
            case nil: empty()
            case .some((.idle, .idle)), .some((.idle, .loaded)), .some((.loaded, .idle)): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case idle, loaded(Int) }")
    }

    func testLargePartialOptionalSwitchUsesCompilerCheckableOuterCases() throws {
        let cases = (0 ..< 1500).map { "value\($0)" }.joined(separator: ", ")
        let declarations = """
        enum State { case \(cases) }
        """
        let input = """
        func render(_ value: State?) {
            switch value {
            case .value0: first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ value: State?) {
            switch value {
            case .value0: first()
            case _?, nil: fallback()
            }
        }
        """
        try check(input, output, declarations: declarations)
    }

    func testLargePartialOptionalSwitchKeepsPreviouslyCoveredNil() throws {
        let cases = (0 ..< 1500).map { "value\($0)" }.joined(separator: ", ")
        let declarations = """
        enum State { case \(cases) }
        """
        let input = """
        func render(_ value: State?) {
            switch value {
            case .value0: first()
            case nil: empty()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ value: State?) {
            switch value {
            case .value0: first()
            case nil: empty()
            case _?: fallback()
            }
        }
        """
        try check(input, output, declarations: declarations)
    }

    func testTupleWithEarlierPatternsPreservesCompilerRequiredDefault() throws {
        try check("""
        func compare(_ lhs: State, _ rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.a, .a), (.b, .b), (.c, .c), (.d, .d), (.e, .e), (.f, .f), (.g, .g), (.h, .h), (.i, .i): true
            default: false
            }
        }
        """, declarations: "enum State { case a, b, c, d, e, f, g, h, i }")
    }

    func testSixtyFourCellTupleWithEarlierPatternCanExpand() throws {
        let input = """
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            case (.a, _): first()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            case (.a, _): first()
            case (.b, .a), (.b, .b), (.b, .c), (.b, .d), (.b, .e), (.b, .f), (.b, .g), (.b, .h), (.c, .a), (.c, .b), (.c, .c), (.c, .d), (.c, .e), (.c, .f), (.c, .g), (.c, .h), (.d, .a), (.d, .b), (.d, .c), (.d, .d), (.d, .e), (.d, .f), (.d, .g), (.d, .h), (.e, .a), (.e, .b), (.e, .c), (.e, .d), (.e, .e), (.e, .f), (.e, .g), (.e, .h), (.f, .a), (.f, .b), (.f, .c), (.f, .d), (.f, .e), (.f, .f), (.f, .g), (.f, .h), (.g, .a), (.g, .b), (.g, .c), (.g, .d), (.g, .e), (.g, .f), (.g, .g), (.g, .h), (.h, .a), (.h, .b), (.h, .c), (.h, .d), (.h, .e), (.h, .f), (.h, .g), (.h, .h): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case a, b, c, d, e, f, g, h }")
    }

    func testLargerDefaultOnlyTupleCanStillExpand() throws {
        let input = """
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            case (.a, .a), (.a, .b), (.a, .c), (.a, .d), (.a, .e), (.a, .f), (.a, .g), (.a, .h), (.a, .i), (.b, .a), (.b, .b), (.b, .c), (.b, .d), (.b, .e), (.b, .f), (.b, .g), (.b, .h), (.b, .i), (.c, .a), (.c, .b), (.c, .c), (.c, .d), (.c, .e), (.c, .f), (.c, .g), (.c, .h), (.c, .i), (.d, .a), (.d, .b), (.d, .c), (.d, .d), (.d, .e), (.d, .f), (.d, .g), (.d, .h), (.d, .i), (.e, .a), (.e, .b), (.e, .c), (.e, .d), (.e, .e), (.e, .f), (.e, .g), (.e, .h), (.e, .i), (.f, .a), (.f, .b), (.f, .c), (.f, .d), (.f, .e), (.f, .f), (.f, .g), (.f, .h), (.f, .i), (.g, .a), (.g, .b), (.g, .c), (.g, .d), (.g, .e), (.g, .f), (.g, .g), (.g, .h), (.g, .i), (.h, .a), (.h, .b), (.h, .c), (.h, .d), (.h, .e), (.h, .f), (.h, .g), (.h, .h), (.h, .i), (.i, .a), (.i, .b), (.i, .c), (.i, .d), (.i, .e), (.i, .f), (.i, .g), (.i, .h), (.i, .i): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case a, b, c, d, e, f, g, h, i }")
    }

    func testLargeTupleProductPreservesCompilerRequiredDefault() throws {
        let cases = (0 ..< 33).map { "value\($0)" }.joined(separator: ", ")
        let declarations = """
        enum State { case \(cases) }
        """
        try check("""
        func render(_ lhs: State, _ rhs: State) {
            switch (lhs, rhs) {
            default: fallback()
            }
        }
        """, declarations: declarations)
    }

    func testLargeOptionalTupleProductUsesOuterOptionalCases() throws {
        let cases = (0 ..< 33).map { "value\($0)" }.joined(separator: ", ")
        let declarations = """
        enum State { case \(cases) }
        """
        let input = """
        func render(_ lhs: State?, _ rhs: State?) {
            switch (lhs, rhs) {
            case (.value0, _): first()
            case (nil, nil): empty()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ lhs: State?, _ rhs: State?) {
            switch (lhs, rhs) {
            case (.value0, _): first()
            case (nil, nil): empty()
            case (_?, _?), (_?, nil), (nil, _?): fallback()
            }
        }
        """
        try check(input, output, declarations: declarations)
    }

    func testNestedOptionalInnerNilIsSubtracted() throws {
        let input = """
        func render(_ value: State??) {
            switch value {
            case .some(nil): innerNil()
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ value: State??) {
            switch value {
            case .some(nil): innerNil()
            case .some(.some(.idle)), .some(.some(.loaded)), nil: fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case idle, loaded }")
    }

    func testHighArityTuplePreservesCompilerRequiredDefault() throws {
        try check("""
        func render(_ a: State, _ b: State, _ c: State, _ d: State, _ e: State, _ f: State, _ g: State, _ h: State, _ i: State) {
            switch (a, b, c, d, e, f, g, h, i) {
            default: fallback()
            }
        }
        """, declarations: "enum State { case idle, loaded }")
    }

    func testNestedOptionalTupleCompactsBeforeCompilerBudgetIsExceeded() throws {
        let input = """
        func render(_ a: State???, _ b: State???, _ c: State???, _ d: State???) {
            switch (a, b, c, d) {
            default: fallback()
            }
        }
        """
        let output = """
        func render(_ a: State???, _ b: State???, _ c: State???, _ d: State???) {
            switch (a, b, c, d) {
            case (_?, _?, _?, _?), (_?, _?, _?, nil), (_?, _?, nil, _?), (_?, _?, nil, nil), (_?, nil, _?, _?), (_?, nil, _?, nil), (_?, nil, nil, _?), (_?, nil, nil, nil), (nil, _?, _?, _?), (nil, _?, _?, nil), (nil, _?, nil, _?), (nil, _?, nil, nil), (nil, nil, _?, _?), (nil, nil, _?, nil), (nil, nil, nil, _?), (nil, nil, nil, nil): fallback()
            }
        }
        """
        try check(input, output, declarations: "enum State { case idle }")
    }

    func testCollectionSubscriptUsesProjectElementEnum() throws {
        let input = """
        func render(_ states: [State]) {
            switch states[0] {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ states: [State]) {
            switch states[0] {
            case .loaded: showContent()
            case .idle, .failed: showPlaceholder()
            }
        }
        """
        try check(input, output)
    }

    func testDictionaryLookupEnumeratesMissingKeyAndValueCases() throws {
        let input = """
        func render(_ states: [String: State], key: String) {
            switch states[key] {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ states: [String: State], key: String) {
            switch states[key] {
            case .loaded: showContent()
            case .some(.idle), .some(.failed), nil: showPlaceholder()
            }
        }
        """
        try check(input, output)
    }

    func testLoopOverCrossFileCollectionElementProperty() throws {
        let input = """
        func render(_ models: [Model]) {
            for model in models {
                switch model.state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render(_ models: [Model]) {
            for model in models {
                switch model.state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Model { let state: State }
        """)
    }

    func testShorthandCollectionCallbackUsesProjectPropertyType() throws {
        let input = """
        func render(_ models: [Model]) {
            models.filter { $0.visible }.map {
                switch $0.state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render(_ models: [Model]) {
            models.filter { $0.visible }.map {
                switch $0.state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Model { let state: State; let visible: Bool }
        """)
    }

    func testDictionaryTupleClosureUsesValueEnum() throws {
        let input = """
        func render(_ states: [String: State]) {
            states.forEach { key, state in
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render(_ states: [String: State]) {
            states.forEach { key, state in
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output)
    }

    func testUnknownCollectionSubscriptDoesNotGuessFromCasePatterns() throws {
        try check("""
        func render(_ states: [State], index: ExternalIndex) {
            switch states[index] {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """)
    }

    func testDictionaryViewExtensionDoesNotAssumeBuiltinCallback() throws {
        try check("""
        func render(_ states: [String: State]) {
            states.values.map {
                switch $0 {
                case .idle: showIdle()
                default: showOther()
                }
            }
        }
        """, declarations: """
        enum State: Hashable { case idle, loaded }
        enum Other { case idle, unrelated }
        extension Dictionary.Values where Value == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        """)
    }

    func testCollectionProtocolExtensionDoesNotAssumeBuiltinCallback() throws {
        try check("""
        func render(_ states: [State]) {
            states.map {
                switch $0 {
                case .idle: showIdle()
                default: showOther()
                }
            }
        }
        """, declarations: """
        enum State: Hashable { case idle, loaded }
        enum Other { case idle, unrelated }
        protocol CustomSequence: Sequence {}
        extension Array: CustomSequence {}
        extension CustomSequence where Element == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        """)
    }

    func testSpecializedConstructorCallbackExpandsItsProjectEnum() throws {
        let input = """
        func render() {
            Handler<State> { state in
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render() {
            Handler<State> { state in
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """)
    }

    func testContextualInitializerCallbackExpandsItsProjectEnum() throws {
        let input = """
        func render() {
            let handler: Handler<State> = .init { state in
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render() {
            let handler: Handler<State> = .init { state in
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """)
    }

    func testIndexedCallContextSuppliesInitializerCallbackEnum() throws {
        let input = """
        func render() {
            consume(.init { state in
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            })
        }
        """
        let output = """
        func render() {
            consume(.init { state in
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            })
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        func consume(_ handler: Handler<State>) {}
        """)
    }

    func testGenericArrayFunctionResultExpandsProjectEnum() throws {
        let input = """
        func render(_ states: [State]) {
            switch select(states) {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ states: [State]) {
            switch select(states) {
            case .loaded: showContent()
            case .idle, .failed: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        func select<Value>(_ values: [Value]) -> Value { fatalError() }
        """)
    }

    func testGenericTupleAliasFunctionResultExpandsProjectEnum() throws {
        let input = """
        func render(_ pair: (Int, State)) {
            switch select(pair) {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ pair: (Int, State)) {
            switch select(pair) {
            case .loaded: showContent()
            case .idle, .failed: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        typealias Pair<Value> = (Int, Value)
        func select<Value>(_ pair: Pair<Value>) -> Value { fatalError() }
        """)
    }

    func testEnumeratedCollectionCallbackExpandsProjectEnum() throws {
        let input = """
        func render(_ states: [State]) {
            states.enumerated().forEach { _, state in
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render(_ states: [State]) {
            states.enumerated().forEach { _, state in
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        """)
    }

    func testReversedCollectionLoopExpandsProjectEnum() throws {
        let input = """
        func render(_ states: [State]) {
            for state in states.reversed() {
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render(_ states: [State]) {
            for state in states.reversed() {
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        """)
    }

    func testMappedProjectMemberExpandsOptionalEnumCases() throws {
        let input = """
        func render(_ models: [Model]) {
            switch models.map({ $0.state }).first {
            case .loaded?: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ models: [Model]) {
            switch models.map({ $0.state }).first {
            case .loaded?: showContent()
            case .some(.idle), .some(.failed), nil: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Model { let state: State }
        """)
    }

    func testCompactMappedProjectMemberExpandsOptionalEnumCases() throws {
        let input = """
        func render(_ models: [Model]) {
            switch models.compactMap({ $0.state }).first {
            case .loaded?: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ models: [Model]) {
            switch models.compactMap({ $0.state }).first {
            case .loaded?: showContent()
            case .some(.idle), .some(.failed), nil: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Model { let state: State? }
        """)
    }

    func testConstructorCallbackOverloadsPreserveDefault() throws {
        try check("""
        func render() {
            Handler { state in
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """, declarations: """
        enum State { case idle, loaded, failed }
        enum Other { case loaded, unrelated }
        struct Handler {
            init(_ callback: (State) -> Void) {}
            init(_ callback: (Other) -> Void) {}
        }
        """)
    }

    func testAnnotatedClosureVariableExpandsItsInputEnum() throws {
        let input = """
        func render() {
            let callback: (State) -> Void = { state in
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render() {
            let callback: (State) -> Void = { state in
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        """)
    }

    func testReturnedClosureExpandsItsInputEnum() throws {
        let input = """
        func render() -> (State) -> Void {
            { state in
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render() -> (State) -> Void {
            { state in
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        """)
    }

    func testCallableParameterResultExpandsProjectEnum() throws {
        let input = """
        func render(_ make: () -> State) {
            switch make() {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ make: () -> State) {
            switch make() {
            case .loaded: showContent()
            case .idle, .failed: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        """)
    }

    func testOptionalCallableResultIncludesNilPattern() throws {
        let input = """
        func render(_ make: (() -> State)?) {
            switch make?() {
            case .loaded?: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ make: (() -> State)?) {
            switch make?() {
            case .loaded?: showContent()
            case .some(.idle), .some(.failed), nil: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        """)
    }

    func testGenericCallablePropertyResultExpandsProjectEnum() throws {
        let input = """
        func render(_ model: Model<State>) {
            switch model.make() {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ model: Model<State>) {
            switch model.make() {
            case .loaded: showContent()
            case .idle, .failed: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Model<Value> { let make: () -> Value }
        """)
    }

    func testTernarySubjectUsesTheCommonProjectEnum() throws {
        let input = """
        func render(_ flag: Bool, _ state: State) {
            switch flag ? state : .idle {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ flag: Bool, _ state: State) {
            switch flag ? state : .idle {
            case .loaded: showContent()
            case .idle, .failed: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        """)
    }

    func testCoalescedSubjectUsesTheWrappedProjectEnum() throws {
        let input = """
        func render(_ state: State?) {
            switch state ?? .idle {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ state: State?) {
            switch state ?? .idle {
            case .loaded: showContent()
            case .idle, .failed: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        """)
    }

    func testKeyPathTransformExpandsItsOptionalProjectResult() throws {
        let input = """
        func render(_ models: [Model]) {
            switch models.map(\\.state).first {
            case .loaded?: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ models: [Model]) {
            switch models.map(\\.state).first {
            case .loaded?: showContent()
            case .some(.idle), .some(.failed), nil: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Model { let state: State }
        """)
    }

    func testCompactMapKeyPathRemovesOneOptionalLayer() throws {
        let input = """
        func render(_ models: [Model]) {
            switch models.compactMap(\\.state).first {
            case .loaded?: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ models: [Model]) {
            switch models.compactMap(\\.state).first {
            case .loaded?: showContent()
            case .some(.idle), .some(.failed), nil: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded, failed }
        struct Model { let state: State? }
        """)
    }

    func testLocalNominalShadowsCallableBindingDuringFormatting() throws {
        try check("""
        let make: () -> State = { .idle }
        func render() {
            struct make {}
            switch make() {
            case let value where isHandled(value): break
            default: break
            }
        }
        """, declarations: """
        enum State { case idle, loaded, failed }
        func isHandled<Value>(_ value: Value) -> Bool { false }
        """)
    }

    func testOperatorOverloadPreventsCoalescingSubjectExpansion() throws {
        try check("""
        func render(_ state: State?, _ fallback: State) {
            switch state ?? fallback {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """, declarations: """
        enum State { case idle, loaded, failed }
        enum Other { case loaded, unrelated }
        func ?? (_ lhs: State?, _ rhs: State) -> Other { .unrelated }
        """)
    }

    func testKeyPathTransformOverloadPreservesDefault() throws {
        try check("""
        func render(_ models: [Model]) {
            switch models.map(\\.state).first {
            case .loaded?: showContent()
            default: showPlaceholder()
            }
        }
        """, declarations: """
        enum State { case idle, loaded, failed }
        struct Model { let state: State }
        enum Other { case loaded, unrelated }
        extension Array where Element == Model {
            func map(_ keyPath: KeyPath<Model, State>) -> [Other] { [] }
        }
        """)
    }

    func testOptionalTryCoalescingRetainsThrownErrorNilCase() throws {
        let input = """
        func render() {
            switch try? make() ?? State.idle {
            case .loaded?: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render() {
            switch try? make() ?? State.idle {
            case .loaded?: showContent()
            case .some(.idle), nil: showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: """
        enum State { case idle, loaded }
        func make() throws -> State? { .loaded }
        """)
    }

    func testStandardResultSuccessBindingExpandsProjectEnum() throws {
        let input = """
        func render(_ result: Result<State, Error>) {
            if case let .success(state) = result {
                switch state {
                case .loaded: showContent()
                default: showPlaceholder()
                }
            }
        }
        """
        let output = """
        func render(_ result: Result<State, Error>) {
            if case let .success(state) = result {
                switch state {
                case .loaded: showContent()
                case .idle, .failed: showPlaceholder()
                }
            }
        }
        """
        try check(input, output)
    }

    func testStandardResultGetExpandsProjectEnumAndThrownErrorNil() throws {
        let input = """
        func render(_ result: Result<State, Error>) {
            switch try? result.get() {
            case .loaded?: showContent()
            default: showPlaceholder()
            }
        }
        """
        let output = """
        func render(_ result: Result<State, Error>) {
            switch try? result.get() {
            case .loaded?: showContent()
            case .some(.idle), .some(.failed), nil: showPlaceholder()
            }
        }
        """
        try check(input, output)
    }

    func testStandardResultGetOverloadPreservesDefault() throws {
        try check("""
        func render(_ result: Result<State, Error>) throws {
            switch try result.get() {
            case .loaded: showContent()
            default: showPlaceholder()
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case loaded, unrelated }
        extension Result where Success == State {
            func get() -> Other { .unrelated }
        }
        """)
    }

    func testTransitiveExtensionResultExpandsProjectEnum() throws {
        let input = """
        import Facade
        func render() {
            switch makeModel().state() {
            case .loaded:
                showContent()
            default:
                showPlaceholder()
            }
        }
        """
        let output = """
        import Facade
        func render() {
            switch makeModel().state() {
            case .loaded:
                showContent()
            case .idle, .failed:
                showPlaceholder()
            }
        }
        """
        try check(input, output, declarations: "enum State { case unrelated }", modules: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded, failed }
            extension Model { public func state() -> State { .idle } }
            """,
            "Facade": """
            import Models
            import Adapters
            public func makeModel() -> Model { fatalError() }
            """,
        ])
    }

    private func check(
        _ input: String, _ output: String? = nil,
        declarations: String = "enum State { case idle, loaded, failed }",
        modules: [String: String] = [:],
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        _ = FormatRules.all
        let fileURL = URL(fileURLWithPath: "/Project/Calls.swift")
        var files = [
            fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
            "/Project/State.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
        ]
        for (module, source) in modules {
            files["/Project/\(module).swift"] = makeSourceFileIndex(from: source, moduleIdentifiers: [module], moduleNames: [module: module])
        }
        let project = ProjectIndex(files: files)
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
