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

    func testCovariantInputDoesNotFixAContextualCallbackParameter() throws {
        try check("""
        func render(_ state: State) {
            observe(initial: state) { value in observeValue(value) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        func observe<Value>(initial: Value, callback: (Value) -> Void) {}
        """, expected: nil)
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
        """, expected: "Other")
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

    func testLocalDeclarationInsideAGuardInitializerClosureKeepsItsOwnScope() throws {
        try check("""
        func render(_ state: State) {
            guard let current = ({ () -> State? in
                let value = state
                observeValue(value)
                return value
            })() else { return }
        }
        """, declarations: """
        enum State { case idle }
        """, expected: "State")
    }

    func testGuardPayloadBindingUsesTheEnclosingStatementScope() throws {
        try check("""
        func render(_ event: Event) {
            guard case .value(let state) = event else { return }
            observeValue(state)
        }
        """, declarations: """
        enum State { case idle }
        enum Event { case value(State), finished }
        """, expected: "State")
    }

    func testGenericArgumentCountDisambiguatesImportedNominalTypes() throws {
        try checkModules("""
        import Models
        import UI
        func render(_ state: State) { observeValue(state) }
        """, sources: [
            "Models": "public enum State { case idle, loaded }",
            "UI": "public struct State<Value> {}",
        ], expectedCases: ["idle", "loaded"])
    }

    func testGenericSpecializationSelectsTheGenericImportedDeclaration() throws {
        try checkModules("""
        import Models
        import UI
        enum Phase { case idle }
        func render(_ state: State<Phase>) { observeValue(state.value) }
        """, sources: [
            "Models": "public enum State { case unrelated }",
            "UI": "public struct State<Value> { public var value: Value }",
        ], expectedCases: ["idle"])
    }

    func testLocalGenericTypeStillShadowsAnImportedNongenericNamesake() throws {
        try checkModules("""
        import Models
        struct State<Value> {
            func render(_ state: State) { observeValue(state) }
        }
        """, sources: ["Models": "public enum State { case unrelated }"], expectedCases: nil)
    }

    func testCanonicalTypeDoesNotReapplyItsLexicalNamespace() throws {
        try checkModules("""
        enum State { case correct }
        struct Container {
            enum App { enum State { case wrong } }
            func render(_ value: State) { observeValue(value) }
        }
        """, sources: [:], expectedCases: ["correct"])
    }

    func testGenericArgumentCountDisambiguatesImportedAliases() throws {
        try checkModules("""
        import Models
        import UI
        func render(_ state: State) { observeValue(state) }
        """, sources: [
            "Models": "public enum Phase { case idle }; public typealias State = Phase",
            "UI": "public typealias State<Value> = Value",
        ], expectedCases: ["idle"])
    }

    func testVariableAnnotationAllowsInferredGenericArguments() throws {
        try checkModules("""
        import Models
        import UI
        func render() {
            let state: State = State(value: 1)
            observeValue(state)
        }
        """, sources: [
            "Models": "public enum State { case unrelated }",
            "UI": "public struct State<Value> { public let value: Value }",
        ], expectedCases: nil)
    }

    func testGuardBindingIsVisibleInsideALaterConditionClosure() throws {
        try checkModules("""
        enum Old { case old }
        enum New { case new }
        func render(_ value: Old, _ optional: New?) {
            guard let value = optional, ({
                let selected = value
                observeValue(selected)
                return true
            })() else { return }
        }
        """, sources: [:], expectedCases: ["new"])
    }

    func testGuardElseBodyUsesTheOuterBinding() throws {
        try checkModules("""
        enum Old { case old }
        enum New { case new }
        func render(_ value: Old, _ optional: New?) {
            guard let value = optional else {
                observeValue(value)
                return
            }
        }
        """, sources: [:], expectedCases: ["old"])
    }

    func testGuardInitializerUsesTheOuterBinding() throws {
        try checkModules("""
        enum State { case idle }
        func render(_ value: State?) {
            guard let value = ({
                observeValue(value!)
                return value
            })() else { return }
        }
        """, sources: [:], expectedCases: ["idle"])
    }

    func testIfBindingIsVisibleInsideALaterConditionClosure() throws {
        try checkModules("""
        enum Old { case old }
        enum New { case new }
        func render(_ value: Old, _ optional: New?) {
            if let value = optional, ({
                observeValue(value)
                return true
            })() {}
        }
        """, sources: [:], expectedCases: ["new"])
    }

    func testGuardPayloadBindingIsVisibleInALaterCondition() throws {
        try checkModules("""
        enum Old { case old }
        enum New { case new }
        enum Event { case value(New), finished }
        func render(_ value: Old, _ event: Event) {
            guard case .value(let value) = event, ({
                observeValue(value)
                return true
            })() else { return }
        }
        """, sources: [:], expectedCases: ["new"])
    }

    func testGenericParentArgumentsDoNotDisambiguateANestedType() throws {
        try checkModules("""
        import Models
        import UI
        func render(_ value: Outer<Int>.State) { observeValue(value) }
        """, sources: [
            "Models": "public enum Outer<T> { public enum State { case correct } }",
            "UI": "public enum Outer { public enum State<T> { case wrong } }",
        ], expectedCases: nil)
    }

    func testImportedCanonicalTypeKeepsItsDeclarationContext() throws {
        try checkModules("""
        import Other
        enum Other { enum State { case wrong } }
        func render(_ value: State) { observeValue(value) }
        """, sources: ["Other": "public enum State { case correct }"], expectedCases: ["correct"])
    }

    func testStandardLibraryModuleIsImplicitlyImported() throws {
        try checkModules("""
        func render(_ value: Result<Int, Never>) { observeValue(value) }
        """, sources: [
            "Swift": "public enum Result<Success, Failure> { case success(Success), failure(Failure) }",
        ], expectedCases: ["success", "failure"])
    }

    func testGuardPayloadElseBodyUsesTheOuterBinding() throws {
        try checkModules("""
        enum Old { case old }
        enum New { case new }
        enum Event { case value(New), finished }
        func render(_ value: Old, _ event: Event) {
            guard case .value(let value) = event else {
                observeValue(value)
                return
            }
        }
        """, sources: [:], expectedCases: ["old"])
    }

    func testConditionalDuplicateInheritedTypesDoNotRecurse() throws {
        try checkModules("""
        import Models
        enum State { case idle }
        struct Renderer: Base {
            func render(_ value: State) { observeValue(value) }
        }
        """, sources: ["Models": """
        #if FIRST
        public struct Base {}
        #else
        public struct Base {}
        #endif
        """], expectedCases: nil)
    }

    func testDeclaredPropertyOnADynamicMemberTypeUsesItsAnnotation() throws {
        try check("""
        func render(_ box: Box<State>) { observeValue(box.state) }
        """, declarations: """
        enum State { case idle }
        @dynamicMemberLookup
        struct Box<Value> {
            let state: Value
            subscript(dynamicMember name: String) -> Int { 0 }
        }
        """, expected: "State")
    }

    func testUndeclaredDynamicMemberDoesNotUseAGlobalNamesake() throws {
        try check("""
        func render(_ box: Box) { observeValue(box.state) }
        """, declarations: """
        enum State { case idle }
        let state: State = .idle
        @dynamicMemberLookup
        struct Box { subscript(dynamicMember name: String) -> Int { 0 } }
        """, expected: nil)
    }

    func testStandardAnyObjectAliasDoesNotBlockProjectTypeLookup() throws {
        try checkModules("""
        import Models
        final class Renderer: Service {
            func render(_ value: State) { observeValue(value) }
        }
        """, sources: [
            "Models": "public protocol Service: AnyObject {}; public enum State { case idle, loaded }",
            "Swift": "public typealias AnyObject = Builtin.AnyObject",
        ], expectedCases: ["idle", "loaded"])
    }

    func testAsyncThrowingProjectMethodRetainsItsDeclaredReturnType() throws {
        try check("""
        func render(_ model: Model) async throws {
            let state = try await model.load()
            observeValue(state)
        }
        """, declarations: """
        enum State { case idle }
        actor Model { func load() throws -> State { .idle } }
        """, expected: "State")
    }

    func testOptionalTryAddsOptionalityToAProjectEnumResult() throws {
        try check("""
        func render(_ model: Model) {
            let state = try? model.load()
            observeValue(state)
        }
        """, declarations: """
        enum State { case idle }
        struct Model { func load() throws -> State { .idle } }
        """, expected: "State", expectedOptional: true)
    }

    func testGenericProjectFunctionInfersAnOptionalArgument() throws {
        try check("""
        func render(_ source: State?) {
            let value = require(source)
            observeValue(value)
        }
        """, declarations: """
        enum State { case idle }
        func require<Value>(_ value: Value?) -> Value { value! }
        """, expected: "State")
    }

    func testGenericProjectFunctionInfersNestedReceiverArguments() throws {
        try check("""
        func render(_ source: Box<State>) {
            let value = read(source)
            observeValue(value)
        }
        """, declarations: """
        enum State { case idle }
        struct Box<Value> { let value: Value }
        func read<Value>(_ box: Box<Value>) -> Value { box.value }
        """, expected: "State")
    }

    func testGenericProjectAutoclosureInfersItsResultType() throws {
        try check("""
        func render(_ source: State?) {
            let value = require(source)
            observeValue(value)
        }
        """, declarations: """
        enum State { case idle }
        func require<Value>(_ value: @autoclosure () -> Value?) -> Value { value()! }
        """, expected: "State")
    }

    func testGenericProjectFunctionRejectsConflictingNestedArguments() throws {
        try check("""
        func render(_ first: Box<State>, _ second: Box<Other>) {
            let value = read(first, second)
            observeValue(value)
        }
        """, declarations: """
        enum State { case idle }
        enum Other { case unrelated }
        struct Box<Value> { let value: Value }
        func read<Value>(_ first: Box<Value>, _ second: Box<Value>) -> Value { first.value }
        """, expected: nil)
    }

    func testAnUnknownGenericArgumentCannotNarrowTheInferredResult() throws {
        try check("""
        func render(_ source: State?) {
            func opaque() -> Any { 0 }
            let value = choose(source, opaque())
            observeValue(value)
        }
        """, declarations: """
        enum State { case idle }
        func choose<Value>(_ first: Value?, _ second: Value) -> Value { second }
        """, expected: nil)
    }

    func testOptionalTryFlattensAProjectOptionalResultInSwift5AndLater() throws {
        try check("""
        func render(_ model: Model) {
            let state = try? model.load()
            observeValue(state)
        }
        """, declarations: """
        enum State { case idle }
        struct Model { func load() throws -> State? { .idle } }
        """, expected: "State", expectedOptional: true, options: FormatOptions(swiftVersion: "6"))
    }

    func testOptionalTryDoesNotAssumeFlatteningBeforeSwift5() throws {
        try check("""
        func render(_ model: Model) {
            let state = try? model.load()
            observeValue(state)
        }
        """, declarations: """
        enum State { case idle }
        struct Model { func load() throws -> State? { .idle } }
        """, expected: nil, options: FormatOptions(swiftVersion: "4.2"))
    }

    func testAnUnresolvedExpressionCannotNarrowAnotherGenericArgument() throws {
        try check("""
        func render(_ state: State, _ other: Any, _ flag: Bool) {
            let value = choose(state, flag ? state : other)
            observeValue(value)
        }
        """, declarations: """
        enum State { case idle }
        func choose<Value>(_ first: Value, _ second: Value) -> Value { first }
        """, expected: nil)
    }

    func testCallbackResultCannotWidenAContextualGenericParameterUnnoticed() throws {
        try check("""
        func render(_ source: State, _ other: Any) {
            transform(source) { value in
                observeValue(value)
                return other
            }
        }
        """, declarations: """
        enum State { case idle }
        func transform<Value>(_ initial: Value, _ callback: (Value) -> Value) {}
        """, expected: nil)
    }

    func testNestedPatternResolvesGenericProjectPayloads() throws {
        try check("""
        func render(_ event: Event<Result<State>>) {
            if case .wrapped(.success(let value)) = event { observeValue(value) }
        }
        """, declarations: """
        enum State { case idle }
        enum Result<Value> { case success(Value), failure }
        enum Event<Value> { case wrapped(Value), finished }
        """, expected: "State")
    }

    func testNestedPatternResolvesOptionalProjectPayloads() throws {
        try check("""
        func render(_ event: Event<State?>?) {
            if case .some(.value(.some(let value))) = event { observeValue(value) }
        }
        """, declarations: """
        enum State { case idle }
        enum Event<Value> { case value(Value), finished }
        """, expected: "State")
    }

    func testAssociatedTypeConstraintsDoNotHideAnUnrelatedProjectType() throws {
        try check("""
        struct Model: Service {
            typealias Input = Int
            func render(_ state: State) { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle }
        protocol Service where Input: Equatable { associatedtype Input }
        """, expected: "State")
    }

    func testSelfConstraintsCannotHideAnInheritedProjectTypeUnnoticed() throws {
        try check("""
        struct Model: Service {
            func render(_ state: State) { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle }
        protocol Parent { associatedtype State }
        protocol Service where Self: Parent {}
        """, expected: nil)
    }

    func testConstrainedProtocolAssociatedTypesStillShadowProjectTypes() throws {
        try check("""
        struct Model: Service {
            func render(_ state: State) { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle }
        protocol Service where State: Equatable { associatedtype State }
        """, expected: nil)
    }

    func testPostfixOptionalPatternResolvesAProjectPayload() throws {
        try check("""
        func render(_ event: Event?) {
            if case .value(let state)? = event { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle }
        enum Event { case value(State), finished }
        """, expected: "State")
    }

    func testPayloadCastPatternDoesNotKeepTheUncastType() throws {
        try check("""
        func render(_ event: Event) {
            if case .value(let value as State) = event { observeValue(value) }
        }
        """, declarations: """
        enum State { case idle }
        enum Event { case value(Any), finished }
        """, expected: nil)
    }

    func testInoutCallbackCannotNarrowAContextualGenericParameter() throws {
        try check("""
        func render(_ state: State) {
            mutate(state) { value in observeValue(value) }
        }
        """, declarations: """
        enum State { case idle }
        func mutate<Value>(_ initial: Value, _ callback: (inout Value) -> Void) {}
        """, expected: nil)
    }

    func testInvariantCallbackInputCannotNarrowAContextualGenericParameter() throws {
        try check("""
        func render(_ state: State) {
            observe(state) { box in observeValue(box.value) }
        }
        """, declarations: """
        enum State { case idle }
        struct Box<Value> { let value: Value }
        func observe<Value>(_ initial: Value, _ callback: (Box<Value>) -> Void) {}
        """, expected: nil)
    }

    func testInvariantProjectInputFixesAContextualCallbackParameter() throws {
        try check("""
        func render(_ source: Box<State>) {
            observe(initial: source) { value in observeValue(value) }
        }
        """, declarations: """
        enum State { case idle }
        struct Box<Value> { let value: Value }
        func observe<Value>(initial: Box<Value>, callback: (Value) -> Void) {}
        """, expected: "State")
    }

    func testCallbackTypeAliasResolvesItsDeclarationContext() throws {
        try check("""
        func render(_ model: Model) {
            model.observe { value in observeValue(value) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Observer = @Sendable (State) -> Void
        struct Model { func observe(_ callback: Observer) {} }
        """, expected: "State")
    }

    func testGenericCallbackTypeAliasSubstitutesNestedPayloads() throws {
        try check("""
        func render(_ model: Model<State>) {
            model.observe { event in
                if case .value(let value) = event { observeValue(value) }
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Event<Value> { case value(Value), finished }
        typealias Observer<Value> = (Event<Value>) -> Void
        struct Model<Value> { func observe(_ callback: Observer<Value>) {} }
        """, expected: "State")
    }

    func testCallbackAliasDoesNotResolveToAnUnrelatedCallerType() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ model: Model) {
            model.observe { value in observeValue(value) }
        }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public typealias Observer = (State) -> Void
            public struct Model { public func observe(_ callback: Observer) {} }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testCallbackAliasKeepsUnknownGenericParametersUnresolved() throws {
        try check("""
        func render() {
            observe { value in observeValue(value) }
        }
        """, declarations: """
        typealias Observer<Value> = (Value) -> Void
        func observe<Value>(_ callback: Observer<Value>) {}
        """, expected: nil)
    }

    func testTupleExpressionElementRetainsItsType() throws {
        try check("""
        func render(_ state: State, _ other: Other) {
            let pair = (other, state)
            observeValue(pair.1)
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testGenericLabeledTuplePropertySubstitutesSelectedElement() throws {
        try check("""
        func render(_ model: Model<State>) { observeValue(model.pair.current) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model<Value> { let pair: (previous: Value?, current: Value) }
        """, expected: "State")
    }

    func testTupleElementsDoNotGuessFromAnUnknownExpression() throws {
        try check("""
        func render(_ state: State) {
            let pair = (state, opaque())
            observeValue(pair.0)
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testEnumSelfAnnotationResolvesToItsDeclaration() throws {
        try check("""
        enum State {
            case idle, loaded
            func render(_ other: Self) { observeValue(other) }
        }
        """, declarations: "", expected: "State")
    }

    func testOptionalTuplePropertyPreservesProjectionOptionality() throws {
        try check("""
        func render(_ model: Model<State>) { observeValue(model.pair?.current) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model<Value> { let pair: (previous: Value?, current: Value)? }
        """, expected: "State", expectedOptional: true)
    }

    func testGroupedOptionalCallbackAliasResolvesParameter() throws {
        try check("""
        func render(_ model: Model) {
            model.observe { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Observer = ((State) -> Void)?
        struct Model { func observe(_ callback: Observer) {} }
        """, expected: "State")
    }

    func testInvariantGenericInputResolvesAliasedNestedCallbackParameter() throws {
        try check("""
        func render(_ source: Box<State>) {
            observe(initial: source) { box in observeValue(box.value) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Value> { let value: Value }
        typealias Observer<Value> = (Box<Value>) -> Void
        func observe<Value>(initial: Box<Value>, callback: Observer<Value>) {}
        """, expected: "State")
    }

    func testCovariantGenericInputDoesNotFixAliasedCallbackParameter() throws {
        try check("""
        func render(_ source: State) {
            observe(initial: source) { value in observeValue(value) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Observer<Value> = (Value) -> Void
        func observe<Value>(initial: Value, callback: Observer<Value>) {}
        """, expected: nil)
    }

    func testEnumSelfReturnRetainsItsDeclarationModule() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ value: Models.State) { observeValue(value.copy()) }
        """, sources: [
            "Models": """
            public enum State {
                case idle, loaded
                public func copy() -> Self { self }
            }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testExplicitConstructorResolvesInferredLocalReceiver() throws {
        try check("""
        func render() {
            let model = Model(dependencies: opaque())
            observeValue(model.state)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {
            init(dependencies: Any) {}
            var state: State { .idle }
        }
        """, expected: "State")
    }

    func testExplicitGenericConstructorPreservesTypeArguments() throws {
        try check("""
        func render() {
            let model = Model<State>()
            observeValue(model.state)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model<Value> {
            init() {}
            var state: Value { fatalError() }
        }
        """, expected: "State")
    }

    func testFailableConstructorRetainsOptionalResult() throws {
        try check("""
        func render() {
            let model = Model()
            observeValue(model?.state)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {
            init?() {}
            var state: State { .idle }
        }
        """, expected: "State", expectedOptional: true)
    }

    func testConstructorCannotIgnoreASameNamedFactoryOverload() throws {
        try checkModules("""
        import Models
        struct Other { var state: Int }
        func Model(_ value: Int) -> Other { fatalError() }
        func render() {
            let model = Model(opaque())
            observeValue(model.state)
        }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public struct Model {
                public init(_ value: String) {}
                public var state: State { .idle }
            }
            """,
        ], expectedCases: nil)
    }

    func testConstructorCannotIgnoreAmbiguousFailability() throws {
        try check("""
        func render() {
            let model = Model(opaque())
            observeValue(model.state)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {
            init(_ value: String) {}
            init?(_ value: Int) {}
            var state: State { .idle }
        }
        """, expected: nil)
    }

    func testConstructorAliasCannotIgnoreASameNamedFactoryOverload() throws {
        try checkModules("""
        import Models
        struct Other { var state: Int }
        func Alias(_ value: Int) -> Other { fatalError() }
        func render() {
            let model = Alias(opaque())
            observeValue(model.state)
        }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public struct Model {
                public init(_ value: String) {}
                public var state: State { .idle }
            }
            public typealias Alias = Model
            """,
        ], expectedCases: nil)
    }

    func testImportedAliasConstructorRetainsDeclarationContext() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render() {
            let model = Alias()
            observeValue(model.state)
        }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public struct Model {
                public init() {}
                public var state: State { .idle }
            }
            public typealias Alias = Model
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testConstructorCannotIgnoreUnknownInheritedFactory() throws {
        try check("""
        class Renderer: ExternalBase {
            func render() {
                let model = Model()
                observeValue(model.state)
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {
            init() {}
            var state: State { .idle }
        }
        """, expected: nil)
    }

    func testUnqualifiedEnumCaseInCrossFileExtension() throws {
        try check("""
        extension State {
            static func render() { observeValue(idle) }
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testUnqualifiedEnumCaseShadowsGlobalValue() throws {
        try check("""
        let idle: Other = .ready
        extension State {
            static func render() { observeValue(idle) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        """, expected: "State")
    }

    func testLocalFunctionShadowsUnqualifiedEnumCase() throws {
        try check("""
        extension State {
            static func render() {
                func idle() {}
                observeValue(idle)
            }
        }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testLocalTypeShadowsUnqualifiedEnumCase() throws {
        try check("""
        extension State {
            static func render() {
                struct idle {}
                observeValue(idle.self)
            }
        }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testInheritedInstancePropertyShadowsEnumCase() throws {
        try check("""
        extension State {
            func render() { observeValue(idle) }
        }
        """, declarations: """
        enum Other { case ready }
        protocol Rendering {}
        extension Rendering { var idle: Other { .ready } }
        enum State: Rendering { case idle, loaded }
        """, expected: nil)
    }

    func testAssociatedValueConstructorShadowsGlobalEnumValue() throws {
        try check("""
        let loaded: Other = .ready
        extension State {
            static func render() { observeValue(loaded) }
        }
        """, declarations: """
        enum State { case idle, loaded(Int) }
        enum Other { case ready }
        """, expected: nil)
    }

    func testLocalBindingShadowsUnqualifiedEnumCase() throws {
        try check("""
        extension State {
            static func render(_ idle: Other) { observeValue(idle) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        """, expected: "Other")
    }

    func testArrayAliasPreservesElementDeclarationContext() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ model: Model) { observeValue(model.states.first!) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public typealias States = [State]
        public struct Model { public let states: States }
        """], expectedCases: ["idle", "loaded"])
    }

    func testArraySubscriptResolvesCrossFileMember() throws {
        try check("""
        func render(_ models: [Model], _ index: Int) { observeValue(models[index].state) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testDictionaryLookupAddsOptionalToValue() throws {
        try check("""
        func render(_ states: [String: State], _ key: String) { observeValue(states[key]) }
        """, declarations: "enum State { case idle, loaded }", expected: "State", expectedOptional: true)
    }

    func testDictionaryDefaultSubscriptKeepsNonoptionalValue() throws {
        try check("""
        func render(_ states: [String: State], _ key: String, _ fallback: State) {
            observeValue(states[key, default: fallback])
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testNestedOptionalCollectionsPreserveElementType() throws {
        try check("""
        func render(_ models: [String: [Model]]?, _ key: String) {
            observeValue(models?[key]?.first?.state)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State", expectedOptional: true)
    }

    func testArrayForLoopPropagatesElementType() throws {
        try check("""
        func render(_ models: [Model]) {
            for model in models { observeValue(model.state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testDictionaryForLoopDestructuresKeyAndValue() throws {
        try check("""
        func render(_ models: [String: Model]) {
            for (_, model) in models { observeValue(model.state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testArrayLoopDestructuresTupleElement() throws {
        try check("""
        func render(_ pairs: [(State, Other)]) {
            for (_, state) in pairs { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        """, expected: "Other")
    }

    func testDictionaryValuesCollectionRetainsValueType() throws {
        try check("""
        func render(_ models: Dictionary<String, Model>) {
            for model in models.values { observeValue(model.state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testSetForEachInfersNamedClosureParameter() throws {
        try check("""
        func render(_ states: Set<State>) {
            states.forEach { state in observeValue(state) }
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testArrayMapInfersShorthandParameterMember() throws {
        try check("""
        func render(_ models: [Model]) {
            models.map { observeValue($0.state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testDictionaryCallbackDestructuresElement() throws {
        try check("""
        func render(_ models: [String: Model]) {
            models.forEach { key, value in observeValue(value.state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testFilterChainPreservesCollectionElement() throws {
        try check("""
        func render(_ models: [Model]) {
            models.filter { $0.isVisible }.map { observeValue($0.state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let isVisible: Bool }
        """, expected: "State")
    }

    func testNestedShorthandClosuresUseInnermostCollection() throws {
        try check("""
        func render(_ groups: [[Model]]) {
            groups.forEach { $0.forEach { observeValue($0.state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testNamedInnerClosureDoesNotCaptureOuterShorthandType() throws {
        try check("""
        func render(_ models: [Model]) {
            models.forEach { consume($0) { value in observeValue($0.state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: nil)
    }

    func testProjectArrayNamesakeUsesIndexedProperty() throws {
        try check("""
        func render(_ states: Array<State>) { observeValue(states.first) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        struct Array<Element> { let first: Other }
        """, expected: "Other")
    }

    func testCollectionSugarBypassesProjectArrayNamesake() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.first!) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        struct Array<Element> { let first: Other }
        """, expected: "State")
    }

    func testSliceSubscriptIsNotAnElementSubscript() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states[0..<2]) }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testUnknownArrayIndexTypeDoesNotGuessAnElement() throws {
        try check("""
        func render(_ states: [State], _ index: UnknownIndex) { observeValue(states[index]) }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testExplicitSwiftCollectionIsNotShadowedByLocalType() throws {
        try check("""
        func render(_ states: Swift.Array<State>) { observeValue(states.last!) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Array<Element> {}
        """, expected: "State")
    }

    func testDictionaryIndexDoesNotResolveAsAKeyLookup() throws {
        try check("""
        func render(_ states: [String: State], index: Dictionary<String, State>.Index) {
            observeValue(states[index])
        }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testArrayStartIndexResolvesAsAnElementSubscript() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states[states.startIndex]) }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testCollectionExtensionCallbackOverloadDoesNotUseBuiltinParameter() throws {
        try check("""
        func render(_ states: [State]) { states.map { observeValue($0) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        extension Array where Element == State {
            func map(_ body: (Other) -> Void) {}
        }
        """, expected: nil)
    }

    func testCollectionExtensionSubscriptDoesNotUseBuiltinResult() throws {
        try check("""
        func render(_ states: [State], _ index: Int) { observeValue(states[index]) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        extension Array where Element == State {
            subscript(index: Int) -> Other { .ready }
        }
        """, expected: nil)
    }

    func testDictionaryViewExtensionDoesNotAssumeBuiltinCallback() throws {
        try check("""
        func render(_ states: [String: State]) { states.values.map { observeValue($0) } }
        """, declarations: """
        enum State: Hashable { case idle, loaded }
        enum Other { case idle, unrelated }
        extension Dictionary.Values where Value == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        """, expected: nil)
    }

    func testCollectionProtocolExtensionDoesNotAssumeBuiltinCallback() throws {
        try check("""
        func render(_ states: [State]) { states.map { observeValue($0) } }
        """, declarations: """
        enum State: Hashable { case idle, loaded }
        enum Other { case idle, unrelated }
        protocol CustomSequence: Sequence {}
        extension Array: CustomSequence {}
        extension CustomSequence where Element == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        """, expected: nil)
    }

    func testProjectSwiftNamespaceDoesNotUseBuiltinCollectionShape() throws {
        try check("""
        func render(_ states: Swift.Array<State>) { observeValue(states.first) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case ready }
        enum Swift {
            struct Array<Element> { let first: Other }
        }
        """, expected: "Other")
    }

    func testIndexedSwiftCollectionStillChecksProjectOverloads() throws {
        try checkModules("""
        enum State { case idle, loaded }
        enum Other { case idle, unrelated }
        extension Array where Element == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        func render(_ states: [State]) { states.map { observeValue($0) } }
        """, sources: ["Swift": "public struct Array<Element> {}"], expectedCases: nil)
    }

    func testCollectionProtocolAliasOverloadDoesNotUseBuiltinParameter() throws {
        try check("""
        func render(_ states: [State]) { states.map { observeValue($0) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case idle, unrelated }
        protocol CustomSequence: Sequence {}
        typealias Alias = CustomSequence
        extension Array: Alias {}
        extension CustomSequence where Element == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        """, expected: nil)
    }

    func testIndexedStandardLibraryMethodsDoNotHideCollectionElementInference() throws {
        try checkModules("""
        enum State { case idle, loaded }
        func render(_ states: [State]) { states.map { observeValue($0) } }
        """, sources: ["Swift": """
        public struct Array<Element> {
            public func map(_ body: (Element) -> Void) {}
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testQualifiedImportedCollectionProtocolOverloadIsRecognized() throws {
        try checkModules("""
        import Library
        extension Array: Library.CustomSequence {}
        func render(_ states: [Library.State]) { states.map { observeValue($0) } }
        """, sources: ["Library": """
        public enum State { case idle, loaded }
        public enum Other { case idle, unrelated }
        public protocol CustomSequence: Sequence {}
        public extension CustomSequence where Element == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        """], expectedCases: nil)
    }

    func testCallerArrayNamesakeDoesNotHideImportedStandardCollectionOverload() throws {
        try checkModules("""
        import Library
        struct Array<Element> {}
        func render(_ states: [Library.State]) { states.map { observeValue($0) } }
        """, sources: ["Library": """
        public enum State { case idle, loaded }
        public enum Other { case idle, unrelated }
        public extension Array where Element == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        """], expectedCases: nil)
    }

    func testCollectionAliasExtensionDoesNotUseBuiltinCallbackParameter() throws {
        try check("""
        func render(_ states: [State]) { states.map { observeValue($0) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case idle, unrelated }
        typealias MyArray<Element> = Array<Element>
        extension MyArray where Element == State {
            func map(_ body: (Other) -> Void) { body(.idle) }
        }
        """, expected: nil)
    }

    func testQualifiedImportedCollectionAliasPropertyDoesNotUseBuiltinType() throws {
        try checkModules("""
        import Library
        extension Library.MyArray where Element == Library.State {
            var first: Library.Other? { .idle }
        }
        func render(_ states: [Library.State]) { observeValue(states.first!) }
        """, sources: ["Library": """
        public enum State { case idle, loaded }
        public enum Other { case idle, unrelated }
        public typealias MyArray<Element> = Array<Element>
        """], expectedCases: nil)
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

    private func check(_ input: String, declarations: String, expected: String?, expectedOptional: Bool = false, options: FormatOptions = .default, file: StaticString = #filePath, line: UInt = #line) throws {
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        let project = ProjectIndex(files: [
            url.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
            "/Project/Declarations.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
        ])
        let formatter = Formatter(tokenize(input), options: options)
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
