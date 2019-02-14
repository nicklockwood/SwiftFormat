//
//  Options.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 21/10/2016.
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

/// The indenting mode to use for #if/#endif statements
public enum IndentMode: String {
    case indent
    case noIndent = "no-indent"
    case outdent

    public init?(rawValue: String) {
        switch rawValue {
        case "indent":
            self = .indent
        case "no-indent", "noindent":
            self = .noIndent
        case "outdent":
            self = .outdent
        default:
            return nil
        }
    }
}

/// Wrap mode for arguments
public enum WrapMode: String {
    case beforeFirst = "before-first"
    case afterFirst = "after-first"
    case preserve
    case disabled

    public init?(rawValue: String) {
        switch rawValue {
        case "before-first", "beforefirst":
            self = .beforeFirst
        case "after-first", "afterfirst":
            self = .afterFirst
        case "preserve":
            self = .preserve
        case "disabled":
            self = .disabled
        default:
            return nil
        }
    }
}

/// Argument type for stripping
public enum ArgumentStrippingMode: String {
    case unnamedOnly = "unnamed-only"
    case closureOnly = "closure-only"
    case all = "always"
}

/// Version number wrapper
public struct Version: RawRepresentable, Comparable, ExpressibleByStringLiteral {
    public let rawValue: String

    public static let undefined = Version(rawValue: "0")!

    public init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }

    public init?(rawValue: String) {
        let rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawValue.components(separatedBy: ".").contains(where: { Double($0) == nil }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func == (lhs: Version, rhs: Version) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        return lhs.rawValue.compare(
            rhs.rawValue,
            options: .numeric,
            locale: Locale(identifier: "en_US")
        ) == .orderedAscending
    }
}

/// Argument type for stripping
public enum HeaderStrippingMode: Equatable, RawRepresentable, ExpressibleByStringLiteral {
    case ignore
    case replace(String)

    public init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }

    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "ignore", "keep", "preserve":
            self = .ignore
        case "strip", "":
            self = .replace("")
        default:
            // Normalize the header
            let header = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let isMultiline = header.hasPrefix("/*")
            var lines = header.components(separatedBy: "\\n")
            lines = lines.map {
                var line = $0
                if !isMultiline, !line.hasPrefix("//") {
                    line = "//\(line.isEmpty ? "" : " ")\(line)"
                }
                return line
            }
            while lines.last?.isEmpty == true {
                lines.removeLast()
            }
            self = .replace(lines.joined(separator: "\n"))
        }
    }

    public var rawValue: String {
        switch self {
        case .ignore:
            return "ignore"
        case let .replace(string):
            return string.isEmpty ? "strip" : string.replacingOccurrences(of: "\n", with: "\\n")
        }
    }

    public static func == (lhs: HeaderStrippingMode, rhs: HeaderStrippingMode) -> Bool {
        switch (lhs, rhs) {
        case (.ignore, .ignore):
            return true
        case let (.replace(lhs), .replace(rhs)):
            return lhs == rhs
        case (.ignore, _),
             (.replace, _):
            return false
        }
    }
}

/// File info, used for constructing header comments
public struct FileInfo {
    var fileName: String?
    var creationDate: Date?

    public init(fileName: String? = nil, creationDate: Date? = nil) {
        self.fileName = fileName
        self.creationDate = creationDate
    }
}

/// Grouping for numeric literals
public enum Grouping: Equatable, RawRepresentable, CustomStringConvertible {
    case ignore
    case none
    case group(Int, Int)

    public init?(rawValue: String) {
        switch rawValue {
        case "ignore":
            self = .ignore
        case "none":
            self = .none
        default:
            let parts = rawValue.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard (1 ... 2).contains(parts.count),
                let group = parts.first.flatMap(Int.init),
                let threshold = parts.last.flatMap(Int.init) else {
                return nil
            }
            self = (group == 0) ? .none : .group(group, threshold)
        }
    }

    public var rawValue: String {
        switch self {
        case .ignore:
            return "ignore"
        case .none:
            return "none"
        case let .group(group, threshold):
            return "\(group),\(threshold)"
        }
    }

    public var description: String {
        return rawValue
    }

