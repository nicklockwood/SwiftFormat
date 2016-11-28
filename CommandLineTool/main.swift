//
//  main.swift
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

func showHelp() {
    print("")
    print("swiftformat, version \(version)")
    print("copyright (c) 2016 Nick Lockwood")
    print("")
    print("usage: swiftformat [<file> ...] [--output path] [--indent spaces] [...]")
    print("")
    print(" <file> ...        input file(s) or directory path(s)")
    print(" --output          output path for formatted file(s) (defaults to input path)")
    print(" --symlinks        how symlinks are handled. \"follow\" or \"ignore\" (default)")
    print(" --fragment        input is part of a larger file. \"true\" or \"false\" (default)")
    print(" --cache           path to cache file, or \"clear\" or \"ignore\" the default cache")
    print("")
    print(" --inferoptions    path to file or directory from which to infer formatting options")
    print(" --disable         a comma-delimited list of format rules that should be disabled")
    print("")
    print(" --rules           prints the list of all format rules")
    print(" --help            print this help page")
    print(" --version         prints version information")
    print("")
    print(" --indent          number of spaces to indent, or \"tab\" to use tabs")
    print(" --allman          use allman indentation style \"true\" or \"false\" (default)")
    print(" --linebreaks      linebreak character to use. \"cr\", \"crlf\" or \"lf\" (default)")
    print(" --semicolons      allow semicolons. \"never\" or \"inline\" (default)")
    print(" --commas          commas in collection literals. \"always\" (default) or \"inline\"")
    print(" --comments        indenting of comment bodies. \"indent\" (default) or \"ignore\"")
    print(" --ranges          spacing for ranges. \"spaced\" (default) or \"nospace\"")
    print(" --empty           how empty values are represented. \"void\" (default) or \"tuple\"")
    print(" --trimwhitespace  trim trailing space. \"always\" (default) or \"nonblank-lines\"")
    print(" --insertlines     insert blank line after {. \"enabled\" (default) or \"disabled\"")
    print(" --removelines     remove blank line before }. \"enabled\" (default) or \"disabled\"")
    print(" --header          header comments. \"strip\" to remove, or \"ignore\" (default)")
    print(" --ifdef           #if indenting. \"indent\" (default), \"noindent\" or \"outdent\"")
    print(" --wraparguments   wrap function args. \"beforefirst\" or \"disabled\" (default)")
    print(" --wrapelements    wrap array elements. \"beforefirst\" (default) or \"disabled\"")
    print(" --hexliterals     casing for hex literals. \"uppercase\" (default) or \"lowercase\"")
    print(" --experimental    experimental rules. \"enabled\" or \"disabled\" (default)")
    print("")
}

func expandPath(_ path: String) -> URL {
    let path = NSString(string: path).expandingTildeInPath
    let directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return URL(fileURLWithPath: path, relativeTo: directoryURL)
}

func timeEvent(block: () throws -> Void) rethrows -> String {
    let start = CFAbsoluteTimeGetCurrent()
    try block()
    let time = round((CFAbsoluteTimeGetCurrent() - start) * 100) / 100 // round to nearest 10ms
    return String(format: "%gs", time)
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            write(data)
        }
    }
}

