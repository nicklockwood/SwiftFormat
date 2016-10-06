//
//  SwiftFormat.swift
//  SwiftFormat
//
//  Version 0.11.4
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Charcoal Design
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

func processInput(_ inputURL: URL, andWriteToOutput outputURL: URL, withOptions options: FormatOptions) -> Int {
    let manager = FileManager.default
    var isDirectory: ObjCBool = false
    if manager.fileExists(atPath: inputURL.path, isDirectory: &isDirectory) {
        if isDirectory.boolValue {
            if let files = try? manager.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) {
                var filesWritten = 0
                for url in files {
                    let inputDirectory = inputURL.path
                    let path = outputURL.path + url.path.substring(from: inputDirectory.characters.endIndex)
                    let outputDirectory = path.components(separatedBy: "/").dropLast().joined(separator: "/")
                    if (try? manager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)) != nil {
                        filesWritten += processInput(url, andWriteToOutput: URL(fileURLWithPath: path), withOptions: options)
                    } else {
                        print("error: failed to create directory at: \(outputDirectory)")
                    }
                }
                return filesWritten
            } else {
                print("error: failed to read contents of directory at: \(inputURL.path)")
            }
        } else if inputURL.pathExtension == "swift" {
            if let input = try? String(contentsOf: inputURL) {
                guard let output = try? format(input, options: options) else {
                    print("error: could not parse file: \(inputURL.path)")
                    return 0
                }
                if output != input {
                    if (try? output.write(to: outputURL, atomically: true, encoding: String.Encoding.utf8)) != nil {
                        return 1
                    } else {
                        print("error: failed to write file: \(outputURL.path)")
                    }
                }
            } else {
                print("error: failed to read file: \(inputURL.path)")
            }
        }
    } else {
        print("error: file not found: \(inputURL.path)")
    }
    return 0
}

func preprocessArguments(_ args: [String], _ names: [String]) -> [String: String]? {
    var quoted = false
    var anonymousArgs = 0
    var namedArgs: [String: String] = [:]
    var name = ""
    for arg in args {
        // Handle quotes and spaces
        var arg = arg
        var unterminated = false
        // Check for opening quote
        if !quoted && arg.hasPrefix("\"") {
            arg = arg.substring(from: arg.characters.index(arg.startIndex, offsetBy: 1))
            quoted = true
        }
        if quoted {
            // Handle escaped \ and "
            var escaped = false
            var lastCharEscaped = false
            var processedArg = ""
            for c in arg.characters {
                if !escaped && c == "\\" {
                    escaped = true
                } else {
                    processedArg.append(c)
                    lastCharEscaped = escaped
                    escaped = false
                }
            }
            arg = processedArg
            // Check for closing "
            if !lastCharEscaped && arg.hasSuffix("\"") {
                arg = arg.substring(to: arg.characters.index(arg.endIndex, offsetBy: -1))
                quoted = false
            }
            unterminated = quoted
        } else if arg.hasPrefix("--") {
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
        } else if arg.hasSuffix("\\") {
            // Check for trailing \
            arg = arg.substring(to: arg.characters.index(arg.endIndex, offsetBy: -1))
            unterminated = true
        }
        if name == "" {
            // Argument is anonymous
            name = String(anonymousArgs)
            anonymousArgs += 1
        }
        arg = (namedArgs[name] ?? "") + arg
        if unterminated {
            namedArgs[name] = arg + " "
        } else {
            namedArgs[name] = arg
            name = ""
        }
    }
    return namedArgs
}

/// Format code with specified rules and options
public func format(_ source: String,
    rules: [FormatRule] = defaultRules,
    options: FormatOptions = FormatOptions()) throws -> String {

    // Parse
    var tokens = tokenize(source)
    guard options.fragment || tokens.last?.type != .error else {
        // TODO: more useful errors
        throw NSError(domain: "SwiftFormat", code: 0, userInfo: nil)
    }

    // Format
    let formatter = Formatter(tokens, options: options)
    rules.forEach { $0(formatter) }
    tokens = formatter.tokens

    // Output
    return tokens.reduce("", { $0 + $1.string })
}
