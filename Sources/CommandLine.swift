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
    public static func run(in directory: String, with args: [String] = CommandLine.arguments) {
        processArguments(args, in: directory)
    }

    /// Run the CLI with the specified input string (this will be parsed into multiple arguments)
    public static func run(in directory: String, with argumentString: String) {
        run(in: directory, with: parseArguments(argumentString))
    }
}

private func print(_ message: String, as type: CLI.OutputType = .info) {
    CLI.print(message, type)
}

func printWarnings(_ errors: [Error]) {
    for error in errors {
        print("warning: \(error)", as: .warning)
    }
}

func printHelp() {
    print("")
    print("swiftformat, version \(version)")
    print("copyright (c) 2016 Nick Lockwood")
    print("")
    print("--help             print this help page")
    print("--version          print the currently installed swiftformat version")
    print("")
    print("swiftformat can operate on file & directories, or directly on input from stdin:")
    print("")
    print("usage: swiftformat [<file> <file> ...] [--inferoptions] [--output path] [...]")
    print("")
    print("<file> <file> ...  one or more swift files or directory paths to be processed")
    print("")
    print("--inferoptions     instead of formatting input, use it to infer format options")
    print("--output           output path for formatted file(s) (defaults to input path)")
    print("--exclude          list of file or directory paths to ignore (comma-delimited)")
    print("--symlinks         how symlinks are handled. \"follow\" or \"ignore\" (default)")
    print("--fragment         input is part of a larger file. \"true\" or \"false\" (default)")
    print("--conflictmarkers  merge conflict markers, either \"reject\" (default) or \"ignore\"")
    print("--cache            path to cache file, or \"clear\" or \"ignore\" the default cache")
    print("--verbose          display detailed formatting output and warnings/errors")
    print("--dryrun           run in \"dry\" mode (without actually changing any files)")
    print("")
    print("swiftformat has a number of rules that can be enabled or disabled. by default")
    print("most rules are enabled. use --rules to display all enabled/disabled rules:")
    print("")
    print("--disable          a list of format rules to be disabled (comma-delimited)")
    print("--enable           a list of disabled rules to be re-enabled (comma-delimited)")
    print("--rules            the list of rules to apply (pass nothing to print rules)")
    print("")
    print("swiftformat's rules can be configured using options. a given option may affect")
    print("multiple rules. options have no affect if the related rules have been disabled:")
    print("")
    print("--allman           use allman indentation style. \"true\" or \"false\" (default)")
    print("--binarygrouping   binary grouping,threshold or \"none\", \"ignore\". default: 4,8")
    print("--commas           commas in collection literals. \"always\" (default) or \"inline\"")
    print("--comments         indenting of comment bodies. \"indent\" (default) or \"ignore\"")
    print("--decimalgrouping  decimal grouping,threshold or \"none\", \"ignore\". default: 3,6")
    print("--elseposition     placement of else/catch. \"same-line\" (default) or \"next-line\"")
    print("--empty            how empty values are represented. \"void\" (default) or \"tuple\"")
    print("--experimental     experimental rules. \"enabled\" or \"disabled\" (default)")
    print("--exponentcase     case of 'e' in numbers. \"lowercase\" or \"uppercase\" (default)")
    print("--header           header comments. \"strip\", \"ignore\", or the text you wish use")
    print("--hexgrouping      hex grouping,threshold or \"none\", \"ignore\". default: 4,8")
    print("--hexliteralcase   casing for hex literals. \"uppercase\" (default) or \"lowercase\"")
    print("--ifdef            #if indenting. \"indent\" (default), \"noindent\" or \"outdent\"")
    print("--indent           number of spaces to indent, or \"tab\" to use tabs")
    print("--indentcase       indent cases inside a switch. \"true\" or \"false\" (default)")
    print("--linebreaks       linebreak character to use. \"cr\", \"crlf\" or \"lf\" (default)")
    print("--octalgrouping    octal grouping,threshold or \"none\", \"ignore\". default: 4,8")
    print("--operatorfunc     spacing for operator funcs. \"spaced\" (default) or \"nospace\"")
    print("--patternlet       let/var placement in patterns. \"hoist\" (default) or \"inline\"")
    print("--ranges           spacing for ranges. \"spaced\" (default) or \"nospace\"")
    print("--semicolons       allow semicolons. \"never\" or \"inline\" (default)")
    print("--self             use self for member variables. \"remove\" (default) or \"insert\"")
    print("--stripunusedargs  \"closure-only\", \"unnamed-only\" or \"always\" (default)")
    print("--trimwhitespace   trim trailing space. \"always\" (default) or \"nonblank-lines\"")
    print("--wraparguments    wrap function args. \"beforefirst\", \"afterfirst\", \"disabled\"")
    print("--wrapelements     wrap array/dict. \"beforefirst\", \"afterfirst\", \"disabled\"")
    print("")
}

