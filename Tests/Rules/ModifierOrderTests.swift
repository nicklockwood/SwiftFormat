//
//  ModifierOrderTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 7/28/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class ModifierOrderTests: XCTestCase {
    func testVarModifiersCorrected() {
        let input = """
        unowned private static var foo
        """
        let output = """
        private unowned static var foo
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .modifierOrder, options: options)
    }

    func testPrivateSetModifierNotMangled() {
        let input = """
        private(set) public weak lazy var foo
        """
        let output = """
        public private(set) lazy weak var foo
        """
        testFormatting(for: input, output, rule: .modifierOrder)
    }

    func testUnownedUnsafeModifierNotMangled() {
        let input = """
        unowned(unsafe) lazy var foo
        """
        let output = """
        lazy unowned(unsafe) var foo
        """
        testFormatting(for: input, output, rule: .modifierOrder)
    }

    func testPrivateRequiredStaticFuncModifiers() {
        let input = """
        required static private func foo()
        """
        let output = """
        private required static func foo()
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .modifierOrder, options: options)
    }

    func testPrivateConvenienceInit() {
        let input = """
        convenience private init()
        """
        let output = """
        private convenience init()
        """
        testFormatting(for: input, output, rule: .modifierOrder)
    }

    func testSpaceInModifiersLeftIntact() {
        let input = """
        weak private(set) /* read-only */
        public var
        """
        let output = """
        public private(set) /* read-only */
        weak var
        """
        testFormatting(for: input, output, rule: .modifierOrder)
    }

    func testSpaceInModifiersLeftIntact2() {
        let input = """
        nonisolated(unsafe) public var foo: String
        """
        let output = """
        public nonisolated(unsafe) var foo: String
        """
        testFormatting(for: input, output, rule: .modifierOrder)
    }

    func testPrefixModifier() {
        let input = """
        prefix public static func - (rhs: Foo) -> Foo
        """
        let output = """
        public static prefix func - (rhs: Foo) -> Foo
        """
        let options = FormatOptions(fragment: true)
        testFormatting(for: input, output, rule: .modifierOrder, options: options)
    }

    func testModifierOrder() {
        let input = """
        override public var foo: Int { 5 }
        """
        let output = """
        public override var foo: Int { 5 }
        """
        let options = FormatOptions(modifierOrder: ["public", "override"])
        testFormatting(for: input, output, rule: .modifierOrder, options: options)
    }

    func testConsumingModifierOrder() {
        let input = """
        consuming public func close()
        """
        let output = """
        public consuming func close()
        """
        let options = FormatOptions(modifierOrder: ["public", "consuming"])
        testFormatting(for: input, output, rule: .modifierOrder, options: options, exclude: [.noExplicitOwnership])
    }

    func testNoConfusePostfixIdentifierWithKeyword() {
        let input = """
        var foo = .postfix
        override init() {}
        """
        testFormatting(for: input, rule: .modifierOrder)
    }

    func testNoConfusePostfixIdentifierWithKeyword2() {
        let input = """
        var foo = postfix
        override init() {}
        """
        testFormatting(for: input, rule: .modifierOrder)
    }

    func testNoConfuseCaseWithModifier() {
        let input = """
        public enum Foo {
            case strong
            case weak
            public init() {}
        }
        """
        testFormatting(for: input, rule: .modifierOrder)
    }
}
