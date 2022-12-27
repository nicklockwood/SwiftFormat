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
public enum IndentMode: String, CaseIterable {
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
public enum WrapMode: String, CaseIterable {
    case beforeFirst = "before-first"
    case afterFirst = "after-first"
    case preserve
    case auto
    case always
    case disabled
    case `default`

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
        case "default":
            self = .default
        case "auto":
            self = .auto
        case "always":
            self = .always
        default:
            return nil
        }
    }
}

/// Wrap enum cases
public enum WrapEnumCases: String, CaseIterable {
    case always
    case withValues = "with-values"
}

/// Argument type for stripping
public enum ArgumentStrippingMode: String, CaseIterable {
    case unnamedOnly = "unnamed-only"
    case closureOnly = "closure-only"
    case all = "always"
}

// Wrap mode for @ attributes
public enum AttributeMode: String, CaseIterable {
    case prevLine = "prev-line"
    case sameLine = "same-line"
    case preserve
}

/// Argument type for else position
public enum ElsePosition: String, CaseIterable {
    case sameLine = "same-line"
    case nextLine = "next-line"
    case auto
}

/// Where to place the access control keyword of an extension
public enum ExtensionACLPlacement: String, CaseIterable {
    case onExtension = "on-extension"
    case onDeclarations = "on-declarations"
}

/// Wrapping behavior for the return type of a function declaration
public enum WrapReturnType: String, CaseIterable {
    case ifMultiline = "if-multiline"
    case preserve
}

/// Wrapping behavior for effects (`async`, `throws`)
public enum WrapEffects: String, CaseIterable {
    case preserve
    /// `async` and `throws` are wrapped to the line after the closing paren
    /// if the function spans multiple lines
    case ifMultiline = "if-multiline"
    /// `async` and `throws` are never wrapped, and are always included on the same line as the closing paren
    case never
}

/// Annotation which should be kept when removing a redundant type
public enum RedundantType: String, CaseIterable {
    /// Preserves the type as a part of the property definition:
    /// `let foo: Foo = Foo()` becomes `let foo: Foo = .init()`
    case explicit

    /// Uses type inference to omit the type in the property definition:
    /// `let foo: Foo = Foo()` becomes `let foo = Foo()`
    case inferred

    /// Uses `.inferred` for properties within local scopes (method bodies, etc.),
    /// but `.explicit` for globals and properties within types.
    ///  - This is because type checking for globals and type properties
    ///    using inferred types can be more expensive.
    ///    https://twitter.com/uint_min/status/1441448033988722691?s=21
    case inferLocalsOnly = "infer-locals-only"
}

/// Argument type for empty brace spacing behavior
public enum EmptyBracesSpacing: String, CaseIterable {
    case spaced
    case noSpace = "no-space"
    case linebreak
}

/// Wrapping behavior for multi-line ternary operators
public enum TernaryOperatorWrapMode: String, CaseIterable {
    /// Wraps ternary operators using the default `wrap` behavior,
    /// which performs the minimum amount of wrapping necessary.
    case `default`
    /// Wraps long / multi-line ternary operators before each of the component operators
    case beforeOperators = "before-operators"
}

/// Whether or not to remove `-> Void` from closures
public enum ClosureVoidReturn: String, CaseIterable {
    case remove
    case preserve
}

/// Version number wrapper
public struct Version: RawRepresentable, Comparable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public static let undefined = Version(rawValue: "0")!

    public init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }

    public init?(rawValue: String) {
        let rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard CharacterSet.decimalDigits.contains(rawValue.unicodeScalars.first ?? " ") else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        lhs.rawValue.compare(
            rhs.rawValue,
            options: .numeric,
            locale: Locale(identifier: "en_US")
        ) == .orderedAscending
    }

    public var description: String {
        rawValue
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
}

/// File info, used for constructing header comments
public struct FileInfo: Equatable, CustomStringConvertible {
    var filePath: String?
    var creationDate: Date?

    var fileName: String? {
        filePath.map { URL(fileURLWithPath: $0).lastPathComponent }
    }

    public init(filePath: String? = nil, creationDate: Date? = nil) {
        self.filePath = filePath
        self.creationDate = creationDate
    }

