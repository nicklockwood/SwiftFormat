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
    case noIndent = "noindent"
    case outdent
}

/// Wrap mode for arguments
public enum WrapMode: String {
    case beforeFirst = "beforefirst"
    case afterFirst = "afterfirst"
    case preserve
    case disabled
}

/// Argument type for stripping
public enum ArgumentStrippingMode: String {
    case unnamedOnly = "unnamed-only"
    case closureOnly = "closure-only"
    case all = "always"
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
    public var removeSelf: Bool
    public var experimentalRules: Bool
    public var fragment: Bool
    public var commasInsteadOfAmpersands: Bool

    // Doesn't really belong here, but hard to put elsewhere
    public var ignoreConflictMarkers: Bool

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
                removeSelf: Bool = true,
                experimentalRules: Bool = false,
                fragment: Bool = false,
                ignoreConflictMarkers: Bool = false,
                commasInsteadOfAmpersands: Bool = true) {
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
        self.removeSelf = removeSelf
        self.experimentalRules = experimentalRules
        self.fragment = fragment
        self.ignoreConflictMarkers = ignoreConflictMarkers
        self.commasInsteadOfAmpersands = commasInsteadOfAmpersands
    }

    public var allOptions: [String: Any] {
        let pairs = Mirror(reflecting: self).children.map { ($0!, $1) }
        return Dictionary(pairs, uniquingKeysWith: { $1 })
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
    public var excludedURLs: [URL]

    public static let `default` = FileOptions()

    public init(followSymlinks: Bool = false,
                supportedFileExtensions: [String] = ["swift"],
                excludedURLs: [URL] = []) {
        self.followSymlinks = followSymlinks
        self.supportedFileExtensions = supportedFileExtensions
        self.excludedURLs = excludedURLs
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
