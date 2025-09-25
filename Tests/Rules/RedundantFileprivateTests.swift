//
//  RedundantFileprivateTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 2/3/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantFileprivateTests: XCTestCase {
    func testFileScopeFileprivateVarChangedToPrivate() {
        let input = """
        fileprivate var foo = "foo"
        """
        let output = """
        private var foo = "foo"
        """
        testFormatting(for: input, output, rule: .redundantFileprivate)
    }

    func testFileScopeFileprivateVarNotChangedToPrivateIfFragment() {
        let input = """
        fileprivate var foo = "foo"
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarChangedToPrivateIfNotAccessedFromAnotherType() {
        let input = """
        struct Foo {
            fileprivate var foo = "foo"
        }
        """
        let output = """
        struct Foo {
            private var foo = "foo"
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarChangedToPrivateIfNotAccessedFromAnotherTypeAndFileIncludesImports() {
        let input = """
        import Foundation

        struct Foo {
            fileprivate var foo = "foo"
        }
        """
        let output = """
        import Foundation

        struct Foo {
            private var foo = "foo"
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAnotherType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        struct Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromSubclass() {
        let input = """
        class Foo {
            fileprivate func foo() {}
        }

        class Bar: Foo {
            func bar() {
                return foo()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAFunction() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        func getFoo() -> String {
            return Foo().foo
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAConstant() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        let kFoo = Foo().foo
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes])
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAVar() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        var kFoo: String { return Foo().foo }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromCode() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print(Foo().foo)
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAClosure() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print({ Foo().foo }())
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options, exclude: [.redundantClosure])
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAnExtensionOnAnotherType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Bar {
            func bar() {
                print(Foo().foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarChangedToPrivateIfAccessedFromAnExtensionOnSameType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }
        """
        let output = """
        struct Foo {
            private let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarChangedToPrivateIfAccessedViaSelfFromAnExtensionOnSameType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(self.foo)
            }
        }
        """
        let output = """
        struct Foo {
            private let foo = "foo"
        }

        extension Foo {
            func bar() {
                print(self.foo)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options,
                       exclude: [.redundantSelf])
    }

    func testFileprivateMultiLetNotChangedToPrivateIfAccessedOutsideType() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo", bar = "bar"
        }

        extension Foo {
            func bar() {
                print(foo)
            }
        }

        extension Bar {
            func bar() {
                print(Foo().bar)
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options, exclude: [.singlePropertyPerLine])
    }

    func testFileprivateInitChangedToPrivateIfConstructorNotCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate init() {}
        }
        """
        let output = """
        struct Foo {
            private init() {}
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateInitNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate init() {}
        }

        let foo = Foo()
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes])
    }

    func testFileprivateInitNotChangedToPrivateIfConstructorCalledOutsideType2() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        struct Bar {
            let foo = Foo()
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes])
    }

    func testFileprivateStructMemberNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate let bar: String
        }

        let foo = Foo(bar: "test")
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes])
    }

    func testFileprivateClassMemberChangedToPrivateEvenIfConstructorCalledOutsideType() {
        let input = """
        class Foo {
            fileprivate let bar: String
        }

        let foo = Foo()
        """
        let output = """
        class Foo {
            private let bar: String
        }

        let foo = Foo()
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes])
    }

    func testFileprivateExtensionFuncNotChangedToPrivateIfPartOfProtocolConformance() {
        let input = """
        private class Foo: Equatable {
            fileprivate static func == (_: Foo, _: Foo) -> Bool {
                return true
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateInnerTypeNotChangedToPrivate() {
        let input = """
        struct Foo {
            fileprivate enum Bar {
                case a, b
            }

            fileprivate let bar: Bar
        }

        func foo(foo: Foo) {
            print(foo.bar)
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input,
                       rule: .redundantFileprivate,
                       options: options,
                       exclude: [.wrapEnumCases])
    }

    func testFileprivateClassTypeMemberNotChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate class var bar = "bar"
        }

        func foo() {
            print(Foo.bar)
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testOverriddenFileprivateInitNotChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        class Bar: Foo, Equatable {
            override init() {
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testNonOverriddenFileprivateInitChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        class Bar: Baz {
            override init() {
                super.init()
            }
        }
        """
        let output = """
        class Foo {
            private init() {}
        }

        class Bar: Baz {
            override init() {
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateInitNotChangedToPrivateWhenUsingTypeInferredInits() {
        let input = """
        struct Example {
            fileprivate init() {}
        }

        enum Namespace {
            static let example: Example = .init()
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options, exclude: [.propertyTypes])
    }

    func testFileprivateInitNotChangedToPrivateWhenUsingTrailingClosureInit() {
        let input = """
        private struct Foo {}

        public struct Bar {
            fileprivate let consumeFoo: (Foo) -> Void
        }

        public func makeBar() -> Bar {
            Bar { _ in }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateNotChangedToPrivateWhenAccessedFromExtensionOnContainingType() {
        let input = """
        extension Foo.Bar {
            fileprivate init() {}
        }

        extension Foo {
            func baz() -> Foo.Bar {
                return Bar()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateNotChangedToPrivateWhenAccessedFromExtensionOnNestedType() {
        let input = """
        extension Foo {
            fileprivate init() {}
        }

        extension Foo.Bar {
            func baz() -> Foo {
                return Foo()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateInExtensionNotChangedToPrivateWhenAccessedFromSubclass() {
        let input = """
        class Foo: Bar {
            func quux() {
                baz()
            }
        }

        extension Bar {
            fileprivate func baz() {}
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateInitNotChangedToPrivateWhenAccessedFromSubclass() {
        let input = """
        public class Foo {
            fileprivate init() {}
        }

        private class Bar: Foo {
            init(something: String) {
                print(something)
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateInExtensionNotChangedToPrivateWhenAccessedFromExtensionOnSubclass() {
        let input = """
        class Foo: Bar {}

        extension Foo {
            func quux() {
                baz()
            }
        }

        extension Bar {
            fileprivate func baz() {}
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateVarWithPropertWrapperNotChangedToPrivateIfAccessedFromSubclass() {
        let input = """
        class Foo {
            @Foo fileprivate var foo = 5
        }

        class Bar: Foo {
            func bar() {
                return $foo
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateInArrayExtensionNotChangedToPrivateWhenAccessedInFile() {
        let input = """
        extension [String] {
            fileprivate func fileprivateMember() {}
        }

        extension Namespace {
            func testCanAccessFileprivateMember() {
                ["string", "array"].fileprivateMember()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate, options: options)
    }

    func testFileprivateInArrayExtensionNotChangedToPrivateWhenAccessedInFile2() {
        let input = """
        extension Array<String> {
            fileprivate func fileprivateMember() {}
        }

        extension Namespace {
            func testCanAccessFileprivateMember() {
                ["string", "array"].fileprivateMember()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: .redundantFileprivate,
                       options: options, exclude: [.typeSugar])
    }
}
