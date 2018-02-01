//
//  PerformanceTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 30/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import SwiftFormat
import XCTest

class PerformanceTests: XCTestCase {
    static let files: [String] = {
        var files = [String]()
        let inputURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
        _ = enumerateFiles(withInputURL: inputURL) { url, _ in
            return {
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
            _ = tokens.map { try! format($0, rules: FormatRules.default) }
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
            wrapElements: .afterFirst,
            uppercaseHex: false,
            uppercaseExponent: true,
            decimalGrouping: .group(1, 1),
            binaryGrouping: .group(1, 1),
            octalGrouping: .group(1, 1),
            hexGrouping: .group(1, 1),
            hoistPatternLet: false,
            elseOnNextLine: true,
            removeSelf: false,
            experimentalRules: true
        )
        measure {
            _ = tokens.map { try! format($0, rules: FormatRules.default, options: options) }
        }
    }

    func testInferring() {
        let files = PerformanceTests.files
        let tokens = files.flatMap { tokenize($0) }
        measure {
            _ = inferOptions(from: tokens)
        }
    }

    func testIndent() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: [FormatRules.indent]) }
        }
    }

    func testWorstCaseIndent() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        let options = FormatOptions(indent: "\t", allmanBraces: true)
        measure {
            _ = tokens.map { try! format($0, rules: [FormatRules.indent], options: options) }
        }
    }

    func testRedundantSelf() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: [FormatRules.redundantSelf]) }
        }
    }

    func testWorstCaseRedundantSelf() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        let options = FormatOptions(removeSelf: false)
        measure {
            _ = tokens.map { try! format($0, rules: [FormatRules.redundantSelf], options: options) }
        }
    }

    func testNumberFormatting() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: [FormatRules.numberFormatting]) }
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
            _ = tokens.map { try! format($0, rules: [FormatRules.numberFormatting], options: options) }
        }
    }
}
