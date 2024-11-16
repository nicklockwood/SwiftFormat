//
//  PropertyTypesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 3/29/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class PropertyTypesTests: XCTestCase {
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

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.propertyTypes, .redundantInit], options: options)
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

        let dictionary: [Foo: Bar] = .init()
        let array: [Foo] = .init()
        let genericType: MyGenericType<Foo, Bar> = .init()
        """

        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .propertyTypes, options: options)
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

            let dictionary: [Foo: Bar] = .init()
            let array: [Foo] = .init()
            let genericType: MyGenericType<Foo, Bar> = .init()
        }
        """

        let options = FormatOptions(propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, output, rule: .propertyTypes, options: options)
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

        let options = FormatOptions(propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, [output], rules: [.propertyTypes, .redundantInit], options: options)
    }

    func testPreservesInferredTypeFollowingTypeWithDots() {
        let input = """
        let baaz = Baaz.Example.default
        let color = Color.Theme.default
        """

        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .propertyTypes, options: options)
    }

    func testPreservesExplicitTypeIfNoRHS() {
        let input = """
        let foo: Foo
        let bar: Bar
        """

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .propertyTypes, options: options)
    }

    func testPreservesImplicitTypeIfNoRHSType() {
        let input = """
        let foo = foo()
        let bar = bar
        let int = 24
        let array = ["string"]
        """

        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .propertyTypes, options: options)
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

        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .propertyTypes, options: options, exclude: [.void])
    }

    func testPreservesExplicitTypeIfUsingLocalValueOrLiteral() {
        let input = """
        let foo: Foo = localFoo
        let bar: Bar = localBar
        let int: Int64 = 1234
        let number: CGFloat = 12.345
        let array: [String] = []
        let dictionary: [String: Int] = [:]
        let tuple: (String, Int) = ("foo", 123)
        """

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .propertyTypes, options: options, exclude: [.redundantType])
    }

    func testCompatibleWithRedundantTypeInferred() {
        let input = """
        let foo: Foo = Foo()
        """

        let output = """
        let foo = Foo()
        """

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, [output], rules: [.redundantType, .propertyTypes], options: options)
    }

    func testCompatibleWithRedundantTypeExplicit() {
        let input = """
        let foo: Foo = Foo()
        """

        let output = """
        let foo: Foo = .init()
        """

        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, [output], rules: [.redundantType, .propertyTypes], options: options)
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

        let options = FormatOptions(propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, [output], rules: [.redundantType, .propertyTypes, .redundantInit], options: options)
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

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .propertyTypes, options: options)
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

        let options = FormatOptions(propertyTypes: .inferred, inferredTypesInConditionalExpressions: true)
        testFormatting(for: input, [output], rules: [.propertyTypes, .redundantInit], options: options)
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

        let options = FormatOptions(propertyTypes: .inferred, inferredTypesInConditionalExpressions: true)
        testFormatting(for: input, [output], rules: [.propertyTypes, .redundantInit], options: options)
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

        let options = FormatOptions(propertyTypes: .inferred, inferredTypesInConditionalExpressions: true)
        testFormatting(for: input, rule: .propertyTypes, options: options)
    }

    func testPreservesExplicitOptionalType() {
        // `let foo = Foo?.foo` doesn't work if `.foo` is defined on `Foo` but not `Foo?`
        let input = """
        let optionalFoo1: Foo? = .foo
        let optionalFoo2: Foo? = Foo.foo
        let optionalFoo3: Foo! = .foo
        let optionalFoo4: Foo! = Foo.foo
        """

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .propertyTypes, options: options)
    }

    func testPreservesTypeWithSeparateDeclarationAndProperty() {
        let input = """
        var foo: Foo!
        foo = Foo(afterDelay: {
            print(foo)
        })
        """

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .propertyTypes, options: options)
    }

    func testPreservesTypeWithExistentialAny() {
        let input = """
        protocol ShapeStyle {}
        struct MyShapeStyle: ShapeStyle {}

        extension ShapeStyle where Self == MyShapeStyle {
            static var myShape: MyShapeStyle { MyShapeStyle() }
        }

        /// This compiles
        let myShape1: any ShapeStyle = .myShape

        // This would fail with "error: static member 'myShape' cannot be used on protocol metatype '(any ShapeStyle).Type'"
        // let myShape2 = (any ShapeStyle).myShape
        """

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .propertyTypes, options: options)
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

        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .propertyTypes, options: options)
    }

    func testRedundantTypeInModelClassNotStripped() {
        // See: https://github.com/nicklockwood/SwiftFormat/issues/1649
        let input = """
        @Model
        class FooBar {
            var created: Date = Date.now
        }
        """
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .propertyTypes, options: options)
    }

    func testPreservesInferredRightHandSideWithOperators() {
        let input = """
        let foo = Foo().bar
        let foo = Foo.bar.baaz.quux
        let foo = Foo.bar ... baaz
        """

        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .propertyTypes, options: options)
    }

    func testNonUppercaseSymbolsNotTreatedAsTypes() {
        let input = """
        let foo = bar()
        let foo = _bar()
        """

        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .propertyTypes, options: options)
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

        let options = FormatOptions(propertyTypes: .inferLocalsOnly, preservedSymbols: ["Foo", "Baaz", "quux"])
        testFormatting(for: input, output, rule: .propertyTypes, options: options)
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

        let options = FormatOptions(propertyTypes: .inferLocalsOnly, preservedSymbols: ["init"])
        testFormatting(for: input, output, rule: .propertyTypes, options: options, exclude: [.redundantInit])
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

        let options = FormatOptions(propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, [output], rules: [.propertyTypes, .redundantInit], options: options)
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

        let options = FormatOptions(propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, rule: .propertyTypes, options: options)
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

        let options = FormatOptions(propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, rule: .propertyTypes, options: options)
    }
}
