//
//  Globs.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 31/12/2018.
//  Copyright 2018 Nick Lockwood
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

func pathContainsGlobSyntax(_ path: String) -> Bool {
    "*?[{".contains(where: { path.contains($0) })
}

/// Glob type represents either an exact path or wildcard
public enum Glob: CustomStringConvertible, Hashable {
    case path(String)
    case regex(String, NSRegularExpression)

    public func matches(_ path: String) -> Bool {
        switch self {
        case let .path(_path):
            return _path == path
        case let .regex(prefix, regex):
            guard path.hasPrefix(prefix) else {
                return false
            }
            let count = prefix.utf16.count
            let range = NSRange(location: count, length: path.utf16.count - count)
            return regex.firstMatch(in: path, options: [], range: range) != nil
        }
    }

    public var description: String {
        switch self {
        case let .path(path):
            return path
        case let .regex(prefix, regex):
            var result = regex.pattern.dropFirst().dropLast()
                .replacingOccurrences(of: "([^/]+)?", with: "*")
                .replacingOccurrences(of: "(.+/)?", with: "**/")
                .replacingOccurrences(of: ".+", with: "**")
                .replacingOccurrences(of: "[^/]", with: "?")
                .replacingOccurrences(of: "\\", with: "")
            while let range = result.range(of: "\\([^)]+\\)", options: .regularExpression) {
                let options = result[range].dropFirst().dropLast().components(separatedBy: "|")
                result.replaceSubrange(range, with: "{\(options.joined(separator: ","))}")
            }
            return prefix + result
        }
    }
}

/// Expand one or more comma-delimited file paths using glob syntax
public func expandGlobs(_ paths: String, in directory: String) -> [Glob] {
    guard pathContainsGlobSyntax(paths) else {
        return parseCommaDelimitedList(paths).map {
            .path(expandPath($0, in: directory).path)
        }
    }
    var paths = paths
    var tokens = [String: String]()
    while let range = paths.range(of: "\\{[^}]+\\}", options: .regularExpression) {
        let options = paths[range].dropFirst().dropLast()
            .replacingOccurrences(of: "[.+(){\\\\|]", with: "\\\\$0", options: .regularExpression)
            .components(separatedBy: ",")
        let token = "<<<\(tokens.count)>>>"
        tokens[token] = "(\(options.joined(separator: "|")))"
        paths.replaceSubrange(range, with: token)
    }
    return parseCommaDelimitedList(paths).map { path -> Glob in
        let path = expandPath(path, in: directory).path
        if FileManager.default.fileExists(atPath: path) {
            // TODO: should we also handle cases where path includes tokens?
            return .path(path)
        }
        var prefix = "", regex = ""
        let parts = path.components(separatedBy: "/")
        for (i, part) in parts.enumerated() {
            if pathContainsGlobSyntax(part) || part.contains("<<<") {
                regex = parts[i...].joined(separator: "/")
                break
            }
            prefix += "\(part)/"
        }
        regex = "^\(regex)$"
            .replacingOccurrences(of: "[.+(){\\\\|]", with: "\\\\$0", options: .regularExpression)
            .replacingOccurrences(of: "?", with: "[^/]")
            .replacingOccurrences(of: "**/", with: "(.+/)?")
            .replacingOccurrences(of: "**", with: ".+")
            .replacingOccurrences(of: "*", with: "([^/]+)?")
        for (token, replacement) in tokens {
            regex = regex.replacingOccurrences(of: token, with: replacement)
        }
        return try! .regex(prefix, NSRegularExpression(pattern: regex, options: []))
    }
}

func matchGlobs(_ globs: [Glob], in directory: String) throws -> [URL] {
    var urls = [URL]()
    let keys: [URLResourceKey] = [.isDirectoryKey]
    let manager = FileManager.default
    func enumerate(_ directory: URL, with glob: Glob) {
        guard let files = try? manager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: keys, options: []
        ) else {
            return
        }
        for url in files {
            let path = url.path
            var isDirectory: ObjCBool = false
            if glob.matches(path) {
                urls.append(url)
            } else if manager.fileExists(atPath: path, isDirectory: &isDirectory),
                      isDirectory.boolValue
            {
                enumerate(url, with: glob)
            }
        }
    }
    for glob in globs {
        switch glob {
        case let .path(path):
            if manager.fileExists(atPath: path) {
                urls.append(URL(fileURLWithPath: path))
            } else {
                throw FormatError.options("File not found at \(glob)")
            }
        case let .regex(path, _):
            let count = urls.count
            if directory.hasPrefix(path) {
                enumerate(URL(fileURLWithPath: directory).standardized, with: glob)
            } else if path.hasPrefix(directory) {
                enumerate(URL(fileURLWithPath: path).standardized, with: glob)
            }
            if count == urls.count {
                throw FormatError.options("Glob did not match any files at \(glob)")
            }
        }
    }
    return urls
}
