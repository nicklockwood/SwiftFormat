//
//  main.swift
//  SwiftFormat
//
//  Version 0.14
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

let version = "0.14"

func showHelp() {
    print("swiftformat, version \(version)")
    print("copyright (c) 2016 Nick Lockwood")
    print("")
    print("usage: swiftformat [<file>] [--output path] [--indent spaces] [...]")
    print("")
    print("  <file>        input file or directory path")
    print("  --output      output path (defaults to input path)")
    print("  --indent      number of spaces to indent, or \"tab\" to use tabs")
    print("  --linebreaks  linebreak character to use. \"cr\", \"crlf\" or \"lf\" (default)")
    print("  --semicolons  allow semicolons. values are \"never\" or \"inline\" (default)")
    print("  --commas      commas in collection literals. \"always\" (default) or \"inline\"")
    print("  --ranges      spacing for ranges. either \"spaced\" (default) or \"nospace\"")
    print("  --empty       how empty values are represented. \"void\" (default) or \"tuple\"")
    print("  --fragment    treat code as only part of file. \"true\" or \"false\" (default)")
    print("  --help        this help page")
    print("  --version     version information")
    print("")
}

func expandPath(_ path: String) -> URL {
    let path = NSString(string: path).expandingTildeInPath
    let directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return URL(fileURLWithPath: path, relativeTo: directoryURL)
}

func optionsForArguments(_ args: [String: String]) throws -> FormatOptions {

    func processOption(_ key: String, handler: (String) throws -> Void) throws {
        guard let value = args[key] else {
            return
        }
        guard !value.isEmpty else {
            print("error: --\(key) option expects a value.")
            throw NSError()
        }
        do {
            try handler(value.lowercased())
        } catch {
            print("error: unsupported --\(key) value: \(value).")
            throw error
        }
    }

    var options = FormatOptions()
    try processOption("indent") {
        switch $0 {
        case "tab", "tabs":
            options.indent = "\t"
        default:
            if let spaces = Int($0) {
                options.indent = String(repeating: " ", count: spaces)
                break
            }
            throw NSError()
        }
    }
    try processOption("semicolons") {
        switch $0 {
        case "inline":
            options.allowInlineSemicolons = true
        case "never":
            options.allowInlineSemicolons = false
        default:
            throw NSError()
        }
    }
    try processOption("commas") {
        switch $0 {
        case "always":
            options.trailingCommas = true
        case "inline":
            options.trailingCommas = false
        default:
            throw NSError()
        }
    }
    try processOption("linebreaks") {
        switch $0 {
        case "cr":
            options.linebreak = "\r"
        case "lf":
            options.linebreak = "\n"
        case "crlf":
            options.linebreak = "\r\n"
        default:
            throw NSError()
        }
    }
    try processOption("ranges") {
        switch $0 {
        case "space", "spaced", "spaces":
            options.spaceAroundRangeOperators = true
        case "nospace":
            options.spaceAroundRangeOperators = false
        default:
            throw NSError()
        }
    }
    try processOption("empty") {
        switch $0 {
        case "void":
            options.useVoid = true
        case "tuple":
            options.useVoid = false
        default:
            throw NSError()
        }
    }
    try processOption("fragment") {
        switch $0 {
        case "true":
            options.fragment = true
        case "false":
            options.fragment = false
        default:
            throw NSError()
        }
    }
    return options
}

func processArguments(_ args: [String]) {
    guard let args = preprocessArguments(args, [
        "output",
        "indent",
        "linebreaks",
        "semicolons",
        "ranges",
        "empty",
        "fragment",
        "help",
        "version",
    ]) else {
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

    // Get input / output paths
    let inputURL = args["1"].map { expandPath($0) }
    let outputURL = (args["output"] ?? args["1"]).map { expandPath($0) }

    // Get options
    guard let options = try? optionsForArguments(args) else {
        return
    }

    // If no input file, try stdin
    if inputURL == nil {
        var input: String?
        var finished = false
        DispatchQueue.global(qos: .userInitiated).async {
            while let line = readLine(strippingNewline: false) {
                input = (input ?? "") + line
            }
            if let input = input {
                guard let output = try? format(input, rules: defaultRules, options: options) else {
                    print("error: could not parse input")
                    finished = true
                    return
                }
                if let outputURL = outputURL {
                    if (try? output.write(to: outputURL, atomically: true, encoding: String.Encoding.utf8)) != nil {
                        print("swiftformat completed successfully")
                    } else {
                        print("error: failed to write file: \(outputURL.path)")
                    }
                } else {
                    // Write to stdout
                    print(output)
                }
            }
            finished = true
        }
        // Wait for input
        let start = NSDate()
        while start.timeIntervalSinceNow > -0.01 {}
        // If no input received by now, assume none is coming
        if input != nil {
            while !finished && start.timeIntervalSinceNow > -30 {}
        } else {
            showHelp()
        }
        return
    }

    print("running swiftformat...")

    // Format the code
    let filesWritten = processInput(inputURL!, andWriteToOutput: outputURL!, withOptions: options)
    print("swiftformat completed. \(filesWritten) file(s) updated.")
}

processArguments(CommandLine.arguments)
