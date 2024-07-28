//
//  Reporter.swift
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
    static var name: String { get }
    static var fileExtension: String? { get }

    init(environment: [String: String])

    func report(_ changes: [Formatter.Change])
    func write() throws -> Data?
}

final class DefaultReporter: Reporter {
    static let name: String = "default"
    static let fileExtension: String? = nil

    private let quietMode: Bool
    private let lenient: Bool

    init(environment: [String: String]) {
        quietMode = environment["quiet"] != nil
        lenient = environment["lenient"] != nil
    }

    func report(_ changes: [Formatter.Change]) {
        if !quietMode {
            for change in changes {
                CLI.print(change.description(asError: !lenient), lenient ? .warning : .error)
            }
        }
    }

    // TODO: support file output?
    func write() throws -> Data? { nil }
}

enum Reporters {
    static let all: [Reporter.Type] = [
        JSONReporter.self,
        GithubActionsLogReporter.self,
        XMLReporter.self,
    ]

    static var help: String {
        let names = all.map { "\"\($0.name)\"" }
        return names.joined(separator: ", ")
    }

    static func reporter(named: String, environment: [String: String]) -> Reporter? {
        all.first(where: {
            $0.name.caseInsensitiveCompare(named) == .orderedSame
        })?.init(environment: environment)
    }

    static func reporter(for url: URL, environment: [String: String]) -> Reporter? {
        all.first(where: {
            $0.fileExtension?.caseInsensitiveCompare(url.pathExtension) == .orderedSame
        })?.init(environment: environment)
    }
}