    public var description: String {
        "\(fileName ?? "");\(creationDate.map { "\($0)" } ?? "")"
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
                  let threshold = parts.last.flatMap(Int.init)
            else {
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
        rawValue
    }
}

/// Grouping for sorting imports
public enum ImportGrouping: String, CaseIterable {
    case alpha
    case length
    case testableFirst = "testable-first"
    case testableLast = "testable-last"
}

/// Self insertion mode
public enum SelfMode: String, CaseIterable {
    case insert
    case remove
    case initOnly = "init-only"
}

/// Optionals mode
public enum OptionalsMode: String, CaseIterable {
    case exceptProperties = "except-properties"
    case always
}

/// Argument type for yoda conditions
public enum YodaMode: String, CaseIterable {
    case literalsOnly = "literals-only"
    case always
}

/// Argument type for asset literals
public enum AssetLiteralWidth: String, CaseIterable {
    case actualWidth = "actual-width"
    case visualWidth = "visual-width"
}

/// Whether or not to mark types / extensions
public enum MarkMode: String, CaseIterable {
    case always
    case never
    case ifNotEmpty = "if-not-empty"
}

/// Whether to convert types to enum
public enum EnumNamespacesMode: String, CaseIterable {
    case always
    case structsOnly = "structs-only"
}

/// Whether or not to add spacing around data type delimiter
public enum SpaceAroundDelimiter: String, CaseIterable {
    case trailing
    case leadingTrailing = "leading-trailing"
}

/// Configuration options for formatting. These aren't actually used by the
/// Formatter class itself, but it makes them available to the format rules.
public struct FormatOptions: CustomStringConvertible {
    public var lineAfterMarks: Bool
    public var indent: String
    public var linebreak: String
    public var allowInlineSemicolons: Bool
    public var spaceAroundRangeOperators: Bool
    public var spaceAroundOperatorDeclarations: Bool
    public var useVoid: Bool
    public var indentCase: Bool
    public var trailingCommas: Bool
    public var truncateBlankLines: Bool
    public var insertBlankLines: Bool
    public var removeBlankLines: Bool
    public var allmanBraces: Bool
    public var fileHeader: HeaderStrippingMode
    public var ifdefIndent: IndentMode
    public var wrapArguments: WrapMode
    public var wrapParameters: WrapMode
    public var wrapCollections: WrapMode
    public var wrapTypealiases: WrapMode
    public var wrapEnumCases: WrapEnumCases
    public var closingParenOnSameLine: Bool
    public var wrapReturnType: WrapReturnType
    public var wrapConditions: WrapMode
    public var wrapTernaryOperators: TernaryOperatorWrapMode
    public var conditionsWrap: WrapMode
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
    public var guardElsePosition: ElsePosition
    public var explicitSelf: SelfMode
    public var selfRequired: Set<String>
    public var throwCapturing: Set<String>
    public var asyncCapturing: Set<String>
    public var experimentalRules: Bool
    public var importGrouping: ImportGrouping
    public var trailingClosures: Set<String>
    public var neverTrailing: Set<String>
    public var xcodeIndentation: Bool
    public var tabWidth: Int
    public var maxWidth: Int
    public var smartTabs: Bool
    public var assetLiteralWidth: AssetLiteralWidth
    public var noSpaceOperators: Set<String>
    public var noWrapOperators: Set<String>
    public var modifierOrder: [String]
    public var shortOptionals: OptionalsMode
    public var funcAttributes: AttributeMode
    public var typeAttributes: AttributeMode
    public var varAttributes: AttributeMode
    public var markTypes: MarkMode
    public var typeMarkComment: String
    public var markExtensions: MarkMode
    public var extensionMarkComment: String
    public var groupedExtensionMarkComment: String
    public var markCategories: Bool
    public var categoryMarkComment: String
    public var beforeMarks: Set<String>
    public var lifecycleMethods: Set<String>
    public var organizeTypes: Set<String>
    public var organizeClassThreshold: Int
    public var organizeStructThreshold: Int
    public var organizeEnumThreshold: Int
    public var organizeExtensionThreshold: Int
    public var yodaSwap: YodaMode
    public var extensionACLPlacement: ExtensionACLPlacement
    public var redundantType: RedundantType
    public var emptyBracesSpacing: EmptyBracesSpacing
    public var acronyms: Set<String>
    public var indentStrings: Bool
    public var closureVoidReturn: ClosureVoidReturn
    public var enumNamespaces: EnumNamespacesMode
    public var removeStartOrEndBlankLinesFromTypes: Bool
    public var genericTypes: String
    public var useSomeAny: Bool
    public var wrapEffects: WrapEffects
    public var spaceAroundDelimiter: SpaceAroundDelimiter

    // Deprecated
    public var indentComments: Bool

    // Doesn't really belong here, but hard to put elsewhere
    public var fragment: Bool
    public var ignoreConflictMarkers: Bool
    public var swiftVersion: Version
    public var fileInfo: FileInfo
    public var timeout: TimeInterval

    // Enabled rules
    var enabledRules: Set<String> = []

    public static let `default` = FormatOptions()

