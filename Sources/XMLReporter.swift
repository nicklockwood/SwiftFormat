//
//  XMLReporter.swift
//  SwiftFormat
//
//  Created by Saeid Rezaei on 13/04/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//
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
///  Reports changes as XML conforming to the Checkstyle specification, as defined here:
///  https://www.jetbrains.com/help/teamcity/xml-report-processing.html
import Foundation

final class XMLReporter: Reporter {
    static var name = "xml"
    static var fileExtension: String? = "xml"

    private var changes: [Formatter.Change] = []

    init(environment _: [String: String]) {}

    func report(_ changes: [Formatter.Change]) {
        self.changes.append(contentsOf: changes)
    }

    func write() throws -> Data {
        let fileChanges = Dictionary(grouping: changes, by: { $0.filePath ?? "<nopath>" })
        let report = [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">",
            fileChanges
                .sorted(by: { $0.key < $1.key })
                .map(generateChangeForFile).joined(),
            "\n</checkstyle>",
        ].joined()

        guard let data = report.data(using: .utf8) else { throw FormatError.parsing("") }
        return data
    }

    // MARK: - Private

    private func generateChangeForFile(_ file: String, fileChanges: [Formatter.Change]) -> String {
        [
            "\n\t<file name=\"", file, "\">\n",
            fileChanges.map(generateChange).joined(),
            "\t</file>",
        ].joined()
    }

    private func generateChange(_ change: Formatter.Change) -> String {
        let line = change.line
        let col = 0
        let severity = "warning"
        let reason = change.help
        let rule = change.rule.name
        return [
            "\t\t<error line=\"\(line)\" ",
            "column=\"\(col)\" ",
            "severity=\"", severity, "\" ",
            "message=\"", reason, "\" ",
            "source=\"\(rule)\"/>\n",
        ].joined()
    }
}
