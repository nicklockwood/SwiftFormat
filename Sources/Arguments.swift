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
    static let maxArgumentNameLength = 16

    init(_ args: [String: String], in directory: String) throws {
        fileOptions = try fileOptionsFor(args, in: directory)
        formatOptions = try formatOptionsFor(args)
        rules = try rulesFor(args)
    }

    mutating func addArguments(_ args: [String: String], in directory: String) throws {
        let oldArguments = argumentsFor(self)
        let newArguments = try mergeArguments(args, into: oldArguments)
        var newOptions = try Options(newArguments, in: directory)
        if let fileInfo = formatOptions?.fileInfo {
            newOptions.formatOptions?.fileInfo = fileInfo
        }
        self = newOptions
    }
}

// Parse a space-delimited string into an array of command-line arguments
// Replicates the behavior implemented by the console when parsing input
func parseArguments(_ argumentString: String, ignoreComments: Bool = true) -> [String] {
    var arguments = [""] // Arguments always begin with script path
    var characters = String.UnicodeScalarView.SubSequence(argumentString.unicodeScalars)
    var string = ""
    var escaped = false
    var quoted = false
    loop: while let char = characters.popFirst() {
        switch char {
        case "#" where !ignoreComments && !escaped && !quoted:
            break loop // comment
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

// Parse a flat array of command-line arguments into a dictionary of flags and values
func preprocessArguments(_ args: [String], _ names: [String]) throws -> [String: String] {
    var anonymousArgs = 0
    var namedArgs: [String: String] = [:]
    var name = ""
    for arg in args {
        if arg.hasPrefix("--") {
            // Long argument names
            let key = String(arg.unicodeScalars.dropFirst(2))
            if !names.contains(key) {
                throw FormatError.options("Unknown option --\(key)")
            }
            name = key
            namedArgs[name] = namedArgs[name] ?? ""
            continue
        } else if arg.hasPrefix("-") {
            // Short argument names
            let flag = String(arg.unicodeScalars.dropFirst())
            let matches = names.filter { $0.hasPrefix(flag) }
            if matches.count > 1 {
                throw FormatError.options("Ambiguous flag -\(flag)")
            } else if matches.isEmpty {
                throw FormatError.options("Unknown flag -\(flag)")
            } else {
                name = matches[0]
                namedArgs[name] = namedArgs[name] ?? ""
            }
            continue
        }
        if name == "" {
            // Argument is anonymous
            name = String(anonymousArgs)
            anonymousArgs += 1
        }
        if let existing = namedArgs[name], !existing.isEmpty,
            // TODO: find a more general way to represent merge-able options
            ["exclude", "unexclude", "disable", "enable", "rules"].contains(name) ||
            FormatOptions.Descriptor.all.contains(where: {
                $0.argumentName == name && $0.isSetType
            })
        {
            namedArgs[name] = existing + "," + arg
        } else {
            namedArgs[name] = arg
        }
        name = ""
    }
    return namedArgs
}

// Parse a comma-delimited list of items
func parseCommaDelimitedList(_ string: String) -> [String] {
    return string.components(separatedBy: ",").compactMap {
        let item = $0.trimmingCharacters(in: .whitespacesAndNewlines)
        return item.isEmpty ? nil : item
    }
}

// Parse a comma-delimited string into an array of rules
let allRules = Set(FormatRules.byName.keys)
func parseRules(_ rules: String) throws -> [String] {
    return try parseCommaDelimitedList(rules).map { proposedName in
        if let name = allRules.first(where: {
            $0.lowercased() == proposedName.lowercased()
        }) {
            return name
        }
        if FormatOptions.Descriptor.all.contains(where: {
            $0.argumentName == proposedName
        }) {
            for rule in FormatRules.all where rule.options.contains(proposedName) {
                throw FormatError.options(
                    "'\(proposedName)' is not a formatting rule. Did you mean '\(rule.name)'?"
                )
            }
            throw FormatError.options("'\(proposedName)' is not a formatting rule")
        }
        throw FormatError.options("Unknown rule '\(proposedName)'")
    }
}

// Parse single file path
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

// Parse one or more comma-delimited file paths
func parsePaths(_ paths: String, for argument: String, in directory: String) throws -> [URL] {
    return try parseCommaDelimitedList(paths).map {
        try parsePath($0, for: argument, in: directory)
    }
}

// Merge two dictionaries of arguments
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
        }
    } else {
        if let _disable = try output["disable"].map(parseRules) {
            if let rules = try input["rules"].map(parseRules) {
                input["rules"] = Set(rules).subtracting(_disable).sorted().joined(separator: ",")
            }
            if let enable = try input["enable"].map(parseRules) {
                input["enable"] = Set(enable).subtracting(_disable).sorted().joined(separator: ",")
            }
            if let disable = try input["disable"].map(parseRules) {
                input["disable"] = Set(disable).union(_disable).sorted().joined(separator: ",")
                output["disable"] = nil
            }
        }
        if let _enable = try args["enable"].map(parseRules) {
            if let enable = try input["enable"].map(parseRules) {
                input["enable"] = Set(enable).union(_enable).sorted().joined(separator: ",")
                output["enable"] = nil
            }
            if let disable = try input["disable"].map(parseRules) {
                input["disable"] = Set(disable).subtracting(_enable).sorted().joined(separator: ",")
            }
        }
    }
    // Merge other arguments
    for (key, inValue) in input {
        guard let outValue = output[key] else {
            output[key] = inValue
            continue
        }
        if FormatOptions.Descriptor.all.contains(where: { $0.argumentName == key && $0.isSetType }) {
            let inOptions = parseCommaDelimitedList(inValue)
            let outOptions = parseCommaDelimitedList(outValue)
            output[key] = Set(inOptions).union(outOptions).sorted().joined(separator: ",")
        }
    }
    return output
}

