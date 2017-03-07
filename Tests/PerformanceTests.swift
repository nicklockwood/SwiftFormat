//
//  PerformanceTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 30/10/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import XCTest
import SwiftFormat

class PerformanceTests: XCTestCase {

    static let files: [String] = {
        var files = [String]()
        let inputURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
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
        var tokens = [[Token]]()
        measure {
            tokens = files.map { tokenize($0) }
        }
        for tokens in tokens {
            if let token = tokens.last, case let .error(msg) = token {
                XCTFail("error: \(msg)")
            }
        }
    }

    func testFormatting() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: FormatRules.default) }
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

    func testNumberFormatting() {
        let files = PerformanceTests.files
        let tokens = files.map { tokenize($0) }
        measure {
            _ = tokens.map { try! format($0, rules: [FormatRules.numberFormatting]) }
        }
    }
}
