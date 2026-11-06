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
    func testInvariantGenericArgumentEliminatesUnequalAssociatedConstraint() throws {
        try check("""
        func render(_ source: Box<Model>) { consume(source) { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = State }
        struct Box<Value> {}
        func consume<Input: Source>(_ input: Box<Input>, handle: (State) -> Void) where Input.Output == State {}
        func consume<Input: Source>(_ input: Box<Input>, handle: (Other) -> Void) where Input.Output == Other {}
        """, expected: "State")
    }

    func testKnownTupleArgumentEliminatesIncompatibleOverload() throws {
        try check("""
        func render(_ pair: (Model, State)) { observeValue(read(pair)) }
        """, declarations: """
        struct Model {}
        struct Other {}
        enum State { case idle, loaded }
        enum Unrelated { case other }
        func read(_ pair: (Model, State)) -> State { .idle }
        func read(_ pair: (Other, State)) -> Unrelated { .other }
        """, expected: "State")
    }

    func testTupleExpressionEliminatesIncompatibleOverload() throws {
        try check("""
        func render(_ model: Model, _ state: State) { observeValue(read((model, state))) }
        """, declarations: """
        struct Model {}
        struct Other {}
        enum State { case idle, loaded }
        enum Unrelated { case other }
        func read(_ pair: (Model, State)) -> State { .idle }
        func read(_ pair: (Other, State)) -> Unrelated { .other }
        """, expected: "State")
    }

    func testGroupedArgumentEliminatesIncompatibleOverload() throws {
        try check("""
        func render(_ model: Model) { observeValue(read(((model)))) }
        """, declarations: """
        struct Model {}
        struct Other {}
        enum State { case idle, loaded }
        enum Unrelated { case other }
        func read(_ model: Model) -> State { .idle }
        func read(_ model: Other) -> Unrelated { .other }
        """, expected: "State")
    }

    func testKnownMetatypeArgumentEliminatesIncompatibleOverload() throws {
        try check("""
        func render() { observeValue(read(Model.self)) }
        """, declarations: """
        struct Model {}
        struct Other {}
        enum State { case idle, loaded }
        enum Unrelated { case other }
        func read(_ model: Model.Type) -> State { .idle }
        func read(_ model: Other.Type) -> Unrelated { .other }
        """, expected: "State")
    }

    func testTupleClassUpcastRetainsCompetingOverload() throws {
        try check("""
        func render(_ pair: (Child, State)) { observeValue(read(pair)) }
        """, declarations: """
        class Parent {}
        class Child: Parent {}
        enum State { case idle, loaded }
        enum Other { case unrelated }
        func read(_ pair: (Child, State)) -> State { .idle }
        func read(_ pair: (Parent, State)) -> Other { .unrelated }
        """, expected: nil)
    }

    func testCollectionElementMismatchEliminatesIncompatibleOverload() throws {
        try check("""
        func render(_ values: [State]) { observeValue(read(values)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        func read(_ values: [State]) -> State { .idle }
        func read(_ values: [Other]) -> Other { .unrelated }
        """, expected: "State")
    }

    func testUnknownAssociatedWitnessRetainsConstrainedOverloads() throws {
        try check("""
        func render<Input: Source>(_ source: Box<Input>) { consume(source) { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol Source { associatedtype Output }
        struct Box<Value> {}
        func consume<Input: Source>(_ input: Box<Input>, handle: (State) -> Void) where Input.Output == State {}
        func consume<Input: Source>(_ input: Box<Input>, handle: (Other) -> Void) where Input.Output == Other {}
        """, expected: nil)
    }

    func testCollectionClassUpcastRetainsCompetingOverload() throws {
        try check("""
        func render(_ values: [Child]) { observeValue(read(values)) }
        """, declarations: """
        class Parent {}
        class Child: Parent {}
        enum State { case idle, loaded }
        enum Other { case unrelated }
        func read(_ values: [Child]) -> State { .idle }
        func read(_ values: [Parent]) -> Other { .unrelated }
        """, expected: nil)
    }

    func testOpaqueProtocolParameterExposesConcreteProperty() throws {
        try check("""
        func render(_ source: some Source) { observeValue(source.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { var state: State { get } }
        """, expected: "State")
    }

    func testOpaqueProtocolParameterExposesCallbackSignature() throws {
        try check("""
        func render(_ source: some Source) { source.observe { value in observeValue(value) } }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { func observe(_ callback: (State) -> Void) }
        """, expected: "State")
    }

    func testOpaqueProtocolCompositionExposesConcreteProperty() throws {
        try check("""
        func render(_ source: some (Marker & Source)) { observeValue(source.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Marker {}
        protocol Source { var state: State { get } }
        """, expected: "State")
    }

    func testExistentialProtocolCompositionExposesCallbackSignature() throws {
        try check("""
        func render(_ source: any Marker & Source) { source.observe { value in observeValue(value) } }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Marker {}
        protocol Source { func observe(_ callback: (State) -> Void) }
        """, expected: "State")
    }

    func testAliasedProtocolCompositionKeepsDeclarationContext() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ source: Sources) { observeValue(source.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Marker {}
        public protocol Source { var state: State { get } }
        public typealias Sources = Marker & Source
        """], expectedCases: ["idle", "loaded"])
    }

    func testProtocolCompositionKeepsUnknownBoundsConservative() throws {
        try check("""
        func render(_ source: some (Missing & Source)) { observeValue(source.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { var state: State { get } }
        """, expected: nil)
    }

    func testNamedGenericAcceptsAnAliasedProtocolComposition() throws {
        try check("""
        func render<Input: Sources>(_ source: Input) { observeValue(source.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Marker {}
        protocol Source { var state: State { get } }
        typealias Sources = Marker & Source
        """, expected: "State")
    }

    func testOptionalProtocolCompositionPreservesOptionalProjection() throws {
        try check("""
        func render(_ source: (any Marker & Source)?) { observeValue(source?.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Marker {}
        protocol Source { var state: State { get } }
        """, expected: "State", expectedOptional: true)
    }

    func testProtocolCompositionKeepsCompetingCallbackOverloads() throws {
        try check("""
        func render(_ source: any First & Second) { source.observe { value in observeValue(value) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol First { func observe(_ callback: (State) -> Void) }
        protocol Second { func observe(_ callback: (Other) -> Void) }
        """, expected: nil)
    }

    func testOpaqueProtocolDoesNotGuessAssociatedWitness() throws {
        try check("""
        func render(_ source: some Source) { observeValue(source.value) }
        """, declarations: """
        enum Output { case unrelated }
        protocol Source { associatedtype Output; var value: Output { get } }
        """, expected: nil)
    }

    func testSuppressedGenericCapabilityDoesNotBlockConcreteCallResult() throws {
        try check("""
        func render(_ model: Model) { observeValue(read(model)) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {}
        func read<Value: ~Copyable>(_ value: borrowing Value) -> State { .idle }
        """, expected: "State")
    }

    func testSuppressedGenericCapabilityKeepsPositiveProtocolBound() throws {
        try check("""
        func render<Input: Source & ~Copyable>(_ input: borrowing Input) { observeValue(input.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source: ~Copyable { var state: State { get } }
        """, expected: "State")
    }

    func testLeadingSuppressedGenericCapabilityKeepsPositiveProtocolBound() throws {
        try check("""
        func render<Input: ~Copyable & Source>(_ input: borrowing Input) { observeValue(input.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source: ~Copyable { var state: State { get } }
        """, expected: "State")
    }

    func testSuppressedGenericCapabilityDoesNotHideUnknownPositiveBound() throws {
        try check("""
        func render<Input: Source & ~Copyable & Missing>(_ input: borrowing Input) { observeValue(input.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source: ~Copyable { var state: State { get } }
        """, expected: nil)
    }

    func testSuppressedWhereBoundKeepsAssociatedTypeEquality() throws {
        try check("""
        func render<Input: Source>(_ input: Input) where Input.Output == State { observeValue(read(input)) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source: ~Copyable { associatedtype Output }
        func read<Input: Source & ~Copyable>(_ input: borrowing Input) -> Input.Output { fatalError() }
        """, expected: "State")
    }

    func testSuppressedCapabilitiesDoNotHideEnumCaseInitializer() throws {
        try checkModules("""
        import Models
        func render(_ holder: Holder) { observeValue(holder.state) }
        """, sources: ["Models": """
        public protocol Marker: ~Copyable, ~Escapable {}
        public enum State: Marker { case idle, loaded }
        public struct Holder { public let state = State.idle }
        """], expectedCases: ["idle", "loaded"])
    }

    func testSuppressedCapabilitiesDoNotDiscardUnknownInheritedProtocol() throws {
        try checkModules("""
        import Models
        func render(_ holder: Holder) { observeValue(holder.state) }
        """, sources: ["Models": """
        public protocol Marker: ~Copyable, MissingProtocol {}
        public enum State: Marker { case idle, loaded }
        public struct Holder { public let state = State.idle }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testStructuralAssociatedEqualityFixesCallbackGeneric() throws {
        try check("""
        func render(_ model: Model) { consume(model) { value in observeValue(value) } }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Value> {}
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = Box<State> }
        func consume<Input: Source, Value>(_ input: Input, callback: (Value) -> Void) where Input.Output == Box<Value> {}
        """, expected: "State")
    }

    func testStructuralEqualityDoesNotFixCovariantInputCallback() throws {
        try check("""
        func render(_ child: Child) { consume(child) { value in observeValue(value) } }
        """, declarations: """
        class Parent {}
        class Child: Parent {}
        struct Box<Value> {}
        func consume<Input, Value>(_ input: Input, callback: (Value) -> Void) where Box<Input> == Box<Value> {}
        """, expected: nil)
    }

    func testAssociatedEqualityInfersGenericInsideProjectWrapper() throws {
        try check("""
        func render(_ model: Model) { observeValue(read(model)) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Value> {}
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = Box<State> }
        func read<Input: Source, Value>(_ input: Input) -> Value where Input.Output == Box<Value> { fatalError() }
        """, expected: "State")
    }

    func testAssociatedEqualityInfersNestedOptionalTupleGeneric() throws {
        try check("""
        func render(_ model: Model) { observeValue(read(model)) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = (payload: State?, count: Int) }
        func read<Input: Source, Value>(_ input: Input) -> Value where Input.Output == (payload: Value?, count: Int) { fatalError() }
        """, expected: "State")
    }

    func testAssociatedEqualityInfersGenericThroughAliasedCollection() throws {
        try check("""
        func render(_ model: Model) { observeValue(read(model)) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = [String: State] }
        typealias Values<Value> = [String: Value]
        func read<Input: Source, Value>(_ input: Input) -> Value where Input.Output == Values<Value> { fatalError() }
        """, expected: "State")
    }

    func testStructuralEqualityDoesNotRetainPartialConflictingInference() throws {
        try check("""
        func render(_ model: Model) { observeValue(read(model)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = (State, Other) }
        func read<Input: Source, Value>(_ input: Input) -> Value where Input.Output == (Value, Value) { fatalError() }
        """, expected: nil)
    }

    func testStructuralEqualityRequiresMatchingNominalDeclaration() throws {
        try check("""
        func render(_ model: Model) { observeValue(read(model)) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Value> {}
        struct OtherBox<Value> {}
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = OtherBox<State> }
        func read<Input: Source, Value>(_ input: Input) -> Value where Input.Output == Box<Value> { fatalError() }
        """, expected: nil)
    }

    func testArrayLiteralCarriesItsClosureElementContext() throws {
        try check("""
        func render() {
            let handlers: [(State) -> Void] = [{ value in observeValue(value) }]
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testTupleLiteralCarriesItsLabeledClosureContext() throws {
        try check("""
        func render() {
            let pair: (count: Int, callback: (State) -> Void) =
                (count: 0, callback: { value in observeValue(value) })
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testNestedDictionaryAndArrayLiteralCarryInitializerContext() throws {
        try check("""
        func render() {
            let handlers: [String: [Handler]] = ["first": [.init { value in observeValue(value) }]]
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: "State")
    }

    func testEnumKeyDictionaryLiteralCarriesValueContext() throws {
        try check("""
        func render() {
            let handlers: [Key: Handler] = [.primary: .init { value in observeValue(value) }]
        }
        """, declarations: """
        enum Key { case primary }
        enum State { case idle, loaded }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: "State")
    }

    func testDictionaryKeyInitializerReceivesItsCallbackContext() throws {
        try check("""
        func render() {
            let handlers: [Handler: Int] = [.init { value in observeValue(value) }: 0]
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler: Hashable { init(_ callback: (State) -> Void) {} }
        """, expected: "State")
    }

    func testAggregateContextFlowsThroughCallParameterAndAlias() throws {
        try check("""
        func render() {
            consume([.init { value in observeValue(value) }])
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler { init(_ callback: (State) -> Void) {} }
        typealias Handlers = [Handler]
        func consume(_ handlers: Handlers) {}
        """, expected: "State")
    }

    func testCustomArrayLiteralDoesNotInventStandardElementContext() throws {
        try check("""
        func render() {
            let handlers: Handlers = [{ value in observeValue(value) }]
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handlers: ExpressibleByArrayLiteral {
            init(arrayLiteral elements: ((State) -> Void)...) {}
        }
        """, expected: nil)
    }

    func testTransformedArrayLiteralDoesNotBorrowResultElementContext() throws {
        try check("""
        func render() {
            let handlers: [(State) -> Void] = [{ value in observeValue(value) }].unknown()
        }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testTupleLiteralArityMismatchDoesNotBorrowClosureContext() throws {
        try check("""
        func render() {
            let handlers: ((State) -> Void, Int, Int) = ({ value in observeValue(value) }, 0)
        }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testLocalFactoryInAnotherFunctionDoesNotHideEnumReference() throws {
        try check("""
        func unrelated() { func State() -> Int { 0 } }
        func render() { observeValue(State.idle) }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testLocalFactoryInSiblingBranchDoesNotHideGlobalCall() throws {
        try check("""
        func render(_ flag: Bool) {
            if flag { func current() -> Int { 0 } }
            observeValue(current())
        }
        """, declarations: """
        enum State { case idle, loaded }
        func current() -> State { .idle }
        """, expected: "State")
    }

    func testLocalFactoryIsVisibleBeforeItsDeclaration() throws {
        try check("""
        func render() {
            observeValue(current())
            func current() -> Int { 0 }
        }
        """, declarations: """
        enum State { case idle, loaded }
        func current() -> State { .idle }
        """, expected: nil)
    }

    func testEscapedLocalFactoryStillShadowsGlobalCall() throws {
        try check("""
        func render() {
            func `current`() -> Int { 0 }
            observeValue(current())
        }
        """, declarations: """
        enum State { case idle, loaded }
        func current() -> State { .idle }
        """, expected: nil)
    }

    func testLocalFunctionDoesNotShadowExplicitMemberCall() throws {
        try check("""
        func render(_ provider: Provider) {
            func current() -> Int { 0 }
            observeValue(provider.current())
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Provider { func current() -> State { .idle } }
        """, expected: "State")
    }

    func testLocalCallbackHelperInAnotherScopeDoesNotHideGlobalCallback() throws {
        try check("""
        func unrelated() { func consume() {} }
        func render() {
            consume { value in observeValue(value) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        func consume(_ callback: (State) -> Void) {}
        """, expected: "State")
    }

    func testUnrelatedMembersAndParametersDoNotHideEnumReference() throws {
        try check("""
        func render() { observeValue(State.idle) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Container { associatedtype State }
        struct Other { let State: Int }
        func unrelated(_ State: Int) {}
        """, expected: "State")
    }

    func testUnimportedFactoryDoesNotHideConstructor() throws {
        try checkModules("""
        import Models
        func render() { observeValue(Model().state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public init() {}; public let state: State = .idle }
        """, "Unrelated": """
        public func Model() -> Int { 0 }
        """], expectedCases: ["idle", "loaded"])
    }

    func testQualifiedConstructorIgnoresFactoryInAnotherImportedModule() throws {
        try checkModules("""
        import Models
        import Other
        func render() { observeValue(Models.Model().state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public init() {}; public let state: State = .idle }
        """, "Other": """
        public func Model() -> Int { 0 }
        """], expectedCases: ["idle", "loaded"])
    }

    func testFilePrivateFactoryInOtherFileDoesNotHideConstructor() throws {
        try checkModules("""
        import Models
        func render() { observeValue(Model().state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public init() {}; public let state: State = .idle }
        """], otherAppSources: ["""
        private func Model(_ value: Int = 0) -> Int { value }
        """], expectedCases: ["idle", "loaded"])
    }

    func testImportedFactoryStillBlocksUnqualifiedConstructor() throws {
        try checkModules("""
        import Models
        import Other
        func render() { observeValue(Model().state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public init() {}; public let state: State = .idle }
        """, "Other": """
        public func Model() -> Int { 0 }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testAliasConstructorIgnoresFactoryNamedAfterItsTarget() throws {
        try checkModules("""
        import Models
        typealias Alias = Models.Model
        func Model(_ value: Int) -> Int { value }
        func render() { observeValue(Alias().state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public init() {}; public let state: State = .idle }
        """], expectedCases: ["idle", "loaded"])
    }

    func testTestableImportRetainsInternalFactoryShadow() throws {
        try checkModules("""
        import Models
        @testable import Other
        func render() { observeValue(Model(0).state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public init(_ value: String) {}; public let state: State = .idle }
        """, "Other": """
        public enum Other { case unrelated }
        struct OtherModel { let state: Other }
        func Model(_ value: Int) -> OtherModel { OtherModel(state: .unrelated) }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testPropertyInitializerIgnoresUnrelatedMemberAndParameterNames() throws {
        try check("""
        func render(_ holder: Holder) { observeValue(holder.state) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Holder { let state = State.idle }
        protocol Other { associatedtype State }
        func unused(State: Int) {}
        """, expected: "State")
    }

    func testPropertyInitializerDoesNotMistakeMemberFactoryForNominalConstructor() throws {
        try check("""
        func render() { observeValue(Holder.model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Model { init(_ value: Int) {}; let state: State = .idle }
        struct OtherModel { let state: Other }
        struct Holder {
            static func Model(_ value: Int) -> OtherModel { OtherModel(state: .unrelated) }
            static let model = Model(0)
        }
        """, expected: nil)
    }

    func testPropertyInitializerDoesNotMistakeEscapedMemberFactoryForNominalConstructor() throws {
        try check("""
        func render() { observeValue(Holder.model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Model { init(_ value: Int) {}; let state: State = .idle }
        struct OtherModel { let state: Other }
        struct Holder {
            static func `Model`(_ value: Int) -> OtherModel { OtherModel(state: .unrelated) }
            static let model = Model(0)
        }
        """, expected: nil)
    }

    func testPropertyInitializerDoesNotMistakePrivateMemberFactoryForNominalConstructor() throws {
        try check("""
        func render() { observeValue(Holder.model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Model { init(_ value: Int) {}; let state: State = .idle }
        struct OtherModel { let state: Other }
        struct Holder {
            private static func Model(_ value: Int) -> OtherModel { OtherModel(state: .unrelated) }
            static let model = Model(0)
        }
        """, expected: nil)
    }

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
        try checkModules("""
        enum State { case unrelated }
        func render<State>(_ state: State) { observeValue(state) }
        """, sources: [:], expectedCases: nil, expectedAbstractParameter: "State")
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
        """, expected: "Other")
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

    func testGenericParentArityDisambiguatesItsOwnDeclaration() throws {
        try checkModules("""
        import Models
        import UI
        func render(_ value: Outer<Int>.State) { observeValue(value) }
        """, sources: [
            "Models": "public enum Outer<T> { public enum State { case correct } }",
            "UI": "public enum Outer { public enum State<T> { case wrong } }",
        ], expectedCases: ["correct"])
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

    func testOwnEnumCaseShadowsInheritedStaticProperty() throws {
        try check("""
        extension State {
            static func render() { observeValue(idle) }
        }
        """, declarations: """
        enum Other { case ready }
        protocol Rendering {}
        extension Rendering { static var idle: Other { .ready } }
        enum State: Rendering { case idle, loaded }
        """, expected: "State")
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
        """, expected: "Other")
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

    func testConstructorTrailingClosureReceivesConcreteParameter() throws {
        try check("""
        func render() {
            Handler { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: "State")
    }

    func testSpecializedConstructorTrailingClosureReceivesGenericParameter() throws {
        try check("""
        func render() {
            Handler<State> { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testSpecializedConstructorParenthesizedClosureReceivesGenericParameter() throws {
        try check("""
        func render() {
            Handler<State>(handle: { observeValue($0) })
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(handle: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testConstructorDefaultArgumentBeforeTrailingClosure() throws {
        try check("""
        func render() {
            Handler<State> { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(enabled: Bool = true, handle: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testConstructorAdditionalTrailingClosureUsesItsOwnParameter() throws {
        try check("""
        func render() {
            Handler<State> { _ in } completion: { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(handle: (Int) -> Void, completion: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testFailableConstructorCallbackHasNonoptionalInput() throws {
        try check("""
        func render() {
            Handler<State> { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init?(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testConstructorCallbackAliasSubstitutesGenericParameter() throws {
        try check("""
        func render() {
            Handler<State> { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Callback<Value> = (Value) -> Void
        struct Handler<Value> { init(_ callback: Callback<Value>) {} }
        """, expected: "State")
    }

    func testImportedConstructorAliasRetainsCallbackDeclarationContext() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render() { StateHandler { state in observeValue(state) } }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Handler<Value> { public init(_ callback: (Value) -> Void) {} }
        public typealias StateHandler = Handler<State>
        """], expectedCases: ["idle", "loaded"])
    }

    func testModuleQualifiedConstructorPreservesUseSiteGenericArguments() throws {
        try checkModules("""
        import Models
        enum State { case localIdle, localLoaded }
        func render() { Models.Handler<State> { state in observeValue(state) } }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public struct Handler<Value> { public init(_ callback: (Value) -> Void) {} }
        """], expectedCases: ["localIdle", "localLoaded"])
    }

    func testExplicitInitOnSpecializedTypeResolvesCallback() throws {
        try check("""
        func render() { Handler<State>.init { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testConstructorCallbackCannotIgnoreSameNamedFactory() throws {
        try check("""
        func Handler(_ callback: (Other) -> Void) {}
        func render() { Handler { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testExplicitInitDoesNotUseSameNamedFactory() throws {
        try check("""
        func Handler(_ callback: (Other) -> Void) {}
        func render() { Handler.init { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: "State")
    }

    func testConstructorCallbackCannotIgnoreCallableBinding() throws {
        try check("""
        func render(_ Handler: (@escaping (Other) -> Void) -> Void) {
            Handler { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testConstructorCallbackCannotIgnoreLocalFactory() throws {
        try check("""
        func render() {
            func Handler(_ callback: (Other) -> Void) {}
            Handler { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testConstructorCallbackCannotChooseBetweenOverloads() throws {
        try check("""
        func render() { Handler { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler {
            init(_ callback: (State) -> Void) {}
            init(_ callback: (Other) -> Void) {}
        }
        """, expected: nil)
    }

    func testConstructorCallbackDoesNotUseUnknownInheritedCallable() throws {
        try check("""
        class Renderer: ExternalBase {
            func render() { Handler { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testAnnotatedLocalProvidesShorthandInitializerCallbackContext() throws {
        try check("""
        func render() {
            let handler: Handler<State> = .init { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testAnnotatedOptionalProvidesWrappedInitializerContext() throws {
        try check("""
        func render() {
            let handler: Handler<State>? = .init(handle: { state in observeValue(state) })
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(handle: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testAnnotatedPropertyProvidesInitializerContext() throws {
        try check("""
        struct Renderer {
            let handler: Handler<State> = .init { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testExplicitReturnProvidesInitializerContext() throws {
        try check("""
        func render() -> Handler<State> {
            return .init { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testImplicitReturnProvidesInitializerContext() throws {
        try check("""
        func render() -> Handler<State> {
            .init { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testComputedPropertyProvidesInitializerContext() throws {
        try check("""
        struct Renderer {
            var handler: Handler<State> {
                .init { state in observeValue(state) }
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testAssignmentProvidesInitializerContextFromExistingBinding() throws {
        try check("""
        func render() {
            var handler: Handler<State>
            handler = .init { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testMemberAssignmentProvidesInitializerContextFromIndexedProperty() throws {
        try check("""
        func render(_ model: Model<State>) {
            model.handler = .init { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        final class Model<Value> { var handler: Handler<Value> }
        """, expected: "State")
    }

    func testOuterFunctionArgumentProvidesInitializerContext() throws {
        try check("""
        func render() {
            consume(handler: .init { state in observeValue(state) })
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        func consume(handler: Handler<State>) {}
        """, expected: "State")
    }

    func testOuterMethodArgumentSubstitutesReceiverGenericsForInitializerContext() throws {
        try check("""
        func render(_ model: Model<State>) {
            model.consume(.init { state in observeValue(state) })
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        struct Model<Value> { func consume(_ handler: Handler<Value>) {} }
        """, expected: "State")
    }

    func testOuterConstructorArgumentProvidesInitializerContext() throws {
        try check("""
        func render() {
            Model<State>(handler: .init { state in observeValue(state) })
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        struct Model<Value> { init(handler: Handler<Value>) {} }
        """, expected: "State")
    }

    func testImportedArgumentContextRetainsTheDefiningModule() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render() { consume(.init { state in observeValue(state) }) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Handler<Value> { public init(_ callback: (Value) -> Void) {} }
        public func consume(_ handler: Handler<State>) {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testAmbiguousOuterArgumentCannotProvideInitializerContext() throws {
        try check("""
        func render() { consume(.init { state in observeValue(state) }) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        func consume(_ handler: Handler<State>) {}
        func consume(_ handler: Handler<Other>) {}
        """, expected: nil)
    }

    func testUnannotatedBindingCannotProvideInitializerContext() throws {
        try check("""
        func render() {
            let handler = .init { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testInitializerContextDoesNotCrossAnUntypedClosureBoundary() throws {
        try check("""
        func render() -> Handler<State> {
            opaque {
                return .init { state in observeValue(state) }
            }
            fatalError()
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: nil)
    }

    func testInitializerContextDoesNotUseAPropertyWrapperAnnotation() throws {
        try check("""
        struct Renderer {
            @Wrapper var handler: Handler<State> = .init { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: nil)
    }

    func testGenericFunctionInfersArrayElementThroughSugar() throws {
        try check("""
        func render(_ states: [State]) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        func select<Value>(_ values: [Value]) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericFunctionInfersDictionaryValue() throws {
        try check("""
        func render(_ states: [String: State]) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        func select<Value>(_ values: [String: Value]) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericFunctionInfersSetElement() throws {
        try check("""
        func render(_ states: Set<State>) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        func select<Value>(_ values: Set<Value>) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericFunctionInfersTupleComponent() throws {
        try check("""
        func render(_ pair: (previous: Other, current: State)) { observeValue(select(pair)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        func select<Value>(_ values: (previous: Other, current: Value)) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericFunctionInfersGroupedOptionalArrayElement() throws {
        try check("""
        func render(_ states: [State?]) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        func select<Value>(_ values: [(Value)?]) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericFunctionInfersThroughCollectionAlias() throws {
        try check("""
        func render(_ states: [State]) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Values<Value> = [Value]
        func select<Value>(_ values: Values<Value>) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericFunctionInfersThroughNominalAlias() throws {
        try check("""
        func render(_ states: Box<State>) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Element> { let element: Element }
        typealias Wrapped<Value> = Box<Value>
        func select<Value>(_ values: Wrapped<Value>) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericFunctionInfersNestedCollectionTuple() throws {
        try check("""
        func render(_ states: [String: (Int, State?)]) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        func select<Value>(_ values: [String: (Int, Value?)]) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericCollectionArgumentKeepsItsUseSiteModule() throws {
        try checkModules("""
        import Helpers
        enum State { case idle, loaded }
        func render(_ states: [State]) { observeValue(select(states)) }
        """, sources: ["Helpers": """
        public enum State { case unrelated }
        public func select<Value>(_ values: [Value]) -> Value { fatalError() }
        """], expectedCases: ["idle", "loaded"])
    }

    func testGenericFunctionRejectsDifferentDictionaryKey() throws {
        try check("""
        func render(_ states: [Int: State]) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        func select<Value>(_ values: [String: Value]) -> Value { fatalError() }
        """, expected: nil)
    }

    func testGenericFunctionRejectsDifferentCollectionShape() throws {
        try check("""
        func render(_ states: Set<State>) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        func select<Value>(_ values: [Value]) -> Value { fatalError() }
        """, expected: nil)
    }

    func testGenericFunctionRejectsConflictingTupleComponents() throws {
        try check("""
        func render(_ states: (State, Other)) { observeValue(select(states)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        func select<Value>(_ values: (Value, Value)) -> Value { fatalError() }
        """, expected: nil)
    }

    func testCovariantCollectionDoesNotFixContextualCallbackType() throws {
        try check("""
        func render(_ states: [State]) {
            select(states) { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        func select<Value>(_ values: [Value], handle: (Value) -> Void) {}
        """, expected: nil)
    }

    func testInvariantWrapperAroundCollectionFixesContextualCallbackType() throws {
        try check("""
        func render(_ states: Box<[State]>) {
            select(states) { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Value> { let value: Value }
        func select<Value>(_ values: Box<[Value]>, handle: (Value) -> Void) {}
        """, expected: "State")
    }

    func testInvariantWrapperInsideCollectionFixesContextualCallbackType() throws {
        try check("""
        func render(_ states: [Box<State>]) {
            select(states) { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Value> { let value: Value }
        func select<Value>(_ values: [Box<Value>], handle: (Value) -> Void) {}
        """, expected: "State")
    }

    func testInvariantAliasFixesContextualCallbackType() throws {
        try check("""
        func render(_ states: Box<State>) {
            select(states) { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Value> { let value: Value }
        typealias Wrapped<Value> = Box<Value>
        func select<Value>(_ values: Wrapped<Value>, handle: (Value) -> Void) {}
        """, expected: "State")
    }

    func testInheritedMetatypePropertyShadowsExplicitInitializerReceiver() throws {
        try check("""
        class Renderer: Base {
            func render() { Handler.init { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler { init(_ callback: (State) -> Void) {} }
        struct OtherHandler { init(_ callback: (Other) -> Void) {} }
        class Base { let Handler: OtherHandler.Type = OtherHandler.self }
        """, expected: nil)
    }

    func testAutoclosureArgumentProvidesResultContextForInitializer() throws {
        try check("""
        func render() { consume(.init { state in observeValue(state) }) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        func consume(_ handler: @autoclosure () -> Handler<State>) {}
        """, expected: "State")
    }

    func testEnumeratedLoopDestructuresProjectElement() throws {
        try check("""
        func render(_ states: [State]) {
            for (_, state) in states.enumerated() { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testEnumeratedCallbackDestructuresProjectElement() throws {
        try check("""
        func render(_ states: [State]) {
            states.enumerated().forEach { _, state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testEnumeratedCallbackTupleRetainsElementLabel() throws {
        try check("""
        func render(_ states: [State]) {
            states.enumerated().forEach { pair in observeValue(pair.element) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testEnumeratedDictionaryElementKeepsItsValueType() throws {
        try check("""
        func render(_ states: [String: State]) {
            for pair in states.enumerated() { observeValue(pair.element.value) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testReversedCollectionRetainsElementType() throws {
        try check("""
        func render(_ states: [State]) {
            for state in states.reversed() { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testReversedSetRetainsElementType() throws {
        try check("""
        func render(_ states: Set<State>) {
            for state in states.reversed() { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testReversedEnumeratedSetRetainsOriginalElement() throws {
        try check("""
        func render(_ states: Set<State>) {
            states.enumerated().reversed().forEach { _, state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", options: FormatOptions(swiftVersion: "6.2"))
    }

    func testArrayPrefixRetainsElementType() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.prefix(2).first) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testArraySuffixRetainsElementType() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.suffix(2).last) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testDropFirstRetainsElementType() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.dropFirst().first) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testDropLastWithCountRetainsElementType() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.dropLast(2).last) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testSortedCollectionRetainsElementType() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.sorted().first) }
        """, declarations: """
        enum State: Comparable { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testSortedComparatorRetainsElementType() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.sorted(by: { _, _ in true }).first) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testMapProjectMemberRetainsResultType() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.map { $0.state }.first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: "State", expectedOptional: true)
    }

    func testMapNamedCallbackRetainsResultType() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.map { model in model.state }.first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: "State", expectedOptional: true)
    }

    func testMapExplicitReturnRetainsResultType() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.map { model in return model.state }.first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: "State", expectedOptional: true)
    }

    func testMapAnnotatedResultDoesNotRequireBodyInference() throws {
        try check("""
        func render(_ models: [Model]) {
            observeValue(models.map { model -> State in
                if opaque() { return .idle }
                return .loaded
            }.first)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: "State", expectedOptional: true)
    }

    func testCompactMapUnwrapsOptionalProjectMember() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.compactMap { $0.optionalState }.first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: "State", expectedOptional: true)
    }

    func testFlatMapProjectCollectionFlattensOneLayer() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.flatMap { $0.children }.first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: "State", expectedOptional: true)
    }

    func testMapChainPropagatesNamedElement() throws {
        try check("""
        func render(_ models: [Model]) {
            models.map { $0.state }.forEach { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: "State")
    }

    func testTransformDoesNotInferAcrossMultipleStatements() throws {
        try check("""
        func render(_ models: [Model]) {
            observeValue(models.map { model in
                sideEffect()
                return model.state
            }.first)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: nil)
    }

    func testDeprecatedOptionalFlatMapOverloadRemainsUnresolved() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.flatMap { $0.optionalState }.first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        """, expected: nil)
    }

    func testCollectionTransformCannotIgnoreProjectOverload() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.map { $0.state }.first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State?; let children: [State] }
        extension Array where Element == Model {
            func map(_ callback: (Model) -> State) -> [Other] { [] }
        }
        enum Other { case unrelated }
        """, expected: nil)
    }

    func testEnumerationCannotIgnoreProjectOverload() throws {
        try check("""
        func render(_ states: [State]) {
            for pair in states.enumerated() { observeValue(pair.element) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        extension Array where Element == State {
            func enumerated() -> [Other] { [] }
        }
        enum Other { case unrelated }
        """, expected: nil)
    }

    func testReversedResultCannotIgnoreReversedCollectionExtension() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.reversed().first) }
        """, declarations: """
        enum State { case idle, loaded }
        extension ReversedCollection { var first: Int { 0 } }
        """, expected: nil)
    }

    func testAnnotatedClosureVariableSuppliesNamedParameter() throws {
        try check("""
        func render() {
            let callback: (State) -> Void = { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testAnnotatedClosureVariableSuppliesShorthandParameter() throws {
        try check("""
        func render() {
            let callback: (Int, State) -> Void = { observeValue($1) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testAnnotatedClosureAliasRetainsDeclarationContext() throws {
        try check("""
        func render() {
            let callback: Callback = { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Callback = (State) -> Void
        """, expected: "State")
    }

    func testOptionalCallbackAnnotationSuppliesParameter() throws {
        try check("""
        func render() {
            let callback: ((State) -> Void)? = { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testReturnedClosureUsesFunctionReturnSignature() throws {
        try check("""
        func render() -> (State) -> Void {
            return { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testImplicitReturnedClosureUsesFunctionReturnSignature() throws {
        try check("""
        func render() -> (State) -> Void {
            { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testComputedClosurePropertyUsesItsFunctionSignature() throws {
        try check("""
        struct Renderer {
            var callback: (State) -> Void {
                { state in observeValue(state) }
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testAssignedClosureUsesExistingBindingType() throws {
        try check("""
        func render() {
            var callback: (State) -> Void
            callback = { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testAssignedClosureUsesIndexedGenericMemberType() throws {
        try check("""
        func render(_ model: Model<State>) {
            model.callback = { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        final class Model<Value> { var callback: (Value) -> Void }
        """, expected: "State")
    }

    func testClosureContextDoesNotLeakIntoNestedShorthandClosure() throws {
        try check("""
        func render() {
            let callback: (State) -> Void = {
                opaque { observeValue($0) }
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testClosureAnnotationCannotBindAnExtraParameter() throws {
        try check("""
        func render() {
            let callback: (State) -> Void = { observeValue($1) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testImportedClosureAliasAnnotationRetainsTheDeclaringModule() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render() {
            let callback: Callback = { state in observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public typealias Callback = (State) -> Void
        """], expectedCases: ["idle", "loaded"])
    }

    func testDoubleReverseUsesTheOriginalArraysOverloads() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.reversed().reversed().first) }
        """, declarations: """
        enum State { case idle, loaded }
        extension Array { var first: Int { 0 } }
        """, expected: nil)
    }

    func testReversedEnumerationUsesModernReversedCollectionOverloads() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.enumerated().reversed().first) }
        """, declarations: """
        enum State { case idle, loaded }
        extension ReversedCollection { var first: Int { 0 } }
        """, expected: nil, options: FormatOptions(swiftVersion: "6.2"))
    }

    func testEnumerationReverseDoesNotAssumeAnUnknownStandardLibraryConformance() throws {
        for options in [FormatOptions.default, FormatOptions(swiftVersion: "5.9"), FormatOptions(swiftVersion: "6.2")] {
            try check("""
            func render(_ states: [State]) { observeValue(states.enumerated().reversed().first) }
            """, declarations: """
            enum State { case idle, loaded }
            """, expected: nil, options: options)
        }
    }

    func testSliceOfSetReversesToAnArray() throws {
        try check("""
        func render(_ states: Slice<Set<State>>) { observeValue(states.reversed().first) }
        """, declarations: """
        enum State { case idle, loaded }
        extension Array { var first: Int { 0 } }
        """, expected: nil)
    }

    func testFunctionParameterCallRetainsDeclaredEnumResult() throws {
        try check("""
        func render(_ make: () -> State) { observeValue(make()) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testFunctionParameterCallRetainsOptionalResult() throws {
        try check("""
        func render(_ make: () -> State?) { observeValue(make()) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testParenthesizedFunctionValueCallRetainsEnumResult() throws {
        try check("""
        func render(_ make: () -> State) { observeValue((make)()) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testLocalClosureAnnotationSuppliesCalledResult() throws {
        try check("""
        func render() {
            let make: () -> State = { .idle }
            observeValue(make())
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testFunctionAliasCallRetainsDeclaredResult() throws {
        try check("""
        func render(_ make: Factory) { observeValue(make()) }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Factory = () -> State
        """, expected: "State")
    }

    func testGenericFunctionPropertyCallSubstitutesReceiverArguments() throws {
        try check("""
        func render(_ model: Model<State>) { observeValue(model.make()) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model<Value> { var make: () -> Value }
        """, expected: "State")
    }

    func testStaticFunctionPropertyCallRetainsEnumResult() throws {
        try check("""
        func render() { observeValue(Model.make()) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { static var make: () -> State }
        """, expected: "State")
    }

    func testChainedFunctionValueCallRetainsNestedSignature() throws {
        try check("""
        func render(_ make: () -> (() -> State)) { observeValue(make()()) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testFunctionValueResultRetainsCollectionElementMetadata() throws {
        try check("""
        func render(_ make: () -> [State]) { observeValue(make().first) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testFunctionValueResultRetainsTupleElementMetadata() throws {
        try check("""
        func render(_ make: () -> (Int, State)) { observeValue(make().1) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testOptionalFunctionCallAddsResultOptionality() throws {
        try check("""
        func render(_ make: (() -> State)?) { observeValue(make?()) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testForcedFunctionCallRetainsNonoptionalResult() throws {
        try check("""
        func render(_ make: (() -> State)?) { observeValue(make!()) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testOptionalMemberFunctionValueCallRetainsResult() throws {
        try check("""
        func render(_ model: Model<State>) { observeValue(model.make?()) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model<Value> { var make: (() -> Value)? }
        """, expected: "State", expectedOptional: true)
    }

    func testFunctionValueCallRejectsIncorrectArity() throws {
        try check("""
        func render(_ make: (Int) -> State) { observeValue(make()) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testFunctionValueCallRejectsUnexpectedArgumentLabel() throws {
        try check("""
        func render(_ make: (Int) -> State) { observeValue(make(value: opaque())) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testFunctionValueWithArgumentRetainsDeclaredEnumResult() throws {
        try check("""
        func render(_ make: (Int) -> State) { observeValue(make(opaque())) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testOptionalFunctionValueRequiresUnwrappingBeforeCalling() throws {
        try check("""
        func render(_ make: (() -> State)?) { observeValue(make()) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testProjectPropertyNamedLikeMethodDoesNotUseMethodSignature() throws {
        try check("""
        func render(_ model: Model) { observeValue(model.make()) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {
            var make: Int
            func make(_ value: Int = 0) -> State { .idle }
        }
        """, expected: nil)
    }

    func testImportedFunctionAliasKeepsResultDeclarationContext() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ make: Factory) { observeValue(make()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public typealias Factory = () -> State
        """], expectedCases: ["idle", "loaded"])
    }

    func testTernaryBranchesAgreeOnProjectEnum() throws {
        try check("""
        func render(_ flag: Bool, _ first: State, _ second: State) { observeValue(flag ? first : second) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testTernaryKnownOperandSuppliesShorthandCaseContext() throws {
        try check("""
        func render(_ flag: Bool, _ state: State) { observeValue(flag ? state : .idle) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testTernaryShorthandFirstOperandUsesOtherOperandContext() throws {
        try check("""
        func render(_ flag: Bool, _ state: State) { observeValue(flag ? .idle : state) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testNestedTernariesRetainCommonEnumType() throws {
        try check("""
        func render(_ flag: Bool, _ state: State) { observeValue(flag ? (flag ? .loaded : state) : state) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testRightAssociativeTernariesRetainCommonEnumType() throws {
        try check("""
        func render(_ flag: Bool, _ state: State) { observeValue(flag ? state : flag ? state : .idle) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testTernaryPromotesMatchingOptionalEnumOperand() throws {
        try check("""
        func render(_ flag: Bool, _ state: State, _ optional: State?) { observeValue(flag ? state : optional) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State", expectedOptional: true)
    }

    func testTernaryRejectsDifferentProjectEnums() throws {
        try check("""
        func render(_ flag: Bool, _ state: State, _ other: Other) { observeValue(flag ? state : other) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: nil)
    }

    func testTernaryDoesNotInferBothShorthandOperandsFromNames() throws {
        try check("""
        func render(_ flag: Bool) { observeValue(flag ? .idle : .loaded) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: nil)
    }

    func testNilCoalescingUnwrapsOptionalEnum() throws {
        try check("""
        func render(_ state: State?, _ fallback: State) { observeValue(state ?? fallback) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testNilCoalescingSuppliesFallbackCaseContext() throws {
        try check("""
        func render(_ state: State?) { observeValue(state ?? .idle) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testNilCoalescingRetainsOptionalFallbackType() throws {
        try check("""
        func render(_ state: State?, _ fallback: State?) { observeValue(state ?? fallback) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State", expectedOptional: true)
    }

    func testNilCoalescingResolvesRightAssociativeChain() throws {
        try check("""
        func render(_ first: State?, _ second: State?) { observeValue(first ?? second ?? .idle) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testNilCoalescingDoesNotIgnoreAnUnknownOperand() throws {
        try check("""
        func render(_ fallback: State) { observeValue(opaque() ?? fallback) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: nil)
    }

    func testNilCoalescingRejectsDifferentProjectEnumOperands() throws {
        try check("""
        func render(_ state: State?, _ fallback: Other) { observeValue(state ?? fallback) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: nil)
    }

    func testTernaryWithCoalescingUsesCorrectBranchBoundaries() throws {
        try check("""
        func render(_ flag: Bool, _ state: State?, _ fallback: State) { observeValue(flag ? state ?? fallback : fallback) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "State")
    }

    func testProjectNilCoalescingOverloadPreventsBuiltinInference() throws {
        try check("""
        func render(_ state: State?, _ fallback: State) { observeValue(state ?? fallback) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        func ?? (_ lhs: State?, _ rhs: State) -> Other { .unrelated }
        """, expected: nil)
    }

    func testTernaryOperandKeepsImportedEnumIdentity() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ flag: Bool, _ state: Models.State) { observeValue(flag ? .idle : state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLocalFunctionShadowsGlobalCallableVariable() throws {
        try check("""
        let make: () -> State = { .idle }
        func render() {
            func make() -> Other { .unrelated }
            observeValue(make())
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: nil)
    }

    func testLocalFunctionShadowsIndexedCallableProperty() throws {
        try check("""
        extension Model {
            func render() {
                func make() -> Other { .unrelated }
                observeValue(make())
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Model { let make: () -> State }
        """, expected: nil)
    }

    func testLocalNominalTypeShadowsGlobalCallableVariable() throws {
        try check("""
        let make: () -> State = { .idle }
        func render() {
            struct make {}
            observeValue(make())
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testLocalNominalTypeShadowsIndexedCallableProperty() throws {
        try check("""
        extension Model {
            func render() {
                struct make {}
                observeValue(make())
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let make: () -> State }
        """, expected: nil)
    }

    func testMapKeyPathRetainsProjectPropertyType() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.map(\\.state).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State? }
        """, expected: "State", expectedOptional: true)
    }

    func testMapExplicitRootKeyPathRetainsPropertyType() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.map(\\Model.state).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State? }
        """, expected: "State", expectedOptional: true)
    }

    func testMapIdentityKeyPathRetainsProjectEnum() throws {
        try check("""
        func render(_ states: [State]) { observeValue(states.map(\\.self).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State? }
        """, expected: "State", expectedOptional: true)
    }

    func testCompactMapKeyPathUnwrapsProjectPropertyType() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.compactMap(\\.optionalState).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State? }
        """, expected: "State", expectedOptional: true)
    }

    func testGenericReceiverKeyPathSubstitutesPropertyType() throws {
        try check("""
        func render(_ boxes: [Box<State>]) { observeValue(boxes.map(\\.value).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {}
        struct Box<Value> { let value: Value }
        """, expected: "State", expectedOptional: true)
    }

    func testGenericExplicitKeyPathRootKeepsTypeArguments() throws {
        try check("""
        func render(_ boxes: [Box<State>]) { observeValue(boxes.map(\\Box<State>.value).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {}
        struct Box<Value> { let value: Value }
        """, expected: "State", expectedOptional: true)
    }

    func testExplicitKeyPathRootCannotUseAnotherGenericSpecialization() throws {
        try check("""
        func render(_ boxes: [Box<State>]) { observeValue(boxes.map(\\Box<Model>.value).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model {}
        struct Box<Value> { let value: Value }
        """, expected: nil)
    }

    func testKeyPathTransformCannotUseAnUnrelatedRoot() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.map(\\State.self).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State; let optionalState: State? }
        """, expected: nil)
    }

    func testOptionalKeyPathChainPreservesBothMapOptionalLayers() throws {
        try check("""
        func render(_ boxes: [Box?]) {
            observeValue(boxes.map(\\.self?.state).first!)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box { let state: State }
        """, expected: "State", expectedOptional: true)
    }

    func testImportedKeyPathMemberKeepsDeclarationContext() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ models: [Model]) { observeValue(models.map(\\.state).first!) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public let state: State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testFlatMapKeyPathFlattensProjectCollections() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.flatMap(\\.states).first) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let states: [State] }
        """, expected: "State", expectedOptional: true)
    }

    func testIndexedCallbackDestructuresOneTupleInput() throws {
        try check("""
        func render() { observe { _, state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        func observe(_ callback: ((Int, State)) -> Void) {}
        """, expected: "State")
    }

    func testTupleInputWithoutDestructuringKeepsItsProjection() throws {
        try check("""
        func render() {
            let callback: ((Int, State)) -> Void = { pair in observeValue(pair.1) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testTupleClosureCannotInventAnExtraInput() throws {
        try check("""
        func render() {
            let callback: ((Int, State)) -> Void = { _, _, state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testMapPreservesNestedOptionalResultMetadata() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.map { $0.state }.first!) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State? }
        """, expected: "State", expectedOptional: true)
    }

    func testCompactMapRemovesExactlyOneOptionalLayer() throws {
        try check("""
        func render(_ models: [Model]) { observeValue(models.compactMap { $0.state }.first!) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State?? }
        """, expected: "State", expectedOptional: true)
    }

    func testParenthesizedCallableCannotIgnoreLocalTypeShadowing() throws {
        try check("""
        let make: () -> State = { .idle }
        func render() {
            struct make {}
            observeValue((make)())
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: nil)
    }

    func testParenthesizedCallableCannotIgnoreLocalFunctionShadowing() throws {
        try check("""
        let make: () -> State = { .idle }
        func render() {
            func make() -> Other { .unrelated }
            observeValue((make)())
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: nil)
    }

    func testOptionalTryWrapsTheEntireCoalescingExpression() throws {
        try check("""
        func render() { observeValue(try? make() ?? State.idle) }
        """, declarations: """
        enum State { case idle, loaded }
        func make() throws -> State? { .loaded }
        """, expected: "State", expectedOptional: true, options: FormatOptions(swiftVersion: "6"))
    }

    func testParenthesizedOptionalTryCanBeCoalescedToANonoptionalEnum() throws {
        try check("""
        func render() { observeValue((try? make()) ?? State.idle) }
        """, declarations: """
        enum State { case idle, loaded }
        func make() throws -> State { .loaded }
        """, expected: "State", options: FormatOptions(swiftVersion: "6"))
    }

    func testImportedOperatorOverloadPreventsCoalescingInference() throws {
        try checkModules("""
        import Models
        import Operators
        func render(_ state: State?) { observeValue(state ?? State.idle) }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            """,
            "Operators": """
            import Models
            public enum Other { case unrelated }
            public func ?? (_ lhs: State?, _ rhs: State) -> Other { .unrelated }
            """,
        ], expectedCases: nil)
    }

    func testUnimportedOperatorDoesNotHideBuiltinCoalescing() throws {
        try checkModules("""
        import Models
        func render(_ state: State?) { observeValue(state ?? State.idle) }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            """,
            "Operators": """
            import Models
            public enum Other { case unrelated }
            public func ?? (_ lhs: State?, _ rhs: State) -> Other { .unrelated }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testPrivateImportedOperatorDoesNotHideBuiltinCoalescing() throws {
        try checkModules("""
        import Models
        import Operators
        func render(_ state: State?) { observeValue(state ?? State.idle) }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            """,
            "Operators": """
            import Models
            enum Other { case unrelated }
            private func ?? (_ lhs: State?, _ rhs: State) -> Other { .unrelated }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testStandardResultSuccessPayloadKeepsProjectEnumType() throws {
        try check("""
        func render(_ result: Result<State, Error>) {
            if case let .success(state) = result { observeValue(state) }
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testStandardResultFailurePayloadKeepsProjectErrorType() throws {
        try check("""
        func render(_ result: Result<Int, LoadError>) {
            guard case let .failure(error) = result else { return }
            observeValue(error)
        }
        """, declarations: "enum LoadError: Error { case offline, rejected }", expected: "LoadError")
    }

    func testStandardResultNestedOptionalPayloadKeepsAllBindings() throws {
        try check("""
        func render(_ result: Result<State?, Error>?) {
            if case let .success(.some(state))? = result { observeValue(state) }
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testProjectResultUsesItsOwnPayloadDeclaration() throws {
        try check("""
        func render(_ result: Result<State, LoadError>) {
            if case let .success(other) = result { observeValue(other) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        enum LoadError: Error { case offline }
        enum Result<Value, Failure> { case success(Other), failure(Failure) }
        """, expected: "Other")
    }

    func testQualifiedSwiftResultIgnoresProjectResultNamesake() throws {
        try check("""
        func render(_ result: Swift.Result<State, Error>) {
            if case let .success(state) = result { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Result<Value, Failure> {}
        """, expected: "State")
    }

    func testSwiftNamespaceNamesakeDoesNotUseBuiltinResultPayloads() throws {
        try check("""
        func render(_ result: Swift.Result<State, Error>) {
            if case let .success(state) = result { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        enum Swift { enum Result<Value, Failure> { case success(Other), failure(Failure) } }
        """, expected: "Other")
    }

    func testResultPayloadPreservesImportedGenericArgumentIdentity() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ response: Response) {
            if case let .success(state) = response { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public typealias Response = Result<State, Error>
        """], expectedCases: ["idle", "loaded"])
    }

    func testStandardResultGetReturnsProjectSuccessType() throws {
        try check("""
        func render(_ result: Result<State, Error>) throws {
            observeValue(try result.get())
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testOptionalTryResultGetRetainsTheFailureNilCase() throws {
        try check("""
        func render(_ result: Result<State, Error>) {
            observeValue(try? result.get())
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State", expectedOptional: true)
    }

    func testOptionalResultGetRetainsOptionalChain() throws {
        try check("""
        func render(_ result: Result<State, Error>?) throws {
            observeValue(try result?.get())
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State", expectedOptional: true)
    }

    func testResultGetOverloadPreventsBuiltinSignatureAssumption() throws {
        try check("""
        func render(_ result: Result<State, Error>) throws {
            observeValue(try result.get())
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        extension Result where Success == State {
            func get() -> Other { .unrelated }
        }
        """, expected: nil)
    }

    func testResultAliasExtensionPreventsBuiltinGetAssumption() throws {
        try check("""
        func render(_ result: Response) {
            observeValue(try result.get())
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        typealias Response = Result<State, Error>
        extension Response {
            func get() -> Other { .unrelated }
        }
        """, expected: nil)
    }

    func testOtherIndexedResultMemberStillUsesItsDeclaration() throws {
        try checkModules("""
        enum State { case idle, loaded }
        func render(_ result: Result<State, Error>) {
            observeValue(result.resolvedState())
        }
        """, sources: ["Swift": """
        public enum Result<Success, Failure: Error> { case success(Success), failure(Failure) }
        public extension Result {
            func resolvedState() -> Success { fatalError() }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testArgumentTakingResultGetStillUsesItsDeclaration() throws {
        try checkModules("""
        enum State { case idle, loaded }
        func render(_ result: Result<State, Error>, fallback: State) {
            observeValue(result.get(fallback: fallback))
        }
        """, sources: ["Swift": """
        public enum Result<Success, Failure: Error> { case success(Success), failure(Failure) }
        public extension Result {
            func get(fallback: Success) -> Success { fallback }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testImportedResultGetPreservesSuccessDeclarationIdentity() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ response: Response) throws { observeValue(try response.get()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public typealias Response = Result<State, Error>
        """], expectedCases: ["idle", "loaded"])
    }

    func testProjectResultGetUsesItsOwnReturnType() throws {
        try check("""
        func render(_ result: Result<State, Error>) { observeValue(result.get()) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Result<Value, Failure> {
            func get() -> Other { .unrelated }
        }
        """, expected: "Other")
    }

    func testImportedExtensionPropertyKeepsItsDeclaringModule() throws {
        try checkModules("""
        import Models
        import Adapters
        enum State { case unrelated }
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public var state: State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testImportedExtensionFunctionKeepsItsDeclaringModule() throws {
        try checkModules("""
        import Models
        import Adapters
        enum State { case unrelated }
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testTransitivelyImportedExtensionIsVisible() throws {
        try checkModules("""
        import Facade
        func render() { observeValue(makeModel().state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
            "Facade": """
            import Models
            import Adapters
            public func makeModel() -> Model { fatalError() }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testImplementationOnlyExtensionDoesNotPropagate() throws {
        try checkModules("""
        import Facade
        func render() { observeValue(makeModel().state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
            "Facade": """
            import Models
            @_implementationOnly import Adapters
            public func makeModel() -> Model { fatalError() }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testImplementationOnlyExtensionIsVisibleInsideImportingModule() throws {
        try checkModules("""
        import Models
        @_implementationOnly import Adapters
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testExtensionOwnerUsesCanonicalModuleIdentity() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Models.Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "OtherModels": "public struct Model {}",
            "Adapters": """
            import OtherModels
            public enum State { case unrelated }
            extension Model { public func state() -> State { .unrelated } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testQualifiedExtensionOwnerDisambiguatesImportedNamesakes() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}; public enum State { case wrong }",
            "OtherModels": "public struct Model {}",
            "Adapters": """
            import Models
            import OtherModels
            public enum State { case idle, loaded }
            extension Models.Model { public func state() -> State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testUnimportedExtensionCannotSupplyMemberType() throws {
        try checkModules("""
        import Models
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testInternalImportedExtensionMemberIsInaccessible() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            enum State { case idle, loaded }
            extension Model { var state: State { .idle } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testImportedExtensionOverloadPreventsLabelOnlySelection() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.state(1)) }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public struct Model { public func state(_ value: Int) -> State { .idle } }
            """,
            "Adapters": """
            import Models
            public enum Other { case unrelated }
            extension Model { public func state(_ value: String) -> Other { .unrelated } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testImportedGenericExtensionRetainsReceiverArguments() throws {
        try checkModules("""
        import Models
        import Adapters
        enum State { case idle, loaded }
        func render(_ model: Box<State>) { observeValue(model.value()) }
        """, sources: [
            "Models": "public struct Box<Value> {}",
            "Adapters": """
            import Models
            public enum State { case unrelated }
            extension Box { public func value() -> Value { fatalError() } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testImportedGenericExtensionPropertyRetainsReceiverArguments() throws {
        try checkModules("""
        import Models
        import Adapters
        enum State { case idle, loaded }
        func render(_ model: Box<State>) { observeValue(model.value) }
        """, sources: [
            "Models": "public struct Box<Value> {}",
            "Adapters": """
            import Models
            public enum State { case unrelated }
            extension Box { public var value: Value { fatalError() } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testUnqualifiedMethodInImportedTypeExtension() throws {
        try checkModules("""
        import Models
        import Adapters
        extension Model {
            func render() { observeValue(state()) }
        }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testAliasExtensionCannotHideCompetingOverload() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.state(1)) }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public struct Model { public func state(_ value: Int) -> State { .idle } }
            """,
            "Adapters": """
            import Models
            public typealias Alias = Model
            public enum Other { case unrelated }
            extension Alias { public func state(_ value: String) -> Other { .unrelated } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testConstrainedExtensionUsesProvenReceiverRequirement() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Box<Int>) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Box<Value> {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Box where Value == Int { public func state() -> State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testImportedExtensionCallablePropertyIsCalledUsingItsSignature() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.make()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public var make: () -> State { { .idle } } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testImportedStaticExtensionMethod() throws {
        try checkModules("""
        import Models
        import Adapters
        func render() { observeValue(Model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public static func state() -> State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testSameModuleFileImportMakesExtensionAvailable() throws {
        try checkModules("""
        import Models
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
        ], otherAppSources: ["import Adapters"], expectedCases: ["idle", "loaded"])
    }

    func testConditionalImportContributesExtensionCandidates() throws {
        try checkModules("""
        import Models
        #if DEBUG
        import Adapters
        #endif
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testNestedAliasExtensionUsesItsLexicalOwner() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Outer.Model) { observeValue(model.state()) }
        """, sources: [
            "Models": """
            public struct Model {}
            public enum Outer {
                public struct Model {}
                public typealias Alias = Model
            }
            """,
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Outer.Alias { public func state() -> State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testNestedAliasExtensionDoesNotAttachToGlobalNamesake() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": """
            public struct Model {}
            public enum Outer {
                public struct Model {}
                public typealias Alias = Model
            }
            """,
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Outer.Alias { public func state() -> State { .idle } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testSpecializedExtensionCannotHideCompetingOverload() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Box<Int>) { observeValue(model.state(1)) }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public struct Box<Value> { public func state(_ value: Int) -> State { .idle } }
            """,
            "Adapters": """
            import Models
            public enum Other { case unrelated }
            extension Box<Int> { public func state(_ value: String) -> Other { .unrelated } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testExtensionConformanceCannotHideInheritedOverload() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.state(1)) }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public struct Model { public func state(_ value: Int) -> State { .idle } }
            """,
            "Adapters": """
            import Models
            public enum Other { case unrelated }
            public protocol Describing {}
            extension Describing { public func state(_ value: String) -> Other { .unrelated } }
            extension Model: Describing {}
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testTransitiveCollectionExtensionPreventsBuiltinSignatureAssumption() throws {
        try checkModules("""
        import Facade
        func render() { observeValue(makeStates().first) }
        """, sources: [
            "Models": "public enum State { case idle, loaded }",
            "Adapters": """
            import Models
            extension Array { public var first: Int { 0 } }
            """,
            "Facade": """
            import Models
            import Adapters
            public func makeStates() -> [State] { [] }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testExtensionMustBeAvailableInEveryModuleContainingSharedSource() throws {
        try checkModules("""
        import Models
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
        ], otherAppSources: ["import Adapters"], inputModules: ["App", "Tests"], expectedCases: nil, expectUnresolved: true)
    }

    func testExtensionPropertyMustBeAvailableInEverySharedSourceModule() throws {
        try checkModules("""
        import Models
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public var state: State { .idle } }
            """,
        ], otherAppSources: ["import Adapters"], inputModules: ["App", "Tests"], expectedCases: nil, expectUnresolved: true)
    }

    func testImportedExtensionIsAvailableInEverySharedSourceModule() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.state()) }
        """, sources: [
            "Models": "public struct Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public func state() -> State { .idle } }
            """,
        ], inputModules: ["App", "Tests"], expectedCases: ["idle", "loaded"])
    }

    func testSharedExtensionOwnerMustMatchInEveryCompilationContext() throws {
        try checkModules("""
                         import Models
                         func render(_ model: First) { observeValue(model.state()) }
                         """, sources: [
                             "Models": """
                             public struct First {}
                             public struct Second {}
                             public enum State { case idle, loaded }
                             """,
                             "AdapterA": "import Models; public typealias Model = First",
                             "AdapterB": "import Models; public typealias Model = Second",
                             "Shared": """
                             import Models
                             extension Model { public func state() -> State { .idle } }
                             """,
                             "Tests": "import AdapterB",
                         ], otherAppSources: ["import AdapterA"], inputModules: ["App", "Tests"],
                         sharedSources: ["Shared": ["AdapterA", "AdapterB"]], expectedCases: nil, expectUnresolved: true)
    }

    func testInferredGenericArrayPropertyKeepsReceiverElementType() throws {
        try check("""
        func render(_ holder: Holder<State>) { observeValue(holder.values.first) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Value { case unrelated }
        struct Holder<Value> { var values = [Value]() }
        """, expected: "State", expectedOptional: true)
    }

    func testInferredDictionaryPropertySuppliesItsValueType() throws {
        try check("""
        func render(_ holder: Holder, _ key: String) { observeValue(holder.values[key]) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Holder { var values = [String: State]() }
        """, expected: "State", expectedOptional: true)
    }

    func testLocalExplicitArrayConstructionSuppliesElementType() throws {
        try check("""
        func render() {
            let states = [State]()
            observeValue(states.first)
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testExplicitSetConstructionSuppliesElementType() throws {
        try check("""
        func render() { observeValue(Set<State>().first) }
        """, declarations: """
        enum State: Hashable { case idle, loaded }
        """, expected: "State", expectedOptional: true)
    }

    func testInferredGenericPropertyRetainsImportedArgumentProvenance() throws {
        try checkModules("""
        import Models
        enum State { case idle, loaded }
        func render(_ holder: Holder<State>) {
            for state in holder.values { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public struct Holder<Value> { public var values = [Value]() }
        """], expectedCases: ["idle", "loaded"])
    }

    func testInferredGenericEnumPropertySuppliesPayloadType() throws {
        try check("""
        func render(_ holder: Holder<State>) {
            if case let .loaded(state) = holder.request { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Request<Value> { case idle, loaded(Value) }
        extension Request { var isIdle: Bool { false } }
        struct Holder<Value> { var request = Request<Value>.idle }
        """, expected: "State")
    }

    func testInferredEnumPropertyUsesItsDeclaringModule() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ holder: Holder) { observeValue(holder.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Holder { public var state = State.idle }
        """], expectedCases: ["idle", "loaded"])
    }

    func testInferredConstructorPropertySuppliesNestedMemberType() throws {
        try check("""
        func render(_ holder: Holder) { observeValue(holder.model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { init() {}; let state: State = .idle }
        extension Model { func unused() {} }
        struct Holder { var model = Model() }
        """, expected: "State")
    }

    func testInferredFailableConstructorPropertyRetainsOptionality() throws {
        try check("""
        func render(_ holder: Holder) { observeValue(holder.model?.state) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { init?() {}; let state: State = .idle }
        struct Holder { var model = Model() }
        """, expected: "State", expectedOptional: true)
    }

    func testGlobalValueCannotBeMistakenForInitializerEnumRoot() throws {
        try checkModules("""
        import Models
        struct Holder { var state = Factory.initial }
        func render(_ holder: Holder) { observeValue(holder.state) }
        """, sources: ["Models": """
        public enum Factory { case initial, loaded }
        """], otherAppSources: ["""
        enum Other { case unrelated }
        struct RuntimeFactory { let initial: Other }
        let Factory = RuntimeFactory(initial: .unrelated)
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testPropertyValueCannotBeMistakenForInitializerEnumRoot() throws {
        try checkModules("""
        import Models
        struct Holder {
            static let Factory = RuntimeFactory(initial: .unrelated)
            var state = Holder.Factory.initial
        }
        func render(_ holder: Holder) { observeValue(holder.state) }
        """, sources: ["Models": """
        public enum Holder { public enum Factory { case initial, loaded } }
        """], otherAppSources: ["""
        enum Other { case unrelated }
        struct RuntimeFactory { let initial: Other }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testFactoryCannotBeMistakenForCollectionPropertyConstructor() throws {
        try checkModules("""
        import Models
        enum Other { case unrelated }
        struct Holder { var values = StateSet(0) }
        func StateSet(_ value: Int) -> [Other] { [] }
        func render(_ holder: Holder) { observeValue(holder.values.first) }
        """, sources: ["Models": """
        public enum State: Hashable { case idle, loaded }
        public typealias StateSet = Set<State>
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testQualifiedInheritedTypeRootTakesPrecedenceOverGlobalNamesake() throws {
        try check("""
        class Holder: Base { var state = Factory.State.idle }
        func render(_ holder: Holder) { observeValue(holder.state) }
        """, declarations: """
        class Base { enum Factory { enum State { case idle, loaded } } }
        enum Factory { enum State { case unrelated } }
        """, expected: "Base.Factory.State")
    }

    func testPropertyInitializerDoesNotGuessThroughUnknownInheritedNamespace() throws {
        try checkModules("""
        import Models
        class Holder: ExternalBase { var model = Models.Model(0) }
        func render(_ holder: Holder) { observeValue(holder.model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public init(_ value: String) {}; public let state: State = .idle }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testPayloadConstructorReferenceIsNotAnEnumValueInitializer() throws {
        try check("""
        func render(_ holder: Holder<State>) { observeValue(holder.make) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Request<Value> { case idle, loaded(Value) }
        struct Holder<Value> { var make = Request<Value>.loaded }
        """, expected: nil)
    }

    func testCollectionInitializerExtensionPreventsNonfailableAssumption() throws {
        try check("""
        func render(_ state: State) { observeValue([State](state)?.first) }
        """, declarations: """
        enum State { case idle, loaded }
        extension Array {
            init?(_ state: State) { self = [] }
        }
        """, expected: nil)
    }

    func testExtensionTargetsDoNotCountAsConstructorShadowingDeclarations() throws {
        try check("""
        func render() { observeValue(Model().state) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { init() {}; let state: State = .idle }
        extension Model { func unused() {} }
        """, expected: "State")
    }

    func testPropertyAnnotationDoesNotUseCallerLocalTypesForForeignNamespace() throws {
        try checkModules("""
        import Models
        enum Model { enum State { case unrelated } }
        func render(_ model: Models.Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Model { public let state: State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testClosureConstructorExcludesProtocolConstrainedGenericOverload() throws {
        try check("""
        func render() {
            Consumer<State> { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Sink { associatedtype Input; func consume(_ value: Input) }
        struct Consumer<Value>: Sink {
            init(handle: @escaping (Value) -> Void) {}
            init<Other: Sink>(_ other: Other) where Other.Input == Value {}
            func consume(_ value: Value) {}
        }
        """, expected: "State")
    }

    func testParenthesizedClosureExcludesGenericWhereBoundOverload() throws {
        try check("""
        func render() {
            Consumer<State>({ state in observeValue(state) })
        }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Sink { associatedtype Input; func consume(_ value: Input) }
        struct Consumer<Value> {
            init(_ handle: @escaping (Value) -> Void) {}
            init<Other>(_ other: Other) where Other: Sink, Other.Input == Value {}
        }
        """, expected: "State")
    }

    func testClosureFunctionExcludesAliasedImportedProtocolBound() throws {
        try checkModules("""
        import Models
        enum State { case callerOnly }
        func render() { consume { state in observeValue(state) } }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public protocol Sink { associatedtype Input; func consume(_ value: Input) }
        public typealias Bound = Sink
        """], otherAppSources: ["""
        import Models
        enum Event { case idle, loaded }
        func consume(handle: (Event) -> Void) {}
        func consume<Other: Bound>(_ other: Other) {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testClosureOverloadFilteringMapsDefaultedParameterPositions() throws {
        try check("""
        func render() { consume { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Sink { associatedtype Input }
        func consume(_ token: Int = 0, handle: (State) -> Void) {}
        func consume<Other: Sink>(_ token: Int = 0, _ other: Other) {}
        """, expected: "State")
    }

    func testClosureDoesNotExcludeUnconstrainedGenericOverload() throws {
        try check("""
        func render() { Consumer<State> { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        struct Consumer<Value> {
            init(handle: (Value) -> Void) {}
            init<Other>(_ other: Other) {}
        }
        """, expected: nil)
    }

    func testClosureDoesNotExcludeSendableGenericOverload() throws {
        try check("""
        func render() { Consumer<State> { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        struct Consumer<Value> {
            init(handle: (Value) -> Void) {}
            init<Other: Sendable>(_ other: Other) {}
        }
        """, expected: nil)
    }

    func testClosureDoesNotExcludeAnyOverload() throws {
        try check("""
        func render() { Consumer<State> { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        struct Consumer<Value> {
            init(handle: (Value) -> Void) {}
            init(_ other: Any) {}
        }
        """, expected: nil)
    }

    func testClosureDoesNotExcludeFunctionAliasOverload() throws {
        try check("""
        func render() { Consumer<State> { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Callback = (Int) -> Void
        struct Consumer<Value> {
            init(handle: (Value) -> Void) {}
            init(_ other: Callback) {}
        }
        """, expected: nil)
    }

    func testClosureBoundUsesNestedAliasInsteadOfGlobalProtocolNamesake() throws {
        try check("""
        func render() { Factory().consume { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Bound { associatedtype Input }
        struct Factory {
            typealias Bound = Sendable
            init() {}
            func consume(handle: (State) -> Void) {}
            func consume<Other: Bound>(_ other: Other) {}
        }
        """, expected: nil)
    }

    func testClosureDoesNotExcludeIndexedMarkerProtocolBound() throws {
        try check("""
        func render() { Consumer<State> { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        @_marker protocol Marker {}
        struct Consumer<Value> {
            init(handle: (Value) -> Void) {}
            init<Other: Marker>(_ other: Other) {}
        }
        """, expected: nil)
    }

    func testClosureDoesNotExcludeAmbiguousProtocolBound() throws {
        try check("""
        func render() { Consumer<State> { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        #if FIRST
        protocol Bound { associatedtype Input }
        #else
        protocol Bound { associatedtype Other }
        #endif
        struct Consumer<Value> {
            init(handle: (Value) -> Void) {}
            init<Other: Bound>(_ other: Other) {}
        }
        """, expected: nil)
    }

    func testClosureBoundKeepsPrivateNestedMarkerShadow() throws {
        try check("""
        struct Factory {
            @_marker private protocol Bound {}
            func consume(handle: (State) -> Void) {}
            private func consume<Other: Bound>(_ other: Other) {}
            func render() { consume { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Bound { associatedtype Input }
        """, expected: nil)
    }

    func testClosureBoundAliasKeepsPrivateNestedMarkerShadow() throws {
        try check("""
        struct Factory {
            @_marker private protocol Marker {}
            private typealias Bound = Marker
            func consume(handle: (State) -> Void) {}
            private func consume<Other: Bound>(_ other: Other) {}
            func render() { consume { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Marker { associatedtype Input }
        """, expected: nil)
    }

    func testClosureDoesNotExcludeUnknownProtocolBound() throws {
        try check("""
        func render() { Consumer<State> { state in observeValue(state) } }
        """, declarations: """
        import External
        enum State { case idle, loaded }
        struct Consumer<Value> {
            init(handle: (Value) -> Void) {}
            init<Other: ExternalProtocol>(_ other: Other) {}
        }
        """, expected: nil)
    }

    func testExplicitExistentialProtocolProperty() throws {
        try check("""
        func render(_ model: any Model) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Model { var state: State { get } }
        """, expected: "State")
    }

    func testConcreteProtocolRequirementProperty() throws {
        try check("""
        func render(_ model: Model) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Model { var state: State { get } }
        """, expected: "State")
    }

    func testPublicProtocolRequirementRetainsVisibilityAcrossModules() throws {
        try checkModules("""
        import Models
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Model { var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testConcreteProtocolExtensionPropertyKeepsImports() throws {
        try checkModules("""
        import Models
        import Adapters
        enum State { case unrelated }
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: [
            "Models": "public protocol Model {}",
            "Adapters": """
            import Models
            public enum State { case idle, loaded }
            extension Model { public var state: State { .idle } }
            """,
        ], expectedCases: ["idle", "loaded"])
    }

    func testConcreteProtocolPropertyInsideExtension() throws {
        try check("""
        extension Model { func render() { observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Model { var state: State { get } }
        """, expected: "State")
    }

    func testProtocolAssociatedTypePropertyRemainsUnknown() throws {
        try check("""
        func render(_ model: Model) { observeValue(model.state) }
        """, declarations: """
        enum State { case unrelated }
        protocol Model { associatedtype State; var state: State { get } }
        """, expected: nil)
    }

    func testConcretePropertyDoesNotDependOnPrimaryAssociatedTypeArguments() throws {
        try check("""
        func render(_ model: any Model<State>) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Model<Value> { associatedtype Value; var state: State { get } }
        """, expected: "State")
    }

    func testConstrainedProtocolExtensionPropertyRemainsUnknown() throws {
        try check("""
        func render(_ model: Model) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Model { associatedtype Value }
        extension Model where Value == Int { var state: State { .idle } }
        """, expected: nil)
    }

    func testCompetingProtocolExtensionPropertyRemainsUnknown() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: [
            "Models": """
            public enum State { case idle, loaded }
            public protocol Model { associatedtype Value }
            extension Model { public var state: State { .idle } }
            """,
            "Adapters": """
            import Models
            public enum State { case unrelated }
            extension Model where Value == Int { public var state: State { .unrelated } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testProtocolExtensionPropertyDoesNotReachUnrelatedNamesake() throws {
        try checkModules("""
        import Models
        import Adapters
        func render(_ model: Models.Model) { observeValue(model.state) }
        """, sources: [
            "Models": "public protocol Model {}",
            "Adapters": """
            public enum State { case unrelated }
            public protocol Model {}
            extension Model { public var state: State { .unrelated } }
            """,
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testConformanceExtensionUsesItsOwnProtocolImports() throws {
        try checkModules("""
        enum State { case idle, loaded }
        struct Model {
            func render(_ state: State) { observeValue(state) }
        }
        """, sources: ["Capabilities": "public protocol Marker {}"], otherAppSources: ["""
        import Capabilities
        extension Model: Marker {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testConformanceExtensionRetainsImportedAssociatedTypeShadow() throws {
        try checkModules("""
        enum State { case unrelated }
        struct Model {
            func render(_ state: State) { observeValue(state) }
        }
        """, sources: ["Capabilities": "public protocol Marker { associatedtype State; var value: State { get } }"], otherAppSources: ["""
        import Capabilities
        extension Model: Marker { var value: Int { 0 } }
        """], expectedCases: nil)
    }

    func testConformanceExtensionDoesNotUseDeclaringFilesProtocolNamesake() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        struct Model {
            func render(_ state: State) { observeValue(state) }
        }
        """, sources: [
            "Models": "public protocol Marker {}",
            "Capabilities": """
            public enum RemoteState { case idle, loaded }
            public protocol Marker { typealias State = RemoteState }
            """,
        ], otherAppSources: ["""
        import Capabilities
        extension Model: Marker {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testRefinedProtocolInheritsConcretePropertyRequirement() throws {
        try check("""
        func render(_ model: Child) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Parent { var state: State { get } }
        protocol Child: Parent {}
        """, expected: "State")
    }

    func testRefinedProtocolPropertyKeepsDefiningModule() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        protocol Child: Parent {}
        func render(_ model: Child) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Parent { var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testProtocolRefinementDeduplicatesDiamondRequirement() throws {
        try check("""
        func render(_ model: Child) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Parent { var state: State { get } }
        protocol First: Parent {}
        protocol Second: Parent {}
        protocol Child: First, Second {}
        """, expected: "State")
    }

    func testRefinedProtocolInheritsExtensionProperty() throws {
        try check("""
        extension Child { func render() { observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Parent {}
        extension Parent { var state: State { .idle } }
        protocol Child: Parent {}
        """, expected: "State")
    }

    func testRefinedProtocolAssociatedPropertyDoesNotUseGlobalNamesake() throws {
        try check("""
        func render(_ model: Child) { observeValue(model.state) }
        """, declarations: """
        enum State { case unrelated }
        protocol Parent { associatedtype State; var state: State { get } }
        protocol Child: Parent {}
        """, expected: nil)
    }

    func testRefinedProtocolDoesNotSelectCompetingRequirements() throws {
        try check("""
        func render(_ model: Child) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol First { var state: State { get } }
        protocol Second { var state: State { get } }
        protocol Child: First, Second {}
        """, expected: nil)
    }

    func testRefinedProtocolDoesNotIgnoreUnknownParent() throws {
        try check("""
        func render(_ model: Child) { observeValue(model.state) }
        """, declarations: """
        import External
        enum State { case idle, loaded }
        protocol Parent { var state: State { get } }
        protocol Child: Parent, ExternalProtocol {}
        """, expected: nil)
    }

    func testPrimaryAssociatedPropertyDoesNotUseGlobalNamesake() throws {
        try check("""
        func render(_ model: any Model<State>) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Model<Value> { associatedtype Value; var state: Value { get } }
        """, expected: nil)
    }

    func testRefinedProtocolInheritsCallableProperty() throws {
        try check("""
        func render(_ model: Child) { observeValue(model.load()) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Parent { var load: () -> State { get } }
        protocol Child: Parent {}
        """, expected: "State")
    }

    func testProtocolMarkerDoesNotHideDirectMethod() throws {
        try check("""
        func render(_ model: Model) { observeValue(model.load()) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Model: Sendable { func load() -> State }
        """, expected: "State")
    }

    func testRefinedProtocolMarkerDoesNotHideInheritedProperty() throws {
        try check("""
        func render(_ model: Child) { observeValue(model.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Parent { var state: State { get } }
        protocol Child: Parent, Sendable {}
        """, expected: "State")
    }

    func testStandardProtocolExtensionPropertyStillShadowsMethod() throws {
        try check("""
        func render(_ model: Model) { observeValue(model.load()) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Model: Sendable { func load() -> State }
        extension Sendable { var load: () -> State { { .idle } } }
        """, expected: nil)
    }

    func testConstructorCallbackInsideKnownProtocolConformer() throws {
        try check("""
        struct Renderer: Rendering {
            func render() { Handler<State> { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Rendering: Sendable {}
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testConstructedReceiverInsideKnownProtocolConformer() throws {
        try check("""
        struct Renderer: Rendering {
            func render() {
                let model = Model<State>()
                observeValue(model.state)
            }
        }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Rendering {}
        struct Model<Value> { init() {}; var state: Value { fatalError() } }
        """, expected: "State")
    }

    func testExplicitInitializerCallbackInsideKnownProtocolConformer() throws {
        try check("""
        struct Renderer: Rendering {
            func render() { Handler<State>.init { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Rendering {}
        struct Handler<Value> { init(_ callback: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testConstructorDoesNotIgnoreInheritedCallableProperty() throws {
        try check("""
        struct Renderer: Rendering {
            func render() { Handler { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol Rendering { var Handler: ((Other) -> Void) -> Void { get } }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testConstructorDoesNotIgnoreInheritedDynamicMemberLookup() throws {
        try check("""
        class Renderer: Base {
            func render() { Handler { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        @dynamicMemberLookup class Base {
            subscript(dynamicMember name: String) -> ((State) -> Void) -> Void { fatalError() }
        }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testConstructorDoesNotIgnoreStandardProtocolExtensionShadow() throws {
        try check("""
        struct Renderer: Equatable {
            func render() { Handler { state in observeValue(state) } }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        extension Equatable { var Handler: ((Other) -> Void) -> Void { fatalError() } }
        struct Handler { init(_ callback: (State) -> Void) {} }
        """, expected: nil)
    }

    func testConstructorProofRecognizesSynthesizedStandardProperty() {
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        let project = ProjectIndex(files: [url.path: makeSourceFileIndex(from: """
        struct Renderer: Hashable {}
        """, moduleIdentifiers: ["App"])])
        XCTAssertFalse(project.constructorRootIsUnshadowed("hashValue", in: "Renderer", visibleFrom: url))
    }

    func testMetatypeArgumentInfersGenericCallResult() throws {
        try check("""
        func render() { observeValue(load(State.self)) }
        """, declarations: """
        enum State { case idle, loaded }
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: "State")
    }

    func testAnnotatedMetatypeBindingInfersGenericCallResult() throws {
        try check("""
        func render(_ type: State.Type) { observeValue(load(type)) }
        """, declarations: """
        enum State { case idle, loaded }
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: "State")
    }

    func testMetatypeArgumentPropagatesThroughGenericCollection() throws {
        try check("""
        func render() { observeValue(events(ofType: Model.self).first?.state) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { var state: State }
        func events<Value>(ofType type: Value.Type) -> [Value] { [] }
        """, expected: "State", expectedOptional: true)
    }

    func testGenericNominalMetatypeRetainsTypeArguments() throws {
        try check("""
        func render() { observeValue(load(Box<State>.self).value) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Box<Value> { var value: Value }
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: "State")
    }

    func testImportedMetatypeAliasRetainsDeclarationContext() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render() { observeValue(load(Namespace.Status.self)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum Namespace { public typealias Status = State }
        public func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """], expectedCases: ["idle", "loaded"])
    }

    func testInstanceSelfPreservesItsValueType() throws {
        try check("""
        func render(_ state: State) { observeValue(state.self) }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testMetatypeParameterDoesNotAcceptInstanceArgument() throws {
        try check("""
        func render(_ state: State) { observeValue(load(state)) }
        """, declarations: """
        enum State { case idle, loaded }
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: nil)
    }

    func testGenericMetatypeDoesNotInventConcreteArgument() throws {
        try checkModules("""
        import Models
        func render<Value>(_: Value.Type) { observeValue(load(Value.self)) }
        """, sources: ["Models": """
        public enum Value { case unrelated }
        public func load<T>(_ type: T.Type) -> T { fatalError() }
        """], expectedCases: nil, expectedAbstractParameter: "Value")
    }

    func testHigherMetatypeDoesNotBecomeAnEnumInstance() throws {
        try check("""
        func render() { observeValue(load(State.Type.self)) }
        """, declarations: """
        enum State { case idle, loaded }
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: nil)
    }

    func testHigherMetatypeAliasDoesNotBecomeAnEnumInstance() throws {
        try check("""
        func render() { observeValue(load(Kind.self)) }
        """, declarations: """
        enum State { case idle, loaded }
        typealias Kind = State.Type
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: nil)
    }

    func testOptionalReferentMetatypeRemainsUnknown() throws {
        try check("""
        func render(_ type: (State?).Type) { observeValue(load(type)) }
        """, declarations: """
        enum State { case idle, loaded }
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: nil)
    }

    func testMetatypeInferenceDoesNotFixCovariantCallbackParameter() throws {
        try check("""
        func render() { visit(State.self) { value in observeValue(value) } }
        """, declarations: """
        enum State { case idle, loaded }
        func visit<Value>(_ type: Value.Type, _ callback: (Value) -> Void) {}
        """, expected: nil)
    }

    func testMetatypeValueCanPassThroughGenericIdentity() throws {
        try check("""
        func render() { observeValue(load(identity(State.self))) }
        """, declarations: """
        enum State { case idle, loaded }
        func identity<Value>(_ value: Value) -> Value { value }
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: "State")
    }

    func testGenericInferenceDistinguishesMetatypesFromInstances() throws {
        try check("""
        func render(_ state: State) { observeValue(choose(state, State.self)) }
        """, declarations: """
        enum State { case idle, loaded }
        func choose<Value>(_ first: Value, _ second: Value) -> Value { first }
        """, expected: nil)
    }

    func testOptionalMetatypeDoesNotEraseOptionalReferent() throws {
        try check("""
        func render(_ type: (State?).Type) { observeValue(load(type)) }
        """, declarations: """
        enum State { case idle, loaded }
        func load<Value>(_ type: Value.Type?) -> Value { fatalError() }
        """, expected: nil)
    }

    func testInheritedMetatypePropertyDoesNotUseGlobalTypeNamesake() throws {
        try check("""
        class Renderer: Base {
            func render() { observeValue(load(State.self)) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        class Base { var State: Other.Type { Other.self } }
        func load<Value>(_ type: Value.Type) -> Value { fatalError() }
        """, expected: nil)
    }

    func testNestedNamedInitializerCallbackReceivesExpectedType() throws {
        try check("""
        struct Renderer {
            private func consume(handler: Handler<State>) {}
            func render() { consume(handler: .init(handle: { state in observeValue(state) })) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(handle: (Value) -> Void) {} }
        """, expected: "State")
    }

    func testDoublyNestedInitializerCallbackReceivesExpectedType() throws {
        try check("""
        func render() { consume(options: .init(handler: .init(handle: { state in observeValue(state) }))) }
        """, declarations: """
        enum State { case idle, loaded }
        struct Handler<Value> { init(handle: (Value) -> Void) {} }
        struct Options<Value> { init(handler: Handler<Value>) {} }
        func consume(options: Options<State>) {}
        """, expected: "State")
    }

    func testNestedInitializerKeepsOuterOverloadAmbiguity() throws {
        try check("""
        func render() { consume(handler: .init(handle: { state in observeValue(state) })) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler<Value> { init(handle: (Value) -> Void) {} }
        func consume(handler: Handler<State>) {}
        func consume(handler: Handler<Other>) {}
        """, expected: nil)
    }

    func testSpecializedGenericEnumReferenceRetainsPayloadArguments() throws {
        try check("""
        func render() {
            let value = Event<State>.idle
            if case .value(let state) = value { observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Event<Value> { case idle, value(Value) }
        """, expected: "State")
    }

    func testGenericEnumReferenceCannotIgnoreLocalTypealiasShadow() throws {
        try check("""
        func render() {
            typealias Event<Value> = Other
            observeValue(Event<State>.idle)
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        enum Event<Value> { case idle, value(Value) }
        """, expected: nil)
    }

    func testGenericEnumPayloadConstructorIsNotAnEnumValue() throws {
        try check("""
        func render() { observeValue(Event<State>.value) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Event<Value> { case idle, value(Value) }
        """, expected: nil)
    }

    func testInheritedGenericPropertySubstitutesAcrossMultipleParents() throws {
        try check("""
        func render(_ model: Child<State>) { observeValue(model.value.first!) }
        """, declarations: """
        enum State { case idle, loaded }
        class Base<Element> { var value: Element { fatalError() } }
        class Middle<Item>: Base<[Item]> {}
        class Child<Value>: Middle<Value> {}
        """, expected: "State")
    }

    func testInheritedGenericMethodSubstitutesDeclaringReceiver() throws {
        try check("""
        func render(_ model: Child<State>) { observeValue(model.read()) }
        """, declarations: """
        enum State { case idle, loaded }
        class Base<Element> { func read() -> Element { fatalError() } }
        class Child<Value>: Base<Value> {}
        """, expected: "State")
    }

    func testInheritedGenericCallbackSubstitutesDeclaringReceiver() throws {
        try check("""
        func render(_ model: Child<State>) { model.observe { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        class Base<Element> { func observe(_ callback: (Element) -> Void) {} }
        class Child<Value>: Base<Value> {}
        """, expected: "State")
    }

    func testGenericAssociatedTypeAliasSuppliesCallbackParameter() throws {
        try check("""
        func render(_ model: Model<State>) { consume(model) { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { associatedtype Output }
        struct Model<Value>: Source { typealias Output = Value }
        func consume<Input: Source>(_ model: Input, handle: (Input.Output) -> Void) {}
        """, expected: "State")
    }

    func testInheritedAssociatedTypeAliasSubstitutesAncestorArguments() throws {
        try check("""
        func render(_ model: Child<State>) { observeValue(read(model)) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { associatedtype Output }
        class Base<Element>: Source { typealias Output = Element }
        class Child<Value>: Base<Value> {}
        func read<Input: Source>(_ model: Input) -> Input.Output { fatalError() }
        """, expected: "State")
    }

    func testAssociatedTypeInferredFromConcretePropertyWitness() throws {
        try check("""
        func render(_ model: Model<State>) { observeValue(read(model)) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { associatedtype Output; var value: Output { get } }
        struct Model<Value>: Source { var value: Value }
        func read<Input: Source>(_ model: Input) -> Input.Output { fatalError() }
        """, expected: "State")
    }

    func testAssociatedTypeDoesNotGuessUnwitnessedRequirement() throws {
        try check("""
        func render(_ model: any Source) { observeValue(read(model)) }
        """, declarations: """
        enum Output { case unrelated }
        protocol Source { associatedtype Output; var value: Output { get } }
        func read<Input: Source>(_ model: Input) -> Input.Output { fatalError() }
        """, expected: nil)
    }

    func testInheritedGenericOverloadsRemainAmbiguous() throws {
        try check("""
        func render(_ model: Child<State>) { observeValue(model.read()) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        class Base<Element> { func read(_ key: Int = 0) -> Element { fatalError() } }
        class Child<Value>: Base<Value> { func read(_ key: String = "") -> Other { fatalError() } }
        """, expected: nil)
    }

    func testAssociatedWitnessIgnoresSubclassAliasShadow() throws {
        try check("""
        func render(_ model: Child) { consume(model) { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol Source { associatedtype Output }
        class Base: Source { typealias Output = State }
        class Child: Base { typealias Output = Other }
        func consume<Input: Source>(_ model: Input, handle: (Input.Output) -> Void) {}
        """, expected: "State")
    }

    func testRecursiveInferredAssociatedWitnessTerminates() throws {
        try check("""
        func render(_ model: Loop) { observeValue(read(model)) }
        """, declarations: """
        protocol Source { associatedtype Output; var value: Output { get } }
        struct Loop: Source { var value = Box<Self.Output>() }
        struct Box<Value> { init() {} }
        func read<Input: Source>(_ model: Input) -> Input.Output { fatalError() }
        """, expected: nil)
    }

    func testNestedInitializerPreservesInnerOverloadAmbiguity() throws {
        try check("""
        func render() { consume(handler: .init(handle: { state in observeValue(state) })) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler {
            init(handle: (State) -> Void) {}
            init(handle: (Other) -> Void) {}
        }
        func consume(handler: Handler) {}
        """, expected: nil)
    }

    func testNestedInitializerKeepsLocalCallableShadow() throws {
        try check("""
        func render() {
            let consume: (Handler<Other>) -> Void
            consume(.init(handle: { state in observeValue(state) }))
        }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Handler<Value> { init(handle: (Value) -> Void) {} }
        func consume(_ handler: Handler<State>) {}
        """, expected: nil)
    }

    func testConditionalAliasAgreesAcrossExhaustiveBranches() throws {
        try check("""
        func render(_ state: Phase) { observeValue(state) }
        """, declarations: """
        enum State { case idle, loaded }
        #if FIRST
        typealias Phase = State
        #elseif SECOND
        typealias Phase = State
        #else
        typealias Phase = State
        #endif
        """, expected: "State")
    }

    func testConditionalAliasRequiresAllBranchesToAgree() throws {
        try check("""
        func render(_ state: Phase) { observeValue(state) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        #if FIRST
        typealias Phase = State
        #else
        typealias Phase = Other
        #endif
        """, expected: "Phase")
    }

    func testConditionalAliasDoesNotAssumeHostPlatform() throws {
        try check("""
        func render(_ state: Phase) { observeValue(state) }
        """, declarations: """
        enum State { case idle, loaded }
        #if os(iOS)
        typealias Phase = State
        #endif
        """, expected: "Phase")
    }

    func testAliasUsesItsOwnConditionalBranch() throws {
        try check("""
        enum State { case idle, loaded }
        enum Other { case unrelated }
        #if FIRST
        typealias Phase = State
        func render(_ state: Phase) { observeValue(state) }
        #else
        typealias Phase = Other
        #endif
        """, declarations: """
        """, expected: "State")
    }

    func testIndependentConditionalAliasesRemainAmbiguous() throws {
        try check("""
        func render(_ state: Phase) { observeValue(state) }
        """, declarations: """
        enum State { case idle, loaded }
        #if FIRST
        typealias Phase = State
        #endif
        #if SECOND
        typealias Phase = State
        #endif
        """, expected: "Phase")
    }

    func testNestedConditionalAliasesRequireCompleteCoverage() throws {
        try check("""
        func render(_ state: Phase) { observeValue(state) }
        """, declarations: """
        enum State { case idle, loaded }
        #if FIRST
        #if SECOND
        typealias Phase = State
        #else
        typealias Phase = State
        #endif
        #else
        typealias Phase = State
        #endif
        """, expected: "State")
    }

    func testSameTypeRequirementPropagatesAssociatedWitnessToReturnType() throws {
        try check("""
        func render(_ source: Model) { observeValue(read(source)) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = State }
        func read<Input: Source, Value>(_ input: Input) -> Value where Input.Output == Value { fatalError() }
        """, expected: "State")
    }

    func testSameTypeRequirementsReachAFixedPointRegardlessOfOrder() throws {
        try check("""
        func render(_ source: Model) { observeValue(read(source)) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = State }
        func read<Input: Source, Value, Result>(_ input: Input) -> Result where Value == Result, Input.Output == Value { fatalError() }
        """, expected: "State")
    }

    func testKnownArgumentTypeSelectsFunctionOverload() throws {
        try check("""
        func render(_ model: Model) { observeValue(read(model)) }
        """, declarations: """
        struct Model {}
        struct Other {}
        enum State { case idle, loaded }
        enum Unrelated { case other }
        func read(_ model: Model) -> State { .idle }
        func read(_ model: Other) -> Unrelated { .other }
        """, expected: "State")
    }

    func testKnownArgumentTypeSelectsConstructorCallback() throws {
        try check("""
        func render(_ model: Model) {
            Handler(model, handle: { state in observeValue(state) })
        }
        """, declarations: """
        struct Model {}
        struct Other {}
        enum State { case idle, loaded }
        enum Unrelated { case other }
        struct Handler {
            init(_ model: Model, handle: (State) -> Void) {}
            init(_ model: Other, handle: (Unrelated) -> Void) {}
        }
        """, expected: "State")
    }

    func testUnknownArgumentKeepsCompetingOverload() throws {
        try check("""
        func render() { observeValue(read(unknown())) }
        """, declarations: """
        struct Model {}
        struct Other {}
        enum State { case idle, loaded }
        enum Unrelated { case other }
        func read(_ model: Model) -> State { .idle }
        func read(_ model: Other) -> Unrelated { .other }
        """, expected: nil)
    }

    func testClassUpcastKeepsCompetingOverload() throws {
        try check("""
        func render(_ model: Child) { observeValue(read(model)) }
        """, declarations: """
        class Parent {}
        class Child: Parent {}
        enum State { case idle, loaded }
        enum Unrelated { case other }
        func read(_ model: Child) -> State { .idle }
        func read(_ model: Parent) -> Unrelated { .other }
        """, expected: nil)
    }

    func testConstrainedExtensionOverloadEliminatesUnequalReceiver() throws {
        try check("""
        func render(_ box: Box<State>) { observeValue(box.read()) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Box<Value> {}
        extension Box where Value == State { func read() -> State { .idle } }
        extension Box where Value == Other { func read() -> Other { .unrelated } }
        """, expected: "State")
    }

    func testUnprovenProtocolRequirementRetainsDefault() throws {
        try check("""
        func render<Value: Marker>(_ box: Box<Value>) { observeValue(box.read()) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Marker {}
        struct Box<Value> {}
        extension Box where Value: Marker { func read() -> State { .idle } }
        """, expected: nil)
    }

    func testEqualityRequirementUsesOriginalInheritedAssociatedWitness() throws {
        try check("""
        func render(_ source: Child) { observeValue(read(source)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol Source { associatedtype Output }
        class Parent: Source { typealias Output = State }
        class Child: Parent { typealias Output = Other }
        func read<Input: Source, Value>(_ input: Input) -> Value where Input.Output == Value { fatalError() }
        """, expected: "State")
    }

    func testGenericEqualityRejectsIncompatibleKnownOverload() throws {
        try check("""
        func render(_ source: Model) { observeValue(read(source)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = State }
        func read<Input: Source>(_ input: Input) -> State where Input.Output == State { .idle }
        func read<Input: Source>(_ input: Input) -> Other where Input.Output == Other { .unrelated }
        """, expected: "State")
    }

    func testSameTypeRequirementDoesNotExcludeAConvertibleClassArgument() throws {
        try check("""
        func render(_ child: Child) { observeValue(read(child)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        class Parent {}
        class Child: Parent {}
        func read<Value>(_ value: Value) -> State where Value == Parent { .idle }
        func read(_ value: Any) -> Other { .unrelated }
        """, expected: nil)
    }

    func testConditionalAliasContextDoesNotCrossFileBoundaries() throws {
        try check("""
        #if FIRST
        func render(_ state: Phase) { observeValue(state) }
        #endif
        """, declarations: """
        #if FIRST
        typealias Phase = State
        #else
        typealias Phase = Other
        #endif
        enum State { case idle, loaded }
        enum Other { case unrelated }
        """, expected: "Phase")
    }

    func testNestedConditionalAliasRejectsMissingInnerBranch() throws {
        try check("""
        func render(_ state: Phase) { observeValue(state) }
        """, declarations: """
        enum State { case idle, loaded }
        #if FIRST
        #if SECOND
        typealias Phase = State
        #endif
        #else
        typealias Phase = State
        #endif
        """, expected: "Phase")
    }

    func testOuterEqualityDoesNotConstrainShadowingMethodGeneric() throws {
        try check("""
        func render(_ box: Box<State, Model>, _ other: Other) { observeValue(box.read(other)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = State }
        struct Box<Value, Input: Source> where Input.Output == Value {
            func read<Value>(_ value: Value) -> Value { value }
            func read(_ value: Any) -> State { .idle }
        }
        """, expected: nil)
    }

    func testKnownStandardScalarSelectsOverloadWithoutSDKIndex() throws {
        try check("""
        func render(_ count: Int) { observeValue(read(count)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        func read(_ value: Int) -> State { .idle }
        func read(_ value: String) -> Other { .unrelated }
        """, expected: "State")
    }

    func testKnownInvariantGenericArgumentSelectsOverload() throws {
        try check("""
        func render(_ box: Box<State>) { observeValue(read(box)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Box<Value> {}
        func read(_ value: Box<State>) -> State { .idle }
        func read(_ value: Box<Other>) -> Other { .unrelated }
        """, expected: "State")
    }

    func testContextualLiteralKeepsItsCompetingOverload() throws {
        try check("""
        func render() { observeValue(read(1)) }
        """, declarations: """
        enum State { case idle, loaded }
        enum Other { case unrelated }
        struct Number: ExpressibleByIntegerLiteral { init(integerLiteral value: Int) {} }
        func read(_ value: Int) -> State { .idle }
        func read(_ value: Number) -> Other { .unrelated }
        """, expected: nil)
    }

    func testAssociatedEqualitySuppliesContextualCallbackParameter() throws {
        try check("""
        func render(_ model: Model) { observe(model) { state in observeValue(state) } }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Source { associatedtype Output }
        struct Model: Source { typealias Output = State }
        func observe<Input: Source, Value>(_ input: Input, callback: (Value) -> Void) where Input.Output == Value {}
        """, expected: "State")
    }

    func testEqualityDoesNotFixACovariantCallbackGeneric() throws {
        try check("""
        func render(_ child: Child) { observe(child) { value in observeValue(value) } }
        """, declarations: """
        class Parent {}
        class Child: Parent {}
        func observe<Input, Value>(_ input: Input, callback: (Value) -> Void) where Input == Value {}
        """, expected: nil)
    }

    func testStandardCollectionCovarianceKeepsCompetingOverload() throws {
        try checkModules("""
        func render(_ values: [Child]) { observeValue(read(values)) }
        """, sources: ["Swift": "public struct Array<Element> {}"], otherAppSources: ["""
        class Parent {}
        class Child: Parent {}
        enum State { case idle, loaded }
        enum Other { case unrelated }
        func read(_ values: [Child]) -> State { .idle }
        func read(_ values: [Parent]) -> Other { .unrelated }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testAliasExtensionResolvesInstancePropertyFromCanonicalOwner() throws {
        try checkModules("""
        import Models
        extension Namespace.Alias {
            func render() { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Payload { public let state: State }
        public enum Namespace { public typealias Alias = Payload }
        """], expectedCases: ["idle", "loaded"])
    }

    func testNestedTypeThroughAliasResolvesSelfInExtension() throws {
        try checkModules("""
        import Models
        extension Namespace.Alias.State {
            func render() { observeValue(self) }
        }
        """, sources: ["Models": """
        public struct Payload {
            public enum State { case idle, loaded }
        }
        public enum Namespace { public typealias Alias = Payload }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAliasExtensionResolvesExplicitSelfProperty() throws {
        try checkModules("""
        import Models
        extension Namespace.Alias {
            func render() { observeValue(self.state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Payload { public let state: State }
        public enum Namespace { public typealias Alias = Payload }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAliasExtensionResolvesStaticSelfProperty() throws {
        try checkModules("""
        import Models
        extension Namespace.Alias {
            static func render() { observeValue(Self.state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Payload { public static var state: State { .idle } }
        public enum Namespace { public typealias Alias = Payload }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAliasExtensionPreservesSpecializedGenericReceiver() throws {
        try checkModules("""
        import Models
        extension Namespace.Alias {
            func render() { observeValue(value) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Payload<Value> { public let value: Value }
        public enum Namespace { public typealias Alias = Payload<State> }
        """], expectedCases: ["idle", "loaded"])
    }

    func testQualifiedAliasMemberKeepsDeclarationModule() throws {
        try checkModules("""
        import Models
        struct Payload { enum State { case unrelated } }
        func render(_ state: Namespace.Alias.State) { observeValue(state) }
        """, sources: ["Models": """
        public struct Payload { public enum State { case idle, loaded } }
        public enum Namespace { public typealias Alias = Payload }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAliasExtensionKeepsLocalValueShadowing() throws {
        try checkModules("""
        import Models
        enum Local { case unrelated }
        extension Namespace.Alias {
            func render(_ state: Local) { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Payload { public let state: State }
        public enum Namespace { public typealias Alias = Payload }
        """], expectedCases: ["unrelated"])
    }

    func testConditionalAliasMemberRemainsAmbiguous() throws {
        try checkModules("""
        import Models
        func render(_ state: Namespace.Alias.State) { observeValue(state) }
        """, sources: ["Models": """
        public struct First { public enum State { case idle, loaded } }
        public struct Second { public enum State { case other } }
        public enum Namespace {
            #if FIRST
            public typealias Alias = First
            #else
            public typealias Alias = Second
            #endif
        }
        """], expectedCases: nil)
    }

    func testCyclicAliasMemberDoesNotResolve() throws {
        try checkModules("""
        import Models
        func render(_ state: Namespace.First.State) { observeValue(state) }
        """, sources: ["Models": """
        public enum Namespace {
            public typealias First = Second
            public typealias Second = First
        }
        """], expectedCases: nil)
    }

    func testAliasExtensionResolvesUnqualifiedStaticProperty() throws {
        try checkModules("""
        import Models
        extension Namespace.Alias {
            static func render() { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Payload { public static var state: State { .idle } }
        public enum Namespace { public typealias Alias = Payload }
        """], expectedCases: ["idle", "loaded"])
    }

    func testQualifiedAliasMemberResolvesMultipleNestedComponents() throws {
        try checkModules("""
        import Models
        func render(_ state: Namespace.Alias.Container.State) { observeValue(state) }
        """, sources: ["Models": """
        public struct Payload {
            public struct Container { public enum State { case idle, loaded } }
        }
        public enum Namespace { public typealias Alias = Payload }
        """], expectedCases: ["idle", "loaded"])
    }

    func testGenericFunctionPreservesNominalEnumWithAbstractArgument() throws {
        try checkModules("""
        import Models
        func render<Value>(_ event: Event<Value>) { observeValue(event) }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        """], expectedCases: ["idle", "loaded"])
    }

    func testGenericTypePreservesNominalEnumWithAbstractArgument() throws {
        try checkModules("""
        import Models
        struct Renderer<Value> {
            func render(_ event: Event<Value>) { observeValue(event) }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractGenericArgumentFlowsThroughArrayElement() throws {
        try checkModules("""
        import Models
        func render<Value>(_ events: [Event<Value>]) {
            for event in events { observeValue(event) }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractGenericArgumentSubstitutesIndexedProperty() throws {
        try checkModules("""
        import Models
        func render<Value>(_ box: Box<Value>) { observeValue(box.event) }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        public struct Box<Value> { public let event: Event<Value> }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractGenericDependentMemberCannotResolveNamesake() throws {
        try checkModules("""
        import Models
        func render<Payload: Model>(_ state: Payload.State) { observeValue(state) }
        """, sources: ["Models": """
        public protocol Model { associatedtype State }
        public struct Payload { public enum State { case idle, loaded } }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testAbstractGenericPropertyDoesNotCaptureNamesakeEnum() throws {
        try checkModules("""
        import Models
        func render<State>(_ box: Box<State>) { observeValue(box.value) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Box<Value> { public let value: Value }
        """], expectedCases: nil, expectedAbstractParameter: "State")
    }

    func testAbstractGenericParametersHaveLexicalIdentity() throws {
        let input = """
        func first<Value>(_ value: Value) { observeFirst(value) }
        func second<Value>(_ value: Value) { observeSecond(value) }
        """
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        let formatter = Formatter(tokenize(input))
        let lookup = ProjectSymbolLookup(formatter: formatter, project: ProjectIndex(files: [
            url.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ]), fileURL: url)
        let first = try XCTUnwrap(formatter.tokens.firstIndex(of: .identifier("observeFirst")))
        let second = try XCTUnwrap(formatter.tokens.firstIndex(of: .identifier("observeSecond")))
        let firstType = try XCTUnwrap(lookup.bindingType(named: "value", at: first, depth: 0))
        let secondType = try XCTUnwrap(lookup.bindingType(named: "value", at: second, depth: 0))
        let repeatedFirstType = try XCTUnwrap(lookup.bindingType(named: "value", at: first, depth: 0))
        XCTAssertTrue(lookup.sameType(firstType, as: repeatedFirstType))
        XCTAssertFalse(lookup.sameType(firstType, as: secondType))
        XCTAssertNil(lookup.qualifiedName(for: firstType))
        formatter.clearDerivedCaches()
    }

    func testAbstractMetatypeArgumentPreservesNominalEnum() throws {
        try checkModules("""
        import Models
        func render<Value>(_ event: Event<Value.Type>) { observeValue(event) }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLocalAliasShadowsEnclosingAbstractParameter() throws {
        try checkModules("""
        import Models
        struct Renderer<Value> {
            func render() {
                typealias Value = Unknown
                let event: Event<Value>
                observeValue(event)
            }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testLexicalGenericReceiverSubstitutesExplicitSelfProperty() throws {
        try checkModules("""
        import Models
        struct Renderer<Value>: Model {
            let event: Event<Value>
            func render() { observeValue(self.event) }
        }
        """, sources: ["Models": """
        public protocol Model {}
        public enum Event<Value> { case idle, loaded(Value) }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalGenericReceiverSubstitutesImplicitProperty() throws {
        try checkModules("""
        import Models
        extension Renderer {
            func render() { observeValue(event) }
        }
        """, sources: ["Models": """
        public struct Renderer<Value> { public let event: Event<Value> }
        public enum Event<Value> { case idle, loaded(Value) }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalGenericReceiverSubstitutesExplicitMethod() throws {
        try checkModules("""
        import Models
        struct Renderer<Value> {
            func event() -> Event<Value> { fatalError() }
            func render() { observeValue(self.event()) }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalGenericExtensionPreservesAbstractArguments() throws {
        try checkModules("""
        import Models
        extension Renderer {
            func render() { observeValue(self.event) }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        public struct Renderer<Value> { public let event: Event<Value> }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalGenericReceiverDoesNotCaptureNamesakePayload() throws {
        try checkModules("""
        import Models
        struct Renderer<State> {
            let value: State
            func render() { observeValue(self.value) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        """], expectedCases: nil, expectedAbstractParameter: "State")
    }

    func testIndexedGenericSelfReferenceRetainsReceiverArguments() throws {
        try checkModules("""
        import Models
        enum State { case idle, loaded }
        func render(_ model: Model<State>) { observeValue(model.copy().value) }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public struct Model<Value> {
            public let value: Value
            public func copy() -> Model { self }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testIndexedGenericSelfReferenceKeepsOwnerWhenMethodShadowsParameter() throws {
        try checkModules("""
        import Models
        enum State { case idle, loaded }
        func render(_ model: Model<State>, _ value: Int) { observeValue(model.copy(value).value) }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public struct Model<Value> {
            public let value: Value
            public func copy<Value>(_ other: Value) -> Model { self }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testIndexedGenericStaticMethodReturnsNominalInstance() throws {
        try checkModules("""
        import Models
        enum State { case idle, loaded }
        func render() { observeValue(Model<State>.copy().value) }
        """, sources: ["Models": """
        public struct Model<Value> {
            public let value: Value
            public static func copy() -> Model { fatalError() }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testIndexedGenericStaticMethodReturnsSelfInstance() throws {
        try checkModules("""
        import Models
        enum State { case idle, loaded }
        func render() { observeValue(Model<State>.copy().value) }
        """, sources: ["Models": """
        public struct Model<Value> {
            public let value: Value
            public static func copy() -> Self { fatalError() }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testIndexedStaticPropertyInitializerUsesDeclaredResultType() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Factory { public static var initial: State { .idle } }
        public struct Model { public var state = Factory.initial }
        """], expectedCases: ["idle", "loaded"])
    }

    func testIndexedStaticPropertyInitializerSubstitutesGenericOwner() throws {
        try checkModules("""
        import Models
        enum State { case idle, loaded }
        func render(_ model: Model<State>) {
            if case let .loaded(value) = model.state { observeValue(value) }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public enum Request<Value> {
            case idle, loaded(Value)
            public static var initial: Request { .idle }
        }
        public struct Model<Value> { public var state = Request<Value>.initial }
        """], expectedCases: ["idle", "loaded"])
    }

    func testIndexedStaticPropertyInitializerFollowsStoredDeclarationChain() throws {
        try checkModules("""
        import Models
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Factory {
            public static let seed = State.idle
            public static let initial = Factory.seed
        }
        public struct Model { public var state = Factory.initial }
        """], expectedCases: ["idle", "loaded"])
    }

    func testIndexedStaticPropertyInitializerCycleRemainsUnresolved() throws {
        try checkModules("""
        import Models
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public struct Factory {
            public static let initial = Factory.seed
            public static let seed = Factory.initial
        }
        public struct Model { public var state = Factory.initial }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testGenericEnumStaticSelfReturnPreservesPayloadSubstitution() throws {
        try checkModules("""
        import Models
        enum State { case idle, loaded }
        func render(_ type: Model<State>.Type) {
            if case let .loaded(value) = type.copy() { observeValue(value) }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public enum Model<Value> {
            case loaded(Value)
            public static func copy() -> Self { fatalError() }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testModuleQualifiedGenericStaticReceiverRetainsArguments() throws {
        try checkModules("""
        import Models
        enum State { case idle, loaded }
        func render() { observeValue(Models.Model<State>.copy().value) }
        """, sources: ["Models": """
        public struct Model<Value> {
            public let value: Value
            public static func copy() -> Model { fatalError() }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testIndexedStaticInitializerUsesLexicalPrivateMember() throws {
        try checkModules("""
        import Models
        enum Other { case unrelated }
        extension Factory { static var initial: Other { .unrelated } }
        func render(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Factory {
            private static var initial: State { .idle }
            public static var proxy = Factory.initial
        }
        public struct Model { public var state = Factory.proxy }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLocalCoalescingInitializerUsesShadowedParameter() throws {
        try check("""
        func render(_ state: State?, _ fallback: State) {
            let state = state ?? fallback
            observeValue(state)
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testLocalTernaryInitializerUsesShadowedParameter() throws {
        try check("""
        func render(_ state: State, _ flag: Bool) {
            let state = flag ? state : State.idle
            observeValue(state)
        }
        """, declarations: """
        enum State { case idle, loaded }
        """, expected: "State")
    }

    func testLocalMemberInitializerUsesShadowedParameter() throws {
        try check("""
        func render(_ value: Model) {
            let value = value.state
            observeValue(value)
        }
        """, declarations: """
        enum State { case idle, loaded }
        struct Model { let state: State }
        """, expected: "State")
    }

    func testImplicitGenericMethodReceiverPreservesArguments() throws {
        try checkModules("""
        import Models
        extension Renderer {
            func render() { observeValue(event()) }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        public struct Renderer<Value> {
            public func event() -> Event<Value> { fatalError() }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testImplicitGenericCallbackReceiverPreservesArguments() throws {
        try checkModules("""
        import Models
        extension Renderer {
            func render() {
                receive { event in observeValue(event) }
            }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        public struct Renderer<Value> {
            public func receive(_ body: (Event<Value>) -> Void) {}
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testImplicitGenericStaticReceiverPreservesArguments() throws {
        try checkModules("""
        import Models
        extension Renderer {
            static func render() { observeValue(event()) }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        public struct Renderer<Value> {
            public static func event() -> Event<Value> { fatalError() }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testImplicitInheritedGenericMethodProjectsReceiver() throws {
        try checkModules("""
        import Models
        final class Renderer<Value>: Base<Value> {
            func render() { observeValue(event()) }
        }
        """, sources: ["Models": """
        public enum Event<Value> { case idle, loaded(Value) }
        open class Base<Value> {
            public func event() -> Event<Value> { fatalError() }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testImplicitGenericCallbackPayloadRetainsAbstractIdentity() throws {
        try checkModules("""
        import Models
        extension Renderer {
            func render() {
                receive { event in
                    if case let .loaded(state) = event { observeValue(state) }
                }
            }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public enum Event<Value> { case idle, loaded(Value) }
        public struct Renderer<State> {
            public func receive(_ body: (Event<State>) -> Void) {}
        }
        """], expectedCases: nil, expectedAbstractParameter: "State")
    }

    func testNestedGenericParentPreservesPayloadType() throws {
        try checkModules("""
        import Models
        func render(_ event: Container<State>.Event) {
            if case let .loaded(state) = event { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Container<Value> {
            public enum Event { case idle, loaded(Value) }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testNestedTypeRetainsItsOwnGenericArguments() throws {
        try checkModules("""
        import Models
        func render(_ event: Container<State>.Event<Other>) {
            if case let .loaded(_, value) = event { observeValue(value) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum Other { case first, second }
        public struct Container<Value> {
            public enum Event<Detail> { case idle, loaded(Value, Detail) }
        }
        """], expectedCases: ["first", "second"])
    }

    func testNestedGenericParentMemberUsesOuterArgument() throws {
        try checkModules("""
        import Models
        func render(_ model: Container<State>.Model) { observeValue(model.value) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Container<Value> {
            public struct Model { public let value: Value }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testNestedGenericParentAliasUsesOuterArgument() throws {
        try checkModules("""
        import Models
        func render(_ value: Container<State>.Alias) { observeValue(value) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Container<Value> { public typealias Alias = Value }
        """], expectedCases: ["idle", "loaded"])
    }

    func testNestedGenericParentMethodResultPreservesArguments() throws {
        try checkModules("""
        import Models
        func render(_ model: Container<State>.Model) { observeValue(model.value()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Container<Value> {
            public struct Model { public func value() -> Value { fatalError() } }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testNestedGenericParentInferenceBindsOuterArgument() throws {
        try checkModules("""
        import Models
        func render(_ model: Container<State>.Model) { observeValue(extract(model)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Container<Value> { public struct Model {} }
        public func extract<Value>(_ model: Container<Value>.Model) -> Value { fatalError() }
        """], expectedCases: ["idle", "loaded"])
    }

    func testNestedGenericParentSpecializationsSelectOverload() throws {
        try checkModules("""
        import Models
        func render(_ model: Container<State>.Model) { observeValue(extract(model)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum Other { case unrelated }
        public struct Container<Value> { public struct Model {} }
        public func extract(_ model: Container<State>.Model) -> State { fatalError() }
        public func extract(_ model: Container<Other>.Model) -> Other { fatalError() }
        """], expectedCases: ["idle", "loaded"])
    }

    func testBareNestedTypeRetainsEnclosingSpecialization() throws {
        try checkModules("""
        import Models
        extension Container {
            func render(_ model: Model) { observeValue(model.value) }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public struct Container<State> {
            public struct Model { public let value: State }
        }
        """], expectedCases: nil, expectedAbstractParameter: "State")
    }

    func testNestedGenericParentAmbiguityPreservesUnknownType() throws {
        try checkModules("""
        import Models
        import Other
        func render(_ value: Container<Int>.Event) { observeValue(value) }
        """, sources: [
            "Models": "public struct Container<T> { public enum Event { case first } }",
            "Other": "public struct Container<T> { public enum Event { case second } }",
        ], expectedCases: nil, expectUnresolved: true)
    }

    func testNestedGenericParentCannotUseMissingArgumentNamesake() throws {
        try checkModules("""
        import Models
        func render(_ value: Container.Model) { observeValue(value.state) }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public struct Container<State> { public struct Model { public let state: State } }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testMultipleNestedGenericParentsPreserveOuterArgument() throws {
        try checkModules("""
        import Models
        func render(_ value: Container<State>.Middle<Int>.Model) { observeValue(value.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Container<Value> {
            public struct Middle<Detail> { public struct Model { public let state: Value } }
        }
        """], expectedCases: ["idle", "loaded"])
    }

    func testNestedGenericEnumValueRetainsPayloadSubstitution() throws {
        try checkModules("""
        import Models
        func render() {
            let event = Container<State>.Event.idle
            if case let .loaded(state) = event { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Container<Value> { public enum Event { case idle, loaded(Value) } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testNestedGenericOwnArgumentUsesCallerDeclaration() throws {
        try checkModules("""
        import Models
        enum State { case correct }
        func render(_ event: Container<Int>.Event<State>) {
            if case let .loaded(state) = event { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case wrong }
        public struct Container<Value> { public enum Event<Detail> { case loaded(Detail) } }
        """], expectedCases: ["correct"])
    }

    func testNestedGenericOwnArgumentRetainsAbstractIdentity() throws {
        try checkModules("""
        import Models
        func render<State>(_ event: Container<Int>.Event<State>) {
            if case let .loaded(state) = event { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public struct Container<Value> { public enum Event<Detail> { case loaded(Detail) } }
        """], expectedCases: nil, expectedAbstractParameter: "State")
    }

    func testNestedGenericInferenceBindsOwnArgument() throws {
        try checkModules("""
        import Models
        func render(_ event: Container<Int>.Event<State>) { observeValue(extract(event)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Container<Value> { public enum Event<Detail> { case loaded(Detail) } }
        public func extract<Detail>(_ event: Container<Int>.Event<Detail>) -> Detail { fatalError() }
        """], expectedCases: ["idle", "loaded"])
    }

    func testGenericAliasRetainsNestedArgumentCallerContext() throws {
        try checkModules("""
        import Models
        enum State { case correct }
        func render(_ event: Envelope<State>) {
            if case let .loaded(state) = event { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case wrong }
        public struct Container<Value> { public enum Event<Detail> { case loaded(Detail) } }
        public typealias Envelope<Detail> = Container<Int>.Event<Detail>
        """], expectedCases: ["correct"])
    }

    func testLexicalAssociatedTypeEqualityResolvesParameterAnnotation() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ state: Model.State, _: Model.Type) where Model.State == State {
            observeValue(state)
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testGenericTypeEqualityResolvesMethodParameter() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> where Model.State == State {
            func render(_ state: Model.State) { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testGenericExtensionEqualityResolvesMethodParameter() throws {
        try checkModules("""
        import Models
        extension Renderer where Model.State == State {
            func render(_ state: Model.State) { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State }
        public struct Renderer<Model: Modeling> {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testMethodEqualityRefinesEnclosingGenericParameter() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> {
            func render(_ state: Model.State) where Model.State == State { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalEqualityChainResolvesAssociatedType() throws {
        try checkModules("""
        import Models
        func render<First: Modeling, Second: Modeling>(_ state: First.State, _: First.Type, _: Second.Type)
            where First.State == Second.State, Second.State == State {
            observeValue(state)
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalEqualityTargetRetainsDeclarationNamespace() throws {
        try checkModules("""
        import Models
        enum State { case local }
        func render<Model: Modeling>(_ state: Model.State, _: Model.Type) where Model.State == State {
            observeValue(state)
        }
        """, sources: ["Models": """
        public enum State { case imported }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["local"])
    }

    func testLexicalEqualityDoesNotEscapeItsFunction() throws {
        try checkModules("""
        import Models
        func constrained<Model: Modeling>(_ state: Model.State, _: Model.Type) where Model.State == State {}
        func render<Model: Modeling>(_ state: Model.State, _: Model.Type) { observeValue(state) }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public protocol Modeling { associatedtype State }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testLexicalEqualityCycleDoesNotInventNominalType() throws {
        try checkModules("""
        import Models
        func render<First: Modeling, Second: Modeling>(_ state: First.State, _: First.Type, _: Second.Type)
            where First.State == Second.State {
            observeValue(state)
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public protocol Modeling { associatedtype State }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testLexicalEqualityResolvesNestedAssociatedMember() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ state: Model.State.Phase, _: Model.Type) where Model.State == State {
            observeValue(state)
        }
        """, sources: ["Models": """
        public struct State { public enum Phase { case idle, loaded } }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalEqualityTargetIgnoresBodyTypealiasShadow() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> where Model.State == State {
            func render(_ initial: Model.State) {
                typealias State = Other
                let state: Model.State = initial
                observeValue(state)
            }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum Other { case unrelated }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalEqualityDoesNotEscapeItsExtension() throws {
        try checkModules("""
        import Models
        extension Renderer where Model.State == State {
            func constrained(_ state: Model.State) {}
        }
        extension Renderer {
            func render(_ state: Model.State) { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public protocol Modeling { associatedtype State }
        public struct Renderer<Model: Modeling> {}
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testLexicalEqualityResolvesReversedRequirement() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ state: Model.State, _: Model.Type) where State == Model.State {
            observeValue(state)
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalEqualityChainUsesVisibleMethodRefinement() throws {
        try checkModules("""
        import Models
        struct Renderer<First: Modeling, Second: Modeling> where First.State == Second.State {
            func render(_ state: First.State) where Second.State == State { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalEqualityTargetIgnoresMethodGenericNamesake() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> where Model.State == State {
            func render<State>(_ state: Model.State, _: State.Type) { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testLexicalEqualityDoesNotConstrainShadowingMethodParameter() throws {
        // Swift 5 permits shadowing an enclosing generic parameter.
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> where Model.State == State {
            func render<Model: Modeling>(_ state: Model.State, _: Model.Type) { observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public protocol Modeling { associatedtype State }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testLexicalEqualityChainDoesNotBypassLocalAliasShadow() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> where Model.State == State {
            func render() {
                typealias Model = Other
                func nested<Item: Modeling>(_ state: Item.State, _: Item.Type) where Item.State == Model.State {
                    observeValue(state)
                }
            }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public enum OtherState { case other }
        public protocol Modeling { associatedtype State }
        public struct Other: Modeling { public typealias State = OtherState }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testLexicalEqualitySubjectDoesNotBypassLocalAliasShadow() throws {
        try checkModules("""
        import Models
        struct Renderer<First: Modeling, Second: Modeling> where First.State == Second.State {
            func render() {
                typealias Second = Other
                func nested<Item>(_ state: First.State, _: Item.Type) where Second.State == State {
                    observeValue(state)
                }
            }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public protocol Modeling { associatedtype State }
        public struct Other: Modeling { public typealias State = Models.State }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testAbstractProtocolBoundResolvesConcreteProperty() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractWhereBoundResolvesConcreteProperty() throws {
        try checkModules("""
        import Models
        func render<Model>(_ model: Model) where Model: Modeling { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractInheritedProtocolBoundResolvesProperty() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: RefinedModeling> {
            func render(_ model: Model) { observeValue(model.state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { var state: State { get } }
        public protocol RefinedModeling: Modeling {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractAssociatedPropertyUsesLexicalEquality() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) where Model.State == State { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State; var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractSelfAssociatedPropertyUsesLexicalEquality() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> where Model.State == State {
            func render(_ model: Model) { observeValue(model.state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State; var state: Self.State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractAssociatedPropertyRemainsUnresolvedWithoutEquality() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public protocol Modeling { associatedtype State; var state: State { get } }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testAbstractBoundRetainsDeclarationNamespace() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) {
            typealias Modeling = Other
            observeValue(model.state)
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public protocol Modeling { var state: State { get } }
        public protocol Other { var state: OtherState { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractClassBoundResolvesInheritedProperty() throws {
        try checkModules("""
        import Models
        func render<Model: Base>(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        open class Base { public var state: State { .idle } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractStoredReceiverUsesMethodRefinement() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> {
            let model: Model
            func render() where Model.State == State { observeValue(model.state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State; var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractComposedBoundsResolveAgreeingPropertyTypes() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second>(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol First { var state: State { get } }
        public protocol Second { var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractBoundUsesShadowingMethodGenericIdentity() throws {
        // This generic shadowing is permitted in Swift 5.
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> {
            func render<Model: Other>(_ model: Model) { observeValue(model.state) }
        }
        """, sources: ["Models": """
        public enum State { case unrelated }
        public enum OtherState { case correct }
        public protocol Modeling { var state: State { get } }
        public protocol Other { var state: OtherState { get } }
        """], expectedCases: ["correct"])
    }

    func testAbstractAssociatedDefaultDoesNotEstablishConcreteWitness() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum DefaultState { case unrelated }
        public protocol Modeling { associatedtype State = DefaultState; var state: State { get } }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testAbstractOptionalReceiverPreservesOptionalPropertyResult() throws {
        try check("""
        func render<Model: Modeling>(_ model: Model?) { observeValue(model?.state) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Modeling { var state: State { get } }
        """, expected: "State", expectedOptional: true)
    }

    func testAbstractMetatypeResolvesStaticProperty() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_: Model.Type) { observeValue(Model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { static var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractUnindexedAdditionalBoundDoesNotProveMemberLookup() throws {
        try checkModules("""
        import Foundation
        import Models
        func render<Model: Modeling & NSObjectProtocol>(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { var state: State { get } }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testAbstractSpecializedSuperclassBoundProjectsInheritedProperty() throws {
        try checkModules("""
        import Models
        func render<Model: Child<State>>(_ model: Model) { observeValue(model.state) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        open class Base<Value> {
            public let state: Value
            public init(_ value: Value) { state = value }
        }
        open class Child<Value>: Base<Value> {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractTupleReceiverRetainsVisibleMethodRefinement() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> {
            let stored: (model: Model, count: Int)
            func render() where Model.State == State { observeValue(stored.model.state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State; var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractCollectionReceiverRetainsVisibleMethodRefinement() throws {
        try checkModules("""
        import Models
        struct Renderer<Model: Modeling> {
            let models: [Model]
            func render() where Model.State == State { observeValue(models[0].state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State; var state: State { get } }
        """], expectedCases: ["idle", "loaded"])
    }

    func testAbstractSuperclassBoundRetainsVisibleArgumentRefinement() throws {
        try checkModules("""
        import Models
        struct Renderer<Value, Model: Child<Value>> {
            let model: Model
            func render() where Value == State { observeValue(model.state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        open class Base<Value> {
            public let state: Value
            public init(_ value: Value) { state = value }
        }
        open class Child<Value>: Base<Value> {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedReceiverMethodResolvesConcreteResult() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) { observeValue(model.load()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { func load() -> State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedReceiverMethodResolvesAssociatedResult() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) where Model.State == State { observeValue(model.load()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State; func load() -> State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedReceiverCallbackResolvesAssociatedParameter() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) where Model.State == State {
            model.load { state in observeValue(state) }
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { associatedtype State; func load(_ callback: (State) -> Void) }
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedReceiverMethodProjectsGenericSuperclass() throws {
        try checkModules("""
        import Models
        func render<Model: Child<State>>(_ model: Model) { observeValue(model.load()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        open class Base<Value> {
            public let value: Value
            public init(_ value: Value) { self.value = value }
            public func load() -> Value { value }
        }
        open class Child<Value>: Base<Value> {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedReceiverOverloadUsesKnownArgumentTypeAcrossBounds() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second>(_ model: Model, _ count: Int) { observeValue(model.load(count)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public protocol First { func load(_ count: Int) -> State }
        public protocol Second { func load(_ name: String) -> OtherState }
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedReceiverDeduplicatesSharedInheritedRequirement() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second>(_ model: Model) { observeValue(model.load()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { func load() -> State }
        public protocol First: Modeling {}
        public protocol Second: Modeling {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedMetatypeResolvesStaticMethodResult() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_: Model.Type) { observeValue(Model.load()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public protocol Modeling { static func load() -> State }
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedReceiverUnknownAdditionalAncestryPreventsOverloadSelection() throws {
        try checkModules("""
        import Models
        func render<Model: First & ExternalAncestor>(_ model: Model) { observeValue(model.load()) }
        """, sources: ["Models": """
        import Foundation
        public enum State { case idle, loaded }
        public protocol First { func load() -> State }
        public protocol ExternalAncestor: NSObjectProtocol {}
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testConstrainedReceiverOverloadResolvesSelfAssociatedArgument() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second>(_ model: Model, _ other: OtherState) where Model.State == State {
            observeValue(model.load(other))
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case correct }
        public protocol First { associatedtype State; func load(_ state: Self.State) -> Self.State }
        public protocol Second { func load(_ state: OtherState) -> OtherState }
        """], expectedCases: ["correct"])
    }

    func testConstrainedOptionalReceiverMethodPreservesOptionalResult() throws {
        try check("""
        func render<Model: Modeling>(_ model: Model?) { observeValue(model?.load()) }
        """, declarations: """
        enum State { case idle, loaded }
        protocol Modeling { func load() -> State }
        """, expected: "State", expectedOptional: true)
    }

    func testConstrainedReceiverDoesNotInferIncompatibleCallablePropertyResult() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second>(_ model: Model, _ count: Int) { observeValue(model.load(count)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public protocol First { func load(_ count: Int) -> State }
        public protocol Second { var load: (String) -> OtherState { get } }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testConstrainedReceiverDoesNotAssumeAbstractArgumentFitsCallableProperty() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second, Value>(_ model: Model, _ value: Value) { observeValue(model.load(value)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public protocol First { func load(_ value: Any) -> State }
        public protocol Second { var load: (String) -> OtherState { get } }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testParenthesizedConstrainedMemberRetainsCallableApplicabilityProof() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second, Value>(_ model: Model, _ value: Value) { observeValue((model.load)(value)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public protocol First { func load(_ value: Any) -> State }
        public protocol Second { var load: (String) -> OtherState { get } }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testParenthesizedConstrainedMemberUsesCompatibleCallableProperty() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second>(_ model: Model, _ count: Int) { observeValue((model.load)(count)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case correct }
        public protocol First { func load(_ count: Int) -> State }
        public protocol Second { var load: (Int) -> OtherState { get } }
        """], expectedCases: ["correct"])
    }

    func testConstrainedReceiverUsesCompatibleCallableProperty() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second>(_ model: Model, _ count: Int) { observeValue(model.load(count)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case correct }
        public protocol First { func load(_ count: Int) -> State }
        public protocol Second { var load: (Int) -> OtherState { get } }
        """], expectedCases: ["correct"])
    }

    func testConstrainedReceiverUnknownArgumentPreservesOverloadAmbiguity() throws {
        try checkModules("""
        import Models
        func render<Model: First & Second, Value>(_ model: Model, _ value: Value) { observeValue(model.load(value)) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public protocol First { func load(_ value: Any) -> State }
        public protocol Second { func load(_ value: Int) -> OtherState }
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testConstrainedReceiverDistinguishesStaticAndInstanceMethods() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_ model: Model) { observeValue(model.load()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public protocol Modeling { func load() -> State; static func load() -> OtherState }
        """], expectedCases: ["idle", "loaded"])
    }

    func testConstrainedMetatypeDistinguishesStaticAndInstanceMethods() throws {
        try checkModules("""
        import Models
        func render<Model: Modeling>(_: Model.Type) { observeValue(Model.load()) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case correct }
        public protocol Modeling { func load() -> State; static func load() -> OtherState }
        """], expectedCases: ["correct"])
    }

    func testTernaryTrueClosureInheritsAnnotatedFunctionType() throws {
        try check("""
        func render(_ enabled: Bool) {
            let callback: ((State) -> Void)? = enabled ? { state in observeValue(state) } : nil
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testTernaryFalseClosureInheritsAssignedMemberType() throws {
        try check("""
        func render(_ model: Model, _ enabled: Bool) {
            model.callback = enabled ? nil : { state in observeValue(state) }
        }
        """, declarations: """
        enum State { case idle, loaded }
        class Model { var callback: ((State) -> Void)? }
        """, expected: "State")
    }

    func testNestedTernaryClosureInheritsOuterExpectedType() throws {
        try check("""
        func render(_ first: Bool, _ second: Bool) {
            let callback: ((State) -> Void)? = first ? nil : second ? { state in observeValue(state) } : nil
        }
        """, declarations: "enum State { case idle, loaded }", expected: "State")
    }

    func testParenthesizedClosureInheritsCallArgumentType() throws {
        try checkModules("""
        import Models
        func render() { listen(({ state in observeValue(state) })) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public func listen(_ callback: (State) -> Void) {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testParenthesizedInitializerInheritsGenericParameterType() throws {
        try checkModules("""
        import Models
        enum State { case unrelated }
        func render() { listen((.init(callback: { state in observeValue(state) }))) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Receiver<Value> { public init(callback: (Value) -> Void) {} }
        public func listen(_ receiver: Receiver<State>) {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testTernaryInitializerInheritsGenericParameterType() throws {
        try checkModules("""
        import Models
        func render(_ enabled: Bool) {
            listen(enabled ? nil : .init(callback: { state in observeValue(state) }))
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public struct Receiver<Value> { public init(callback: (Value) -> Void) {} }
        public func listen(_ receiver: Receiver<State>?) {}
        """], expectedCases: ["idle", "loaded"])
    }

    func testTernaryCallbackDoesNotSelectUnknownOverloadFromCaseNames() throws {
        try checkModules("""
        import Models
        func render(_ enabled: Bool) { listen(enabled ? nil : { state in observeValue(state) }) }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public func listen(_ callback: ((State) -> Void)?) {}
        public func listen(_ callback: ((OtherState) -> Void)?) {}
        """], expectedCases: nil, expectUnresolved: true)
    }

    func testTernaryConditionCallbackUsesItsOwnParameterContext() throws {
        try checkModules("""
        import Models
        func render() {
            let callback: ((OtherState) -> Void)? = predicate { state in observeValue(state) } ? nil : nil
        }
        """, sources: ["Models": """
        public enum State { case idle, loaded }
        public enum OtherState { case unrelated }
        public func predicate(_ callback: (State) -> Void) -> Bool { true }
        """], expectedCases: ["idle", "loaded"])
    }

    func testGroupedClosureCastDoesNotBorrowOuterFunctionParameters() throws {
        try check("""
        func render() {
            let callback: (State) -> Void = ({ value in observeValue(value) } as (Any) -> Void)
        }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testTernaryClosureCastDoesNotBorrowOuterFunctionParameters() throws {
        try check("""
        func render(_ enabled: Bool) {
            let callback: ((State) -> Void)? = enabled ? ({ value in observeValue(value) } as (Any) -> Void) : nil
        }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    func testInvokedGroupedClosureDoesNotBorrowItsResultFunctionParameters() throws {
        try check("""
        func render() {
            let callback: (State) -> Void = ({ value in
                observeValue(value)
                return { (_: State) in }
            })(0)
        }
        """, declarations: "enum State { case idle, loaded }", expected: nil)
    }

    private func checkModules(_ input: String, sources: [String: String], otherAppSources: [String] = [], inputModules: Set<String> = ["App"], sharedSources: [String: Set<String>] = [:], expectedCases: [String]?, expectUnresolved: Bool = false, expectedAbstractParameter: String? = nil,
                              file: StaticString = #filePath, line: UInt = #line) throws
    {
        let url = URL(fileURLWithPath: "/Project/Input.swift")
        var files = [url.path: makeSourceFileIndex(from: input, moduleIdentifiers: inputModules, moduleNames: Dictionary(uniqueKeysWithValues: inputModules.map { ($0, $0) }))]
        for (index, source) in otherAppSources.enumerated() {
            files["/Project/AppExtra\(index).swift"] = makeSourceFileIndex(from: source, moduleIdentifiers: ["App"], moduleNames: ["App": "App"])
        }
        for (module, source) in sources {
            let identifiers = sharedSources[module] ?? [module]
            files["/Project/\(module).swift"] = makeSourceFileIndex(from: source, moduleIdentifiers: identifiers,
                                                                    moduleNames: Dictionary(uniqueKeysWithValues: identifiers.map { ($0, $0) }))
        }
        let project = ProjectIndex(files: files)
        let formatter = Formatter(tokenize(input))
        let lookup = ProjectSymbolLookup(formatter: formatter, project: project, fileURL: url)
        let observe = try XCTUnwrap(formatter.tokens.firstIndex(of: .identifier("observeValue")), file: file, line: line)
        let open = try XCTUnwrap(formatter.index(of: .startOfScope("("), after: observe), file: file, line: line)
        let close = try XCTUnwrap(formatter.endOfScope(at: open), file: file, line: line)
        let type = lookup.expressionType(in: open + 1 ... close - 1)
        if expectUnresolved {
            XCTAssertNil(type, file: file, line: line)
        }
        if let expectedAbstractParameter {
            let abstract = try XCTUnwrap(type, file: file, line: line)
            XCTAssertEqual(abstract.name, expectedAbstractParameter, file: file, line: line)
            XCTAssertNotNil(abstract.genericParameterScope, file: file, line: line)
            XCTAssertNil(lookup.qualifiedName(for: abstract), file: file, line: line)
        }
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
