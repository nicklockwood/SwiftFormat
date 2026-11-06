//
//  SwiftFormat.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
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
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

/// The current SwiftFormat version
let swiftFormatVersion = "0.64.6"
public let version = swiftFormatVersion

/// The standard SwiftFormat config file name
public let swiftFormatConfigurationFile = ".swiftformat"

/// The standard Swift version file name
public let swiftVersionFile = ".swift-version"

/// Supported Swift compiler versions
public let swiftVersions = [
    "3.x", "4.0", "4.1", "4.2",
    "5.0", "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8", "5.9", "5.10",
    "6.0", "6.1", "6.2", "6.3", "6.4",
]

/// Supported Swift language modes
public let languageModes = [
    "4", "4.2", "5", "6",
]

/// The default language mode for the given Swift compiler version
func defaultLanguageMode(for compilerVersion: Version) -> Version {
    switch compilerVersion {
    case "4.0" ..< "4.2":
        return "4"
    case "4.2":
        return "4.2"
    case "5.0" ..< "6.0":
        return "5"
    case "6.0"...:
        // The default language mode in Swift 6.0 is Swift 5 mode.
        // https://developer.apple.com/documentation/swift/adoptingswift6
        return "5"
    default:
        return .undefined
    }
}

/// An enumeration of the types of error that may be thrown by SwiftFormat
public enum FormatError: Error, CustomStringConvertible, LocalizedError, CustomNSError {
    case reading(String)
    case writing(String)
    case parsing(String)
    case options(String)

    static func invalidOption(
        _ option: String,
        for argumentName: String,
        with validOptions: [String]
    ) -> Self {
        let message = "Unsupported --\(argumentName) value '\(option)'"
        guard let match = option.bestMatch(in: validOptions) else {
            return .options("\(message). Valid options are \(validOptions.formattedList())")
        }
        return .options("\(message). Did you mean '\(match)'?")
    }

    public var description: String {
        switch self {
        case let .reading(string),
             let .writing(string),
             let .parsing(string),
             let .options(string):
            return string
        }
    }

    public var localizedDescription: String {
        "Error: \(description)."
    }

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }
}

/// Callback for enumerateFiles() function
public typealias FileEnumerationHandler = (
    _ inputURL: URL,
    _ ouputURL: URL,
    _ options: Options
) throws -> () throws -> Void

/// Callback for logging info and warnings
public struct Logger {
    let print: (String, CLI.OutputType) -> Void

    public func info(_ message: String) {
        print(message, .info)
    }

    public func warn(_ message: String) {
        print(message, .warning)
    }
}

/// Deprecated callback for informational messages.
@available(*, deprecated, message: "Use Logger instead")
public typealias LegacyLogger = (String) -> Void