func processArguments(_ args: [String]) {
    do {
        // Get options
        let args = try preprocessArguments(args, commandLineArguments)
        let formatOptions = try formatOptionsFor(args)
        let enumerationOptions = try enumerationOptionsFor(args)

        // Version
        if args["rules"] != nil {
            print("")
            for name in FormatRules.byName.keys {
                print(" " + name)
            }
            print("")
            return
        }

        // Show help if requested specifically or if no arguments are passed
        if args["help"] != nil {
            showHelp()
            return
        }

        // Version
        if args["version"] != nil {
            print("swiftformat, version \(version)")
            return
        }

        // Rules
        var rulesByName = FormatRules.byName
        if let names = args["disable"]?.components(separatedBy: ",") {
            for name in names {
                var name = (name as NSString).trimmingCharacters(in: .whitespaces)
                if !rulesByName.keys.contains(name) {
                    throw FormatError.options("unknown rule '\(name)'")
                }
                rulesByName.removeValue(forKey: name)
            }
        }
        let rules = Array(rulesByName.values)

        // Infer options
        if args["inferoptions"] != nil {
            if let inferURL = args["inferoptions"].map({ expandPath($0) }) {
                print("inferring swiftformat options from source file(s)...")
                var files = 0
                var arguments = ""
                let time = try timeEvent {
                    let (count, options) = try inferOptions(from: inferURL)
                    arguments = commandLineArguments(for: options).map({
                        "--\($0) \($1)" }).joined(separator: " ")
                    files = count
                }
                print("options inferred from \(files) file\(files == 1 ? "" : "s") in \(time)")
                print("")
                print(arguments)
                print("")
            } else {
                throw FormatError.options("--inferoptions argument was not a valid path")
            }
            return
        }

        // Get input path(s)
        var inputURLs = [URL]()
        while let inputPath = args[String(inputURLs.count + 1)] {
            inputURLs.append(expandPath(inputPath))
        }

        // Get output path
        let outputURL = args["output"].map { expandPath($0) }
        if outputURL != nil && inputURLs.count > 1 {
            throw FormatError.options("--output argument is only valid for a single input file")
        }

        // Get cache path
        var cacheURL: URL?
        let defaultCacheFileName = "swiftformat.cache"
        let manager = FileManager.default
        func setDefaultCacheURL() throws {
            if let cachePath =
                NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
                let cacheDirectory = URL(fileURLWithPath: cachePath).appendingPathComponent("com.charcoaldesign.swiftformat")
                do {
                    try manager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
                    cacheURL = cacheDirectory.appendingPathComponent(defaultCacheFileName)
                } catch {
                    throw FormatError.writing("failed to create cache directory at: \(cacheDirectory.path)")
                }
            } else {
                throw FormatError.reading("failed to find cache directory at ~/Library/Caches")
            }
        }
        if let cache = args["cache"] {
            switch cache {
            case "":
                throw FormatError.options("--cache option expects a value.")
            case "ignore":
                break
            case "clear":
                try setDefaultCacheURL()
                if let cacheURL = cacheURL, manager.fileExists(atPath: cacheURL.path) {
                    do {
                        try manager.removeItem(at: cacheURL)
                    } catch {
                        throw FormatError.writing("failed to delete cache file at: \(cacheURL.path)")
                    }
                }
            default:
                cacheURL = expandPath(cache)
                guard cacheURL != nil else {
                    throw FormatError.options("unsupported --cache value: \(cache).")
                }
                var isDirectory: ObjCBool = false
                if manager.fileExists(atPath: cacheURL!.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                    cacheURL = cacheURL!.appendingPathComponent(defaultCacheFileName)
                }
            }
        } else {
            try setDefaultCacheURL()
        }

        // If no input file, try stdin
        if inputURLs.count == 0 {
            var input: String?
            var asyncError: Error?
            var finished = false
            DispatchQueue.global(qos: .userInitiated).async {
                while let line = readLine(strippingNewline: false) {
                    input = (input ?? "") + line
                }
                if let input = input {
                    do {
                        let output = try format(input, rules: rules, options: formatOptions)
                        if let outputURL = outputURL {
                            do {
                                try output.write(to: outputURL, atomically: true, encoding: String.Encoding.utf8)
                                print("swiftformat completed successfully")
                            } catch {
                                throw FormatError.writing("failed to write file: \(outputURL.path)")
                            }
                        } else {
                            // Write to stdout
                            print(output)
                        }
                    } catch {
                        asyncError = error
                    }
                }
                finished = true
            }
            // Wait for input
            let start = NSDate()
            while start.timeIntervalSinceNow > -0.01 {}
            // If no input received by now, assume none is coming
            if input != nil {
                while !finished && start.timeIntervalSinceNow > -30 {
                    if let error = asyncError {
                        throw error
                    }
                }
            } else {
                showHelp()
            }
            return
        }

        print("running swiftformat...")

        // Format the code
        var filesWritten = 0, filesChecked = 0
        let time = try timeEvent {
            (filesWritten, filesChecked) = try processInput(
                inputURLs,
                andWriteToOutput: outputURL,
                withRules: rules,
                formatOptions: formatOptions,
                enumerationOptions: enumerationOptions,
                cacheURL: cacheURL
            )
        }
        print("swiftformat completed. \(filesWritten)/\(filesChecked) files updated in \(time)")

    } catch {
        var stderr = FileHandle.standardError
        print("error: \(error)", to: &stderr)
    }
}

// Pass in arguments
processArguments(CommandLine.arguments)
