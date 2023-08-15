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
public enum CLI {}

public extension CLI {
    /// Output type for printed content
    enum OutputType {
        case info
        case success
        case error
        case warning
        case content
        case raw
    }

    /// Output handler - override this to intercept output from the CLI
    static var print: (String, OutputType) -> Void = { _, _ in
        fatalError("No print hook set.")
    }

    /// Input handler - override this to inject input into the CLI
    /// Injected lines should include the terminating newline character
    static var readLine: () -> String? = {
        Swift.readLine(strippingNewline: false)
    }

    /// Run the CLI with the specified input arguments
    static func run(in directory: String, with args: [String] = CommandLine.arguments) -> ExitCode {
        processArguments(args, environment: ProcessInfo.processInfo.environment, in: directory)
    }

    /// Run the CLI with the specified input string (this will be parsed into multiple arguments)
    static func run(in directory: String, with argumentString: String) -> ExitCode {
        run(in: directory, with: parseArguments(argumentString))
    }
}

private var quietMode = false
private func print(_ message: String, as type: CLI.OutputType = .info) {
    if !quietMode || [.raw, .content, .error].contains(type) {
        CLI.print(message, type)
    }
}

/// Print warnings and return true if any was an actual error
private func printWarnings(_ errors: [Error]) -> Bool {
    var containsError = false
    for error in errors {
        var errorMessage = "\(error)"
        if !".?!".contains(errorMessage.last ?? " ") {
            errorMessage += "."
        }
        let isError: Bool
        switch error as? FormatError {
        case let .writing(string)?:
            isError = !string.contains(" cache ")
        case .parsing?, .reading?, .options?:
            isError = true
        case nil:
            isError = true
            errorMessage = error.localizedDescription
        }
        if isError {
            containsError = true
            print("error: \(errorMessage)", as: .error)
        } else {
            print("warning: \(errorMessage)", as: .warning)
        }
    }
    return containsError
}

/// Represents the exit codes to the command line. See `man sysexits` for more information.
public enum ExitCode: Int32 {
    case ok = 0 // EX_OK
    case lintFailure = 1
    case error = 70 // EX_SOFTWARE
}

func printOptions(as type: CLI.OutputType) {
    print("")
    print(Descriptors.formatting.compactMap {
        guard !$0.isDeprecated else { return nil }
        var result = "--\($0.argumentName)"
        for _ in 0 ..< Options.maxArgumentNameLength + 3 - result.count {
            result += " "
        }
        return result + stripMarkdown($0.help)
    }.sorted().joined(separator: "\n"), as: type)
    print("")
}

func printRuleInfo(for name: String, as type: CLI.OutputType) throws {
    guard let rule = FormatRules.byName[name] else {
        if name.isEmpty {
            throw FormatError.options("--ruleinfo command expects a rule name")
        }
        throw FormatError.options("'\(name)' rule does not exist")
    }
    print("")
    print(name, as: type)
    print("", as: type)
    print(stripMarkdown(rule.help), as: type)
    if let message = rule.deprecationMessage {
        print("", as: type)
        print("Note: \(rule.name) rule is deprecated. \(message)")
        print("")
        return
    }
    if !rule.options.isEmpty {
        print("\nOptions:\n", as: type)
        print(rule.options.compactMap {
            guard let descriptor = Descriptors.byName[$0], !descriptor.isDeprecated else {
                return nil
            }
            var result = "--\(descriptor.argumentName)"
            for _ in 0 ..< 19 - result.count {
                result += " "
            }
            return result + stripMarkdown(descriptor.help)
        }.sorted().joined(separator: "\n"), as: type)
    }
    if var examples = rule.examples {
        examples = examples
            .replacingOccurrences(of: "```diff\n", with: "")
            .replacingOccurrences(of: "```\n", with: "")
        if examples.hasSuffix("```") {
            examples = String(examples.dropLast(3))
        }
        print("\nExamples:\n", as: type)
        print(examples, as: type)
    }
    print("")
}

