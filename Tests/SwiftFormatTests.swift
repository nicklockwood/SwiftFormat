//
//  SwiftFormatTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 28/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
@testable import SwiftFormat

class SwiftFormatTests: XCTestCase {
    // MARK: enumerateFiles

    func testInputFileMatchesOutputFileForNilOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file)
        let errors = enumerateFiles(withInputURL: inputURL) { inputURL, outputURL, _ in
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
        let errors = enumerateFiles(withInputURL: inputURL, outputURL: inputURL) { inputURL, outputURL, _ in
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
        let errors = enumerateFiles(withInputURL: inputURL) { inputURL, outputURL, _ in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 71)
    }

    func testInputFilesMatchOutputFilesForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURL: inputURL, outputURL: inputURL) { inputURL, outputURL, _ in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 71)
    }

    func testInputFileNotEnumeratedWhenExcluded() {
        var files = [URL]()
        let currentFile = URL(fileURLWithPath: #file)
        let options = Options(fileOptions: FileOptions(excludedGlobs: [
            Glob.path(currentFile.deletingLastPathComponent().path),
        ]))
        let inputURL = currentFile.deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURL: inputURL, outputURL: inputURL, options: options) { inputURL, outputURL, _ in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 45)
    }

    // MARK: format function

    func testFormatReturnsInputWithNoRules() {
        let input = "foo ()  "
        XCTAssertEqual(try format(input, rules: []), input)
    }

    func testFormatUsesDefaultRulesIfNoneSpecified() {
        let input = "foo ()  "
        let output = "foo()\n"
        XCTAssertEqual(try format(input), output)
    }

    // MARK: lint function

    func testLintReturnsNoChangesWithNoRules() {
        let input = "foo ()  "
        XCTAssertEqual(try lint(input, rules: []), [])
    }

    func testLintWithDefaultRules() {
        let input = "foo ()  "
        XCTAssertEqual(try lint(input), [
            .init(line: 1, rule: FormatRules.linebreakAtEndOfFile, filePath: nil),
            .init(line: 1, rule: FormatRules.spaceAroundParens, filePath: nil),
            .init(line: 1, rule: FormatRules.trailingSpace, filePath: nil),
        ])
    }

    func testLintConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n"
        XCTAssertEqual(try lint(input), [
            .init(line: 2, rule: FormatRules.consecutiveBlankLines, filePath: nil),
        ])
    }

    // MARK: fragments

    func testFormattingFailsForFragment() {
        let input = "foo () {"
        XCTAssertThrowsError(try format(input, rules: [])) {
            XCTAssertEqual("\($0)", "Unexpected end of file at 1:9")
        }
    }

    func testFormattingSucceedsForFragmentWithOption() {
        let input = "foo () {"
        let options = FormatOptions(fragment: true)
        XCTAssertEqual(try format(input, rules: [], options: options), input)
    }

    // MARK: format line range

    func testFormattingRange() {
        let input = """
        let  badlySpaced1:Int   = 5
        let   badlySpaced2:Int=5
        let   badlySpaced3 : Int = 5
        """
        let output = """
        let  badlySpaced1:Int   = 5
        let badlySpaced2: Int = 5
        let   badlySpaced3 : Int = 5
        """
        XCTAssertEqual(try format(input, lineRange: 2 ... 2), output)
    }

    func testFormattingRangeNoCrash() {
        let input = """
        func foo() {
          if bar {
            print(  "foo")
          }
        }
        """
        XCTAssertNoThrow(try format(input, lineRange: 3 ... 4))
    }

    // MARK: conflict markers

    func testFormattingFailsForConflict() {
        let input = "foo () {\n<<<<<< old\n    bar()\n======\n    baz()\n>>>>>> new\n}"
        XCTAssertThrowsError(try format(input, rules: [])) {
            XCTAssertEqual("\($0)", "Found conflict marker <<<<<< at 2:1")
        }
    }

    func testFormattingSucceedsForConflictWithOption() {
        let input = "foo () {\n<<<<<< old\n    bar()\n======\n    baz()\n>>>>>> new\n}"
        let options = FormatOptions(ignoreConflictMarkers: true)
        XCTAssertEqual(try format(input, rules: [], options: options), input)
    }

    // MARK: empty file

    func testNoTimeoutForEmptyFile() {
        let input = ""
        XCTAssertEqual(try format(input), input)
    }

    // MARK: offsetForToken

    func testOffsetForToken() {
        let tokens = tokenize("// a comment\n    let foo = 5\n")
        let offset = offsetForToken(at: 7, in: tokens, tabWidth: 1)
        XCTAssertEqual(offset, SourceOffset(line: 2, column: 9))
    }

    func testOffsetForTokenWithTabs() {
        let tokens = tokenize("// a comment\n\tlet foo = 5\n")
        let offset = offsetForToken(at: 7, in: tokens, tabWidth: 2)
        XCTAssertEqual(offset, SourceOffset(line: 2, column: 7))
    }

    // MARK: tokenIndex for offset

    func testTokenIndexForOffset() {
        let tokens = tokenize("// a comment\n    let foo = 5\n")
        let offset = SourceOffset(line: 2, column: 9)
        XCTAssertEqual(tokenIndex(for: offset, in: tokens, tabWidth: 1), 7)
    }

    func testTokenIndexForOffsetWithTabs() {
        let tokens = tokenize("// a comment\n\tlet foo = 5\n")
        let offset = SourceOffset(line: 2, column: 7)
        XCTAssertEqual(tokenIndex(for: offset, in: tokens, tabWidth: 2), 7)
    }

    func testTokenIndexForLastLine() {
        let tokens = tokenize("""
        let foo = 5
        let bar = 6
        """)
        let offset = SourceOffset(line: 2, column: 0)
        XCTAssertEqual(tokenIndex(for: offset, in: tokens, tabWidth: 1), 8)
    }

    func testTokenIndexPastEndOfFile() {
        let tokens = tokenize("""
        let foo = 5
        let bar = 6
        """)
        let offset = SourceOffset(line: 3, column: 0)
        XCTAssertEqual(tokenIndex(for: offset, in: tokens, tabWidth: 1), 15)
    }

    func testTokenIndexForBlankLastLine() {
        let tokens = tokenize("""
        let foo = 5
        let bar = 6

        """)
        let offset = SourceOffset(line: 3, column: 0)
        XCTAssertEqual(tokenIndex(for: offset, in: tokens, tabWidth: 1), 16)
    }

    // MARK: tokenRange

    func testTokenRange() {
        let tokens = tokenize("// a comment\n    let foo = 5\n")
        XCTAssertEqual(tokenRange(forLineRange: 1 ... 1, in: tokens), 0 ..< 4)
    }

    // MARK: newOffset

    func testNewOffsetsForUnchangedPosition() {
        let tokens = tokenize("foo\nbar\nbaz")
        let offset1 = SourceOffset(line: 1, column: 1)
        let offset2 = SourceOffset(line: 2, column: 1)
        let offset3 = SourceOffset(line: 3, column: 1)
        XCTAssertEqual(newOffset(for: offset1, in: tokens, tabWidth: 1), offset1)
        XCTAssertEqual(newOffset(for: offset2, in: tokens, tabWidth: 1), offset2)
        XCTAssertEqual(newOffset(for: offset3, in: tokens, tabWidth: 1), offset3)
    }

    func testNewOffsetsForRemovedLine() throws {
        let input = tokenize("foo\nbar\n\n\nbaz\nquux")
        let offset1 = SourceOffset(line: 1, column: 1)
        let offset2 = SourceOffset(line: 2, column: 1)
        let offset3 = SourceOffset(line: 5, column: 1)
        let offset4 = SourceOffset(line: 6, column: 1)
        let output = try format(input, rules: [FormatRules.consecutiveBlankLines])
        let expected3 = SourceOffset(line: 4, column: 1)
        let expected4 = SourceOffset(line: 5, column: 1)
        XCTAssertEqual(newOffset(for: offset1, in: output, tabWidth: 1), offset1)
        XCTAssertEqual(newOffset(for: offset2, in: output, tabWidth: 1), offset2)
        XCTAssertEqual(newOffset(for: offset3, in: output, tabWidth: 1), expected3)
        XCTAssertEqual(newOffset(for: offset4, in: output, tabWidth: 1), expected4)
    }

    func testNewOffsetsForEmptyOutput() {
        let offset = SourceOffset(line: 1, column: 1)
        XCTAssertEqual(newOffset(for: offset, in: [], tabWidth: 1), offset)
    }

    // MARK: expand path

    func testExpandPathWithRelativePath() {
        XCTAssertEqual(
            expandPath("relpath/to/file.swift", in: "/dir").path,
            "/dir/relpath/to/file.swift"
        )
    }

    func testExpandPathWithFullPath() {
        XCTAssertEqual(
            expandPath("/full/path/to/file.swift", in: "/dir").path,
            "/full/path/to/file.swift"
        )
    }

    func testExpandPathWithUserPath() {
        XCTAssertEqual(
            expandPath("~/file.swift", in: "/dir").path,
            NSString(string: "~/file.swift").expandingTildeInPath
        )
    }

    // MARK: shared option inference

    func testLinebreakInferredForBlankLinesBetweenScopes() {
        let input = "class Foo {\r  func bar() {\r  }\r  func baz() {\r  }\r}"
        let output = "class Foo {\r  func bar() {\r  }\r\r  func baz() {\r  }\r}"
        XCTAssertEqual(try format(input, rules: [FormatRules.blankLinesBetweenScopes]), output)
    }
}