/// Enumerate all Swift files at the specified location and (optionally) calculate an output file URL for each.
/// Ignores the file if any of the excluded file URLs is a prefix of the input file URL.
///
/// Files are enumerated concurrently. For convenience, the enumeration block returns a completion block, which
/// will be executed synchronously on the calling thread once enumeration is complete.
///
/// Errors may be thrown by either the enumeration block or the completion block, and are gathered into an
/// array and returned after enumeration is complete, along with any errors generated by the function itself.
/// Throwing an error from inside either block does *not* terminate the enumeration.
public func enumerateFiles(withInputURLs inputURLs: [URL],
                           outputURL: URL? = nil,
                           options baseOptions: Options = .default,
                           concurrent: Bool = true,
                           logger: Logger? = nil,
                           skipped: FileEnumerationHandler? = nil,
                           handler: @escaping FileEnumerationHandler) -> [Error]
{
    let manager = FileManager.default
    let keys: [URLResourceKey] = [
        .isRegularFileKey, .isDirectoryKey,
        .isAliasFileKey, .isSymbolicLinkKey,
        .creationDateKey, .pathKey,
    ]

    let group = DispatchGroup()
    var completionBlocks = [() throws -> Void]()
    let completionQueue = DispatchQueue(label: "swiftformat.enumeration")
    func onComplete(_ block: @escaping () throws -> Void) {
        completionQueue.async(group: group) {
            completionBlocks.append(block)
        }
    }

    let queue = concurrent ? DispatchQueue.global(qos: .userInitiated) : completionQueue

    func resolveInputURL(_ inputURL: URL, options: Options) -> (URL, URLResourceValues, Options)? {
        let fileOptions = options.fileOptions ?? .default
        let inputURL = inputURL.standardizedFileURL
        if options.shouldSkipFile(inputURL) {
            if let handler = skipped {
                do {
                    try onComplete(handler(inputURL, inputURL, options))
                } catch {
                    onComplete { throw error }
                }
            }
            return nil
        }
        do {
            let resourceValues = try getResourceValues(for: inputURL, keys: keys)
            #if os(macOS)
                if resourceValues.isAliasFile == true {
                    if fileOptions.followSymlinks {
                        guard let resolvedURL = try? URL(resolvingAliasFileAt: inputURL) else {
                            throw FormatError.options("Could not resolve alias at \(inputURL.path)")
                        }
                        return resolveInputURL(resolvedURL, options: options)
                    } else {
                        if let handler = skipped {
                            try onComplete(handler(inputURL, inputURL, options))
                        }
                        return nil
                    }
                }
            #endif
            if resourceValues.isSymbolicLink == true {
                if fileOptions.followSymlinks {
                    let resolvedURL = inputURL.resolvingSymlinksInPath()
                    return resolveInputURL(resolvedURL, options: options)
                } else {
                    if let handler = skipped {
                        try onComplete(handler(inputURL, inputURL, options))
                    }
                    return nil
                }
            } else {
                return (inputURL, resourceValues, options)
            }
        } catch {
            onComplete { throw error }
            return nil
        }
    }

    func enumerate(inputURL: URL,
                   outputURL: URL?,
                   options: Options)
    {
        assert(options.formatOptions != nil)
        guard let (inputURL, resourceValues, options) = resolveInputURL(inputURL, options: options) else {
            return
        }
        assert(options.formatOptions != nil)
        let fileOptions = options.fileOptions ?? .default
        if resourceValues.isRegularFile == true {
            if fileOptions.supportedFileExtensions.contains(inputURL.pathExtension) {
                let fileInfo = collectFileInfo(inputURL: inputURL,
                                               options: options,
                                               resourceValues: resourceValues)

                var options = options
                options.formatOptions?.fileInfo = fileInfo
                do {
                    try onComplete(handler(inputURL, outputURL ?? inputURL, options))
                } catch {
                    onComplete { throw error }
                }
            }
        } else if resourceValues.isDirectory == true {
            var tempOptions = options
            do {
                try processDirectory(inputURL, with: &tempOptions, logger: logger)
            } catch {
                onComplete { throw error }
                return
            }
            let options = tempOptions
            let fileOptions = options.fileOptions ?? .default
            let enumerationOptions: FileManager.DirectoryEnumerationOptions = .skipsHiddenFiles
            guard let files = try? manager.contentsOfDirectory(
                at: inputURL, includingPropertiesForKeys: keys, options: enumerationOptions
            ) else {
                onComplete { throw FormatError.reading("Failed to read contents of directory at \(inputURL.path)") }
                return
            }
            for url in files where !url.path.hasPrefix(".") && !fileOptions.shouldSkipBuildDirectory(url) {
                let options = options
                queue.async(group: group) {
                    let outputURL = outputURL.map {
                        URL(fileURLWithPath: $0.path + url.path[inputURL.path.endIndex ..< url.path.endIndex])
                    }
                    enumerate(inputURL: url, outputURL: outputURL, options: options)
                }
            }
        }
    }

    for inputURL in inputURLs {
        queue.async(group: group) {
            var options = baseOptions
            var inputURL = inputURL
            if options.formatOptions == nil {
                options.formatOptions = .default
            }
            do {
                try gatherOptions(&options, for: inputURL, with: logger)
                guard let (resolvedURL, resourceValues, _) = resolveInputURL(inputURL, options: options) else {
                    return
                }
                inputURL = resolvedURL
                let fileOptions = options.fileOptions ?? .default
                if resourceValues.isDirectory == false,
                   !fileOptions.supportedFileExtensions.contains(inputURL.pathExtension)
                {
                    throw FormatError.options("Unsupported file type: \(inputURL.path)")
                }
            } catch {
                onComplete { throw error }
                return
            }
            enumerate(inputURL: inputURL, outputURL: outputURL, options: options)
        }
    }
    group.wait()

    var errors = [Error]()
    for block in completionBlocks {
        do {
            try block()
        } catch {
            errors.append(error)
        }
    }
    return errors
}

@available(*, deprecated)
public func enumerateFiles(withInputURL inputURL: URL,
                           outputURL: URL? = nil,
                           options baseOptions: Options = .default,
                           concurrent: Bool = true,
                           logger: Logger? = nil,
                           skipped: FileEnumerationHandler? = nil,
                           handler: @escaping FileEnumerationHandler) -> [Error]
{
    enumerateFiles(withInputURLs: [inputURL],
                   outputURL: outputURL,
                   options: baseOptions,
                   concurrent: concurrent,
                   logger: logger,
                   skipped: skipped,
                   handler: handler)
}

@available(*, deprecated, message: "Use the Logger overload")
public func enumerateFiles(withInputURLs inputURLs: [URL], outputURL: URL? = nil,
                           options baseOptions: Options = .default, concurrent: Bool = true,
                           logger: @escaping LegacyLogger, skipped: FileEnumerationHandler? = nil,
                           handler: @escaping FileEnumerationHandler) -> [Error]
{
    enumerateFiles(withInputURLs: inputURLs, outputURL: outputURL, options: baseOptions,
                   concurrent: concurrent, logger: Logger { message, type in
                       if type == .info {
                           logger(message)
                       }
                   }, skipped: skipped, handler: handler)
}