    public static func == (lhs: Grouping, rhs: Grouping) -> Bool {
        switch (lhs, rhs) {
        case (.ignore, .ignore),
             (.none, .none):
            return true
        case let (.group(a, b), .group(c, d)):
            return a == c && b == d
        case (.ignore, _),
             (.none, _),
             (.group, _):
            return false
        }
    }
}

/// Grouping for sorting imports
public enum ImportGrouping: String {
    case alphabetized
    case testableTop = "testable-top"
    case testableBottom = "testable-bottom"
}

/// Self insertion mode
public enum SelfMode: String {
    case insert
    case remove
    case initOnly = "init-only"
}

/// Configuration options for formatting. These aren't actually used by the
/// Formatter class itself, but it makes them available to the format rules.
public struct FormatOptions: CustomStringConvertible {
    public var indent: String
    public var linebreak: String
    public var allowInlineSemicolons: Bool
    public var spaceAroundRangeOperators: Bool
    public var spaceAroundOperatorDeclarations: Bool
    public var useVoid: Bool
    public var indentCase: Bool
    public var trailingCommas: Bool
    public var indentComments: Bool
    public var truncateBlankLines: Bool
    public var insertBlankLines: Bool
    public var removeBlankLines: Bool
    public var allmanBraces: Bool
    public var fileHeader: HeaderStrippingMode
    public var ifdefIndent: IndentMode
    public var wrapArguments: WrapMode
    public var wrapCollections: WrapMode
    public var closingParenOnSameLine: Bool
    public var uppercaseHex: Bool
    public var uppercaseExponent: Bool
    public var decimalGrouping: Grouping
    public var binaryGrouping: Grouping
    public var octalGrouping: Grouping
    public var hexGrouping: Grouping
    public var fractionGrouping: Bool
    public var exponentGrouping: Bool
    public var hoistPatternLet: Bool
    public var stripUnusedArguments: ArgumentStrippingMode
    public var elseOnNextLine: Bool
    public var explicitSelf: SelfMode
    public var selfRequired: [String]
    public var experimentalRules: Bool
    public var importGrouping: ImportGrouping
    public var trailingClosures: [String]

    // Doesn't really belong here, but hard to put elsewhere
    public var fragment: Bool
    public var ignoreConflictMarkers: Bool
    public var swiftVersion: Version
    public var fileInfo: FileInfo

    public static let `default` = FormatOptions()

