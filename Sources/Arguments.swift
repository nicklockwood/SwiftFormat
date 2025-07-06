//
//  Arguments.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 07/08/2018.
//  Copyright © 2018 Nick Lockwood.
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

extension Options {
    init(_ args: [String: String], in directory: String) throws {
        fileOptions = try fileOptionsFor(args, in: directory)
        formatOptions = try formatOptionsFor(args)
        configURLs = args["config"].map {
            parseCommaDelimitedList($0).map { expandPath($0, in: directory) }
        }
        let lint = args.keys.contains("lint")
        self.lint = lint
        rules = try rulesFor(args, lint: lint)
    }

    mutating func addArguments(_ args: [String: String], in directory: String) throws {
        let oldArguments = argumentsFor(self)
        let newArguments = try mergeArguments(args, into: oldArguments)
        var newOptions = try Options(newArguments, in: directory)
        if let fileInfo = formatOptions?.fileInfo {
            newOptions.formatOptions?.fileInfo = fileInfo
        }
        newOptions.configURLs = configURLs
        self = newOptions
    }
}

extension String {
    /// Find best match for the string in a list of options
    func bestMatches(in options: [String]) -> [String] {
        let lowercaseQuery = lowercased()
        // Sort matches by Levenshtein edit distance
        return options
            .compactMap { option -> (String, distance: Int, commonPrefix: Int)? in
                let lowercaseOption = option.lowercased()
                let distance = lowercaseOption.editDistance(from: lowercaseQuery)
                let commonPrefix = lowercaseOption.commonPrefix(with: lowercaseQuery)
                if commonPrefix.isEmpty, distance > lowercaseQuery.count / 2 {
                    return nil
                }
                return (option, distance, commonPrefix.count)
            }
            .sorted {
                if $0.distance == $1.distance {
                    return $0.commonPrefix > $1.commonPrefix
                }
                return $0.distance < $1.distance
            }
            .map(\.0)
    }

    /// The Damerau-Levenshtein edit-distance between two strings
    func editDistance(from other: String) -> Int {
        let lhs = Array(self)
        let rhs = Array(other)
        var dist = [[Int]]()
        for i in stride(from: 0, through: lhs.count, by: 1) {
            dist.append([i])
        }
        for j in stride(from: 1, through: rhs.count, by: 1) {
            dist[0].append(j)
        }
        for i in stride(from: 1, through: lhs.count, by: 1) {
            for j in stride(from: 1, through: rhs.count, by: 1) {
                if lhs[i - 1] == rhs[j - 1] {
                    dist[i].append(dist[i - 1][j - 1])
                } else {
                    dist[i].append(Swift.min(dist[i - 1][j] + 1,
                                             dist[i][j - 1] + 1,
                                             dist[i - 1][j - 1] + 1))
                }
                if i > 1, j > 1, lhs[i - 1] == rhs[j - 2], lhs[i - 2] == rhs[j - 1] {
                    dist[i][j] = Swift.min(dist[i][j], dist[i - 2][j - 2] + 1)
                }
            }
        }
        return dist[lhs.count][rhs.count]
    }
}

/// Extract content from a string, stopping at unquoted comment markers
/// Handles quoted strings and escaped characters properly
private func contentBeforeUnquotedComment(in string: String) -> String {
    var result = ""
    var inQuotes = false
    var escaped = false

    for char in string {
        if escaped {
            result.append(char)
            escaped = false
        } else if char == "\\" {
            result.append(char)
            escaped = true
        } else if char == "\"" {
            result.append(char)
            inQuotes.toggle()
        } else if char == "#", !inQuotes {
            // Found unquoted comment marker, stop here
            break
        } else {
            result.append(char)
        }
    }

    return result
}

