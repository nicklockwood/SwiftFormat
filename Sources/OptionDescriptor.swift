//
//  OptionDescriptor.swift
//  SwiftFormat
//
//  Created by Vincent Bernier on 10-02-18.
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

class OptionDescriptor {
    enum ArgumentType: EnumAssociable {
        case binary(true: String, false: String)
        case `enum`([String])
        case text
        case int
        case array
        case set
    }

    let argumentName: String // command-line argument; must not change
    fileprivate(set) var propertyName = "" // internal property; ok to change this
    let displayName: String
    private(set) var help: String
    let deprecationMessage: String?
    let toOptions: (String, inout FormatOptions) throws -> Void
    let fromOptions: (FormatOptions) -> String
    let type: ArgumentType

    var defaultArgument: String {
        fromOptions(FormatOptions.default)
    }

    func validateArgument(_ arg: String) -> Bool {
        var options = FormatOptions.default
        return (try? toOptions(arg, &options)) != nil
    }

    var isSetType: Bool {
        guard case .set = type else {
            return false
        }
        return true
    }

    /// Formatted list of valid arguments (for boolean or enum-type options)
    var argumentList: String? {
        switch type {
        case let .binary(true: trueValue, false: falseValue):
            return [trueValue, falseValue].formattedList(default: defaultArgument)
        case let .enum(values):
            return values.formattedList(default: defaultArgument)
        case .array, .set, .int, .text:
            return nil
        }
    }

    /// Designated initializer
    private init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String?,
        toOptions: @escaping (String, inout FormatOptions) throws -> Void,
        fromOptions: @escaping (FormatOptions) -> String,
        type: ArgumentType
    ) {
        assert(argumentName == argumentName.lowercased())

        self.argumentName = argumentName
        self.displayName = displayName
        self.help = help
        self.deprecationMessage = deprecationMessage
        self.toOptions = toOptions
        self.fromOptions = fromOptions
        self.type = type

        // Auto-populate help options
        if help.hasSuffix(":") {
            guard let argumentList else {
                preconditionFailure("Cannot auto-populate options for \(argumentName)")
            }
            self.help = "\(help) \(argumentList)"
        }
    }
}

extension OptionDescriptor {
    var isDeprecated: Bool {
        deprecationMessage != nil
    }

    var isRenamed: Bool {
        isDeprecated && help.hasPrefix("Renamed to")
    }

    /// Returns the new argument name for a property that has been renamed
    var newArgumentName: String? {
        isRenamed ? String(help.dropFirst("Renamed to --".count)) : nil
    }

    /// Mark an option as having been renamed
    /// Note: this only affects the documentation, and not its behavior
    func renamed(to newArgumentName: String) -> OptionDescriptor {
        .init(
            argumentName: argumentName,
            displayName: displayName,
            help: "Renamed to --\(newArgumentName)",
            deprecationMessage: "Use --\(newArgumentName) instead.",
            toOptions: toOptions,
            fromOptions: fromOptions,
            type: type
        )
    }

    /// Define a boolean option with simple true/false values
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, Bool>
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            trueValues: ["true"],
            falseValues: ["false"]
        )
    }

    /// Define a boolean option with an array of true/false values
    /// Note: only the first true/false value are included in help/docs
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, Bool>,
        trueValues: [String],
        falseValues: [String]
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            toOptions: { value, options in
                switch value.lowercased() {
                case let value where trueValues.contains(where: { value == $0.lowercased() }):
                    options[keyPath: keyPath] = true
                case let value where falseValues.contains(where: { value == $0.lowercased() }):
                    options[keyPath: keyPath] = false
                default:
                    throw FormatError.options("")
                }
            },
            fromOptions: { options in
                options[keyPath: keyPath] ? trueValues[0] : falseValues[0]
            },
            type: .binary(true: trueValues[0], false: falseValues[0])
        )
    }

    /// Define a freeform option with closures to convert to/from an argument string
    convenience init<T>(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, T>,
        type: ArgumentType,
        fromArgument: @escaping (String) throws -> T?,
        toArgument: @escaping (T) -> String
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            toOptions: { argument, options in
                guard let value = try fromArgument(argument) else {
                    throw FormatError.options("")
                }
                options[keyPath: keyPath] = value
            },
            fromOptions: { options in
                toArgument(options[keyPath: keyPath])
            },
            type: type
        )
    }

    /// Define a list-type option with automatic mapping between keys and values
    convenience init<T: Equatable>(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, T>,
        options: KeyValuePairs<String, T>
    ) {
        let map = Dictionary(uniqueKeysWithValues: options.map { ($0.lowercased(), $1) })
        let defaultValue = FormatOptions.default[keyPath: keyPath]
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            type: .enum(options.map(\.key)),
            fromArgument: { map[$0.lowercased()] },
            toArgument: { value in
                if let key = options.first(where: { $0.value == value })?.key {
                    return key
                }
                // TODO: is this fallback path needed? how would a non-existent value arise?
                return map.first(where: { $0.value == defaultValue })!.key
            }
        )
    }

    // TODO: we should add some sort of range validation to this
    /// Define an integer option
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, Int>
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            type: .int,
            fromArgument: { Int($0).map { max(0, $0) } },
            toArgument: { String($0) }
        )
    }

    /// Define a raw-representable option
    convenience init<T: RawRepresentable>(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, T>,
        type: ArgumentType,
        altOptions: [String: T] = [:]
    ) where T.RawValue == String {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            type: type,
            fromArgument: {
                T(rawValue: $0) ?? T(rawValue: $0.lowercased()) ??
                    altOptions[$0] ?? altOptions[$0.lowercased()]
            },
            toArgument: { $0.rawValue }
        )

        // Validate help
        for value in help.quotedValues {
            assert(T(rawValue: value) ?? altOptions[value] != nil, "Option \"\(value)\" doesn't exist")
        }
    }

    /// Define a plain text option
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, String>
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            type: .text,
            fromArgument: { $0 },
            toArgument: { $0 }
        )
    }

    /// Define a String-representable option
    @_disfavoredOverload
    convenience init<T: RawRepresentable>(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, T>
    ) where T.RawValue == String {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            type: .text
        )
    }

    /// Define a String-representable option with a fixed set of CaseIterable argument values
    convenience init<T: RawRepresentable & CaseIterable>(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, T>,
        altOptions: [String: T] = [:]
    ) where T.RawValue == String {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            type: .enum(T.allCases.map(\.rawValue)),
            altOptions: altOptions
        )
    }

    /// Define a StringArray-type option with a validation callback applied to the whole argument array
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, [String]>,
        validateArray: @escaping ([String]) throws -> Void = { _ in }
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            type: .array,
            fromArgument: {
                let values = parseCommaDelimitedList($0)
                try validateArray(values)
                return values
            },
            toArgument: { $0.joined(separator: ",") }
        )
    }

    /// Define a StringArray-type option with a validation callback applied individually to each argument
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage _: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, [String]>,
        validate: @escaping (String) throws -> Void = { _ in }
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            keyPath: keyPath,
            validateArray: { values in
                for (index, value) in values.enumerated() {
                    if values[0 ..< index].contains(value) {
                        throw FormatError.options("Duplicate value '\(value)'")
                    }
                    try validate(value)
                }
            }
        )
    }

    /// Define an optional StringArray-type option with a validation callback applied to the whole argument array
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, [String]?>,
        validateArray: @escaping ([String]) throws -> Void = { _ in }
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            toOptions: { value, options in
                let values = parseCommaDelimitedList(value)

                if values.isEmpty {
                    options[keyPath: keyPath] = nil
                } else {
                    try validateArray(values)
                    options[keyPath: keyPath] = values
                }
            },
            fromOptions: { options in
                options[keyPath: keyPath]?.joined(separator: ",") ?? ""
            },
            type: .array
        )
    }

    /// Define an optional StringArray-type option with a validation callback applied individually to each argument
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage _: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, [String]?>,
        validate: @escaping (String) throws -> Void = { _ in }
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            keyPath: keyPath,
            validateArray: { values in
                for (index, value) in values.enumerated() {
                    if values[0 ..< index].contains(value) {
                        throw FormatError.options("Duplicate value '\(value)'")
                    }
                    try validate(value)
                }
            }
        )
    }

    /// Define a StringSet-type option with a validation callback applied individually to each argument
    convenience init(
        argumentName: String,
        displayName: String,
        help: String,
        deprecationMessage: String? = nil,
        keyPath: WritableKeyPath<FormatOptions, Set<String>>,
        validate: @escaping (String) throws -> Void = { _ in }
    ) {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            type: .set,
            fromArgument: {
                let values = parseCommaDelimitedList($0)
                try values.forEach(validate)
                return Set(values)
            },
            toArgument: { $0.sorted().joined(separator: ",") }
        )
    }
}

