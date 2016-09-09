//
//  SwiftFormat.swift
//  SwiftFormat
//
//  Version 0.9.2
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

func processInput(inputURL: NSURL, andWriteToOutput outputURL: NSURL, withOptions options: FormatOptions) -> Int {
    let manager = NSFileManager.defaultManager()
    var isDirectory: ObjCBool = false
    if manager.fileExistsAtPath(inputURL.path!, isDirectory: &isDirectory) {
        if isDirectory {
            if let files = try? manager.contentsOfDirectoryAtURL(inputURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles) {
                var filesWritten = 0
                for url in files {
                    if var path = url.path {
                        let inputDirectory = inputURL.path ?? ""
                        let range = inputDirectory.startIndex ..< inputDirectory.endIndex
                        path.replaceRange(range, with: outputURL.path ?? "")
                        let outputDirectory = path.componentsSeparatedByString("/").dropLast().joinWithSeparator("/")
                        if (try? manager.createDirectoryAtPath(outputDirectory, withIntermediateDirectories: true, attributes: nil)) != nil {
                            filesWritten += processInput(url, andWriteToOutput: NSURL(fileURLWithPath: path), withOptions: options)
                        } else {
                            print("error: failed to create directory at: \(outputDirectory)")
                        }
                    }
                }
                return filesWritten
            } else {
                print("error: failed to read contents of directory at: \(inputURL.path!)")
            }
        } else if inputURL.pathExtension == "swift" {
            if let input = try? String(contentsOfURL: inputURL) {
                guard let output = try? format(input, options: options) else {
                    print("error: could not parse file: \(inputURL.path!)")
                    return 0
                }
                if output != input {
                    if (try? output.writeToURL(outputURL, atomically: true, encoding: NSUTF8StringEncoding)) != nil {
                        return 1
                    } else {
                        print("error: failed to write file: \(outputURL.path!)")
                    }
                }
            } else {
                print("error: failed to read file: \(inputURL.path!)")
            }
        }
    } else {
        print("error: file not found: \(inputURL.path!)")
    }
    return 0
}

func preprocessArguments(args: [String], _ names: [String]) -> [String: String]? {
    var quoted = false
    var anonymousArgs = 0
    var namedArgs: [String: String] = [:]
    var name = ""
    for arg in args {
        if arg.hasPrefix("--") {
            // Long argument names
            let key = arg.substringFromIndex(arg.startIndex.advancedBy(2))
            if !names.contains(key) {
                print("error: unknown argument: \(arg).")
                return nil
            }
            name = key
            namedArgs[name] = ""
        } else if arg.hasPrefix("-") {
            // Short argument names
            let flag = arg.substringFromIndex(arg.startIndex.advancedBy(1))
            let matches = names.filter { $0.hasPrefix(flag) }
            if matches.count > 1 {
                print("error: ambiguous argument: -\(flag).")
                return nil
            } else if matches.count == 0 {
                print("error: unknown argument: -\(flag).")
                return nil
            } else {
                name = matches[0]
                namedArgs[name] = ""
            }
        } else {
            if name == "" {
                // Argument is anonymous
                name = String(anonymousArgs)
                anonymousArgs += 1
            }
            // Handle quotes and spaces
            var arg = arg
            var unterminated = false
            if quoted {
                unterminated = true
            } else if arg.hasPrefix("\"") {
                quoted = true
                unterminated = true
                arg = arg.substringFromIndex(arg.startIndex.advancedBy(1))
            } else if arg.hasSuffix("\\") {
                arg = arg.substringToIndex(arg.endIndex.advancedBy(-1))
                unterminated = true
            }
            if quoted {
                arg = arg
                    .stringByReplacingOccurrencesOfString("\\\"", withString: "\"")
                    .stringByReplacingOccurrencesOfString("\\\\", withString: "\\")
                if arg.hasSuffix("\"") {
                    arg = arg.substringToIndex(arg.endIndex.advancedBy(-1))
                    unterminated = false
                    quoted = false
                }
            }
            if unterminated {
                arg = arg + " "
            }
            namedArgs[name] = (namedArgs[name] ?? "") + arg
            if !unterminated {
                name = ""
            }
        }
    }
    return namedArgs
}

/// Format code with specified rules and options
public func format(source: String,
    rules: [FormatRule] = defaultRules,
    options: FormatOptions = FormatOptions()) throws -> String {

    // Parse
    var tokens = tokenize(source)
    guard tokens.last?.type != .Error else {
        // TODO: more useful errors
        throw NSError(domain: "SwiftFormat", code: 0, userInfo: nil)
    }

    // Format
    let formatter = Formatter(tokens, options: options)
    rules.forEach { $0(formatter) }
    tokens = formatter.tokens

    // Output
    return tokens.reduce("", combine: { $0 + $1.string })
}
