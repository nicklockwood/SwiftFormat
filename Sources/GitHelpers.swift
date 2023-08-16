//
//  GitHelpers.swift
//  SwiftFormat
//
//  Created by Hampus Tågerud on 2023-08-08.
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

private func memoize<K, T>(_ keyFn: @escaping (K) -> String?,
                           _ workFn: @escaping (K) -> T) -> (K) -> T
{
    let lock = NSLock()
    var cache: [String: T] = [:]

    return { input in
        let key = keyFn(input) ?? "@nil"

        lock.lock()
        defer { lock.unlock() }

        if let value = cache[key] {
            return value
        }

        let newValue = workFn(input)
        cache[key] = newValue

        return newValue
    }
}

struct GitFileInfo {
    var createdByName: String?
    var createdByEmail: String?
    var createdAt: Date?
}

enum GitHelpers {
    static let getGitRoot: (URL) -> URL? = memoize({ $0.relativePath }) { url in
        let dir = "git rev-parse --show-toplevel".shellOutput(cwd: url)

        guard let root = dir, FileManager.default.fileExists(atPath: root) else {
            return nil
        }

        return URL(fileURLWithPath: root, isDirectory: true)
    }

    // If a file has never been committed, default to the local git user for the repository
    static let getDefaultGitInfo: (URL) -> GitFileInfo? = memoize({ $0.relativePath }) { url in
        let name = "git config user.name".shellOutput(cwd: url)
        let email = "git config user.email".shellOutput(cwd: url)

        guard let safeName = name, let safeEmail = email else { return nil }

        return GitFileInfo(createdByName: safeName, createdByEmail: safeEmail)
    }

    private static func getGitCommit(_ url: URL, root: URL, follow: Bool) -> String? {
        let command = [
            "git log",
            // --follow to keep tracking the file across renames
            follow ? "--follow" : "",
            "--diff-filter=A",
            "--author-date-order",
            "--pretty=%H",
            url.relativePath,
        ]
        .filter { ($0?.count ?? 0) > 0 }
        .joined(separator: " ")

        let output = command.shellOutput(cwd: root)

        guard let safeValue = output, !safeValue.isEmpty else { return nil }

        if safeValue.contains("\n") {
            let parts = safeValue.split(separator: "\n")

            if parts.count > 1, let first = parts.first {
                return String(first)
            }
        }

        return safeValue
    }

    static var json: JSONDecoder { JSONDecoder() }

    static let getCommitInfo: ((String, URL)) -> GitFileInfo? = memoize(
        { hash, root in hash + root.relativePath },
        { hash, root in
            let format = #"{"name":"%an","email":"%ae","time":"%at"}"#
            let command = "git show --format='\(format)' -s \(hash)"
            guard let commitInfo = command.shellOutput(cwd: root) else {
                return nil
            }

            guard let commitData = commitInfo.data(using: .utf8) else {
                return nil
            }

            let MapType = [String: String].self
            guard let dict = try? json.decode(MapType, from: commitData) else {
                return nil
            }

            let (name, email) = (dict["name"], dict["email"])

            var date: Date?
            if let createdAtString = dict["time"],
               let interval = TimeInterval(createdAtString)
            {
                date = Date(timeIntervalSince1970: interval)
            }

            return GitFileInfo(createdByName: name,
                               createdByEmail: email,
                               createdAt: date)
        }
    )

    static func fileInfo(_ url: URL, follow: Bool = false) -> GitFileInfo? {
        let dir = url.deletingLastPathComponent()
        guard let gitRoot = getGitRoot(dir) else { return nil }

        guard let commitHash = getGitCommit(url, root: gitRoot, follow: follow) else {
            return nil
        }

        return getCommitInfo((commitHash, gitRoot))
    }
}