    public init(lineAfterMarks: Bool = true,
                indent: String = "    ",
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
                wrapParameters: WrapMode = .default,
                wrapCollections: WrapMode = .preserve,
                wrapTypealiases: WrapMode = .preserve,
                wrapEnumCases: WrapEnumCases = .always,
                closingParenOnSameLine: Bool = false,
                wrapReturnType: WrapReturnType = .preserve,
                wrapConditions: WrapMode = .preserve,
                wrapTernaryOperators: TernaryOperatorWrapMode = .default,
                conditionsWrap: WrapMode = .disabled,
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
                guardElsePosition: ElsePosition = .auto,
                explicitSelf: SelfMode = .remove,
                selfRequired: Set<String> = [],
                throwCapturing: Set<String> = [],
                asyncCapturing: Set<String> = [],
                experimentalRules: Bool = false,
                importGrouping: ImportGrouping = .alpha,
                trailingClosures: Set<String> = [],
                neverTrailing: Set<String> = [],
                xcodeIndentation: Bool = false,
                tabWidth: Int = 0,
                maxWidth: Int = 0,
                smartTabs: Bool = true,
                assetLiteralWidth: AssetLiteralWidth = .visualWidth,
                noSpaceOperators: Set<String> = [],
                noWrapOperators: Set<String> = [],
                modifierOrder: [String] = [],
                shortOptionals: OptionalsMode = .always,
                funcAttributes: AttributeMode = .preserve,
                typeAttributes: AttributeMode = .preserve,
                varAttributes: AttributeMode = .preserve,
                markTypes: MarkMode = .always,
                typeMarkComment: String = "MARK: - %t",
                markExtensions: MarkMode = .always,
                extensionMarkComment: String = "MARK: - %t + %c",
                groupedExtensionMarkComment: String = "MARK: %c",
                markCategories: Bool = true,
                categoryMarkComment: String = "MARK: %c",
                beforeMarks: Set<String> = [],
                lifecycleMethods: Set<String> = [],
                organizeTypes: Set<String> = ["class", "actor", "struct", "enum"],
                organizeClassThreshold: Int = 0,
                organizeStructThreshold: Int = 0,
                organizeEnumThreshold: Int = 0,
                organizeExtensionThreshold: Int = 0,
                yodaSwap: YodaMode = .always,
                extensionACLPlacement: ExtensionACLPlacement = .onExtension,
                redundantType: RedundantType = .inferLocalsOnly,
                emptyBracesSpacing: EmptyBracesSpacing = .noSpace,
                acronyms: Set<String> = ["ID", "URL", "UUID"],
                indentStrings: Bool = false,
                closureVoidReturn: ClosureVoidReturn = .remove,
                enumNamespaces: EnumNamespacesMode = .always,
                removeStartOrEndBlankLinesFromTypes: Bool = true,
                genericTypes: String = "",
                useSomeAny: Bool = true,
                wrapEffects: WrapEffects = .preserve,
                // Doesn't really belong here, but hard to put elsewhere
                fragment: Bool = false,
                ignoreConflictMarkers: Bool = false,
                swiftVersion: Version = .undefined,
                fileInfo: FileInfo = FileInfo(),
                timeout: TimeInterval = 1,
                spaceAroundDelimiter: SpaceAroundDelimiter = .trailing)
    {
        self.lineAfterMarks = lineAfterMarks
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
        self.wrapParameters = wrapParameters
        self.wrapCollections = wrapCollections
        self.wrapTypealiases = wrapTypealiases
        self.wrapEnumCases = wrapEnumCases
        self.closingParenOnSameLine = closingParenOnSameLine
        self.wrapReturnType = wrapReturnType
        self.wrapConditions = wrapConditions
        self.wrapTernaryOperators = wrapTernaryOperators
        self.conditionsWrap = conditionsWrap
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
        self.guardElsePosition = guardElsePosition
        self.explicitSelf = explicitSelf
        self.selfRequired = selfRequired
        self.throwCapturing = throwCapturing
        self.asyncCapturing = asyncCapturing
        self.experimentalRules = experimentalRules
        self.importGrouping = importGrouping
        self.trailingClosures = trailingClosures
        self.neverTrailing = neverTrailing
        self.xcodeIndentation = xcodeIndentation
        self.tabWidth = tabWidth
        self.maxWidth = maxWidth
        self.smartTabs = smartTabs
        self.assetLiteralWidth = assetLiteralWidth
        self.noSpaceOperators = noSpaceOperators
        self.noWrapOperators = noWrapOperators
        self.modifierOrder = modifierOrder
        self.shortOptionals = shortOptionals
        self.funcAttributes = funcAttributes
        self.typeAttributes = typeAttributes
        self.varAttributes = varAttributes
        self.markTypes = markTypes
        self.typeMarkComment = typeMarkComment
        self.markExtensions = markExtensions
        self.extensionMarkComment = extensionMarkComment
        self.groupedExtensionMarkComment = groupedExtensionMarkComment
        self.markCategories = markCategories
        self.categoryMarkComment = categoryMarkComment
        self.beforeMarks = beforeMarks
        self.lifecycleMethods = lifecycleMethods
        self.organizeTypes = organizeTypes
        self.organizeClassThreshold = organizeClassThreshold
        self.organizeStructThreshold = organizeStructThreshold
        self.organizeEnumThreshold = organizeEnumThreshold
        self.organizeExtensionThreshold = organizeExtensionThreshold
        self.yodaSwap = yodaSwap
        self.extensionACLPlacement = extensionACLPlacement
        self.redundantType = redundantType
        self.emptyBracesSpacing = emptyBracesSpacing
        self.acronyms = acronyms
        self.indentStrings = indentStrings
        self.closureVoidReturn = closureVoidReturn
        self.enumNamespaces = enumNamespaces
        self.removeStartOrEndBlankLinesFromTypes = removeStartOrEndBlankLinesFromTypes
        self.genericTypes = genericTypes
        self.useSomeAny = useSomeAny
        self.wrapEffects = wrapEffects
        self.spaceAroundDelimiter = spaceAroundDelimiter
        // Doesn't really belong here, but hard to put elsewhere
        self.fragment = fragment
        self.ignoreConflictMarkers = ignoreConflictMarkers
        self.swiftVersion = swiftVersion
        self.fileInfo = fileInfo
        self.timeout = timeout
    }

