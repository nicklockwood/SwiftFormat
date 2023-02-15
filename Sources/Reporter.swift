//
//  Report.swift
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

import Foundation

protocol Reporter {
    init(environment: [String: String])
    func report(_ changes: [Formatter.Change])
    func write() throws -> Data
}

enum Reporters {
    static var availableIdentifiersHelp: String {
        reporters.keys.sorted().joined(separator: ", ")
    }

    static func makeReporter(identifier: String, environment: [String: String]) -> Reporter? {
        reporters[identifier].map { $0.init(environment: environment) }
    }
}

private let reporters: [String: Reporter.Type] = [
    "json": JSONReporter.self,
    "github-actions-log": GithubActionsLogReporter.self,
]
