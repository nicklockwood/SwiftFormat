//
//  RedundantInitTests.swift
//  SwiftFormatTests
//
//  Created by Alejandro Martínez on 6/19/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantInitTests: XCTestCase {
    func testRemoveRedundantInit() {
        let input = "[1].flatMap { String.init($0) }"
        let output = "[1].flatMap { String($0) }"
        testFormatting(for: input, output, rule: .redundantInit)
    }

    func testRemoveRedundantInit2() {
        let input = "[String.self].map { Type in Type.init(foo: 1) }"
        let output = "[String.self].map { Type in Type(foo: 1) }"
        testFormatting(for: input, output, rule: .redundantInit)
    }

    func testRemoveRedundantInit3() {
        let input = "String.init(\"text\")"
        let output = "String(\"text\")"
        testFormatting(for: input, output, rule: .redundantInit)
    }

    func testDontRemoveInitInSuperCall() {
        let input = "class C: NSObject { override init() { super.init() } }"
        testFormatting(for: input, rule: .redundantInit)
    }

    func testDontRemoveInitInSelfCall() {
        let input = "struct S { let n: Int }; extension S { init() { self.init(n: 1) } }"
        testFormatting(for: input, rule: .redundantInit)
    }

    func testDontRemoveInitWhenPassedAsFunction() {
        let input = "[1].flatMap(String.init)"
        testFormatting(for: input, rule: .redundantInit)
    }

    func testDontRemoveInitWhenUsedOnMetatype() {
        let input = "[String.self].map { type in type.init(1) }"
        testFormatting(for: input, rule: .redundantInit)
    }

    func testDontRemoveInitWhenUsedOnImplicitClosureMetatype() {
        let input = "[String.self].map { $0.init(1) }"
        testFormatting(for: input, rule: .redundantInit)
    }

    func testDontRemoveInitWhenUsedOnPossibleMetatype() {
        let input = "let something = Foo.bar.init()"
        testFormatting(for: input, rule: .redundantInit)
    }

    func testDontRemoveInitWithExplicitSignature() {
        let input = "[String.self].map(Foo.init(bar:))"
        testFormatting(for: input, rule: .redundantInit)
    }

    func testRemoveInitWithOpenParenOnFollowingLine() {
        let input = """
        var foo: Foo {
            Foo.init
            (
                bar: bar,
                baaz: baaz
            )
        }
        """
        let output = """
        var foo: Foo {
            Foo(
                bar: bar,
                baaz: baaz
            )
        }
        """
        testFormatting(for: input, output, rule: .redundantInit)
    }

    func testNoRemoveInitWithOpenParenOnFollowingLineAfterComment() {
        let input = """
        var foo: Foo {
            Foo.init // foo
            (
                bar: bar,
                baaz: baaz
            )
        }
        """
        testFormatting(for: input, rule: .redundantInit)
    }

    func testNoRemoveInitForLowercaseType() {
        let input = """
        let foo = bar.init()
        """
        testFormatting(for: input, rule: .redundantInit)
    }

    func testNoRemoveInitForLocalLetType() {
        let input = """
        let Foo = Foo.self
        let foo = Foo.init()
        """
        testFormatting(for: input, rule: .redundantInit, exclude: [.propertyTypes])
    }

    func testNoRemoveInitForLocalLetType2() {
        let input = """
        let Foo = Foo.self
        if x {
            return Foo.init(x)
        } else {
            return Foo.init(y)
        }
        """
        testFormatting(for: input, rule: .redundantInit)
    }

    func testNoRemoveInitInsideIfdef() {
        let input = """
        func myFunc() async throws -> String {
            #if DEBUG
            .init("foo")
            #else
            ""
            #endif
        }
        """
        testFormatting(for: input, rule: .redundantInit, exclude: [.indent])
    }

    func testNoRemoveInitInsideIfdef2() {
        let input = """
        func myFunc() async throws(Foo) -> String {
            #if DEBUG
            .init("foo")
            #else
            ""
            #endif
        }
        """
        testFormatting(for: input, rule: .redundantInit, exclude: [.indent])
    }

    func testRemoveInitAfterCollectionLiterals() {
        let input = """
        let array = [String].init()
        let arrayElement = [String].Element.init()
        let nestedArray = [[String]].init()
        let tupleArray = [(key: String, value: Int)].init()
        let dictionary = [String: Int].init()
        """
        let output = """
        let array = [String]()
        let arrayElement = [String].Element()
        let nestedArray = [[String]]()
        let tupleArray = [(key: String, value: Int)]()
        let dictionary = [String: Int]()
        """
        testFormatting(for: input, output, rule: .redundantInit, exclude: [.propertyTypes])
    }

    func testPreservesInitAfterTypeOfCall() {
        let input = """
        type(of: oldViewController).init()
        """

        testFormatting(for: input, rule: .redundantInit)
    }

    func testRemoveInitAfterOptionalType() {
        let input = """
        let someOptional = String?.init("Foo")
        // (String!.init("Foo") isn't valid Swift code, so we don't test for it)
        """
        let output = """
        let someOptional = String?("Foo")
        // (String!.init("Foo") isn't valid Swift code, so we don't test for it)
        """

        testFormatting(for: input, output, rule: .redundantInit, exclude: [.propertyTypes])
    }

    func testPreservesTryBeforeInit() {
        let input = """
        let throwing: Foo = try .init()
        let throwingOptional1: Foo = try? .init()
        let throwingOptional2: Foo = try! .init()
        """

        testFormatting(for: input, rule: .redundantInit)
    }

    func testRemoveInitAfterGenericType() {
        let input = """
        let array = Array<String>.init()
        let dictionary = Dictionary<String, Int>.init()
        let atomicDictionary = Atomic<[String: Int]>.init()
        """
        let output = """
        let array = Array<String>()
        let dictionary = Dictionary<String, Int>()
        let atomicDictionary = Atomic<[String: Int]>()
        """

        testFormatting(for: input, output, rule: .redundantInit, exclude: [.typeSugar, .propertyTypes])
    }

    func testPreserveNonRedundantInitInTernaryOperator() {
        let input = """
        let bar: Bar = (foo.isBar && bar.isBaaz) ? .init() : nil
        """
        testFormatting(for: input, rule: .redundantInit)
    }
}