func expandPath(_ path: String, in directory: String) -> URL {
    let path = NSString(string: path).expandingTildeInPath
    let directoryURL = URL(fileURLWithPath: directory)
    return URL(fileURLWithPath: path, relativeTo: directoryURL)
}

func timeEvent(block: () throws -> Void) rethrows -> String {
    let start = CFAbsoluteTimeGetCurrent()
    try block()
    let time = round((CFAbsoluteTimeGetCurrent() - start) * 100) / 100 // round to nearest 10ms
    return String(format: "%gs", time)
}

func parseArguments(_ argumentString: String) -> [String] {
    var arguments = [""] // Arguments always begin with script path
    var characters = String.UnicodeScalarView.SubSequence(argumentString.unicodeScalars)
    var string = ""
    var escaped = false
    var quoted = false
    while let char = characters.popFirst() {
        switch char {
        case "\\" where !escaped:
            escaped = true
        case "\"" where !escaped && !quoted:
            quoted = true
        case "\"" where !escaped && quoted:
            quoted = false
            fallthrough
        case " " where !escaped && !quoted:
            if !string.isEmpty {
                arguments.append(string)
            }
            string.removeAll()
        case "\"" where escaped:
            escaped = false
            string.append("\"")
        case _ where escaped && quoted:
            string.append("\\")
            fallthrough
        default:
            escaped = false
            string.append(Character(char))
        }
    }
    if !string.isEmpty {
        arguments.append(string)
    }
    return arguments
}

