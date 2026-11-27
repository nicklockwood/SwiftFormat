//
//  CodeClimateReporter.swift
//  SwiftFormat
//
//  Created by Mario Trangoni on 18/11/2026.
//  Copyright 2026 Nick Lockwood and the SwiftFormat project authors
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

final class CodeClimateReporter: Reporter {
    static let name = "codeclimate"
    static let fileExtension: String? = nil

    private let repositoryRoot: URL
    private var changes: [Formatter.Change] = []

    init(environment: [String: String]) {
        repositoryRoot = URL(
            fileURLWithPath: environment["PWD"] ?? FileManager.default.currentDirectoryPath,
            isDirectory: true
        ).standardizedFileURL
    }

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
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            encoder.outputFormatting.insert(.withoutEscapingSlashes)
        }
        var data = try encoder.encode(changes.map { CodeClimateIssue($0, path: relativePath(for: $0.filePath)) })
        if #unavailable(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0),
           let string = String(data: data, encoding: .utf8)
        {
            data = Data(string.replacingOccurrences(of: "\\/", with: "/").utf8)
        }
        return data
    }

    private func relativePath(for filePath: String?) -> String {
        guard let filePath else { return "" }
        let path = URL(fileURLWithPath: filePath, relativeTo: repositoryRoot).standardizedFileURL.path
        let rootPath = repositoryRoot.path
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard path.hasPrefix(prefix) else { return path }
        return String(path.dropFirst(prefix.count))
    }
}

private struct CodeClimateIssue: Encodable {
    let type = "issue"
    let checkName: String
    let description: String
    let categories = ["Style"]
    let fingerprint: String
    let severity = "minor"
    let location: Location

    init(_ change: Formatter.Change, path: String) {
        checkName = "SwiftFormat/\(change.rule.name)"
        description = change.help
        fingerprint = computeHash("\(checkName):\(path):\(change.line)")
        location = Location(path: path, lines: LineRange(begin: change.line, end: change.line))
    }

    struct Location: Encodable {
        let path: String
        let lines: LineRange
    }

    struct LineRange: Encodable {
        let begin: Int
        let end: Int
    }
}
