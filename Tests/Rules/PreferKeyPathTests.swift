//
//  PreferKeyPathTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 7/29/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class PreferKeyPathTests: XCTestCase {
    func testMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map { $0.foo }
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testCompactMapPropertyToKeyPath() {
        let input = """
        let foo = bar.compactMap { $0.foo }
        """
        let output = """
        let foo = bar.compactMap(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testFlatMapPropertyToKeyPath() {
        let input = """
        let foo = bar.flatMap { $0.foo }
        """
        let output = """
        let foo = bar.flatMap(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testMapNestedPropertyWithSpacesToKeyPath() {
        let input = """
        let foo = bar.map { $0 . foo . bar }
        """
        let output = """
        let foo = bar.map(\\ . foo . bar)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options, exclude: [.spaceAroundOperators])
    }

    func testMultilineMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map {
            $0.foo
        }
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testParenthesizedMapPropertyToKeyPath() {
        let input = """
        let foo = bar.map({ $0.foo })
        """
        let output = """
        let foo = bar.map(\\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath,
                       options: options)
    }

    func testNoMapSelfToKeyPath() {
        let input = """
        let foo = bar.map { $0 }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForSwiftLessThan5_2() {
        let input = """
        let foo = bar.map { $0.foo }
        """
        let options = FormatOptions(swiftVersion: "5.1")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForFunctionCalls() {
        let input = """
        let foo = bar.map { $0.foo() }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForCompoundExpressions() {
        let input = """
        let foo = bar.map { $0.foo || baz }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForOptionalChaining() {
        let input = """
        let foo = bar.map { $0?.foo }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testNoMapPropertyToKeyPathForTrailingContains() {
        let input = """
        let foo = bar.contains { $0.foo }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testMapPropertyToKeyPathForContainsWhere() {
        let input = """
        let foo = bar.contains(where: { $0.foo })
        """
        let output = """
        let foo = bar.contains(where: \\.foo)
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, output, rule: .preferKeyPath, options: options)
    }

    func testMultipleTrailingClosuresNotConvertedToKeyPath() {
        let input = """
        foo.map { $0.bar } reverse: { $0.bar }
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testSelfNotConvertedToKeyPathBeforeSwift6() {
        // https://bugs.swift.org/browse/SR-12897
        let input = """
        let foo = bar.compactMap { $0 }
        """
        let options = FormatOptions(swiftVersion: "5.10")
        testFormatting(for: input, rule: .preferKeyPath, options: options)
    }

    func testSelfConvertedToKeyPath() {
        let input = """
        let foo = bar.compactMap { $0 }
        """
        let output = """
        let foo = bar.compactMap(\\.self)
        """
        let options = FormatOptions(swiftVersion: "6")
        testFormatting(for: input, output, rule: .preferKeyPath, options: options)
    }
}
