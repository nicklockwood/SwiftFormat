//
//  SwiftFormat.swift
//  SwiftFormat
//
//  Version 0.18
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import Foundation

/// Errors
public enum FormatError: Error, CustomStringConvertible {
    case reading(String)
    case writing(String)
    case parsing(String)
    case options(String)

    public var description: String {
        switch self {
        case .reading(let string),
             .writing(let string),
             .parsing(let string),
             .options(let string):
            return string
        }
    }
}

/// The current SwiftFormat version
public let version = "0.18"

/// Enumerate all swift files at the specified location and (optionally) calculate an output file URL for each
public func enumerateSwiftFiles(withInputURL inputURL: URL, outputURL: URL? = nil, block: (URL, URL) throws -> Void) throws {
    let manager = FileManager.default
    let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
    var isDirectory: ObjCBool = false
    if manager.fileExists(atPath: inputURL.path, isDirectory: &isDirectory) {
        if isDirectory.boolValue {
            guard let files = try? manager.contentsOfDirectory(
                at: inputURL, includingPropertiesForKeys: keys, options: .skipsHiddenFiles) else {
                throw FormatError.reading("failed to read contents of directory at: \(inputURL.path)")
            }
            for url in files {
                do {
                    let resourceValues = try url.resourceValues(forKeys: Set(keys))
                    if resourceValues.isRegularFile != true && resourceValues.isDirectory != true {
                        // Not a regular file or directory
                        continue
                    }
                } catch {
                    throw FormatError.reading("failed to read attributes for file: \(url.path)")
                }
                let outputURL = outputURL.map {
                    URL(fileURLWithPath: $0.path + url.path.substring(from: inputURL.path.characters.endIndex))
                }
                try enumerateSwiftFiles(withInputURL: url, outputURL: outputURL, block: block)
            }
        } else if inputURL.pathExtension == "swift" {
            try block(inputURL, outputURL ?? inputURL)
        }
    } else {
        throw FormatError.reading("file not found: \(inputURL.path)")
    }
}

/// Process token error
public func parsingError(for tokens: [Token]) -> FormatError? {
    if let last = tokens.last, case .error(let string) = last {
        // TODO: more useful errors
        if string.isEmpty {
            return .parsing("unexpected end of file")
        } else {
            return .parsing("unexpected token '\(string)'")
        }
    }
    return nil
}

/// Format a pre-parsed token array
public func format(_ tokens: [Token],
                   rules: [FormatRule] = FormatRules.default,
                   options: FormatOptions = FormatOptions()) throws -> String {
    // Parse
    if !options.fragment, let error = parsingError(for: tokens) {
        throw error
    }

    // Format
    let formatter = Formatter(tokens, options: options)
    rules.forEach { $0(formatter) }

    // Output
    var output = ""
    for token in formatter.tokens { output += token.string }
    return output
}

/// Format code with specified rules and options
public func format(_ source: String,
                   rules: [FormatRule] = FormatRules.default,
                   options: FormatOptions = FormatOptions()) throws -> String {

    return try format(tokenize(source), rules: rules, options: options)
}

// MARK: Internal APIs used by CLI - included here for testing purposes

func inferOptions(from inputURL: URL) throws -> (Int, FormatOptions) {
    var tokens = [Token]()
    var filesChecked = 0
    try enumerateSwiftFiles(withInputURL: inputURL) { inputURL, _ in
        let input = try String(contentsOf: inputURL)
        let _tokens = tokenize(input)
        if let error = parsingError(for: _tokens) {
            throw error
        }
        filesChecked += 1
        tokens += _tokens
    }
    return (filesChecked, inferOptions(tokens))
}

func processInput(_ inputURLs: [URL], andWriteToOutput outputURL: URL? = nil,
                  withRules rules: [FormatRule], options: FormatOptions, cacheURL: URL? = nil) throws -> (Int, Int) {
    // Load cache
    let cachePrefix = version + String(describing: options)
    let cacheDirectory = cacheURL?.deletingLastPathComponent().absoluteURL
    var cache: [String: String]?
    if let cacheURL = cacheURL {
        cache = NSDictionary(contentsOf: cacheURL) as? [String: String] ?? [:]
    }
    // Format files
    var filesChecked = 0, filesWritten = 0
    for inputURL in inputURLs {
        try enumerateSwiftFiles(withInputURL: inputURL, outputURL: outputURL) { inputURL, outputURL in
            filesChecked += 1
            let cacheKey: String = {
                var path = inputURL.absoluteURL.path
                if let cacheDirectory = cacheDirectory {
                    let commonPrefix = path.commonPrefix(with: cacheDirectory.path)
                    path = path.substring(from: commonPrefix.endIndex)
                }
                return path
            }()
            if let input = try? String(contentsOf: inputURL) {
                let output: String
                if cache?[cacheKey] == cachePrefix + String(input.characters.count) {
                    output = input
                } else {
                    output = try format(input, rules: rules, options: options)
                }
                if outputURL != inputURL {
                    if (try? String(contentsOf: outputURL)) == output {
                        // Destination file is already the same as output
                        return
                    }
                    do {
                        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                                                withIntermediateDirectories: true,
                                                                attributes: nil)
                    } catch {
                        throw FormatError.writing("failed to create directory at: \(outputURL.path), \(error)")
                    }
                } else if output == input {
                    // No changes needed
                    return
                }
                do {
                    try output.write(to: outputURL, atomically: true, encoding: String.Encoding.utf8)
                    filesWritten += 1
                    cache?[cacheKey] = cachePrefix + String(output.characters.count)
                } catch {
                    throw FormatError.writing("failed to write file: \(outputURL.path), \(error)")
                }
            } else {
                throw FormatError.reading("failed to read file: \(inputURL.path)")
            }
        }
    }
    // Save cache
    if let cache = cache, let cacheURL = cacheURL, let cacheDirectory = cacheDirectory {
        if !(cache as NSDictionary).write(to: cacheURL, atomically: true) {
            if FileManager.default.fileExists(atPath: cacheDirectory.path) {
                throw FormatError.writing("failed to write cache file at: \(cacheURL.path)")
            } else {
                throw FormatError.reading("specified cache file directory does not exist: \(cacheDirectory.path)")
            }
        }
    }
    return (filesWritten, filesChecked)
}

