//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

// An error relating to files or file parsing
struct FileError: Error, CustomStringConvertible {
    let message: String
    let file: URL

    public init(_ message: String, for file: URL) {
        self.message = message
        self.file = file
    }

    public init(_ error: Error, for file: URL) {
        let message = (error as NSError).localizedDescription
        self.init(message, for: file)
    }

    public var description: String {
        var description = message
        if !description.contains(file.path) {
            description = "\(description) at \(file.path)"
        }
        return description
    }

    /// Associates error thrown by the wrapped closure with the given path
    static func wrap<T>(_ closure: () throws -> T, for file: URL) throws -> T {
        do {
            return try closure()
        } catch {
            throw self.init(error, for: file)
        }
    }
}

// Name of the Layout ignore file
let layoutIgnoreFile = ".layout-ignore"

// Parses a `.layout-ignore` file and returns the paths as URLs
func parseIgnoreFile(_ file: URL) throws -> [URL] {
    let data = try FileError.wrap({ try Data(contentsOf: file) }, for: file)
    guard let string = String(data: data, encoding: .utf8) else {
        throw FileError("Unable to read \(file.lastPathComponent) file", for: file)
    }
    return parseIgnoreFile(string, baseURL: file.deletingLastPathComponent())
}

func parseIgnoreFile(_ contents: String, baseURL: URL) -> [URL] {
    var paths = [URL]()
    for line in contents.components(separatedBy: .newlines) {
        let line = line
            .replacingOccurrences(of: "\\s*#.*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^\\s*", with: "", options: .regularExpression)
        if !line.isEmpty {
            let path = baseURL.appendingPathComponent(line)
            paths.append(path)
        }
    }
    return paths
}
