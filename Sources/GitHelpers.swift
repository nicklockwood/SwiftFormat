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

struct GitFileInfo {
    var createdByName: String?
    var createdByEmail: String?
    var createdAt: Date?
}

struct GitHelpers {
    var currentWorkingDirectory: URL?

    init(cwd: URL?) {
        currentWorkingDirectory = cwd
    }

    private var inGitRoot: Bool {
        // Get current git repository top level directory
        guard let root = "git rev-parse --show-toplevel"
            .shellOutput(cwd: currentWorkingDirectory) else { return false }
        // Make sure a valid URL was returned
        guard let _ = URL(string: root) else { return false }
        // Make sure an existing path was returned
        return FileManager.default.fileExists(atPath: root)
    }

    // If a file has never been committed, defaults to the local git user for that repository
    private var defaultGitInfo: GitFileInfo? {
        guard inGitRoot else { return nil }

        let name = "git config user.name"
            .shellOutput(cwd: currentWorkingDirectory)
        let email = "git config user.email"
            .shellOutput(cwd: currentWorkingDirectory)

        guard let safeName = name, let safeEmail = email else { return nil }

        return GitFileInfo(createdByName: safeName, createdByEmail: safeEmail)
    }

    private enum FileInfoPart: String {
        case email = "ae"
        case name = "an"
        case createdAt = "at"
    }

    private func fileInfoPart(_ inputURL: URL,
                              _ part: FileInfoPart,
                              follow: Bool) -> String?
    {
        // --follow to keep tracking the file across renames
        let follow = follow ? "--follow" : ""
        let format = part.rawValue
        let path = inputURL.relativePath

        let value = "git log \(follow) --diff-filter=A --pretty=%\(format) \(path)"
            .shellOutput(cwd: currentWorkingDirectory)

        guard let safeValue = value, !safeValue.isEmpty else { return nil }
        return safeValue
    }

    func fileInfo(_ inputURL: URL, follow: Bool) -> GitFileInfo? {
        guard inGitRoot else { return nil }

        let name = fileInfoPart(inputURL, .name, follow: follow) ??
            defaultGitInfo?.createdByName
        let email = fileInfoPart(inputURL, .email, follow: follow) ??
            defaultGitInfo?.createdByEmail

        var date: Date?
        if let createdAtString = fileInfoPart(inputURL, .createdAt, follow: follow),
           let interval = TimeInterval(createdAtString)
        {
            date = Date(timeIntervalSince1970: interval)
        }

        return GitFileInfo(createdByName: name,
                           createdByEmail: email,
                           createdAt: date)
    }

    static func fileInfo(_ inputURL: URL,
                         cwd: URL? = nil,
                         follow: Bool = false) -> GitFileInfo?
    {
        GitHelpers(cwd: cwd).fileInfo(inputURL, follow: follow)
    }
}
