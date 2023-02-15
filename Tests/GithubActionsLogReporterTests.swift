//
//  GithubActionsLogReporterTests.swift
//  SwiftFormat
//
//  Created by Jonas Boberg on 2023/02/13.
//  Copyright 2023 Nick Lockwood and the SwiftFormat project authors
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

class GithubActionsLogReporterTests: XCTestCase {
    func testWrite() throws {
        let reporter = GithubActionsLogReporter(environment: ["GITHUB_WORKSPACE": "/bar"])
        let rule = FormatRules.consecutiveSpaces
        reporter.report([
            .init(line: 1, rule: rule, filePath: "/bar/foo.swift"),
            .init(line: 2, rule: rule, filePath: "/bar/foo.swift"),
        ])
        let expectedOutput = """
        ::warning file=foo.swift,line=1::\(rule.help) (\(rule.name))
        ::warning file=foo.swift,line=2::\(rule.help) (\(rule.name))

        """
        let output = try reporter.write()
        let outputString = String(decoding: output, as: UTF8.self)
        XCTAssertEqual(outputString, expectedOutput)
    }
}