    public var useTabs: Bool {
        indent.first == "\t"
    }

    public var requiresFileInfo: Bool {
        let string = fileHeader.rawValue
        return string.contains("{created") || string.contains("{file")
    }

    public var allOptions: [String: Any] {
        let pairs = Mirror(reflecting: self).children.map { ($0!, $1) }
        var options = Dictionary(pairs, uniquingKeysWith: { $1 })
        for key in ["fileInfo", "enabledRules", "timeout"] { // Special cases
            options[key] = nil
        }
        return options
    }

    public var description: String {
        let allowedCharacters = CharacterSet.newlines.inverted
        return Mirror(reflecting: self).children.compactMap { child in
            let value = (child.value as? Set<AnyHashable>).map { $0.sorted as Any } ?? child.value
            return "\(value);".addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        }.joined()
    }
}

/// File enumeration options
public struct FileOptions {
    public var followSymlinks: Bool
    public var supportedFileExtensions: [String]
    public var excludedGlobs: [Glob]
    public var unexcludedGlobs: [Glob]
    public var minVersion: Version

    public static let `default` = FileOptions()

    public init(followSymlinks: Bool = false,
                supportedFileExtensions: [String] = ["swift"],
                excludedGlobs: [Glob] = [],
                unexcludedGlobs: [Glob] = [],
                minVersion: Version = .undefined)
    {
        self.followSymlinks = followSymlinks
        self.supportedFileExtensions = supportedFileExtensions
        self.excludedGlobs = excludedGlobs
        self.unexcludedGlobs = unexcludedGlobs
        self.minVersion = minVersion
    }

    public func shouldSkipFile(_ inputURL: URL) -> Bool {
        let parts = inputURL.standardizedFileURL.path.components(separatedBy: "/")
        var path: String!
        var shouldSkip = false
        for part in parts {
            path = path.map { "\($0)/\(part)" } ?? part
            if !shouldSkip, excludedGlobs.contains(where: { $0.matches(path) }) {
                shouldSkip = true
            }
            if shouldSkip, unexcludedGlobs.contains(where: { $0.matches(path) }) {
                shouldSkip = false
            }
        }
        return shouldSkip
    }
}

/// All options
public struct Options {
    public var fileOptions: FileOptions?
    public var formatOptions: FormatOptions?
    public var rules: Set<String>?
    public var configURL: URL?
    public var lint: Bool

    public static let `default` = Options(
        fileOptions: .default,
        formatOptions: .default,
        rules: Set(FormatRules.byName.keys).subtracting(FormatRules.disabledByDefault),
        configURL: nil,
        lint: false
    )

    public init(fileOptions: FileOptions? = nil,
                formatOptions: FormatOptions? = nil,
                rules: Set<String>? = nil,
                configURL: URL? = nil,
                lint: Bool = false)
    {
        self.fileOptions = fileOptions
        self.formatOptions = formatOptions
        self.rules = rules
        self.configURL = configURL
        self.lint = lint
    }

    public func shouldSkipFile(_ inputURL: URL) -> Bool {
        fileOptions?.shouldSkipFile(inputURL) ?? false
    }
}