private extension String {
    var quotedValues: [String] {
        let parts = components(separatedBy: "\"")
        var even = false
        return parts.compactMap {
            defer { even = !even }
            return even ? $0.components(separatedBy: "/").first : nil
        }
    }
}

let Descriptors = _Descriptors()

private var _allDescriptors: [OptionDescriptor] = {
    var descriptors = [OptionDescriptor]()
    for (label, value) in Mirror(reflecting: Descriptors).children {
        guard let name = label, var descriptor = value as? OptionDescriptor else {
            continue
        }
        if let newArgumentName = descriptor.newArgumentName {
            guard let old = descriptors.first(where: {
                $0.argumentName == newArgumentName
            }) else {
                preconditionFailure("No property matches argument name \(newArgumentName)")
            }
            descriptor.propertyName = old.propertyName
        } else {
            descriptor.propertyName = name
        }
        descriptors.append(descriptor)
    }
    return descriptors
}()

private var _descriptorsByName: [String: OptionDescriptor] = Dictionary(uniqueKeysWithValues: _allDescriptors.map { ($0.argumentName, $0) })

private let _formattingDescriptors: [OptionDescriptor] = {
    let internalDescriptors = Descriptors.internal.map(\.argumentName)
    return _allDescriptors.filter { !internalDescriptors.contains($0.argumentName) }
}()

extension _Descriptors {
    var formatting: [OptionDescriptor] {
        _formattingDescriptors
    }

    var `internal`: [OptionDescriptor] {
        [
            experimentalRules,
            fragment,
            ignoreConflictMarkers,
            swiftVersion,
            languageMode,
            markdownFiles,
        ]
    }

    /// An Array of all descriptors
    var all: [OptionDescriptor] { _allDescriptors }

    /// All deprecated descriptors
    var deprecated: [OptionDescriptor] { _allDescriptors.filter(\.isDeprecated) }

    /// All renamed descriptors
    var renamed: [OptionDescriptor] { _allDescriptors.filter(\.isRenamed) }

    /// A Dictionary of descriptors by name
    var byName: [String: OptionDescriptor] {
        _descriptorsByName
    }
}

