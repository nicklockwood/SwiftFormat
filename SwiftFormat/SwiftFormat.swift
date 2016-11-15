//
//  SwiftFormat.swift
//  SwiftFormat
//
//  Version 0.17.2
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
public let version = "0.17.2"

/// Enumerate all swift files at the specified location and (optionally) calculate an output file URL for each
public func enumerateSwiftFiles(withInputURL inputURL: URL, outputURL: URL? = nil, block: (URL, URL) -> Void) {
    let manager = FileManager.default
    var isDirectory: ObjCBool = false
    if manager.fileExists(atPath: inputURL.path, isDirectory: &isDirectory) {
        if isDirectory.boolValue {
            guard let files = try? manager.contentsOfDirectory(
                at: inputURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
                print("error: failed to read contents of directory at: \(inputURL.path)")
                return
            }
            if let outputURL = outputURL {
                do {
                    try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                    for url in files {
                        let outputPath = outputURL.path + url.path.substring(from: inputURL.path.characters.endIndex)
                        enumerateSwiftFiles(withInputURL: url, outputURL: URL(fileURLWithPath: outputPath), block: block)
                    }
                } catch {
                    print("error: failed to create directory at: \(outputURL.path), \(error)")
                    return
                }
            } else {
                for url in files {
                    enumerateSwiftFiles(withInputURL: url, block: block)
                }
            }
        } else if inputURL.pathExtension == "swift" {
            block(inputURL, outputURL ?? inputURL)
        }
    } else {
        print("error: file not found: \(inputURL.path)")
    }
}

/// Format a pre-parsed token array
public func format(_ tokens: [Token],
                   rules: [FormatRule] = defaultRules,
                   options: FormatOptions = FormatOptions()) throws -> String {

    // Parse
    guard options.fragment || tokens.last?.isError == false else {
        // TODO: more useful errors
        throw NSError(domain: "SwiftFormat", code: 0, userInfo: nil)
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
                   rules: [FormatRule] = defaultRules,
                   options: FormatOptions = FormatOptions()) throws -> String {

    return try format(tokenize(source), rules: rules, options: options)
}

// MARK: Internal APIs used by CLI - included here for testing purposes

func inferOptions(from inputURL: URL) -> (Int, FormatOptions) {
    var tokens = [Token]()
    var filesChecked = 0
    enumerateSwiftFiles(withInputURL: inputURL) { inputURL, _ in
        if let input = try? String(contentsOf: inputURL) {
            let _tokens = tokenize(input)
            if _tokens.last?.isError == false {
                filesChecked += 1
                tokens += _tokens
            } else {
                print("error: could not parse file: \(inputURL.path)")
            }
        } else {
            print("error: failed to read file: \(inputURL.path)")
        }
    }
    return (filesChecked, inferOptions(tokens))
}

func processInput(_ inputURLs: [URL], andWriteToOutput outputURL: URL? = nil,
                  withOptions options: FormatOptions, cacheURL: URL? = nil) -> (Int, Int) {
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
        enumerateSwiftFiles(withInputURL: inputURL, outputURL: outputURL) { inputURL, outputURL in
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
                if cache?[cacheKey] == cachePrefix + String(input.characters.count) {
                    // No changes needed
                    return
                }
                guard let output = try? format(input, options: options) else {
                    print("error: could not parse file: \(inputURL.path)")
                    return
                }
                if output != input {
                    if (try? output.write(to: outputURL, atomically: true, encoding: String.Encoding.utf8)) != nil {
                        filesWritten += 1
                    } else {
                        print("error: failed to write file: \(outputURL.path)")
                        return
                    }
                }
                cache?[cacheKey] = cachePrefix + String(output.characters.count)
            } else {
                print("error: failed to read file: \(inputURL.path)")
            }
        }
    }
    // Save cache
    if let cache = cache, let cacheURL = cacheURL, let cacheDirectory = cacheDirectory {
        if !(cache as NSDictionary).write(to: cacheURL, atomically: true) {
            if FileManager.default.fileExists(atPath: cacheDirectory.path) {
                print("error: failed to write cache file at: \(cacheURL.path)")
            } else {
                print("error: specified cache file directory does not exist: \(cacheDirectory.path)")
            }
        }
    }
    return (filesWritten, filesChecked)
}

func preprocessArguments(_ args: [String], _ names: [String]) -> [String: String]? {
    var anonymousArgs = 0
    var namedArgs: [String: String] = [:]
    var name = ""
    for arg in args {
        if arg.hasPrefix("--") {
            // Long argument names
            let key = arg.substring(from: arg.characters.index(arg.startIndex, offsetBy: 2))
            if !names.contains(key) {
                print("error: unknown argument: \(arg).")
                return nil
            }
            name = key
            namedArgs[name] = ""
            continue
        } else if arg.hasPrefix("-") {
            // Short argument names
            let flag = arg.substring(from: arg.characters.index(arg.startIndex, offsetBy: 1))
            let matches = names.filter { $0.hasPrefix(flag) }
            if matches.count > 1 {
                print("error: ambiguous argument: \(arg).")
                return nil
            } else if matches.count == 0 {
                print("error: unknown argument: \(arg).")
                return nil
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
            case "ifdefIndentMode":
                args["ifdef"] = options.ifdefIndentMode.rawValue
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
    "experimental",
    "fragment",
    "cache",
    "help",
    "version",
]