    public init(indent: String = "    ",
                linebreak: String = "\n",
                allowInlineSemicolons: Bool = true,
                spaceAroundRangeOperators: Bool = true,
                spaceAroundOperatorDeclarations: Bool = true,
                useVoid: Bool = true,
                indentCase: Bool = false,
                trailingCommas: Bool = true,
                indentComments: Bool = true,
                truncateBlankLines: Bool = true,
                insertBlankLines: Bool = true,
                removeBlankLines: Bool = true,
                allmanBraces: Bool = false,
                fileHeader: HeaderStrippingMode = .ignore,
                ifdefIndent: IndentMode = .indent,
                wrapArguments: WrapMode = .preserve,
                wrapCollections: WrapMode = .preserve,
                closingParenOnSameLine: Bool = false,
                uppercaseHex: Bool = true,
                uppercaseExponent: Bool = false,
                decimalGrouping: Grouping = .group(3, 6),
                binaryGrouping: Grouping = .group(4, 8),
                octalGrouping: Grouping = .group(4, 8),
                hexGrouping: Grouping = .group(4, 8),
                fractionGrouping: Bool = false,
                exponentGrouping: Bool = false,
                hoistPatternLet: Bool = true,
                stripUnusedArguments: ArgumentStrippingMode = .all,
                elseOnNextLine: Bool = false,
                explicitSelf: SelfMode = .remove,
                selfRequired: [String] = [],
                experimentalRules: Bool = false,
                importGrouping: ImportGrouping = .alphabetized,
                trailingClosures: [String] = [],
                // Doesn't really belong here, but hard to put elsewhere
                fragment: Bool = false,
                ignoreConflictMarkers: Bool = false,
                swiftVersion: Version = .undefined,
                fileInfo: FileInfo = FileInfo()) {
        self.indent = indent
        self.linebreak = linebreak
        self.allowInlineSemicolons = allowInlineSemicolons
        self.spaceAroundRangeOperators = spaceAroundRangeOperators
        self.spaceAroundOperatorDeclarations = spaceAroundOperatorDeclarations
        self.useVoid = useVoid
        self.indentCase = indentCase
        self.trailingCommas = trailingCommas
        self.indentComments = indentComments
        self.truncateBlankLines = truncateBlankLines
        self.insertBlankLines = insertBlankLines
        self.removeBlankLines = removeBlankLines
        self.allmanBraces = allmanBraces
        self.fileHeader = fileHeader
        self.ifdefIndent = ifdefIndent
        self.wrapArguments = wrapArguments
        self.wrapCollections = wrapCollections
        self.closingParenOnSameLine = closingParenOnSameLine
        self.uppercaseHex = uppercaseHex
        self.uppercaseExponent = uppercaseExponent
        self.decimalGrouping = decimalGrouping
        self.fractionGrouping = fractionGrouping
        self.exponentGrouping = exponentGrouping
        self.binaryGrouping = binaryGrouping
        self.octalGrouping = octalGrouping
        self.hexGrouping = hexGrouping
        self.hoistPatternLet = hoistPatternLet
        self.stripUnusedArguments = stripUnusedArguments
        self.elseOnNextLine = elseOnNextLine
        self.explicitSelf = explicitSelf
        self.selfRequired = selfRequired
        self.experimentalRules = experimentalRules
        self.importGrouping = importGrouping
        self.trailingClosures = trailingClosures
        // Doesn't really belong here, but hard to put elsewhere
        self.fragment = fragment
        self.ignoreConflictMarkers = ignoreConflictMarkers
        self.swiftVersion = swiftVersion
        self.fileInfo = fileInfo
    }

    public var allOptions: [String: Any] {
        let pairs = Mirror(reflecting: self).children.map { ($0!, $1) }
        var options = Dictionary(pairs, uniquingKeysWith: { $1 })
        options["fileInfo"] = nil // Special case
        return options
    }

    public var description: String {
        let allowedCharacters = CharacterSet.newlines.inverted
        return Mirror(reflecting: self).children.map({
            "\($0.value);".addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
        }).joined()
    }
}

/// File enumeration options
public struct FileOptions {
    public var followSymlinks: Bool
    public var supportedFileExtensions: [String]
    public var excludedGlobs: [Glob]

    @available(*, deprecated, message: "Use excludedGlobs property instead")
    public var excludedURLs: [URL] {
        return excludedGlobs.compactMap {
            switch $0 {
            case let .path(path): return URL(fileURLWithPath: path)
            case .regex: return nil
            }
        }
    }

    public static let `default` = FileOptions()

    @available(*, deprecated, message: "Use other init() method instead")
    public init(followSymlinks: Bool = false,
                supportedFileExtensions: [String] = ["swift"],
                excludedURLs: [URL]) {
        self.init(followSymlinks: followSymlinks,
                  supportedFileExtensions: supportedFileExtensions,
                  excludedGlobs: excludedURLs.map { Glob.path($0.path) })
    }

    public init(followSymlinks: Bool = false,
                supportedFileExtensions: [String] = ["swift"],
                excludedGlobs: [Glob] = []) {
        self.followSymlinks = followSymlinks
        self.supportedFileExtensions = supportedFileExtensions
        self.excludedGlobs = excludedGlobs
    }
}

/// All options
public struct Options {
    public var fileOptions: FileOptions?
    public var formatOptions: FormatOptions?
    public var rules: Set<String>?

    public static let `default` = Options(
        fileOptions: .default,
        formatOptions: .default,
        rules: Set(FormatRules.byName.keys).subtracting(FormatRules.disabledByDefault)
    )

    public init(fileOptions: FileOptions? = nil,
                formatOptions: FormatOptions? = nil,
                rules: Set<String>? = nil) {
        self.fileOptions = fileOptions
        self.formatOptions = formatOptions
        self.rules = rules
    }
}