func processArguments(_ args: [String], in directory: String) {
    var errors = [Error]()
    var verbose = false
    var dryrun = false
    do {
        // Get options
        let args = try preprocessArguments(args, commandLineArguments)
        let formatOptions = try formatOptionsFor(args)
        let fileOptions = try fileOptionsFor(args)

        // Show help if requested specifically or if no arguments are passed
        if args["help"] != nil {
            printHelp()
            return
        }

        // Version
        if args["version"] != nil {
            print("swiftformat, version \(version)")
            return
        }

        // Rules
        var rules = Set(FormatRules.byName.keys)
        var disabled = Set(FormatRules.disabledByDefault)
        if let names = args["enable"]?.components(separatedBy: ",") {
            for name in names {
                var name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !rules.contains(name) {
                    throw FormatError.options("unknown rule '\(name)'")
                }
                disabled.remove(name)
            }
        }
        if let names = args["disable"]?.components(separatedBy: ",") {
            for name in names {
                var name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !rules.contains(name) {
                    throw FormatError.options("unknown rule '\(name)'")
                }
                disabled.insert(name)
            }
        }
        if let names = args["rules"]?.components(separatedBy: ",") {
            if names.count == 1, names[0].isEmpty {
                print("")
                for name in Array(rules).sorted() {
                    let disabled = disabled.contains(name) ? " (disabled)" : ""
                    print(" \(name)\(disabled)")
                }
                print("")
                return
            }
            var whitelist = Set<String>()
            for name in names {
                var name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if rules.contains(name) {
                    whitelist.insert(name)
                } else {
                    throw FormatError.options("unknown rule '\(name)'")
                }
            }
            rules = whitelist
        } else {
            for name: String in disabled {
                rules.remove(name)
            }
        }

        // Get input path(s)
        var inputURLs = [URL]()
        while let inputPath = args[String(inputURLs.count + 1)] {
            inputURLs.append(expandPath(inputPath, in: directory))
        }

        // Verbose
        if let arg = args["verbose"] {
            verbose = true
            if !arg.isEmpty {
                // verbose doesn't take an argument, so treat argument as another input path
                inputURLs.append(expandPath(arg, in: directory))
            }
            if inputURLs.isEmpty, args["output"] ?? "" != "" {
                throw FormatError.options("--verbose option has no effect unless an output file is specified")
            }
        }

        // Dry
        if let arg = args["dryrun"] {
            dryrun = true
            if !arg.isEmpty {
                // dryrun doesn't take an argument, so treat argument as another input path
                inputURLs.append(expandPath(arg, in: directory))
            }
        }

        // Get path(s) that will be excluded
        // Get path(s) that will be excluded
        var excludedURLs = [URL]()
        if let arg = args["exclude"] {
            if inputURLs.isEmpty {
                throw FormatError.options("--exclude option has no effect unless an input path is specified")
            }
            for path in arg.components(separatedBy: ",") {
                excludedURLs.append(expandPath(path, in: directory))
            }
        }

        // Infer options
        if let arg = args["inferoptions"] {
            if !arg.isEmpty {
                // inferoptions doesn't take an argument, so treat argument as another input path
                inputURLs.append(expandPath(arg, in: directory))
            }
            if inputURLs.count > 0 {
                print("inferring swiftformat options from source file(s)...")
                var filesParsed = 0, options = FormatOptions(), errors = [Error]()
                let time = timeEvent {
                    (filesParsed, options, errors) = inferOptions(from: inputURLs, excluding: excludedURLs)
                }
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
                print("options inferred from \(filesParsed)/\(filesChecked) files in \(time)")
                print("")
                print(commandLineArguments(for: options).map({ "--\($0.key) \($0.value)" }).joined(separator: " "))
                print("")
                return
            }
        }

        // Get output path
        let outputURL = args["output"].map { expandPath($0, in: directory) }
        if outputURL != nil {
            if args["output"] == "" {
                throw FormatError.options("--output argument expects a value")
            } else if inputURLs.count > 1 {
                throw FormatError.options("--output argument is only valid for a single input file")
            }
        }

        // Get cache path
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
                cacheURL = expandPath(cache, in: directory)
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
                            let options = inferOptions(from: tokens)
                            print(commandLineArguments(for: options).map({ "--\($0.key) \($0.value)" }).joined(separator: " "))
                        } else if let outputURL = outputURL {
                            print("running swiftformat...")
                            if dryrun {
                                print("(dryrun mode - no files will be changed)", as: .warning)
                            }
                            let output = try format(
                                input,
                                ruleNames: Array(rules),
                                options: formatOptions,
                                verbose: verbose
                            )
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
                            let output = try format(
                                input,
                                ruleNames: Array(rules),
                                options: formatOptions,
                                verbose: false
                            )
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
                printHelp()
            }
            return
        }

        print("running swiftformat...")
        if dryrun {
            print("(dryrun mode - no files will be changed)", as: .warning)
        }

        // Format the code
        var filesWritten = 0, filesFailed = 0, filesChecked = 0
        let time = timeEvent {
            var _errors = [Error]()
            (filesWritten, filesFailed, filesChecked, _errors) = processInput(
                inputURLs,
                excluding: excludedURLs,
                andWriteToOutput: outputURL,
                withRules: Array(rules),
                formatOptions: formatOptions,
                fileOptions: fileOptions,
                verbose: verbose,
                dryrun: dryrun,
                cacheURL: cacheURL
            )
            errors += _errors
        }

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
            print("swiftformat completed. \(filesFailed)/\(filesChecked) files would have been updated in \(time)", as: .success)
        } else {
            print("swiftformat completed. \(filesWritten)/\(filesChecked) files updated in \(time)", as: .success)
        }
    } catch {
        if !verbose {
            // Warnings would be redundant at this point
            printWarnings(errors)
        }
        // Fatal error
        print("error: \(error)", as: .error)
    }
}