func preprocessArguments(_ args: [String], _ names: [String]) throws -> [String: String] {
    var anonymousArgs = 0
    var namedArgs: [String: String] = [:]
    var name = ""
    for arg in args {
        if arg.hasPrefix("--") {
            // Long argument names
            let key = arg.substring(from: arg.characters.index(arg.startIndex, offsetBy: 2))
            if !names.contains(key) {
                throw FormatError.options("unknown argument: \(arg).")
            }
            name = key
            namedArgs[name] = ""
            continue
        } else if arg.hasPrefix("-") {
            // Short argument names
            let flag = arg.substring(from: arg.characters.index(arg.startIndex, offsetBy: 1))
            let matches = names.filter { $0.hasPrefix(flag) }
            if matches.count > 1 {
                throw FormatError.options("ambiguous argument: \(arg).")
            } else if matches.count == 0 {
                throw FormatError.options("unknown argument: \(arg).")
            } else {
                name = matches[0]
                namedArgs[name] = ""
            }
            continue
        }
        if name == "" {
            // Argument is anonymous
            name = String(anonymousArgs)
            anonymousArgs += 1
        }
        namedArgs[name] = arg
        name = ""
    }
    return namedArgs
}

func commandLineArguments(for options: FormatOptions) -> [String: String] {
    var args = [String: String]()
    for child in Mirror(reflecting: options).children {
        if let label = child.label {
            switch label {
            case "indent":
                if options.indent == "\t" {
                    args["indent"] = "tabs"
                } else {
                    args["indent"] = String(options.indent.characters.count)
                }
            case "linebreak":
                switch options.linebreak {
                case "\r":
                    args["linebreaks"] = "cr"
                case "\n":
                    args["linebreaks"] = "lf"
                case "\r\n":
                    args["linebreaks"] = "crlf"
                default:
                    break
                }
            case "allowInlineSemicolons":
                args["semicolons"] = options.allowInlineSemicolons ? "inline" : "never"
            case "spaceAroundRangeOperators":
                args["ranges"] = options.spaceAroundRangeOperators ? "spaced" : "nospace"
            case "useVoid":
                args["empty"] = options.useVoid ? "void" : "tuples"
            case "trailingCommas":
                args["commas"] = options.trailingCommas ? "always" : "inline"
            case "indentComments":
                args["comments"] = options.indentComments ? "indent" : "ignore"
            case "truncateBlankLines":
                args["trimwhitespace"] = options.truncateBlankLines ? "always" : "nonblank-lines"
            case "insertBlankLines":
                args["insertlines"] = options.insertBlankLines ? "enabled" : "disabled"
            case "removeBlankLines":
                args["removelines"] = options.removeBlankLines ? "enabled" : "disabled"
            case "allmanBraces":
                args["allman"] = options.allmanBraces ? "true" : "false"
            case "stripHeader":
                args["header"] = options.stripHeader ? "strip" : "ignore"
            case "ifdefIndent":
                args["ifdef"] = options.ifdefIndent.rawValue
            case "wrapArguments":
                args["wraparguments"] = options.wrapArguments.rawValue
            case "wrapElements":
                args["wrapelements"] = options.wrapElements.rawValue
            case "uppercaseHex":
                args["hexliterals"] = options.uppercaseHex ? "uppercase" : "lowercase"
            case "experimentalRules":
                args["experimental"] = options.experimentalRules ? "enabled" : nil
            case "fragment":
                args["fragment"] = options.fragment ? "true" : nil
            default:
                assertionFailure("Unknown option: \(label)")
            }
        }
    }
    return args
}

let commandLineArguments = [
    "output",
    "inferoptions",
    "indent",
    "allman",
    "linebreaks",
    "semicolons",
    "commas",
    "comments",
    "ranges",
    "empty",
    "trimwhitespace",
    "insertlines",
    "removelines",
    "header",
    "ifdef",
    "wraparguments",
    "wrapelements",
    "hexliterals",
    "experimental",
    "fragment",
    "cache",
    "disable",
    "rules",
    "help",
    "version",
]
