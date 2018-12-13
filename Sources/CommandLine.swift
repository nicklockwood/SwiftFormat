//
//  CommandLine.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/01/2017.
//  Copyright 2017 Nick Lockwood
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

/// Public interface for the SwiftFormat command-line functions
public struct CLI {
    /// Output type for printed content
    public enum OutputType {
        case info
        case success
        case error
        case warning
        case content
    }

    /// Output handler - override this to intercept output from the CLI
    public static var print: (String, OutputType) -> Void = { _, _ in
        fatalError("No print hook set")
    }

    /// Input handler - override this to inject input into the CLI
    /// Injected lines should include the terminating newline character
    public static var readLine: () -> String? = {
        Swift.readLine(strippingNewline: false)
    }

    /// Run the CLI with the specified input arguments
    public static func run(in directory: String, with args: [String] = CommandLine.arguments) -> ExitCode {
        return processArguments(args, in: directory)
    }

    /// Run the CLI with the specified input string (this will be parsed into multiple arguments)
    public static func run(in directory: String, with argumentString: String) -> ExitCode {
        return run(in: directory, with: parseArguments(argumentString))
    }
}

private var quietMode = false
private func print(_ message: String, as type: CLI.OutputType = .info) {
    if !quietMode || [.content, .error].contains(type) {
        CLI.print(message, type)
    }
}

private func printWarnings(_ errors: [Error]) {
    for error in errors {
        print("warning: \(error)", as: .warning)
    }
}

// Represents the exit codes to the command line. See `man sysexits` for more information.
public enum ExitCode: Int32 {
    case ok = 0 // EX_OK
    case lintFailure = 1
    case error = 70 // EX_SOFTWARE
}

func printHelp(as type: CLI.OutputType) {
    print("")
    print("""
    swiftformat, version \(version)
    copyright (c) 2016 Nick Lockwood

    --help             print this help page
    --version          print the currently installed swiftformat version

    swiftformat can operate on files & directories, or directly on input from stdin:

    usage: swiftformat [<file> <file> ...] [--inferoptions] [--output path] [...]

    <file> <file> ...  one or more swift files or directory paths to be processed

    --config           path to a configuration file containing rules and options
    --inferoptions     instead of formatting input, use it to infer format options
    --output           output path for formatted file(s) (defaults to input path)
    --exclude          comma-delimited list of ignored paths (supports glob syntax)
    --symlinks         how symlinks are handled. "follow" or "ignore" (default)
    --fragment         input is part of a larger file. "true" or "false" (default)
    --conflictmarkers  merge conflict markers, either "reject" (default) or "ignore"
    --cache            path to cache file, or "clear" or "ignore" the default cache
    --verbose          display detailed formatting output and warnings/errors
    --quiet            disables non-critical output messages and warnings
    --dryrun           run in "dry" mode (without actually changing any files)
    --lint             like --dryrun, but returns an error if formatting is needed

    swiftformat has a number of rules that can be enabled or disabled. by default
    most rules are enabled. use --rules to display all enabled/disabled rules:

    --rules            the list of rules to apply (pass nothing to print all rules)
    --disable          a list of format rules to be disabled (comma-delimited)
    --enable           a list of disabled rules to be re-enabled (comma-delimited)
    --experimental     experimental rules. "enabled" or "disabled" (default)

    swiftformat's rules can be configured using options. a given option may affect
    multiple rules. options have no affect if the related rules have been disabled:

    --allman           use allman indentation style. "true" or "false" (default)
    --binarygrouping   binary grouping,threshold (default: 4,8) or "none", "ignore"
    --commas           commas in collection literals. "always" (default) or "inline"
    --comments         indenting of comment bodies. "indent" (default) or "ignore"
    --closingparen     closing paren position, "balanced" (default) or "same-line"
    --decimalgrouping  decimal grouping,threshold (default: 3,6) or "none", "ignore"
    --elseposition     placement of else/catch. "same-line" (default) or "next-line"
    --empty            how empty values are represented. "void" (default) or "tuple"
    --exponentcase     case of 'e' in numbers. "lowercase" or "uppercase" (default)
    --exponentgrouping group exponent digits, "enabled" or "disabled" (default)
    --fractiongrouping group digits after '.', "enabled" or "disabled" (default)
    --header           header comments. "strip", "ignore", or the text you wish use
    --hexgrouping      hex grouping,threshold (default: 4,8) or "none", "ignore"
    --hexliteralcase   casing for hex literals. "uppercase" (default) or "lowercase"
    --ifdef            #if indenting. "indent" (default), "noindent" or "outdent"
    --indent           number of spaces to indent, or "tab" to use tabs
    --indentcase       indent cases inside a switch. "true" or "false" (default)
    --linebreaks       linebreak character to use. "cr", "crlf" or "lf" (default)
    --octalgrouping    octal grouping,threshold or "none", "ignore". default: 4,8
    --operatorfunc     spacing for operator funcs. "spaced" (default) or "nospace"
    --patternlet       let/var placement in patterns. "hoist" (default) or "inline"
    --ranges           spacing for ranges. "spaced" (default) or "nospace"
    --semicolons       allow semicolons. "never" or "inline" (default)
    --self             use self for member variables. "remove" (default) or "insert"
    --importgrouping   "testable-top", "testable-bottom" or "alphabetized" (default)
    --stripunusedargs  "closure-only", "unnamed-only" or "always" (default)
    --trimwhitespace   trim trailing space. "always" (default) or "nonblank-lines"
    --wraparguments    wrap function args. "beforefirst", "afterfirst", "preserve"
    --wrapcollections  wrap array/dict. "beforefirst", "afterfirst", "preserve"
    """, as: type)
    print("")
}

