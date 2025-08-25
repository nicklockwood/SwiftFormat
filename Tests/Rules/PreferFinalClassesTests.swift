//
//  PreferFinalClassesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 2025-08-25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class PreferFinalClassesTests: XCTestCase {
    func testBasicClassMadesFinal() {
        let input = """
        class Foo {}
        """
        let output = """
        final class Foo {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testPublicClassMadesFinal() {
        let input = """
        public class Bar {}
        """
        let output = """
        public final class Bar {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testPrivateClassMadesFinal() {
        let input = """
        private class Baz {}
        """
        let output = """
        private final class Baz {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testInternalClassMadesFinal() {
        let input = """
        internal class Qux {}
        """
        let output = """
        internal final class Qux {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.redundantInternal])
    }

    func testOpenClassLeftUnchanged() {
        let input = """
        open class OpenClass {}
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    func testAlreadyFinalClassLeftUnchanged() {
        let input = """
        final class FinalClass {}
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    func testPublicFinalClassLeftUnchanged() {
        let input = """
        public final class PublicFinalClass {}
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    func testPublicOpenClassLeftUnchanged() {
        let input = """
        public open class PublicOpenClass {}
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    func testClassFunctionNotAffected() {
        let input = """
        struct Foo {
            class func bar() {}
        }
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    func testClassVariableNotAffected() {
        let input = """
        struct Foo {
            class var bar: String { "bar" }
        }
        """
        testFormatting(for: input, rule: .preferFinalClasses)
    }

    func testNestedClass() {
        let input = """
        class OuterClass {
            class InnerClass {}
        }
        """
        let output = """
        final class OuterClass {
            final class InnerClass {}
        }
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.enumNamespaces])
    }

    func testClassWithInheritance() {
        let input = """
        class Child: Parent {}
        """
        let output = """
        final class Child: Parent {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testClassWithProtocolConformance() {
        let input = """
        class MyClass: SomeProtocol {}
        """
        let output = """
        final class MyClass: SomeProtocol {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testClassWithMultipleModifiers() {
        let input = """
        @objc public class MyClass {}
        """
        let output = """
        @objc public final class MyClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testMultipleClasses() {
        let input = """
        class FirstClass {}
        class SecondClass {}
        open class ThirdClass {}
        final class FourthClass {}
        """
        let output = """
        final class FirstClass {}
        final class SecondClass {}
        open class ThirdClass {}
        final class FourthClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testClassWithComments() {
        let input = """
        // This is a class
        class MyClass {
            // Some content
        }
        """
        let output = """
        // This is a class
        final class MyClass {
            // Some content
        }
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.docComments])
    }

    func testClassWithSubclassNotMadeFinal() {
        let input = """
        class BaseClass {}
        class SubClass: BaseClass {}
        """
        let output = """
        class BaseClass {}
        final class SubClass: BaseClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testMultipleInheritanceLevels() {
        let input = """
        class GrandParent {}
        class Parent: GrandParent {}
        class Child: Parent {}
        """
        let output = """
        class GrandParent {}
        class Parent: GrandParent {}
        final class Child: Parent {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testClassWithProtocolConformanceStillMadeFinal() {
        let input = """
        protocol SomeProtocol {}
        class MyClass: SomeProtocol {}
        """
        let output = """
        protocol SomeProtocol {}
        final class MyClass: SomeProtocol {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testClassInheritingFromExternalClassMadeFinal() {
        let input = """
        class MyViewController: UIViewController {}
        """
        let output = """
        final class MyViewController: UIViewController {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testMixedScenario() {
        let input = """
        class BaseClass {}
        final class AlreadyFinalClass {}
        open class OpenClass {}
        class SubClass: BaseClass {}
        class IndependentClass {}
        """
        let output = """
        class BaseClass {}
        final class AlreadyFinalClass {}
        open class OpenClass {}
        final class SubClass: BaseClass {}
        final class IndependentClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testGenericClassWithSubclass() {
        let input = """
        class Container<T> {}
        class StringContainer: Container<String> {}
        """
        let output = """
        class Container<T> {}
        final class StringContainer: Container<String> {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testGenericClassWithGenericSubclass() {
        let input = """
        class BaseContainer<T> {}
        class SpecialContainer<U>: BaseContainer<U> {}
        """
        let output = """
        class BaseContainer<T> {}
        final class SpecialContainer<U>: BaseContainer<U> {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testMultipleGenericParameters() {
        let input = """
        class GenericClass<T, U> {}
        class ConcreteClass: GenericClass<String, Int> {}
        """
        let output = """
        class GenericClass<T, U> {}
        final class ConcreteClass: GenericClass<String, Int> {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testComplexGenericInheritanceChain() {
        let input = """
        class BaseContainer<T> {}
        class MiddleContainer<T>: BaseContainer<T> {}
        class FinalContainer: MiddleContainer<String> {}
        """
        let output = """
        class BaseContainer<T> {}
        class MiddleContainer<T>: BaseContainer<T> {}
        final class FinalContainer: MiddleContainer<String> {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testBaseClassNotMadeFinal() {
        let input = """
        class BaseClass {}
        class ClassBase {}
        class SomeBase {}
        class BaseSomething {}
        class ViewControllerBase {}
        class RegularClass {}
        """
        let output = """
        class BaseClass {}
        class ClassBase {}
        class SomeBase {}
        class BaseSomething {}
        class ViewControllerBase {}
        final class RegularClass {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testConvertOpenMembersToPublic() {
        let input = """
        public class MyClass {
            open var property1: String = ""
            open let property2: Int = 0
            open func method1() {}
            private var privateProperty: String = ""
            public func publicMethod() {}
        }
        """
        let output = """
        public final class MyClass {
            public var property1: String = ""
            public let property2: Int = 0
            public func method1() {}
            private var privateProperty: String = ""
            public func publicMethod() {}
        }
        """
        testFormatting(for: input, output, rule: .preferFinalClasses)
    }

    func testNestedClassWithOpenMembersNotConverted() {
        let input = """
        public class OuterClass {
            open var outerProperty: String = ""

            public class InnerClass {
                open var innerProperty: String = ""
            }
        }
        """
        let output = """
        public final class OuterClass {
            public var outerProperty: String = ""

            public final class InnerClass {
                public var innerProperty: String = ""
            }
        }
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.enumNamespaces])
    }

    func testMixedScenarioWithBaseAndOpen() {
        let input = """
        class BaseController {}
        public class MyController {
            open var title: String = ""
            open func setup() {}
        }
        class UtilityBase {}
        """
        let output = """
        class BaseController {}
        public final class MyController {
            public var title: String = ""
            public func setup() {}
        }
        class UtilityBase {}
        """
        testFormatting(for: input, output, rule: .preferFinalClasses, exclude: [.blankLinesBetweenScopes])
    }
}
