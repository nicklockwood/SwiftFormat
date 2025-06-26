//
//  SARIFReporter.swift
//  SwiftFormat
//
//  Created by Laurent Etiemble on 25/06/2025.
//  Copyright 2025 Nick Lockwood and the SwiftFormat project authors
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

final class SARIFReporter: Reporter {
    static let name: String = "sarif"
    static let fileExtension: String? = "sarif"

    private var changes: [Formatter.Change] = []

    init(environment _: [String: String]) {}

    func report(_ changes: [Formatter.Change]) {
        self.changes.append(contentsOf: changes)
    }

    func write() throws -> Data? {
        let encoder = JSONEncoder()
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
        let result = SARIFLog(changes)
        var data = try encoder.encode(result)
        if stripSlashes, let string = String(data: data, encoding: .utf8) {
            data = Data(string.replacingOccurrences(of: "\\/", with: "/").utf8)
        }
        return data
    }
}

/// Partial model for a SARIF log object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790728
private struct SARIFLog: Encodable {
    let version: String = "2.1.0"
    let schema = "https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/schemas/sarif-schema-2.1.0.json"
    let runs: [Run]

    init(_ changes: [Formatter.Change]) {
        runs = [Run(changes)]
    }

    enum CodingKeys: String, CodingKey {
        case version
        case schema = "$schema"
        case runs
    }
}

/// Partial model for a SARIF run object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790734
private struct Run: Encodable {
    let tool: Tool
    let results: [Result]

    init(_ changes: [Formatter.Change]) {
        tool = Tool()
        results = changes.map(Result.init)
    }
}

/// Partial model for a SARIF tool object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790779
private struct Tool: Encodable {
    let driver = ToolComponent()
}

/// Partial model for a SARIF toolComponent object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790783
private struct ToolComponent: Encodable {
    let name = "SwiftFormat"
    let version = swiftFormatVersion
    let informationUri = "https://github.com/nicklockwood/SwiftFormat"
}

/// Partial model for a SARIF result object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790888
private struct Result: Encodable {
    let ruleId: String
    let level: Level
    let message: Message
    let locations: [Location]

    init(_ change: Formatter.Change) {
        ruleId = change.rule.name
        level = .warning
        message = Message(change)
        locations = [Location(change)]
    }
}

private enum Level: String, Encodable {
    case none
    case note
    case warning
    case error
}

/// Partial model for a SARIF message object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790709
private struct Message: Encodable {
    let text: String

    init(_ change: Formatter.Change) {
        text = change.help
    }
}

/// Partial model for a SARIF location object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790920
private struct Location: Encodable {
    let physicalLocation: PhysicalLocation

    init(_ change: Formatter.Change) {
        physicalLocation = PhysicalLocation(change)
    }
}

/// Partial model for a SARIF physicalLocation object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790928
private struct PhysicalLocation: Encodable {
    let artifactLocation: ArtifactLocation
    let region: Region

    init(_ change: Formatter.Change) {
        artifactLocation = ArtifactLocation(change)
        region = Region(change)
    }
}

/// Partial model for a SARIF artifactLocation object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790677
private struct ArtifactLocation: Encodable {
    let uri: URL

    init(_ change: Formatter.Change) {
        uri = URL(fileURLWithPath: change.filePath ?? "/")
    }
}

/// Partial model for a SARIF message object.
/// https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790935
private struct Region: Encodable {
    let startLine: Int
    let startColumn: Int
    let endLine: Int
    let endColumn: Int

    init(_ change: Formatter.Change) {
        startLine = change.line
        startColumn = 1
        endLine = change.line
        endColumn = 2
    }
}
