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
        XCTAssertEqual(files.count, 36)
    }

    func testInputFilesMatchOutputFilesForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURL: inputURL, outputURL: inputURL) { inputURL, outputURL, _ in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(files.count, 36)
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
        XCTAssertEqual(files.count, 26)
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

    // MARK: expand glob

    func testExpandWildcardPathWithExactName() {
        let path = "Tokenizer.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithWildcardInMiddle() {
        let path = "Rule*.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithSingleCharacterWildcardInMiddle() {
        let path = "Rule?.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithWildcardAtEnd() {
        let path = "Options*"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 2)
    }

    func testExpandPathWithDoubleWildcardAtEnd() {
        let path = "Options**"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 2)
    }

    func testExpandPathWithCharacterClass() {
        let path = "Options[DS]*.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithCharacterClassRange() {
        let path = "Options[E-T]*.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("EditorExtension/Shared")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithPattern() {
        let path = "Option{s,sDescriptor}.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 2)
    }

    func testExpandPathsWithPatterns() {
        let path = "Option{s,sDescriptor}.swift, SwiftFormat.{h,swift}"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 4)
    }

    func testExpandPathWithWildcardAtStart() {
        let path = "*Tests.swift"
        let directory = URL(fileURLWithPath: #file).deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 10)
    }

    func testExpandPathWithSubdirectoryAndWildcard() {
        let path = "Tests/*Tests.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 10)
    }

    func testSingleWildcardDoesNotMatchDirectorySlash() {
        let path = "*/SwiftFormatTests.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 0)
    }

    func testDoubleWildcardMatchesDirectorySlash() {
        let path = "**/SwiftFormatTests.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testDoubleWildcardMatchesNoSubdirectories() {
        let path = "Tests/**/SwiftFormatTests.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandGlobsChecksForExactPaths() {
        let path = "Tests/Glob?Test[5]*.txt"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }
}