@available(*, deprecated, message: "Use the Logger overload")
public func enumerateFiles(withInputURL inputURL: URL, outputURL: URL? = nil,
                           options baseOptions: Options = .default, concurrent: Bool = true,
                           logger: @escaping LegacyLogger, skipped: FileEnumerationHandler? = nil,
                           handler: @escaping FileEnumerationHandler) -> [Error]
{
    enumerateFiles(withInputURLs: [inputURL], outputURL: outputURL, options: baseOptions,
                   concurrent: concurrent, logger: logger, skipped: skipped, handler: handler)
}

func collectFileInfo(inputURL: URL, options: Options, resourceValues: URLResourceValues?) -> FileInfo {
    let fileHeaderRuleEnabled = options.rules?.contains(FormatRule.fileHeader.name) ?? false
    let shouldGetGitInfo = fileHeaderRuleEnabled &&
        options.formatOptions?.fileHeader.needsGitInfo == true

    let gitInfo = shouldGetGitInfo ? GitFileInfo(url: inputURL) : nil

    return FileInfo(
        filePath: resourceValues?.path ?? inputURL.path,
        creationDate: gitInfo?.creationDate ?? resourceValues?.creationDate,
        replacements: [
            .author: ReplacementType(gitInfo?.author),
            .authorName: ReplacementType(gitInfo?.authorName),
            .authorEmail: ReplacementType(gitInfo?.authorEmail),
        ].compactMapValues { $0 }
    )
}

/// Process configuration in all directories in specified path.
func gatherOptions(_ options: inout Options, for inputURL: URL, with logger: Logger?) throws {
    var directory = URL(fileURLWithPath: inputURL.pathComponents[0]).standardized
    for part in inputURL.pathComponents.dropFirst().dropLast() {
        directory.appendPathComponent(part)
        if options.shouldSkipFile(directory) {
            return
        }
        try processDirectory(directory, with: &options, logger: logger)
    }
}

/// Process configuration files in specified directory.
private var configCache = [URL: [[String: String]]]()
private let configQueue = DispatchQueue(label: "swiftformat.config", qos: .userInteractive)
private func processDirectory(_ inputURL: URL, with options: inout Options, logger: Logger?) throws {
    let inputURL = inputURL.standardizedFileURL
    let args = try configQueue.sync { () throws -> [[String: String]] in
        if let args = configCache[inputURL] {
            return args
        }

        let args = try parseConfigArguments(in: inputURL, options: options, logger: logger)
        configCache[inputURL] = args
        return args
    }

    assert(options.formatOptions != nil)
    var baseArgs = [[String: String]]()
    for args in args {
        // Sections with a `--filter` only apply to matching files, so store them separately
        if let filterValue = args["filter"] {
            let filters = try ConfigFilter.parseList(filterValue, in: inputURL.path)
            if !filters.isEmpty {
                options.filterOptions.append((filters, args))
            }
        } else {
            baseArgs.append(args)
        }
    }
    try options.addArguments(baseArgs, in: inputURL.path, logger: logger)
}

private func parseConfigArguments(in inputURL: URL, options: Options, logger: Logger?) throws -> [[String: String]] {
    var args = [[String: String]]()
    let manager = FileManager.default
    let configFile = inputURL.appendingPathComponent(swiftFormatConfigurationFile)
    if manager.fileExists(atPath: configFile.path) {
        if let configURLs = options.configURLs {
            let standardizedConfigFile = configFile.standardizedFileURL
            if !configURLs.contains(where: { $0.standardizedFileURL == standardizedConfigFile }) {
                logger?.info("Ignoring config file at \(configFile.path)")
            }
        } else {
            logger?.info("Reading config file at \(configFile.path)")
            let data = try Data(contentsOf: configFile)
            args = try parseConfigFile(data, logger: logger)
        }
    }
    let versionFile = inputURL.appendingPathComponent(swiftVersionFile)
    if manager.fileExists(atPath: versionFile.path) {
        // Don't read .swift-version from directories that will be excluded (affects no files)
        let baseArgs = args.filter { $0["filter"] == nil }
        var tempOptions = options
        try tempOptions.addArguments(baseArgs, in: inputURL.standardizedFileURL.path, logger: logger)
        if !tempOptions.shouldSkipFile(inputURL) {
            let versionString = try String(contentsOf: versionFile, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if baseArgs.contains(where: { $0["swift-version"] != nil }) {
                logger?.info("Ignoring swift-version file at \(versionFile.path)")
            } else if Version(rawValue: versionString) != nil {
                logger?.info("Reading swift-version file at \(versionFile.path) (version \(versionString))")
                // Add as a separate section so that it isn't limited to `--filter`ed files
                args.insert(["swift-version": versionString], at: 0)
            } else {
                // Don't treat as error, per: https://github.com/nicklockwood/SwiftFormat/issues/639
                // TODO: find a better solution for logging warnings here
                logger?.warn("Unrecognized swift version string '\(versionString)' in \(versionFile.path)")
            }
        }
    }
    return args
}

/// Line and column offset in source
/// Note: line and column indexes start at 1
public struct SourceOffset: Equatable, CustomStringConvertible {
    var line, column: Int

    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }

    public var description: String {
        "\(line):\(column)"
    }
}