func printHelp(as type: CLI.OutputType) {
    print("")
    print("""
    SwiftFormat, version \(version)
    Copyright (c) 2016 Nick Lockwood

    --help             Print this help page
    --version          Print the currently installed swiftformat version

    SwiftFormat can operate on files & directories, or directly on input from stdin.

    Usage: swiftformat [<file> <file> ...] [--inferoptions] [--output path] [...]

    <file> <file> ...  Swift files or directories to be processed, or "stdin"

    --filelist         Path to a file with names of files to process, one per line
    --stdinpath        Path to stdin source file (used for generating header)
    --scriptinput      Read Xcode SCRIPT_INPUT_FILE* environment variables as files
    --config           Path to a configuration file containing rules and options
    --baseconfig       Like --config, but local .swiftformat files aren't ignored
    --inferoptions     Instead of formatting input, use it to infer format options
    --output           Output path for formatted file(s) (defaults to input path)
    --exclude          Comma-delimited list of ignored paths (supports glob syntax)
    --unexclude        Paths to not exclude, even if excluded elsewhere in config
    --symlinks         How symlinks are handled: "follow" or "ignore" (default)
    --linerange        Range of lines to process within the input file (first, last)
    --fragment         \(stripMarkdown(Descriptors.fragment.help))
    --conflictmarkers  \(stripMarkdown(Descriptors.ignoreConflictMarkers.help))
    --swiftversion     \(stripMarkdown(Descriptors.swiftVersion.help))
    --minversion       The minimum SwiftFormat version to be used for these files
    --cache            Path to cache file, or "clear" or "ignore" the default cache
    --dryrun           Run in "dry" mode (without actually changing any files)
    --lint             Return an error for unformatted input, and list violations
    --report           Path to a file where --lint output should be written
    --reporter         Report format: \(Reporters.help)
    --lenient          Suppress errors for unformatted code in --lint mode
    --strict           Emit errors for unformatted code when formatting
    --verbose          Display detailed formatting output and warnings/errors
    --quiet            Disables non-critical output messages and warnings

    SwiftFormat has a number of rules that can be enabled or disabled. By default
    most rules are enabled. Use --rules to display all enabled/disabled rules.

    --rules            The list of rules to apply. Pass nothing to print rules list
    --disable          Comma-delimited list of format rules to be disabled, or "all"
    --enable           Comma-delimited list of rules to be enabled, or "all"
    --lintonly         A list of rules to be enabled only when using --lint mode

    SwiftFormat's rules can be configured using options. A given option may affect
    multiple rules. Options have no effect if the related rules have been disabled.

    --ruleinfo         Display options for a given rule or rules (comma-delimited)
    --options          Prints a list of all formatting options and their usage
    """, as: type)
    print("")
}

func timeEvent(block: () throws -> Void) rethrows -> TimeInterval {
    #if os(macOS)
        let start = CFAbsoluteTimeGetCurrent()
        try block()
        return CFAbsoluteTimeGetCurrent() - start
    #else
        let start = Date.timeIntervalSinceReferenceDate
        try block()
        return Date.timeIntervalSinceReferenceDate - start
    #endif
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
            throw FormatError.writing("Failed to write options to \(outputURL.path)")
        }
    } else {
        print(serialize(options: options, excludingDefaults: true, separator: " "), as: .content)
        print("")
    }
}

private func readConfigArg(
    _ name: String,
    with args: inout [String: String],
    in directory: String
) throws -> URL? {
    guard let url = try args[name].map({
        try parsePath($0, for: "--\(name)", in: directory)
    }) else {
        return nil
    }
    if args[name] == "" {
        throw FormatError.options("--\(name) argument expects a value")
    }
    if !FileManager.default.fileExists(atPath: url.path) {
        throw FormatError.reading("Specified config file does not exist: \(url.path)")
    }
    let data: Data
    do {
        data = try Data(contentsOf: url)
    } catch {
        throw FormatError.reading("Failed to read config file at \(url.path), \(error)")
    }
    var config = try parseConfigFile(data)
    // Ensure exclude paths in config file are treated as relative to the file itself
    // TODO: find a better way/place to do this
    let directory = url.deletingLastPathComponent().path
    if let exclude = config["exclude"] {
        let excluded = expandGlobs(exclude, in: directory)
        if excluded.isEmpty {
            print("warning: --exclude value '\(exclude)' did not match any files in \(directory).", as: .warning)
            config["exclude"] = nil
        } else {
            config["exclude"] = excluded.map { $0.description }.sorted().joined(separator: ",")
        }
    }
    if let unexclude = config["unexclude"] {
        let unexcluded = expandGlobs(unexclude, in: directory)
        if unexcluded.isEmpty {
            print("warning: --unexclude value '\(unexclude)' did not match any files in \(directory).", as: .warning)
            config["unexclude"] = nil
        } else {
            config["unexclude"] = unexcluded.map { $0.description }.sorted().joined(separator: ",")
        }
    }
    args = try mergeArguments(args, into: config)
    return url
}