/// Parse a space-delimited string into an array of command-line arguments
/// Replicates the behavior implemented by the console when parsing input
func parseArguments(_ argumentString: String, ignoreComments: Bool = true) -> [String] {
    // First handle comments using the shared logic if comments are not ignored
    let inputString = ignoreComments ? argumentString : contentBeforeUnquotedComment(in: argumentString)

    var arguments = [""] // Arguments always begin with script path
    var characters = String.UnicodeScalarView.SubSequence(inputString.unicodeScalars)
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

/// Parse a flat array of command-line arguments into a dictionary of flags and values
func preprocessArguments(_ args: [String], _ names: [String]) throws -> [String: String] {
    var anonymousArgs = 0
    var namedArgs: [String: String] = [:]
    var name = ""
    for arg in args {
        if arg.hasPrefix("--") {
            let key = String(arg.unicodeScalars.dropFirst(2)).lowercased()

            if names.contains(key) {
                name = key
            }

            // Support legacy `--alloneword` option names by finding
            // any matching `--kebab-case` option name.
            else if !key.contains("-") {
                for kebabCaseName in names {
                    let nonKebabCaseName = kebabCaseName.replacingOccurrences(of: "-", with: "")
                    if nonKebabCaseName == key {
                        name = kebabCaseName
                        break
                    }
                }
            }

            if name.isEmpty {
                guard let match = key.bestMatches(in: names).first else {
                    throw FormatError.options("Unknown option --\(key)")
                }
                throw FormatError.options("Unknown option --\(key). Did you mean --\(match)?")
            }

            namedArgs[name] = namedArgs[name] ?? ""
            continue
        } else if arg.hasPrefix("-") {
            // Short argument names
            let flag = String(arg.unicodeScalars.dropFirst()).lowercased()
            guard let match = names.first(where: { $0.hasPrefix(flag) }) else {
                throw FormatError.options("Unknown flag -\(flag)")
            }
            name = match
            namedArgs[name] = namedArgs[name] ?? ""
            continue
        }
        if name == "" {
            // Argument is anonymous
            name = String(anonymousArgs)
            anonymousArgs += 1
        }
        var arg = arg
        let hasTrailingComma = arg.hasSuffix(",") && arg != ","
        if hasTrailingComma {
            arg = String(arg.dropLast())
        }
        if let existing = namedArgs[name], !existing.isEmpty,
           // TODO: find a more general way to represent merge-able options
           ["exclude", "unexclude", "disable", "enable", "lint-only", "rules", "config"].contains(name) ||
           Descriptors.all.contains(where: {
               $0.argumentName == name && $0.isSetType
           })
        {
            namedArgs[name] = existing + "," + arg
        } else {
            namedArgs[name] = arg
        }
        if !hasTrailingComma {
            name = ""
        }
    }
    return namedArgs
}

/// Parse a comma-delimited list of items
func parseCommaDelimitedList(_ string: String) -> [String] {
    string.components(separatedBy: ",").compactMap {
        let item = $0.trimmingCharacters(in: .whitespacesAndNewlines)
        return item.isEmpty ? nil : item
    }
}

/// Parse a comma-delimited string into an array of rules
let allRules = Set(FormatRules.all.map(\.name))
let defaultRules = Set(FormatRules.default.map(\.name))
func parseRules(_ rules: String) throws -> [String] {
    try parseCommaDelimitedList(rules).flatMap { proposedName -> [String] in
        let lowercaseName = proposedName.lowercased()
        if let name = allRules.first(where: { $0.lowercased() == lowercaseName }) {
            return [name]
        } else if lowercaseName == "all" {
            return FormatRules.all.compactMap { $0.isDeprecated ? nil : $0.name }
        }
        if Descriptors.all.contains(where: { $0.argumentName == lowercaseName }) {
            for rule in FormatRules.all where rule.options.contains(lowercaseName) {
                throw FormatError.options(
                    "'\(proposedName)' is not a formatting rule. Did you mean '\(rule.name)'?"
                )
            }
            throw FormatError.options("'\(proposedName)' is not a formatting rule")
        }
        guard let match = proposedName.bestMatches(in: Array(allRules)).first else {
            throw FormatError.options("Unknown rule '\(proposedName)'")
        }
        throw FormatError.options("Unknown rule '\(proposedName)'. Did you mean '\(match)'?")
    }
}

/// Parse single file path, disallowing globs or commas
func parsePath(_ path: String, for argument: String, in directory: String) throws -> URL {
    let expandedPath = expandPath(path, in: directory)
    if !FileManager.default.fileExists(atPath: expandedPath.path) {
        if path.contains(",") {
            throw FormatError.options("\(argument) argument does not support multiple paths")
        }
        if pathContainsGlobSyntax(path) {
            throw FormatError.options("\(argument) path cannot contain wildcards")
        }
    }
    return expandedPath
}

/// Parse one or more comma-delimited file paths, expanding globs as required
func parsePaths(_ paths: String, in directory: String) throws -> [URL] {
    try matchGlobs(expandGlobs(paths, in: directory), in: directory)
}

/// Merge two dictionaries of arguments
func mergeArguments(_ args: [String: String], into config: [String: String]) throws -> [String: String] {
    var input = config
    var output = args
    // Merge excluded urls
    if let exclude = output["exclude"].map(parseCommaDelimitedList),
       var excluded = input["exclude"].map({ Set(parseCommaDelimitedList($0)) })
    {
        excluded.formUnion(exclude)
        output["exclude"] = Array(excluded).sorted().joined(separator: ",")
    }
    // Merge unexcluded urls
    if let unexclude = output["unexclude"].map(parseCommaDelimitedList),
       var unexcluded = input["unexclude"].map({ Set(parseCommaDelimitedList($0)) })
    {
        unexcluded.formUnion(unexclude)
        output["unexclude"] = Array(unexcluded).sorted().joined(separator: ",")
    }
    // Merge rules
    if let rules = try output["rules"].map(parseRules) {
        if rules.isEmpty {
            output["rules"] = nil
        } else {
            input["rules"] = nil
            input["enable"] = nil
            input["disable"] = nil
            input["lint-only"] = nil
        }
    } else {
        if let _disable = try output["disable"].map(parseRules) {
            if let rules = try input["rules"].map(parseRules) {
                input["rules"] = Set(rules).subtracting(_disable).sorted().joined(separator: ",")
            }
            if let enable = try input["enable"].map(parseRules) {
                input["enable"] = Set(enable).subtracting(_disable).sorted().joined(separator: ",")
            }
            if let lintonly = try input["lint-only"].map(parseRules) {
                input["lint-only"] = Set(lintonly).subtracting(_disable).sorted().joined(separator: ",")
            }
            if let disable = try input["disable"].map(parseRules) {
                input["disable"] = Set(disable).union(_disable).sorted().joined(separator: ",")
                output["disable"] = nil
            }
        }
        if let _enable = try output["enable"].map(parseRules) {
            if let enable = try input["enable"].map(parseRules) {
                input["enable"] = Set(enable).union(_enable).sorted().joined(separator: ",")
                output["enable"] = nil
            }
            if let lintonly = try input["lint-only"].map(parseRules) {
                input["lint-only"] = Set(lintonly).subtracting(_enable).sorted().joined(separator: ",")
            }
            if let disable = try input["disable"].map(parseRules) {
                input["disable"] = Set(disable).subtracting(_enable).sorted().joined(separator: ",")
            }
        }
        if let _lintonly = try output["lint-only"].map(parseRules) {
            if let lintonly = try input["lint-only"].map(parseRules) {
                input["lint-only"] = Set(lintonly).union(_lintonly).sorted().joined(separator: ",")
                output["lint-only"] = nil
            }
        }
    }
    // Merge other arguments
    for (key, inValue) in input where output[key] == nil {
        output[key] = inValue
    }
    return output
}

/// Parse a configuration file into a dictionary of arguments
public func parseConfigFile(_ data: Data) throws -> [String: String] {
    guard let input = String(data: data, encoding: .utf8) else {
        throw FormatError.reading("Unable to read data for configuration file")
    }
    let lines = try cumulate(successiveLines: input.components(separatedBy: .newlines))
    let arguments = try lines.flatMap { line -> [String] in
        // TODO: parseArguments isn't a perfect fit here - should we use a different approach?
        let line = line.replacingOccurrences(of: "\\n", with: "\n")
        let parts = parseArguments(line, ignoreComments: false).dropFirst().map {
            $0.replacingOccurrences(of: "\n", with: "\\n")
        }
        guard let key = parts.first else {
            return []
        }
        if !key.hasPrefix("-") {
            throw FormatError.options("Unknown option '\(key)' in configuration file")
        }
        return [key, parts.dropFirst().joined(separator: " ")]
    }
    do {
        return try preprocessArguments(arguments, optionsArguments)
    } catch let FormatError.options(message) {
        throw FormatError.options("\(message) in configuration file")
    }
}

private func cumulate(successiveLines: [String]) throws -> [String] {
    var cumulatedLines = [String]()
    var iterator = successiveLines.makeIterator()
    while let currentLine = iterator.next() {
        var cumulatedLine = contentBeforeUnquotedComment(in: currentLine).trimmingCharacters(in: .whitespaces)
        while cumulatedLine.hasSuffix("\\") {
            guard let nextLine = iterator.next() else {
                throw FormatError.reading("Configuration file ends with an illegal line continuation character '\'")
            }
            if !nextLine.trimmingCharacters(in: .whitespaces).starts(with: "#") {
                cumulatedLine = cumulatedLine.dropLast() + contentBeforeUnquotedComment(in: nextLine).trimmingCharacters(in: .whitespaces)
            }
        }
        cumulatedLines.append(String(cumulatedLine))
    }
    return cumulatedLines
}

/// Serialize a set of options into either an arguments string or a file
public func serialize(options: Options,
                      swiftVersion: Version = .undefined,
                      excludingDefaults: Bool = false,
                      separator: String = "\n") -> String
{
    var arguments = [[String: String]]()
    if let fileOptions = options.fileOptions {
        arguments.append(argumentsFor(
            Options(fileOptions: fileOptions),
            excludingDefaults: excludingDefaults
        ))
    }
    if let formatOptions = options.formatOptions {
        arguments.append(argumentsFor(
            Options(formatOptions: formatOptions),
            excludingDefaults: excludingDefaults
        ))
    } else if swiftVersion != .undefined {
        let descriptor = Descriptors.swiftVersion
        arguments.append([descriptor.argumentName: swiftVersion.rawValue])
    }
    if let rules = options.rules {
        arguments.append(argumentsFor(
            Options(rules: rules),
            excludingDefaults: excludingDefaults
        ))
    }
    return arguments
        .map { serialize(arguments: $0, separator: separator) }
        .filter { !$0.isEmpty }
        .joined(separator: separator)
}

/// Serialize arguments
func serialize(arguments: [String: String],
               separator: String = "\n") -> String
{
    arguments.map {
        var value = $1
        if value.contains(" ") {
            value = "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
        }
        if value.contains("#") {
            value = "\"\(value)\""
        }
        return "--\($0) \(value)"
    }.sorted().joined(separator: separator)
}

/// Get command line arguments from options
func argumentsFor(_ options: Options, excludingDefaults: Bool = false) -> [String: String] {
    var args = [String: String]()
    if let fileOptions = options.fileOptions {
        var arguments = Set(fileArguments)
        do {
            if !excludingDefaults || fileOptions.followSymlinks != FileOptions.default.followSymlinks {
                args["symlinks"] = fileOptions.followSymlinks ? "follow" : "ignore"
            }
            arguments.remove("symlinks")
        }
        do {
            if !fileOptions.excludedGlobs.isEmpty {
                // TODO: find a better alternative to stringifying url
                args["exclude"] = fileOptions.excludedGlobs.map(\.description).sorted().joined(separator: ",")
            }
            arguments.remove("exclude")
        }
        do {
            if !fileOptions.unexcludedGlobs.isEmpty {
                // TODO: find a better alternative to stringifying url
                args["unexclude"] = fileOptions.unexcludedGlobs.map(\.description).sorted().joined(separator: ",")
            }
            arguments.remove("unexclude")
        }
        do {
            if !excludingDefaults || fileOptions.minVersion != FileOptions.default.minVersion {
                args["min-version"] = fileOptions.minVersion.description
            }
            arguments.remove("min-version")
        }
        do {
            if !excludingDefaults || fileOptions.markdownFormattingMode != nil {
                args["markdown-files"] = fileOptions.markdownFormattingMode?.rawValue ?? "ignore"
            }
            arguments.remove("markdown-files")
        }
        assert(arguments.isEmpty)
    }
    if let formatOptions = options.formatOptions {
        for descriptor in Descriptors.all where !descriptor.isRenamed {
            let value = descriptor.fromOptions(formatOptions)
            guard value != descriptor.fromOptions(.default) ||
                (!excludingDefaults && !descriptor.isDeprecated)
            else {
                continue
            }
            // Special case for swiftVersion and languageMode
            // TODO: find a better solution for this
            if descriptor.argumentName == Descriptors.swiftVersion.argumentName,
               value == Version.undefined.rawValue
            {
                continue
            }
            if descriptor.argumentName == Descriptors.languageMode.argumentName,
               value == defaultLanguageMode(for: formatOptions.swiftVersion).rawValue
            {
                continue
            }
            args[descriptor.argumentName] = value
        }
    }
    if options.lint {
        args["lint"] = ""
    }
    if let rules = options.rules {
        let enabled = rules.subtracting(defaultRules)
        if !enabled.isEmpty {
            args["enable"] = enabled.sorted().joined(separator: ",")
        }

        let disabled = defaultRules.subtracting(rules)
        if !disabled.isEmpty {
            args["disable"] = disabled.sorted().joined(separator: ",")
        }
    }
    return args
}

private func processOption(_ key: String,
                           in args: [String: String],
                           from: inout Set<String>,
                           handler: (String) throws -> Void) throws
{
    precondition(optionsArguments.contains(key), "\(key) not in optionsArguments")
    var arguments = from
    arguments.remove(key)
    from = arguments
    guard let value = args[key] else {
        return
    }
    do {
        try handler(value)
    } catch {
        guard !value.isEmpty else {
            throw FormatError.options("--\(key) option expects a value")
        }
        if case var FormatError.options(string) = error, !string.isEmpty {
            if !string.contains(key) {
                string += " in --\(key)"
            }
            throw FormatError.options(string)
        }
        throw FormatError.options("Unsupported --\(key) value '\(value)'")
    }
}

/// Parse rule names from arguments
public func rulesFor(_ args: [String: String], lint: Bool, initial: Set<String>? = nil) throws -> Set<String> {
    var rules = initial ?? allRules
    rules = try args["rules"].map {
        try Set(parseRules($0))
    } ?? rules.subtracting(FormatRules.disabledByDefault.map(\.name))
    try args["disable"].map {
        try rules.subtract(parseRules($0))
    }
    try args["enable"].map {
        try rules.formUnion(parseRules($0))
    }
    try args["lint-only"].map { rulesString in
        if lint {
            try rules.formUnion(parseRules(rulesString))
        } else {
            try rules.subtract(parseRules(rulesString))
        }
    }
    return rules
}

/// Parse FileOptions from arguments
func fileOptionsFor(_ args: [String: String], in directory: String) throws -> FileOptions? {
    var options = FileOptions()
    var arguments = Set(fileArguments)

    var containsFileOption = false
    try processOption("symlinks", in: args, from: &arguments) {
        containsFileOption = true
        switch $0.lowercased() {
        case "follow":
            options.followSymlinks = true
        case "ignore":
            options.followSymlinks = false
        default:
            throw FormatError.options("")
        }
    }
    try processOption("exclude", in: args, from: &arguments) {
        containsFileOption = true
        options.excludedGlobs += expandGlobs($0, in: directory)
    }
    try processOption("unexclude", in: args, from: &arguments) {
        containsFileOption = true
        options.unexcludedGlobs += expandGlobs($0, in: directory)
    }
    try processOption("min-version", in: args, from: &arguments) {
        containsFileOption = true
        guard let minVersion = Version(rawValue: $0) else {
            throw FormatError.options("Unsupported --min-version value '\($0)'")
        }
        guard minVersion <= Version(stringLiteral: swiftFormatVersion) else {
            throw FormatError.options("Project specifies SwiftFormat --min-version of \(minVersion)")
        }
        options.minVersion = minVersion
    }
    try processOption("markdown-files", in: args, from: &arguments) {
        containsFileOption = true
        switch $0.lowercased() {
        case "ignore":
            break
        case MarkdownFormattingMode.lenient.rawValue:
            options.supportedFileExtensions.append("md")
            options.markdownFormattingMode = .lenient
        case MarkdownFormattingMode.strict.rawValue:
            options.supportedFileExtensions.append("md")
            options.markdownFormattingMode = .strict
        default:
            throw FormatError.options("""
            Valid options for --markdown-files are 'ignore' (default), \
            'format-lenient', or 'format-strict'.
            """)
        }
    }
    assert(arguments.isEmpty, "\(arguments.joined(separator: ","))")
    return containsFileOption ? options : nil
}

/// Parse FormatOptions from arguments
/// Returns nil if the arguments dictionary does not contain any formatting arguments
public func formatOptionsFor(_ args: [String: String]) throws -> FormatOptions? {
    var options = FormatOptions.default
    let containsFormatOption = try applyFormatOptions(from: args, to: &options)
    return containsFormatOption ? options : nil
}

public func applyFormatOptions(from args: [String: String], to formatOptions: inout FormatOptions) throws -> Bool {
    var arguments = Set(formattingArguments)
    var containsFormatOption = false
    for option in Descriptors.all {
        try processOption(option.argumentName, in: args, from: &arguments) {
            containsFormatOption = true
            try option.toOptions($0, &formatOptions)
        }
    }
    assert(arguments.isEmpty, "\(arguments.joined(separator: ","))")
    return containsFormatOption
}

/// Applies additional arguments to the given `Options` struct
func applyArguments(_ args: [String: String], lint: Bool, to options: inout Options) throws {
    options.rules = try rulesFor(args, lint: lint, initial: options.rules)

    var formatOptions = options.formatOptions ?? .default
    let containsFormatOption = try applyFormatOptions(from: args, to: &formatOptions)
    if containsFormatOption {
        options.formatOptions = formatOptions
    }
}

/// Get deprecation warnings from a set of arguments
func warningsForArguments(_ args: [String: String], ignoreUnusedOptions: Bool = false) -> [String] {
    var warnings = [String]()
    for option in Descriptors.all {
        if args[option.argumentName] != nil, let message = option.deprecationMessage {
            warnings.append("--\(option.argumentName) option is deprecated. \(message)")
        }
    }
    for name in Set(rulesArguments.flatMap { (try? args[$0].map(parseRules) ?? []) ?? [] }) {
        if let message = FormatRules.byName[name]?.deprecationMessage {
            warnings.append("\(name) rule is deprecated. \(message)")
        }
    }
    if !ignoreUnusedOptions, let rules = try? rulesFor(args, lint: true) {
        for arg in args.keys where formattingArguments.contains(arg) {
            if !rules.contains(where: {
                guard let rule = FormatRules.byName[$0] else {
                    return false
                }
                return rule.options.contains(arg) || rule.sharedOptions.contains(arg)
            }), let expected = FormatRules.all.first(where: {
                $0.options.contains(arg)
            })?.name {
                warnings.append("--\(arg) option has no effect when \(expected) rule is disabled")
            }
        }
    }
    return warnings
}

let fileArguments = [
    "symlinks",
    "exclude",
    "unexclude",
    "min-version",
    "markdown-files",
]

let rulesArguments = [
    "disable",
    "enable",
    "lint-only",
    "rules",
]

let formattingArguments = Descriptors.formatting.map(\.argumentName)
let internalArguments = Descriptors.internal.map(\.argumentName)
let optionsArguments = fileArguments + rulesArguments + formattingArguments + internalArguments

let commandLineArguments = [
    // Input options
    "filelist",
    "stdin-path",
    "script-input",
    "config",
    "base-config",
    "infer-options",
    "line-range",
    "output",
    "cache",
    "dry-run",
    "lint",
    "lenient",
    "strict",
    "verbose",
    "quiet",
    "reporter",
    "report",
    // Misc
    "help",
    "version",
    "options",
    "rule-info",
    "date-format",
    "timezone",
    "output-tokens",
] + optionsArguments

let deprecatedArguments = Descriptors.deprecated.map(\.argumentName)
