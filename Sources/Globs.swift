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

    /// Whether a directory can contain a match, without descending into unrelated or deeper trees.
    func canMatchDescendant(of directory: URL) -> Bool {
        guard case let .regex(prefix, regex) = self, directory.path.hasPrefix(prefix) else { return false }
        let components = directory.path.dropFirst(prefix.count).split(separator: "/").map(String.init)
        // Protect the slash in the generated single-component wildcard character class.
        let placeholder = "<<<slash>>>"
        let pattern = regex.pattern.dropFirst().dropLast().replacingOccurrences(of: "[^/]", with: placeholder)
        let segments = pattern.components(separatedBy: "/")
        for (position, component) in components.enumerated() {
            guard segments.indices.contains(position) else { return false }
            let segment = segments[position].replacingOccurrences(of: placeholder, with: "[^/]")
            if segment.contains(".+") {
                return true
            } // A recursive wildcard can consume any remaining path.
            // Slash-containing brace alternatives cannot always be split into independent regexes.
            guard let expression = try? NSRegularExpression(pattern: "^" + segment + "$") else { return true }
            if expression.firstMatch(in: component, range: NSRange(location: 0, length: component.utf16.count)) == nil {
                return false
            }
        }
        return components.count < segments.count
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
public func expandGlobs(_ paths: String, in directory: String, splitOnCommas: Bool = true) -> [Glob] {
    try! parseGlobs(paths, in: directory, splitOnCommas: splitOnCommas)
}

/// Compile glob patterns with recoverable errors for user-supplied manifests.
func parseGlobs(_ paths: String, in directory: String, splitOnCommas: Bool = true) throws -> [Glob] {
    guard pathContainsGlobSyntax(paths) else {
        return (splitOnCommas ? parseCommaDelimitedList(paths) : [paths]).map {
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
    return try (splitOnCommas ? parseCommaDelimitedList(paths) : [paths]).map { path -> Glob in
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
        do {
            return try .regex(prefix, NSRegularExpression(pattern: regex, options: []))
        } catch {
            throw FormatError.options("Invalid glob \(path): \(error.localizedDescription)")
        }
    }
}

func matchGlobs(_ globs: [Glob], in directory: String, includingDirectories: Bool = true, skipUnreadableDirectories: Bool = true) throws -> [URL] {
    var urls = [URL]()
    let keys: [URLResourceKey] = [.isDirectoryKey]
    let manager = FileManager.default
    var ancestors = Set<String>()
    func enumerate(_ directory: URL, with glob: Glob) throws {
        if (try? directory.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true {
            return
        }
        let identity = directory.resolvingSymlinksInPath().standardizedFileURL.path
        guard ancestors.insert(identity).inserted else { return }
        defer { ancestors.remove(identity) }
        let files: [URL]
        do {
            files = try manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys, options: [])
        } catch {
            if skipUnreadableDirectories {
                return
            }
            throw FormatError.reading("Failed to enumerate \(directory.path): \(error.localizedDescription)")
        }
        for file in files {
            // Foundation may resolve a symlink in directory URLs returned by enumeration.
            // Keep paths in the same spelling as the glob's prefix (e.g. /var vs /private/var).
            let url = directory.appendingPathComponent(file.lastPathComponent)
            let path = url.path
            var isDirectory: ObjCBool = false
            _ = manager.fileExists(atPath: path, isDirectory: &isDirectory)
            if glob.matches(path), includingDirectories || !isDirectory.boolValue {
                urls.append(url)
            } else if isDirectory.boolValue {
                let isSymlink = (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true
                if !isSymlink, glob.canMatchDescendant(of: url) {
                    try enumerate(url, with: glob)
                }
            }
        }
    }
    for glob in globs {
        switch glob {
        case let .path(path):
            var isDirectory: ObjCBool = false
            if manager.fileExists(atPath: path, isDirectory: &isDirectory) {
                if includingDirectories || !isDirectory.boolValue {
                    urls.append(URL(fileURLWithPath: path))
                }
            } else {
                throw FormatError.options("File not found at \(glob)")
            }
        case let .regex(path, _):
            let count = urls.count
            if directory.hasPrefix(path) {
                try enumerate(URL(fileURLWithPath: directory).standardized, with: glob)
            } else if path.hasPrefix(directory) {
                try enumerate(URL(fileURLWithPath: path).standardized, with: glob)
            }
            if count == urls.count {
                throw FormatError.options("Glob did not match any files at \(glob)")
            }
        }
    }
    return urls
}