/// Get offset for token
public func offsetForToken(at index: Int, in tokens: [Token], tabWidth: Int) -> SourceOffset {
    var column = 1
    for token in tokens[..<index].reversed() {
        switch token {
        case let .linebreak(_, line):
            return SourceOffset(line: line + 1, column: column)
        default:
            column += token.columnWidth(tabWidth: tabWidth)
        }
    }
    return SourceOffset(line: 1, column: column)
}

/// Get token index for offset
public func tokenIndex(for offset: SourceOffset, in tokens: [Token], tabWidth: Int) -> Int {
    var tokenIndex = 0, line = 1
    for index in tokens.indices {
        guard case let .linebreak(_, originalLine) = tokens[index] else {
            continue
        }
        line = originalLine
        guard originalLine < offset.line else {
            break
        }
        tokenIndex = index + 1
    }
    if line < offset.line - 1 {
        return tokens.endIndex
    }
    var column = 1
    while tokenIndex < tokens.endIndex, column < offset.column {
        column += tokens[tokenIndex].columnWidth(tabWidth: tabWidth)
        tokenIndex += 1
    }
    return tokenIndex
}

/// Deprecated
@available(*, deprecated, message: "Use tokenIndex(for:) instead")
public func tokenIndexForOffset(_ offset: SourceOffset, in tokens: [Token], tabWidth: Int) -> Int {
    tokenIndex(for: offset, in: tokens, tabWidth: tabWidth)
}

/// Get token index range for line range
public func tokenRange(forLineRange lineRange: ClosedRange<Int>, in tokens: [Token]) -> Range<Int> {
    let startOffset = SourceOffset(line: lineRange.lowerBound, column: 0)
    let endOffset = SourceOffset(line: lineRange.upperBound + 1, column: 0)
    // NOTE: tab width is not relevant for line-based offsets
    let tokenStart = max(0, tokenIndex(for: startOffset, in: tokens, tabWidth: 1) - 1)
    let tokenEnd = max(tokenStart, tokenIndex(for: endOffset, in: tokens, tabWidth: 1) - 1)
    return tokenStart ..< tokenEnd
}

/// Get new offset for an original offset (before formatting)
public func newOffset(for offset: SourceOffset, in tokens: [Token], tabWidth: Int) -> SourceOffset {
    var closestLine = 0
    for i in tokens.indices {
        guard case let .linebreak(_, originalLine) = tokens[i] else {
            continue
        }
        closestLine += 1
        guard originalLine >= offset.line else {
            continue
        }
        var lineLength = 0
        for j in (0 ..< i).reversed() {
            let token = tokens[j]
            if token.isLinebreak {
                break
            }
            lineLength += token.columnWidth(tabWidth: tabWidth)
        }
        return SourceOffset(line: closestLine, column: min(offset.column, lineLength + 1))
    }
    let lineLength = tokens.reduce(0) { $0 + $1.columnWidth(tabWidth: tabWidth) }
    return SourceOffset(line: closestLine + 1, column: min(offset.column, lineLength + 1))
}

/// Process parsing errors
public func parsingError(for tokens: [Token], options: FormatOptions, allowErrorsInFragments: Bool = true) -> FormatError? {
    guard let index = tokens.firstIndex(where: {
        guard (options.fragment && allowErrorsInFragments) || !$0.isError else { return true }
        guard !options.ignoreConflictMarkers, case let .operator(string, _) = $0 else {
            return false
        }
        return string.hasPrefix("<<<<<") || string.hasPrefix("=====") || string.hasPrefix(">>>>>")
    }) else {
        return nil
    }
    let message: String
    switch tokens[index] {
    case .error(""):
        message = "Unexpected end of file"
    case let .error(string):
        if string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            message = "Inconsistent whitespace in multi-line string literal"
        } else {
            message = "Unexpected token \(string)"
        }
    case let .operator(string, _):
        message = "Found conflict marker \(string)"
    default:
        preconditionFailure()
    }
    let offset = offsetForToken(at: index, in: tokens, tabWidth: options.tabWidth)
    return .parsing("\(message) at \(offset)")
}

/// Convert a token array back into a string
public func sourceCode(for tokens: [Token]?) -> String {
    (tokens ?? []).map(\.string).joined()
}

