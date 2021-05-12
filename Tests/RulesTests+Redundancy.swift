//
//  RulesTests+Redundancy.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 04/09/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

extension RulesTests {
    // MARK: - redundantBreak

    func testRedundantBreaksRemoved() {
        let input = """
        switch x {
        case foo:
            print("hello")
            break
        case bar:
            print("world")
            break
        default:
            print("goodbye")
            break
        }
        """
        let output = """
        switch x {
        case foo:
            print("hello")
        case bar:
            print("world")
        default:
            print("goodbye")
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantBreak)
    }

    func testBreakInEmptyCaseNotRemoved() {
        let input = """
        switch x {
        case foo:
            break
        case bar:
            break
        default:
            break
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantBreak)
    }

    func testConditionalBreakNotRemoved() {
        let input = """
        switch x {
        case foo:
            if bar {
                break
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantBreak)
    }

    func testBreakAfterSemicolonNotMangled() {
        let input = """
        switch foo {
        case 1: print(1); break
        }
        """
        let output = """
        switch foo {
        case 1: print(1);
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantBreak, exclude: ["semicolons"])
    }

    // MARK: - redundantExtensionACL

    func testPublicExtensionMemberACLStripped() {
        let input = """
        public extension Foo {
            public var bar: Int { 5 }
            private static let baz = "baz"
            public func quux() {}
        }
        """
        let output = """
        public extension Foo {
            var bar: Int { 5 }
            private static let baz = "baz"
            func quux() {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantExtensionACL)
    }

    func testPrivateExtensionMemberACLNotStrippedUnlessFileprivate() {
        let input = """
        private extension Foo {
            fileprivate var bar: Int { 5 }
            private static let baz = "baz"
            fileprivate func quux() {}
        }
        """
        let output = """
        private extension Foo {
            var bar: Int { 5 }
            private static let baz = "baz"
            func quux() {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantExtensionACL)
    }

    // MARK: - redundantFileprivate

    func testFileScopeFileprivateVarChangedToPrivate() {
        let input = """
        fileprivate var foo = "foo"
        """
        let output = """
        private var foo = "foo"
        """
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate)
    }

