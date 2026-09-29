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

final class SwiftFormatTests: XCTestCase {
    func testLineArrayTracksWholeBufferReplacement() {
        let input = ["let a = 1\n", "let b = 2\n"]
        let mutations: [(NSMutableArray) -> Void] = [
            { $0.setArray(input) },
            { $0.replaceObjects(in: NSRange(location: 0, length: input.count), withObjectsFrom: input) },
            {
                $0.removeAllObjects()
                $0.addObjects(from: input)
            },
        ]
        for mutate in mutations {
            let lines = TrackedLineArray(lines: input)
            mutate(lines)
            XCTAssertEqual(lines as? [String], input)
            XCTAssertEqual(lines.originalIndices, [nil, nil])
        }
    }

    func testReplaceLinesWithoutChangesPreservesOriginalObjects() {
        let originals = ["func foo() {\n", "    bar()\n", "}\n"].map { NSMutableString(string: $0) }
        let lines = TrackedLineArray(lines: originals)
        replaceLines(in: lines, with: tokenize(originals.map { $0 as String }.joined()))
        XCTAssertEqual(lines.count, originals.count)
        for index in originals.indices {
            XCTAssertEqual(lines.originalIndices[index], index)
        }
    }

    func testReplaceLinesPreservesUnchangedBlockBetweenEdits() {
        let originals = [
            "let before =  1\n",
            "func untouched() {\n",
            "    /* a folded comment */\n",
            "    print(\"unchanged\")\n",
            "}\n",
            "let after =  2\n",
        ].map { NSMutableString(string: $0) }
        let lines = TrackedLineArray(lines: originals)
        let output = """
        let before = 1
        func untouched() {
            /* a folded comment */
            print("unchanged")
        }
        let after = 2

        """
        replaceLines(in: lines, with: tokenize(output))
        XCTAssertEqual((lines as? [String])?.joined(), output)
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            for index in 1 ... 4 {
                XCTAssertEqual(lines.originalIndices[index], index)
            }
        }
    }

    func testReplaceLinesInsertsAtBeginningMiddleAndEnd() {
        let originals = ["let a = 1\n", "let b = 2\n", "let c = 3\n"].map { NSMutableString(string: $0) }
        let lines = TrackedLineArray(lines: originals)
        let output = """
        // start
        let a = 1
        // middle
        let b = 2
        let c = 3
        // end

        """
        replaceLines(in: lines, with: tokenize(output))
        XCTAssertEqual((lines as? [String])?.joined(), output)
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            for (index, originalIndex) in zip([1, 3, 4], originals.indices) {
                XCTAssertEqual(lines.originalIndices[index], originalIndex)
            }
        }
    }

    func testReplaceLinesDeletesAtBeginningMiddleAndEnd() {
        let originals = ["// start\n", "let a = 1\n", "// middle\n", "let b = 2\n", "// end\n"]
            .map { NSMutableString(string: $0) }
        let lines = TrackedLineArray(lines: originals)
        let output = """
        let a = 1
        let b = 2

        """
        replaceLines(in: lines, with: tokenize(output))
        XCTAssertEqual((lines as? [String])?.joined(), output)
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            XCTAssertEqual(lines.originalIndices[0], 1)
            XCTAssertEqual(lines.originalIndices[1], 3)
        }
    }

    func testReplaceLinesPreservesRepeatedBracesAndBlankLines() {
        let originals = ["func foo() {\n", "    bar ()\n", "}\n", "\n", "func baz() {\n", "    quux()\n", "}\n"]
            .map { NSMutableString(string: $0) }
        let lines = TrackedLineArray(lines: originals)
        let output = """
        func foo() {
            bar()
        }

        func baz() {
            quux()
        }

        """
        replaceLines(in: lines, with: tokenize(output))
        XCTAssertEqual((lines as? [String])?.joined(), output)
        for index in [0, 2, 3, 4, 5, 6] {
            XCTAssertEqual(lines.originalIndices[index], index)
        }
    }

    func testReplaceLinesPreservesLineEndings() {
        for linebreak in ["\n", "\r\n", "\r"] {
            let original = NSMutableString(string: "let café = 1\(linebreak)")
            let lines = TrackedLineArray(lines: [original, "print (café)\(linebreak)"])
            let output = "let café = 1\(linebreak)print(café)\(linebreak)"
            replaceLines(in: lines, with: tokenize(output))
            XCTAssertEqual(lines as? [String], ["let café = 1\(linebreak)", "print(café)\(linebreak)"])
            XCTAssertEqual(lines.originalIndices[0], 0)
        }
    }

    func testReplaceLinesPreservesUnterminatedFinalLine() {
        let original = NSMutableString(string: "print(café)")
        let lines = TrackedLineArray(lines: ["let café =  1\n", original])
        let output = """
        let café = 1
        print(café)
        """
        replaceLines(in: lines, with: tokenize(output))
        XCTAssertEqual((lines as? [String])?.joined(), output)
        XCTAssertEqual(lines.originalIndices[1], 1)
    }

    func testReplaceLinesRetainsExistingTerminalEmptyLine() {
        let terminalLine = NSMutableString(string: "")
        let lines = TrackedLineArray(lines: ["let foo =  1\n", terminalLine])
        let output = "let foo = 1\n"
        replaceLines(in: lines, with: tokenize(output))
        XCTAssertEqual(lines as? [String], [output, ""])
        XCTAssertEqual(lines.originalIndices[1], 1)
    }

    func testReplaceLinesRemovesTerminalEmptyLineForUnterminatedOutput() {
        let lines = NSMutableArray(array: ["let foo = 1\n", ""])
        replaceLines(in: lines, with: tokenize("let foo = 1"))
        XCTAssertEqual(lines as? [String], ["let foo = 1"])
    }

    func testReplaceLinesEmptyOutput() {
        for input in [[], [""], ["let foo = 1\n"], ["let foo = 1\n", ""]] as [[String]] {
            let lines = NSMutableArray(array: input)
            replaceLines(in: lines, with: [])
            XCTAssertEqual((lines as? [String])?.joined(), "")
            XCTAssertEqual(lines as? [String], input.last == "" ? [""] : [])
        }
    }

    func testReplaceLinesEmptyInput() {
        for input in [[], [""]] as [[String]] {
            let lines = NSMutableArray(array: input)
            replaceLines(in: lines, with: tokenize("let foo = 1\n"))
            XCTAssertEqual((lines as? [String])?.joined(), "let foo = 1\n")
        }
    }

    func testReplaceLinesAfterFormattingSelectedRange() throws {
        let originals = ["let foo =  1\n", "func untouched() {}\n", "let bar =  2\n"]
            .map { NSMutableString(string: $0) }
        let lines = TrackedLineArray(lines: originals)
        let input = tokenize(originals.map { $0 as String }.joined())
        let range = tokenRange(forLineRange: 1 ... 1, in: input)
        let output = try format(input, rules: [.consecutiveSpaces], range: range).tokens
        replaceLines(in: lines, with: output)
        XCTAssertEqual((lines as? [String])?.joined(), "let foo = 1\nfunc untouched() {}\nlet bar =  2\n")
        XCTAssertEqual(lines.originalIndices[1], 1)
        XCTAssertEqual(lines.originalIndices[2], 2)
    }

    func testReplaceLinesUsesExactUnicodeRepresentation() throws {
        for (input, output) in [
            ("let café = 1\n", "let cafe\u{301} = 1\n"),
            ("let a =  1\nlet café = 1\n", "let a = 1\nlet cafe\u{301} = 1\n"),
            ("let café = 1\nlet b =  2\n", "let cafe\u{301} = 1\nlet b = 2\n"),
            ("let a =  1\nlet café = 1\nlet b =  2\n", "let a = 1\nlet cafe\u{301} = 1\nlet b = 2\n"),
        ] {
            let lines = NSMutableArray(array: tokenize(input).lines.map { sourceCode(for: Array($0)) })
            replaceLines(in: lines, with: tokenize(output))
            XCTAssertEqual(try Array(XCTUnwrap((lines as? [String])?.joined().utf8)), Array(output.utf8))
        }
    }

    func testReplaceLinesWithRepeatedLinesProducesExactOutput() throws {
        var inputs: [[String]] = [[]]
        var level: [[String]] = [[]]
        for _ in 0 ..< 3 {
            level = level.flatMap { prefix in ["let a = 1\n", "}\n", "\n"].map { prefix + [$0] } }
            inputs += level
        }
        for input in inputs {
            for output in inputs {
                let lines = NSMutableArray(array: input)
                replaceLines(in: lines, with: tokenize(output.joined()))
                XCTAssertEqual(try XCTUnwrap(lines as? [String]), output, "Input: \(input)")
            }
        }
    }

    func testReplaceLinesRetainsSelectionOffsetsAfterRemovingLines() throws {
        let input = tokenize("let a = 1\n\n\n\tlet café = 2\n\tprint(café)\n")
        let output = try format(input, rules: [.consecutiveBlankLines]).tokens
        let lines = NSMutableArray(array: input.lines.map { sourceCode(for: Array($0)) })
        replaceLines(in: lines, with: output)
        XCTAssertEqual((lines as? [String])?.joined(), sourceCode(for: output))
        let offsets = [SourceOffset(line: 4, column: 5), SourceOffset(line: 5, column: 10)]
        let expected = [SourceOffset(line: 3, column: 5), SourceOffset(line: 4, column: 10)]
        XCTAssertEqual(offsets.map { newOffset(for: $0, in: output, tabWidth: 4) }, expected)
    }

    func testReplaceLinesPreservesLargeUnchangedRegion() {
        let originals = (0 ..< 5000).map { NSMutableString(string: "let value\($0) = \($0)\n") }
        var updated = originals.map { $0 as String }
        updated[0] = "let value0 = 1\n"
        updated[4999] = "let value4999 = 5000\n"
        let lines = TrackedLineArray(lines: originals)
        replaceLines(in: lines, with: tokenize(updated.joined()))
        XCTAssertEqual(lines as? [String], updated)
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            XCTAssertEqual(lines.originalIndices[2500], 2500)
        }
    }

    func testReplaceLinesMixedChangesAfterUnchangedPrefix() {
        let originals = ["// keep\n", "// remove\n", "let a = 1\n", "}\n", "}\n", "// old end\n"]
            .map { NSMutableString(string: $0) }
        let output = """
        // keep
        let a = 1
        // insert
        }
        }
        // new end

        """
        let lines = TrackedLineArray(lines: originals)
        replaceLines(in: lines, with: tokenize(output))
        XCTAssertEqual((lines as? [String])?.joined(), output)
        XCTAssertEqual(lines.originalIndices[0], 0)
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            XCTAssertEqual(lines.originalIndices[1], 2)
            XCTAssertEqual(lines.originalIndices[3], 3)
            XCTAssertEqual(lines.originalIndices[4], 4)
        }
    }

    func testReplaceLineRangePreservesOutsideLines() {
        for replacement in [[], ["let a = 1\n"], ["let a = 1\n", "let b = 2\n", "let c = 3\n"]] {
            let input = ["// before\n", "let a =  1\n", "let b =  2\n", "// after\n"]
            let lines = TrackedLineArray(lines: input)
            replaceLineRange(in: lines, range: 1 ..< 3, with: replacement)
            XCTAssertEqual(lines as? [String], [input[0]] + replacement + [input[3]])
            XCTAssertEqual(lines.originalIndices, [0] + Array(repeating: nil, count: replacement.count) + [3])
        }
    }

    func testReplaceLineRangeWithEmptyRange() {
        for input in [[], ["// after\n"]] {
            for replacement in [[], ["let a = 1\n", "let b = 2\n"]] {
                let lines = NSMutableArray(array: input)
                replaceLineRange(in: lines, range: 0 ..< 0, with: replacement)
                XCTAssertEqual(lines as? [String], replacement + input)
            }
        }
    }

    // MARK: enumerateFiles

    func testRuleTimeoutReportsRuleName() {
        let slowRule = FormatRule(help: "") { _ in
            Thread.sleep(forTimeInterval: 1)
        } examples: { nil }
        var options = FormatOptions.default
        options.timeout = 0.05
        let tokens = tokenize("let foo = 1")
        XCTAssertThrowsError(try applyRules([slowRule], to: tokens, with: options, trackChanges: false, range: nil)) { error in
            guard case let FormatError.writing(message) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssert(message.hasSuffix("rule timed out"), message)
        }
    }

    func testInputFileMatchesOutputFileForNilOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file)
        let errors = enumerateFiles(withInputURLs: [inputURL]) { inputURL, outputURL, _ in
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
        let errors = enumerateFiles(withInputURLs: [inputURL], outputURL: inputURL) { inputURL, outputURL, _ in
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
        let errors = enumerateFiles(withInputURLs: [inputURL]) { inputURL, outputURL, _ in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertGreaterThanOrEqual(files.count, 180)
    }

    func testInputFilesMatchOutputFilesForSameOutput() {
        var files = [URL]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURLs: [inputURL], outputURL: inputURL) { inputURL, outputURL, _ in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }
        XCTAssertEqual(errors.count, 0)
        XCTAssertGreaterThanOrEqual(files.count, 180)
    }

    func testInputFileNotEnumeratedWhenExcluded() {
        var files = [URL]()
        let currentFile = URL(fileURLWithPath: #file)
        let options = Options(fileOptions: FileOptions(excludedGlobs: [
            Glob.path(currentFile.deletingLastPathComponent().path),
        ]))
        let inputURL = currentFile.deletingLastPathComponent().deletingLastPathComponent()
        let errors = enumerateFiles(withInputURLs: [inputURL], outputURL: inputURL, options: options) { inputURL, outputURL, _ in
            XCTAssertEqual(inputURL, outputURL)
            return { files.append(inputURL) }
        }

        var allFiles = [URL]()
        let allFilesInputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        _ = enumerateFiles(withInputURLs: [allFilesInputURL], outputURL: allFilesInputURL) { inputURL, outputURL, _ in
            XCTAssertEqual(inputURL, outputURL)
            return { allFiles.append(inputURL) }
        }

        XCTAssertEqual(errors.count, 0)
        XCTAssertLessThan(files.count, allFiles.count)
    }

    // MARK: format function

    func testFormatReturnsInputWithNoRules() {
        let input = "foo ()  "
        XCTAssertEqual(try format(input, rules: []).output, input)
    }

    func testFormatUsesDefaultRulesIfNoneSpecified() {
        let input = "foo ()  "
        let output = "foo()\n"
        XCTAssertEqual(try format(input).output, output)
    }

    // MARK: lint function

    func testLintReturnsNoChangesWithNoRules() {
        let input = "foo ()  "
        XCTAssertEqual(try lint(input, rules: []), [])
    }

    func testLintWithDefaultRules() {
        let input = "foo ()  "
        XCTAssertEqual(try lint(input), [
            .init(line: 1, rule: .linebreakAtEndOfFile, filePath: nil, isMove: false),
            .init(line: 1, rule: .spaceAroundParens, filePath: nil, isMove: false),
            .init(line: 1, rule: .trailingSpace, filePath: nil, isMove: false),
        ])
    }

    func testLintConsecutiveBlankLinesAtEndOfFile() {
        let input = "foo\n\n"
        XCTAssertEqual(try lint(input), [
            .init(line: 2, rule: .consecutiveBlankLines, filePath: nil, isMove: false),
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
        XCTAssertEqual(try format(input, rules: [], options: options).output, input)
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
        XCTAssertEqual(try format(input, rules: [], options: options).output, input)
    }

    // MARK: empty file

    func testNoTimeoutForEmptyFile() {
        let input = ""
        XCTAssertEqual(try format(input).output, input)
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
        XCTAssertEqual(tokenRange(forLineRange: 1 ... 1, in: tokens), 0 ..< 3)
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
        let output = try format(input, rules: [.consecutiveBlankLines]).tokens
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
        XCTAssertEqual(try format(input, rules: [.blankLinesBetweenScopes]).output, output)
    }
}

/// Track edits rather than NSString identity, which is lost when Foundation bridges strings on Linux.
private final class TrackedLineArray: NSMutableArray {
    private var storage: [Any] = []
    private(set) var originalIndices: [Int?] = []

    convenience init(lines: [Any]) {
        self.init()
        storage = lines
        originalIndices = lines.indices.map { $0 }
    }

    override var count: Int {
        storage.count
    }

    override func object(at index: Int) -> Any {
        storage[index]
    }

    override func insert(_ anObject: Any, at index: Int) {
        storage.insert(anObject, at: index)
        originalIndices.insert(nil, at: index)
    }

    override func removeObject(at index: Int) {
        storage.remove(at: index)
        originalIndices.remove(at: index)
    }

    override func replaceObject(at index: Int, with anObject: Any) {
        storage[index] = anObject
        originalIndices[index] = nil
    }

    override func add(_ anObject: Any) {
        insert(anObject, at: count)
    }

    override func removeLastObject() {
        if count > 0 {
            removeObject(at: count - 1)
        }
    }

    override func replaceObjects(in range: NSRange, withObjectsFrom otherArray: [Any]) {
        storage.replaceSubrange(Range(range)!, with: otherArray)
        originalIndices.replaceSubrange(Range(range)!, with: Array(repeating: nil, count: otherArray.count))
    }
}
