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
        /// index 0 is official value, others are acceptable
        case binary(true: [String], false: [String])
        case `enum`([String])
        case text
        case int
        case array
        case set
    }

    let argumentName: String // command-line argument; must not change
    fileprivate(set) var propertyName = "" // internal property; ok to change this
    let displayName: String
    fileprivate(set) var help: String
    fileprivate(set) var deprecationMessage: String?
    let toOptions: (String, inout FormatOptions) throws -> Void
    let fromOptions: (FormatOptions) -> String
    private(set) var type: ArgumentType

    var isDeprecated: Bool {
        deprecationMessage != nil
    }

    var isRenamed: Bool {
        isDeprecated && help.hasPrefix("Renamed to")
    }

    fileprivate var newArgumentName: String? {
        isRenamed ? String(help.dropFirst("Renamed to --".count)) : nil
    }

    fileprivate func renamed(to newArgumentName: String) -> OptionDescriptor {
        deprecationMessage = "Use --\(newArgumentName) instead."
        help = "Renamed to --\(newArgumentName)"
        return self
    }

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

    init(argumentName: String,
         displayName: String,
         help: String,
         deprecationMessage: String? = nil,
         keyPath: WritableKeyPath<FormatOptions, Bool>,
         trueValues: [String],
         falseValues: [String])
    {
        assert(argumentName == argumentName.lowercased())
        self.argumentName = argumentName
        self.displayName = displayName
        self.help = help
        self.deprecationMessage = deprecationMessage
        type = .binary(true: trueValues, false: falseValues)
        toOptions = { value, options in
            switch value.lowercased() {
            case let value where trueValues.contains(value):
                options[keyPath: keyPath] = true
            case let value where falseValues.contains(value):
                options[keyPath: keyPath] = false
            default:
                throw FormatError.options("")
            }
        }
        fromOptions = { options in
            options[keyPath: keyPath] ? trueValues[0] : falseValues[0]
        }
    }

    init<T>(argumentName: String,
            displayName: String,
            help: String,
            deprecationMessage: String? = nil,
            keyPath: WritableKeyPath<FormatOptions, T>,
            fromArgument: @escaping (String) -> T?,
            toArgument: @escaping (T) -> String)
    {
        self.argumentName = argumentName
        self.displayName = displayName
        self.help = help
        self.deprecationMessage = deprecationMessage
        type = .text
        toOptions = { key, options in
            guard let value = fromArgument(key) else {
                throw FormatError.options("")
            }
            options[keyPath: keyPath] = value
        }
        fromOptions = { options in
            toArgument(options[keyPath: keyPath])
        }
    }

    convenience init(argumentName: String,
                     displayName: String,
                     help: String,
                     deprecationMessage: String? = nil,
                     keyPath: WritableKeyPath<FormatOptions, String>,
                     options: KeyValuePairs<String, String>)
    {
        let map: [String: String] = Dictionary(options.map { ($0, $1) }, uniquingKeysWith: { $1 })
        let keys = Array(map.keys).sorted()
        self.init(argumentName: argumentName,
                  displayName: displayName,
                  help: help,
                  deprecationMessage: deprecationMessage,
                  keyPath: keyPath,
                  fromArgument: { map[$0.lowercased()] },
                  toArgument: { value in
                      if let key = map.first(where: { $0.value == value })?.key {
                          return key
                      }
                      let fallback = FormatOptions.default[keyPath: keyPath]
                      if let key = map.first(where: { $0.value == fallback })?.key {
                          return key
                      }
                      return keys[0]
                  })
        type = .enum(keys)
    }

    convenience init(argumentName: String,
                     displayName: String,
                     help: String,
                     deprecationMessage: String? = nil,
                     keyPath: WritableKeyPath<FormatOptions, Int>)
    {
        self.init(
            argumentName: argumentName,
            displayName: displayName,
            help: help,
            deprecationMessage: deprecationMessage,
            keyPath: keyPath,
            fromArgument: { Int($0).map { max(0, $0) } },
            toArgument: { String($0) }
        )
        type = .int
    }

    init<T: RawRepresentable>(argumentName: String,
                              displayName: String,
                              help: String,
                              deprecationMessage: String? = nil,
                              keyPath: WritableKeyPath<FormatOptions, T>,
                              type: ArgumentType,
                              altOptions: [String: T] = [:]) where T.RawValue == String
    {
        self.argumentName = argumentName
        self.displayName = displayName
        self.help = help
        for option in help.quotedValues {
            assert(T(rawValue: option) ?? altOptions[option] != nil, "Option \(option) doesn't exist")
        }
        self.deprecationMessage = deprecationMessage
        self.type = type
        toOptions = { rawValue, options in
            guard let value = T(rawValue: rawValue) ?? T(rawValue: rawValue.lowercased()) ??
                altOptions[rawValue] ?? altOptions[rawValue.lowercased()]
            else {
                throw FormatError.options("")
            }
            options[keyPath: keyPath] = value
        }
        fromOptions = { options in
            options[keyPath: keyPath].rawValue
        }
    }

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

    init(argumentName: String,
         displayName: String,
         help: String,
         deprecationMessage: String? = nil,
         keyPath: WritableKeyPath<FormatOptions, [String]>,
         validateArray: @escaping ([String]) throws -> Void = { _ in })
    {
        self.argumentName = argumentName
        self.displayName = displayName
        self.help = help
        self.deprecationMessage = deprecationMessage
        type = .array
        toOptions = { value, options in
            let values = parseCommaDelimitedList(value)
            try validateArray(values)
            options[keyPath: keyPath] = values
        }
        fromOptions = { options in
            options[keyPath: keyPath].joined(separator: ",")
        }
    }

    convenience init(argumentName: String,
                     displayName: String,
                     help: String,
                     deprecationMessage _: String? = nil,
                     keyPath: WritableKeyPath<FormatOptions, [String]>,
                     validate: @escaping (String) throws -> Void = { _ in })
    {
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

    init(argumentName: String,
         displayName: String,
         help: String,
         deprecationMessage: String? = nil,
         keyPath: WritableKeyPath<FormatOptions, [String]?>,
         validateArray: @escaping ([String]) throws -> Void = { _ in })
    {
        self.argumentName = argumentName
        self.displayName = displayName
        self.help = help
        self.deprecationMessage = deprecationMessage
        type = .array
        toOptions = { value, options in
            let values = parseCommaDelimitedList(value)

            if values.isEmpty {
                options[keyPath: keyPath] = nil
            } else {
                try validateArray(values)
                options[keyPath: keyPath] = values
            }
        }
        fromOptions = { options in
            options[keyPath: keyPath]?.joined(separator: ",") ?? ""
        }
    }

    convenience init(argumentName: String,
                     displayName: String,
                     help: String,
                     deprecationMessage _: String? = nil,
                     keyPath: WritableKeyPath<FormatOptions, [String]?>,
                     validate: @escaping (String) throws -> Void = { _ in })
    {
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

    init(argumentName: String,
         displayName: String,
         help: String,
         deprecationMessage: String? = nil,
         keyPath: WritableKeyPath<FormatOptions, Set<String>>,
         validate: @escaping (String) throws -> Void = { _ in })
    {
        self.argumentName = argumentName
        self.displayName = displayName
        self.help = help
        self.deprecationMessage = deprecationMessage
        type = .set
        toOptions = { value, options in
            let values = parseCommaDelimitedList(value)
            try values.forEach(validate)
            options[keyPath: keyPath] = Set(values)
        }
        fromOptions = { options in
            options[keyPath: keyPath].sorted().joined(separator: ",")
        }
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
        help: "Insert blank line after \"MARK:\": \"true\" (default) or \"false\"",
        keyPath: \.lineAfterMarks,
        trueValues: ["true"],
        falseValues: ["false"]
    )
    let indent = OptionDescriptor(
        argumentName: "indent",
        displayName: "Indent",
        help: "Number of spaces to indent, or \"tab\" to use tabs",
        keyPath: \.indent,
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
        help: "Linebreak character to use: \"cr\", \"crlf\" or \"lf\" (default)",
        keyPath: \.linebreak,
        options: ["cr": "\r", "lf": "\n", "crlf": "\r\n"]
    )
    let allowInlineSemicolons = OptionDescriptor(
        argumentName: "semicolons",
        displayName: "Semicolons",
        help: "Allow semicolons: \"never\" or \"inline\" (default)",
        keyPath: \.allowInlineSemicolons,
        trueValues: ["inline"],
        falseValues: ["never", "false"]
    )
    let spaceAroundOperatorDeclarations = OptionDescriptor(
        argumentName: "operator-func",
        displayName: "Operator Functions",
        help: "Operator funcs: \"spaced\" (default), \"no-space\", or \"preserve\"",
        keyPath: \.spaceAroundOperatorDeclarations,
        fromArgument: { argument in
            switch argument {
            case "spaced", "space", "spaces":
                return .insert
            case "no-space", "nospace":
                return .remove
            case "preserve", "preserve-spaces", "preservespaces":
                return .preserve
            default:
                return nil
            }
        },
        toArgument: { value in
            value.rawValue
        }
    )
    let useVoid = OptionDescriptor(
        argumentName: "void-type",
        displayName: "Void Type",
        help: "How void types are represented: \"void\" (default) or \"tuple\"",
        keyPath: \.useVoid,
        trueValues: ["void"],
        falseValues: ["tuple", "tuples", "()"]
    )
    let indentCase = OptionDescriptor(
        argumentName: "indent-case",
        displayName: "Indent Case",
        help: "Indent cases inside a switch: \"true\" or \"false\" (default)",
        keyPath: \.indentCase,
        trueValues: ["true"],
        falseValues: ["false"]
    )
    let trailingCommas = OptionDescriptor(
        argumentName: "trailing-commas",
        displayName: "Trailing commas",
        help: "Trailing commas: \"always\" (default), \"never\", or \"collections-only\"",
        keyPath: \.trailingCommas
    )
    let truncateBlankLines = OptionDescriptor(
        argumentName: "trim-whitespace",
        displayName: "Trim White Space",
        help: "Trim trailing space: \"always\" (default) or \"nonblank-lines\"",
        keyPath: \.truncateBlankLines,
        trueValues: ["always"],
        falseValues: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank",
                      "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"]
    )
    let allmanBraces = OptionDescriptor(
        argumentName: "allman",
        displayName: "Allman Braces",
        help: "Use allman indentation style: \"true\" or \"false\" (default)",
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
        help: "#if indenting: \"indent\" (default), \"no-indent\" or \"outdent\"",
        keyPath: \.ifdefIndent
    )
    let wrapArguments = OptionDescriptor(
        argumentName: "wrap-arguments",
        displayName: "Wrap Arguments",
        help: "Wrap all arguments: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapArguments
    )
    let wrapEnumCases = OptionDescriptor(
        argumentName: "wrap-enum-cases",
        displayName: "Wrap Enum Cases",
        help: "Wrap enum cases: \"always\" (default) or \"with-values\"",
        keyPath: \.wrapEnumCases
    )
    let wrapParameters = OptionDescriptor(
        argumentName: "wrap-parameters",
        displayName: "Wrap Parameters",
        help: "Wrap func params: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapParameters
    )
    let wrapCollections = OptionDescriptor(
        argumentName: "wrap-collections",
        displayName: "Wrap Collections",
        help: "Wrap array/dict: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapCollections
    )
    let wrapTypealiases = OptionDescriptor(
        argumentName: "wrap-type-aliases",
        displayName: "Wrap Typealiases",
        help: "Wrap typealiases: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapTypealiases
    )
    let wrapReturnType = OptionDescriptor(
        argumentName: "wrap-return-type",
        displayName: "Wrap Return Type",
        help: "Wrap return type: \"if-multiline\", \"preserve\", \"never\"",
        keyPath: \.wrapReturnType
    )
    let wrapEffects = OptionDescriptor(
        argumentName: "wrap-effects",
        displayName: "Wrap Function Effects (throws, async)",
        help: "Wrap effects: \"if-multiline\", \"never\", \"preserve\"",
        keyPath: \.wrapEffects
    )
    let wrapConditions = OptionDescriptor(
        argumentName: "wrap-conditions",
        displayName: "Wrap Conditions",
        help: "Wrap conditions: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapConditions
    )
    let wrapTernaryOperators = OptionDescriptor(
        argumentName: "wrap-ternary",
        displayName: "Wrap Ternary Operators",
        help: "Wrap ternary operators: \"default\" (wrap if needed), \"before-operators\"",
        keyPath: \.wrapTernaryOperators
    )
    let wrapStringInterpolation = OptionDescriptor(
        argumentName: "wrap-string-interpolation",
        displayName: "Wrap String Interpolation",
        help: "Wrap string interpolation: \"default\" (wrap if needed), \"preserve\"",
        keyPath: \.wrapStringInterpolation
    )
    let closingParenPosition = OptionDescriptor(
        argumentName: "closing-paren",
        displayName: "Closing Paren Position",
        help: "Closing paren position: \"balanced\" (default) or \"same-line\"",
        keyPath: \.closingParenPosition
    )
    let callSiteClosingParenPosition = OptionDescriptor(
        argumentName: "call-site-paren",
        displayName: "Call Site Closing Paren",
        help: "Closing paren at call sites: \"balanced\" or \"same-line\"",
        keyPath: \.callSiteClosingParenPosition
    )
    let uppercaseHex = OptionDescriptor(
        argumentName: "hex-literal-case",
        displayName: "Hex Literal Case",
        help: "Casing for hex literals: \"uppercase\" (default) or \"lowercase\"",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    let uppercaseExponent = OptionDescriptor(
        argumentName: "exponent-case",
        displayName: "Exponent Case",
        help: "Case of 'e' in numbers: \"lowercase\" or \"uppercase\" (default)",
        keyPath: \.uppercaseExponent,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    let decimalGrouping = OptionDescriptor(
        argumentName: "decimal-grouping",
        displayName: "Decimal Grouping",
        help: "Decimal grouping,threshold (default: 3,6) or \"none\", \"ignore\"",
        keyPath: \.decimalGrouping
    )
    let fractionGrouping = OptionDescriptor(
        argumentName: "fraction-grouping",
        displayName: "Fraction Grouping",
        help: "Group digits after '.': \"enabled\" or \"disabled\" (default)",
        keyPath: \.fractionGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let exponentGrouping = OptionDescriptor(
        argumentName: "exponent-grouping",
        displayName: "Exponent Grouping",
        help: "Group exponent digits: \"enabled\" or \"disabled\" (default)",
        keyPath: \.exponentGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let binaryGrouping = OptionDescriptor(
        argumentName: "binary-grouping",
        displayName: "Binary Grouping",
        help: "Binary grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.binaryGrouping
    )
    let octalGrouping = OptionDescriptor(
        argumentName: "octal-grouping",
        displayName: "Octal Grouping",
        help: "Octal grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.octalGrouping
    )
    let hexGrouping = OptionDescriptor(
        argumentName: "hex-grouping",
        displayName: "Hex Grouping",
        help: "Hex grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.hexGrouping
    )
    let hoistPatternLet = OptionDescriptor(
        argumentName: "pattern-let",
        displayName: "Pattern Let",
        help: "let/var placement in patterns: \"hoist\" (default) or \"inline\"",
        keyPath: \.hoistPatternLet,
        trueValues: ["hoist"],
        falseValues: ["inline"]
    )
    let stripUnusedArguments = OptionDescriptor(
        argumentName: "strip-unused-args",
        displayName: "Strip Unused Arguments",
        help: "\"closure-only\", \"unnamed-only\" or \"always\" (default)",
        keyPath: \.stripUnusedArguments
    )
    let elseOnNextLine = OptionDescriptor(
        argumentName: "else-position",
        displayName: "Else Position",
        help: "Placement of else/catch: \"same-line\" (default) or \"next-line\"",
        keyPath: \.elseOnNextLine,
        trueValues: ["next-line", "nextline"],
        falseValues: ["same-line", "sameline"]
    )
    let guardElsePosition = OptionDescriptor(
        argumentName: "guard-else",
        displayName: "Guard Else Position",
        help: "Guard else: \"same-line\", \"next-line\" or \"auto\" (default)",
        keyPath: \.guardElsePosition
    )
    let explicitSelf = OptionDescriptor(
        argumentName: "self",
        displayName: "Self",
        help: "Explicit self: \"insert\", \"remove\" (default) or \"init-only\"",
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
        help: "\"testable-first/last\", \"alpha\" (default) or \"length\"",
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
        help: "Match Xcode indenting: \"enabled\" or \"disabled\" (default)",
        keyPath: \.xcodeIndentation,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let tabWidth = OptionDescriptor(
        argumentName: "tab-width",
        displayName: "Tab Width",
        help: "The width of a tab character. Defaults to \"unspecified\"",
        keyPath: \.tabWidth,
        fromArgument: { $0.lowercased() == "unspecified" ? 0 : Int($0).map { max(0, $0) } },
        toArgument: { $0 > 0 ? String($0) : "unspecified" }
    )
    let maxWidth = OptionDescriptor(
        argumentName: "max-width",
        displayName: "Max Width",
        help: "Maximum length of a line before wrapping. defaults to \"none\"",
        keyPath: \.maxWidth,
        fromArgument: { $0.lowercased() == "none" ? 0 : Int($0).map { max(0, $0) } },
        toArgument: { $0 > 0 ? String($0) : "none" }
    )
    let smartTabs = OptionDescriptor(
        argumentName: "smart-tabs",
        displayName: "Smart Tabs",
        help: "Align code independently of tab width. defaults to \"enabled\"",
        keyPath: \.smartTabs,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let assetLiteralWidth = OptionDescriptor(
        argumentName: "asset-literals",
        displayName: "Asset Literals",
        help: "Color/image literal width. \"actual-width\" or \"visual-width\"",
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
        displayName: "Type delimiter spacing",
        help: "\"space-after\" (default), \"spaced\" or \"no-space\"",
        keyPath: \.typeDelimiterSpacing
    )
    let spaceAroundRangeOperators = OptionDescriptor(
        argumentName: "ranges",
        displayName: "Ranges",
        help: "Range spaces: \"spaced\" (default) or \"no-space\", or \"preserve\"",
        keyPath: \.spaceAroundRangeOperators,
        fromArgument: { argument in
            switch argument {
            case "spaced", "space", "spaces":
                return .insert
            case "no-space", "nospace":
                return .remove
            case "preserve", "preserve-spaces", "preservespaces":
                return .preserve
            default:
                return nil
            }
        },
        toArgument: { value in
            value.rawValue
        }
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
        help: "Use ? for optionals \"always\" or \"except-properties\" (default)",
        keyPath: \.shortOptionals
    )
    let markTypes = OptionDescriptor(
        argumentName: "mark-types",
        displayName: "Mark Types",
        help: "Mark types \"always\" (default), \"never\", \"if-not-empty\"",
        keyPath: \.markTypes
    )
    let typeMarkComment = OptionDescriptor(
        argumentName: "type-mark",
        displayName: "Type Mark Comment",
        help: "Template for type mark comments. Defaults to \"MARK: - %t\"",
        keyPath: \.typeMarkComment,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let markExtensions = OptionDescriptor(
        argumentName: "mark-extensions",
        displayName: "Mark Extensions",
        help: "Mark extensions \"always\" (default), \"never\", \"if-not-empty\"",
        keyPath: \.markExtensions
    )
    let extensionMarkComment = OptionDescriptor(
        argumentName: "extension-mark",
        displayName: "Extension Mark Comment",
        help: "Mark for standalone extensions. Defaults to \"MARK: - %t + %c\"",
        keyPath: \.extensionMarkComment,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let groupedExtensionMarkComment = OptionDescriptor(
        argumentName: "grouped-extension",
        displayName: "Grouped Extension Mark Comment",
        help: "Mark for extension grouped with extended type. (\"MARK: %c\")",
        keyPath: \.groupedExtensionMarkComment,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let markCategories = OptionDescriptor(
        argumentName: "mark-categories",
        displayName: "Mark Categories",
        help: "Insert MARK comments between categories (true by default)",
        keyPath: \.markCategories,
        trueValues: ["true"],
        falseValues: ["false"]
    )
    let categoryMarkComment = OptionDescriptor(
        argumentName: "category-mark",
        displayName: "Category Mark Comment",
        help: "Template for category mark comments. Defaults to \"MARK: %c\"",
        keyPath: \.categoryMarkComment,
        fromArgument: { $0 },
        toArgument: { $0 }
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
        help: "Organize declarations by \"visibility\" (default) or \"type\"",
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
        keyPath: \.blankLineAfterSubgroups,
        trueValues: ["true"],
        falseValues: ["false"]
    )
    let alphabeticallySortedDeclarationPatterns = OptionDescriptor(
        argumentName: "sorted-patterns",
        displayName: "Declaration Name Patterns To Sort Alphabetically",
        help: "List of patterns to sort alphabetically without `:sort` mark.",
        keyPath: \.alphabeticallySortedDeclarationPatterns
    )
    let funcAttributes = OptionDescriptor(
        argumentName: "func-attributes",
        displayName: "Function Attributes",
        help: "Function @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.funcAttributes
    )
    let typeAttributes = OptionDescriptor(
        argumentName: "type-attributes",
        displayName: "Type Attributes",
        help: "Type @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.typeAttributes
    )
    let storedVarAttributes = OptionDescriptor(
        argumentName: "stored-var-attributes",
        displayName: "Stored Property Attributes",
        help: "Stored var @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.storedVarAttributes
    )
    let computedVarAttributes = OptionDescriptor(
        argumentName: "computed-var-attributes",
        displayName: "Computed Property Attributes",
        help: "Computed var @attributes: \"preserve\", \"prev-line\", \"same-line\"",
        keyPath: \.computedVarAttributes
    )
    let complexAttributes = OptionDescriptor(
        argumentName: "complex-attributes",
        displayName: "Complex Attributes",
        help: "Complex @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
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
        help: "Swap yoda values: \"always\" (default) or \"literals-only\"",
        keyPath: \.yodaSwap
    )
    let extensionACLPlacement = OptionDescriptor(
        argumentName: "extension-acl",
        displayName: "Extension Access Control Level Placement",
        help: "Place ACL \"on-extension\" (default) or \"on-declarations\"",
        keyPath: \.extensionACLPlacement
    )
    let propertyTypes = OptionDescriptor(
        argumentName: "property-types",
        displayName: "Property Types",
        help: "\"inferred\", \"explicit\", or \"infer-locals-only\" (default)",
        keyPath: \.propertyTypes
    )
    let inferredTypesInConditionalExpressions = OptionDescriptor(
        argumentName: "inferred-types",
        displayName: "Prefer Inferred Types",
        help: "\"exclude-cond-exprs\" (default) or \"always\"",
        keyPath: \.inferredTypesInConditionalExpressions,
        trueValues: ["exclude-cond-exprs"],
        falseValues: ["always"]
    )
    let emptyBracesSpacing = OptionDescriptor(
        argumentName: "empty-braces",
        displayName: "Empty Braces",
        help: "Empty braces: \"no-space\" (default), \"spaced\" or \"linebreak\"",
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
        help: "Indent multiline strings: \"false\" (default) or \"true\"",
        keyPath: \.indentStrings,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let closureVoidReturn = OptionDescriptor(
        argumentName: "closure-void",
        displayName: "Closure Void Return",
        help: "Closure void returns: \"remove\" (default) or \"preserve\"",
        keyPath: \.closureVoidReturn
    )
    let enumNamespaces = OptionDescriptor(
        argumentName: "enum-namespaces",
        displayName: "Convert namespaces types to enum",
        help: "Change type to enum: \"always\" (default) or \"structs-only\"",
        keyPath: \.enumNamespaces
    )
    let typeBlankLines = OptionDescriptor(
        argumentName: "type-blank-lines",
        displayName: "Blank lines types",
        help: "breakLine: \"remove\" (default), \"insert\", or \"preserve\"",
        keyPath: \.typeBlankLines
    )
    let genericTypes = OptionDescriptor(
        argumentName: "generic-types",
        displayName: "Additional generic types",
        help: "Semicolon-delimited list of generic types and type parameters. For example: \"LinkedList<Element>;StateStore<State, Action>\"",
        keyPath: \.genericTypes,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let useSomeAny = OptionDescriptor(
        argumentName: "some-any",
        displayName: "Use `some Any`",
        help: "Use `some Any` types: \"true\" (default) or \"false\"",
        keyPath: \.useSomeAny,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let preserveAnonymousForEach = OptionDescriptor(
        argumentName: "anonymous-for-each",
        displayName: "Anonymous forEach closures",
        help: "Convert anonymous forEach closures to for loops: \"convert\" (default) or \"ignore\"",
        keyPath: \.preserveAnonymousForEach,
        trueValues: ["ignore", "preserve"],
        falseValues: ["convert"]
    )
    let preserveSingleLineForEach = OptionDescriptor(
        argumentName: "single-line-for-each",
        displayName: "Single-line forEach closures",
        help: "Convert single-line forEach closures to for loop: \"convert\", \"ignore\" (default)",
        keyPath: \.preserveSingleLineForEach,
        trueValues: ["ignore", "preserve"],
        falseValues: ["convert"]
    )
    let preserveDocComments = OptionDescriptor(
        argumentName: "doc-comments",
        displayName: "Doc comments",
        help: "Convert standard comments to doc comments: \"before-declarations\" (default) or \"preserve\"",
        keyPath: \.preserveDocComments,
        trueValues: ["preserve"],
        falseValues: ["before-declarations", "declarations"]
    )
    let conditionalAssignmentOnlyAfterNewProperties = OptionDescriptor(
        argumentName: "conditional-assignment",
        displayName: "Apply conditionalAssignment rule",
        help: "Use if/switch expressions for conditional assignment: \"after-property\" (default) or \"always\"",
        keyPath: \.conditionalAssignmentOnlyAfterNewProperties,
        trueValues: ["after-property"],
        falseValues: ["always"]
    )
    let initCoderNil = OptionDescriptor(
        argumentName: "init-coder-nil",
        displayName: "Return nil in init?(coder)",
        help: "Replace fatalError with nil in unavailable init?(coder:)",
        keyPath: \.initCoderNil,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let dateFormat = OptionDescriptor(
        argumentName: "date-format",
        displayName: "Date format",
        help: "\"system\" (default), \"iso\", \"dmy\", \"mdy\" or custom",
        keyPath: \.dateFormat,
        fromArgument: { DateFormat(rawValue: $0) },
        toArgument: { $0.rawValue }
    )
    let timeZone = OptionDescriptor(
        argumentName: "timezone",
        displayName: "Date formatting timezone",
        help: "\"system\" (default) or a valid identifier/abbreviation",
        keyPath: \.timeZone,
        fromArgument: { FormatTimeZone(rawValue: $0) },
        toArgument: { $0.rawValue }
    )
    let nilInit = OptionDescriptor(
        argumentName: "nil-init",
        displayName: "Nil init type",
        help: "\"remove\" (default) redundant nil or \"insert\" missing nil",
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
        help: "Sort SwiftUI props: \"none\", \"alphabetize\", \"first-appearance-sort\"",
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
        help: "File macro to prefer: \"#file\" (default) or \"#fileID\".",
        keyPath: \.preferFileMacro,
        trueValues: ["#file", "file"],
        falseValues: ["#fileID", "fileID"]
    )
    let lineBetweenConsecutiveGuards = OptionDescriptor(
        argumentName: "line-between-guards",
        displayName: "Blank Line Between Consecutive Guards",
        help: "Insert line between guards: \"true\" or \"false\" (default)",
        keyPath: \.lineBetweenConsecutiveGuards,
        trueValues: ["true"],
        falseValues: ["false"]
    )

    // MARK: - Internal

    let fragment = OptionDescriptor(
        argumentName: "fragment",
        displayName: "Fragment",
        help: "Input is part of a larger file: \"true\" or \"false\" (default)",
        keyPath: \.fragment,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let ignoreConflictMarkers = OptionDescriptor(
        argumentName: "conflict-markers",
        displayName: "Conflict Markers",
        help: "Merge-conflict markers: \"reject\" (default) or \"ignore\"",
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

    // MARK: - DEPRECATED

    let indentComments = OptionDescriptor(
        argumentName: "comments",
        displayName: "Comments",
        help: "Indenting of comment bodies: \"indent\" (default) or \"ignore\"",
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