/// Update an editor's line array without replacing unchanged lines.
func replaceLines(in lines: NSMutableArray, with tokens: [Token]) {
    let originalLines = lines as! [String]
    var updatedLines = tokens.lines.map { sourceCode(for: Array($0)) }
    // Retain the editor's terminal empty line when the output still ends at a line boundary.
    if originalLines.last == "", tokens.last?.isLinebreak != false {
        updatedLines.append("")
    }
    // String equality alone would ignore changes between canonically equivalent Unicode representations.
    let areEqual: (String, String) -> Bool = { $0.utf8.elementsEqual($1.utf8) }

    var start = 0
    while start < min(originalLines.count, updatedLines.count),
          areEqual(originalLines[start], updatedLines[start])
    {
        start += 1
    }
    var oldEnd = originalLines.count, newEnd = updatedLines.count
    while oldEnd > start, newEnd > start,
          areEqual(originalLines[oldEnd - 1], updatedLines[newEnd - 1])
    {
        oldEnd -= 1
        newEnd -= 1
    }
    guard oldEnd > start || newEnd > start else { return }

    if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
        let difference = updatedLines[start ..< newEnd].difference(from: originalLines[start ..< oldEnd], by: areEqual)
        // CollectionDifference removes in descending order, then inserts in ascending order.
        for change in difference {
            switch change {
            case let .remove(offset, _, _):
                lines.removeObject(at: start + offset)
            case let .insert(offset, line, _):
                lines.insert(line, at: start + offset)
            }
        }
    } else {
        // On older systems, preserve the unchanged prefix and suffix of the buffer.
        replaceLineRange(in: lines, range: start ..< oldEnd, with: Array(updatedLines[start ..< newEnd]))
    }
}

/// Replace a line range using operations available on older systems.
func replaceLineRange(in lines: NSMutableArray, range: Range<Int>, with updatedLines: [String]) {
    for index in range.reversed() {
        lines.removeObject(at: index)
    }
    for (offset, line) in updatedLines.enumerated() {
        lines.insert(line, at: range.lowerBound + offset)
    }
}

/// Apply specified rules to a token array and optionally capture list of changes
public func applyRules(
    _ originalRules: [FormatRule],
    to originalTokens: [Token],
    with options: FormatOptions,
    trackChanges: Bool,
    range originalRange: Range<Int>?,
    logger: Logger? = nil,
    maxIterations: Int = 10
) throws -> (tokens: [Token], changes: [Formatter.Change]) {
    try applyRules(
        originalRules,
        to: originalTokens,
        with: options,
        trackChanges: trackChanges,
        range: originalRange,
        logger: logger,
        maxIterations: maxIterations,
        context: .empty
    )
}

