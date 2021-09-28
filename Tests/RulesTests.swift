//
//  RulesTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
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

class RulesTests: XCTestCase {
    // MARK: - shared test infra

    func testFormatting(for input: String, _ output: String? = nil, rule: FormatRule,
                        options: FormatOptions = .default, exclude: [String] = [],
                        file: StaticString = #file, line: UInt = #line)
    {
        testFormatting(for: input, output.map { [$0] } ?? [], rules: [rule],
                       options: options, exclude: exclude, file: file, line: line)
    }

    func testFormatting(for input: String, _ outputs: [String] = [], rules: [FormatRule],
                        options: FormatOptions = .default, exclude: [String] = [],
                        file: StaticString = #file, line: UInt = #line)
    {
        // The `name` property on individual rules is not populated until the first call into `rulesByName`,
        // so we have to make sure to trigger this before checking the names of the given rules.
        if rules.contains(where: { $0.name.isEmpty }) {
            _ = FormatRules.all
        }

        precondition(input != outputs.first || input != outputs.last, "Redundant output parameter")
        precondition((0 ... 2).contains(outputs.count), "Only 0, 1 or 2 output parameters permitted")
        precondition(Set(exclude).intersection(rules.map { $0.name }).isEmpty, "Cannot exclude rule under test")
        let output = outputs.first ?? input, output2 = outputs.last ?? input
        let exclude = exclude
            + (rules.first?.name == "linebreakAtEndOfFile" ? [] : ["linebreakAtEndOfFile"])
            + (rules.first?.name == "organizeDeclarations" ? [] : ["organizeDeclarations"])
            + (rules.first?.name == "extensionAccessControl" ? [] : ["extensionAccessControl"])
            + (rules.first?.name == "markTypes" ? [] : ["markTypes"])
            + (rules.first?.name == "blockToLineComments" ? [] : ["blockToLineComments"])
        XCTAssertEqual(try format(input, rules: rules, options: options), output, file: file, line: line)
        XCTAssertEqual(try format(input, rules: FormatRules.all(except: exclude), options: options),
                       output2, file: file, line: line)
        if input != output {
            XCTAssertEqual(try format(output, rules: rules, options: options),
                           output, file: file, line: line)
            if !input.hasPrefix("#!") {
                for rule in rules {
                    let disabled = "// swiftformat:disable \(rule.name)\n\(input)"
                    XCTAssertEqual(try format(disabled, rules: [rule], options: options),
                                   disabled, "Failed to disable \(rule.name) rule", file: file, line: line)
                }
            }
        }
        if input != output2, output != output2 {
            XCTAssertEqual(try format(output2, rules: FormatRules.all(except: exclude), options: options),
                           output2, file: file, line: line)
        }

        #if os(macOS)
            // These tests are flakey on Linux, and it's hard to debug
            XCTAssertEqual(try lint(output, rules: rules, options: options), [], file: file, line: line)
            XCTAssertEqual(try lint(output2, rules: FormatRules.all(except: exclude), options: options),
                           [], file: file, line: line)
        #endif
    }
}
