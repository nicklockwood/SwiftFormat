//
//  PropertyTypesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 3/29/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PropertyTypesTests: XCTestCase {
    func testIndexedStaticPropertyAndFactoryReturnTypes() throws {
        let declarations = """
        enum Tools {
            static var text: String { "hello" }
            static func count() -> Int { 1 }
        }
        """
        let input = """
        let text = Tools.text
        let count = Tools.count()
        """
        let output = """
        let text: String = Tools.text
        let count: Int = Tools.count()
        """
        try testPropertyTypeIndex(declarations: declarations, input: input, output: output, placement: .explicit)
    }

    func testIndexedOverloadsPreserveContextualAnnotations() throws {
        let declarations = """
        struct Value {
            static func make() -> Value { Value() }
            static func make() -> Int { 1 }
            static var choice: Value { Value() }
            static var choice: String { "value" }
        }
        """
        let input = """
        let named: Value = Value.make()
        let shorthand: Value = .make()
        let property: Value = .choice
        """
        try testPropertyTypeIndex(declarations: declarations, input: input, output: input, placement: .inferred)
        let untyped = """
        let value = Value.make()
        """
        try testPropertyTypeIndex(declarations: declarations, input: untyped, output: untyped, placement: .explicit)
    }

    func testIndexedImplicitlyUnwrappedResultsPreserveAnnotations() throws {
        let declarations = """
        struct Value {
            init!() {}
            static func make() -> Value! { Value() }
            static var shared: Value! { Value() }
        }
        """
        let input = """
        let constructor: Value = Value()
        let initializer: Value = .init()
        let factory: Value = Value.make()
        let shorthand: Value = .make()
        let property: Value = .shared
        """
        try testPropertyTypeIndex(declarations: declarations, input: input, output: input, placement: .inferred)
        let untyped = """
        let value = Value()
        let factory = Value.make()
        """
        try testPropertyTypeIndex(declarations: declarations, input: untyped, output: untyped, placement: .explicit)
    }

    func testIndexedFailableInitializerPreserved() throws {
        let declarations = """
        struct Value {
            init?() { nil }
        }
        """
        let input = """
        let value = Value()
        """
        try testPropertyTypeIndex(declarations: declarations, input: input, output: input, placement: .explicit)
    }

    func testIndexedProtocolStaticMemberPreservesExistential() throws {
        let declarations = """
        protocol Style {}
        struct CustomStyle: Style {}
        extension Style where Self == CustomStyle {
            static var custom: CustomStyle { CustomStyle() }
        }
        """
        let input = """
        let style: Style = .custom
        """
        try testPropertyTypeIndex(declarations: declarations, input: input, output: input, placement: .inferred)
    }

    func testIndexedUnambiguousStaticMembersAllowInference() throws {
        let declarations = """
        struct Value {
            static var shared: Value { Value() }
            static func make() -> Value { Value() }
        }
        """
        let input = """
        let named: Value = Value.make()
        let shorthand: Value = .shared
        """
        let output = """
        let named = Value.make()
        let shorthand = Value.shared
        """
        try testPropertyTypeIndex(declarations: declarations, input: input, output: output, placement: .inferred)
    }

    func testIndexedConditionalBranchesPreserveAmbiguousAnnotations() throws {
        let declarations = """
        struct Value {
            static func make() -> Value { Value() }
            static func make() -> Int { 1 }
        }
        """
        let input = """
        let value: Value = if flag { .make() } else { .make() }
        """
        try testPropertyTypeIndex(declarations: declarations, input: input, output: input, placement: .inferred)
    }

    func testIndexedNestedResultTypeIsNotAssumedGlobal() throws {
        let declarations = """
        struct Tools {
            struct Result {}
            static var result: Result { Result() }
            static var results: [Result] { [] }
        }
        struct Result {}
        """
        let input = """
        let result = Tools.result
        let results = Tools.results
        """
        try testPropertyTypeIndex(declarations: declarations, input: input, output: input, placement: .explicit)
    }

    func testIndexedStaticMemberRespectsPreservedSymbols() {
        let input = """
        enum Tools {
            static var text: String {
                "hello"
            }
        }

        let value = Tools.text
        """
        for symbol in ["Tools", "text", "String"] {
            testFormatting(for: input, rule: .propertyTypes,
                           options: FormatOptions(propertyTypes: .explicit, preservedPropertyTypes: [symbol]))
        }
    }

    private func testPropertyTypeIndex(
        declarations: String, input: String, output: String, placement: PropertyTypes,
        file: StaticString = #file, line: UInt = #line
    ) throws {
        _ = FormatRules.all
        let fileURL = URL(fileURLWithPath: "/Project/Use.swift")
        let options = FormatOptions(propertyTypes: placement, inferredTypesInConditionalExpressions: true, swiftVersion: "5.9")
        let project = ProjectIndex(files: [
            "/Project/Declarations.swift": makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
            fileURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.propertyTypes], to: tokenize(input), with: options, trackChanges: false, range: nil,
            context: FormattingContext(currentFileURL: fileURL, projectIndex: project)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output, file: file, line: line)
        let localInput = declarations + "\n" + input
        let local = try applyRules([.propertyTypes], to: tokenize(localInput), with: options,
                                   trackChanges: false, range: nil)
        XCTAssertEqual(sourceCode(for: local.tokens), declarations + "\n" + output, file: file, line: line)
    }

    func testExplicitStaticMemberQualifierPolicy() {
        let input = """
        var value = LongBar.value
        """
        let output = """
        var value: LongBar = .value
        """
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions],
                       options: FormatOptions(propertyTypes: .explicit))
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions],
                       options: FormatOptions(initTypes: .always, propertyTypes: .explicit))
    }

    func testExplicitQualifierPolicy() {
        let input = """
        var value = LongBar()
        """
        let explicit = """
        var value: LongBar = LongBar()
        """
        let contextual = """
        var value: LongBar = .init()
        """
        testFormatting(for: input, [explicit], rules: [.propertyTypes, .implicitMemberExpressions],
                       options: FormatOptions(initTypes: .always, propertyTypes: .explicit))
        testFormatting(for: input, [contextual], rules: [.propertyTypes, .implicitMemberExpressions],
                       options: FormatOptions(propertyTypes: .explicit))
    }

    func testPreservesShortConstructorNamesByDefault() {
        let input = """
        var value = Tiny()
        """
        let preserved = """
        var value: Tiny = Tiny()
        """
        let shortened = """
        var value: Tiny = .init()
        """
        testFormatting(for: input, [preserved], rules: [.propertyTypes, .implicitMemberExpressions],
                       options: FormatOptions(propertyTypes: .explicit))
        testFormatting(for: input, [shortened], rules: [.propertyTypes, .implicitMemberExpressions],
                       options: FormatOptions(initTypeMinLength: 4, propertyTypes: .explicit))
    }

    func testExplicitQualifiersWithInferredAnnotations() {
        let input = """
        var value: LongBar = .init()
        """
        let output = """
        var value = LongBar()
        """
        testFormatting(for: input, [output], rules: [.propertyTypes, .redundantInit],
                       options: FormatOptions(initTypes: .always, propertyTypes: .inferred))
    }

    func testConvertsExplicitTypeToInferredType() {
        let input = """
        let foo: Foo = .init()
        let bar: Bar = .staticBar
        let baaz: Baaz = .Example.default
        let quux: Quux = .quuxBulder(foo: .foo, bar: .bar)

        let dictionary: [Foo: Bar] = .init()
        let array: [Foo] = .init()
        let genericType: MyGenericType<Foo, Bar> = .init()
        let underscoredType: _Foo = .init()
        let lowercaseType: c_type = .init()
        """

        let output = """
        let foo = Foo()
        let bar = Bar.staticBar
        let baaz = Baaz.Example.default
        let quux = Quux.quuxBulder(foo: .foo, bar: .bar)

        let dictionary = [Foo: Bar]()
        let array = [Foo]()
        let genericType = MyGenericType<Foo, Bar>()
        let underscoredType = _Foo()
        let lowercaseType = c_type.init()
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions, .redundantInit], options: options)
    }

    func testConvertsInferredTypeToExplicitType() {
        let input = """
        let foo = Foo()
        let bar = Bar.staticBar
        let quux = Quux.quuxBulder(foo: .foo, bar: .bar)

        let dictionary = [Foo: Bar]()
        let array = [Foo]()
        let genericType = MyGenericType<Foo, Bar>()
        """

        let output = """
        let foo: Foo = .init()
        let bar: Bar = .staticBar
        let quux: Quux = .quuxBulder(foo: .foo, bar: .bar)

        let dictionary: [Foo: Bar] = [:]
        let array: [Foo] = []
        let genericType: MyGenericType<Foo, Bar> = .init()
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testConvertsForceUnwrappedInitToExplicitType() {
        let input = """
        let url = URL(string: "https://example.com")!
        """

        let output = """
        let url: URL = .init(string: "https://example.com")!
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testConvertsInitWithTrailingClosureToExplicitType() {
        let input = """
        let button = Button(title: "Tap") {
            print("tapped")
        }
        """

        let output = """
        let button: Button = .init(title: "Tap") {
            print("tapped")
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesInferredTypeForSubscriptedInit() {
        let input = """
        let first = Foo(bar)[0]
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testConvertsInitWithDidSetObserverToExplicitType() {
        let input = """
        var foo = Foo() {
            didSet { notify() }
        }
        """

        let output = """
        var foo: Foo = .init() {
            didSet { notify() }
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testConvertsInitWithWillSetObserverToExplicitType() {
        let input = """
        var foo = Foo(bar: 1) {
            willSet(newFoo) { print(newFoo) }
        }
        """

        let output = """
        var foo: Foo = .init(bar: 1) {
            willSet(newFoo) { print(newFoo) }
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testConvertsTypeMembersToExplicitType() {
        let input = """
        struct Foo {
            let foo = Foo()
            let bar = Bar.staticBar
            let quux = Quux.quuxBulder(foo: .foo, bar: .bar)

            let dictionary = [Foo: Bar]()
            let array = [Foo]()
            let genericType = MyGenericType<Foo, Bar>()
        }
        """

        let output = """
        struct Foo {
            let foo: Foo = .init()
            let bar: Bar = .staticBar
            let quux: Quux = .quuxBulder(foo: .foo, bar: .bar)

            let dictionary: [Foo: Bar] = [:]
            let array: [Foo] = []
            let genericType: MyGenericType<Foo, Bar> = .init()
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testConvertsLocalsToImplicitType() {
        let input = """
        struct Foo {
            let foo = Foo()

            func bar() {
                let bar: Bar = .staticBar
                let quux: Quux = .quuxBulder(foo: .foo, bar: .bar)

                let dictionary: [Foo: Bar] = .init()
                let array: [Foo] = .init()
                let genericType: MyGenericType<Foo, Bar> = .init()
            }
        }
        """

        let output = """
        struct Foo {
            let foo: Foo = .init()

            func bar() {
                let bar = Bar.staticBar
                let quux = Quux.quuxBulder(foo: .foo, bar: .bar)

                let dictionary = [Foo: Bar]()
                let array = [Foo]()
                let genericType = MyGenericType<Foo, Bar>()
            }
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions, .redundantInit], options: options)
    }

    func testPreservesInferredTypeFollowingTypeWithDots() {
        let input = """
        let baaz = Baaz.Example.default
        let color = Color.Theme.default
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesExplicitTypeIfNoRHS() {
        let input = """
        let foo: Foo
        let bar: Bar
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesImplicitTypeIfNoRHSType() {
        let input = """
        let foo = foo()
        let bar = bar
        let int = 24
        let array = ["string"]
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesImplicitForVoidAndTuples() {
        let input = """
        let foo = Void()
        let foo = (foo: "foo", bar: "bar").foo
        let foo = ["bar", "baz"].quux(quuz)
        let foo = [bar].first
        let foo = [bar, baaz].first
        let foo = ["foo": "bar"].first
        let foo = [foo: bar].first
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options, exclude: [.void])
    }

    func testPreservesExplicitTypeIfUsingLocalValueOrLiteral() {
        let input = """
        let foo: Foo = localFoo
        let bar: Bar = localBar
        let int: Int64 = 1234
        let number: CGFloat = 12.345
        let tuple: (String, Int) = ("foo", 123)
        """
        let output = """
        let foo: Foo = localFoo
        let bar: Bar = localBar
        let int: Int64 = 1234
        let number: CGFloat = 12.345
        let tuple = ("foo", 123)
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options, exclude: [.redundantType])
    }

    func testCompatibleWithRedundantTypeInferred() {
        let input = """
        let foo: Foo = Foo()
        """

        let output = """
        let foo = Foo()
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testCompatibleWithRedundantTypeExplicit() {
        let input = """
        let foo: Foo = Foo()
        """

        let output = """
        let foo: Foo = .init()
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testCompatibleWithRedundantTypeInferLocalsOnly() {
        let input = """
        let foo: Foo = Foo.init()
        let foo: Foo = .init()

        func bar() {
            let baaz: Baaz = Baaz.init()
            let baaz: Baaz = .init()
        }
        """

        let output = """
        let foo: Foo = .init()
        let foo: Foo = .init()

        func bar() {
            let baaz = Baaz()
            let baaz = Baaz()
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions, .redundantInit], options: options)
    }

    func testPropertyTypeWithIfExpressionDisabledByDefault() {
        let input = """
        let foo: SomeTypeWithALongGenrericName<AndGenericArgument> =
            if condition {
                .init(bar)
            } else {
                .init(baaz)
            }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPropertyTypeWithIfExpression() {
        let input = """
        let foo: Foo =
            if condition {
                .init(bar)
            } else {
                .init(baaz)
            }
        """

        let output = """
        let foo =
            if condition {
                Foo(bar)
            } else {
                Foo(baaz)
            }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred, inferredTypesInConditionalExpressions: true)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions, .redundantInit], options: options)
    }

    func testPropertyTypeWithSwitchExpression() {
        let input = """
        let foo: Foo =
            switch condition {
            case true:
                .init(bar)
            case false:
                .init(baaz)
            }
        """

        let output = """
        let foo =
            switch condition {
            case true:
                Foo(bar)
            case false:
                Foo(baaz)
            }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred, inferredTypesInConditionalExpressions: true)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions, .redundantInit], options: options)
    }

    func testPreservesNonMatchingIfExpression() {
        let input = """
        let foo: Foo =
            if condition {
                .init(bar)
            } else {
                [] // e.g. using ExpressibleByArrayLiteral
            }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred, inferredTypesInConditionalExpressions: true)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesExplicitOptionalType() {
        // `let foo = Foo?.foo` doesn't work if `.foo` is defined on `Foo` but not `Foo?`
        let input = """
        let optionalFoo1: Foo? = .foo
        let optionalFoo2: Foo? = Foo.foo
        let optionalFoo3: Foo! = .foo
        let optionalFoo4: Foo! = Foo.foo
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesTypeWithSeparateDeclarationAndProperty() {
        let input = """
        var foo: Foo!
        foo = Foo(afterDelay: {
            print(foo)
        })
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesTypeWithExistentialAny() {
        let input = """
        protocol ShapeStyle {}
        struct MyShapeStyle: ShapeStyle {}

        extension ShapeStyle where Self == MyShapeStyle {
            static var myShape: MyShapeStyle { .init() }
        }

        /// This compiles
        let myShape1: any ShapeStyle = .myShape
        let myShape2: (any ShapeStyle) = .myShape

        // This would fail with "error: static member 'myShape' cannot be used on protocol metatype '(any ShapeStyle).Type'"
        // let myShape3 = (any ShapeStyle).myShape
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options, exclude: [.wrapFunctionBodies, .wrapPropertyBodies])
    }

    func testPreservesTypeWithSomeKeyword() {
        let input = """
        /// This compiles
        let myShape1: some ShapeStyle = .myShape
        let myShape2: (some ShapeStyle) = .myShape

        // This would fail to compile
        // let myShape4 = (some ShapeStyle).myShape
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesExplicitRightHandSideWithOperator() {
        let input = """
        let value: ClosedRange<Int> = .zero ... 10
        let dynamicTypeSizeRange: ClosedRange<DynamicTypeSize> = .large ... .xxxLarge
        let dynamicTypeSizeRange: ClosedRange<DynamicTypeSize> = .large() ... .xxxLarge()
        let dynamicTypeSizeRange: ClosedRange<DynamicTypeSize> = .convertFromLiteral(.large ... .xxxLarge)
        """

        let output = """
        let value: ClosedRange<Int> = .zero ... 10
        let dynamicTypeSizeRange: ClosedRange<DynamicTypeSize> = .large ... .xxxLarge
        let dynamicTypeSizeRange: ClosedRange<DynamicTypeSize> = .large() ... .xxxLarge()
        let dynamicTypeSizeRange = ClosedRange<DynamicTypeSize>.convertFromLiteral(.large ... .xxxLarge)
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testRedundantTypeInModelClassNotStripped() {
        // See: https://github.com/nicklockwood/SwiftFormat/issues/1649
        let input = """
        @Model
        class FooBar {
            var created: Date = Date.now
        }
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesInferredRightHandSideWithOperators() {
        let input = """
        let foo = Foo().bar
        let foo = Foo.bar.baaz.quux
        let foo = Foo.bar ... baaz
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testNonUppercaseSymbolsNotTreatedAsTypes() {
        let input = """
        let foo = bar()
        let foo = _bar()
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreservesUserProvidedSymbolTypes() {
        let input = """
        class Foo {
            let foo = Foo()
            let bar = Bar()

            func bar() {
                let foo: Foo = .foo
                let bar: Bar = .bar
                let baaz: Baaz = .baaz
                let quux: Quux = .quux
            }
        }
        """

        let output = """
        class Foo {
            let foo = Foo()
            let bar: Bar = .init()

            func bar() {
                let foo: Foo = .foo
                let bar = Bar.bar
                let baaz: Baaz = .baaz
                let quux: Quux = .quux
            }
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferLocalsOnly, preservedPropertyTypes: ["Foo", "Baaz", "quux"])
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPreserveInitIfExplicitlyExcluded() {
        let input = """
        class Foo {
            let foo = Foo()
            let bar = Bar.init()
            let baaz = Baaz.baaz()

            func bar() {
                let foo: Foo = .init()
                let bar: Bar = .init()
                let baaz: Baaz = .baaz()
            }
        }
        """

        let output = """
        class Foo {
            let foo = Foo()
            let bar = Bar.init()
            let baaz: Baaz = .baaz()

            func bar() {
                let foo: Foo = .init()
                let bar: Bar = .init()
                let baaz = Baaz.baaz()
            }
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferLocalsOnly, preservedPropertyTypes: ["init"])
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options, exclude: [.redundantInit])
    }

    func testClosureBodyIsConsideredLocal() {
        let input = """
        foo {
            let bar = Bar()
            let baaz: Baaz = .init()
        }

        foo(bar: bar, baaz: baaz, quux: {
            let bar = Bar()
            let baaz: Baaz = .init()
        })

        foo {
            let bar = Bar()
            let baaz: Baaz = .init()
        } bar: {
            let bar = Bar()
            let baaz: Baaz = .init()
        }

        class Foo {
            let foo = Foo.bar {
                let baaz = Baaz()
                let baaz: Baaz = .init()
            }
        }
        """

        let output = """
        foo {
            let bar = Bar()
            let baaz = Baaz()
        }

        foo(bar: bar, baaz: baaz, quux: {
            let bar = Bar()
            let baaz = Baaz()
        })

        foo {
            let bar = Bar()
            let baaz = Baaz()
        } bar: {
            let bar = Bar()
            let baaz = Baaz()
        }

        class Foo {
            let foo: Foo = .bar {
                let baaz = Baaz()
                let baaz = Baaz()
            }
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions, .redundantInit], options: options)
    }

    func testIfGuardConditionsPreserved() {
        let input = """
        if let foo = Foo(bar) {
            let foo = Foo(bar)
        } else if let foo = Foo(bar) {
            let foo = Foo(bar)
        } else {
            let foo = Foo(bar)
        }

        guard let foo = Foo(bar) else {
            return
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testPropertyObserversConsideredLocal() {
        let input = """
        class Foo {
            var foo: Foo {
                get {
                    let foo = Foo(bar)
                }
                set {
                    let foo = Foo(bar)
                }
                willSet {
                    let foo = Foo(bar)
                }
                didSet {
                    let foo = Foo(bar)
                }
            }
        }
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testHandlesEscapedIdentifiers() {
        let input = """
        let `property with raw identifier 1` = `function with raw identifier`()
        let `property with raw identifier 2` = `Escaped Type Name`.staticMember
        """

        let output = """
        let `property with raw identifier 1` = `function with raw identifier`()
        let `property with raw identifier 2`: `Escaped Type Name` = .staticMember
        """

        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testEmptyArrayLiteralToInferredType() {
        let input = """
        let array: [Int] = []
        var numbers: [Double] = []
        let matrix: [[String]] = []
        """
        let output = """
        let array = [Int]()
        var numbers = [Double]()
        let matrix = [[String]]()
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testEmptyDictionaryLiteralToInferredType() {
        let input = """
        let dict: [String: Int] = [:]
        var mapping: [Int: String] = [:]
        let nested: [String: [Int: Bool]] = [:]
        """
        let output = """
        let dict = [String: Int]()
        var mapping = [Int: String]()
        let nested = [String: [Int: Bool]]()
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testEmptyCollectionInitToCollectionLiteral() {
        let input = """
        let array = [Foo]()
        var mapping = [Int: String]()
        let nested = [String: [Int: Bool]]()
        let repeatedArray = [Int](repeating: 0, count: 10)
        """
        let output = """
        let array: [Foo] = []
        var mapping: [Int: String] = [:]
        let nested: [String: [Int: Bool]] = [:]
        let repeatedArray: [Int] = .init(repeating: 0, count: 10)
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testEmptyCollectionLiteralWithSpaces() {
        let input = """
        let array: [Int] = [ ]
        let dict: [String: Int] = [ : ]
        """
        let output = """
        let array = [Int]()
        let dict = [String: Int]()
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options, exclude: [.spaceInsideBrackets, .spaceAroundOperators])
    }

    func testRemovesRedundantDictionaryTypeAndInfersEmptyCollectionType() {
        let input = """
        let array: [Int] = [1, 2, 3]
        let dict: [String: Int] = ["key": 1]
        let emptyArray: [Int] = []
        """

        let output = """
        let array: [Int] = [1, 2, 3]
        let dict = ["key": 1]
        let emptyArray = [Int]()
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options, exclude: [.redundantType])
    }

    func testEmptyCollectionLiteralWithComplexTypes() {
        let input = """
        let array: [Int?] = []
        let dict: [String: Int?] = [:]
        let generic: [MyType<T>] = []
        let genericDict: [MyKey<T>: MyValue<U>] = [:]
        """
        let output = """
        let array = [Int?]()
        let dict = [String: Int?]()
        let generic = [MyType<T>]()
        let genericDict = [MyKey<T>: MyValue<U>]()
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testEmptySetLiteralToInferredType() {
        let input = """
        let set: Set<Int> = []
        var strings: Set<String> = []
        let nested: Set<Set<Bool>> = []
        """
        let output = """
        let set = Set<Int>()
        var strings = Set<String>()
        let nested = Set<Set<Bool>>()
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testEmptySetInitToSetLiteral() {
        let input = """
        let set = Set<Foo>()
        var mapping = Set<String>()
        let nested = Set<Set<Int>>()
        let capacitySet = Set<Int>(minimumCapacity: 10)
        """
        let output = """
        let set: Set<Foo> = []
        var mapping: Set<String> = []
        let nested: Set<Set<Int>> = []
        let capacitySet: Set<Int> = .init(minimumCapacity: 10)
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testExplicitTypeSimplifiesToIntegerLiteral() {
        let input = """
        let a = UInt8(3)
        let b = Int16(42)
        let c = UInt64(100)
        """
        let output = """
        let a: UInt8 = 3
        let b: Int16 = 42
        let c: UInt64 = 100
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testExplicitTypeSimplifiesToFloatLiteral() {
        let input = """
        let a = Float(3.14)
        let b = Float16(1.0)
        """
        let output = """
        let a: Float = 3.14
        let b: Float16 = 1.0
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testExplicitTypeSimplifiesToStringLiteral() {
        let input = """
        let a = StaticString("hello")
        let b = Substring("world")
        """
        let output = """
        let a: StaticString = "hello"
        let b: Substring = "world"
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testExplicitTypeDoesNotSimplifyNonLiteralArg() {
        let input = """
        let a = UInt8(someVariable)
        """
        let output = """
        let a: UInt8 = .init(someVariable)
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testExplicitTypeDoesNotSimplifyUnknownType() {
        let input = """
        let a = CGFloat(3.14)
        """
        let output = """
        let a: CGFloat = .init(3.14)
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testExplicitTypeSimplifiesIntegerLiteralForFloatType() {
        let input = """
        let a = Float(3)
        let b = Double(42)
        """
        let output = """
        let a: Float = 3
        let b: Double = 42
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testExplicitTypeSimplifiesSetWithArrayLiteral() {
        let input = """
        let s = Set<Int>([1, 2, 3])
        """
        let output = """
        let s: Set<Int> = [1, 2, 3]
        """
        let options = FormatOptions(initTypeMinLength: 0, propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.propertyTypes, .implicitMemberExpressions], options: options)
    }

    func testAnnotationPlacementDoesNotChooseConstructorSpelling() {
        let input = """
        let view = CustomView()
        """
        let output = """
        let view: CustomView = CustomView()
        """
        testFormatting(for: input, output, rule: .propertyTypes,
                       options: FormatOptions(initTypes: .always, propertyTypes: .explicit))
    }

    func testRedundantOnlyDoesNotMoveAnnotations() {
        let input = """
        let global = LongName()
        func foo() {
            let duplicate: LongName = LongName()
            let explicit: LongName = .init()
        }
        """
        let output = """
        let global = LongName()
        func foo() {
            let duplicate = LongName()
            let explicit: LongName = .init()
        }
        """
        testFormatting(for: input, output, rule: .propertyTypes,
                       options: FormatOptions(propertyTypesMode: .redundantOnly))
    }

    func testPropertyTypesDisabledByDefault() {
        XCTAssertTrue(FormatRule.propertyTypes.disabledByDefault)
        XCTAssertTrue(FormatRule.redundantType.isDeprecated)
    }
}
