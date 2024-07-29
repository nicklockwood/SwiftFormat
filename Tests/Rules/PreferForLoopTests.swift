//
//  PreferForLoopTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class PreferForLoopTests: XCTestCase {
    func testConvertSimpleForEachToForLoop() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach { string in
            print(string)
        }

        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach { (string: String) in
            print(string)
        }
        """

        let output = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        for string in placeholderStrings {
            print(string)
        }

        let placeholderStrings = ["foo", "bar", "baaz"]
        for string in placeholderStrings {
            print(string)
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testConvertAnonymousForEachToForLoop() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach {
            print($0)
        }

        potatoes.forEach({ $0.bake() })
        """

        let output = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        for placeholderString in placeholderStrings {
            print(placeholderString)
        }

        potatoes.forEach({ $0.bake() })
        """

        testFormatting(for: input, output, rule: .preferForLoop, exclude: [.trailingClosures])
    }

    func testNoConvertAnonymousForEachToForLoop() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach {
            print($0)
        }

        potatoes.forEach({ $0.bake() })
        """

        let options = FormatOptions(preserveAnonymousForEach: true, preserveSingleLineForEach: false)
        testFormatting(for: input, rule: .preferForLoop, options: options, exclude: [.trailingClosures])
    }

    func testConvertSingleLineForEachToForLoop() {
        let input = "potatoes.forEach({ item in item.bake() })"
        let output = "for item in potatoes { item.bake() }"

        let options = FormatOptions(preserveSingleLineForEach: false)
        testFormatting(for: input, output, rule: .preferForLoop, options: options,
                       exclude: [.wrapLoopBodies])
    }

    func testConvertSingleLineAnonymousForEachToForLoop() {
        let input = "potatoes.forEach({ $0.bake() })"
        let output = "for potato in potatoes { potato.bake() }"

        let options = FormatOptions(preserveSingleLineForEach: false)
        testFormatting(for: input, output, rule: .preferForLoop, options: options,
                       exclude: [.wrapLoopBodies])
    }

    func testConvertNestedForEach() {
        let input = """
        let nestedArrays = [[1, 2], [3, 4]]
        nestedArrays.forEach {
            $0.forEach {
                $0.forEach {
                    print($0)
                }
            }
        }
        """

        let output = """
        let nestedArrays = [[1, 2], [3, 4]]
        for nestedArray in nestedArrays {
            for item in nestedArray {
                for item in item {
                    print(item)
                }
            }
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testDefaultNameAlreadyUsedInLoopBody() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach {
            let placeholderString = $0.uppercased()
            print(placeholderString, $0)
        }
        """

        let output = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        for item in placeholderStrings {
            let placeholderString = item.uppercased()
            print(placeholderString, item)
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testIgnoreLoopsWithCaptureListForNow() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach { [someCapturedValue = fooBar] in
            print($0, someCapturedValue)
        }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    func testRemoveAllPrefixFromLoopIdentifier() {
        let input = """
        allWindows.forEach {
            print($0)
        }
        """

        let output = """
        for window in allWindows {
            print(window)
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testConvertsReturnToContinue() {
        let input = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        placeholderStrings.forEach {
            func capitalize(_ value: String) -> String {
                return value.uppercased()
            }

            if $0 == "foo" {
                return
            } else {
                print(capitalize($0))
            }
        }
        """

        let output = """
        let placeholderStrings = ["foo", "bar", "baaz"]
        for placeholderString in placeholderStrings {
            func capitalize(_ value: String) -> String {
                return value.uppercased()
            }

            if placeholderString == "foo" {
                continue
            } else {
                print(capitalize(placeholderString))
            }
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testHandlesForEachOnChainedProperties() {
        let input = """
        let bar = foo.bar
        bar.baaz.quux.strings.forEach {
            print($0)
        }
        """

        let output = """
        let bar = foo.bar
        for string in bar.baaz.quux.strings {
            print(string)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testHandlesForEachOnFunctionCallResult() {
        let input = """
        let bar = foo.bar
        foo.item().bar[2].baazValues(option: true).forEach {
            print($0)
        }
        """

        let output = """
        let bar = foo.bar
        for baazValue in foo.item().bar[2].baazValues(option: true) {
            print(baazValue)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testHandlesForEachOnSubscriptResult() {
        let input = """
        let bar = foo.bar
        foo.item().bar[2].dictionary["myValue"].forEach {
            print($0)
        }
        """

        let output = """
        let bar = foo.bar
        for item in foo.item().bar[2].dictionary["myValue"] {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testHandlesForEachOnArrayLiteral() {
        let input = """
        let quux = foo.bar.baaz.quux
        ["foo", "bar", "baaz", quux].forEach {
            print($0)
        }
        """

        let output = """
        let quux = foo.bar.baaz.quux
        for item in ["foo", "bar", "baaz", quux] {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testHandlesForEachOnCurriedFunctionWithSubscript() {
        let input = """
        let quux = foo.bar.baaz.quux
        foo(bar)(baaz)["item"].forEach {
            print($0)
        }
        """

        let output = """
        let quux = foo.bar.baaz.quux
        for item in foo(bar)(baaz)["item"] {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testHandlesForEachOnArrayLiteralInParens() {
        let input = """
        let quux = foo.bar.baaz.quux
        (["foo", "bar", "baaz", quux]).forEach {
            print($0)
        }
        """

        let output = """
        let quux = foo.bar.baaz.quux
        for item in (["foo", "bar", "baaz", quux]) {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop, exclude: [.redundantParens])
    }

    func testPreservesForEachAfterMultilineChain() {
        let input = """
        placeholderStrings
            .filter { $0.style == .fooBar }
            .map { $0.uppercased() }
            .forEach { print($0) }

        placeholderStrings
            .filter({ $0.style == .fooBar })
            .map({ $0.uppercased() })
            .forEach({ print($0) })
        """
        testFormatting(for: input, rule: .preferForLoop, exclude: [.trailingClosures])
    }

    func testPreservesChainWithClosure() {
        let input = """
        // Converting this to a for loop would result in unusual looking syntax like
        // `for string in strings.map { $0.uppercased() } { print($0) }`
        // which causes a warning to be emitted: "trailing closure in this context is
        // confusable with the body of the statement; pass as a parenthesized argument
        // to silence this warning".
        strings.map { $0.uppercased() }.forEach { print($0) }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    func testForLoopVariableNotUsedIfClashesWithKeyword() {
        let input = """
        Foo.allCases.forEach {
            print($0)
        }
        """
        let output = """
        for item in Foo.allCases {
            print(item)
        }
        """
        testFormatting(for: input, output, rule: .preferForLoop)
    }

    func testTryNotRemovedInThrowingForEach() {
        let input = """
        try list().forEach {
            print($0)
        }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    func testOptionalTryNotRemovedInThrowingForEach() {
        let input = """
        try? list().forEach {
            print($0)
        }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    func testAwaitNotRemovedInAsyncForEach() {
        let input = """
        await list().forEach {
            print($0)
        }
        """
        testFormatting(for: input, rule: .preferForLoop)
    }

    func testForEachOverDictionary() {
        let input = """
        let dict = ["a": "b"]

        dict.forEach { (header: (key: String, value: String)) in
            print(header.key)
            print(header.value)
        }
        """

        let output = """
        let dict = ["a": "b"]

        for header in dict {
            print(header.key)
            print(header.value)
        }
        """

        testFormatting(for: input, output, rule: .preferForLoop)
    }
}
