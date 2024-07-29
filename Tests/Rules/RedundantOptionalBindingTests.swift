//
//  RedundantOptionalBindingTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 8/1/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantOptionalBindingTests: XCTestCase {
    func testRemovesRedundantOptionalBindingsInSwift5_7() {
        let input = """
        if let foo = foo {
            print(foo)
        }

        else if var bar = bar {
            print(bar)
        }

        guard let self = self else {
            return
        }

        while var quux = quux {
            break
        }
        """

        let output = """
        if let foo {
            print(foo)
        }

        else if var bar {
            print(bar)
        }

        guard let self else {
            return
        }

        while var quux {
            break
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options, exclude: [.elseOnSameLine])
    }

    func testRemovesMultipleOptionalBindings() {
        let input = """
        if let foo = foo, let bar = bar, let baaz = baaz {
            print(foo, bar, baaz)
        }

        guard let foo = foo, let bar = bar, let baaz = baaz else {
            return
        }
        """

        let output = """
        if let foo, let bar, let baaz {
            print(foo, bar, baaz)
        }

        guard let foo, let bar, let baaz else {
            return
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testRemovesMultipleOptionalBindingsOnSeparateLines() {
        let input = """
        if
          let foo = foo,
          let bar = bar,
          let baaz = baaz
        {
          print(foo, bar, baaz)
        }

        guard
          let foo = foo,
          let bar = bar,
          let baaz = baaz
        else {
          return
        }
        """

        let output = """
        if
          let foo,
          let bar,
          let baaz
        {
          print(foo, bar, baaz)
        }

        guard
          let foo,
          let bar,
          let baaz
        else {
          return
        }
        """

        let options = FormatOptions(indent: "  ", swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .redundantOptionalBinding, options: options)
    }

    func testKeepsRedundantOptionalBeforeSwift5_7() {
        let input = """
        if let foo = foo {
            print(foo)
        }
        """

        let options = FormatOptions(swiftVersion: "5.6")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
    }

    func testKeepsNonRedundantOptional() {
        let input = """
        if let foo = bar {
            print(foo)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
    }

    func testKeepsOptionalNotEligibleForShorthand() {
        let input = """
        if let foo = self.foo, let bar = bar(), let baaz = baaz[0] {
            print(foo, bar, baaz)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options, exclude: [.redundantSelf])
    }

    func testRedundantSelfAndRedundantOptionalTogether() {
        let input = """
        if let foo = self.foo {
            print(foo)
        }
        """

        let output = """
        if let foo {
            print(foo)
        }
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, [output], rules: [.redundantOptionalBinding, .redundantSelf], options: options)
    }

    func testDoesntRemoveShadowingOutsideOfOptionalBinding() {
        let input = """
        let foo = foo

        if let bar = baaz({
            let foo = foo
            print(foo)
        }) {}
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .redundantOptionalBinding, options: options)
    }
}
