//
//  SemicolonsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/24/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SemicolonsTests: XCTestCase {
    func testSemicolonRemovedAtEndOfLine() {
        let input = "print(\"hello\");\n"
        let output = "print(\"hello\")\n"
        testFormatting(for: input, output, rule: .semicolons)
    }

    func testSemicolonRemovedAtStartOfLine() {
        let input = "\n;print(\"hello\")"
        let output = "\nprint(\"hello\")"
        testFormatting(for: input, output, rule: .semicolons)
    }

    func testSemicolonRemovedAtEndOfProgram() {
        let input = "print(\"hello\");"
        let output = "print(\"hello\")"
        testFormatting(for: input, output, rule: .semicolons)
    }

    func testSemicolonRemovedAtStartOfProgram() {
        let input = ";print(\"hello\")"
        let output = "print(\"hello\")"
        testFormatting(for: input, output, rule: .semicolons)
    }

    func testIgnoreInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let options = FormatOptions(semicolons: .inlineOnly)
        testFormatting(for: input, rule: .semicolons, options: options)
    }

    func testReplaceInlineSemicolon() {
        let input = "print(\"hello\"); print(\"goodbye\")"
        let output = "print(\"hello\")\nprint(\"goodbye\")"
        let options = FormatOptions(semicolons: .never)
        testFormatting(for: input, output, rule: .semicolons, options: options)
    }

    func testReplaceSemicolonFollowedByComment() {
        let input = "print(\"hello\"); // comment\nprint(\"goodbye\")"
        let output = "print(\"hello\") // comment\nprint(\"goodbye\")"
        let options = FormatOptions(semicolons: .inlineOnly)
        testFormatting(for: input, output, rule: .semicolons, options: options)
    }

    func testSemicolonNotReplacedAfterReturn() {
        let input = "return;\nfoo()"
        testFormatting(for: input, rule: .semicolons)
    }

    func testSemicolonReplacedAfterReturnIfEndOfScope() {
        let input = "do { return; }"
        let output = "do { return }"
        testFormatting(for: input, output, rule: .semicolons)
    }

    func testRequiredSemicolonNotRemovedAfterInferredVar() {
        let input = """
        func foo() {
            @Environment(\\.colorScheme) var colorScheme;
            print(colorScheme)
        }
        """
        testFormatting(for: input, rule: .semicolons)
    }
}
