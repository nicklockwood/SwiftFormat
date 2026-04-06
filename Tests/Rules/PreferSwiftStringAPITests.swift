//
//  PreferSwiftStringAPITests.swift
//  SwiftFormatTests
//
//  Created by Sutheesh Sukumaran on 05/04/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftFormat

final class PreferSwiftStringAPITests: XCTestCase {
    func testReplacingOccurrences() {
        let input = """
        str.replacingOccurrences(of: "foo", with: "bar")
        """

        let output = """
        str.replacing("foo", with: "bar")
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .preferSwiftStringAPI, options: options)
    }

    func testReplacingOccurrencesOnOptionalChain() {
        let input = """
        str?.replacingOccurrences(of: "foo", with: "bar")
        """

        let output = """
        str?.replacing("foo", with: "bar")
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .preferSwiftStringAPI, options: options)
    }

    func testReplacingOccurrencesMultiline() {
        let input = """
        str.replacingOccurrences(
            of: "foo",
            with: "bar"
        )
        """

        let output = """
        str.replacing(
            "foo",
            with: "bar"
        )
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, output, rule: .preferSwiftStringAPI, options: options)
    }

    func testReplacingOccurrencesNotTransformedBeforeSwift5_7() {
        let input = """
        str.replacingOccurrences(of: "foo", with: "bar")
        """

        let options = FormatOptions(swiftVersion: "5.6")
        testFormatting(for: input, rule: .preferSwiftStringAPI, options: options)
    }

    func testReplacingOccurrencesWithOptionsNotTransformed() {
        let input = """
        str.replacingOccurrences(of: "foo", with: "bar", options: [.caseInsensitive])
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .preferSwiftStringAPI, options: options)
    }

    func testReplacingOccurrencesWithRangeNotTransformed() {
        let input = """
        str.replacingOccurrences(of: "foo", with: "bar", options: [], range: str.startIndex...)
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .preferSwiftStringAPI, options: options)
    }

    func testReplacingOccurrencesNotTransformedWhenNoVersionSet() {
        let input = """
        str.replacingOccurrences(of: "foo", with: "bar")
        """

        testFormatting(for: input, rule: .preferSwiftStringAPI)
    }

    func testFreestandingReplacingOccurrencesNotTransformed() {
        let input = """
        replacingOccurrences(of: "foo", with: "bar")
        """

        let options = FormatOptions(swiftVersion: "5.7")
        testFormatting(for: input, rule: .preferSwiftStringAPI, options: options)
    }
}
