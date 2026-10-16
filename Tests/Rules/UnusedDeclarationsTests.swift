//
//  UnusedDeclarationsTests.swift
//  SwiftFormatTests
//
//  Created by Manny Lopez on 7/17/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class UnusedDeclarationsTests: XCTestCase {
    private func testProjectFormatting(
        for input: String,
        _ output: String? = nil,
        references: String,
        visibility: VisibilityThreshold,
        declarationModules: Set<String> = ["App"],
        referenceModules: Set<String> = ["App"],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        _ = FormatRules.all
        let declarationsURL = URL(fileURLWithPath: "/Project/Sources/App/Declarations.swift")
        let referencesURL = URL(fileURLWithPath: "/Project/Sources/App/References.swift")
        let projectIndex = ProjectIndex(files: [
            declarationsURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: declarationModules),
            referencesURL.path: makeSourceFileIndex(from: references, moduleIdentifiers: referenceModules),
        ])
        let result = try applyRules(
            [.unusedDeclarations],
            to: tokenize(input),
            with: FormatOptions(unusedVisibility: visibility),
            trackChanges: false,
            range: nil,
            context: FormattingContext(currentFileURL: declarationsURL, projectIndex: projectIndex)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output ?? input, file: file, line: line)
    }

    func testDefaultVisibilityPreservesInternalDeclaration() {
        let input = """
        func unused() {}
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testFileVisibilityRemovesPrivateAndFileprivateDeclarations() {
        let input = """
        fileprivate func unused() {}
        private func alsoUnused() {}
        """
        testFormatting(
            for: input,
            """
            """,
            rule: .unusedDeclarations,
            options: FormatOptions(unusedVisibility: .file),
            exclude: [.redundantFileprivate]
        )
    }

    func testInternalVisibilityRemovesUnusedInternalDeclaration() throws {
        let input = """
        internal func unused() {}
        """
        try testProjectFormatting(
            for: input,
            "",
            references: "",
            visibility: .internal
        )
    }

    func testInternalVisibilityPreservesCrossFileReferenceInSameModule() throws {
        let input = """
        internal func performWork() {}
        """
        try testProjectFormatting(
            for: input,
            references: "performWork()",
            visibility: .internal
        )
    }

    func testInternalVisibilityIgnoresReferenceInAnotherModule() throws {
        let input = """
        internal func performWork() {}
        """
        try testProjectFormatting(
            for: input,
            "",
            references: "performWork()",
            visibility: .internal,
            referenceModules: ["Library"]
        )
    }

    func testPackageVisibilityPreservesReferenceInAnotherModule() throws {
        let input = """
        package var sharedValue = 0
        """
        try testProjectFormatting(
            for: input,
            references: "print(sharedValue)",
            visibility: .package,
            referenceModules: ["Library"]
        )
    }

    func testPublicVisibilityRemovesUnusedPublicDeclaration() throws {
        let input = """
        public func unusedAPI() {}
        """
        try testProjectFormatting(
            for: input,
            "",
            references: "",
            visibility: .public
        )
    }

    func testWiderVisibilityPreservesDeclarationWithoutProjectContext() {
        let input = """
        func unused() {}
        """
        testFormatting(
            for: input,
            rule: .unusedDeclarations,
            options: FormatOptions(unusedVisibility: .internal)
        )
    }

    func testRemoveUnusedPrivate() {
        let input = """
        struct Foo {
            private var foo = "foo"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testPreservePropertyParticipatingInSynthesizedEquatableConformance() {
        let input = """
        struct Token: Equatable {
            private let uuid: UUID = .init()
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testPreservePropertyParticipatingInQualifiedEquatableConformance() {
        let input = """
        struct Token: Swift.Equatable {
            private let uuid: UUID = .init()
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotPreservePropertyParticipatingInCustomQualifiedEquatableConformance() {
        let input = """
        struct Token: MyModule.Equatable {
            private let uuid: UUID = .init()
            let value: Int
        }
        """
        let output = """
        struct Token: MyModule.Equatable {
            let value: Int
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testPreservePropertyParticipatingInSynthesizedHashableConformance() {
        let input = """
        struct Token: Hashable {
            private let uuid: UUID = .init()
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testPreservePropertyParticipatingInQualifiedHashableConformance() {
        let input = """
        struct Token: Swift.Hashable {
            private let uuid: UUID = .init()
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotPreservePropertyParticipatingInCustomQualifiedHashableConformance() {
        let input = """
        struct Token: MyModule.Hashable {
            private let uuid: UUID = .init()
            let value: Int
        }
        """
        let output = """
        struct Token: MyModule.Hashable {
            let value: Int
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testPreservePropertyWhenConformanceUsesTypealiasOrRefiningProtocol() {
        let input = """
        typealias ValueEquatable = Swift.Equatable
        typealias IndirectEquatable = ValueEquatable

        protocol ValueHashable: Swift.Hashable {}
        protocol IndirectHashable: ValueHashable {}

        struct EquatableToken: IndirectEquatable {
            private let uuid: UUID = .init()
        }

        struct HashableToken: IndirectHashable {
            private let uuid: UUID = .init()
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testPreservePropertyWhenConformanceUsesProtocolCompositionTypealias() {
        let input = """
        typealias EquatableValue = Swift.Equatable & Sendable
        typealias HashableValue = Sendable & Swift.Hashable

        struct EquatableToken: EquatableValue {
            private let uuid: UUID = .init()
        }

        struct HashableToken: HashableValue {
            private let uuid: UUID = .init()
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotPreservePropertyWhenTypealiasOrRefiningProtocolIsCustomQualified() {
        let input = """
        typealias CustomEquatable = MyModule.Equatable
        protocol CustomHashable: MyModule.Hashable {}

        struct EquatableToken: CustomEquatable {
            private let equatableUUID: UUID = .init()
            let value: Int
        }

        struct HashableToken: CustomHashable {
            private let hashableUUID: UUID = .init()
            let value: Int
        }
        """
        let output = """
        typealias CustomEquatable = MyModule.Equatable
        protocol CustomHashable: MyModule.Hashable {}

        struct EquatableToken: CustomEquatable {
            let value: Int
        }

        struct HashableToken: CustomHashable {
            let value: Int
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testDoNotPreservePropertyOnClass() {
        let input = """
        class Token: Equatable {
            private let uuid: UUID = .init()
            let value: Int = 0
        }
        """
        let output = """
        class Token: Equatable {
            let value: Int = 0
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testPreserveFileprivateStoredProperty() {
        let input = """
        struct Token: Equatable {
            fileprivate let uuid: UUID = .init()
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testPreservePropertyWhenConformanceIsDeclaredInExtension() {
        let input = """
        struct Token {
            private let uuid: UUID = .init()
        }

        extension Token: Hashable {}
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotPreserveComputedOrStaticPropertiesForSynthesizedConformance() {
        let input = """
        struct Token: Hashable {
            private static let namespace = UUID()
            private var description: String { "token" }
        }
        """
        let output = """
        struct Token: Hashable {
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations, exclude: [.emptyBraces])
    }

    func testDoNotPreservePropertyWithManualEquatableImplementation() {
        let input = """
        struct Token: Equatable {
            private let uuid = UUID()

            static func == (lhs: Token, rhs: Token) -> Bool {
                String(describing: lhs) == String(describing: rhs)
            }
        }
        """
        let output = """
        struct Token: Equatable {
            static func == (lhs: Token, rhs: Token) -> Bool {
                String(describing: lhs) == String(describing: rhs)
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testPreservePropertyWhenEqualsOverloadDoesNotMatchEquatableRequirement() {
        let input = """
        struct Token: Equatable {
            private let uuid: UUID = .init()

            static func == (lhs: Token, rhs: String) -> Bool {
                String(describing: lhs) == rhs
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testPreservePropertyWhenEquatableImplementationIsInConstrainedExtension() {
        let input = """
        struct Token<Value: Equatable>: Equatable {
            private let uuid: UUID = .init()
            let value: Value
        }

        extension Token where Value == String {
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.value == rhs.value
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testPreservePropertyWithManualHashableImplementationAndSynthesizedEquatableConformance() {
        let input = """
        struct Token: Hashable {
            private let uuid: UUID = .init()

            func hash(into hasher: inout Hasher) {
                hasher.combine(0)
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testPreservePropertyWhenHashOverloadDoesNotMatchHashableRequirement() {
        let input = """
        struct Token: Hashable {
            private let uuid: UUID = .init()

            func hash(into value: inout Int) {
                value += 1
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testPreservePropertyWhenHashableImplementationIsConditionallyCompiled() {
        let input = """
        struct Token: Hashable {
            private let uuid: UUID = .init()

            #if DEBUG
                func hash(into hasher: inout Hasher) {
                    hasher.combine(0)
                }
            #endif
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testRecognizesSupportedManualEquatableWitnessSignatures() {
        let input = """
        struct SelfType: Equatable {
            static func == (lhs: Self, rhs: Self) -> Swift.Bool { true }
        }

        struct Outer {
            struct Nested: Equatable {
                static func == (lhs: Nested, rhs: Nested) -> Bool { true }
            }
        }

        struct Extended: Equatable {}

        extension Extended {
            static func == (lhs: Extended, rhs: Extended) -> Bool { true }
        }
        """
        let synthesizedTypes = synthesizedConformanceTypes(for: input)
        XCTAssertEqual(synthesizedTypes, [])
    }

    func testRejectsNonEquatableWitnessSignatures() {
        let input = """
        struct InstanceMethod: Equatable {
            func == (lhs: InstanceMethod, rhs: InstanceMethod) -> Bool { true }
        }

        struct WrongArity: Equatable {
            static func == (value: WrongArity) -> Bool { true }
        }

        struct WrongReturn: Equatable {
            static func == (lhs: WrongReturn, rhs: WrongReturn) -> Int { 0 }
        }
        """
        let synthesizedTypes = synthesizedConformanceTypes(for: input)
        XCTAssertEqual(
            synthesizedTypes,
            Set(["InstanceMethod", "WrongArity", "WrongReturn"])
        )
    }

    func testTreatsAmbiguousEquatableWitnessesAsSynthesized() {
        let input = """
        struct Attributed: Equatable {
            @available(*, deprecated)
            static func == (lhs: Attributed, rhs: Attributed) -> Bool { true }
        }

        struct Generic: Equatable {
            static func == <Value>(lhs: Generic, rhs: Generic) -> Bool { true }
        }

        struct ConstrainedFunction<Value>: Equatable {
            static func == (lhs: Self, rhs: Self) -> Bool where Value == String { true }
        }

        struct Effectful: Equatable {
            static func == (lhs: Effectful, rhs: Effectful) async -> Bool { true }
        }
        """
        let synthesizedTypes = synthesizedConformanceTypes(for: input)
        XCTAssertEqual(
            synthesizedTypes,
            Set(["Attributed", "Generic", "ConstrainedFunction", "Effectful"])
        )
    }

    func testRecognizesSupportedManualHashableWitnessSignatures() {
        let input = """
        struct QualifiedHasher: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            func hash(into hasher: inout Swift.Hasher) {}
        }

        struct ExplicitVoid: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            func hash(into hasher: inout Hasher) -> Void {}
        }

        struct QualifiedVoid: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            func hash(into hasher: inout Hasher) -> Swift.Void {}
        }

        struct TupleVoid: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            func hash(into hasher: inout Hasher) -> () {}
        }
        """
        let synthesizedTypes = synthesizedConformanceTypes(for: input)
        XCTAssertEqual(synthesizedTypes, [])
    }

    func testRejectsNonHashableWitnessSignatures() {
        let input = """
        struct StaticMethod: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            static func hash(into hasher: inout Hasher) {}
        }

        struct MutatingMethod: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            mutating func hash(into hasher: inout Hasher) {}
        }

        struct ConsumingMethod: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            consuming func hash(into hasher: inout Hasher) {}
        }

        struct WrongArity: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            func hash(into hasher: inout Hasher, salt: Int) {}
        }

        struct WrongLabel: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            func hash(_ hasher: inout Hasher) {}
        }

        struct WrongReturn: Hashable {
            static func == (lhs: Self, rhs: Self) -> Bool { true }
            func hash(into hasher: inout Hasher) -> Int { 0 }
        }
        """
        let synthesizedTypes = synthesizedConformanceTypes(for: input)
        XCTAssertEqual(
            synthesizedTypes,
            Set(["StaticMethod", "MutatingMethod", "ConsumingMethod", "WrongArity", "WrongLabel", "WrongReturn"])
        )
    }

    func testIncludesTypesWithEitherSynthesizedEquatableOrHashableRequirement() {
        let input = """
        struct ManualEquatable: Hashable {
            static func == (lhs: ManualEquatable, rhs: ManualEquatable) -> Bool { true }
        }

        struct ManualHashable: Hashable {
            func hash(into hasher: inout Hasher) {}
        }
        """
        let synthesizedTypes = synthesizedConformanceTypes(for: input)
        XCTAssertEqual(synthesizedTypes, ["ManualEquatable", "ManualHashable"])
    }

    func testRemoveUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testDoNotRemoveUsedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testRemoveMultipleUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            fileprivate var baz = "baz"
            var bar = "bar"
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testRemoveMixedUsedAndUnusedFilePrivate() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
            fileprivate var baz = "baz"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        let output = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"
        }

        struct Hello {
            let localFoo = Foo().foo
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testDoNotRemoveFilePrivateUsedInSameStruct() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
            var bar = "bar"

            func useFoo() {
                print(foo)
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testRemoveUnusedFilePrivateInNestedStruct() {
        let input = """
        struct Foo {
            var bar = "bar"

            struct Inner {
                fileprivate var foo = "foo"
            }
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"

            struct Inner {
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations, exclude: [.emptyBraces])
    }

    func testDoNotRemoveFilePrivateUsedInNestedStruct() {
        let input = """
        struct Foo {
            var bar = "bar"

            struct Inner {
                fileprivate var foo = "foo"
                func useFoo() {
                    print(foo)
                }
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testRemoveUnusedFileprivateFunction() {
        let input = """
        struct Foo {
            var bar = "bar"

            fileprivate func sayHi() {
                print("hi")
            }
        }
        """
        let output = """
        struct Foo {
            var bar = "bar"
        }
        """
        testFormatting(for: input, [output], rules: [.unusedDeclarations, .blankLinesAtEndOfScope])
    }

    func testDoNotRemoveUnusedFileprivateOperatorDefinition() {
        let input = """
        private class Foo: Equatable {
            fileprivate static func == (_: Foo, _: Foo) -> Bool {
                return true
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testRemovePrivateDeclarationButDoNotRemoveUnusedPrivateType() {
        let input = """
        private struct Foo {
            private func bar() {
                print("test")
            }
        }
        """
        let output = """
        private struct Foo {
        }
        """

        testFormatting(for: input, output, rule: .unusedDeclarations, exclude: [.emptyBraces])
    }

    func testRemovePrivateDeclarationButDoNotRemovePrivateExtension() {
        let input = """
        private extension Foo {
            private func doSomething() {}
            func anotherFunction() {}
        }
        """
        let output = """
        private extension Foo {
            func anotherFunction() {}
        }
        """

        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testRemovesPrivateTypealias() {
        let input = """
        enum Foo {
            struct Bar {}
            private typealias Baz = Bar
        }
        """
        let output = """
        enum Foo {
            struct Bar {}
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testDoesntRemoveFileprivateInit() {
        let input = """
        struct Foo {
            fileprivate init() {}
            static let foo = Foo()
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations, exclude: [.propertyTypes])
    }

    func testCanDisableUnusedDeclarationsRule() {
        let input = """
        private enum Foo {
            // swiftformat:disable:next unusedDeclarations
            fileprivate static func bar() {}
        }
        """

        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoesNotRemovePropertyWrapperPrefixesIfUsed() {
        let input = """
        public struct ContentView: View {
            public init() {
                _showButton = .init(initialValue: false)
            }

            @State private var showButton: Bool
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations, exclude: [.privateSwiftUIDynamicProperties])
    }

    func testDoesNotRemoveUnderscoredDeclarationIfUsed() {
        let input = """
        struct Foo {
            private var _showButton: Bool = true
            print(_showButton)
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoesNotRemoveBacktickDeclarationIfUsed() {
        let input = """
        struct Foo {
            fileprivate static var `default`: Bool = true
            func printDefault() {
                print(Foo.default)
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoesNotRemoveBacktickUsage() {
        let input = """
        struct Foo {
            fileprivate static var foo = true
            func printDefault() {
                print(Foo.`foo`)
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations, exclude: [.redundantBackticks])
    }

    func testDoNotRemovePreservedPrivateDeclarations() {
        let input = """
        enum Foo {
            private static let registryAssociation = false
        }
        """
        let options = FormatOptions(preservedPrivateDeclarations: ["registryAssociation", "hello"])
        testFormatting(for: input, rule: .unusedDeclarations, options: options)
    }

    func testDoNotRemoveOverridePrivateMethodDeclarations() {
        let input = """
        class Poodle: Dog {
            override private func makeNoise() {
                print("Yip!")
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotRemoveOverridePrivatePropertyDeclarations() {
        let input = """
        class Poodle: Dog {
            override private var age: Int {
                7
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotRemoveObjcPrivatePropertyDeclaration() {
        let input = """
        struct Foo {
            @objc
            private var bar = "bar"
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotRemoveObjcPrivateFunctionDeclaration() {
        let input = """
        struct Foo {
            @objc
            private func doSomething() {}
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotRemoveIBActionPrivateFunctionDeclaration() {
        let input = """
        class FooViewController: UIViewController {
            @IBAction private func buttonPressed(_: UIButton) {
                print("Button pressed!")
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testRemoveUnusedRecursivePrivateDeclaration() {
        let input = """
        struct Planet {
            private typealias Dependencies = UniverseBuilderProviding // unused
            private var mass: Double // unused
            private func distance(to: Planet) { } // unused
            private func gravitationalForce(between other: Planet) -> Double {
                (G * mass * other.mass) / distance(to: other).squared()
            } // unused

            var ageInBillionYears: Double {
                ageInMillionYears / 1000
            }
        }
        """
        let output = """
        struct Planet {
            var ageInBillionYears: Double {
                ageInMillionYears / 1000
            }
        }
        """
        testFormatting(for: input, output, rule: .unusedDeclarations)
    }

    func testDeclarationNotRemovedWhenUsedOutsideFormatRange() {
        let input = """
        private let used: Int = 22
        // swiftformat:disable:all
        struct Formatting {
            let a: Int

            init() {
                self.a = used
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations)
    }

    func testDoNotRemovePrivateTestFunction() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test private func featureWorks() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations, exclude: [.testSuiteAccessControl])
    }

    func testDoNotRemoveFileprivateTestFunction() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test fileprivate func featureWorks() {
                #expect(true)
            }
        }
        """
        testFormatting(for: input, rule: .unusedDeclarations, exclude: [.testSuiteAccessControl])
    }

    private func synthesizedConformanceTypes(for input: String) -> Set<String> {
        let formatter = Formatter(tokenize(input))
        return formatter.synthesizedEquatableAndHashableTypes(in: formatter.parseDeclarations())
    }
}
