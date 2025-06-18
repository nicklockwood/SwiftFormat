//
//  RedundantPublicTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 5/30/2025.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantPublicTests: XCTestCase {
    func testRemovesPublicFromPropertyInInternalStruct() {
        let input = """
        struct Foo {
            public let bar: Bar
        }
        """
        let output = """
        struct Foo {
            let bar: Bar
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic])
    }

    func testRemovesPublicFromMethodInInternalClass() {
        let input = """
        class Example {
            public func doSomething() {}
        }
        """
        let output = """
        class Example {
            func doSomething() {}
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic])
    }

    func testRemovesPublicFromMultipleDeclarationsInInternalType() {
        let input = """
        struct Container {
            public let value: Int
            public var name: String
            public func calculate() -> Int { 42 }
            public init(value: Int, name: String) {
                self.value = value
                self.name = name
            }
        }
        """
        let output = """
        struct Container {
            let value: Int
            var name: String
            func calculate() -> Int { 42 }
            init(value: Int, name: String) {
                self.value = value
                self.name = name
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic], exclude: [.redundantMemberwiseInit])
    }

    func testDoesNotRemovePublicFromPublicType() {
        let input = """
        public struct PublicStruct {
            public let value: String
            public func getValue() -> String { value }
        }
        """
        testFormatting(for: input, rules: [.redundantPublic])
    }

    func testRemovesPublicFromExplicitlyInternalType() {
        let input = """
        internal struct InternalStruct {
            public var count: Int
            public func increment() { count += 1 }
        }
        """
        let output = """
        internal struct InternalStruct {
            var count: Int
            func increment() { count += 1 }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic], exclude: [.redundantInternal])
    }

    func testDoesNotRemovePublicFromPrivateType() {
        let input = """
        private struct PrivateStruct {
            public let value: String
        }
        """
        testFormatting(for: input, rules: [.redundantPublic])
    }

    func testDoesNotRemovePublicFromFileprivateType() {
        let input = """
        fileprivate class Helper {
            public func help() {}
        }
        """
        testFormatting(for: input, rules: [.redundantPublic], exclude: [.redundantFileprivate])
    }

    func testRemovesPublicFromNestedTypeInInternalParent() {
        let input = """
        struct Outer {
            struct Inner {
                public var value: Int
            }
        }
        """
        let output = """
        struct Outer {
            struct Inner {
                var value: Int
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic], exclude: [.enumNamespaces])
    }

    func testPreservesPublicInExtension() {
        let input = """
        extension Array {
            public var isNotEmpty: Bool { !isEmpty }
        }
        """
        testFormatting(for: input, rules: [.redundantPublic])
    }

    func testPreservesPublicInTypeInPublicExtension() {
        let input = """
        public extension Foo {
            struct Bar {
                public var baaz: Baaz
            }
        }
        """
        testFormatting(for: input, rules: [.redundantPublic])
    }

    func testRemovesPublicInExtensionOfInternalTypeInSameFile() {
        let input = """
        struct InternalType {}

        extension InternalType {
            public func foo() {}
            public func bar() {}

            #if DEBUG
                public func baaz() {}
            #endif
        }
        """

        let output = """
        struct InternalType {}

        extension InternalType {
            func foo() {}
            func bar() {}

            #if DEBUG
                func baaz() {}
            #endif
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic])
    }

    func testRemovesPublicInExtensionOfNestedInternalType() {
        let input = """
        enum OuterType {
            public struct InnerType {
                let num: Int
            }
        }

        extension OuterType.InnerType {
            public func calculate() -> Int { num * 2 }
        }
        """

        let output = """
        enum OuterType {
            struct InnerType {
                let num: Int
            }
        }

        extension OuterType.InnerType {
            func calculate() -> Int { num * 2 }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic])
    }

    func testRemovesPublicInTypeInExtension() {
        let input = """
        extension Foo {
            struct Bar {
                public var baaz: Int
            }
        }
        """

        let output = """
        extension Foo {
            struct Bar {
                var baaz: Int
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic])
    }

    func testRemovesPublicFromEnumCasesInInternalEnum() {
        let input = """
        enum State {
            public static let initialValue = 0
            case idle
            case loading
        }
        """
        let output = """
        enum State {
            static let initialValue = 0
            case idle
            case loading
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic])
    }

    func testHandlesConditionalCompilation() {
        let input = """
        struct Container {
            #if DEBUG
            public let debugValue: String
            #else
            public let releaseValue: String
            #endif
        }
        """
        let output = """
        struct Container {
            #if DEBUG
            let debugValue: String
            #else
            let releaseValue: String
            #endif
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic], exclude: [.indent])
    }

    func testPreservesInternalModifierWhenRemovingPublic() {
        let input = """
        struct Foo {
            public internal(set) var value: Int
        }
        """
        let output = """
        struct Foo {
            internal(set) var value: Int
        }
        """
        testFormatting(for: input, [output], rules: [.redundantPublic])
    }

    func testPreservesPublicInConditionalCompilationInsideExtension() {
        let input = """
        extension Foo {
            #if DEBUG
                public var publicProperty: Int { 10 }

            #if OTHER_CONDITION
                public var otherPublicProperty: Int { 10 }
            #endif
            #endif
        }
        """
        testFormatting(for: input, rules: [.redundantPublic], exclude: [.indent])
    }

    func testPreservesPublicInNestedTypeInsidePublicExtension() {
        let input = """
        public extension Foo {
            struct Bar {
                private var foo: Int
                private let bar: Int

                public var foobar: (Int, Int) {
                    (foo, bar)
                }

                public init(foo: Int, bar: Int) {
                    self.foo = foo
                    self.bar = bar
                }
            }
        }
        """
        testFormatting(for: input, rules: [.redundantPublic])
    }

    func testPreservesPublicInProtocolExtension() {
        // A method in an extenison of an internal protocol may actually be publically accessible
        // via some public type that implements the protocol.
        let input = """
        protocol Foo {}

        extension Foo {
            public func bar() {}
        }
        """
        testFormatting(for: input, rules: [.redundantPublic])
    }
}