func applyRules(
    _ originalRules: [FormatRule],
    to originalTokens: [Token],
    with options: FormatOptions,
    trackChanges: Bool,
    range originalRange: Range<Int>?,
    logger: Logger? = nil,
    maxIterations: Int = 10,
    context: FormattingContext
) throws -> (tokens: [Token], changes: [Formatter.Change]) {
    precondition(maxIterations > 1)

    let originalRules = originalRules.sorted()
    var tokens = originalTokens
    var range = originalRange

    // Ensure rule names have been set
    if originalRules.first?.name == FormatRule.unnamedRule {
        _ = FormatRules.all
    }

    // Check for parsing errors
    if let error = parsingError(for: originalTokens, options: options) {
        throw error
    }

    // Infer shared options
    var options = options
    options.enabledRules = Set(originalRules.map(\.name))
    let sharedOptions = FormatRules
        .sharedOptionsForRules(originalRules)
        .compactMap { Descriptors.byName[$0] }
        .filter { $0.defaultArgument == $0.fromOptions(options) }
        .map(\.propertyName)

    inferFormatOptions(sharedOptions, from: originalTokens, into: &options)

    // Check if required FileInfo is available
    if originalRules.contains(.fileHeader) {
        let header = options.fileHeader
        let fileInfo = options.fileInfo

        for key in ReplacementKey.allCases {
            if case let .replace(string) = header,
               !fileInfo.hasReplacement(for: key, options: options),
               string.contains(key.placeholder)
            {
                throw FormatError.options(
                    "Failed to apply \(key.placeholder) template in file header as required info is unavailable"
                )
            }
        }
    }

    // Split tokens into lines
    func getLines(in tokens: [Token], includingLinebreaks: Bool) -> [Int: ArraySlice<Token>] {
        var lines: [Int: ArraySlice<Token>] = [:]
        var startIndex = 0, nextLine = 1
        for (i, token) in tokens.enumerated() {
            if case let .linebreak(_, line) = token {
                let endIndex = i + (includingLinebreaks ? 1 : 0)
                if let existing = lines[line] {
                    lines[line] = tokens[existing.startIndex ..< endIndex]
                } else {
                    lines[line] = tokens[startIndex ..< endIndex]
                }
                nextLine = line + 1
                startIndex = i + 1
            }
        }
        lines[nextLine] = tokens[startIndex...]
        return lines
    }

    // Apply trim/indent rule once at start
    var rules = originalRules
    if rules.contains(.indent) {
        rules.insert(.indent, at: 0)
        if rules.contains(.trailingSpace) {
            rules.insert(.trailingSpace, at: 0)
        }
    }

    // Recursively apply rules until no changes are detected
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "swiftformat.formatting", qos: .userInteractive)
    let timeout = options.timeout + TimeInterval(originalTokens.count) / 1000
    var changes = [Formatter.Change]()
    var lastChanges = [Formatter.Change]()
    for iteration in 0 ..< maxIterations {
        let formatter = Formatter(tokens, options: options,
                                  trackChanges: trackChanges, range: range,
                                  logger: logger, context: context)
        let progress = RuleProgress()
        // The project index is shared by every file, so building it (or waiting for another file
        // to build it) is not charged to whichever rule happens to request it first.
        formatter.projectIndexRequestStateChanged = { progress.setIndexing($0) }
        queue.async(group: group) {
            for (index, rule) in rules.enumerated() {
                progress.begin(ruleAt: index)
                rule.apply(with: formatter)
            }
            // Cached declarations retain the formatter. Release them here, on the same queue
            // the rules ran on, so the formatter is never touched from two threads at once.
            formatter.clearDerivedCaches()
        }
        // Each rule is allowed `timeout` seconds of CPU time (see `RuleProgress`). Poll rather than
        // waiting for the whole timeout, as CPU time can lag far behind wall-clock time on a busy machine.
        let pollInterval = min(timeout, 0.1)
        while group.wait(timeout: .now() + pollInterval) == .timedOut {
            guard let timedOut = progress.timeout(after: timeout),
                  // The rules may have finished since the last wait
                  group.wait(timeout: .now()) == .timedOut
            else {
                continue
            }
            throw FormatError.writing(timedOut.message(for: rules))
        }

        // Abort if there are fatal errors
        if let error = formatter.errors.first, !options.fragment {
            throw error
        }

        // Record changes
        lastChanges = formatter.changes
        changes += lastChanges

        // Update range and discard unwanted changes
        var newTokens = formatter.tokens
        if let oldRange = range, let newRange = formatter.range {
            // Discard changes outside of specified range
            newTokens = Array(tokens[..<oldRange.lowerBound] + newTokens[newRange] + tokens[oldRange.upperBound...])
            range = oldRange.lowerBound ..< (oldRange.lowerBound + newRange.count)
        }

        // Terminate early if there were no changes
        if tokens == newTokens {
            if changes.isEmpty {
                return (tokens, [])
            }

            // Sort changes
            changes.sort(by: {
                if $0.line == $1.line {
                    return $0.rule.name < $1.rule.name
                }
                return $0.line < $1.line
            })

            // Get lines
            let oldLines = getLines(in: originalTokens, includingLinebreaks: true)
            let newLines = getLines(in: tokens, includingLinebreaks: true)

            // Filter out duplicates and lines that haven't changed
            var last: Formatter.Change?
            changes = changes.filter { change in
                if last == change {
                    return false
                }
                last = change
                // Filter out lines that haven't changed from their original line in
                // the input code, unless the change was explicitly marked as a move.
                if !change.isMove, newLines[change.line] == oldLines[change.line] {
                    return false
                }
                return true
            }
            return (tokens, changes)
        }

        // Update tokens
        tokens = newTokens

        // Remove rules that should only be run once
        if iteration == 0 {
            rules = originalRules
            rules.removeAll(where: { $0.runOnceOnly })
        }
    }

    // If we got here, formatting failed to terminate within max iterations
    let rulesApplied = Set(lastChanges.map(\.rule.name)).sorted()
    guard !rulesApplied.isEmpty else {
        // No rules were applied this time (maybe something else went wrong?)
        throw FormatError.writing("Failed to terminate")
    }
    let names = rulesApplied.count == 1 ?
        "\(rulesApplied[0]) rule" :
        "\(rulesApplied.formattedList(lastSeparator: "and")) rules"
    let changeLines = Set(lastChanges.map { "\($0.line)" }).sorted()
    let lines = changeLines.count == 1 ?
        "line \(changeLines[0])" :
        "lines \(changeLines.formattedList(lastSeparator: "and"))"
    throw FormatError.writing("The \(names) failed to terminate at \(lines)")
}

/// Format a pre-parsed token array
/// Returns the formatted token array
public func format(
    _ tokens: [Token], rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, range: Range<Int>? = nil
) throws -> (tokens: [Token], changes: [Formatter.Change]) {
    try applyRules(rules, to: tokens, with: options, trackChanges: true, range: range)
}

