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
}

enum GitHelpers {
    private static var inGitRoot: Bool {
        // Get current git repository top level directory
        guard let root = "git rev-parse --show-toplevel".shellOutput() else { return false }
        // Make sure a valid URL was returned
        guard let _ = URL(string: root) else { return false }
        // Make sure an existing path was returned
        return FileManager.default.fileExists(atPath: root)
    }

    // If a file has never been committed, default to the local git user for that repository
    private static var defaultGitInfo: GitFileInfo? {
        guard inGitRoot else { return nil }

        let name = "git config user.name".shellOutput()
        let email = "git config user.email".shellOutput()

        guard let safeName = name, let safeEmail = email else { return nil }

        return GitFileInfo(createdByName: safeName, createdByEmail: safeEmail)
    }

    private enum FileInfoPart: String {
        case email = "ae"
        case name = "an"
    }

    private static func fileInfoPart(_ inputURL: URL, _ part: FileInfoPart) -> String? {
        let value = "git log --diff-filter=A --pretty=%\(part.rawValue) \(inputURL.relativePath)"
            .shellOutput()

        guard let safeValue = value, !safeValue.isEmpty else { return nil }
        return safeValue
    }

    static func fileInfo(_ inputURL: URL) -> GitFileInfo? {
        guard inGitRoot else { return nil }

        let name = fileInfoPart(inputURL, .name) ?? defaultGitInfo?.createdByName
        let email = fileInfoPart(inputURL, .email) ?? defaultGitInfo?.createdByEmail

        return GitFileInfo(createdByName: name, createdByEmail: email)
    }
}
