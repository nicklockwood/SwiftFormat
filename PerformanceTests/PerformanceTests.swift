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

class PerformanceTests: XCTestCase {
    static let files: [String] = {
        var files = [String]()
        _ = enumerateFiles(withInputURL: rulesDirectory) { url, _, _ in
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
            spaceAroundRangeOperators: false,
            spaceAroundOperatorDeclarations: false,
            useVoid: false,
            indentCase: true,
            trailingCommas: false,
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
            elseOnNextLine: true,
            explicitSelf: .insert,
            experimentalRules: true
        )
        measure {
            _ = tokens.map { try! format($0, options: options) }
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

    func testIndent() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: [.indent]) }
        }
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