func inferOptions(from inputURLs: [URL], excluding excludedURLs: [URL]) -> (Int, FormatOptions, [Error]) {
    var tokens = [Token]()
    var errors = [Error]()
    var filesParsed = 0
    for inputURL in inputURLs {
        errors += enumerateFiles(withInputURL: inputURL, excluding: excludedURLs) { inputURL, _ in
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
    return (filesParsed, inferOptions(from: tokens), errors)
}

func format(_ source: String,
            ruleNames: [String],
            options: FormatOptions,
            verbose: Bool) throws -> String {
    // Parse source
    let originalTokens = tokenize(source)
    var tokens = originalTokens

    // Apply rules
    let rulesByName = FormatRules.byName
    var rules = [FormatRule]()
    for name in ruleNames {
        if let rule = rulesByName[name] {
            rules.append(rule)
        }
    }
    var rulesApplied = Set<String>()
    let callback: ((Int, [Token]) -> Void)? = verbose ? { i, updatedTokens in
        if updatedTokens != tokens {
            rulesApplied.insert(ruleNames[i])
            tokens = updatedTokens
        }
    } : nil
    tokens = try applyRules(rules, to: tokens, with: options, callback: callback)

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
                  excluding excludedURLs: [URL],
                  andWriteToOutput outputURL: URL?,
                  withRules enabled: [String],
                  formatOptions: FormatOptions,
                  fileOptions: FileOptions,
                  verbose: Bool,
                  dryrun: Bool,
                  cacheURL: URL?) -> (Int, Int, Int, [Error]) {
    // Filter rules
    var disabled = [String]()
    for name: String in FormatRules.byName.keys {
        if !enabled.contains(name) {
            disabled.append(name)
        }
    }
    let ruleNames = enabled.count <= disabled.count ?
        (enabled.count == 0 ? "" : "rules:\(enabled.joined(separator: ","));") :
        (disabled.count == 0 ? "" : "disabled:\(disabled.joined(separator: ","));")
    // Load cache
    let cachePrefix = "\(version);\(formatOptions)\(ruleNames)"
    let cacheDirectory = cacheURL?.deletingLastPathComponent().absoluteURL
    var cache: [String: String]?
    if let cacheURL = cacheURL {
        cache = NSDictionary(contentsOf: cacheURL) as? [String: String] ?? [:]
    }
    // Format files
    var errors = [Error]()
    var filesChecked = 0, filesFailed = 0, filesWritten = 0
    for inputURL in inputURLs {
        errors += enumerateFiles(withInputURL: inputURL,
                                 excluding: excludedURLs,
                                 outputURL: outputURL,
                                 options: fileOptions,
                                 concurrent: !verbose) { inputURL, outputURL in

            guard let input = try? String(contentsOf: inputURL) else {
                throw FormatError.reading("failed to read file \(inputURL.path)")
            }
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
                    print("formatting \(inputURL.path)")
                }
                let output: String
                if cache?[cacheKey] == cachePrefix + String(input.count) {
                    output = input
                    if verbose {
                        print("-- no changes", as: .success)
                    }
                } else {
                    output = try format(input, ruleNames: enabled, options: formatOptions, verbose: verbose)
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
                        cache?[cacheKey] = cachePrefix + String(output.count)
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
                            cache?[cacheKey] = cachePrefix + String(output.count)
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

func preprocessArguments(_ args: [String], _ names: [String]) throws -> [String: String] {
    var anonymousArgs = 0
    var namedArgs: [String: String] = [:]
    var name = ""
    for arg in args {
        if arg.hasPrefix("--") {
            // Long argument names
            let key = String(arg.unicodeScalars.dropFirst(2))
            if !names.contains(key) {
                throw FormatError.options("unknown argument: \(arg)")
            }
            name = key
            namedArgs[name] = ""
            continue
        } else if arg.hasPrefix("-") {
            // Short argument names
            let flag = String(arg.unicodeScalars.dropFirst())
            let matches = names.filter { $0.hasPrefix(flag) }
            if matches.count > 1 {
                throw FormatError.options("ambiguous argument: \(arg)")
            } else if matches.count == 0 {
                throw FormatError.options("unknown argument: \(arg)")
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
                    args["indent"] = String(options.indent.count)
                }
            case FormatOptions.lineBreakDescriptor.propertyName:
                args[FormatOptions.lineBreakDescriptor.argumentName] = FormatOptions.lineBreakDescriptor.fromOptions(options)
            case "allowInlineSemicolons":
                args["semicolons"] = options.allowInlineSemicolons ? "inline" : "never"
            case "spaceAroundRangeOperators":
                args["ranges"] = options.spaceAroundRangeOperators ? "spaced" : "nospace"
            case "spaceAroundOperatorDeclarations":
                args["operatorfunc"] = options.spaceAroundOperatorDeclarations ? "spaced" : "nospace"
            case "useVoid":
                args["empty"] = options.useVoid ? "void" : "tuples"
            case "trailingCommas":
                args["commas"] = options.trailingCommas ? "always" : "inline"
            case "indentCase":
                args["indentcase"] = options.indentCase ? "true" : "false"
            case "indentComments":
                args["comments"] = options.indentComments ? "indent" : "ignore"
            case "truncateBlankLines":
                args["trimwhitespace"] = options.truncateBlankLines ? "always" : "nonblank-lines"
            case "allmanBraces":
                args["allman"] = options.allmanBraces ? "true" : "false"
            case "fileHeader":
                args["header"] = options.fileHeader.map { $0.isEmpty ? "strip" : $0 } ?? "ignore"
            case "ifdefIndent":
                args["ifdef"] = options.ifdefIndent.rawValue
            case "wrapArguments":
                args["wraparguments"] = options.wrapArguments.rawValue
            case "wrapElements":
                args["wrapelements"] = options.wrapElements.rawValue
            case "uppercaseHex":
                args["hexliteralcase"] = options.uppercaseHex ? "uppercase" : "lowercase"
            case "uppercaseExponent":
                args["exponentcase"] = options.uppercaseExponent ? "uppercase" : "lowercase"
            case "decimalGrouping":
                args["decimalgrouping"] = options.decimalGrouping.rawValue
            case "binaryGrouping":
                args["binarygrouping"] = options.binaryGrouping.rawValue
            case "octalGrouping":
                args["octalgrouping"] = options.octalGrouping.rawValue
            case "hexGrouping":
                args["hexgrouping"] = options.hexGrouping.rawValue
            case "hoistPatternLet":
                args["patternlet"] = options.hoistPatternLet ? "hoist" : "inline"
            case "stripUnusedArguments":
                args["stripunusedargs"] = options.stripUnusedArguments.rawValue
            case "elseOnNextLine":
                args["elseposition"] = options.elseOnNextLine ? "next-line" : "same-line"
            case "removeSelf":
                args["self"] = options.removeSelf ? "remove" : "insert"
            case "experimentalRules":
                args["experimental"] = options.experimentalRules ? "enabled" : nil
            case "fragment":
                args["fragment"] = options.fragment ? "true" : nil
            case "ignoreConflictMarkers":
                args["conflictmarkers"] = options.ignoreConflictMarkers ? "ignore" : nil
            case "insertBlankLines", "removeBlankLines":
                break // Deprecated
            default:
                assertionFailure("Unknown option: \(label)")
            }
        }
    }
    for arg in deprecatedArguments {
        args[arg] = nil
    }
    return args
}

private func processOption(_ key: String, in args: [String: String],
                           from: inout Set<String>, handler: (String) throws -> Void) throws {
    precondition(commandLineArguments.contains(key))
    var arguments = from
    arguments.remove(key)
    from = arguments
    guard let value = args[key] else {
        return
    }
    guard !value.isEmpty else {
        throw FormatError.options("--\(key) option expects a value")
    }
    do {
        try handler(value)
    } catch {
        throw FormatError.options("unsupported --\(key) value: \(value)")
    }
}

private func processOption(_ key: String,
                           in args: [String: String],
                           from: inout Set<String>,
                           to options: inout FormatOptions,
                           handler: (String, inout FormatOptions) throws -> Void) throws {
    do {
        try processOption(key,
                          in: args,
                          from: &from) {
            do {
                try handler($0, &options)
            } catch let err {
                throw err
            }
        }
    } catch let err {
        throw err
    }
}

func fileOptionsFor(_ args: [String: String]) throws -> FileOptions {
    var options = FileOptions()
    var arguments = Set(fileArguments)
    try processOption("symlinks", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "follow":
            options.followSymlinks = true
        case "ignore":
            options.followSymlinks = false
        default:
            throw FormatError.options("")
        }
    }
    assert(arguments.isEmpty, "\(arguments.joined(separator: ","))")
    return options
}

func formatOptionsFor(_ args: [String: String]) throws -> FormatOptions {
    var options = FormatOptions()
    var arguments = Set(formatArguments)
    try processOption("indent", in: args, from: &arguments) {
        switch $0.lowercased() {
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
    try processOption("indentcase", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "true":
            options.indentCase = true
        case "false":
            options.indentCase = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("allman", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "true", "enabled":
            options.allmanBraces = true
        case "false", "disabled":
            options.allmanBraces = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("semicolons", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "inline":
            options.allowInlineSemicolons = true
        case "never", "false":
            options.allowInlineSemicolons = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("commas", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "always", "true":
            options.trailingCommas = true
        case "inline", "false":
            options.trailingCommas = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("comments", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "indent", "indented":
            options.indentComments = true
        case "ignore":
            options.indentComments = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption(FormatOptions.lineBreakDescriptor.argumentName,
                      in: args,
                      from: &arguments,
                      to: &options,
                      handler: FormatOptions.lineBreakDescriptor.toOptions)
    try processOption("ranges", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "space", "spaced", "spaces":
            options.spaceAroundRangeOperators = true
        case "nospace":
            options.spaceAroundRangeOperators = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("operatorfunc", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "space", "spaced", "spaces":
            options.spaceAroundOperatorDeclarations = true
        case "nospace":
            options.spaceAroundOperatorDeclarations = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("elseposition", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "nextline", "next-line":
            options.elseOnNextLine = true
        case "sameline", "same-line":
            options.elseOnNextLine = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("empty", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "void":
            options.useVoid = true
        case "tuple", "tuples":
            options.useVoid = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("trimwhitespace", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "always":
            options.truncateBlankLines = true
        case "nonblank-lines", "nonblank", "non-blank-lines", "non-blank",
             "nonempty-lines", "nonempty", "non-empty-lines", "non-empty":
            options.truncateBlankLines = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("header", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "strip":
            options.fileHeader = ""
        case "ignore":
            options.fileHeader = nil
        default:
            // Normalize the header
            let header = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            let isMultiline = header.hasPrefix("/*")
            var lines = header.components(separatedBy: "\\n")
            lines = lines.map {
                var line = $0
                if !isMultiline, !line.hasPrefix("//") {
                    line = "//" + line
                }
                if let range = line.range(of: "{year}") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy"
                    line.replaceSubrange(range, with: formatter.string(from: Date()))
                }
                return line
            }
            while lines.last?.isEmpty == true {
                lines.removeLast()
            }
            options.fileHeader = lines.joined(separator: "\n")
        }
    }
    try processOption("ifdef", in: args, from: &arguments) {
        if let mode = IndentMode(rawValue: $0.lowercased()) {
            options.ifdefIndent = mode
        } else {
            throw FormatError.options("")
        }
    }
    try processOption("wraparguments", in: args, from: &arguments) {
        if let mode = WrapMode(rawValue: $0.lowercased()) {
            options.wrapArguments = mode
        } else {
            throw FormatError.options("")
        }
    }
    try processOption("wrapelements", in: args, from: &arguments) {
        if let mode = WrapMode(rawValue: $0.lowercased()) {
            options.wrapElements = mode
        } else {
            throw FormatError.options("")
        }
    }
    try processOption("hexliteralcase", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "uppercase", "upper":
            options.uppercaseHex = true
        case "lowercase", "lower":
            options.uppercaseHex = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("exponentcase", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "uppercase", "upper":
            options.uppercaseExponent = true
        case "lowercase", "lower":
            options.uppercaseExponent = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("decimalgrouping", in: args, from: &arguments) {
        guard let grouping = Grouping(rawValue: $0.lowercased()) else {
            throw FormatError.options("")
        }
        options.decimalGrouping = grouping
    }
    try processOption("binarygrouping", in: args, from: &arguments) {
        guard let grouping = Grouping(rawValue: $0.lowercased()) else {
            throw FormatError.options("")
        }
        options.binaryGrouping = grouping
    }
    try processOption("octalgrouping", in: args, from: &arguments) {
        guard let grouping = Grouping(rawValue: $0.lowercased()) else {
            throw FormatError.options("")
        }
        options.octalGrouping = grouping
    }
    try processOption("hexgrouping", in: args, from: &arguments) {
        guard let grouping = Grouping(rawValue: $0.lowercased()) else {
            throw FormatError.options("")
        }
        options.hexGrouping = grouping
    }
    try processOption("patternlet", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "hoist":
            options.hoistPatternLet = true
        case "inline":
            options.hoistPatternLet = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("self", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "remove":
            options.removeSelf = true
        case "insert":
            options.removeSelf = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("fragment", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "true", "enabled":
            options.fragment = true
        case "false", "disabled":
            options.fragment = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("conflictmarkers", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "true", "enabled":
            options.fragment = true
        case "false", "disabled":
            options.fragment = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("stripunusedargs", in: args, from: &arguments) {
        guard let type = ArgumentType(rawValue: $0.lowercased()) else {
            throw FormatError.options("")
        }
        options.stripUnusedArguments = type
    }
    try processOption("experimental", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "enabled", "true":
            options.experimentalRules = true
        case "disabled", "false":
            options.experimentalRules = false
        default:
            throw FormatError.options("")
        }
    }
    // Deprecated
    try processOption("hexliterals", in: args, from: &arguments) {
        print("`--hexliterals` option is deprecated. Use `--hexliteralcase` instead", as: .warning)
        switch $0.lowercased() {
        case "uppercase", "upper":
            options.uppercaseHex = true
        case "lowercase", "lower":
            options.uppercaseHex = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("insertlines", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "enabled", "true":
            print("`--insertlines` option is deprecated. Use `--enable blankLinesBetweenScopes` or `--enable blankLinesAroundMark` instead", as: .warning)
            options.insertBlankLines = true
        case "disabled", "false":
            print("`--insertlines` option is deprecated. Use `--disable blankLinesBetweenScopes` or `--disable blankLinesAroundMark` instead", as: .warning)
            options.insertBlankLines = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("removelines", in: args, from: &arguments) {
        switch $0.lowercased() {
        case "enabled", "true":
            print("`--removelines` option is deprecated. Use `--enable blankLinesAtStartOfScope` or `--enable blankLinesAtEndOfScope` instead", as: .warning)
            options.removeBlankLines = true
        case "disabled", "false":
            print("`--removelines` option is deprecated. Use `--disable blankLinesAtStartOfScope` or `--disable blankLinesAtEndOfScope` instead", as: .warning)
            options.removeBlankLines = false
        default:
            throw FormatError.options("")
        }
    }
    assert(arguments.isEmpty, "\(arguments.joined(separator: ","))")
    return options
}

let fileArguments = [
    // File options
    "symlinks",
]

let formatArguments = [
    // Format options
    "allman",
    "binarygrouping",
    "commas",
    "comments",
    "decimalgrouping",
    "elseposition",
    "empty",
    "exponentcase",
    "header",
    "hexgrouping",
    "hexliteralcase",
    "ifdef",
    "indent",
    "indentcase",
    "insertlines",
    "linebreaks",
    "octalgrouping",
    "operatorfunc",
    "ranges",
    "removelines",
    "semicolons",
    "stripunusedargs",
    "trimwhitespace",
    "wraparguments",
    "wrapelements",
    "patternlet",
    "self",
]

let deprecatedArguments = [
    "hexliterals",
    "insertlines",
    "removelines",
]

let commandLineArguments = [
    // File options
    "inferoptions",
    "output",
    "exclude",
    "fragment",
    "conflictmarkers",
    "cache",
    "verbose",
    "dryrun",
    // Rules
    "disable",
    "enable",
    "rules",
    // Misc
    "help",
    "version",
    // Format options
    "experimental",
] + deprecatedArguments + fileArguments + formatArguments