// Parse a configuration file into a dictionary of arguments
func parseConfigFile(_ data: Data) throws -> [String: String] {
    guard let input = String(data: data, encoding: .utf8) else {
        throw FormatError.reading("Unable to read data for configuration file")
    }
    let lines = input.components(separatedBy: .newlines)
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

// Serialize a set of options into either an arguments string or a file
func serialize(options: Options,
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
        let descriptor = FormatOptions.Descriptor.swiftVersion
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

// Serialize arguments
func serialize(arguments: [String: String],
               separator: String = "\n") -> String
{
    return arguments.map {
        var value = $1
        if value.contains(" ") {
            value = "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
        }
        return "--\($0) \(value)"
    }.sorted().joined(separator: separator)
}

// Get command line arguments from options
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
                args["exclude"] = fileOptions.excludedGlobs.map { $0.description }.sorted().joined(separator: ",")
            }
            arguments.remove("exclude")
        }
        do {
            if !fileOptions.unexcludedGlobs.isEmpty {
                // TODO: find a better alternative to stringifying url
                args["unexclude"] = fileOptions.unexcludedGlobs.map { $0.description }.sorted().joined(separator: ",")
            }
            arguments.remove("unexclude")
        }
        do {
            if !excludingDefaults || fileOptions.minVersion != FileOptions.default.minVersion {
                args["minversion"] = fileOptions.minVersion.description
            }
            arguments.remove("minversion")
        }
        assert(arguments.isEmpty)
    }
    if let formatOptions = options.formatOptions {
        for descriptor in FormatOptions.Descriptor.all where !descriptor.isRenamed {
            let value = descriptor.fromOptions(formatOptions)
            guard value != descriptor.fromOptions(.default) ||
                (!excludingDefaults && !descriptor.isDeprecated)
            else {
                continue
            }
            // Special case for swiftVersion
            // TODO: find a better solution for this
            if descriptor.argumentName == FormatOptions.Descriptor.swiftVersion.argumentName,
                value == Version.undefined.rawValue
            {
                continue
            }
            args[descriptor.argumentName] = value
        }
        // Special case for wrapParameters
        let argumentName = FormatOptions.Descriptor.wrapParameters.argumentName
        if args[argumentName] == WrapMode.default.rawValue {
            args[argumentName] = args[FormatOptions.Descriptor.wrapArguments.argumentName]
        }
    }
    if let rules = options.rules {
        let defaultRules = allRules.subtracting(FormatRules.disabledByDefault)

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

// Parse rule names from arguments
func rulesFor(_ args: [String: String]) throws -> Set<String> {
    var rules = allRules
    rules = try args["rules"].map {
        try Set(parseRules($0))
    } ?? rules.subtracting(FormatRules.disabledByDefault)
    try args["enable"].map {
        try rules.formUnion(parseRules($0))
    }
    try args["disable"].map {
        try rules.subtract(parseRules($0))
    }
    return rules
}

// Parse FileOptions from arguments
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
    try processOption("minversion", in: args, from: &arguments) {
        containsFileOption = true
        guard let minVersion = Version(rawValue: $0) else {
            throw FormatError.options("Unsupported --minversion value '\($0)'")
        }
        guard minVersion <= Version(stringLiteral: swiftFormatVersion) else {
            throw FormatError.options("Project specifies SwiftFormat --minversion of \(minVersion)")
        }
        options.minVersion = minVersion
    }
    assert(arguments.isEmpty, "\(arguments.joined(separator: ","))")
    return containsFileOption ? options : nil
}

// Parse FormatOptions from arguments
// Returns nil if the arguments dictionary does not contain any formatting arguments
func formatOptionsFor(_ args: [String: String]) throws -> FormatOptions? {
    var options = FormatOptions.default
    var arguments = Set(formattingArguments)

    var containsFormatOption = false
    for option in FormatOptions.Descriptor.all {
        try processOption(option.argumentName, in: args, from: &arguments) {
            containsFormatOption = true
            try option.toOptions($0, &options)
        }
    }
    assert(arguments.isEmpty, "\(arguments.joined(separator: ","))")
    return containsFormatOption ? options : nil
}

// Get deprecation warnings from a set of arguments
func warningsForArguments(_ args: [String: String]) -> [String] {
    var warnings = [String]()
    for option in FormatOptions.Descriptor.all {
        if args[option.argumentName] != nil, let message = option.deprecationMessage {
            warnings.append(message)
        }
    }
    for name in Set(rulesArguments.flatMap { (try? args[$0].map(parseRules) ?? []) ?? [] }) {
        if let message = FormatRules.byName[name]?.deprecationMessage {
            warnings.append(message)
        }
    }
    return warnings
}

let fileArguments = [
    "symlinks",
    "exclude",
    "unexclude",
    "minversion",
]

let rulesArguments = [
    "disable",
    "enable",
    "rules",
]

let formattingArguments = FormatOptions.Descriptor.formatting.map { $0.argumentName }
let internalArguments = FormatOptions.Descriptor.internal.map { $0.argumentName }
let optionsArguments = fileArguments + rulesArguments + formattingArguments + internalArguments

let commandLineArguments = [
    // Input options
    "filelist",
    "stdinpath",
    "config",
    "inferoptions",
    "linerange",
    "output",
    "cache",
    "dryrun",
    "lint",
    "lenient",
    "verbose",
    "quiet",
    // Misc
    "help",
    "version",
    "options",
    "ruleinfo",
] + optionsArguments

let deprecatedArguments = FormatOptions.Descriptor.all.compactMap {
    $0.isDeprecated ? $0.argumentName : nil
}
