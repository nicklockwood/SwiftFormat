//
//  RedundantTypeTests.swift
//  SwiftFormatTests
//
//  Created by Facundo Menzella on 8/20/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantTypeTests: XCTestCase {
    func testVarRedundantTypeRemoval() {
        let input = "var view: UIView = UIView()"
        let output = "var view = UIView()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testVarRedundantArrayTypeRemoval() {
        let input = "var foo: [String] = [String]()"
        let output = "var foo = [String]()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testVarRedundantDictionaryTypeRemoval() {
        let input = "var foo: [String: Int] = [String: Int]()"
        let output = "var foo = [String: Int]()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testLetRedundantGenericTypeRemoval() {
        let input = "let relay: BehaviourRelay<Int?> = BehaviourRelay<Int?>(value: nil)"
        let output = "let relay = BehaviourRelay<Int?>(value: nil)"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testVarNonRedundantTypeDoesNothing() {
        let input = "var view: UIView = UINavigationBar()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testLetRedundantTypeRemoval() {
        let input = "let view: UIView = UIView()"
        let output = "let view = UIView()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testLetNonRedundantTypeDoesNothing() {
        let input = "let view: UIView = UINavigationBar()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testTypeNoRedundancyDoesNothing() {
        let input = "let foo: Bar = 5"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testClassTwoVariablesNoRedundantTypeDoesNothing() {
        let input = """
        final class LGWebSocketClient: WebSocketClient, WebSocketLibraryDelegate {
            var webSocket: WebSocketLibraryProtocol
            var timeoutIntervalForRequest: TimeInterval = LGCoreKitConstants.websocketTimeOutTimeInterval
        }
        """
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testRedundantTypeRemovedIfValueOnNextLine() {
        let input = """
        let view: UIView
            = UIView()
        """
        let output = """
        let view
            = UIView()
        """
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testRedundantTypeRemovedIfValueOnNextLine2() {
        let input = """
        let view: UIView =
            UIView()
        """
        let output = """
        let view =
            UIView()
        """
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testAllRedundantTypesRemovedInCommaDelimitedDeclaration() {
        let input = "var foo: Int = 0, bar: Int = 0"
        let output = "var foo = 0, bar = 0"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testRedundantTypeRemovalWithComment() {
        let input = "var view: UIView /* view */ = UIView()"
        let output = "var view /* view */ = UIView()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testRedundantTypeRemovalWithComment2() {
        let input = "var view: UIView = /* view */ UIView()"
        let output = "var view = /* view */ UIView()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testNonRedundantTernaryConditionTypeNotRemoved() {
        let input = "let foo: Bar = Bar.baz() ? .bar1 : .bar2"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testTernaryConditionAfterLetNotTreatedAsPartOfExpression() {
        let input = """
        let foo: Bar = Bar.baz()
        baz ? bar2() : bar2()
        """
        let output = """
        let foo = Bar.baz()
        baz ? bar2() : bar2()
        """
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testNoRemoveRedundantTypeIfVoid() {
        let input = "let foo: Void = Void()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType,
                       options: options, exclude: [.void])
    }

    func testNoRemoveRedundantTypeIfVoid2() {
        let input = "let foo: () = ()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType,
                       options: options, exclude: [.void])
    }

    func testNoRemoveRedundantTypeIfVoid3() {
        let input = "let foo: [Void] = [Void]()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testNoRemoveRedundantTypeIfVoid4() {
        let input = "let foo: Array<Void> = Array<Void>()"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType,
                       options: options, exclude: [.typeSugar])
    }

    func testNoRemoveRedundantTypeIfVoid5() {
        let input = "let foo: Void? = Void?.none"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testNoRemoveRedundantTypeIfVoid6() {
        let input = "let foo: Optional<Void> = Optional<Void>.none"
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType,
                       options: options, exclude: [.typeSugar])
    }

    func testRedundantTypeWithLiterals() {
        let input = """
        let a1: Bool = true
        let a2: Bool = false

        let b1: String = "foo"
        let b2: String = "\\(b1)"

        let c1: Int = 1
        let c2: Int = 1.0

        let d1: Double = 3.14
        let d2: Double = 3

        let e1: [Double] = [3.14]
        let e2: [Double] = [3]

        let f1: [String: Int] = ["foo": 5]
        let f2: [String: Int?] = ["foo": nil]
        """
        let output = """
        let a1 = true
        let a2 = false

        let b1 = "foo"
        let b2 = "\\(b1)"

        let c1 = 1
        let c2: Int = 1.0

        let d1 = 3.14
        let d2: Double = 3

        let e1 = [3.14]
        let e2: [Double] = [3]

        let f1 = ["foo": 5]
        let f2: [String: Int?] = ["foo": nil]
        """
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options)
    }

    func testRedundantTypePreservesLiteralRepresentableTypes() {
        let input = """
        let a: MyBoolRepresentable = true
        let b: MyStringRepresentable = "foo"
        let c: MyIntRepresentable = 1
        let d: MyDoubleRepresentable = 3.14
        let e: MyArrayRepresentable = ["bar"]
        let f: MyDictionaryRepresentable = ["baz": 1]
        """
        let options = FormatOptions(propertyTypes: .inferred)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testPreservesTypeWithIfExpressionInSwift5_8() {
        let input = """
        let foo: Foo
        if condition {
            foo = Foo("foo")
        } else {
            foo = Foo("bar")
        }
        """
        let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.8")
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testPreservesNonRedundantTypeWithIfExpression() {
        let input = """
        let foo: Foo = if condition {
            Foo("foo")
        } else {
            FooSubclass("bar")
        }
        """
        let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.9")
        testFormatting(for: input, rule: .redundantType, options: options, exclude: [.wrapMultilineConditionalAssignment])
    }

    func testRedundantTypeWithIfExpression_inferred() {
        let input = """
        let foo: Foo = if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """
        let output = """
        let foo = if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """
        let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantType, options: options, exclude: [.wrapMultilineConditionalAssignment])
    }

    func testRedundantTypeWithIfExpression_explicit() {
        let input = """
        let foo: Foo = if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """
        let output = """
        let foo: Foo = if condition {
            .init("foo")
        } else {
            .init("bar")
        }
        """
        let options = FormatOptions(propertyTypes: .explicit, swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantType, options: options, exclude: [.wrapMultilineConditionalAssignment, .propertyTypes])
    }

    func testRedundantTypeWithNestedIfExpression_inferred() {
        let input = """
        let foo: Foo = if condition {
            switch condition {
            case true:
                if condition {
                    Foo("foo")
                } else {
                    Foo("bar")
                }

            case false:
                Foo("baaz")
            }
        } else {
            Foo("quux")
        }
        """
        let output = """
        let foo = if condition {
            switch condition {
            case true:
                if condition {
                    Foo("foo")
                } else {
                    Foo("bar")
                }

            case false:
                Foo("baaz")
            }
        } else {
            Foo("quux")
        }
        """
        let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantType, options: options, exclude: [.wrapMultilineConditionalAssignment])
    }

    func testRedundantTypeWithNestedIfExpression_explicit() {
        let input = """
        let foo: Foo = if condition {
            switch condition {
            case true:
                if condition {
                    Foo("foo")
                } else {
                    Foo("bar")
                }

            case false:
                Foo("baaz")
            }
        } else {
            Foo("quux")
        }
        """
        let output = """
        let foo: Foo = if condition {
            switch condition {
            case true:
                if condition {
                    .init("foo")
                } else {
                    .init("bar")
                }

            case false:
                .init("baaz")
            }
        } else {
            .init("quux")
        }
        """
        let options = FormatOptions(propertyTypes: .explicit, swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantType, options: options, exclude: [.wrapMultilineConditionalAssignment, .propertyTypes])
    }

    func testRedundantTypeWithLiteralsInIfExpression() {
        let input = """
        let foo: String = if condition {
            "foo"
        } else {
            "bar"
        }
        """
        let output = """
        let foo = if condition {
            "foo"
        } else {
            "bar"
        }
        """
        let options = FormatOptions(propertyTypes: .inferred, swiftVersion: "5.9")
        testFormatting(for: input, output, rule: .redundantType, options: options, exclude: [.wrapMultilineConditionalAssignment])
    }

    // --redundanttype explicit

    func testVarRedundantTypeRemovalExplicitType() {
        let input = "var view: UIView = UIView()"
        let output = "var view: UIView = .init()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testVarRedundantTypeRemovalExplicitType2() {
        let input = "var view: UIView = UIView /* foo */()"
        let output = "var view: UIView = .init /* foo */()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.spaceAroundComments, .propertyTypes])
    }

    func testLetRedundantGenericTypeRemovalExplicitType() {
        let input = "let relay: BehaviourRelay<Int?> = BehaviourRelay<Int?>(value: nil)"
        let output = "let relay: BehaviourRelay<Int?> = .init(value: nil)"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testLetRedundantGenericTypeRemovalExplicitTypeIfValueOnNextLine() {
        let input = "let relay: Foo<Int?> = Foo<Int?>\n    .default"
        let output = "let relay: Foo<Int?> = \n    .default"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.trailingSpace, .propertyTypes])
    }

    func testVarNonRedundantTypeDoesNothingExplicitType() {
        let input = "var view: UIView = UINavigationBar()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    func testLetRedundantTypeRemovalExplicitType() {
        let input = "let view: UIView = UIView()"
        let output = "let view: UIView = .init()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeRemovedIfValueOnNextLineExplicitType() {
        let input = """
        let view: UIView
            = UIView()
        """
        let output = """
        let view: UIView
            = .init()
        """
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeRemovedIfValueOnNextLine2ExplicitType() {
        let input = """
        let view: UIView =
            UIView()
        """
        let output = """
        let view: UIView =
            .init()
        """
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeRemovalWithCommentExplicitType() {
        let input = "var view: UIView /* view */ = UIView()"
        let output = "var view: UIView /* view */ = .init()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeRemovalWithComment2ExplicitType() {
        let input = "var view: UIView = /* view */ UIView()"
        let output = "var view: UIView = /* view */ .init()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeRemovalWithStaticMember() {
        let input = """
        let session: URLSession = URLSession.default

        init(foo: Foo, bar: Bar) {
            self.foo = foo
            self.bar = bar
        }
        """
        let output = """
        let session: URLSession = .default

        init(foo: Foo, bar: Bar) {
            self.foo = foo
            self.bar = bar
        }
        """
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeRemovalWithStaticFunc() {
        let input = """
        let session: URLSession = URLSession.default()

        init(foo: Foo, bar: Bar) {
            self.foo = foo
            self.bar = bar
        }
        """
        let output = """
        let session: URLSession = .default()

        init(foo: Foo, bar: Bar) {
            self.foo = foo
            self.bar = bar
        }
        """
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeDoesNothingWithChainedMember() {
        let input = "let session: URLSession = URLSession.default.makeCopy()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType, options: options, exclude: [.propertyTypes])
    }

    func testRedundantRedundantChainedMemberTypeRemovedOnSwift5_4() {
        let input = "let session: URLSession = URLSession.default.makeCopy()"
        let output = "let session: URLSession = .default.makeCopy()"
        let options = FormatOptions(propertyTypes: .explicit, swiftVersion: "5.4")
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeDoesNothingWithChainedMember2() {
        let input = "let color: UIColor = UIColor.red.withAlphaComponent(0.5)"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType, options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeDoesNothingWithChainedMember3() {
        let input = "let url: URL = URL(fileURLWithPath: #file).deletingLastPathComponent()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType, options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeRemovedWithChainedMemberOnSwift5_4() {
        let input = "let url: URL = URL(fileURLWithPath: #file).deletingLastPathComponent()"
        let output = "let url: URL = .init(fileURLWithPath: #file).deletingLastPathComponent()"
        let options = FormatOptions(propertyTypes: .explicit, swiftVersion: "5.4")
        testFormatting(for: input, output, rule: .redundantType, options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeDoesNothingIfLet() {
        let input = "if let foo: Foo = Foo() {}"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType, options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeDoesNothingGuardLet() {
        let input = "guard let foo: Foo = Foo() else {}"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType, options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeDoesNothingIfLetAfterComma() {
        let input = "if check == true, let foo: Foo = Foo() {}"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType, options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeWorksAfterIf() {
        let input = """
        if foo {}
        let foo: Foo = Foo()
        """
        let output = """
        if foo {}
        let foo: Foo = .init()
        """
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeIfVoid() {
        let input = "let foo: [Void] = [Void]()"
        let output = "let foo: [Void] = .init()"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testRedundantTypeWithIntegerLiteralNotMangled() {
        let input = "let foo: Int = 1.toFoo"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType,
                       options: options)
    }

    func testRedundantTypeWithFloatLiteralNotMangled() {
        let input = "let foo: Double = 1.0.toFoo"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType,
                       options: options)
    }

    func testRedundantTypeWithArrayLiteralNotMangled() {
        let input = "let foo: [Int] = [1].toFoo"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType,
                       options: options)
    }

    func testRedundantTypeWithBoolLiteralNotMangled() {
        let input = "let foo: Bool = false.toFoo"
        let options = FormatOptions(propertyTypes: .explicit)
        testFormatting(for: input, rule: .redundantType,
                       options: options)
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
        testFormatting(for: input, rule: .redundantType, options: options)
    }

    // --redundanttype infer-locals-only

    func testRedundantTypeinferLocalsOnly() {
        let input = """
        let globalFoo: Foo = Foo()

        struct SomeType {
            let instanceFoo: Foo = Foo()

            func method() {
                let localFoo: Foo = Foo()
                let localString: String = "foo"
            }

            let instanceString: String = "foo"
        }

        let globalString: String = "foo"
        """

        let output = """
        let globalFoo: Foo = .init()

        struct SomeType {
            let instanceFoo: Foo = .init()

            func method() {
                let localFoo = Foo()
                let localString = "foo"
            }

            let instanceString: String = "foo"
        }

        let globalString: String = "foo"
        """

        let options = FormatOptions(propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, output, rule: .redundantType,
                       options: options, exclude: [.propertyTypes])
    }

    func testClassWithWhereNotMistakenForLocalScope() {
        let input = """
        final class Foo<Bar> where Bar: Equatable {
            var isFoo: Bool = false
            var fooName: String = "name"
        }
        """

        let options = FormatOptions(propertyTypes: .inferLocalsOnly)
        testFormatting(for: input, rule: .redundantType, options: options)
    }
}
