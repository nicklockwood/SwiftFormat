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

import XCTest
@testable import SwiftFormat

class SwiftFormatTests: XCTestCase {

    // MARK: enumerateSwiftFiles

    func testInputFileMatchesOutputFileForNilOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file)
        enumerateSwiftFiles(withInputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            XCTAssertEqual(inputURL, URL(fileURLWithPath: #file))
            files.append(inputURL)
        }
        XCTAssertEqual(files.count, 1)
    }

    func testInputFileMatchesOutputFileForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file)
        enumerateSwiftFiles(withInputURL: inputURL, outputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            XCTAssertEqual(inputURL, URL(fileURLWithPath: #file))
            files.append(inputURL)
        }
        XCTAssertEqual(files.count, 1)
    }

    func testInputFilesMatchOutputFilesForNilOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        enumerateSwiftFiles(withInputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            files.append(inputURL)
        }
        XCTAssertEqual(files.count, 19)
    }

    func testInputFilesMatchOutputFilesForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        enumerateSwiftFiles(withInputURL: inputURL, outputURL: inputURL) { inputURL, outputURL in
            XCTAssertEqual(inputURL, outputURL)
            files.append(inputURL)
        }
        XCTAssertEqual(files.count, 19)
    }

    // MARK: format function

    func testFormatReturnsInputWithNoRules() {
        let input = "foo ()  "
        let output = "foo ()  "
        XCTAssertEqual(try! format(input, rules: []), output)
    }

    func testFormatUsesDefaultRulesIfNoneSpecified() {
        let input = "foo ()  "
        let output = "foo()\n"
        XCTAssertEqual(try! format(input), output)
    }

    // MARK: arg preprocessor

    func testPreprocessArguments() {
        let input = ["", "foo", "-o", "bar", "-i", "4", "-l", "cr", "-s", "inline"]
        let output = (files: ["", "foo"], options: ["output": "bar", "indent": "4", "linebreaks": "cr", "semicolons": "inline"])
        let preprocessedArgs = preprocessArguments(input, [
            "output",
            "indent",
            "linebreaks",
            "semicolons",
        ])!
        XCTAssertEqual(output.files, preprocessedArgs.files)
        XCTAssertEqual(output.options, preprocessedArgs.options)
    }
}