typealias OutputFlags = (
    filesWritten: Int,
    filesChecked: Int,
    filesSkipped: Int,
    filesFailed: Int
)

func processArguments(_ args: [String], environment: [String: String] = [:], in directory: String) -> ExitCode {
    var errors = [Error]()
    var verbose = false
    var lenient = false
    var strict = false

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

        // Lenient
        lenient = (args["lenient"] != nil)

        // Strict
        strict = (args["strict"] != nil)

        // Lint
        let lint = (args["lint"] != nil)

        // Dry run
        let dryrun = lint || (args["dryrun"] != nil)

        // Warnings
        for warning in warningsForArguments(args) {
            print("warning: \(warning)", as: .warning)
        }

        // Reporter
        var reporter: Reporter? = try args["reporter"].map { identifier in
            guard let reporter = Reporters.reporter(
                named: identifier,
                environment: environment
            ) else {
                var message = "'\(identifier)' is not a valid reporter"
                let names = Reporters.all.map { $0.name }
                if let match = identifier.bestMatches(in: names).first {
                    message += "(did you mean '\(match)'?)"
                }
                throw FormatError.options(message)
            }
            return reporter
        }

        // Report URL
        let reportURL: URL? = try args["report"].map { arg in
            let url = try parsePath(arg, for: "--output", in: directory)
            if reporter == nil {
                reporter = Reporters.reporter(for: url, environment: environment)
                guard reporter != nil else {
                    throw FormatError
                        .options("--report requires --reporter to be specified")
                }
            }
            return url
        }

        // Show help
        if args["help"] != nil {
            printHelp(as: .content)
            return .ok
        }

        // Show version
        if args["version"] != nil {
            print(version, as: .content)
            return .ok
        }

        // Show options
        if args["options"] != nil {
            printOptions(as: .content)
            return .ok
        }

        // Show rule info
        if let names = try args["ruleinfo"].map(parseRules) {
            let names = names.isEmpty ? allRules.sorted() : names.sorted()
            for name in names {
                try printRuleInfo(for: name, as: .content)
            }
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
        let configURL = try readConfigArg("config", with: &args, in: directory)

        // FormatOption overrides
        var overrides = [String: String]()
        for key in formattingArguments + rulesArguments {
            overrides[key] = args[key]
        }

        // Base config
        _ = try readConfigArg("baseconfig", with: &args, in: directory)
        _ = try readConfigArg("config", with: &args, in: directory)

        // Options
        var options = try Options(args, in: directory)

        // Show rules
        if showRules {
            print("")
            let rules = options.rules ?? allRules.subtracting(FormatRules.disabledByDefault)
            for name in Array(allRules).sorted() {
                let annotation: String
                if rules.contains(name) {
                    annotation = ""
                } else if FormatRules.byName[name]?.isDeprecated == true {
                    annotation = " (deprecated)"
                } else {
                    annotation = " (disabled)"
                }
                print(" \(name)\(annotation)", as: .content)
            }
            print("")
            return .ok
        }

        // Input path(s)
        var inputURLs = [URL]()
        if let fileListPath = args["filelist"] {
            let fileListURL = try parsePath(fileListPath, for: "filelist", in: directory)
            if !FileManager.default.fileExists(atPath: fileListURL.path) {
                throw FormatError.reading("File not found at \(fileListURL.path)")
            }
            guard let source = try? String(contentsOf: fileListURL) else {
                throw FormatError.options("Failed to read file list at \(fileListPath)")
            }
            inputURLs += try parseFileList(source, in: fileListURL.deletingLastPathComponent().path)
        }
        var useStdin = false
        while let inputPath = args[String(inputURLs.count + 1)] {
            if inputPath.lowercased() == "stdin" {
                useStdin = true
                inputURLs.append(URL(string: "stdin")!)
            } else {
                inputURLs += try parsePaths(inputPath, in: directory)
            }
        }
        if useStdin {
            if inputURLs.count > 1 {
                if args["filelist"] != nil {
                    throw FormatError.options("--filelist option cannot be combined with stdin input")
                }
                throw FormatError.options("Cannot combine stdin with other file inputs")
            }
            inputURLs = []
        }
        if let stdinPath = args["stdinpath"] {
            if !useStdin {
                print("warning: --stdinpath option only applies when using stdin", as: .warning)
            }
            let stdinURL = try parsePath(stdinPath, for: "stdinpath", in: directory)
            let resourceValues = try getResourceValues(
                for: stdinURL.standardizedFileURL,
                keys: [.creationDateKey, .pathKey]
            )
            var formatOptions = options.formatOptions ?? .default

            formatOptions.fileInfo = FileInfo(
                filePath: resourceValues.path,
                creationDate: resourceValues.creationDate
            )
            options.formatOptions = formatOptions
        }
        if args["scriptinput"] != nil {
            inputURLs += try parseScriptInput(from: environment)
        }

        // Treat values for arguments that do not take a value as input paths
        func addInputPaths(for argName: String) throws {
            guard let arg = args[argName], !arg.isEmpty else {
                return
            }
            guard inputURLs.isEmpty || "/.,".contains(where: { arg.contains($0) }) else {
                throw FormatError.options("--\(argName) argument does not expect a value")
            }
            if arg.lowercased() == "stdin" {
                useStdin = true
            } else {
                inputURLs += try parsePaths(arg, in: directory)
            }
        }
        try addInputPaths(for: "quiet")
        try addInputPaths(for: "verbose")
        try addInputPaths(for: "lenient")
        try addInputPaths(for: "strict")
        try addInputPaths(for: "dryrun")
        try addInputPaths(for: "lint")
        try addInputPaths(for: "inferoptions")

        // Output path
        var useStdout = false
        let outputURL = try args["output"].flatMap { arg -> URL? in
            if arg == "" {
                throw FormatError.options("--output argument expects a value")
            } else if inputURLs.count > 1 {
                throw FormatError.options("--output argument is only valid for a single input file or directory")
            } else if arg == "stdout" {
                useStdout = true
                return URL(string: arg)
            }
            if args["lint"] != nil {
                print("warning: --output argument is unused when running in --lint mode", as: .warning)
            }
            return try parsePath(arg, for: "--output", in: directory)
        }

        guard !useStdout || (reporter == nil || reportURL != nil) else {
            throw FormatError.options("--report file must be specified when --output is stdout")
        }

        // Source range
        let lineRange = try args["linerange"].flatMap { arg -> ClosedRange<Int>? in
            if arg == "" {
                throw FormatError.options("--linerange argument expects a value")
            } else if inputURLs.count > 1 {
                throw FormatError.options("--linerange argument is only valid for a single input file")
            }
            let parts = arg.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard (1 ... 2).contains(parts.count),
                  let start = parts.first.flatMap(Int.init),
                  let end = parts.last.flatMap(Int.init)
            else {
                throw FormatError.options("Unsupported --linerange value '\(arg)'")
            }
            return start ... end
        }

        // Infer options
        if args["inferoptions"] != nil {
            guard configURL == nil else {
                throw FormatError.options("--inferoptions option can't be used along with a config file")
            }
            guard args["range"] == nil else {
                throw FormatError.options("--inferoptions option can't be applied to a line range")
            }
            if !inputURLs.isEmpty {
                print("Inferring swiftformat options from source file(s)...", as: .info)
                var filesParsed = 0, formatOptions = FormatOptions.default, errors = [Error]()
                let fileOptions = options.fileOptions ?? .default
                let time = formatTime(timeEvent {
                    (filesParsed, formatOptions, errors) = inferOptions(from: inputURLs, options: fileOptions)
                })
                if printWarnings(errors) || filesParsed == 0 {
                    throw FormatError.parsing("Failed to to infer options")
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
                print("Options inferred from \(filesParsed)/\(filesChecked) files in \(time).", as: .info)
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
            let cacheDirectory = { () -> URL in
                #if os(macOS)
                    if let cachePath = NSSearchPathForDirectoriesInDomains(
                        .cachesDirectory, .userDomainMask, true
                    ).first {
                        return URL(fileURLWithPath: cachePath)
                    }
                #endif
                if #available(macOS 10.12, *) {
                    return FileManager.default.temporaryDirectory
                } else {
                    return URL(fileURLWithPath: "/var/tmp/")
                }
            }().appendingPathComponent("com.charcoaldesign.swiftformat")
            do {
                try manager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
                cacheURL = cacheDirectory.appendingPathComponent(defaultCacheFileName)
            } catch {
                errors.append(FormatError.writing("Failed to create cache directory at \(cacheDirectory.path)"))
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
                        errors.append(FormatError.writing("Failed to delete cache file at \(cacheURL.path)"))
                    }
                }
            default:
                cacheURL = try parsePath(cache, for: "--cache", in: directory)
                guard cacheURL != nil else {
                    throw FormatError.options("Invalid --cache value '\(cache)'")
                }
                var isDirectory: ObjCBool = false
                if manager.fileExists(atPath: cacheURL!.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    cacheURL = cacheURL!.appendingPathComponent(defaultCacheFileName)
                }
            }
        } else {
            setDefaultCacheURL()
        }

        func printRunningMessage() {
            print("Running SwiftFormat...", as: .info)
            if lint {
                print("(lint mode - no files will be changed.)", as: .info)
            } else if dryrun {
                print("(dryrun mode - no files will be changed.)", as: .info)
            }
        }

        enum Status {
            case idle, started, finished(ExitCode)
        }

        var input: String?
        var status = Status.idle
        func processFromStdin() {
            status = .started
            while let line = CLI.readLine() {
                input = (input ?? "") + line
            }
            guard let input = input else {
                status = .finished(.ok)
                return
            }
            do {
                var options = options
                if args["inferoptions"] != nil {
                    let tokens = tokenize(input)
                    options.formatOptions = inferFormatOptions(from: tokens)
                    try serializeOptions(options, to: outputURL)
                    status = .finished(.ok)
                } else {
                    printRunningMessage()
                    if let stdinURL = options.formatOptions?.fileInfo.filePath.map(URL.init(fileURLWithPath:)) {
                        try gatherOptions(&options, for: stdinURL, with: { print($0, as: .info) })
                        if options.shouldSkipFile(stdinURL) {
                            print(input, as: .raw)
                            status = .finished(.ok)
                            return
                        }
                    }
                    let output = try applyRules(
                        input, options: options, lineRange: lineRange,
                        verbose: verbose, lint: lint, lenient: lenient, reporter: reporter
                    )
                    if let outputURL = outputURL, !useStdout {
                        if !dryrun, (try? String(contentsOf: outputURL)) != output {
                            try write(output, to: outputURL)
                        }
                    } else {
                        // Write to stdout
                        print(dryrun ? input : output, as: .raw)
                    }
                    let exitCode: ExitCode
                    if lint, output != input {
                        print("Source input did not pass lint check.", as: lenient ? .warning : .error)
                        exitCode = lenient ? .ok : .lintFailure
                    } else if strict, output != input {
                        print("Source input was reformatted.", as: .error)
                        exitCode = .lintFailure
                    } else {
                        print("SwiftFormat completed successfully.", as: .success)
                        exitCode = .ok
                    }
                    status = .finished(exitCode)
                }
            } catch {
                if printWarnings([error]) {
                    status = .finished(.error)
                } else {
                    status = .finished(.ok)
                }
                // Ensure input isn't lost
                print(input, as: .raw)
            }
        }

        if useStdin {
            processFromStdin()
            if case let .finished(exitCode) = status {
                return exitCode
            }
            return .ok
        } else if inputURLs.isEmpty {
            // If no input file, try stdin
            DispatchQueue.global(qos: .userInitiated).async {
                processFromStdin()
            }
            // Wait for input
            while case .idle = status {}
            let start = NSDate()
            while input == nil, start.timeIntervalSinceNow > -0.2 {}
            // If no input received by now, assume none is coming
            if input != nil {
                while start.timeIntervalSinceNow > -30 {
                    if case let .finished(exitCode) = status {
                        return exitCode
                    }
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
        var outputFlags: OutputFlags = (0, 0, 0, 0)
        let time = formatTime(timeEvent {
            var _errors: [Error]
            (outputFlags, _errors) = processInput(inputURLs,
                                                  andWriteToOutput: outputURL,
                                                  options: options,
                                                  overrides: overrides,
                                                  lineRange: lineRange,
                                                  verbose: verbose,
                                                  dryrun: dryrun,
                                                  lint: lint,
                                                  lenient: lenient,
                                                  cacheURL: cacheURL,
                                                  reporter: reporter)
            errors += _errors
        })

        if printWarnings(errors) {
            return .error
        }
        if outputFlags.filesChecked == 0, outputFlags.filesSkipped == 0 {
            let inputPaths = inputURLs.map { $0.path }.joined(separator: ", ")
            print("warning: No eligible files found at \(inputPaths).", as: .warning)
        }
        if let reporter = reporter {
            let reporterOutput = try reporter.write()
            if let reportURL = reportURL {
                print("Writing report file to \(reportURL.path)")
                try reporterOutput.write(to: reportURL, options: .atomic)
            } else {
                print(String(decoding: reporterOutput, as: UTF8.self), as: .raw)
            }
        }
        print("SwiftFormat completed in \(time).", as: .success)
        return printResult(dryrun, lint, lenient, strict, outputFlags)
    } catch {
        _ = printWarnings(errors)
        // Fatal error
        var errorMessage = "\(error)"
        if ![".", "?", "!"].contains(errorMessage.last ?? " ") {
            errorMessage += "."
        }
        print("error: \(errorMessage)", as: .error)
        return .error
    }
}

func write(_ output: String, to file: URL) throws {
    do {
        let fm = FileManager.default
        let attributes = try? fm.attributesOfItem(atPath: file.path)
        try output.write(to: file, atomically: true, encoding: .utf8)
        if let created = attributes?[.creationDate] {
            try? fm.setAttributes([.creationDate: created], ofItemAtPath: file.path)
        }
    } catch {
        throw FormatError.writing("Failed to write file \(file.path)")
    }
}

func parseFileList(_ source: String, in directory: String) throws -> [URL] {
    try source
        .components(separatedBy: .newlines)
        .map { $0.components(separatedBy: "#")[0].trimmingCharacters(in: .whitespaces) }
        .flatMap { try parsePaths($0, in: directory) }
}

func parseScriptInput(from environment: [String: String]) throws -> [URL] {
    guard let countString = environment["SCRIPT_INPUT_FILE_COUNT"],
          let count = Int(countString)
    else {
        throw FormatError
            .options("--scriptinput requires a configured SCRIPT_INPUT_FILE_COUNT integer variable")
    }

    return try (0 ..< count).map { index in
        guard let file = environment["SCRIPT_INPUT_FILE_\(index)"] else {
            throw FormatError
                .options("Input file count is \(count), but SCRIPT_INPUT_FILE_\(index) is not present")
        }
        return URL(fileURLWithPath: file)
    }
}

func printResult(_ dryrun: Bool, _ lint: Bool, _ lenient: Bool, _ strict: Bool, _ flags: OutputFlags) -> ExitCode {
    let (written, checked, skipped, failed) = flags
    let ignored = (skipped == 0) ? "" : ", \(skipped) file\(skipped == 1 ? "" : "s") skipped"
    if checked == 0 {
        print("0 files formatted\(ignored).", as: .info)
    } else if lint {
        if failed > 0 {
            print("Source input did not pass lint check.", as: .error)
        }
        print("\(failed)/\(checked) files require formatting\(ignored).", as: .info)
    } else if dryrun {
        print("\(failed)/\(checked) files would have been formatted\(ignored).", as: .info)
    } else {
        print("\(written)/\(checked) files formatted\(ignored).", as: .info)
    }
    return ((!lenient && lint) || strict) && failed > 0 ? .lintFailure : .ok
}

func inferOptions(from inputURLs: [URL], options: FileOptions) -> (Int, FormatOptions, [Error]) {
    var tokens = [Token]()
    var errors = [Error]()
    var filesParsed = 0
    let baseOptions = Options(fileOptions: options)
    for inputURL in inputURLs {
        errors += enumerateFiles(
            withInputURL: inputURL,
            options: baseOptions,
            logger: { print($0, as: .info) }
        ) { inputURL, _, _ in
            guard let input = try? String(contentsOf: inputURL) else {
                throw FormatError.reading("Failed to read file \(inputURL.path)")
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

func applyRules(_ source: String, options: Options, lineRange: ClosedRange<Int>?,
                verbose: Bool, lint: Bool, lenient: Bool, reporter: Reporter?) throws -> String
{
    // Parse source
    var tokens = tokenize(source)

    // Get rules
    let rulesByName = FormatRules.byName
    let ruleNames = Array(options.rules ?? allRules.subtracting(FormatRules.disabledByDefault)).sorted()
    let rules = ruleNames.compactMap { rulesByName[$0] }

    if verbose, let path = options.formatOptions?.fileInfo.filePath {
        print("\(lint ? "Linting" : "Formatting") \(path)", as: .info)
    }

    // Apply rules
    let formatOptions = options.formatOptions ?? .default
    var changes = [Formatter.Change]()
    let range = lineRange.map { tokenRange(forLineRange: $0, in: tokens) }
    (tokens, changes) = try applyRules(
        rules, to: tokens, with: formatOptions,
        trackChanges: lint || verbose || reporter != nil,
        range: range
    )

    // Display info
    let updatedSource = sourceCode(for: tokens)
    if lint, updatedSource != source {
        changes.forEach { print($0.description(asError: !lenient), as: lenient ? .warning : .error) }
        reporter?.report(changes)
    }
    if verbose {
        let rulesApplied = changes.reduce(into: Set<String>()) {
            $0.insert($1.rule.name)
        }
        if rulesApplied.isEmpty || updatedSource == source {
            print("-- no changes", as: .success)
        } else {
            let sortedNames = Array(rulesApplied).sorted().joined(separator: ", ")
            print("-- rules applied: \(sortedNames)", as: .success)
        }
    }

    // Output
    return updatedSource
}

func processInput(_ inputURLs: [URL],
                  andWriteToOutput outputURL: URL?,
                  options: Options,
                  overrides: [String: String],
                  lineRange: ClosedRange<Int>?,
                  verbose: Bool,
                  dryrun: Bool,
                  lint: Bool,
                  lenient: Bool,
                  cacheURL: URL?,
                  reporter: Reporter?) -> (OutputFlags, [Error])
{
    // Load cache
    let cacheDirectory = cacheURL?.deletingLastPathComponent().absoluteURL
    var cache: [String: String]?
    if let cacheURL = cacheURL {
        if let data = try? Data(contentsOf: cacheURL) {
            cache = try? JSONDecoder().decode([String: String].self, from: data)
        }
        cache = cache ?? [:]
    }
    // Logging skipped files
    var outputFlags: OutputFlags = (0, 0, 0, 0)
    let skippedHandler: FileEnumerationHandler? = verbose ? { inputURL, _, _ in
        print("Skipping \(inputURL.path)", as: .info)
        print("-- ignored", as: .warning)
        return {}
    } : { _, _, _ in
        { outputFlags.filesSkipped += 1 }
    }
    // Swift version
    var shownWarnings = Set<String>()
    var showedConfigurationWarnings = false
    func showConfigurationWarnings(_ options: Options) {
        let arguments = argumentsFor(options, excludingDefaults: true)
        let warnings = warningsForArguments(arguments, ignoreUnusedOptions: true)
        for warning in warnings where !shownWarnings.contains(warning) {
            shownWarnings.insert(warning)
            print("warning: \(warning)", as: .warning)
        }
        guard !showedConfigurationWarnings else {
            return
        }
        let formatOptions = options.formatOptions ?? .default
        if formatOptions.swiftVersion == .undefined {
            print("warning: No Swift version was specified, so some formatting features were disabled. Specify the version of Swift you are using with the --swiftversion option, or by adding a \(swiftVersionFile) file to your project.", as: .warning)
        }
        if formatOptions.useTabs, formatOptions.tabWidth <= 0, !formatOptions.smartTabs {
            print("warning: The --smarttabs option is disabled, but no --tabwidth was specified.", as: .warning)
        }
        showedConfigurationWarnings = true
    }
    // Format files
    var errors = [Error]()
    for inputURL in inputURLs {
        errors += enumerateFiles(
            withInputURL: inputURL,
            outputURL: outputURL,
            options: options,
            concurrent: !verbose,
            logger: { print($0, as: .info) },
            skipped: skippedHandler
        ) { inputURL, outputURL, options in
            guard let input = try? String(contentsOf: inputURL) else {
                throw FormatError.reading("Failed to read file \(inputURL.path)")
            }
            // Override options
            var options = options
            try options.addArguments(overrides, in: "") // No need for directory as overrides are formatOptions only
            let formatOptions = options.formatOptions ?? .default
            let range = lineRange.map { "\($0.lowerBound),\($0.upperBound);" } ?? ""
            // Check cache
            let rules = options.rules ?? allRules.subtracting(FormatRules.disabledByDefault)
            let configHash = computeHash("\(formatOptions)\(range)\(rules.sorted().joined(separator: ","))")
            let cachePrefix = "\(version);\(configHash);"
            let cacheKey: String = {
                var path = inputURL.absoluteURL.path
                if let cacheDirectory = cacheDirectory {
                    let commonPrefix = path.commonPrefix(with: cacheDirectory.path)
                    path = String(path[commonPrefix.endIndex ..< path.endIndex])
                }
                return path
            }()
            do {
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
                        print("\(lint ? "Linting" : "Formatting") \(inputURL.path)", as: .info)
                        print("-- no changes (cached)", as: .success)
                    }
                } else {
                    output = try applyRules(input, options: options, lineRange: lineRange,
                                            verbose: verbose, lint: lint, lenient: lenient,
                                            reporter: reporter)
                    if output != input {
                        sourceHash = nil
                    }
                }
                let cacheValue = cache.map { _ in
                    // Only bother computing this if cache is enabled
                    cachePrefix + (sourceHash ?? computeHash(output))
                }
                if outputURL.lastPathComponent.lowercased() == "stdout" {
                    if !dryrun {
                        // Write to stdout
                        print(output, as: .raw)
                        return {
                            outputFlags.filesChecked += 1
                            outputFlags.filesFailed += 1
                            outputFlags.filesWritten += 1
                            showConfigurationWarnings(options)
                        }
                    }
                } else if outputURL != inputURL, (try? String(contentsOf: outputURL)) != output {
                    if !dryrun {
                        do {
                            try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                                                    withIntermediateDirectories: true,
                                                                    attributes: nil)
                        } catch {
                            throw FormatError.writing("Failed to create directory at \(outputURL.path), \(error)")
                        }
                    }
                } else if output == input {
                    // No changes needed
                    return {
                        outputFlags.filesChecked += 1
                        cache?[cacheKey] = cacheValue
                        showConfigurationWarnings(options)
                    }
                }
                if dryrun {
                    return {
                        outputFlags.filesChecked += 1
                        outputFlags.filesFailed += 1
                        showConfigurationWarnings(options)
                    }
                } else {
                    if verbose {
                        print("Writing \(outputURL.path)", as: .info)
                    }
                    try write(output, to: outputURL)
                    return {
                        outputFlags.filesChecked += 1
                        outputFlags.filesFailed += 1
                        outputFlags.filesWritten += 1
                        cache?[cacheKey] = cacheValue
                        showConfigurationWarnings(options)
                    }
                }
            } catch {
                if verbose {
                    var errorMessage = "\(error)"
                    if !".?!".contains(errorMessage.last ?? " ") {
                        errorMessage += "."
                    }
                    print("-- error: \(errorMessage)", as: .error)
                }
                return {
                    outputFlags.filesChecked += 1
                    showConfigurationWarnings(options)
                    switch error {
                    case let FormatError.parsing(string):
                        throw FormatError.parsing("\(string) in \(inputURL.path)")
                    case let FormatError.writing(string):
                        throw FormatError.writing("\(string) in \(inputURL.path)")
                    default:
                        throw error
                    }
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
    // Save cache
    if outputFlags.filesChecked > 0, let cache = cache, let cacheURL = cacheURL,
       let cacheDirectory = cacheDirectory
    {
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            if FileManager.default.fileExists(atPath: cacheDirectory.path) {
                errors.append(FormatError.writing("Failed to write cache file at \(cacheURL.path)"))
            } else {
                errors.append(FormatError.reading("Specified cache file directory does not exist: \(cacheDirectory.path)"))
            }
        }
    }
    return (outputFlags, errors)
}
