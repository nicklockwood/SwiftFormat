//
//  JSONReporter.swift
//  SwiftFormat
//
//  Created by Daniele Formichelli on 09/04/2021.
//  Copyright 2021 Nick Lockwood
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

final class JSONReporter: Reporter {
    static let name: String = "json"
    static let fileExtension: String? = "json"

    private var changes: [Formatter.Change] = []

    init(environment _: [String: String]) {}

    func report(_ changes: [Formatter.Change]) {
        self.changes.append(contentsOf: changes)
    }

    func write() throws -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .prettyPrinted
        if #available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            encoder.outputFormatting.insert(.sortedKeys)
        }
        let stripSlashes: Bool
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            stripSlashes = false
            encoder.outputFormatting.insert(.withoutEscapingSlashes)
        } else {
            stripSlashes = true
        }
        var data = try encoder.encode(changes.map(ReportItem.init))
        if stripSlashes, let string = String(data: data, encoding: .utf8) {
            data = Data(string.replacingOccurrences(of: "\\/", with: "/").utf8)
        }
        return data
    }
}

private struct ReportItem: Encodable {
    let file: String?
    let line: Int
    let reason: String
    let ruleID: String

    init(_ change: Formatter.Change) {
        file = change.filePath
        line = change.line
        reason = change.help
        ruleID = change.rule.name
    }
}