struct _Descriptors {
    let lineAfterMarks = OptionDescriptor(
        argumentName: "line-after-marks",
        displayName: "Blank line after \"MARK\"",
        help: "Insert blank line after \"MARK:\":",
        keyPath: \.lineAfterMarks
    )
    let indent = OptionDescriptor(
        argumentName: "indent",
        displayName: "Indent",
        help: "Number of spaces to indent, or \"tab\" to use tabs",
        keyPath: \.indent,
        type: .text,
        fromArgument: { arg in
            switch arg.lowercased() {
            case "tab", "tabs", "tabbed":
                return "\t"
            default:
                return Int(arg).flatMap { $0 > 0 ? String(repeating: " ", count: $0) : nil }
            }
        },
        toArgument: { $0 == "\t" ? "tab" : String($0.count) }
    )
    let linebreak = OptionDescriptor(
        argumentName: "linebreaks",
        displayName: "Linebreak Character",
        help: "Linebreak character to use:",
        keyPath: \.linebreak,
        options: ["cr": "\r", "crlf": "\r\n", "lf": "\n"]
    )
    let semicolons = OptionDescriptor(
        argumentName: "semicolons",
        displayName: "Semicolons",
        help: "Allow semicolons:",
        keyPath: \.semicolons,
        altOptions: [
            "inline": .inlineOnly,
            "false": .never,
        ]
    )
    let spaceAroundOperatorDeclarations = OptionDescriptor(
        argumentName: "operator-func",
        displayName: "Operator Functions",
        help: "Operator function spacing:",
        keyPath: \.spaceAroundOperatorDeclarations,
        altOptions: [
            "space": .insert,
            "spaces": .insert,
            "nospace": .remove,
            "preserve": .preserve,
            "preserve-spaces": .preserve,
            "preservespaces": .preserve,
        ]
    )
    let useVoid = OptionDescriptor(
        argumentName: "void-type",
        displayName: "Void Type",
        help: "How Void types are represented:",
        keyPath: \.useVoid,
        trueValues: ["Void"],
        falseValues: ["tuple", "tuples", "()"]
    )
    let indentCase = OptionDescriptor(
        argumentName: "indent-case",
        displayName: "Indent Case",
        help: "Indent cases inside a switch statement:",
        keyPath: \.indentCase
    )
    let trailingCommas = OptionDescriptor(
        argumentName: "trailing-commas",
        displayName: "Trailing commas",
        help: "Include trailing commas:",
        keyPath: \.trailingCommas
    )
    let truncateBlankLines = OptionDescriptor(
        argumentName: "trim-whitespace",
        displayName: "Trim White Space",
        help: "Trim trailing whitespace:",
        keyPath: \.truncateBlankLines,
        trueValues: ["always"],
        falseValues: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank",
                      "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"]
    )
    let allmanBraces = OptionDescriptor(
        argumentName: "allman",
        displayName: "Allman Braces",
        help: "Use Allman indentation style:",
        keyPath: \.allmanBraces,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let fileHeader = OptionDescriptor(
        argumentName: "header",
        displayName: "Header",
        help: "Header comments: \"strip\", \"ignore\", or the text you wish use",
        keyPath: \.fileHeader
    )
    let ifdefIndent = OptionDescriptor(
        argumentName: "ifdef",
        displayName: "Ifdef Indent",
        help: "#if statement indenting:",
        keyPath: \.ifdefIndent
    )
    let wrapEnumCases = OptionDescriptor(
        argumentName: "wrap-enum-cases",
        displayName: "Wrap Enum Cases",
        help: "Enum case wrapping:",
        keyPath: \.wrapEnumCases
    )
    let wrapArguments = OptionDescriptor(
        argumentName: "wrap-arguments",
        displayName: "Wrap Arguments",
        help: "Function argument wrapping:",
        keyPath: \.wrapArguments
    )
    let wrapParameters = OptionDescriptor(
        argumentName: "wrap-parameters",
        displayName: "Wrap Parameters",
        help: "Function call parameter wrapping:",
        keyPath: \.wrapParameters
    )
    let wrapCollections = OptionDescriptor(
        argumentName: "wrap-collections",
        displayName: "Wrap Collections",
        help: "Collection literal element wrapping:",
        keyPath: \.wrapCollections
    )
    let wrapTypealiases = OptionDescriptor(
        argumentName: "wrap-type-aliases",
        displayName: "Wrap Typealiases",
        help: "Typealias wrapping:",
        keyPath: \.wrapTypealiases
    )
    let wrapReturnType = OptionDescriptor(
        argumentName: "wrap-return-type",
        displayName: "Wrap Return Type",
        help: "Function return type wrapping:",
        keyPath: \.wrapReturnType
    )
    let wrapEffects = OptionDescriptor(
        argumentName: "wrap-effects",
        displayName: "Wrap Function Effects",
        help: "Function effects (throws, async) wrapping:",
        keyPath: \.wrapEffects
    )
    let wrapConditions = OptionDescriptor(
        argumentName: "wrap-conditions",
        displayName: "Wrap Conditions",
        help: "Conditional expression wrapping:",
        keyPath: \.wrapConditions
    )
    let wrapTernaryOperators = OptionDescriptor(
        argumentName: "wrap-ternary",
        displayName: "Wrap Ternary Operators",
        help: "Ternary expression wrapping: \"default\" (wrap if needed) or \"before-operators\"",
        keyPath: \.wrapTernaryOperators
    )
    let wrapStringInterpolation = OptionDescriptor(
        argumentName: "wrap-string-interpolation",
        displayName: "Wrap String Interpolation",
        help: "String interpolation wrapping: \"default\" (wrap if needed) or \"preserve\"",
        keyPath: \.wrapStringInterpolation
    )
    let closingParenPosition = OptionDescriptor(
        argumentName: "closing-paren",
        displayName: "Closing Paren Position",
        help: "Closing paren placement:",
        keyPath: \.closingParenPosition
    )
    let callSiteClosingParenPosition = OptionDescriptor(
        argumentName: "call-site-paren",
        displayName: "Call Site Closing Paren",
        help: "Closing paren placement at function call sites:",
        keyPath: \.callSiteClosingParenPosition
    )
    let uppercaseHex = OptionDescriptor(
        argumentName: "hex-literal-case",
        displayName: "Hex Literal Case",
        help: "Case for letters in hex literals:",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    let uppercaseExponent = OptionDescriptor(
        argumentName: "exponent-case",
        displayName: "Exponent Case",
        help: "Case for 'e' in exponent literals:",
        keyPath: \.uppercaseExponent,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    let decimalGrouping = OptionDescriptor(
        argumentName: "decimal-grouping",
        displayName: "Decimal Grouping",
        help: "Decimal grouping and threshold (default: 3,6) or \"none\", \"ignore\"",
        keyPath: \.decimalGrouping
    )
    let fractionGrouping = OptionDescriptor(
        argumentName: "fraction-grouping",
        displayName: "Fraction Grouping",
        help: "Grouping of decimal digits after the '.':",
        keyPath: \.fractionGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let exponentGrouping = OptionDescriptor(
        argumentName: "exponent-grouping",
        displayName: "Exponent Grouping",
        help: "Grouping of exponent digits:",
        keyPath: \.exponentGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let binaryGrouping = OptionDescriptor(
        argumentName: "binary-grouping",
        displayName: "Binary Grouping",
        help: "Binary grouping and threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.binaryGrouping
    )
    let octalGrouping = OptionDescriptor(
        argumentName: "octal-grouping",
        displayName: "Octal Grouping",
        help: "Octal grouping and threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.octalGrouping
    )
    let hexGrouping = OptionDescriptor(
        argumentName: "hex-grouping",
        displayName: "Hex Grouping",
        help: "Hex grouping and threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.hexGrouping
    )
    let hoistPatternLet = OptionDescriptor(
        argumentName: "pattern-let",
        displayName: "Pattern Let",
        help: "Placement of let/var in patterns: \"hoist\" (default) or \"inline\"",
        keyPath: \.hoistPatternLet,
        trueValues: ["hoist"],
        falseValues: ["inline"]
    )
    let stripUnusedArguments = OptionDescriptor(
        argumentName: "strip-unused-args",
        displayName: "Strip Unused Arguments",
        help: "Strip unused arguments:",
        keyPath: \.stripUnusedArguments
    )
    let elsePosition = OptionDescriptor(
        argumentName: "else-position",
        displayName: "Else Position",
        help: "Placement of else/catch:",
        keyPath: \.elsePosition,
        altOptions: ["nextline": .nextLine, "sameline": .sameLine]
    )
    let guardElsePosition = OptionDescriptor(
        argumentName: "guard-else",
        displayName: "Guard Else Position",
        help: "Placement of else in guard statements:",
        keyPath: \.guardElsePosition
    )
    let explicitSelf = OptionDescriptor(
        argumentName: "self",
        displayName: "Self",
        help: "Explicit self:",
        keyPath: \.explicitSelf
    )
    let selfRequired = OptionDescriptor(
        argumentName: "self-required",
        displayName: "Self Required",
        help: "Comma-delimited list of functions with @autoclosure arguments",
        keyPath: \FormatOptions.selfRequired
    )
    let throwCapturing = OptionDescriptor(
        argumentName: "throw-capturing",
        displayName: "Throw Capturing",
        help: "List of functions with throwing @autoclosure arguments",
        keyPath: \FormatOptions.throwCapturing
    )
    let asyncCapturing = OptionDescriptor(
        argumentName: "async-capturing",
        displayName: "Async Capturing",
        help: "List of functions with async @autoclosure arguments",
        keyPath: \FormatOptions.asyncCapturing
    )
    let importGrouping = OptionDescriptor(
        argumentName: "import-grouping",
        displayName: "Import Grouping",
        help: "Import statement grouping:",
        keyPath: \FormatOptions.importGrouping,
        altOptions: [
            "alphabetized": .alpha,
            "alphabetical": .alpha,
            "testable-top": .testableFirst,
            "testable-bottom": .testableLast,
        ]
    )
    let trailingClosures = OptionDescriptor(
        argumentName: "trailing-closures",
        displayName: "Trailing Closure Functions",
        help: "Comma-delimited list of functions that use trailing closures",
        keyPath: \FormatOptions.trailingClosures
    )
    let neverTrailing = OptionDescriptor(
        argumentName: "never-trailing",
        displayName: "Never Trailing Functions",
        help: "List of functions that should never use trailing closures",
        keyPath: \FormatOptions.neverTrailing
    )
    let xcodeIndentation = OptionDescriptor(
        argumentName: "xcode-indentation",
        displayName: "Xcode Indentation",
        help: "Match Xcode indenting:",
        keyPath: \.xcodeIndentation,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let tabWidth = OptionDescriptor(
        argumentName: "tab-width",
        displayName: "Tab Width",
        help: "The width of a tab character. Defaults to \"unspecified\"",
        keyPath: \.tabWidth,
        type: .int,
        fromArgument: { $0.lowercased() == "unspecified" ? 0 : Int($0).map { max(0, $0) } },
        toArgument: { $0 > 0 ? String($0) : "unspecified" }
    )
    let maxWidth = OptionDescriptor(
        argumentName: "max-width",
        displayName: "Max Width",
        help: "Maximum length of a line before wrapping. Defaults to \"none\"",
        keyPath: \.maxWidth,
        type: .int,
        fromArgument: { $0.lowercased() == "none" ? 0 : Int($0).map { max(0, $0) } },
        toArgument: { $0 > 0 ? String($0) : "none" }
    )
    let smartTabs = OptionDescriptor(
        argumentName: "smart-tabs",
        displayName: "Smart Tabs",
        help: "Align code independently of tab-width:",
        keyPath: \.smartTabs,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let assetLiteralWidth = OptionDescriptor(
        argumentName: "asset-literals",
        displayName: "Asset Literals",
        help: "Formatting of color/image literals:",
        keyPath: \.assetLiteralWidth
    )
    let noSpaceOperators = OptionDescriptor(
        argumentName: "no-space-operators",
        displayName: "No-space Operators",
        help: "Comma-delimited list of operators without surrounding space",
        keyPath: \FormatOptions.noSpaceOperators,
        validate: {
            switch $0 {
            case "?":
                throw FormatError.options("Spacing around ? operator is not optional")
            case ":":
                break
            case _ where !$0.isOperator:
                throw FormatError.options("'\($0)' is not a valid infix operator")
            default:
                break
            }
        }
    )
    let typeDelimiterSpacing = OptionDescriptor(
        argumentName: "type-delimiter",
        displayName: "Type Delimiter Spacing",
        help: "Type delimiter spacing:",
        keyPath: \.typeDelimiterSpacing
    )
    let spaceAroundRangeOperators = OptionDescriptor(
        argumentName: "ranges",
        displayName: "Ranges",
        help: "Range operator spacing:",
        keyPath: \.spaceAroundRangeOperators,
        altOptions: [
            "space": .insert,
            "spaces": .insert,
            "nospace": .remove,
            "preserve": .preserve,
            "preserve-spaces": .preserve,
            "preservespaces": .preserve,
        ]
    )
    let noWrapOperators = OptionDescriptor(
        argumentName: "no-wrap-operators",
        displayName: "No-wrap Operators",
        help: "Comma-delimited list of operators that shouldn't be wrapped",
        keyPath: \FormatOptions.noWrapOperators,
        validate: {
            switch $0 {
            case ":", ";", "is", "as", "as!", "as?":
                break
            case _ where !$0.isOperator:
                throw FormatError.options("'\($0)' is not a valid infix operator")
            default:
                break
            }
        }
    )
    let modifierOrder = OptionDescriptor(
        argumentName: "modifier-order",
        displayName: "Modifier Order",
        help: "Comma-delimited list of modifiers in preferred order",
        keyPath: \FormatOptions.modifierOrder,
        validate: {
            guard _FormatRules.mapModifiers($0) != nil else {
                let names = _FormatRules.allModifiers
                    + _FormatRules.semanticModifierGroups
                let error = "'\($0)' is not a valid modifier"
                guard let match = $0.bestMatches(in: names).first else {
                    throw FormatError.options(error)
                }
                throw FormatError.options("\(error) (did you mean '\(match)'?)")
            }
        }
    )
    let shortOptionals = OptionDescriptor(
        argumentName: "short-optionals",
        displayName: "Short Optional Syntax",
        help: "Prefer ? shorthand for optionals:",
        keyPath: \.shortOptionals
    )
    let markTypes = OptionDescriptor(
        argumentName: "mark-types",
        displayName: "Mark Types",
        help: "Mark types:",
        keyPath: \.markTypes
    )
    let typeMarkComment = OptionDescriptor(
        argumentName: "type-mark",
        displayName: "Type Mark Comment",
        help: "Template for type mark comments. Defaults to \"MARK: - %t\"",
        keyPath: \.typeMarkComment
    )
    let markExtensions = OptionDescriptor(
        argumentName: "mark-extensions",
        displayName: "Mark Extensions",
        help: "Mark extensions:",
        keyPath: \.markExtensions
    )
    let extensionMarkComment = OptionDescriptor(
        argumentName: "extension-mark",
        displayName: "Extension Mark Comment",
        help: "Mark for standalone extensions. Defaults to \"MARK: - %t + %c\"",
        keyPath: \.extensionMarkComment
    )
    let groupedExtensionMarkComment = OptionDescriptor(
        argumentName: "grouped-extension",
        displayName: "Grouped Extension Mark Comment",
        help: "Mark for extension grouped with extended type. (\"MARK: %c\")",
        keyPath: \.groupedExtensionMarkComment
    )
    let markCategories = OptionDescriptor(
        argumentName: "mark-categories",
        displayName: "Mark Categories",
        help: "Insert MARK comments between categories:",
        keyPath: \.markCategories
    )
    let categoryMarkComment = OptionDescriptor(
        argumentName: "category-mark",
        displayName: "Category Mark Comment",
        help: "Template for category mark comments. Defaults to \"MARK: %c\"",
        keyPath: \.categoryMarkComment
    )
    let beforeMarks = OptionDescriptor(
        argumentName: "before-marks",
        displayName: "Before Marks",
        help: "Declarations placed before first mark (e.g. `typealias,struct`)",
        keyPath: \.beforeMarks
    )
    let lifecycleMethods = OptionDescriptor(
        argumentName: "lifecycle",
        displayName: "Lifecycle Methods",
        help: "Names of additional Lifecycle methods (e.g. `viewDidLoad`)",
        keyPath: \.lifecycleMethods
    )
    let organizeTypes = OptionDescriptor(
        argumentName: "organize-types",
        displayName: "Declaration Types to Organize",
        help: "Declarations to organize (default: `class,actor,struct,enum`)",
        keyPath: \.organizeTypes
    )
    let organizeStructThreshold = OptionDescriptor(
        argumentName: "struct-threshold",
        displayName: "Organize Struct Threshold",
        help: "Minimum line count to organize struct body. Defaults to 0",
        keyPath: \.organizeStructThreshold
    )
    let organizeClassThreshold = OptionDescriptor(
        argumentName: "class-threshold",
        displayName: "Organize Class Threshold",
        help: "Minimum line count to organize class body. Defaults to 0",
        keyPath: \.organizeClassThreshold
    )
    let organizeEnumThreshold = OptionDescriptor(
        argumentName: "enum-threshold",
        displayName: "Organize Enum Threshold",
        help: "Minimum line count to organize enum body. Defaults to 0",
        keyPath: \.organizeEnumThreshold
    )
    let organizeExtensionThreshold = OptionDescriptor(
        argumentName: "extension-threshold",
        displayName: "Organize Extension Threshold",
        help: "Minimum line count to organize extension body. Defaults to 0",
        keyPath: \.organizeExtensionThreshold
    )
    let organizationMode = OptionDescriptor(
        argumentName: "organization-mode",
        displayName: "Declaration Organization Mode",
        help: "Organize declarations by:",
        keyPath: \.organizationMode
    )
    let visibilityOrder = OptionDescriptor(
        argumentName: "visibility-order",
        displayName: "Organization Order For Visibility",
        help: "Order for visibility groups inside declaration",
        keyPath: \.visibilityOrder,
        validateArray: { order in
            let essentials = VisibilityCategory.essentialCases.map(\.rawValue)
            for type in essentials {
                guard order.contains(type) else {
                    throw FormatError.options("--visibility-order expects \(type) to be included")
                }
            }
            for type in order {
                guard let concrete = VisibilityCategory(rawValue: type) else {
                    let errorMessage = "'\(type)' is not a valid parameter for --visibility-order"
                    guard let match = type.bestMatches(in: VisibilityCategory.allCases.map(\.rawValue)).first else {
                        throw FormatError.options(errorMessage)
                    }
                    throw FormatError.options(errorMessage + ". Did you mean '\(match)?'")
                }
            }
        }
    )
    let typeOrder = OptionDescriptor(
        argumentName: "type-order",
        displayName: "Organization Order For Declaration Types",
        help: "Order for declaration type groups inside declaration",
        keyPath: \.typeOrder,
        validateArray: { order in
            for type in order {
                guard let concrete = DeclarationType(rawValue: type) else {
                    let errorMessage = "'\(type)' is not a valid parameter for --type-order"
                    guard let match = type.bestMatches(in: DeclarationType.allCases.map(\.rawValue)).first else {
                        throw FormatError.options(errorMessage)
                    }
                    throw FormatError.options(errorMessage + ". Did you mean '\(match)?'")
                }
            }
        }
    )
    let customVisibilityMarks = OptionDescriptor(
        argumentName: "visibility-marks",
        displayName: "Custom Visibility Marks",
        help: "Marks for visibility groups (public:Public Fields,..)",
        keyPath: \.customVisibilityMarks,
        validate: {
            if $0.split(separator: ":", maxSplits: 1).count != 2 {
                throw FormatError.options("--visibilitymarks expects <visibility>:<mark> argument")
            }
        }
    )
    let customTypeMarks = OptionDescriptor(
        argumentName: "type-marks",
        displayName: "Custom Type Marks",
        help: "Marks for declaration type groups (classMethod:Baaz,..)",
        keyPath: \.customTypeMarks,
        validate: {
            if $0.split(separator: ":", maxSplits: 1).count != 2 {
                throw FormatError.options("--visibilitymarks expects <visibility>:<mark> argument")
            }
        }
    )
    let blankLineAfterSubgroups = OptionDescriptor(
        argumentName: "group-blank-lines",
        displayName: "Blank Line After Subgroups",
        help: "Require a blank line after each subgroup. Default: true",
        keyPath: \.blankLineAfterSubgroups
    )
    let alphabeticallySortedDeclarationPatterns = OptionDescriptor(
        argumentName: "sorted-patterns",
        displayName: "Declaration Name Patterns To Sort Alphabetically",
        help: "List of patterns to sort alphabetically without `:sort` mark",
        keyPath: \.alphabeticallySortedDeclarationPatterns
    )
    let funcAttributes = OptionDescriptor(
        argumentName: "func-attributes",
        displayName: "Function Attributes",
        help: "Placement for function @attributes:",
        keyPath: \.funcAttributes
    )
    let typeAttributes = OptionDescriptor(
        argumentName: "type-attributes",
        displayName: "Type Attributes",
        help: "Placement for type @attributes:",
        keyPath: \.typeAttributes
    )
    let storedVarAttributes = OptionDescriptor(
        argumentName: "stored-var-attributes",
        displayName: "Stored Property Attributes",
        help: "Placement for stored var @attributes:",
        keyPath: \.storedVarAttributes
    )
    let computedVarAttributes = OptionDescriptor(
        argumentName: "computed-var-attributes",
        displayName: "Computed Property Attributes",
        help: "Placement for computed var @attributes:",
        keyPath: \.computedVarAttributes
    )
    let complexAttributes = OptionDescriptor(
        argumentName: "complex-attributes",
        displayName: "Complex Attributes",
        help: "Placement for complex @attributes:",
        keyPath: \.complexAttributes
    )
    let complexAttributesExceptions = OptionDescriptor(
        argumentName: "non-complex-attributes",
        displayName: "Complex Attribute exceptions",
        help: "List of @attributes to exclude from --complexattributes options",
        keyPath: \.complexAttributesExceptions
    )
    let yodaSwap = OptionDescriptor(
        argumentName: "yoda-swap",
        displayName: "Yoda Swap",
        help: "Swap yoda expression operands:",
        keyPath: \.yodaSwap
    )
    let extensionACLPlacement = OptionDescriptor(
        argumentName: "extension-acl",
        displayName: "Extension Access Control Level Placement",
        help: "Access control keyword placement:",
        keyPath: \.extensionACLPlacement
    )
    let propertyTypes = OptionDescriptor(
        argumentName: "property-types",
        displayName: "Property Types",
        help: "Types in property declarations:",
        keyPath: \.propertyTypes
    )
    let inferredTypesInConditionalExpressions = OptionDescriptor(
        argumentName: "inferred-types",
        displayName: "Inferred Types",
        help: "Prefer inferred types:",
        keyPath: \.inferredTypesInConditionalExpressions,
        trueValues: ["exclude-cond-exprs"],
        falseValues: ["always"]
    )
    let emptyBracesSpacing = OptionDescriptor(
        argumentName: "empty-braces",
        displayName: "Empty Braces",
        help: "Empty brace spacing:",
        keyPath: \.emptyBracesSpacing
    )
    let acronyms = OptionDescriptor(
        argumentName: "acronyms",
        displayName: "Acronyms",
        help: "Acronyms to auto-capitalize. Defaults to \"ID,URL,UUID\"",
        keyPath: \.acronyms
    )
    let preserveAcronyms = OptionDescriptor(
        argumentName: "preserve-acronyms",
        displayName: "Preserve Acronymes",
        help: "List of symbols to be ignored by the acyronyms rule",
        keyPath: \.preserveAcronyms
    )
    let indentStrings = OptionDescriptor(
        argumentName: "indent-strings",
        displayName: "Indent Strings",
        help: "Indent multiline strings:",
        keyPath: \.indentStrings,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let closureVoidReturn = OptionDescriptor(
        argumentName: "closure-void",
        displayName: "Closure Void",
        help: "Explicit Void return types in closures: \"remove\" (default) or \"preserve\"",
        keyPath: \.closureVoidReturn
    )
    let enumNamespaces = OptionDescriptor(
        argumentName: "enum-namespaces",
        displayName: "Enum Namespaces",
        help: "Change types used as namespaces to enums:",
        keyPath: \.enumNamespaces
    )
    let typeBlankLines = OptionDescriptor(
        argumentName: "type-blank-lines",
        displayName: "Type blank lines",
        help: "Blank lines in type declarations:",
        keyPath: \.typeBlankLines
    )
    let genericTypes = OptionDescriptor(
        argumentName: "generic-types",
        displayName: "Additional generic types",
        help: "Semicolon-delimited list of generic types and type parameters. For example: \"LinkedList<Element>;StateStore<State, Action>\"",
        keyPath: \.genericTypes
    )
    let useSomeAny = OptionDescriptor(
        argumentName: "some-any",
        displayName: "Use `some Any`",
        help: "Use `some Any` types:",
        keyPath: \.useSomeAny,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let preserveAnonymousForEach = OptionDescriptor(
        argumentName: "anonymous-for-each",
        displayName: "Anonymous forEach closures",
        help: "Convert anonymous forEach closures to for loops:",
        keyPath: \.preserveAnonymousForEach,
        trueValues: ["ignore", "preserve"],
        falseValues: ["convert"]
    )
    let preserveSingleLineForEach = OptionDescriptor(
        argumentName: "single-line-for-each",
        displayName: "Single-line forEach closures",
        help: "Convert single-line forEach closures to for loops:",
        keyPath: \.preserveSingleLineForEach,
        trueValues: ["ignore", "preserve"],
        falseValues: ["convert"]
    )
    let preserveDocComments = OptionDescriptor(
        argumentName: "doc-comments",
        displayName: "Doc comments",
        help: "Preserve doc comments:",
        keyPath: \.preserveDocComments,
        trueValues: ["preserve"],
        falseValues: ["before-declarations", "declarations"]
    )
    let conditionalAssignmentOnlyAfterNewProperties = OptionDescriptor(
        argumentName: "conditional-assignment",
        displayName: "Apply conditionalAssignment rule",
        help: "Use if/switch expressions for conditional assignment:",
        keyPath: \.conditionalAssignmentOnlyAfterNewProperties,
        trueValues: ["after-property"],
        falseValues: ["always"]
    )
    let initCoderNil = OptionDescriptor(
        argumentName: "init-coder-nil",
        displayName: "Return nil in init?(coder)",
        help: "Replace fatalError with nil in unavailable init?(coder:):",
        keyPath: \.initCoderNil,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let dateFormat = OptionDescriptor(
        argumentName: "date-format",
        displayName: "Date format",
        help: "File header date format: \"system\" (default), \"iso\", \"dmy\", \"mdy\" or custom",
        keyPath: \.dateFormat
    )
    let timeZone = OptionDescriptor(
        argumentName: "timezone",
        displayName: "Date format timezone",
        help: "File header date timezone: \"system\" (default) or a valid identifier/abbreviation",
        keyPath: \.timeZone
    )
    let nilInit = OptionDescriptor(
        argumentName: "nil-init",
        displayName: "Nil init type",
        help: "Explicit nil init value for Optional properties:",
        keyPath: \.nilInit
    )
    let preservedPrivateDeclarations = OptionDescriptor(
        argumentName: "preserve-decls",
        displayName: "Private Declarations to Exclude",
        help: "Comma separated list of declaration names to exclude",
        keyPath: \.preservedPrivateDeclarations
    )
    let preservedPropertyTypes = OptionDescriptor(
        argumentName: "preserved-property-types",
        displayName: "Preserved Property Types",
        help: "Comma-delimited list of symbols to be ignored and preserved as-is by the propertyTypes rule",
        keyPath: \.preservedPropertyTypes
    )
    let additionalXCTestSymbols = OptionDescriptor(
        argumentName: "xctest-symbols",
        displayName: "Additional XCTest symbols",
        help: "Comma-delimited list of symbols that depend on XCTest",
        keyPath: \.additionalXCTestSymbols
    )
    let swiftUIPropertiesSortMode = OptionDescriptor(
        argumentName: "sort-swiftui-properties",
        displayName: "Sort SwiftUI Dynamic Properties",
        help: "SwiftUI property sorting:",
        keyPath: \.swiftUIPropertiesSortMode
    )
    let equatableMacro = OptionDescriptor(
        argumentName: "equatable-macro",
        displayName: "The name and module of an Equatable conformance macro",
        help: "For example: \"@Equatable,EquatableMacroLib\"",
        keyPath: \.equatableMacro
    )
    let urlMacro = OptionDescriptor(
        argumentName: "url-macro",
        displayName: "The name and module of a URL macro",
        help: "For example: --url-macro \"#URL,URLFoundation\"",
        keyPath: \.urlMacro
    )
    let preferFileMacro = OptionDescriptor(
        argumentName: "file-macro",
        displayName: "Preferred File Macro",
        help: "File macro to prefer:",
        keyPath: \.preferFileMacro,
        trueValues: ["#file", "file"],
        falseValues: ["#fileID", "fileID"]
    )
    let lineBetweenConsecutiveGuards = OptionDescriptor(
        argumentName: "line-between-guards",
        displayName: "Blank Line Between Consecutive Guards",
        help: "Insert line between guards:",
        keyPath: \.lineBetweenConsecutiveGuards
    )
    let blankLineAfterSwitchCase = OptionDescriptor(
        argumentName: "blank-line-after-switch-case",
        displayName: "Blank Line After Switch Cases",
        help: "Insert line After switch cases:",
        keyPath: \.blankLineAfterSwitchCase
    )

    // MARK: - Internal

    let fragment = OptionDescriptor(
        argumentName: "fragment",
        displayName: "Fragment",
        help: "Input is part of a larger file:",
        keyPath: \.fragment,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let ignoreConflictMarkers = OptionDescriptor(
        argumentName: "conflict-markers",
        displayName: "Conflict Markers",
        help: "Merge-conflict markers:",
        keyPath: \.ignoreConflictMarkers,
        trueValues: ["ignore", "true", "enabled"],
        falseValues: ["reject", "false", "disabled"]
    )
    let swiftVersion = OptionDescriptor(
        argumentName: "swift-version",
        displayName: "Swift Version",
        help: "The Swift compiler version used in the files being formatted",
        keyPath: \.swiftVersion
    )
    let languageMode = OptionDescriptor(
        argumentName: "language-mode",
        displayName: "Swift Language Mode",
        help: "The Swift language mode used in the files being formatted",
        keyPath: \.languageMode
    )
    let markdownFiles = OptionDescriptor(
        argumentName: "markdown-files",
        displayName: "Markdown Files",
        help: "Swift in markdown files:",
        keyPath: \.markdownFiles
    )

    // MARK: - DEPRECATED

    let indentComments = OptionDescriptor(
        argumentName: "comments",
        displayName: "Comments",
        help: "deprecated",
        deprecationMessage: "Relative indent within multiline comments is now preserved by default.",
        keyPath: \.indentComments,
        trueValues: ["indent", "indented"],
        falseValues: ["ignore"]
    )
    let insertBlankLines = OptionDescriptor(
        argumentName: "insert-lines",
        displayName: "Insert Lines",
        help: "deprecated",
        deprecationMessage: "Use '--enable blankLinesBetweenScopes' or '--enable blankLinesAroundMark' or '--disable blankLinesBetweenScopes' or '--disable blankLinesAroundMark' instead.",
        keyPath: \.insertBlankLines,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let removeBlankLines = OptionDescriptor(
        argumentName: "remove-lines",
        displayName: "Remove Lines",
        help: "deprecated",
        deprecationMessage: "Use '--enable blankLinesAtStartOfScope' or '--enable blankLinesAtEndOfScope' or '--disable blankLinesAtStartOfScope' or '--disable blankLinesAtEndOfScope' instead.",
        keyPath: \.removeBlankLines,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let experimentalRules = OptionDescriptor(
        argumentName: "experimental",
        displayName: "Experimental Rules",
        help: "Experimental rules: \"enabled\" or \"disabled\" (default)",
        deprecationMessage: "Use --enable to opt-in to rules individually.",
        keyPath: \.experimentalRules,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let varAttributes = OptionDescriptor(
        argumentName: "var-attributes",
        displayName: "Var Attributes",
        help: "Property @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        deprecationMessage: "Use with `--storedvarattributes` or `--computedvarattributes` instead.",
        keyPath: \.varAttributes
    )
    let commas = OptionDescriptor(
        argumentName: "commas",
        displayName: "Trailing commas",
        help: "deprecated",
        deprecationMessage: "Use '--trailingcommas' instead",
        keyPath: \.trailingCommas,
        altOptions: [
            "inline": .never,
            "false": .never,
            "true": .always,
        ]
    )

    // MARK: - RENAMED

    let empty = OptionDescriptor(
        argumentName: "empty",
        displayName: "Empty",
        help: "deprecated",
        keyPath: \.useVoid,
        trueValues: ["void"],
        falseValues: ["tuple", "tuples"]
    ).renamed(to: "void-type")

    let hexLiterals = OptionDescriptor(
        argumentName: "hex-literals",
        displayName: "hex-literals",
        help: "deprecated",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    ).renamed(to: "hex-literal-case")

    let wrapElements = OptionDescriptor(
        argumentName: "wrap-elements",
        displayName: "Wrap Elements",
        help: "deprecated",
        keyPath: \.wrapCollections
    ).renamed(to: "wrap-collections")

    let specifierOrder = OptionDescriptor(
        argumentName: "specifier-order",
        displayName: "Specifier Order",
        help: "deprecated",
        keyPath: \FormatOptions.modifierOrder,
        validate: {
            guard _FormatRules.mapModifiers($0) != nil else {
                throw FormatError.options("'\($0)' is not a valid specifier")
            }
        }
    ).renamed(to: "modifier-order")

    let oneLineLineForEach = OptionDescriptor(
        argumentName: "one-line-for-each",
        displayName: "Single-line forEach closures",
        help: "deprecated",
        keyPath: \.preserveSingleLineForEach,
        trueValues: ["ignore", "preserve"],
        falseValues: ["convert"]
    ).renamed(to: "single-line-for-each")

    let redundantType = OptionDescriptor(
        argumentName: "redundant-type",
        displayName: "Redundant Type",
        help: "deprecated",
        keyPath: \.propertyTypes
    ).renamed(to: "property-types")

    let inlinedForEach = OptionDescriptor(
        argumentName: "inlined-for-each",
        displayName: "Inlined forEach closures",
        help: "deprecated",
        keyPath: \.preserveSingleLineForEach,
        trueValues: ["ignore", "preserve"],
        falseValues: ["convert"]
    ).renamed(to: "single-line-for-each")

    let condAssignment = OptionDescriptor(
        argumentName: "cond-assignment",
        displayName: "Apply conditionalAssignment rule",
        help: "deprecated",
        keyPath: \.conditionalAssignmentOnlyAfterNewProperties,
        trueValues: ["after-property"],
        falseValues: ["always"]
    ).renamed(to: "conditional-assignment")

    let storedVarAttrs = OptionDescriptor(
        argumentName: "stored-var-attrs",
        displayName: "Stored Property Attributes",
        help: "deprecated",
        keyPath: \.storedVarAttributes
    ).renamed(to: "stored-var-attributes")

    let computedVarAttrs = OptionDescriptor(
        argumentName: "computed-var-attrs",
        displayName: "Computed Property Attributes",
        help: "deprecated",
        keyPath: \.computedVarAttributes
    ).renamed(to: "computed-var-attributes")

    let complexAttrs = OptionDescriptor(
        argumentName: "complex-attrs",
        displayName: "Complex Attributes",
        help: "deprecated",
        keyPath: \.complexAttributes
    ).renamed(to: "complex-attributes")

    let complexAttrsExceptions = OptionDescriptor(
        argumentName: "non-complex-attrs",
        displayName: "Complex Attribute exceptions",
        help: "deprecated",
        keyPath: \.complexAttributesExceptions
    ).renamed(to: "non-complex-attributes")

    let preservedSymbols = OptionDescriptor(
        argumentName: "preserved-symbols",
        displayName: "Preserved Symbols",
        help: "deprecated",
        keyPath: \.preservedPropertyTypes
    ).renamed(to: "preserved-property-types")

    let swiftUIPropsSortMode = OptionDescriptor(
        argumentName: "sort-swiftui-props",
        displayName: "Sort SwiftUI Dynamic Properties",
        help: "deprecated",
        keyPath: \.swiftUIPropertiesSortMode
    ).renamed(to: "sort-swiftui-properties")

    let organizeExtensionLength = OptionDescriptor(
        argumentName: "extension-length",
        displayName: "Organize Extension Threshold",
        help: "deprecated",
        keyPath: \.organizeExtensionThreshold
    ).renamed(to: "extension-threshold")
}
