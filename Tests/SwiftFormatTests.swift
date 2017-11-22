//
//  SwiftFormatTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 28/08/2016.
//  Copyright 2016 Nick Lockwood
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

import SwiftFormat
import XCTest

class SwiftFormatTests: XCTestCase {

    // MARK: enumerateFiles

    func testInputFileMatchesOutputFileForNilOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file)
        let errors = enumerateFiles(withInputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            XCTAssertEqual(inputURL, URL(fileURLWithPath: #file))
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 1)
    }

    func testInputFileMatchesOutputFileForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file)
        let errors = enumerateFiles(withInputURL: inputURL, outputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            XCTAssertEqual(inputURL, URL(fileURLWithPath: #file))
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 1)
    }

    func testInputFilesMatchOutputFilesForNilOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 22)
    }

    func testInputFilesMatchOutputFilesForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURL: inputURL, outputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 22)
    }

    func testInputFileNotEnumeratedWhenExcluded() {
        var files = [URL]()
        let currentFile = URL(fileURLWithPath: #file)
        let excludedURLs = [currentFile.deletingLastPathComponent()]
        let inputURL = currentFile.deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURL: inputURL, excluding: excludedURLs, outputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 15)
    }

    // MARK: format function

    func testFormatReturnsInputWithNoRules() {
        let input = "foo ()  "
        let output = "foo ()  "
        XCTAssertEqual(try format(input, rules: []), output)
    }

    func testFormatUsesDefaultRulesIfNoneSpecified() {
        let input = "foo ()  "
        let output = "foo()\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: fragments

    func testFormattingFailsForFragment() {
        let input = "foo () {"
        XCTAssertThrowsError(try format(input, rules: [])) {
            XCTAssertEqual("\($0)", "unexpected end of file at 1:8")
        }
    }

    func testFormattingSucceedsForFragmentWithOption() {
        let input = "foo () {"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [], options: options), input)
    }

    // MARK: conflict markers

    func testFormattingFailsForConflict() {
        let input = "foo () {\n<<<<<< old\n    bar()\n======\n    baz()\n>>>>>> new\n}"
        XCTAssertThrowsError(try format(input, rules: [])) {
            XCTAssertEqual("\($0)", "found conflict marker <<<<<< at 2:0")
        }
    }

    func testFormattingSucceedsForConflictWithOption() {
        let input = "foo () {\n<<<<<< old\n    bar()\n======\n    baz()\n>>>>>> new\n}"
        let options = FormatOptions(ignoreConflictMarkers: true)
        XCTAssertEqual(try format(input, rules: [], options: options), input)
    }

    // MARK: offsetForToken

    func testOffsetForToken() {
        let source = "// a comment\n    let foo = 5\n"
        let tokens = tokenize(source)
        let (line, column) = offsetForToken(at: 7, in: tokens)
        XCTAssertEqual(line, 2)
        XCTAssertEqual(column, 8)
    }
}
