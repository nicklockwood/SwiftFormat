//
//  SwiftFormatTests.swift
//  SwiftFormat
//
//  Version 0.8.2
//
//  Created by Nick Lockwood on 28/08/2016.
//  Copyright 2016 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import XCTest
@testable import SwiftFormat

class SwiftFormatTests: XCTestCase {

    // MARK: format function

    func testFormatReturnsInputWithNoRules() {
        let input = "foo ()  "
        let output = "foo ()  "
        XCTAssertEqual(format(input, rules: []), output)
    }

    func testFormatUsesDefaultRulesIfNoneSpecified() {
        let input = "foo ()  "
        let output = "foo()\n"
        XCTAssertEqual(format(input), output)
    }

    // MARK: arg preprocessor

    func testPreprocessArguments() {
        let input = ["", "foo", "-o", "bar", "-i", "4", "-l", "cr", "-s", "inline"]
        let output = ["0": "", "1": "foo", "output": "bar", "indent": "4", "linebreaks": "cr", "semicolons": "inline"]
        XCTAssertEqual(preprocessArguments(input, [
            "output",
            "indent",
            "linebreaks",
            "semicolons",
        ])!, output)
    }

    func testPathWithSpaces() {
        let input = ["", "foo\\", "bar\\", "baz"]
        let output = ["0": "", "1": "foo bar baz"]
        XCTAssertEqual(preprocessArguments(input, [])!, output)
    }

    func testPathInQuotes() {
        let input = ["", "\"foo", "bar", "baz\""]
        let output = ["0": "", "1": "foo bar baz"]
        XCTAssertEqual(preprocessArguments(input, [])!, output)
    }

    func testEscapedQuotesInPath() {
        let input = ["", "\"\\\"foo", "bar", "baz\\\"\""]
        let output = ["0": "", "1": "\"foo bar baz\""]
        XCTAssertEqual(preprocessArguments(input, [])!, output)
    }

    func testEscapedBackslashInPath() {
        let input = ["", "\"\\\\foo", "bar", "baz\\\\\""]
        let output = ["0": "", "1": "\\foo bar baz\\"]
        XCTAssertEqual(preprocessArguments(input, [])!, output)
    }

    func testSinglePartInQuotes() {
        let input = ["", "\"foobar\""]
        let output = ["0": "", "1": "foobar"]
        XCTAssertEqual(preprocessArguments(input, [])!, output)
    }

    func testEscapedQuotesInSinglePartPath() {
        let input = ["", "\"\\\"foobar\\\"\""]
        let output = ["0": "", "1": "\"foobar\""]
        XCTAssertEqual(preprocessArguments(input, [])!, output)
    }

    // MARK: performance

    func testPerformance() {
        let inputPath = ((#file as NSString).stringByDeletingLastPathComponent
            as NSString).stringByDeletingLastPathComponent
        let outputPath = NSTemporaryDirectory()
        self.measureBlock {
            processInput(NSURL(fileURLWithPath: inputPath),
                andWriteToOutput: NSURL(fileURLWithPath: outputPath),
                withOptions: FormatOptions())
        }
    }
}
