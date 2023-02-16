//
//  GithubActionsLogReporter.swift
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

/// Output lint violations as Github Action annotations.
///
/// See https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-a-warning-message
///
final class GithubActionsLogReporter: Reporter {
    static let name: String = "github-actions-log"
    static let fileExtension: String? = nil

    private let workspaceRoot: String?
    private var changes: [Formatter.Change] = []

    init(environment: [String: String]) {
        // See https://docs.github.com/en/actions/learn-github-actions/variables
        workspaceRoot = environment["GITHUB_WORKSPACE"]
    }

    func report(_ changes: [Formatter.Change]) {
        self.changes.append(contentsOf: changes)
    }

    func write() throws -> Data {
        let output = changes.reduce(into: "") { output, change in
            let file = workspaceRelativePath(filePath: change.filePath ?? "")
            output += "::warning file=\(file),line=\(change.line)::\(change.help) (\(change.rule.name))\n"
        }
        return Data(output.utf8)
    }
}

private extension GithubActionsLogReporter {
    func workspaceRelativePath(filePath: String) -> String {
        if let workspaceRoot = workspaceRoot, filePath.hasPrefix(workspaceRoot) {
            return filePath.replacingOccurrences(of: workspaceRoot + "/", with: "", options: [.anchored])
        } else {
            return filePath
        }
    }
}
