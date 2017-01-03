//
//  SwiftFormat.swift
//  SwiftFormat
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

/// The current SwiftFormat version
public let version = "0.22"

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

/// File enumeration options
public struct FileOptions {
    public var followSymlinks: Bool = false
    public var supportedFileExtensions = ["swift"]
}

/// Enumerate all swift files at the specified location and (optionally) calculate an output file URL for each
public func enumerateSwiftFiles(withInputURL inputURL: URL,
                                outputURL: URL? = nil,
                                options: FileOptions = FileOptions(),
                                block: (URL, URL) throws -> Void) throws {

    let manager = FileManager.default
    let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isAliasFileKey, .isSymbolicLinkKey]
    do {
        let resourceValues = try inputURL.resourceValues(forKeys: Set(keys))
        if resourceValues.isRegularFile == true {
            if options.supportedFileExtensions.contains(inputURL.pathExtension) {
                try block(inputURL, outputURL ?? inputURL)
            }
        } else if resourceValues.isDirectory == true {
            guard let files = try? manager.contentsOfDirectory(
                at: inputURL, includingPropertiesForKeys: keys, options: .skipsHiddenFiles) else {
                throw FormatError.reading("failed to read contents of directory at: \(inputURL.path)")
            }
            for url in files {
                let outputURL = outputURL.map {
                    URL(fileURLWithPath: $0.path + url.path.substring(from: inputURL.path.characters.endIndex))
                }
                try enumerateSwiftFiles(withInputURL: url, outputURL: outputURL, options: options, block: block)
            }
        } else if options.followSymlinks &&
            (resourceValues.isSymbolicLink == true || resourceValues.isAliasFile == true) {
            let resolvedURL = inputURL.resolvingSymlinksInPath()
            try enumerateSwiftFiles(
                withInputURL: resolvedURL, outputURL: outputURL, options: options, block: block)
        }
    } catch {
        if manager.fileExists(atPath: inputURL.path) {
            throw FormatError.reading("failed to read attributes for: \(inputURL.path)")
        } else {
            throw FormatError.reading("file not found: \(inputURL.path)")
        }
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

/// Convert a token array back into a string
public func sourceCode(for tokens: [Token]) -> String {
    var output = ""
    for token in tokens { output += token.string }
    return output
}

/// Format a pre-parsed token array
/// Returns the formatted token array, and the number of edits made
public func format(_ tokens: [Token],
                   rules: [FormatRule] = FormatRules.default,
                   options: FormatOptions = FormatOptions()) throws -> [Token] {
    // Parse
    if !options.fragment, let error = parsingError(for: tokens) {
        throw error
    }

    // Recursively apply rules until no changes are detected
    var tokens = tokens
    let formatter = Formatter(tokens, options: options)
    repeat {
        tokens = formatter.tokens
        rules.forEach { $0(formatter) }
    } while tokens != formatter.tokens

    // Output
    return tokens
}

/// Format code with specified rules and options
public func format(_ source: String,
                   rules: [FormatRule] = FormatRules.default,
                   options: FormatOptions = FormatOptions()) throws -> String {

    return sourceCode(for: try format(tokenize(source), rules: rules, options: options))
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
    return (filesChecked, inferOptions(from: tokens))
}

func processInput(_ inputURLs: [URL],
                  andWriteToOutput outputURL: URL? = nil,
                  withRules rules: [FormatRule],
                  formatOptions: FormatOptions,
                  fileOptions: FileOptions,
                  cacheURL: URL? = nil) throws -> (Int, Int) {

    // Load cache
    let cachePrefix = "\(version);\(formatOptions)"
    let cacheDirectory = cacheURL?.deletingLastPathComponent().absoluteURL
    var cache: [String: String]?
    if let cacheURL = cacheURL {
        cache = NSDictionary(contentsOf: cacheURL) as? [String: String] ?? [:]
    }
    // Format files
    var filesChecked = 0, filesWritten = 0
    for inputURL in inputURLs {
        guard let resourceValues = try? inputURL.resourceValues(
            forKeys: Set([.isDirectoryKey, .isAliasFileKey, .isSymbolicLinkKey])) else {
            throw FormatError.reading("failed to read attributes for: \(inputURL.path)")
        }
        if !fileOptions.followSymlinks &&
            (resourceValues.isAliasFile == true || resourceValues.isSymbolicLink == true) {
            throw FormatError.options("cannot format symbolic link or alias file: \(inputURL.path)")
        } else if resourceValues.isDirectory == false &&
            !fileOptions.supportedFileExtensions.contains(inputURL.pathExtension) {
            throw FormatError.options("cannot format non-Swift file: \(inputURL.path)")
        }
        try enumerateSwiftFiles(withInputURL: inputURL, outputURL: outputURL, options: fileOptions) {
            inputURL, outputURL in
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
                    output = try format(input, rules: rules, options: formatOptions)
                    cache?[cacheKey] = cachePrefix + String(output.characters.count)
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
                } catch {
                    throw FormatError.writing("failed to write file: \(outputURL.path), \(error)")
                }
            } else {
                throw FormatError.reading("failed to read file: \(inputURL.path)")
            }
        }
    }
    if filesChecked == 0 {
        let inputPaths = inputURLs.map({ $0.path }).joined(separator: ", ")
        throw FormatError.options("no eligible files found at: \(inputPaths)")
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

private func processOption(_ key: String, in args: [String: String], handler: (String) throws -> Void) throws {
    precondition(commandLineArguments.contains(key))
    guard let value = args[key] else {
        return
    }
    guard !value.isEmpty else {
        throw FormatError.options("--\(key) option expects a value.")
    }
    do {
        try handler(value.lowercased())
    } catch {
        throw FormatError.options("unsupported --\(key) value: \(value).")
    }
}

func fileOptionsFor(_ args: [String: String]) throws -> FileOptions {
    var options = FileOptions()
    try processOption("symlinks", in: args) {
        switch $0 {
        case "follow":
            options.followSymlinks = true
        case "ignore":
            options.followSymlinks = false
        default:
            throw FormatError.options("")
        }
    }
    return options
}

func formatOptionsFor(_ args: [String: String]) throws -> FormatOptions {
    var options = FormatOptions()
    try processOption("indent", in: args) {
        switch $0 {
        case "tab", "tabs", "tabbed":
            options.indent = "\t"
        default:
            if let spaces = Int($0) {
                options.indent = String(repeating: " ", count: spaces)
                break
            }
            throw FormatError.options("")
        }
    }
    try processOption("allman", in: args) {
        switch $0 {
        case "true", "enabled":
            options.allmanBraces = true
        case "false", "disabled":
            options.allmanBraces = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("semicolons", in: args) {
        switch $0 {
        case "inline":
            options.allowInlineSemicolons = true
        case "never", "false":
            options.allowInlineSemicolons = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("commas", in: args) {
        switch $0 {
        case "always", "true":
            options.trailingCommas = true
        case "inline", "false":
            options.trailingCommas = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("comments", in: args) {
        switch $0 {
        case "indent", "indented":
            options.indentComments = true
        case "ignore":
            options.indentComments = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("linebreaks", in: args) {
        switch $0 {
        case "cr":
            options.linebreak = "\r"
        case "lf":
            options.linebreak = "\n"
        case "crlf":
            options.linebreak = "\r\n"
        default:
            throw FormatError.options("")
        }
    }
    try processOption("ranges", in: args) {
        switch $0 {
        case "space", "spaced", "spaces":
            options.spaceAroundRangeOperators = true
        case "nospace":
            options.spaceAroundRangeOperators = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("empty", in: args) {
        switch $0 {
        case "void":
            options.useVoid = true
        case "tuple", "tuples":
            options.useVoid = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("trimwhitespace", in: args) {
        switch $0 {
        case "always":
            options.truncateBlankLines = true
        case "nonblank-lines", "nonblank", "non-blank-lines", "non-blank",
             "nonempty-lines", "nonempty", "non-empty-lines", "non-empty":
            options.truncateBlankLines = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("insertlines", in: args) {
        switch $0 {
        case "enabled", "true":
            options.insertBlankLines = true
        case "disabled", "false":
            options.insertBlankLines = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("removelines", in: args) {
        switch $0 {
        case "enabled", "true":
            options.removeBlankLines = true
        case "disabled", "false":
            options.removeBlankLines = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("header", in: args) {
        switch $0 {
        case "strip":
            options.stripHeader = true
        case "ignore":
            options.stripHeader = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("ifdef", in: args) {
        if let mode = IndentMode(rawValue: $0) {
            options.ifdefIndent = mode
        } else {
            throw FormatError.options("")
        }
    }
    try processOption("wraparguments", in: args) {
        if let mode = WrapMode(rawValue: $0) {
            options.wrapArguments = mode
        } else {
            throw FormatError.options("")
        }
    }
    try processOption("wrapelements", in: args) {
        if let mode = WrapMode(rawValue: $0) {
            options.wrapElements = mode
        } else {
            throw FormatError.options("")
        }
    }
    try processOption("hexliterals", in: args) {
        switch $0 {
        case "uppercase", "upper":
            options.uppercaseHex = true
        case "lowercase", "lower":
            options.uppercaseHex = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("experimental", in: args) {
        switch $0 {
        case "enabled", "true":
            options.experimentalRules = true
        case "disabled", "false":
            options.experimentalRules = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("fragment", in: args) {
        switch $0 {
        case "true", "enabled":
            options.fragment = true
        case "false", "disabled":
            options.fragment = false
        default:
            throw FormatError.options("")
        }
    }
    return options
}

let commandLineArguments = [
    // File options
    "symlinks",
    // Format options
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