/// Format code with specified rules and options
public func format(
    _ source: String, rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, lineRange: ClosedRange<Int>? = nil
) throws -> (output: String, changes: [Formatter.Change]) {
    let tokens = tokenize(source)
    let range = lineRange.map { tokenRange(forLineRange: $0, in: tokens) }
    let output = try format(tokens, rules: rules, options: options, range: range)
    return (sourceCode(for: output.tokens), output.changes)
}

/// Lint a pre-parsed token array
/// Returns the list of edits made
public func lint(
    _ tokens: [Token], rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, range: Range<Int>? = nil
) throws -> [Formatter.Change] {
    try applyRules(rules, to: tokens, with: options, trackChanges: true, range: range).changes
}

/// Lint code with specified rules and options
public func lint(
    _ source: String, rules: [FormatRule] = FormatRules.default,
    options: FormatOptions = .default, lineRange: ClosedRange<Int>? = nil
) throws -> [Formatter.Change] {
    let tokens = tokenize(source)
    let range = lineRange.map { tokenRange(forLineRange: $0, in: tokens) }
    return try lint(tokens, rules: rules, options: options, range: range)
}

// MARK: Path utilities

public func expandPath(_ path: String, in directory: String) -> URL {
    let nsPath: NSString = (path as NSString).expandingTildeInPath as NSString
    if nsPath.isAbsolutePath {
        return URL(fileURLWithPath: nsPath as String).standardized
    }
    return URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(path).standardized
}

func getResourceValues(for url: URL, keys: [URLResourceKey]) throws -> URLResourceValues {
    if let resourceValues = try? url.resourceValues(forKeys: Set(keys)) {
        return resourceValues
    }
    if FileManager.default.fileExists(atPath: url.path) {
        throw FormatError.reading("Failed to read attributes for \(url.path)")
    }
    throw FormatError.options("File not found at \(url.path)")
}

// MARK: Documentation utilities

/// Strip markdown code-formatting
func stripMarkdown(_ input: String) -> String {
    var result = ""
    var startCount = 0
    var endCount = 0
    var escaped = false
    for c in input {
        if c == "`" {
            if escaped {
                endCount += 1
            } else {
                startCount += 1
            }
        } else {
            if escaped, endCount > 0 {
                if endCount != startCount {
                    result += String(repeating: "`", count: endCount)
                } else {
                    escaped = false
                    startCount = 0
                }
                endCount = 0
            }
            if startCount > 0 {
                escaped = true
            }
            result.append(c)
        }
    }
    return result
}

/// The rule currently being applied, shared between the formatting queue and the waiting thread.
///
/// The rule timeout exists to catch rules that never terminate, so it is measured in CPU time used by
/// the thread applying the rule rather than in wall-clock time. Otherwise a rule that is merely waiting
/// for a CPU – for example when many files are formatted concurrently on a loaded CI machine – would be
/// reported as having timed out. Where per-thread CPU time is unavailable, wall-clock time since the
/// rule started is used instead.
///
/// Waiting for a thread to run the rules on is not counted against any rule, but is limited separately
/// and reported as overload rather than as a rule bug, so that a real stall still fails instead of hanging.
/// Building the shared project index is not counted against the rule that requested it either, but has
/// its own wall-clock limit instead (see `setIndexing(_:)`).
final class RuleProgress {
    enum Timeout: Equatable {
        /// The rule at `index` exceeded the timeout.
        case rule(index: Int)
        /// No rule started within `limit` seconds of the progress being created.
        case notStarted(limit: TimeInterval)
        /// Building the project index, or waiting for another file to build it, did not finish within `limit` seconds.
        case projectIndex(limit: TimeInterval)

        func message(for rules: [FormatRule]) -> String {
            switch self {
            case let .rule(index):
                return "\(rules[index].name) rule timed out"
            case let .notStarted(limit):
                return "formatting did not start within \(Int(limit.rounded(.up)))s (the system may be overloaded)"
            case let .projectIndex(limit):
                return "building the project index did not finish within \(Int(limit.rounded(.up)))s"
            }
        }
    }

    /// Wall-clock backstop, as a multiple of the timeout, for a rule that blocks without using CPU,
    /// and for rules that never get a thread to run on.
    static let wallClockLimitFactor: TimeInterval = 10

    /// Wall-clock limit for building the project index, or waiting for another file to build it.
    /// The index scales with the size of the project rather than the file, so this is a fixed limit
    /// rather than a multiple of the rule timeout. It only exists to fail instead of hanging.
    let projectIndexTimeLimit: TimeInterval

    private struct Start {
        var index: Int
        var uptimeNanoseconds: UInt64
        var clock: ThreadCPUClock?
        var cpuTime: TimeInterval?
        /// Time spent building the project index that has finished.
        var excludedNanoseconds: UInt64 = 0
        var excludedCPUTime: TimeInterval = 0
        /// When building the project index in progress started, if any.
        var indexing: (uptimeNanoseconds: UInt64, cpuTime: TimeInterval?)?
    }

