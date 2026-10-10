//
//  PerformanceTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 30/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
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

import SwiftFormat
import XCTest

private let rulesDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Sources/Rules")

final class PerformanceTests: XCTestCase {
    static let files: [String] = {
        var files = [String]()
        _ = enumerateFiles(withInputURLs: [rulesDirectory]) { url, _, _ in
            {
                if let source = try? String(contentsOf: url) {
                    files.append(source)
                }
            }
        }
        return files
    }()

    func testTokenizing() {
        let files = PerformanceTests.files
        var tokens = [Token]()
        measure {
            tokens = files.flatMap { tokenize($0) }
        }
        for case let .error(msg) in tokens {
            XCTFail("error: \(msg)")
        }
    }

    func testFormatting() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0) }
        }
    }

    func testWorstCaseFormatting() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        let options = FormatOptions(
            linebreak: "\r\n",
            spaceAroundRangeOperators: .remove,
            spaceAroundOperatorDeclarations: .remove,
            useVoid: false,
            indentCase: true,
            trailingCommas: .never,
            indentComments: false,
            truncateBlankLines: false,
            allmanBraces: true,
            ifdefIndent: .outdent,
            wrapArguments: .beforeFirst,
            wrapCollections: .afterFirst,
            uppercaseHex: false,
            uppercaseExponent: true,
            decimalGrouping: .group(1, 1),
            binaryGrouping: .group(1, 1),
            octalGrouping: .group(1, 1),
            hexGrouping: .group(1, 1),
            hoistPatternLet: false,
            elsePosition: .nextLine,
            explicitSelf: .insert,
            experimentalRules: true,
            typeBlankLines: .insert
        )
        measure {
            _ = tokens.map { try! format($0, options: options) }
        }
    }

    func testProjectIndexWithoutFunctionReferences() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sources = directory.appendingPathComponent("Sources/Example")
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        let originalPrint = CLI.print
        defer {
            CLI.print = originalPrint
            try? FileManager.default.removeItem(at: directory)
        }
        CLI.print = { _, _ in }
        try "// Package marker".write(
            to: directory.appendingPathComponent("Package.swift"),
            atomically: true,
            encoding: .utf8
        )
        let methods = (0 ..< 512).map {
            "    func operation\($0)(_ value: Int) -> Int { value }"
        }.joined(separator: "\n")
        let references = (0 ..< 512).map {
            "        _ = values.map(operation\($0))"
        }.joined(separator: "\n")
        let source = """
        struct Worker {
        \(methods)
            func process(_ values: [Int]) {
        \(references)
            }
        }
        """
        try source.write(to: sources.appendingPathComponent("Worker.swift"), atomically: true, encoding: .utf8)
        let input = """
        extension Worker {
            public func extra() -> Int { 1 }
        }
        """
        let expected = """
        extension Worker {
            func extra() -> Int { 1 }
        }
        """
        let selected = sources.appendingPathComponent("Extension.swift")
        let cache = directory.appendingPathComponent("swiftformat.cache")
        let arguments = [
            "swiftformat", selected.path, "--rules", "redundantPublic",
            "--project-index", "auto", "--cache", cache.path, "--swift-version", "6.0", "--quiet",
        ]
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            if FileManager.default.fileExists(atPath: cache.path) {
                try! FileManager.default.removeItem(at: cache)
            }
            try! input.write(to: selected, atomically: true, encoding: .utf8)
            startMeasuring()
            let result = CLI.run(in: directory.path, with: arguments)
            stopMeasuring()
            XCTAssertEqual(result, .ok)
            XCTAssertEqual(try? String(contentsOf: selected), expected)
            XCTAssertTrue(FileManager.default.fileExists(atPath: cache.path))
        }
    }

    func testProjectIndexWithPopulatedCache() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sources = directory.appendingPathComponent("Sources/Example")
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        let originalPrint = CLI.print
        defer {
            CLI.print = originalPrint
            try? FileManager.default.removeItem(at: directory)
        }
        CLI.print = { _, _ in }
        try "// Package marker".write(to: directory.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        let fileCount = 1000
        for index in 0 ..< fileCount {
            try "struct Item\(index) {}".write(
                to: sources.appendingPathComponent("Item\(index).swift"), atomically: true, encoding: .utf8
            )
        }
        let input = """
        extension Item0 {
            public func value() -> Int { 1 }
        }
        """
        let expected = """
        extension Item0 {
            func value() -> Int { 1 }
        }
        """
        let selected = sources.appendingPathComponent("Extension.swift")
        try expected.write(to: selected, atomically: true, encoding: .utf8)
        let cache = directory.appendingPathComponent("swiftformat.cache")
        let arguments = [
            "swiftformat", selected.path, "--rules", "redundantPublic",
            "--project-index", "auto", "--cache", cache.path, "--swift-version", "6.0", "--quiet",
        ]
        XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)
        let populatedCache = try Data(contentsOf: cache)
        let cacheContents = try XCTUnwrap(JSONSerialization.jsonObject(with: populatedCache) as? [String: Any])
        let sourceIndexes = try XCTUnwrap(cacheContents["sourceIndexes"] as? [String: Any])
        for index in 0 ..< fileCount {
            XCTAssertTrue(sourceIndexes.keys.contains { $0.hasSuffix("/Item\(index).swift") })
        }

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            try! populatedCache.write(to: cache)
            try! input.write(to: selected, atomically: true, encoding: .utf8)
            startMeasuring()
            let result = CLI.run(in: directory.path, with: arguments)
            stopMeasuring()
            XCTAssertEqual(result, .ok)
            XCTAssertEqual(try? String(contentsOf: selected), expected)
        }
    }

    func testInferring() {
        let files = PerformanceTests.files
        let tokens = files.flatMap { tokenize($0) }
        var options: FormatOptions?
        measure {
            options = inferFormatOptions(from: tokens)
        }
        XCTAssertEqual(options?.indent.count, 4)
    }

    func testWrapShortMemberExpressions() {
        let body = (0 ..< 2000).map { "    consume(value\($0).member)" }.joined(separator: "\n")
        let input = """
        func process() {
        \(body)
        }
        """
        let tokens = tokenize(input)
        let options = FormatOptions(maxWidth: 120)
        var output = [Token]()
        measure {
            output = try! format(tokens, rules: [.wrap], options: options).tokens
        }
        XCTAssertEqual(output, tokens)
    }

    func testWrapLongExpressions() {
        let body = String(repeating: "    value = first + second + third + fourth\n", count: 200)
        let input = """
        func process() {
        \(body)}
        """
        let wrappedBody = String(repeating: "    value = first + second +\n        third + fourth\n", count: 200)
        let expected = """
        func process() {
        \(wrappedBody)}
        """
        let tokens = tokenize(input)
        let options = FormatOptions(maxWidth: 30)
        var output = [Token]()
        measure {
            output = try! format(tokens, rules: [.wrap], options: options).tokens
        }
        XCTAssertEqual(sourceCode(for: output), expected)
    }

    func testIndent() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: [.indent]) }
        }
    }

    func testIndentManySiblingMethods() {
        let methods = (0 ..< 1000).map { index in
            """
                func method\(index)() -> Int {
                    return \(index)
                }
            """
        }.joined(separator: "\n\n")
        let input = """
        struct Example {
        \(methods)
        }
        """
        let tokens = tokenize(input)
        var output = [Token]()

        measure {
            output = try! format(tokens, rules: [.indent]).tokens
        }

        XCTAssertEqual(output, tokens)
    }

    func testWorstCaseIndent() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        let options = FormatOptions(indent: "\t", allmanBraces: true)
        measure {
            _ = tokens.map { try! format($0, rules: [.indent], options: options) }
        }
    }

    func testRedundantSelf() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: [.redundantSelf]) }
        }
    }

    func testWorstCaseRedundantSelf() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        let options = FormatOptions(explicitSelf: .insert)
        measure {
            _ = tokens.map { try! format($0, rules: [.redundantSelf], options: options) }
        }
    }

    func testNumberFormatting() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: [.numberFormatting]) }
        }
    }

    func testDirectiveWithMultilineString() {
        let header = #"""
        // swiftformat:disable:next numberFormatting
        let text = """
        value: \(123456)
        """

        """#
        let declarations = (0 ..< 1000).map { index in
            """
            func value\(index)() -> Int {
                return 123456
            }

            """
        }.joined()
        let tokens = tokenize(header + declarations)
        let expected = tokenize(header + declarations.replacingOccurrences(of: "123456", with: "123_456"))
        var output = [Token]()
        measure {
            output = try! format(tokens, rules: [.numberFormatting]).tokens
        }
        XCTAssertEqual(output, expected)
    }

    func testWorstCaseNumberFormatting() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        let options = FormatOptions(
            uppercaseHex: false,
            uppercaseExponent: true,
            decimalGrouping: .group(1, 1),
            binaryGrouping: .group(1, 1),
            octalGrouping: .group(1, 1),
            hexGrouping: .group(1, 1)
        )
        measure {
            _ = tokens.map { try! format($0, rules: [.numberFormatting], options: options) }
        }
    }
}
