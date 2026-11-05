//
//  ProjectSymbolLookupTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/05/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ProjectSymbolLookupTests: XCTestCase {
    func testEachPatternConditionUsesItsOwnSubject() throws {
        try check("""
        func render(_ first: First, _ second: Second) {
            if case .value(let a) = first, case .value(let b) = second {
                observeValue(b)
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        enum First { case value(State) }
        enum Second { case value(Other) }
        """, expected: "Other")
    }

    func testCrossFileGenericPropertyThroughAlias() throws {
        try check("""
        func render(_ model: Box<Phase>) {
            observeValue(model.value)
        }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Phase = State
        struct Box<Value> { let value: Value }
        """, expected: "State")
    }

    func testConformanceWithoutAssociatedTypeDoesNotBlockGlobalName() throws {
        try check("""
        class Renderer: Rendering {
            func render(_ state: State) { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Rendering: AnyObject {}
        """, expected: "State")
    }

    func testInheritedNestedNameTakesPrecedenceOverGlobalType() throws {
        try check("""
        class Renderer: Base {
            func render(_ state: State) { observeValue(state) }
        }
        """, declarations: """
        enum State { case unrelated }
        class Base { enum State { case idle, loaded } }
        """, expected: "Base.State")
    }

    func testAssociatedTypeDoesNotResolveToUnrelatedGlobalType() throws {
        try check("""
        extension Rendering {
            func render(_ state: State) { observeValue(state) }
        }
        """, declarations: """
        enum State { case unrelated }
        protocol Rendering { associatedtype State }
        """, expected: nil)
    }

    func testUnknownInheritanceDoesNotResolveToGlobalType() throws {
        try check("""
        class Renderer: ExternalBase {
            func render(_ state: State) { observeValue(state) }
        }
        """, declarations: """
        enum State { case unrelated }
        """, expected: nil)
    }

    func testGenericParameterInAnotherScopeDoesNotHideType() throws {
        try check("""
        func unrelated<State>(_ value: State) {}
        func render(_ state: State) { observeValue(state) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testGenericParameterDoesNotResolveToGlobalType() throws {
        try check("""
        func render<State>(_ state: State) { observeValue(state) }
        """, declarations: """
        enum State { case unrelated }
        """, expected: nil)
    }

    func testRecursiveAliasesTerminate() throws {
        try check("""
        func render(_ state: A) { observeValue(state) }
        """, declarations: """
        typealias A = B
        typealias B = A
        """, expected: nil)
    }

    func testImportedModuleIgnoresUnimportedNamesakes() throws {
        try checkModules("""
        import Domain
        func render(_ state: State) { observeValue(state) }
        """, sources: [
            "Domain": """
            public enum State { case idle, loaded }
            """,
            "Unrelated": """
            public enum State { case unrelated }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testCurrentModuleTypeTakesPrecedenceOverImport() throws {
        try checkModules("""
        import Domain
        enum State { case local }
        func render(_ state: State) { observeValue(state) }
        """, sources: ["Domain": """
        public enum State { case imported }
        """], expectedCases: ["local"])
    }

    func testTwoImportedTypesAreAmbiguous() throws {
        try checkModules("""
        import Domain
        import Other
        func render(_ state: State) { observeValue(state) }
        """, sources: [
            "Domain": """
            public enum State { case first }
            """,
            "Other": """
            public enum State { case second }
            """,
        ], expectedCases: nil)
    }

    func testPropertyAnnotationUsesDeclaringFileImports() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: [
            "Models": """
            import Domain
            public struct Model { public let state: State }
            """,
            "Domain": """
            public enum State { case idle, loaded }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testImportedProtocolAliasDoesNotBlockUnrelatedTypeName() throws {
        try checkModules("""
        import Contracts
        enum State { case idle, loaded }
        struct Renderer: Rendering {
            typealias Content = Int
            func render(_ state: State) { observeValue(state) }
        }
        """, sources: ["Contracts": """
        public typealias Rendering = RenderingProtocol
        public protocol RenderingProtocol { associatedtype Content }
        """], expectedCases: ["idle", "loaded"])
    }

    func testFunctionReturnAnnotationUsesDeclaringFileImports() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ model: Model) { observeValue(model.readState()) }
        """, sources: [
            "Models": """
            import Domain
            public struct Model { public func readState() -> State { .idle } }
            """,
            "Domain": """
            public enum State { case idle, loaded }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testReexportedImportsExposeTypesAndProtocolAliases() throws {
        try checkModules("""
        import Facade
        struct Renderer: Rendering {
            typealias Content = Int
            func render(_ state: State) { observeValue(state) }
        }
        """, sources: [
            "Facade": """
            @_exported import Domain
            """,
            "Domain": """
            public typealias Rendering = RenderingProtocol
            public protocol RenderingProtocol { associatedtype Content }
            public enum State { case idle, loaded }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testCapturedValueResolvesInTheOuterScope() throws {
        try check("""
        func render(_ state: State) {
            let callback = { [state] in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testRenamedCaptureResolvesItsInitializerWithoutShadowingOuterNames() throws {
        try check("""
        func render(_ model: Model) {
            let callback = { [model = model.state] in observeValue(model) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testOptionalChainCanBeUnwrappedIntoAnIndexedType() throws {
        try check("""
        func render(_ model: Model?) {
            if let state = model?.state { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testImplicitlyUnwrappedReceiverResolvesIndexedMembers() throws {
        try check("""
        func render(_ model: Model!) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testForceUnwrapWithinOptionalChainDoesNotRemoveTheChainsOptionality() throws {
        try check("""
        func render(_ model: Model?) { observeValue(model?.state!) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State? }
        """, expected: "State", expectedOptional: true)
    }

    func testForceUnwrapOfParenthesizedOptionalChainRemovesOptionality() throws {
        try check("""
        func render(_ model: Model?) { observeValue((model?.state)!) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State? }
        """, expected: "State")
    }

    func testCaptureNamedSafeDoesNotRebindAnInitializerReference() throws {
        try check("""
        func render(_ model: Model) {
            let callback = { [safe = model.state] in observeValue(model) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "Model")
    }

    func testWeakCaptureRetainsOptionalityUntilUnwrapped() throws {
        try check("""
        func render(_ model: Model) {
            let callback = { [weak model] in
                if let state = model?.state { observeValue(state) }
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        final class Model {
            let state: State
            init(state: State) { self.state = state }
        }
        """, expected: "State")
    }

    func testWeakSelfCanBeUnwrappedIntoAnotherBinding() throws {
        try check("""
        final class Renderer {
            func render() {
                let callback = { [weak self] in
                    if let owner = self { observeValue(owner) }
                }
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "Renderer")
    }

    func testOptionalBindingAnnotationDescribesTheBoundValue() throws {
        try check("""
        func render(_ source: State??) {
            if let state: State? = source { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testGenericEnumPayloadBindingResolvesInTheUseSiteModule() throws {
        try check("""
        func render(_ event: Event<State>) {
            if case .value(let state) = event { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Event<Value> { case value(Value), finished }
        """, expected: "State")
    }

    func testSwitchPatternUsesTheCorrectAssociatedValuePosition() throws {
        try check("""
        func render(_ event: Event) {
            switch event {
            case let .value(_, state): observeValue(state)
            case .finished: break
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Event { case value(Int, State), finished }
        """, expected: "State")
    }

    func testConditionalCastProvesTypeWithoutResolvingTheOperand() throws {
        try check("""
        func render(_ object: Any) {
            if let state = object as? State { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testCallbackParameterInferredFromAnIndexedFunction() throws {
        try check("""
        func render() {
            observe { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        func observe(_ callback: (State) -> Void) {}
        """, expected: "State")
    }

    func testCallbackParameterInferredThroughGenericReceiver() throws {
        try check("""
        func render(_ source: Source<State>) {
            source.observe { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        final class Source<Value> { func observe(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testCallbackParameterInferredFromGenericFunctionInput() throws {
        try check("""
        func render(_ state: State) {
            observe(initial: state) { value in observeValue(value) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        func observe<Value>(initial: Value, callback: (Value) -> Void) {}
        """, expected: "State")
    }

    func testAmbiguousCallbackSignaturesDoNotInferAParameterType() throws {
        try check("""
        func render() {
            observe { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case other }
        func observe(_ callback: (State) -> Void) {}
        func observe(_ callback: (Other) -> Void) {}
        """, expected: nil)
    }

    func testGenericMethodReturnPreservesReceiverTypeArguments() throws {
        try check("""
        func render(_ source: Source<State>) { observeValue(source.read()) }
        """, declarations: """
        enum State { case idle, loaded }
        final class Source<Value> { func read() -> Value { fatalError() } }
        """, expected: "State")
    }

    func testPrivateCallbackDeclarationInTheSameFileIsAvailable() throws {
        try check("""
        enum State { case idle, loaded }
        private func observe(_ callback: (State) -> Void) {}
        func render() { observe { state in observeValue(state) } }
        """, declarations: """
        struct Unrelated {}
        """, expected: "State")
    }

    func testPrivateImportedFunctionIsNotUsedForReturnInference() throws {
        try checkModules("""
        import Domain
        func render() { observeValue(readState()) }
        """, sources: ["Domain": """
        public enum State { case idle, loaded }
        private func readState() -> State { .idle }
        """], expectedCases: nil)
    }

    func testCastInOnlyOneCoalescingOperandDoesNotDetermineTheExpressionType() throws {
        try check("""
        func render(_ value: Any?, _ fallback: Any) {
            observeValue(value ?? fallback as! State)
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testMethodGenericParameterShadowsTheReceiversGenericParameter() throws {
        try check("""
        func render(_ box: Box<State>, _ other: Other) { observeValue(box.load(other)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case other }
        struct Box<T> { func load<T>(_ value: T) -> T { value } }
        """, expected: "Other")
    }

    func testNestedAliasRetainsTheReceiversGenericArguments() throws {
        try check("""
        func render(_ source: Source<State>) { observeValue(source.read()) }
        """, declarations: """
        enum Value { case unrelated }
        enum State { case idle }
        struct Source<Value> {
            typealias Output = Value
            func read() -> Output { fatalError() }
        }
        """, expected: "State")
    }

    func testConstrainedExtensionDoesNotSupplyAnInapplicableCallbackType() throws {
        try check("""
        func render(_ source: Source<Other>) {
            source.observe { value in observeValue(value) }
        }
        """, declarations: """
        enum State { case idle }
        enum Other { case other }
        protocol P {}
        extension P { func observe(_ callback: (Other) -> Void) {} }
        struct Source<Value>: P {}
        extension Source where Value == State { func observe(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testInheritedOverloadCannotBeSelectedByArgumentLabelsAlone() throws {
        try check("""
        func render(_ child: Child) { observeValue(child.read(1)) }
        """, declarations: """
        enum State { case idle }
        enum Other { case other }
        class Base { func read(_ value: Int) -> Other { .other } }
        class Child: Base { func read(_ value: String) -> State { .idle } }
        """, expected: nil)
    }

    func testGlobalAliasDoesNotCaptureTheReceiversGenericArguments() throws {
        try check("""
        func render(_ source: Source<State>) { observeValue(source.read()) }
        """, declarations: """
        enum Value { case global }
        enum State { case idle }
        typealias Output = Value
        struct Source<Value> { func read() -> Output { fatalError() } }
        """, expected: "Value")
    }

    func testSeparateConditionalBindingsRetainTheirOwnInitializers() throws {
        try check("""
        func render(_ first: State?, _ second: Other?) {
            guard let a = first, let b = second else { return }
            observeValue(b)
        }
        """, declarations: """
        enum State { case idle }
        enum Other { case other }
        """, expected: "Other")
    }

    func testRecursiveGenericInitializerTerminates() throws {
        try check("""
        func render() {
            let value = identity(value)
            observeValue(value)
        }
        """, declarations: """
        func identity<Value>(_ value: Value) -> Value { value }
        """, expected: nil)
    }

    func testGenericPayloadBindingRetainsTheUseSiteModule() throws {
        try checkModules("""
        import Domain
        enum State { case local }
        func render(_ event: Event<State>) {
            if case .value(let state) = event { observeValue(state) }
        }
        """, sources: ["Domain": """
        public enum State { case imported }
        public enum Event<Value> { case value(Value), finished }
        """], expectedCases: ["local"])
    }

    func testGenericCallbackBindingRetainsTheUseSiteModule() throws {
        try checkModules("""
        import Domain
        enum State { case local }
        func render(_ source: Source<State>) {
            source.observe { state in observeValue(state) }
        }
        """, sources: ["Domain": """
        public enum State { case imported }
        public struct Source<Value> { public func observe(_ callback: (Value) -> Void) {} }
        """], expectedCases: ["local"])
    }

    func testConstrainedOverloadDoesNotExposeTheUnconstrainedReturnType() throws {
        try check("""
        func render(_ source: Source<State>) { observeValue(source.read()) }
        """, declarations: """
        enum State { case idle }
        enum Other { case other }
        struct Source<Value> { func read() -> Other { .other } }
        extension Source where Value == State { func read() -> State { .idle } }
        """, expected: nil)
    }

    func testConstrainedPropertyDoesNotSupplyAnInapplicableType() throws {
        try check("""
        func render(_ source: Source<Other>) { observeValue(source.state) }
        """, declarations: """
        enum State { case idle }
        enum Other { case other }
        protocol P {}
        extension P { var state: Other { .other } }
        struct Source<Value>: P {}
        extension Source where Value == State { var state: State { .idle } }
        """, expected: nil)
    }

    func testNestedPatternDoesNotReadAnUnrelatedOuterCasePayload() throws {
        try check("""
        func render(_ event: Outer) {
            if case .wrapped(.value(let state)) = event { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle }
        enum Other { case other }
        enum Inner { case value(Other) }
        enum Outer { case wrapped(Inner), value(State) }
        """, expected: nil)
    }

    func testProtocolAlternativesWithNoMatchingAssociatedTypeDoNotHideGlobalTypes() throws {
        try checkModules("""
        import Framework
        struct Renderer: View {
            func render(_ state: State) { observeValue(state) }
        }
        enum State { case idle }
        """, sources: ["Framework": """
        #if compiler(>=5.3)
        public protocol View { associatedtype Body }
        #else
        public protocol View { associatedtype Body }
        #endif
        """], expectedCases: ["idle"])
    }

    func testAnyProtocolAlternativeWithMatchingAssociatedTypeBlocksGlobalLookup() throws {
        try checkModules("""
        import Framework
        enum State { case unrelated }
        struct Renderer: View {
            func render(_ state: State) { observeValue(state) }
        }
        """, sources: ["Framework": """
        #if compiler(>=5.3)
        public protocol View { associatedtype State }
        #else
        public protocol View { associatedtype Body }
        #endif
        """], expectedCases: nil)
    }

    func testConditionalAssociatedTypeBlocksAnUnrelatedGlobalType() throws {
        try check("""
        extension Rendering {
            func render(_ state: State) { observeValue(state) }
        }
        """, declarations: """
        enum State { case unrelated }
        protocol Rendering {
        #if FLAG
            associatedtype State
        #endif
        }
        """, expected: nil)
    }

    private func checkModules(_ input: String, sources: [String: String], expectedCases: [String]?,
                              file: StaticString = #filePath, line: UInt = #line) throws
    {
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        var files = [url.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"], moduleNames: ["App": "App"])]
        for (module, source) in sources {
            files["/Project/\(module).swift"] = makeSourceFileIndex(from: source, moduleIdentifiers: [module], moduleNames: [module: module])
        }
        let project = ProjectIndex(files: files)
        let formatter = Formatter(tokenize(input))
        let lookup = ProjectSymbolLookup(formatter: formatter, project: project, fileURL: url)
        let observe = try XCTUnwrap(formatter.tokens.firstIndex(of: .identifier("observeValue")), file: file, line: line)
        let open = try XCTUnwrap(formatter.index(of: .startOfScope("("), after: observe), file: file, line: line)
        let close = try XCTUnwrap(formatter.endOfScope(at: open), file: file, line: line)
        let type = lookup.expressionType(in: open + 1 ... close - 1)
        let cases = type.flatMap { type in
            lookup.qualifiedName(for: type).flatMap { project.enumCases(named: $0, visibleFrom: type.sourceFileURL ?? url) }
        }
        XCTAssertEqual(cases, expectedCases, file: file, line: line)
        formatter.clearDerivedCaches()
    }

    private func check(_ input: String, declarations: String, expected: String?, expectedOptional: Bool = false, file: StaticString = #filePath, line: UInt = #line) throws {
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        let project = ProjectIndex(files: [
            url.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
            "/Project/Declarations.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
        ])
        let formatter = Formatter(tokenize(input))
        let lookup = ProjectSymbolLookup(formatter: formatter, project: project, fileURL: url)
        let observeValue = try XCTUnwrap(formatter.tokens.firstIndex(of: .identifier("observeValue")), file: file, line: line)
        let open = try XCTUnwrap(formatter.index(of: .startOfScope("("), after: observeValue), file: file, line: line)
        let close = try XCTUnwrap(formatter.endOfScope(at: open), file: file, line: line)
        let type = lookup.expressionType(in: open + 1 ... close - 1)
        let resolved = expectedOptional ? type.flatMap { lookup.unwrapped($0) } : type
        if let expected {
            XCTAssertEqual(resolved.flatMap { lookup.qualifiedName(for: $0) }, expected, file: file, line: line)
        } else {
            XCTAssertNil(type, file: file, line: line)
        }
        formatter.clearDerivedCaches()
    }
}