    private let queue = DispatchQueue(label: "swiftformat.ruleprogress")
    /// Create the progress immediately before dispatching the rules, as this is when waiting starts.
    private let createdUptimeNanoseconds = DispatchTime.now().uptimeNanoseconds
    private var start: Start?

    init(projectIndexTimeLimit: TimeInterval = 300) {
        self.projectIndexTimeLimit = projectIndexTimeLimit
    }

    /// Must be called on the thread that applies the rule, immediately before applying it.
    func begin(ruleAt index: Int) {
        let clock = ThreadCPUClock.current()
        let start = Start(
            index: index,
            uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds,
            clock: clock,
            cpuTime: clock?.time()
        )
        queue.sync { self.start = start }
    }

    /// Must be called on the thread that applies the rule. Time spent building the project index is not
    /// counted against the current rule. Instead, building it is reported if it takes more than
    /// `projectIndexTimeLimit` seconds of wall-clock time.
    func setIndexing(_ isIndexing: Bool) {
        let uptimeNanoseconds = DispatchTime.now().uptimeNanoseconds
        queue.sync {
            guard var start, isIndexing != (start.indexing != nil) else {
                return
            }
            let cpuTime = start.clock?.time()
            if let indexing = start.indexing {
                start.excludedNanoseconds += uptimeNanoseconds - indexing.uptimeNanoseconds
                start.excludedCPUTime += indexing.cpuTime.flatMap { startCPUTime in cpuTime.map { $0 - startCPUTime } } ?? 0
                start.indexing = nil
            } else {
                start.indexing = (uptimeNanoseconds, cpuTime)
            }
            self.start = start
        }
    }

    /// How the rules have exceeded `timeout`, or nil if they are still within it.
    func timeout(after timeout: TimeInterval) -> Timeout? {
        let wallClockLimit = timeout * Self.wallClockLimitFactor
        guard let start = queue.sync(execute: { self.start }) else {
            return Self.seconds(since: createdUptimeNanoseconds) > wallClockLimit
                ? .notStarted(limit: wallClockLimit) : nil
        }
        if let indexing = start.indexing {
            return Self.seconds(since: indexing.uptimeNanoseconds) > projectIndexTimeLimit
                ? .projectIndex(limit: projectIndexTimeLimit) : nil
        }
        let wallTime = Self.seconds(since: start.uptimeNanoseconds + start.excludedNanoseconds)
        if wallTime > wallClockLimit {
            return .rule(index: start.index)
        }
        let cpuTime = start.cpuTime.flatMap { startCPUTime in
            start.clock?.time().map { $0 - startCPUTime - start.excludedCPUTime }
        }
        return (cpuTime ?? wallTime) > timeout ? .rule(index: start.index) : nil
    }

    private static func seconds(since uptimeNanoseconds: UInt64) -> TimeInterval {
        TimeInterval(DispatchTime.now().uptimeNanoseconds - uptimeNanoseconds) / 1_000_000_000
    }
}

/// Reads the CPU time consumed by a specific thread. The clock may be read from any thread.
private struct ThreadCPUClock {
    #if canImport(Darwin)
        private let thread: thread_act_t
    #elseif canImport(Glibc) || canImport(Musl)
        private let clockID: clockid_t
    #endif

    /// A clock for the calling thread, or nil if per-thread CPU time is unavailable on this platform.
    static func current() -> ThreadCPUClock? {
        #if canImport(Darwin)
            return ThreadCPUClock(thread: pthread_mach_thread_np(pthread_self()))
        #elseif canImport(Glibc) || canImport(Musl)
            var clockID = clockid_t()
            guard pthread_getcpuclockid(pthread_self(), &clockID) == 0 else {
                return nil
            }
            return ThreadCPUClock(clockID: clockID)
        #else
            return nil
        #endif
    }

    /// CPU time in seconds used by the thread so far, or nil if it cannot be read.
    func time() -> TimeInterval? {
        #if canImport(Darwin)
            var info = thread_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<thread_basic_info>.size / MemoryLayout<integer_t>.size)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    thread_info(thread, thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }
            let seconds = TimeInterval(info.user_time.seconds) + TimeInterval(info.system_time.seconds)
            let microseconds = TimeInterval(info.user_time.microseconds) + TimeInterval(info.system_time.microseconds)
            return result == KERN_SUCCESS ? seconds + microseconds / 1_000_000 : nil
        #elseif canImport(Glibc) || canImport(Musl)
            var time = timespec()
            guard clock_gettime(clockID, &time) == 0 else {
                return nil
            }
            return TimeInterval(time.tv_sec) + TimeInterval(time.tv_nsec) / 1_000_000_000
        #else
            return nil
        #endif
    }
}