    func testFileScopeFileprivateVarNotChangedToPrivateIfFragment() {
        let input = """
        fileprivate var foo = "foo"
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAConstant() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        let kFoo = Foo().foo
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAVar() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        var kFoo: String { return Foo().foo }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromCode() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print(Foo().foo)
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateVarNotChangedToPrivateIfAccessedFromAClosure() {
        let input = """
        struct Foo {
            fileprivate let foo = "foo"
        }

        print({ Foo().foo }())
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options,
                       exclude: ["redundantSelf"])
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateInitNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate init() {}
        }

        let foo = Foo()
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testFileprivateStructMemberNotChangedToPrivateIfConstructorCalledOutsideType() {
        let input = """
        struct Foo {
            fileprivate let bar: String
        }

        let foo = Foo(bar: "test")
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
                       rule: FormatRules.redundantFileprivate,
                       options: options,
                       exclude: ["wrapEnumCases"])
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testOverriddenFileprivateInitNotChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        class Bar: Foo, Equatable {
            override public init() {
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    func testNonOverriddenFileprivateInitChangedToPrivate() {
        let input = """
        class Foo {
            fileprivate init() {}
        }

        class Bar: Baz {
            override public init() {
                super.init()
            }
        }
        """
        let output = """
        class Foo {
            private init() {}
        }

        class Bar: Baz {
            override public init() {
                super.init()
            }
        }
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
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
        testFormatting(for: input, rule: FormatRules.redundantFileprivate, options: options)
    }

    // MARK: - redundantGet

    func testRemoveSingleLineIsolatedGet() {
        let input = "var foo: Int { get { return 5 } }"
        let output = "var foo: Int { return 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantGet)
    }

    func testRemoveMultilineIsolatedGet() {
        let input = "var foo: Int {\n    get {\n        return 5\n    }\n}"
        let output = "var foo: Int {\n    return 5\n}"
        testFormatting(for: input, [output], rules: [FormatRules.redundantGet, FormatRules.indent])
    }

    func testNoRemoveMultilineGetSet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { foo = newValue }\n}"
        testFormatting(for: input, rule: FormatRules.redundantGet)
    }

    func testNoRemoveAttributedGet() {
        let input = "var enabled: Bool { @objc(isEnabled) get { true } }"
        testFormatting(for: input, rule: FormatRules.redundantGet)
    }

    func testRemoveSubscriptGet() {
        let input = "subscript(_ index: Int) {\n    get {\n        return lookup(index)\n    }\n}"
        let output = "subscript(_ index: Int) {\n    return lookup(index)\n}"
        testFormatting(for: input, [output], rules: [FormatRules.redundantGet, FormatRules.indent])
    }

    func testGetNotRemovedInFunction() {
        let input = "func foo() {\n    get {\n        self.lookup(index)\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantGet)
    }

    // MARK: - redundantInit

    func testRemoveRedundantInit() {
        let input = "[1].flatMap { String.init($0) }"
        let output = "[1].flatMap { String($0) }"
        testFormatting(for: input, output, rule: FormatRules.redundantInit)
    }

    func testRemoveRedundantInit2() {
        let input = "[String.self].map { Type in Type.init(foo: 1) }"
        let output = "[String.self].map { Type in Type(foo: 1) }"
        testFormatting(for: input, output, rule: FormatRules.redundantInit)
    }

    func testRemoveRedundantInit3() {
        let input = "String.init(\"text\")"
        let output = "String(\"text\")"
        testFormatting(for: input, output, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitInSuperCall() {
        let input = "class C: NSObject { override init() { super.init() } }"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitInSelfCall() {
        let input = "struct S { let n: Int }; extension S { init() { self.init(n: 1) } }"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitWhenPassedAsFunction() {
        let input = "[1].flatMap(String.init)"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitWhenUsedOnMetatype() {
        let input = "[String.self].map { type in type.init(1) }"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitWhenUsedOnImplicitClosureMetatype() {
        let input = "[String.self].map { $0.init(1) }"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    func testDontRemoveInitWithExplicitSignature() {
        let input = "[String.self].map(Foo.init(bar:))"
        testFormatting(for: input, rule: FormatRules.redundantInit)
    }

    // MARK: - redundantLetError

    func testCatchLetError() {
        let input = "do {} catch let error {}"
        let output = "do {} catch {}"
        testFormatting(for: input, output, rule: FormatRules.redundantLetError)
    }

    // MARK: - redundantObjc

    func testRedundantObjcRemovedFromBeforeOutlet() {
        let input = "@objc @IBOutlet var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testRedundantObjcRemovedFromAfterOutlet() {
        let input = "@IBOutlet @objc var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testRedundantObjcRemovedFromLineBeforeOutlet() {
        let input = "@objc\n@IBOutlet var label: UILabel!"
        let output = "\n@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testRedundantObjcCommentNotRemoved() {
        let input = "@objc // an outlet\n@IBOutlet var label: UILabel!"
        let output = "// an outlet\n@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedFromNSCopying() {
        let input = "@objc @NSCopying var foo: String!"
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testRenamedObjcNotRemoved() {
        let input = "@IBOutlet @objc(uiLabel) var label: UILabel!"
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcRemovedOnObjcMembersClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc var foo: String
        }
        """
        let output = """
        @objcMembers class Foo: NSObject {
            var foo: String
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcRemovedOnRenamedObjcMembersClass() {
        let input = """
        @objcMembers @objc(OCFoo) class Foo: NSObject {
            @objc var foo: String
        }
        """
        let output = """
        @objcMembers @objc(OCFoo) class Foo: NSObject {
            var foo: String
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnNestedClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc class Bar: NSObject {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnRenamedPrivateNestedClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private class Bar: NSObject {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnNestedEnum() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc enum Bar: Int {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcRemovedOnObjcExtensionVar() {
        let input = """
        @objc extension Foo {
            @objc var foo: String {}
        }
        """
        let output = """
        @objc extension Foo {
            var foo: String {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcRemovedOnObjcExtensionFunc() {
        let input = """
        @objc extension Foo {
            @objc func foo() -> String {}
        }
        """
        let output = """
        @objc extension Foo {
            func foo() -> String {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnPrivateFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    func testObjcNotRemovedOnFileprivateFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc fileprivate func bar() {}
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantObjc)
    }

    // MARK: - redundantType

    func testVarRedundantTypeRemoval() {
        let input = "var view: UIView = UIView()"
        let output = "var view = UIView()"
        testFormatting(for: input, output, rule: FormatRules.redundantType)
    }

    func testLetRedundantGenericTypeRemoval() {
        let input = "let relay: BehaviourRelay<Int?> = BehaviourRelay<Int?>(value: nil)"
        let output = "let relay = BehaviourRelay<Int?>(value: nil)"
        testFormatting(for: input, output, rule: FormatRules.redundantType)
    }

    func testVarNonRedundantTypeDoesNothing() {
        let input = "var view: UIView = UINavigationBar()"
        testFormatting(for: input, rule: FormatRules.redundantType)
    }

    func testLetRedundantTypeRemoval() {
        let input = "let view: UIView = UIView()"
        let output = "let view = UIView()"
        testFormatting(for: input, output, rule: FormatRules.redundantType)
    }

    func testLetNonRedundantTypeDoesNothing() {
        let input = "let view: UIView = UINavigationBar()"
        testFormatting(for: input, rule: FormatRules.redundantType)
    }

    func testTypeNoRedundancyDoesNothing() {
        let input = "let foo: Bar = 5"
        testFormatting(for: input, rule: FormatRules.redundantType)
    }

    func testClassTwoVariablesNoRedundantTypeDoesNothing() {
        let input = """
        final class LGWebSocketClient: WebSocketClient, WebSocketLibraryDelegate {
            var webSocket: WebSocketLibraryProtocol
            var timeoutIntervalForRequest: TimeInterval = LGCoreKitConstants.websocketTimeOutTimeInterval
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantType)
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
        testFormatting(for: input, output, rule: FormatRules.redundantType)
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
        testFormatting(for: input, output, rule: FormatRules.redundantType)
    }

    func testRedundantTypeRemovalWithComment() {
        let input = "var view: UIView /* view */ = UIView()"
        let output = "var view /* view */ = UIView()"
        testFormatting(for: input, output, rule: FormatRules.redundantType)
    }

    func testRedundantTypeRemovalWithComment2() {
        let input = "var view: UIView = /* view */ UIView()"
        let output = "var view = /* view */ UIView()"
        testFormatting(for: input, output, rule: FormatRules.redundantType)
    }

    func testNonRedundantTernaryConditionTypeNotRemoved() {
        let input = "let foo: Bar = Bar.baz() ? .bar1 : .bar2"
        testFormatting(for: input, rule: FormatRules.redundantType)
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
        testFormatting(for: input, output, rule: FormatRules.redundantType)
    }

    func testNoRemoveRedundantTypeIfVoid() {
        let input = "let foo: Void = Void()"
        testFormatting(for: input, rule: FormatRules.redundantType,
                       exclude: ["void"])
    }

    func testNoRemoveRedundantTypeIfVoid2() {
        let input = "let foo: () = ()"
        testFormatting(for: input, rule: FormatRules.redundantType,
                       exclude: ["void"])
    }

    func testNoRemoveRedundantTypeIfVoid3() {
        let input = "let foo: [Void] = [Void]()"
        testFormatting(for: input, rule: FormatRules.redundantType)
    }

    func testNoRemoveRedundantTypeIfVoid4() {
        let input = "let foo: Array<Void> = Array<Void>()"
        testFormatting(for: input, rule: FormatRules.redundantType,
                       exclude: ["typeSugar"])
    }

    func testNoRemoveRedundantTypeIfVoid5() {
        let input = "let foo: Void? = Void?.none"
        testFormatting(for: input, rule: FormatRules.redundantType)
    }

    func testNoRemoveRedundantTypeIfVoid6() {
        let input = "let foo: Optional<Void> = Optional<Void>.none"
        testFormatting(for: input, rule: FormatRules.redundantType,
                       exclude: ["typeSugar"])
    }

    // --redundanttype explicit

    func testVarRedundantTypeRemovalExplicitType() {
        let input = "var view: UIView = UIView()"
        let output = "var view: UIView = .init()"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
    }

    func testLetRedundantGenericTypeRemovalExplicitType() {
        let input = "let relay: BehaviourRelay<Int?> = BehaviourRelay<Int?>(value: nil)"
        let output = "let relay: BehaviourRelay<Int?> = .init(value: nil)"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
    }

    func testVarNonRedundantTypeDoesNothingExplicitType() {
        let input = "var view: UIView = UINavigationBar()"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, rule: FormatRules.redundantType, options: options)
    }

    func testLetRedundantTypeRemovalExplicitType() {
        let input = "let view: UIView = UIView()"
        let output = "let view: UIView = .init()"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
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
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
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
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
    }

    func testRedundantTypeRemovalWithCommentExplicitType() {
        let input = "var view: UIView /* view */ = UIView()"
        let output = "var view: UIView /* view */ = .init()"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
    }

    func testRedundantTypeRemovalWithComment2ExplicitType() {
        let input = "var view: UIView = /* view */ UIView()"
        let output = "var view: UIView = /* view */ .init()"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
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
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
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
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
    }

    func testRedundantTypeDoesNothingWithStaticMemberMakingCopy() {
        let input = "let session: URLSession = URLSession.default.makeCopy()"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, rule: FormatRules.redundantType, options: options)
    }

    func testRedundantTypeDoesNothingIfLet() {
        let input = "if let foo: Foo = Foo() {}"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, rule: FormatRules.redundantType, options: options)
    }

    func testRedundantTypeDoesNothingGuardLet() {
        let input = "guard let foo: Foo = Foo() else {}"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, rule: FormatRules.redundantType, options: options)
    }

    func testRedundantTypeDoesNothingIfLetAfterComma() {
        let input = "if check == true, let foo: Foo = Foo() {}"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, rule: FormatRules.redundantType, options: options)
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
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
    }

    func testRedundantTypeIfVoid() {
        let input = "let foo: [Void] = [Void]()"
        let output = "let foo: [Void] = .init()"
        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
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
        """

        let options = FormatOptions(redundantType: .inferred)
        testFormatting(for: input, output, rule: FormatRules.redundantType, options: options)
    }

    func testRedundantTypePreservesLiteralRepresentableTypes() {
        let input = """
        let a: MyBoolRepresentable = true
        let b: MyStringRepresentable = "foo"
        let c: MyIntRepresentable = 1
        let d: MyDoubleRepresentable = 3.14
        let e: MyArrayRepresentable = ["bar"]
        let f: MyDictionaryRepresentable = ["baaz": 1]
        """

        let options = FormatOptions(redundantType: .explicit)
        testFormatting(for: input, rule: FormatRules.redundantType, options: options)
    }

    // MARK: - redundantNilInit

    func testRemoveRedundantNilInit() {
        let input = "var foo: Int? = nil\nlet bar: Int? = nil"
        let output = "var foo: Int?\nlet bar: Int? = nil"
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveLetNilInitAfterVar() {
        let input = "var foo: Int; let bar: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNonNilInit() {
        let input = "var foo: Int? = 0"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testRemoveRedundantImplicitUnwrapInit() {
        let input = "var foo: Int! = nil"
        let output = "var foo: Int!"
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    func testRemoveMultipleRedundantNilInitsInSameLine() {
        let input = "var foo: Int? = nil, bar: Int? = nil"
        let output = "var foo: Int?, bar: Int?"
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveLazyVarNilInit() {
        let input = "lazy var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveLazyPublicPrivateSetVarNilInit() {
        let input = "lazy private(set) public var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit,
                       exclude: ["modifierOrder", "specifiers"])
    }

    func testNoRemoveCodableNilInit() {
        let input = "struct Foo: Codable, Bar {\n    enum CodingKeys: String, CodingKey {\n        case bar = \"_bar\"\n    }\n\n    var bar: Int?\n    var baz: String? = nil\n}"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitWithPropertyWrapper() {
        let input = "@Foo var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitWithLowercasePropertyWrapper() {
        let input = "@foo var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitWithPropertyWrapperWithArgument() {
        let input = "@Foo(bar: baz) var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitWithLowercasePropertyWrapperWithArgument() {
        let input = "@foo(bar: baz) var foo: Int? = nil"
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testRemoveNilInitWithObjcAttributes() {
        let input = "@objc var foo: Int? = nil"
        let output = "@objc var foo: Int?"
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    func testNoRemoveNilInitInStructWithDefaultInit() {
        let input = """
        struct Foo {
            var bar: String? = nil
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantNilInit)
    }

    func testRemoveNilInitInStructWithDefaultInitInSwiftVersion5_2() {
        let input = """
        struct Foo {
            var bar: String? = nil
        }
        """
        let output = """
        struct Foo {
            var bar: String?
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit,
                       options: FormatOptions(swiftVersion: "5.2"))
    }

    func testRemoveNilInitInStructWithCustomInit() {
        let input = """
        struct Foo {
            var bar: String? = nil
            init() {
                bar = "bar"
            }
        }
        """
        let output = """
        struct Foo {
            var bar: String?
            init() {
                bar = "bar"
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantNilInit)
    }

    // MARK: - redundantLet

    func testRemoveRedundantLet() {
        let input = "let _ = bar {}"
        let output = "_ = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetWithType() {
        let input = "let _: String = bar {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    func testRemoveRedundantLetInCase() {
        let input = "if case .foo(let _) = bar {}"
        let output = "if case .foo(_) = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantLet, exclude: ["redundantPattern"])
    }

    func testRemoveRedundantVarsInCase() {
        let input = "if case .foo(var _, var /* unused */ _) = bar {}"
        let output = "if case .foo(_, /* unused */ _) = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetInIf() {
        let input = "if let _ = foo {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetInMultiIf() {
        let input = "if foo == bar, /* comment! */ let _ = baz {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetInGuard() {
        let input = "guard let _ = foo else {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    func testNoRemoveLetInWhile() {
        let input = "while let _ = foo {}"
        testFormatting(for: input, rule: FormatRules.redundantLet)
    }

    // MARK: - redundantPattern

    func testRemoveRedundantPatternInIfCase() {
        let input = "if case .foo(_, _) = bar {}"
        let output = "if case .foo = bar {}"
        testFormatting(for: input, output, rule: FormatRules.redundantPattern)
    }

    func testNoRemoveRequiredPatternInIfCase() {
        let input = "if case (_, _) = bar {}"
        testFormatting(for: input, rule: FormatRules.redundantPattern)
    }

    func testRemoveRedundantPatternInSwitchCase() {
        let input = "switch foo {\ncase .bar(_, _): break\ndefault: break\n}"
        let output = "switch foo {\ncase .bar: break\ndefault: break\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantPattern)
    }

    func testNoRemoveRequiredPatternInSwitchCase() {
        let input = "switch foo {\ncase (_, _): break\ndefault: break\n}"
        testFormatting(for: input, rule: FormatRules.redundantPattern)
    }

    func testSimplifyLetPattern() {
        let input = "let(_, _) = bar"
        let output = "let _ = bar"
        testFormatting(for: input, output, rule: FormatRules.redundantPattern, exclude: ["redundantLet"])
    }

    func testNoRemoveVoidFunctionCall() {
        let input = "if case .foo() = bar {}"
        testFormatting(for: input, rule: FormatRules.redundantPattern)
    }

    func testNoRemoveMethodSignature() {
        let input = "func foo(_, _) {}"
        testFormatting(for: input, rule: FormatRules.redundantPattern)
    }

    // MARK: - redundantRawValues

    func testRemoveRedundantRawString() {
        let input = "enum Foo: String {\n    case bar = \"bar\"\n    case baz = \"baz\"\n}"
        let output = "enum Foo: String {\n    case bar\n    case baz\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantRawValues)
    }

    func testRemoveCommaDelimitedCaseRawStringCases() {
        let input = "enum Foo: String { case bar = \"bar\", baz = \"baz\" }"
        let output = "enum Foo: String { case bar, baz }"
        testFormatting(for: input, output, rule: FormatRules.redundantRawValues,
                       exclude: ["wrapEnumCases"])
    }

    func testRemoveBacktickCaseRawStringCases() {
        let input = "enum Foo: String { case `as` = \"as\", `let` = \"let\" }"
        let output = "enum Foo: String { case `as`, `let` }"
        testFormatting(for: input, output, rule: FormatRules.redundantRawValues,
                       exclude: ["wrapEnumCases"])
    }

    func testNoRemoveRawStringIfNameDoesntMatch() {
        let input = "enum Foo: String {\n    case bar = \"foo\"\n}"
        testFormatting(for: input, rule: FormatRules.redundantRawValues)
    }

    // MARK: - redundantVoidReturnType

    func testRemoveRedundantVoidReturnType() {
        let input = "func foo() -> Void {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: FormatRules.redundantVoidReturnType)
    }

    func testRemoveRedundantEmptyReturnType() {
        let input = "func foo() -> () {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: FormatRules.redundantVoidReturnType)
    }

    func testRemoveRedundantVoidTupleReturnType() {
        let input = "func foo() -> (Void) {}"
        let output = "func foo() {}"
        testFormatting(for: input, output, rule: FormatRules.redundantVoidReturnType)
    }

    func testNoRemoveCommentFollowingRedundantVoidReturnType() {
        let input = "func foo() -> Void /* void */ {}"
        let output = "func foo() /* void */ {}"
        testFormatting(for: input, output, rule: FormatRules.redundantVoidReturnType)
    }

    func testNoRemoveRequiredVoidReturnType() {
        let input = "typealias Foo = () -> Void"
        testFormatting(for: input, rule: FormatRules.redundantVoidReturnType)
    }

    func testNoRemoveChainedVoidReturnType() {
        let input = "func foo() -> () -> Void {}"
        testFormatting(for: input, rule: FormatRules.redundantVoidReturnType)
    }

    func testNoRemoveRedundantVoidInClosureArguments() {
        let input = "{ (foo: Bar) -> Void in foo() }"
        testFormatting(for: input, rule: FormatRules.redundantVoidReturnType)
    }

    // MARK: - redundantReturn

    func testRemoveRedundantReturnInClosure() {
        let input = "foo(with: { return 5 })"
        let output = "foo(with: { 5 })"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, exclude: ["trailingClosures"])
    }

    func testRemoveRedundantReturnInClosureWithArgs() {
        let input = "foo(with: { foo in return foo })"
        let output = "foo(with: { foo in foo })"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, exclude: ["trailingClosures"])
    }

    func testRemoveRedundantReturnInMap() {
        let input = "let foo = bar.map { return 1 }"
        let output = "let foo = bar.map { 1 }"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInComputedVar() {
        let input = "var foo: Int { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInComputedVar() {
        let input = "var foo: Int { return 5 }"
        let output = "var foo: Int { 5 }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInGet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { _foo = newValue }\n}"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInGet() {
        let input = "var foo: Int {\n    get { return 5 }\n    set { _foo = newValue }\n}"
        let output = "var foo: Int {\n    get { 5 }\n    set { _foo = newValue }\n}"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInGetClosure() {
        let input = "let foo = get { return 5 }"
        let output = "let foo = get { 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInVarClosure() {
        let input = "var foo = { return 5 }()"
        let output = "var foo = { 5 }()"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInParenthesizedClosure() {
        let input = "var foo = ({ return 5 }())"
        let output = "var foo = ({ 5 }())"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, exclude: ["redundantParens"])
    }

    func testNoRemoveReturnInFunction() {
        let input = "func foo() -> Int { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInFunction() {
        let input = "func foo() -> Int { return 5 }"
        let output = "func foo() -> Int { 5 }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInOperatorFunction() {
        let input = "func + (lhs: Int, rhs: Int) -> Int { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn, exclude: ["unusedArguments"])
    }

    func testRemoveReturnInOperatorFunction() {
        let input = "func + (lhs: Int, rhs: Int) -> Int { return 5 }"
        let output = "func + (lhs: Int, rhs: Int) -> Int { 5 }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoRemoveReturnInFailableInit() {
        let input = "init?() { return nil }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveReturnInFailableInit() {
        let input = "init?() { return nil }"
        let output = "init?() { nil }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInSubscript() {
        let input = "subscript(index: Int) -> String { return nil }"
        testFormatting(for: input, rule: FormatRules.redundantReturn, exclude: ["unusedArguments"])
    }

    func testRemoveReturnInSubscript() {
        let input = "subscript(index: Int) -> String { return nil }"
        let output = "subscript(index: Int) -> String { nil }"
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn, options: options,
                       exclude: ["unusedArguments"])
    }

    func testNoRemoveReturnInCatch() {
        let input = """
        func foo() -> Int {
            do {
                return try Bar()
            } catch let e as Error {
                return -1
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: FormatRules.redundantReturn, options: options)
    }

    func testNoRemoveReturnInForIn() {
        let input = "for foo in bar { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInForWhere() {
        let input = "for foo in bar where baz { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInIfLetTry() {
        let input = "if let foo = try? bar() { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInMultiIfLetTry() {
        let input = "if let foo = bar, let bar = baz { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnAfterMultipleAs() {
        let input = "if foo as? bar as? baz { return 5 }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveVoidReturn() {
        let input = "{ _ in return }"
        let output = "{ _ in }"
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnAfterKeyPath() {
        let input = "func foo() { if bar == #keyPath(baz) { return 5 } }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnAfterParentheses() {
        let input = "if let foo = (bar as? String) { return foo }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInTupleVarGetter() {
        let input = "var foo: (Int, Int) { return (1, 2) }"
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInIfLetWithNoSpaceAfterParen() {
        let input = """
        var foo: String? {
            if let bar = baz(){
                return bar
            } else {
                return nil
            }
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: FormatRules.redundantReturn, options: options,
                       exclude: ["spaceAroundBraces", "spaceAroundParens"])
    }

    func testNoRemoveReturnInIfWithUnParenthesizedClosure() {
        let input = """
        if foo { $0.bar } {
            return true
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testRemoveBlankLineWithReturn() {
        let input = """
        foo {
            return
                bar
        }
        """
        let output = """
        foo {
            bar
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantReturn,
                       exclude: ["indent"])
    }

    func testRemoveRedundantReturnInFunctionWithWhereClause() {
        let input = """
        func foo<T>(_ name: String) -> T where T: Equatable {
            return name
        }
        """
        let output = """
        func foo<T>(_ name: String) -> T where T: Equatable {
            name
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn,
                       options: options)
    }

    func testRemoveRedundantReturnInSubscriptWithWhereClause() {
        let input = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            return name
        }
        """
        let output = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            name
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, output, rule: FormatRules.redundantReturn,
                       options: options)
    }

    func testNoRemoveReturnFollowedByMoreCode() {
        let input = """
        var foo: Bar = {
            return foo
            let bar = baz
            return bar
        }()
        """
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveReturnInForWhereLoop() {
        let input = """
        func foo() -> Bool {
            for bar in baz where !bar {
                return false
            }
            return true
        }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: FormatRules.redundantReturn, options: options)
    }

    func testRedundantReturnInVoidFunction() {
        let input = """
        func foo() {
            return
        }
        """
        let output = """
        func foo() {
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantReturn,
                       exclude: ["emptyBraces"])
    }

    func testRedundantReturnInVoidFunction2() {
        let input = """
        func foo() {
            print("")
            return
        }
        """
        let output = """
        func foo() {
            print("")
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testRedundantReturnInVoidFunction3() {
        let input = """
        func foo() {
            // empty
            return
        }
        """
        let output = """
        func foo() {
            // empty
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testRedundantReturnInVoidFunction4() {
        let input = """
        func foo() {
            return // empty
        }
        """
        let output = """
        func foo() {
            // empty
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantReturn)
    }

    func testNoRemoveVoidReturnInCatch() {
        let input = """
        func foo() {
            do {
                try Foo()
            } catch Feature.error {
                print("feature error")
                return
            }
            print("foo")
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantReturn)
    }

    // MARK: - redundantBackticks

    func testRemoveRedundantBackticksInLet() {
        let input = "let `foo` = bar"
        let output = "let foo = bar"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeyword() {
        let input = "let `let` = foo"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundSelf() {
        let input = "let `self` = foo"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundClassSelfInTypealias() {
        let input = "typealias `Self` = Foo"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfAsReturnType() {
        let input = "func foo(bar: `Self`) { print(bar) }"
        let output = "func foo(bar: Self) { print(bar) }"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfAsParameterType() {
        let input = "func foo() -> `Self` {}"
        let output = "func foo() -> Self {}"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundClassSelfArgument() {
        let input = "func foo(`Self`: Foo) { print(Self) }"
        let output = "func foo(Self: Foo) { print(Self) }"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeywordFollowedByType() {
        let input = "let `default`: Int = foo"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundContextualGet() {
        let input = "var foo: Int {\n    `get`()\n    return 5\n}"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundGetArgument() {
        let input = "func foo(`get` value: Int) { print(value) }"
        let output = "func foo(get value: Int) { print(value) }"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundTypeAtRootLevel() {
        let input = "enum `Type` {}"
        let output = "enum Type {}"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundTypeInsideType() {
        let input = "struct Foo {\n    enum `Type` {}\n}"
        testFormatting(for: input, rule: FormatRules.redundantBackticks, exclude: ["enumNamespaces"])
    }

    func testNoRemoveBackticksAroundLetArgument() {
        let input = "func foo(`let`: Foo) { print(`let`) }"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundTrueArgument() {
        let input = "func foo(`true`: Foo) { print(`true`) }"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundTrueArgument() {
        let input = "func foo(`true`: Foo) { print(`true`) }"
        let output = "func foo(true: Foo) { print(`true`) }"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks, options: options)
    }

    func testNoRemoveBackticksAroundTypeProperty() {
        let input = "var type: Foo.`Type`"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundTypePropertyInsideType() {
        let input = "struct Foo {\n    enum `Type` {}\n}"
        testFormatting(for: input, rule: FormatRules.redundantBackticks, exclude: ["enumNamespaces"])
    }

    func testNoRemoveBackticksAroundTrueProperty() {
        let input = "var type = Foo.`true`"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundTrueProperty() {
        let input = "var type = Foo.`true`"
        let output = "var type = Foo.true"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks, options: options)
    }

    func testRemoveBackticksAroundProperty() {
        let input = "var type = Foo.`bar`"
        let output = "var type = Foo.bar"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundKeywordProperty() {
        let input = "var type = Foo.`default`"
        let output = "var type = Foo.default"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundKeypathProperty() {
        let input = "var type = \\.`bar`"
        let output = "var type = \\.bar"
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundKeypathKeywordProperty() {
        let input = "var type = \\.`default`"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testRemoveBackticksAroundKeypathKeywordPropertyInSwift5() {
        let input = "var type = \\.`default`"
        let output = "var type = \\.default"
        let options = FormatOptions(swiftVersion: "5")
        testFormatting(for: input, output, rule: FormatRules.redundantBackticks, options: options)
    }

    func testNoRemoveBackticksAroundInitPropertyInSwift5() {
        let input = "let foo: Foo = .`init`"
        let options = FormatOptions(swiftVersion: "5")
        testFormatting(for: input, rule: FormatRules.redundantBackticks, options: options)
    }

    func testNoRemoveBackticksAroundAnyProperty() {
        let input = "enum Foo {\n    case `Any`\n}"
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    func testNoRemoveBackticksAroundGetInSubscript() {
        let input = """
        subscript<T>(_ name: String) -> T where T: Equatable {
            `get`(name)
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantBackticks)
    }

    // MARK: - redundantSelf

    // explicitSelf = .remove

    func testSimpleRemoveRedundantSelf() {
        let input = "func foo() { self.bar() }"
        let output = "func foo() { bar() }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideStringInterpolation() {
        let input = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(self.bar)\")\n    }\n}"
        let output = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(bar)\")\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForArgument() {
        let input = "func foo(bar: Int) { self.bar = bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForLocalVariable() {
        let input = "func foo() { var bar = self.bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCommaDelimitedLocalVariables() {
        let input = "func foo() { let foo = self.foo, bar = self.bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCommaDelimitedLocalVariables2() {
        let input = "func foo() {\n    let foo: Foo, bar: Bar\n    foo = self.foo\n    bar = self.bar\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForTupleAssignedVariables() {
        let input = "func foo() { let (foo, bar) = (self.foo, self.bar) }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForTupleAssignedVariablesFollowedByRegularVariable() {
        let input = "func foo() {\n    let (foo, bar) = (self.foo, self.bar), baz = self.baz\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForTupleAssignedVariablesFollowedByRegularLet() {
        let input = "func foo() {\n    let (foo, bar) = (self.foo, self.bar)\n    let baz = self.baz\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf() {
        let input = "func foo() { func bar() { self.bar() } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf2() {
        let input = "func foo() {\n    func bar() {}\n    self.bar()\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveNonRedundantNestedFunctionSelf3() {
        let input = "func foo() { let bar = 5; func bar() { self.bar = bar } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveClosureSelf() {
        let input = "func foo() { bar { self.bar = 5 } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfAfterOptionalReturn() {
        let input = "func foo() -> String? {\n    var index = startIndex\n    if !matching(self[index]) {\n        break\n    }\n    index = self.index(after: index)\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveRequiredSelfInExtensions() {
        let input = "extension Foo {\n    func foo() {\n        var index = 5\n        if true {\n            break\n        }\n        index = self.index(after: index)\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfBeforeInit() {
        let input = "convenience init() { self.init(5) }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideSwitch() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideSwitchWhere() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo where a == b:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo where a == b:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideSwitchWhereAs() {
        let input = "func foo() {\n    switch self.bar {\n    case .foo where a == b as C:\n        self.baz()\n    }\n}"
        let output = "func foo() {\n    switch bar {\n    case .foo where a == b as C:\n        baz()\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInsideClassInit() {
        let input = "class Foo {\n    var bar = 5\n    init() { self.bar = 6 }\n}"
        let output = "class Foo {\n    var bar = 5\n    init() { bar = 6 }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureInsideIf() {
        let input = "if foo { bar { self.baz() } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForErrorInCatch() {
        let input = "do {} catch { self.error = error }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForNewValueInSet() {
        let input = "var foo: Int { set { self.newValue = newValue } get { return 0 } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCustomNewValueInSet() {
        let input = "var foo: Int { set(n00b) { self.n00b = n00b } get { return 0 } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForNewValueInWillSet() {
        let input = "var foo: Int { willSet { self.newValue = newValue } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCustomNewValueInWillSet() {
        let input = "var foo: Int { willSet(n00b) { self.n00b = n00b } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForOldValueInDidSet() {
        let input = "var foo: Int { didSet { self.oldValue = oldValue } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForCustomOldValueInDidSet() {
        let input = "var foo: Int { didSet(oldz) { self.oldz = oldz } }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForIndexVarInFor() {
        let input = "for foo in bar { self.foo = foo }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForKeyValueTupleInFor() {
        let input = "for (foo, bar) in baz { self.foo = foo; self.bar = bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromComputedVar() {
        let input = "var foo: Int { return self.bar }"
        let output = "var foo: Int { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromOptionalComputedVar() {
        let input = "var foo: Int? { return self.bar }"
        let output = "var foo: Int? { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromNamespacedComputedVar() {
        let input = "var foo: Swift.String { return self.bar }"
        let output = "var foo: Swift.String { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromGenericComputedVar() {
        let input = "var foo: Foo<Int> { return self.bar }"
        let output = "var foo: Foo<Int> { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromComputedArrayVar() {
        let input = "var foo: [Int] { return self.bar }"
        let output = "var foo: [Int] { return bar }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromVarSetter() {
        let input = "var foo: Int { didSet { self.bar() } }"
        let output = "var foo: Int { didSet { bar() } }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarClosure() {
        let input = "var foo = { self.bar }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromLazyVar() {
        let input = "lazy var foo = self.bar"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromLazyVar() {
        let input = "lazy var foo = self.bar"
        let output = "lazy var foo = bar"
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoRemoveSelfFromLazyVarImmediatelyAfterOtherVar() {
        let input = """
        var baz = bar
        lazy var foo = self.bar
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromLazyVarImmediatelyAfterOtherVar() {
        let input = """
        var baz = bar
        lazy var foo = self.bar
        """
        let output = """
        var baz = bar
        lazy var foo = bar
        """
        let options = FormatOptions(swiftVersion: "4")
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoRemoveSelfFromLazyVarClosure() {
        let input = "lazy var foo = { self.bar }()"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromLazyVarClosure2() {
        let input = "lazy var foo = { let bar = self.baz }()"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromLazyVarClosure3() {
        let input = "lazy var foo = { [unowned self] in let bar = self.baz }()"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromVarInFuncWithUnusedArgument() {
        let input = "func foo(bar _: Int) { self.baz = 5 }"
        let output = "func foo(bar _: Int) { baz = 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfFromVarMatchingUnusedArgument() {
        let input = "func foo(bar _: Int) { self.bar = 5 }"
        let output = "func foo(bar _: Int) { bar = 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarMatchingRenamedArgument() {
        let input = "func foo(bar baz: Int) { self.baz = baz }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarRedeclaredInSubscope() {
        let input = "func foo() {\n    if quux {\n        let bar = 5\n    }\n    let baz = self.bar\n}"
        let output = "func foo() {\n    if quux {\n        let bar = 5\n    }\n    let baz = bar\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarDeclaredLaterInScope() {
        let input = "func foo() {\n    let bar = self.baz\n    let baz = quux\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfFromVarDeclaredLaterInOuterScope() {
        let input = "func foo() {\n    if quux {\n        let bar = self.baz\n    }\n    let baz = 6\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInWhilePreceededByVarDeclaration() {
        let input = "var index = start\nwhile index < end {\n    index = self.index(after: index)\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInLocalVarPrecededByLocalVarFollowedByIfComma() {
        let input = "func foo() {\n    let bar = Bar()\n    let baz = Baz()\n    self.baz = baz\n    if let bar = bar, bar > 0 {}\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInLocalVarPrecededByIfLetContainingClosure() {
        let input = "func foo() {\n    if let bar = 5 { baz { _ in } }\n    let quux = self.quux\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarCreatedInGuardScope() {
        let input = "func foo() {\n    guard let bar = 5 else {}\n    let baz = self.bar\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfForVarCreatedInIfScope() {
        let input = "func foo() {\n    if let bar = bar {}\n    let baz = self.bar\n}"
        let output = "func foo() {\n    if let bar = bar {}\n    let baz = bar\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarDeclaredInWhileCondition() {
        let input = "while let foo = bar { self.foo = foo }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfForVarNotDeclaredInWhileCondition() {
        let input = "while let foo == bar { self.baz = 5 }"
        let output = "while let foo == bar { baz = 5 }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarDeclaredInSwitchCase() {
        let input = "switch foo {\ncase bar: let baz = self.baz\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfAfterGenericInit() {
        let input = "init(bar: Int) {\n    self = Foo<Bar>()\n    self.bar(bar)\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfInStaticFunction() {
        let input = "struct Foo {\n    static func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "struct Foo {\n    static func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, exclude: ["enumNamespaces"])
    }

    func testRemoveSelfInClassFunctionWithModifiers() {
        let input = "class Foo {\n    class private func foo() {\n        func bar() { self.foo() }\n    }\n}"
        let output = "class Foo {\n    class private func foo() {\n        func bar() { foo() }\n    }\n}"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf,
                       exclude: ["modifierOrder", "specifiers"])
    }

    func testNoRemoveSelfInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { self.foo() }\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarDeclaredAfterRepeatWhile() {
        let input = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        let foo = 6\n        self.foo()\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfForVarInClosureAfterRepeatWhile() {
        let input = "class Foo {\n    let foo = 5\n    func bar() {\n        repeat {} while foo\n        ({ self.foo() })()\n    }\n}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterVar() {
        let input = "var foo: String\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterNamespacedVar() {
        let input = "var foo: Swift.String\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterOptionalVar() {
        let input = "var foo: String?\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterGenericVar() {
        let input = "var foo: Foo<Int>\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureAfterArray() {
        let input = "var foo: [Int]\nbar { self.baz() }"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInExpectFunction() { // Special case to support the Nimble framework
        let input = """
        class FooTests: XCTestCase {
            let foo = 1
            func testFoo() {
                expect(self.foo) == 1
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInExcludedFunction() {
        let input = """
        class Foo {
            let foo = 1
            func testFoo() {
                log(self.foo)
            }
        }
        """
        let options = FormatOptions(selfRequired: ["log"])
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoMistakeProtocolClassModifierForClassFunction() {
        let input = "protocol Foo: class {}\nfunc bar() {}"
        XCTAssertNoThrow(try format(input, rules: [FormatRules.redundantSelf]))
        XCTAssertNoThrow(try format(input, rules: FormatRules.all))
    }

    func testSelfRemovedFromSwitchCaseWhere() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where self.bar.baz:
                    return self.bar
                default:
                    return nil
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where bar.baz:
                    return bar
                default:
                    return nil
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testSwitchCaseLetVarRecognized() {
        let input = """
        switch foo {
        case .bar:
            baz = nil
        case let baz:
            self.baz = baz
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSwitchCaseHoistedLetVarRecognized() {
        let input = """
        switch foo {
        case .bar:
            baz = nil
        case let .foo(baz):
            self.baz = baz
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSwitchCaseWhereMemberNotTreatedAsVar() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar where self.bar.baz:
                    return self.bar
                default:
                    return nil
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInClosureAfterSwitch() {
        let input = """
        switch x {
        default:
            break
        }
        let foo = { y in
            switch y {
            default:
                self.bar()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInClosureInCaseWithWhereClause() {
        let input = """
        switch foo {
        case bar where baz:
            quux = { self.foo }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfRemovedInDidSet() {
        let input = """
        class Foo {
            var bar = false {
                didSet {
                    self.bar = !self.bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInGetter() {
        let input = """
        class Foo {
            var bar: Int {
                return self.bar
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInIfdef() {
        let input = """
        func foo() {
            #if os(macOS)
                let bar = self.bar
            #endif
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfRemovedWhenFollowedBySwitchContainingIfdef() {
        let input = """
        struct Foo {
            func bar() {
                self.method(self.value)
                switch x {
                #if BAZ
                    case .baz:
                        break
                #endif
                default:
                    break
                }
            }
        }
        """
        let output = """
        struct Foo {
            func bar() {
                method(value)
                switch x {
                #if BAZ
                    case .baz:
                        break
                #endif
                default:
                    break
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfRemovedInsideConditionalCase() {
        let input = """
        struct Foo {
            func bar() {
                let method2 = () -> Void
                switch x {
                #if BAZ
                    case .baz:
                        self.method1(self.value)
                #else
                    case .quux:
                        self.method2(self.value)
                #endif
                default:
                    break
                }
            }
        }
        """
        let output = """
        struct Foo {
            func bar() {
                let method2 = () -> Void
                switch x {
                #if BAZ
                    case .baz:
                        method1(value)
                #else
                    case .quux:
                        self.method2(value)
                #endif
                default:
                    break
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfDoesntGetStuckIfNoParensFound() {
        let input = "init<T>_ foo: T {}"
        testFormatting(for: input, rule: FormatRules.redundantSelf,
                       exclude: ["spaceAroundOperators"])
    }

    func testNoRemoveSelfInIfLetSelf() {
        let input = """
        func foo() {
            if let self = self as? Foo {
                self.bar()
            }
            self.bar()
        }
        """
        let output = """
        func foo() {
            if let self = self as? Foo {
                self.bar()
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInIfLetEscapedSelf() {
        let input = """
        func foo() {
            if let `self` = self as? Foo {
                self.bar()
            }
            self.bar()
        }
        """
        let output = """
        func foo() {
            if let `self` = self as? Foo {
                self.bar()
            }
            bar()
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfAfterGuardLetSelf() {
        let input = """
        func foo() {
            guard let self = self as? Foo else {
                return
            }
            self.bar()
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInClosureInIfCondition() {
        let input = """
        class Foo {
            func foo() {
                if bar({ self.baz() }) {}
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfInTrailingClosureInVarAssignment() {
        let input = """
        func broken() {
            var bad = abc {
                self.foo()
                self.bar
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedWhenPropertyIsKeyword() {
        let input = """
        class Foo {
            let `default` = 5
            func foo() {
                print(self.default)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedWhenPropertyIsContextualKeyword() {
        let input = """
        class Foo {
            let `self` = 5
            func foo() {
                print(self.self)
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfRemovedForContextualKeywordThatRequiresNoEscaping() {
        let input = """
        class Foo {
            let get = 5
            func foo() {
                print(self.get)
            }
        }
        """
        let output = """
        class Foo {
            let get = 5
            func foo() {
                print(get)
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveSelfForMemberNamedLazy() {
        let input = "func foo() { self.lazy() }"
        let output = "func foo() { lazy() }"
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveRedundantSelfInArrayLiteral() {
        let input = """
        class Foo {
            func foo() {
                print([self.bar.x, self.bar.y])
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                print([bar.x, bar.y])
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveRedundantSelfInArrayLiteralVar() {
        let input = """
        class Foo {
            func foo() {
                var bars = [self.bar.x, self.bar.y]
                print(bars)
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                var bars = [bar.x, bar.y]
                print(bars)
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRemoveRedundantSelfInGuardLet() {
        let input = """
        class Foo {
            func foo() {
                guard let bar = self.baz else {
                    return
                }
            }
        }
        """
        let output = """
        class Foo {
            func foo() {
                guard let bar = baz else {
                    return
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInClosureInIf() {
        let input = """
        if let foo = bar(baz: { [weak self] in
            guard let self = self else { return }
            _ = self.myVar
        }) {}
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testSelfNotRemovedInDynamicMemberLookup() {
        let input = """
        @dynamicMemberLookup
        struct Foo {
            subscript(dynamicMember foo: String) -> String {
                return foo + "bar"
            }

            func bar() {
                if self.foo == "foobar" {
                    return
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testNoRemoveSelfAfterGuardCaseLetWithExplicitNamespace() {
        let input = """
        class Foo {
            var name: String?

            func bug(element: Something) {
                guard case let Something.a(name) = element
                else { return }
                self.name = name
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfParsingBug() {
        let input = """
        private class Foo {
            mutating func bar() -> Statement? {
                let start = self
                guard case Token.identifier(let name)? = self.popFirst() else {
                    self = start
                    return nil
                }
                return Statement.declaration(name: name)
            }
        }
        """
        let output = """
        private class Foo {
            mutating func bar() -> Statement? {
                let start = self
                guard case Token.identifier(let name)? = popFirst() else {
                    self = start
                    return nil
                }
                return Statement.declaration(name: name)
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf,
                       exclude: ["hoistPatternLet"])
    }

    func testRedundantSelfParsingBug2() {
        let input = """
        extension Foo {
            private enum NonHashableEnum: RawRepresentable {
                case foo
                case bar

                var rawValue: RuntimeTypeTests.TestStruct {
                    return TestStruct(foo: 0)
                }

                init?(rawValue: RuntimeTypeTests.TestStruct) {
                    switch rawValue.foo {
                    case 0:
                        self = .foo
                    case 1:
                        self = .bar
                    default:
                        return nil
                    }
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    // explicitSelf = .insert

    func testInsertSelf() {
        let input = "class Foo {\n    let foo: Int\n    init() { foo = 5 }\n}"
        let output = "class Foo {\n    let foo: Int\n    init() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfAfterReturn() {
        let input = "class Foo {\n    let foo: Int\n    func bar() -> Int { return foo }\n}"
        let output = "class Foo {\n    let foo: Int\n    func bar() -> Int { return self.foo }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfInsideStringInterpolation() {
        let input = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(bar)\")\n    }\n}"
        let output = "class Foo {\n    var bar: String?\n    func baz() {\n        print(\"\\(self.bar)\")\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInterpretGenericTypesAsMembers() {
        let input = "class Foo {\n    let foo: Bar<Int, Int>\n    init() { self.foo = Int(5) }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfForStaticMemberInClassFunction() {
        let input = "class Foo {\n    static var foo: Int\n    class func bar() { foo = 5 }\n}"
        let output = "class Foo {\n    static var foo: Int\n    class func bar() { self.foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForInstanceMemberInClassFunction() {
        let input = "class Foo {\n    var foo: Int\n    class func bar() { foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForStaticMemberInInstanceFunction() {
        let input = "class Foo {\n    static var foo: Int\n    func bar() { foo = 5 }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForShadowedClassMemberInClassFunction() {
        let input = "class Foo {\n    class func foo() {\n        var foo: Int\n        func bar() { foo = 5 }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInForLoopTuple() {
        let input = "class Foo {\n    var bar: Int\n    func foo() { for (bar, baz) in quux {} }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForTupleTypeMembers() {
        let input = "class Foo {\n    var foo: (Int, UIColor) {\n        let bar = UIColor.red\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForArrayElements() {
        let input = "class Foo {\n    var foo = [1, 2, nil]\n    func bar() { baz(nil) }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForNestedVarReference() {
        let input = "class Foo {\n    func bar() {\n        var bar = 5\n        repeat { bar = 6 } while true\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInSwitchCaseLet() {
        let input = "class Foo {\n    var foo: Bar? {\n        switch bar {\n        case let .baz(foo, _):\n            return nil\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInFuncAfterImportedClass() {
        let input = "import class Foo.Bar\nfunc foo() {\n    var bar = 5\n    if true {\n        bar = 6\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForSubscriptGetSet() {
        let input = "class Foo {\n    func get() {}\n    func set() {}\n    subscript(key: String) -> String {\n        get { return get(key) }\n        set { set(key, newValue) }\n    }\n}"
        let output = "class Foo {\n    func get() {}\n    func set() {}\n    subscript(key: String) -> String {\n        get { return self.get(key) }\n        set { self.set(key, newValue) }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInIfCaseLet() {
        let input = "enum Foo {\n    case bar(Int)\n    var value: Int? {\n        if case let .bar(value) = self { return value }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForPatternLet() {
        let input = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForPatternLet2() {
        let input = "class Foo {\n    func foo() {}\n    func bar() {\n        switch x {\n        case let .foo(baz): print(baz)\n        case .bar(let foo, var bar): print(foo + bar)\n        }\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForTypeOf() {
        let input = "class Foo {\n    var type: String?\n    func bar() {\n        print(\"\\(type(of: self))\")\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForConditionalLocal() {
        let input = "class Foo {\n    func foo() {\n        #if os(watchOS)\n            var foo: Int\n        #else\n            var foo: Float\n        #endif\n        print(foo)\n    }\n}"
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfInExtension() {
        let input = """
        struct Foo {
            var bar = 5
        }

        extension Foo {
            func baz() {
                bar = 6
            }
        }
        """
        let output = """
        struct Foo {
            var bar = 5
        }

        extension Foo {
            func baz() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testGlobalAfterTypeNotTreatedAsMember() {
        let input = """
        struct Foo {
            var foo = 1
        }

        var bar = 5

        extension Foo {
            func baz() {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testForWhereVarNotTreatedAsMember() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                for bar in self where bar.baz {
                    return bar
                }
                return nil
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSwitchCaseWhereVarNotTreatedAsMember() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar where bar.baz:
                    return bar
                default:
                    return nil
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSwitchCaseVarDoesntLeak() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let bar:
                    return bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInSwitchCaseLet() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo:
                    return self.bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInSwitchCaseWhere() {
        let input = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where bar.baz:
                    return bar
                default:
                    return bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar: Bar
            var bazziestBar: Bar? {
                switch x {
                case let foo where self.bar.baz:
                    return self.bar
                default:
                    return self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInDidSet() {
        let input = """
        class Foo {
            var bar = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """
        let output = """
        class Foo {
            var bar = false {
                didSet {
                    self.bar = !self.bar
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedAfterLet() {
        let input = """
        struct Foo {
            let foo = "foo"
            func bar() {
                let x = foo
                baz(x)
            }

            func baz(_: String) {}
        }
        """
        let output = """
        struct Foo {
            let foo = "foo"
            func bar() {
                let x = self.foo
                self.baz(x)
            }

            func baz(_: String) {}
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfNotInsertedInParameterNames() {
        let input = """
        class Foo {
            let a: String

            func bar() {
                foo(a: a)
            }
        }
        """
        let output = """
        class Foo {
            let a: String

            func bar() {
                foo(a: self.a)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfNotInsertedInCaseLet() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                if case let .some(a) = self.a, case var .some(b) = self.b {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfNotInsertedInCaseLet2() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func baz() {
                if case let .foos(a, b) = foo, case let .bars(a, b) = bar {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInTupleAssignment() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                (a, b) = ("foo", "bar")
            }
        }
        """
        let output = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                (self.a, self.b) = ("foo", "bar")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfNotInsertedInTupleAssignment() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            func bar() {
                let (a, b) = (self.a, self.b)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfForMemberNamedLazy() {
        let input = """
        class Foo {
            var lazy = "foo"
            func foo() {
                print(lazy)
            }
        }
        """
        let output = """
        class Foo {
            var lazy = "foo"
            func foo() {
                print(self.lazy)
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForVarDefinedInIfCaseLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                if case let .c(localVar) = self.d, localVar == .e {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForVarDefinedInUnhoistedIfCaseLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                if case .c(let localVar) = self.d, localVar == .e {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options,
                       exclude: ["hoistPatternLet"])
    }

    func testNoInsertSelfForVarDefinedInFor() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                for localVar in 0 ..< 6 where localVar < 5 {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfForVarDefinedInWhileLet() {
        let input = """
        struct A {
            var localVar = ""

            var B: String {
                while let localVar = self.localVar, localVar < 5 {
                    print(localVar)
                }
            }
        }
        """
        let options = FormatOptions(explicitSelf: .insert)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    // explicitSelf = .initOnly

    func testPreserveSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testRemoveSelfIfNotInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            func baz() {
                self.bar = 6
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            func baz() {
                bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testInsertSelfInsideClassInit() {
        let input = """
        class Foo {
            var bar = 5
            init() {
                bar = 6
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            init() {
                self.bar = 6
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testNoInsertSelfInsideClassInitIfNotLvalue() {
        let input = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                bar = baz
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testRemoveSelfInsideClassInitIfNotLvalue() {
        let input = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = self.baz
            }
        }
        """
        let output = """
        class Foo {
            var bar = 5
            let baz = 6
            init() {
                self.bar = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfDotTypeInsideClassInitEdgeCase() {
        let input = """
        class Foo {
            let type: Int

            init() {
                self.type = 5
            }

            func baz() {
                switch type {}
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedInTupleInInit() {
        let input = """
        class Foo {
            let a: String?
            let b: String

            init() {
                (a, b) = ("foo", "bar")
            }
        }
        """
        let output = """
        class Foo {
            let a: String?
            let b: String

            init() {
                (self.a, self.b) = ("foo", "bar")
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testSelfInsertedAfterLetInInit() {
        let input = """
        class Foo {
            var foo: String
            init(bar: Bar) {
                let baz = bar.quux
                foo = baz
            }
        }
        """
        let output = """
        class Foo {
            var foo: String
            init(bar: Bar) {
                let baz = bar.quux
                self.foo = baz
            }
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, output, rule: FormatRules.redundantSelf, options: options)
    }

    func testRedundantSelfWithStaticMethodAfterForLoop() {
        let input = """
        struct Foo {
            init() {
                for foo in self.bar {}
            }

            static func foo() {}
        }

        """
        let output = """
        struct Foo {
            init() {
                for foo in bar {}
            }

            static func foo() {}
        }

        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfWithStaticMethodAfterForWhereLoop() {
        let input = """
        struct Foo {
            init() {
                for foo in self.bar where !bar.isEmpty {}
            }

            static func foo() {}
        }

        """
        let output = """
        struct Foo {
            init() {
                for foo in bar where !bar.isEmpty {}
            }

            static func foo() {}
        }

        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfRuleDoesntErrorInForInTryLoop() {
        let input = "for foo in try bar() {}"
        testFormatting(for: input, rule: FormatRules.redundantSelf)
    }

    func testRedundantSelfRuleDoesntErrorForStaticFuncInProtocolWithWhere() {
        let input = """
        protocol Foo where Self: Bar {
            static func baz() -> Self
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testRedundantSelfRuleDoesntErrorForStaticFuncInStructWithWhere() {
        let input = """
        struct Foo<T> where T: Bar {
            static func baz() -> Foo {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    func testRedundantSelfRuleDoesntErrorForClassFuncInClassWithWhere() {
        let input = """
        class Foo<T> where T: Bar {
            class func baz() -> Foo {}
        }
        """
        let options = FormatOptions(explicitSelf: .initOnly)
        testFormatting(for: input, rule: FormatRules.redundantSelf, options: options)
    }

    // enable/disable

    func testDisableRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable redundantSelf
                self.bar = 1
                // swiftformat:enable redundantSelf
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable redundantSelf
                self.bar = 1
                // swiftformat:enable redundantSelf
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testDisableNextRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable:next redundantSelf
                self.bar = 1
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                // swiftformat:disable:next redundantSelf
                self.bar = 1
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testMultilineDisableRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable redundantSelf */ self.bar = 1 /* swiftformat:enable all */
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable redundantSelf */ self.bar = 1 /* swiftformat:enable all */
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    func testMultilineDisableNextRemoveSelf() {
        let input = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable:next redundantSelf */
                self.bar = 1
                self.bar = 2
            }
        }
        """
        let output = """
        class Foo {
            var bar: Int
            func baz() {
                /* swiftformat:disable:next redundantSelf */
                self.bar = 1
                bar = 2
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.redundantSelf)
    }

    // MARK: - semicolons

    func testSemicolonRemovedAtEndOfLine() {
        let input = "print(\"hello\");\n"
        let output = "print(\"hello\")\n"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    func testSemicolonRemovedAtStartOfLine() {
        let input = "\n;print(\"hello\")"
        let output = "\nprint(\"hello\")"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    func testSemicolonRemovedAtEndOfProgram() {
        let input = "print(\"hello\");"
        let output = "print(\"hello\")"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    func testSemicolonRemovedAtStartOfProgram() {
        let input = ";print(\"hello\")"
        let output = "print(\"hello\")"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    func testIgnoreInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        testFormatting(for: input, rule: FormatRules.semicolons, options: options)
    }

    func testReplaceInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\")\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: false)
        testFormatting(for: input, output, rule: FormatRules.semicolons, options: options)
    }

    func testReplaceSemicolonFollowedByComment() {
        let input = "print(\"hello\"); // comment\nprint(\"goodbye\")"
        let output = "print(\"hello\") // comment\nprint(\"goodbye\")"
        let options = FormatOptions(allowInlineSemicolons: true)
        testFormatting(for: input, output, rule: FormatRules.semicolons, options: options)
    }

    func testSemicolonsNotReplacedInForLoop() {
        let input = "for (i = 0; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        testFormatting(for: input, rule: FormatRules.semicolons, options: options)
    }

    func testSemicolonsNotReplacedInForLoopContainingComment() {
        let input = "for (i = 0 // comment\n    ; i < 5; i++)"
        let options = FormatOptions(allowInlineSemicolons: false)
        testFormatting(for: input, rule: FormatRules.semicolons, options: options,
                       exclude: ["leadingDelimiters"])
    }

    func testSemicolonNotReplacedAfterReturn() {
        let input = "return;\nfoo()"
        testFormatting(for: input, rule: FormatRules.semicolons)
    }

    func testSemicolonReplacedAfterReturnIfEndOfScope() {
        let input = "do { return; }"
        let output = "do { return }"
        testFormatting(for: input, output, rule: FormatRules.semicolons)
    }

    // MARK: - duplicateImports

    func testRemoveDuplicateImport() {
        let input = "import Foundation\nimport Foundation"
        let output = "import Foundation"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testRemoveDuplicateConditionalImport() {
        let input = "#if os(iOS)\n    import Foo\n    import Foo\n#else\n    import Bar\n    import Bar\n#endif"
        let output = "#if os(iOS)\n    import Foo\n#else\n    import Bar\n#endif"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveOverlappingImports() {
        let input = "import MyModule\nimport MyModule.Private"
        testFormatting(for: input, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveCaseDifferingImports() {
        let input = "import Auth0.Authentication\nimport Auth0.authentication"
        testFormatting(for: input, rule: FormatRules.duplicateImports)
    }

    func testRemoveDuplicateImportFunc() {
        let input = "import func Foo.bar\nimport func Foo.bar"
        let output = "import func Foo.bar"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport() {
        let input = "import Foo\n@testable import Foo"
        let output = "\n@testable import Foo"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport2() {
        let input = "@testable import Foo\nimport Foo"
        let output = "@testable import Foo"
        testFormatting(for: input, output, rule: FormatRules.duplicateImports)
    }

    // MARK: - unusedArguments

    // closures

    func testUnusedTypedClosureArguments() {
        let input = "let foo = { (bar: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { (_: Int, baz: String) in\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedUntypedClosureArguments() {
        let input = "let foo = { bar, baz in\n    print(\"Hello \\(baz)\")\n}"
        let output = "let foo = { _, baz in\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureReturnType() {
        let input = "let foo = { () -> Foo.Bar in baz() }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureThrows() {
        let input = "let foo = { () throws in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureGenericReturnTypes() {
        let input = "let foo = { () -> Promise<String> in bar }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureTupleReturnTypes() {
        let input = "let foo = { () -> (Int, Int) in (5, 6) }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveClosureGenericArgumentTypes() {
        let input = "let foo = { (_: Foo<Bar, Baz>) in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testNoRemoveFunctionNameBeforeForLoop() {
        let input = "{\n    func foo() -> Int {}\n    for a in b {}\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testClosureTypeInClosureArgumentsIsNotMangled() {
        let input = "{ (foo: (Int) -> Void) in }"
        let output = "{ (_: (Int) -> Void) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedUnnamedClosureArguments() {
        let input = "{ (_ foo: Int, _ bar: Int) in }"
        let output = "{ (_: Int, _: Int) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInoutClosureArgumentsNotMangled() {
        let input = "{ (foo: inout Foo, bar: inout Bar) in }"
        let output = "{ (_: inout Foo, _: inout Bar) in }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMalformedFunctionNotMisidentifiedAsClosure() {
        let input = "func foo() { bar(5) {} in }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    // functions

    func testMarkUnusedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInNonVoidFunction() {
        let input = "func foo(bar: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        let output = "func foo(bar _: Int, baz: String) -> (A<B, C>, D & E, [F: G]) { return baz.quux }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInThrowsFunction() {
        let input = "func foo(bar: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        let output = "func foo(bar _: Int, baz: String) throws {\n    print(\"Hello \\(baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedArgumentsInOptionalReturningFunction() {
        let input = "func foo(bar: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        let output = "func foo(bar _: Int, baz: String) -> String? {\n    return \"Hello \\(baz)\"\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoMarkUnusedArgumentsInProtocolFunction() {
        let input = "protocol Foo {\n    func foo(bar: Int) -> Int\n    var bar: Int { get }\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testUnusedUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInoutFunctionArgumentIsNotMangled() {
        let input = "func foo(_ foo: inout Foo) {}"
        let output = "func foo(_: inout Foo) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedInternallyRenamedFunctionArgument() {
        let input = "func foo(foo bar: Int) {}"
        let output = "func foo(foo _: Int) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testNoMarkProtocolFunctionArgument() {
        let input = "func foo(foo bar: Int)\nvar bar: Bool { get }"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testMembersAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        let output = "func foo(bar: Int, baz _: String) {\n    print(\"Hello \\(bar.baz)\")\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testLabelsAreNotArguments() {
        let input = "func foo(bar: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        let output = "func foo(bar _: Int, baz: String) {\n    bar: while true { print(baz) }\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testDictionaryLiteralsRuinEverything() {
        let input = "func foo(bar: Int, baz: Int) {\n    let quux = [bar: 1, baz: 2]\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testOperatorArgumentsAreUnnamed() {
        let input = "func == (lhs: Int, rhs: Int) { return false }"
        let output = "func == (_: Int, _: Int) { return false }"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testUnusedtFailableInitArgumentsAreNotMangled() {
        let input = "init?(foo: Bar) {}"
        let output = "init?(foo _: Bar) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testTreatEscapedArgumentsAsUsed() {
        let input = "func foo(default: Int) -> Int {\n    return `default`\n}"
        testFormatting(for: input, rule: FormatRules.unusedArguments)
    }

    func testPartiallyMarkedUnusedArguments() {
        let input = "func foo(bar: Bar, baz _: Baz) {}"
        let output = "func foo(bar _: Bar, baz _: Baz) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testPartiallyMarkedUnusedArguments2() {
        let input = "func foo(bar _: Bar, baz: Baz) {}"
        let output = "func foo(bar _: Bar, baz _: Baz) {}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    // functions (closure-only)

    func testNoMarkFunctionArgument() {
        let input = "func foo(_ bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .closureOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    // functions (unnamed-only)

    func testNoMarkNamedFunctionArgument() {
        let input = "func foo(bar: Int, baz: String) {\n    print(\"Hello \\(baz)\")\n}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    func testRemoveUnnamedFunctionArgument() {
        let input = "func foo(_ foo: Int) {}"
        let output = "func foo(_: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, output, rule: FormatRules.unusedArguments, options: options)
    }

    func testNoRemoveInternalFunctionArgumentName() {
        let input = "func foo(foo bar: Int) {}"
        let options = FormatOptions(stripUnusedArguments: .unnamedOnly)
        testFormatting(for: input, rule: FormatRules.unusedArguments, options: options)
    }

    // init

    func testMarkUnusedInitArgument() {
        let input = "init(bar: Int, baz: String) {\n    self.baz = baz\n}"
        let output = "init(bar _: Int, baz: String) {\n    self.baz = baz\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    // subscript

    func testMarkUnusedSubscriptArgument() {
        let input = "subscript(foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedUnnamedSubscriptArgument() {
        let input = "subscript(_ foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(_: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }

    func testMarkUnusedNamedSubscriptArgument() {
        let input = "subscript(foo foo: Int, baz: String) -> String {\n    return get(baz)\n}"
        let output = "subscript(foo _: Int, baz: String) -> String {\n    return get(baz)\n}"
        testFormatting(for: input, output, rule: FormatRules.unusedArguments)
    }
}