func timeEvent(block: () throws -> Void) rethrows -> TimeInterval {
    let start = CFAbsoluteTimeGetCurrent()
    try block()
    return CFAbsoluteTimeGetCurrent() - start
}

private func formatTime(_ time: TimeInterval) -> String {
    let time = round(time * 100) / 100 // round to nearest 10ms
    return String(format: "%gs", time)
}

private func serializeOptions(_ options: Options, to outputURL: URL?) throws {
    if let outputURL = outputURL {
        let file = serialize(options: options) + "\n"
        do {
            try file.write(to: outputURL, atomically: true, encoding: .utf8)
        } catch {
            throw FormatError.writing("failed to write options to \(outputURL.path)")
        }
    } else {
        print(serialize(options: options, excludingDefaults: true, separator: " "), as: .content)
        print("")
    }
}

func processArguments(_ args: [String], in directory: String) -> ExitCode {
    var errors = [Error]()
    var verbose = false

    quietMode = false
    defer {
        // Reset quiet mode on exit to prevent side-effects between unit tests
        quietMode = false
    }

    do {
        // Get arguments
        var args = try preprocessArguments(args, commandLineArguments)

        // Quiet mode
        quietMode = (args["quiet"] != nil)

        // Verbose
        verbose = (args["verbose"] != nil)

        // Lint
        let lint = (args["lint"] != nil)

        // Dry run
        let dryrun = lint || (args["dryrun"] != nil)

        // Input path(s)
        var inputURLs = [URL]()
        while let inputPath = args[String(inputURLs.count + 1)] {
            inputURLs += try parsePaths(inputPath, for: "input", in: directory)
        }

        // Warnings
        for warning in warningsForArguments(args) {
            print(warning, as: .warning)
        }

        // Show help
        if args["help"] != nil {
            printHelp(as: .content)
            return .ok
        }

        // Show version
        if args["version"] != nil {
            print("swiftformat, version \(version)", as: .content)
            return .ok
        }

        // Display rules (must be checked before merging config)
        let showRules: Bool = args["rules"].map {
            if $0 == "" {
                args["rules"] = nil
                return true
            }
            return false
        } ?? false

        // Config file
        if let configURL = try args["config"].map({ try parsePath($0, for: "--config", in: directory) }) {
            if args["config"] == "" {
                throw FormatError.options("--config argument expects a value")
            }
            if !FileManager.default.fileExists(atPath: configURL.path) {
                throw FormatError.reading("specified config file does not exist: \(configURL.path)")
            }
            let data: Data
            do {
                data = try Data(contentsOf: configURL)
            } catch let error {
                throw FormatError.reading("failed to read config file at \(configURL.path), \(error)")
            }
            var config = try parseConfigFile(data)
            // Ensure exclude paths in config file are treated as relative to the file itself
            // TODO: find a better way/place to do this
            let directory = configURL.deletingLastPathComponent().path
            if let excluded = config["exclude"].map({ expandGlobs($0, in: directory) }) {
                config["exclude"] = excluded.map { $0.path }.sorted().joined(separator: ",")
            }
            args = try mergeArguments(args, into: config)
        }

        // Options
        let options = try Options(args, in: directory)

        // Show rules
        if showRules {
            print("")
            let rules = options.rules ?? allRules.subtracting(FormatRules.disabledByDefault)
            for name in Array(allRules).sorted() {
                print(" \(name)\(rules.contains(name) ? "" : " (disabled)")", as: .content)
            }
            print("")
            return .ok
        }

        // FormatOption overrides
        var overrides = [String: String]()
        for key in formattingArguments + rulesArguments {
            overrides[key] = args[key]
        }

        // Treat values for arguments that do not take a value as input paths
        func addInputPaths(for argName: String) throws {
            guard let arg = args[argName], !arg.isEmpty else {
                return
            }
            guard inputURLs.isEmpty || "/.,".contains(where: { arg.contains($0) }) else {
                throw FormatError.options("--\(argName) argument does not expect a value")
            }
            inputURLs += try parsePaths(arg, for: "input", in: directory)
        }
        try addInputPaths(for: "quiet")
        try addInputPaths(for: "verbose")
        try addInputPaths(for: "dryrun")
        try addInputPaths(for: "lint")
        try addInputPaths(for: "inferoptions")

        // Output path
        let outputURL = try args["output"].map { try parsePath($0, for: "--output", in: directory) }
        if outputURL != nil {
            if args["output"] == "" {
                throw FormatError.options("--output argument expects a value")
            } else if inputURLs.count > 1 {
                throw FormatError.options("--output argument is only valid for a single input file or directory")
            }
        }

        // Infer options
        if args["inferoptions"] != nil {
            guard args["config"] == nil else {
                throw FormatError.options("--inferoptions option can't be used along with a config file")
            }
            if inputURLs.count > 0 {
                print("inferring swiftformat options from source file(s)...", as: .info)
                var filesParsed = 0, formatOptions = FormatOptions.default, errors = [Error]()
                let fileOptions = options.fileOptions ?? .default
                let time = formatTime(timeEvent {
                    (filesParsed, formatOptions, errors) = inferOptions(from: inputURLs, options: fileOptions)
                })
                printWarnings(errors)
                if filesParsed == 0 {
                    throw FormatError.parsing("failed to to infer options")
                }
                var filesChecked = filesParsed
                for case let error as FormatError in errors {
                    switch error {
                    case .parsing, .reading:
                        filesChecked += 1
                    case .writing:
                        assertionFailure()
                    case .options:
                        break
                    }
                }
                print("options inferred from \(filesParsed)/\(filesChecked) files in \(time)", as: .info)
                print("")
                var options = options
                options.formatOptions = formatOptions
                try serializeOptions(options, to: outputURL)
                return .ok
            }
        }

        // Cache path
        var cacheURL: URL?
        let defaultCacheFileName = "swiftformat.cache"
        let manager = FileManager.default
        func setDefaultCacheURL() {
            if let cachePath =
                NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
                let cacheDirectory = URL(fileURLWithPath: cachePath).appendingPathComponent("com.charcoaldesign.swiftformat")
                do {
                    try manager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
                    cacheURL = cacheDirectory.appendingPathComponent(defaultCacheFileName)
                } catch {
                    errors.append(FormatError.writing("failed to create cache directory at \(cacheDirectory.path)"))
                }
            } else {
                errors.append(FormatError.reading("failed to find cache directory at ~/Library/Caches"))
            }
        }
        if let cache = args["cache"] {
            switch cache {
            case "":
                throw FormatError.options("--cache option expects a value")
            case "ignore":
                break
            case "clear":
                setDefaultCacheURL()
                if let cacheURL = cacheURL, manager.fileExists(atPath: cacheURL.path) {
                    do {
                        try manager.removeItem(at: cacheURL)
                    } catch {
                        errors.append(FormatError.writing("failed to delete cache file at \(cacheURL.path)"))
                    }
                }
            default:
                cacheURL = try parsePath(cache, for: "--cache", in: directory)
                guard cacheURL != nil else {
                    throw FormatError.options("unsupported --cache value `\(cache)`")
                }
                var isDirectory: ObjCBool = false
                if manager.fileExists(atPath: cacheURL!.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                    cacheURL = cacheURL!.appendingPathComponent(defaultCacheFileName)
                }
            }
        } else {
            setDefaultCacheURL()
        }

        func printRunningMessage() {
            print("running swiftformat...", as: .info)
            if lint {
                print("(lint mode - no files will be changed)", as: .info)
            } else if dryrun {
                print("(dryrun mode - no files will be changed)", as: .info)
            }
        }

        // If no input file, try stdin
        if inputURLs.count == 0 {
            var input: String?
            var finished = false
            var fatalError: Error?
            DispatchQueue.global(qos: .userInitiated).async {
                while let line = CLI.readLine() {
                    input = (input ?? "") + line
                }
                if let input = input {
                    do {
                        if args["inferoptions"] != nil {
                            let tokens = tokenize(input)
                            var options = options
                            options.formatOptions = inferFormatOptions(from: tokens)
                            try serializeOptions(options, to: outputURL)
                        } else if let outputURL = outputURL {
                            printRunningMessage()
                            let output = try format(input, options: options, verbose: verbose)
                            if (try? String(contentsOf: outputURL)) != output {
                                if dryrun {
                                    print("would have updated \(outputURL.path)", as: .info)
                                } else {
                                    do {
                                        try output.write(to: outputURL, atomically: true, encoding: .utf8)
                                    } catch {
                                        throw FormatError.writing("failed to write file \(outputURL.path)")
                                    }
                                }
                            }
                            print("swiftformat completed successfully", as: .success)
                        } else {
                            // Write to stdout
                            let output = try format(input, options: options, verbose: false)
                            print(output, as: .content)
                        }
                    } catch {
                        fatalError = error
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
                if let fatalError = fatalError {
                    throw fatalError
                }
            } else if args["inferoptions"] != nil {
                throw FormatError.options("--inferoptions requires one or more input files")
            } else {
                printHelp(as: .info)
            }
            return .ok
        }

        printRunningMessage()

        // Format the code
        var filesWritten = 0, filesFailed = 0, filesChecked = 0
        let time = formatTime(timeEvent {
            var _errors = [Error]()
            (filesWritten, filesFailed, filesChecked, _errors) = processInput(inputURLs,
                                                                              andWriteToOutput: outputURL,
                                                                              options: options,
                                                                              overrides: overrides,
                                                                              verbose: verbose,
                                                                              dryrun: dryrun,
                                                                              cacheURL: cacheURL)
            errors += _errors
        })

        if filesWritten == 0 {
            if filesChecked == 0 {
                if let error = errors.first {
                    errors.removeAll()
                    throw error
                }
                let inputPaths = inputURLs.map({ $0.path }).joined(separator: ", ")
                throw FormatError.options("no eligible files found at \(inputPaths)")
            } else if !dryrun && !errors.isEmpty {
                throw FormatError.options("failed to format any files")
            }
        }
        if verbose {
            print("")
        }
        printWarnings(errors)
        if dryrun {
            let result = "swiftformat completed. \(filesFailed)/\(filesChecked) files would have been updated in \(time)"
            if lint && filesFailed > 0 {
                print(result, as: .error)
                return .lintFailure
            } else {
                print(result, as: .success)
            }
        } else {
            print("swiftformat completed. \(filesWritten)/\(filesChecked) files updated in \(time)", as: .success)
        }
        return .ok
    } catch {
        if !verbose {
            // Warnings would be redundant at this point
            printWarnings(errors)
        }
        // Fatal error
        print("error: \(error)", as: .error)
        return .error
    }
}

func inferOptions(from inputURLs: [URL], options: FileOptions) -> (Int, FormatOptions, [Error]) {
    var tokens = [Token]()
    var errors = [Error]()
    var filesParsed = 0
    let baseOptions = Options(fileOptions: options)
    for inputURL in inputURLs {
        errors += enumerateFiles(withInputURL: inputURL, options: baseOptions) { inputURL, _, _ in
            guard let input = try? String(contentsOf: inputURL) else {
                throw FormatError.reading("failed to read file \(inputURL.path)")
            }
            let _tokens = tokenize(input)
            return {
                filesParsed += 1
                tokens += _tokens
            }
        }
    }
    return (filesParsed, inferFormatOptions(from: tokens), errors)
}

func computeHash(_ source: String) -> String {
    var count = 0
    var hash: UInt64 = 5381
    for byte in source.utf8 {
        count += 1
        hash = 127 &* (hash & 0x00FF_FFFF_FFFF_FFFF) &+ UInt64(byte)
    }
    return "\(count)\(hash)"
}

func format(_ source: String, options: Options, verbose: Bool) throws -> String {
    // Parse source
    let originalTokens = tokenize(source)
    var tokens = originalTokens

    // Get rules
    let rulesByName = FormatRules.byName
    let ruleNames = Array(options.rules ?? allRules.subtracting(FormatRules.disabledByDefault)).sorted()
    let rules = ruleNames.compactMap { rulesByName[$0] }
    var rulesApplied = Set<String>()
    let callback: ((Int, [Token]) -> Void)? = verbose ? { i, updatedTokens in
        if updatedTokens != tokens {
            rulesApplied.insert(ruleNames[i])
            tokens = updatedTokens
        }
    } : nil

    // Apply rules
    let formatOptions = options.formatOptions ?? .default
    tokens = try applyRules(rules, to: tokens, with: formatOptions, callback: callback)

    // Display info
    if verbose {
        if rulesApplied.isEmpty || tokens == originalTokens {
            print(" -- no changes", as: .success)
        } else {
            let sortedNames = Array(rulesApplied).sorted().joined(separator: ", ")
            print(" -- rules applied: \(sortedNames)", as: .success)
        }
    }

    // Output
    return sourceCode(for: tokens)
}

func processInput(_ inputURLs: [URL],
                  andWriteToOutput outputURL: URL?,
                  options: Options,
                  overrides: [String: String],
                  verbose: Bool,
                  dryrun: Bool,
                  cacheURL: URL?) -> (Int, Int, Int, [Error]) {
    // Load cache
    let cacheDirectory = cacheURL?.deletingLastPathComponent().absoluteURL
    var cache: [String: String]?
    if let cacheURL = cacheURL {
        cache = NSDictionary(contentsOf: cacheURL) as? [String: String] ?? [:]
    }
    // Logging skipped files
    let skippedHandler: FileEnumerationHandler? = verbose ? { inputURL, _, _ in
        print("skipping \(inputURL.path)", as: .info)
        print("-- ignored", as: .warning)
        return {}
    } : nil
    // Format files
    var errors = [Error]()
    var filesChecked = 0, filesFailed = 0, filesWritten = 0
    for inputURL in inputURLs {
        errors += enumerateFiles(withInputURL: inputURL,
                                 outputURL: outputURL,
                                 options: options,
                                 concurrent: !verbose,
                                 skipped: skippedHandler) { inputURL, outputURL, options in

            guard let input = try? String(contentsOf: inputURL) else {
                throw FormatError.reading("failed to read file \(inputURL.path)")
            }
            // Override options
            var options = options
            try options.addArguments(overrides, in: "") // No need for directory as overrides are formatOptions only
            // Check cache
            let rules = options.rules ?? allRules.subtracting(FormatRules.disabledByDefault)
            let formatOptions = options.formatOptions ?? .default
            let cachePrefix = "\(version);\(formatOptions)\(rules.joined(separator: ","));"
            let cacheKey: String = {
                var path = inputURL.absoluteURL.path
                if let cacheDirectory = cacheDirectory {
                    let commonPrefix = path.commonPrefix(with: cacheDirectory.path)
                    path = String(path[commonPrefix.endIndex ..< path.endIndex])
                }
                return path
            }()
            do {
                if verbose {
                    print("formatting \(inputURL.path)", as: .info)
                }
                var cacheHash: String?
                var sourceHash: String?
                if let cacheEntry = cache?[cacheKey], cacheEntry.hasPrefix(cachePrefix) {
                    cacheHash = String(cacheEntry[cachePrefix.endIndex...])
                    sourceHash = computeHash(input)
                }
                let output: String
                if let cacheHash = cacheHash, cacheHash == sourceHash {
                    output = input
                    if verbose {
                        print("-- no changes (cached)", as: .success)
                    }
                } else {
                    output = try format(input, options: options, verbose: verbose)
                    if output != input {
                        sourceHash = nil
                    }
                }
                let cacheValue = cache.map { _ in
                    // Only bother computing this if cache is enabled
                    cachePrefix + (sourceHash ?? computeHash(output))
                }
                if outputURL != inputURL, (try? String(contentsOf: outputURL)) != output {
                    if !dryrun {
                        do {
                            try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                                                    withIntermediateDirectories: true,
                                                                    attributes: nil)
                        } catch {
                            throw FormatError.writing("failed to create directory at \(outputURL.path), \(error)")
                        }
                    }
                } else if output == input {
                    // No changes needed
                    return {
                        filesChecked += 1
                        cache?[cacheKey] = cacheValue
                    }
                }
                if dryrun {
                    print("would have updated \(outputURL.path)", as: .info)
                    return {
                        filesChecked += 1
                        filesFailed += 1
                    }
                } else {
                    do {
                        if verbose {
                            print("writing \(outputURL.path)", as: .info)
                        }
                        try output.write(to: outputURL, atomically: true, encoding: .utf8)
                        return {
                            filesChecked += 1
                            filesFailed += 1
                            filesWritten += 1
                            cache?[cacheKey] = cacheValue
                        }
                    } catch {
                        throw FormatError.writing("failed to write file \(outputURL.path), \(error)")
                    }
                }
            } catch {
                if verbose {
                    print("-- error: \(error)", as: .error)
                }
                return {
                    filesChecked += 1
                    if case let FormatError.parsing(string) = error {
                        throw FormatError.parsing("\(string) in \(inputURL.path)")
                    }
                    throw error
                }
            }
        }
    }
    if verbose {
        var errorCount = errors.count
        errors = errors.filter { error in
            guard let error = error as? FormatError else {
                return true
            }
            switch error {
            case .options, .reading:
                return true
            case .parsing, .writing:
                return false
            }
        }
        errorCount -= errors.count
        if errorCount > 0 {
            // Replace individual warnings with a generic message, to avoid repetition
            errors.append(FormatError.writing("\(errorCount) file\(errorCount == 1 ? "" : "s") could not be formatted"))
        }
    }
    if filesChecked > 0 {
        // Save cache
        if let cache = cache, let cacheURL = cacheURL, let cacheDirectory = cacheDirectory {
            if !(cache as NSDictionary).write(to: cacheURL, atomically: true) {
                if FileManager.default.fileExists(atPath: cacheDirectory.path) {
                    errors.append(FormatError.writing("failed to write cache file at \(cacheURL.path)"))
                } else {
                    errors.append(FormatError.reading("specified cache file directory does not exist: \(cacheDirectory.path)"))
                }
            }
        }
    }
    return (filesWritten, filesFailed, filesChecked, errors)
}
