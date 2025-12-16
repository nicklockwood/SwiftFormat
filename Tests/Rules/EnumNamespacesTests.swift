//
//  EnumNamespacesTests.swift
//  SwiftFormatTests
//
//  Created by Facundo Menzella on 9/20/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class EnumNamespacesTests: XCTestCase {
    func testEnumNamespacesClassAsProtocolRestriction() {
        let input = """
        @objc protocol Foo: class {
            @objc static var expressionTypes: [String: RuntimeType] { get }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesConformingOtherType() {
        let input = """
        private final class CustomUITableViewCell: UITableViewCell {}
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesImportClass() {
        let input = """
        import class MyUIKit.AutoHeightTableView

        enum Foo {
            static var bar: String
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesImportStruct() {
        let input = """
        import struct Core.CurrencyFormatter

        enum Foo {
            static var bar: String
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesClassFunction() {
        let input = """
        class Container {
            class func bar() {}
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesRemovingExtraKeywords() {
        let input = """
        final class MyNamespace {
            static let bar = "bar"
        }
        """
        let output = """
        enum MyNamespace {
            static let bar = "bar"
        }
        """
        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesNestedTypes() {
        let input = """
        enum Namespace {}
        extension Namespace {
            struct Constants {
                static let bar = "bar"
            }
        }
        """
        let output = """
        enum Namespace {}
        extension Namespace {
            enum Constants {
                static let bar = "bar"
            }
        }
        """
        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesNestedTypes2() {
        let input = """
        struct Namespace {
            struct NestedNamespace {
                static let foo: Int
                static let bar: Int
            }
        }
        """
        let output = """
        enum Namespace {
            enum NestedNamespace {
                static let foo: Int
                static let bar: Int
            }
        }
        """
        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesNestedTypes3() {
        let input = """
        struct Namespace {
            struct TypeNestedInNamespace {
                let foo: Int
                let bar: Int
            }
        }
        """
        let output = """
        enum Namespace {
            struct TypeNestedInNamespace {
                let foo: Int
                let bar: Int
            }
        }
        """
        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesNestedTypes4() {
        let input = """
        struct Namespace {
            static func staticFunction() {
                struct NestedType {
                    init() {}
                }
            }
        }
        """
        let output = """
        enum Namespace {
            static func staticFunction() {
                struct NestedType {
                    init() {}
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesNestedTypes5() {
        let input = """
        struct Namespace {
            static func staticFunction() {
                func nestedFunction() { /* ... */ }
            }
        }
        """
        let output = """
        enum Namespace {
            static func staticFunction() {
                func nestedFunction() { /* ... */ }
            }
        }
        """
        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesStaticVariable() {
        let input = """
        struct Constants {
            static let β = 0, 5
        }
        """
        let output = """
        enum Constants {
            static let β = 0, 5
        }
        """
        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesStaticAndInstanceVariable() {
        let input = """
        struct Constants {
            static let β = 0, 5
            let Ɣ = 0, 3
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesStaticFunction() {
        let input = """
        struct Constants {
            static func remoteConfig() -> Int {
                return 10
            }
        }
        """
        let output = """
        enum Constants {
            static func remoteConfig() -> Int {
                return 10
            }
        }
        """
        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesStaticAndInstanceFunction() {
        let input = """
        struct Constants {
            static func remoteConfig() -> Int {
                return 10
            }

            func instanceConfig(offset: Int) -> Int {
                return offset + 10
            }
        }
        """

        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespaceDoesNothing() {
        let input = """
        struct Foo {
            #if BAR
                func something() {}
            #else
                func something() {}
            #endif
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespaceDoesNothingForEmptyDeclaration() {
        let input = """
        struct Foo {}
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfTypeInitializedInternally() {
        let input = """
        struct Foo {
            static func bar() {
                Foo().baz
            }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfInitializedInternally() {
        let input = """
        struct Foo {
            static func bar() {
                Self().baz
            }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfInitializedInternally2() {
        let input = """
        struct Foo {
            static func bar() -> Foo {
                self.init()
            }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfAssignedInternally() {
        let input = """
        class Foo {
            static func bar() {
                let bundle = Bundle(for: self)
            }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfAssignedInternally2() {
        let input = """
        class Foo {
            static func bar() {
                let `class` = self
            }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesDoesNothingIfSelfAssignedInternally3() {
        let input = """
        class Foo {
            static func bar() {
                let `class` = Foo.self
            }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testClassFuncNotReplacedByEnum() {
        let input = """
        class Foo {
            class override func foo() {
                Bar.bar()
            }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces,
                       exclude: [.modifierOrder])
    }

    func testOpenClassNotReplacedByEnum() {
        let input = """
        open class Foo {
            public static let bar = "bar"
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testClassNotReplacedByEnum() {
        let input = """
        class Foo {
            static let bar = "bar"
        }
        """
        let options = FormatOptions(enumNamespaces: .structsOnly)
        testFormatting(for: input, rule: .enumNamespaces, options: options)
    }

    func testEnumNamespacesAfterImport() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1569
        let input = """
        import Foundation

        final class MyViewModel2 {
            static let = "A"
        }
        """

        let output = """
        import Foundation

        enum MyViewModel2 {
            static let = "A"
        }
        """

        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesAfterImport2() {
        // https://github.com/nicklockwood/SwiftFormat/issues/1569
        let input = """
        final class MyViewModel {
            static let = "A"
        }

        import Foundation

        final class MyViewModel2 {
            static let = "A"
        }
        """

        let output = """
        enum MyViewModel {
            static let = "A"
        }

        import Foundation

        enum MyViewModel2 {
            static let = "A"
        }
        """

        testFormatting(for: input, output, rule: .enumNamespaces)
    }

    func testEnumNamespacesNotAppliedToNonFinalClass() {
        let input = """
        class Foo {
            static let = "A"
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesNotAppliedIfObjC() {
        let input = """
        @objc(NSFoo)
        final class Foo {
            static let = "A"
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesNotAppliedIfMacro() {
        let input = """
        @FooBar
        struct Foo {
            static let = "A"
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesNotAppliedIfParameterizedMacro() {
        let input = """
        @FooMacro(arg: "Foo")
        struct Foo {
            static let = "A"
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesNotAppliedIfGenericMacro() {
        let input = """
        @FooMacro<Int>
        struct Foo {
            static let = "A"
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesNotAppliedIfGenericParameterizedMacro() {
        let input = """
        @FooMacro<Int>(arg: 5)
        struct Foo {
            static let = "A"
        }
        """
        testFormatting(for: input, rule: .enumNamespaces)
    }

    func testEnumNamespacesNotAppliedToStructWithInstanceSubscript() {
        let input = """
        struct MyStruct {
            subscript(key: String) -> String {
                return key
            }
        }
        """
        testFormatting(for: input, rule: .enumNamespaces, exclude: [.unusedArguments])
    }
}
