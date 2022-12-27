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
        // index 0 is official value, others are acceptable
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
    let help: String
    let deprecationMessage: String?
    let toOptions: (String, inout FormatOptions) throws -> Void
    let fromOptions: (FormatOptions) -> String
    private(set) var type: ArgumentType

    var isDeprecated: Bool {
        deprecationMessage != nil
    }

    var isRenamed: Bool {
        isDeprecated && Descriptors.all.contains(where: {
            $0.propertyName == propertyName && $0.argumentName != argumentName
        })
    }

    var defaultArgument: String {
        fromOptions(FormatOptions.default)
    }

    func validateArgument(_ arg: String) -> Bool {
        var options = FormatOptions.default
        return (try? toOptions(arg, &options)) != nil
    }

    fileprivate func renamed(to newPropertyName: String) -> OptionDescriptor {
        propertyName = newPropertyName
        return self
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
        assert(argumentName.count <= Options.maxArgumentNameLength)
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
            type: .enum(T.allCases.map { $0.rawValue }),
            altOptions: altOptions
        )
    }

    init(argumentName: String,
         displayName: String,
         help: String,
         deprecationMessage: String? = nil,
         keyPath: WritableKeyPath<FormatOptions, [String]>,
         validate: @escaping (String) throws -> Void = { _ in })
    {
        self.argumentName = argumentName
        self.displayName = displayName
        self.help = help
        self.deprecationMessage = deprecationMessage
        type = .array
        toOptions = { value, options in
            let values = parseCommaDelimitedList(value)
            for (index, value) in values.enumerated() {
                if values[0 ..< index].contains(value) {
                    throw FormatError.options("Duplicate value '\(value)'")
                }
                try validate(value)
            }
            options[keyPath: keyPath] = values
        }
        fromOptions = { options in
            options[keyPath: keyPath].joined(separator: ",")
        }
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

let Descriptors = _Descriptors()

private var _allDescriptors: [OptionDescriptor] = {
    var descriptors = [OptionDescriptor]()
    for (label, value) in Mirror(reflecting: Descriptors).children {
        guard let name = label, var descriptor = value as? OptionDescriptor else {
            continue
        }
        if descriptor.propertyName.isEmpty {
            descriptor.propertyName = name
        }
        descriptors.append(descriptor)
    }
    return descriptors
}()

private var _descriptorsByName: [String: OptionDescriptor] = Dictionary(uniqueKeysWithValues: _allDescriptors.map { ($0.argumentName, $0) })

private let _formattingDescriptors: [OptionDescriptor] = {
    let internalDescriptors = Descriptors.internal.map { $0.argumentName }
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
        ]
    }

    /// An Array of all descriptors
    var all: [OptionDescriptor] { _allDescriptors }

    /// A Dictionary of descriptors by name
    var byName: [String: OptionDescriptor] {
        _descriptorsByName
    }
}

struct _Descriptors {
    let lineAfterMarks = OptionDescriptor(
        argumentName: "lineaftermarks",
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
        argumentName: "operatorfunc",
        displayName: "Operator Functions",
        help: "Spacing for operator funcs: \"spaced\" (default) or \"no-space\"",
        keyPath: \.spaceAroundOperatorDeclarations,
        trueValues: ["spaced", "space", "spaces"],
        falseValues: ["no-space", "nospace"]
    )
    let useVoid = OptionDescriptor(
        argumentName: "voidtype",
        displayName: "Void Type",
        help: "How void types are represented: \"void\" (default) or \"tuple\"",
        keyPath: \.useVoid,
        trueValues: ["void"],
        falseValues: ["tuple", "tuples", "()"]
    )
    let indentCase = OptionDescriptor(
        argumentName: "indentcase",
        displayName: "Indent Case",
        help: "Indent cases inside a switch: \"true\" or \"false\" (default)",
        keyPath: \.indentCase,
        trueValues: ["true"],
        falseValues: ["false"]
    )
    let trailingCommas = OptionDescriptor(
        argumentName: "commas",
        displayName: "Commas",
        help: "Commas in collection literals: \"always\" (default) or \"inline\"",
        keyPath: \.trailingCommas,
        trueValues: ["always", "true"],
        falseValues: ["inline", "false"]
    )
    let truncateBlankLines = OptionDescriptor(
        argumentName: "trimwhitespace",
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
        argumentName: "wraparguments",
        displayName: "Wrap Arguments",
        help: "Wrap all arguments: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapArguments
    )
    let wrapEnumCases = OptionDescriptor(
        argumentName: "wrapenumcases",
        displayName: "Wrap Enum Cases",
        help: "Wrap enum cases: \"always\" (default) or \"with-values\"",
        keyPath: \.wrapEnumCases
    )
    let wrapParameters = OptionDescriptor(
        argumentName: "wrapparameters",
        displayName: "Wrap Parameters",
        help: "Wrap func params: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapParameters
    )
    let wrapCollections = OptionDescriptor(
        argumentName: "wrapcollections",
        displayName: "Wrap Collections",
        help: "Wrap array/dict: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapCollections
    )
    let wrapTypealiases = OptionDescriptor(
        argumentName: "wraptypealiases",
        displayName: "Wrap Typealiases",
        help: "Wrap typealiases: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapTypealiases
    )
    let wrapReturnType = OptionDescriptor(
        argumentName: "wrapreturntype",
        displayName: "Wrap Return Type",
        help: "Wrap return type: \"if-multiline\", \"preserve\" (default)",
        keyPath: \.wrapReturnType
    )
    let wrapEffects = OptionDescriptor(
        argumentName: "wrapeffects",
        displayName: "Wrap Function Effects (throws, async)",
        help: "Wrap effects: \"if-multiline\", \"never\", \"preserve\"",
        keyPath: \.wrapEffects
    )
    let wrapConditions = OptionDescriptor(
        argumentName: "wrapconditions",
        displayName: "Wrap Conditions",
        help: "Wrap conditions: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapConditions
    )
    let wrapTernaryOperators = OptionDescriptor(
        argumentName: "wrapternary",
        displayName: "Wrap Ternary Operators",
        help: "Wrap ternary operators: \"default\", \"before-operators\"",
        keyPath: \.wrapTernaryOperators
    )
    let conditionsWrap = OptionDescriptor(
        argumentName: "conditionswrap",
        displayName: "Conditions Wrap",
        help: "Wrap conditions as Xcode 12:\"auto\", \"always\", \"disabled\"",
        keyPath: \.conditionsWrap
    )
    let closingParenOnSameLine = OptionDescriptor(
        argumentName: "closingparen",
        displayName: "Closing Paren Position",
        help: "Closing paren position: \"balanced\" (default) or \"same-line\"",
        keyPath: \.closingParenOnSameLine,
        trueValues: ["same-line"],
        falseValues: ["balanced"]
    )
    let uppercaseHex = OptionDescriptor(
        argumentName: "hexliteralcase",
        displayName: "Hex Literal Case",
        help: "Casing for hex literals: \"uppercase\" (default) or \"lowercase\"",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    let uppercaseExponent = OptionDescriptor(
        argumentName: "exponentcase",
        displayName: "Exponent Case",
        help: "Case of 'e' in numbers: \"lowercase\" or \"uppercase\" (default)",
        keyPath: \.uppercaseExponent,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    let decimalGrouping = OptionDescriptor(
        argumentName: "decimalgrouping",
        displayName: "Decimal Grouping",
        help: "Decimal grouping,threshold (default: 3,6) or \"none\", \"ignore\"",
        keyPath: \.decimalGrouping
    )
    let fractionGrouping = OptionDescriptor(
        argumentName: "fractiongrouping",
        displayName: "Fraction Grouping",
        help: "Group digits after '.': \"enabled\" or \"disabled\" (default)",
        keyPath: \.fractionGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let exponentGrouping = OptionDescriptor(
        argumentName: "exponentgrouping",
        displayName: "Exponent Grouping",
        help: "Group exponent digits: \"enabled\" or \"disabled\" (default)",
        keyPath: \.exponentGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let binaryGrouping = OptionDescriptor(
        argumentName: "binarygrouping",
        displayName: "Binary Grouping",
        help: "Binary grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.binaryGrouping
    )
    let octalGrouping = OptionDescriptor(
        argumentName: "octalgrouping",
        displayName: "Octal Grouping",
        help: "Octal grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.octalGrouping
    )
    let hexGrouping = OptionDescriptor(
        argumentName: "hexgrouping",
        displayName: "Hex Grouping",
        help: "Hex grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.hexGrouping
    )
    let hoistPatternLet = OptionDescriptor(
        argumentName: "patternlet",
        displayName: "Pattern Let",
        help: "let/var placement in patterns: \"hoist\" (default) or \"inline\"",
        keyPath: \.hoistPatternLet,
        trueValues: ["hoist"],
        falseValues: ["inline"]
    )
    let stripUnusedArguments = OptionDescriptor(
        argumentName: "stripunusedargs",
        displayName: "Strip Unused Arguments",
        help: "\"closure-only\", \"unnamed-only\" or \"always\" (default)",
        keyPath: \.stripUnusedArguments
    )
    let elseOnNextLine = OptionDescriptor(
        argumentName: "elseposition",
        displayName: "Else Position",
        help: "Placement of else/catch: \"same-line\" (default) or \"next-line\"",
        keyPath: \.elseOnNextLine,
        trueValues: ["next-line", "nextline"],
        falseValues: ["same-line", "sameline"]
    )
    let guardElsePosition = OptionDescriptor(
        argumentName: "guardelse",
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
        argumentName: "selfrequired",
        displayName: "Self Required",
        help: "Comma-delimited list of functions with @autoclosure arguments",
        keyPath: \FormatOptions.selfRequired
    )
    let throwCapturing = OptionDescriptor(
        argumentName: "throwcapturing",
        displayName: "Throw Capturing",
        help: "List of functions with throwing @autoclosure arguments",
        keyPath: \FormatOptions.throwCapturing
    )
    let asyncCapturing = OptionDescriptor(
        argumentName: "asynccapturing",
        displayName: "Async Capturing",
        help: "List of functions with async @autoclosure arguments",
        keyPath: \FormatOptions.asyncCapturing
    )
    let importGrouping = OptionDescriptor(
        argumentName: "importgrouping",
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
        argumentName: "trailingclosures",
        displayName: "Trailing Closure Functions",
        help: "Comma-delimited list of functions that use trailing closures",
        keyPath: \FormatOptions.trailingClosures
    )
    let neverTrailing = OptionDescriptor(
        argumentName: "nevertrailing",
        displayName: "Never Trailing Functions",
        help: "List of functions that should never use trailing closures",
        keyPath: \FormatOptions.neverTrailing
    )
    let xcodeIndentation = OptionDescriptor(
        argumentName: "xcodeindentation",
        displayName: "Xcode Indentation",
        help: "Match Xcode indenting: \"enabled\" or \"disabled\" (default)",
        keyPath: \.xcodeIndentation,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let tabWidth = OptionDescriptor(
        argumentName: "tabwidth",
        displayName: "Tab Width",
        help: "The width of a tab character. Defaults to \"unspecified\"",
        keyPath: \.tabWidth,
        fromArgument: { $0.lowercased() == "unspecified" ? 0 : Int($0).map { max(0, $0) } },
        toArgument: { $0 > 0 ? String($0) : "unspecified" }
    )
    let maxWidth = OptionDescriptor(
        argumentName: "maxwidth",
        displayName: "Max Width",
        help: "Maximum length of a line before wrapping. defaults to \"none\"",
        keyPath: \.maxWidth,
        fromArgument: { $0.lowercased() == "none" ? 0 : Int($0).map { max(0, $0) } },
        toArgument: { $0 > 0 ? String($0) : "none" }
    )
    let smartTabs = OptionDescriptor(
        argumentName: "smarttabs",
        displayName: "Smart Tabs",
        help: "Align code independently of tab width. defaults to \"enabled\"",
        keyPath: \.smartTabs,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let assetLiteralWidth = OptionDescriptor(
        argumentName: "assetliterals",
        displayName: "Asset Literals",
        help: "Color/image literal width. \"actual-width\" or \"visual-width\"",
        keyPath: \.assetLiteralWidth
    )
    let noSpaceOperators = OptionDescriptor(
        argumentName: "nospaceoperators",
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
    let spaceAroundDelimiter = OptionDescriptor(
        argumentName: "typedelimiter",
        displayName: "Spacing around delimiter",
        help: "\"trailing\" (default) or \"leading-trailing\"",
        keyPath: \.spaceAroundDelimiter
    )
    let spaceAroundRangeOperators = OptionDescriptor(
        argumentName: "ranges",
        displayName: "Ranges",
        help: "Spacing for ranges: \"spaced\" (default) or \"no-space\"",
        keyPath: \.spaceAroundRangeOperators,
        trueValues: ["spaced", "space", "spaces"],
        falseValues: ["no-space", "nospace"]
    )
    let noWrapOperators = OptionDescriptor(
        argumentName: "nowrapoperators",
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
        argumentName: "modifierorder",
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
        argumentName: "shortoptionals",
        displayName: "Short Optional Syntax",
        help: "Use ? for optionals \"always\" (default) or \"except-properties\"",
        keyPath: \.shortOptionals
    )
    let markTypes = OptionDescriptor(
        argumentName: "marktypes",
        displayName: "Mark Types",
        help: "Mark types \"always\" (default), \"never\", \"if-not-empty\"",
        keyPath: \.markTypes
    )
    let typeMarkComment = OptionDescriptor(
        argumentName: "typemark",
        displayName: "Type Mark Comment",
        help: "Template for type mark comments. Defaults to \"MARK: - %t\"",
        keyPath: \.typeMarkComment,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let markExtensions = OptionDescriptor(
        argumentName: "markextensions",
        displayName: "Mark Extensions",
        help: "Mark extensions \"always\" (default), \"never\", \"if-not-empty\"",
        keyPath: \.markExtensions
    )
    let extensionMarkComment = OptionDescriptor(
        argumentName: "extensionmark",
        displayName: "Extension Mark Comment",
        help: "Mark for standalone extensions. Defaults to \"MARK: - %t + %c\"",
        keyPath: \.extensionMarkComment,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let groupedExtensionMarkComment = OptionDescriptor(
        argumentName: "groupedextension",
        displayName: "Grouped Extension Mark Comment",
        help: "Mark for extension grouped with extended type. (\"MARK: %c\")",
        keyPath: \.groupedExtensionMarkComment,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let markCategories = OptionDescriptor(
        argumentName: "markcategories",
        displayName: "Mark Categories",
        help: "Insert MARK comments between categories (true by default)",
        keyPath: \.markCategories,
        trueValues: ["true"],
        falseValues: ["false"]
    )
    let categoryMarkComment = OptionDescriptor(
        argumentName: "categorymark",
        displayName: "Category Mark Comment",
        help: "Template for category mark comments. Defaults to \"MARK: %c\"",
        keyPath: \.categoryMarkComment,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let beforeMarks = OptionDescriptor(
        argumentName: "beforemarks",
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
        argumentName: "organizetypes",
        displayName: "Declaration Types to Organize",
        help: "Declarations to organize (default: `class,actor,struct,enum`)",
        keyPath: \.organizeTypes
    )
    let organizeStructThreshold = OptionDescriptor(
        argumentName: "structthreshold",
        displayName: "Organize Struct Threshold",
        help: "Minimum line count to organize struct body. Defaults to 0",
        keyPath: \.organizeStructThreshold
    )
    let organizeClassThreshold = OptionDescriptor(
        argumentName: "classthreshold",
        displayName: "Organize Class Threshold",
        help: "Minimum line count to organize class body. Defaults to 0",
        keyPath: \.organizeClassThreshold
    )
    let organizeEnumThreshold = OptionDescriptor(
        argumentName: "enumthreshold",
        displayName: "Organize Enum Threshold",
        help: "Minimum line count to organize enum body. Defaults to 0",
        keyPath: \.organizeEnumThreshold
    )
    let organizeExtensionThreshold = OptionDescriptor(
        argumentName: "extensionlength",
        displayName: "Organize Extension Threshold",
        help: "Minimum line count to organize extension body. Defaults to 0",
        keyPath: \.organizeExtensionThreshold
    )
    let funcAttributes = OptionDescriptor(
        argumentName: "funcattributes",
        displayName: "Function Attributes",
        help: "Function @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.funcAttributes
    )
    let typeAttributes = OptionDescriptor(
        argumentName: "typeattributes",
        displayName: "Type Attributes",
        help: "Type @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.typeAttributes
    )
    let varAttributes = OptionDescriptor(
        argumentName: "varattributes",
        displayName: "Var Attributes",
        help: "Property @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.varAttributes
    )
    let yodaSwap = OptionDescriptor(
        argumentName: "yodaswap",
        displayName: "Yoda Swap",
        help: "Swap yoda values: \"always\" (default) or \"literals-only\"",
        keyPath: \.yodaSwap
    )
    let extensionACLPlacement = OptionDescriptor(
        argumentName: "extensionacl",
        displayName: "Extension Access Control Level Placement",
        help: "Place ACL \"on-extension\" (default) or \"on-declarations\"",
        keyPath: \.extensionACLPlacement
    )
    let redundantType = OptionDescriptor(
        argumentName: "redundanttype",
        displayName: "Redundant Type",
        help: "\"inferred\", \"explicit\", or \"infer-locals-only\" (default)",
        keyPath: \.redundantType
    )
    let emptyBracesSpacing = OptionDescriptor(
        argumentName: "emptybraces",
        displayName: "Empty Braces",
        help: "Empty braces: \"no-space\" (default), \"spaced\" or \"linebreak\"",
        keyPath: \.emptyBracesSpacing
    )
    let acronyms = OptionDescriptor(
        argumentName: "acronyms",
        displayName: "Acronyms",
        help: "Acronyms to auto-capitalize. Defaults to \"ID,URL,UUID\".",
        keyPath: \.acronyms
    )
    let indentStrings = OptionDescriptor(
        argumentName: "indentstrings",
        displayName: "Indent Strings",
        help: "Indent multiline strings: \"false\" (default) or \"true\"",
        keyPath: \.indentStrings,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    let closureVoidReturn = OptionDescriptor(
        argumentName: "closurevoid",
        displayName: "Closure Void Return",
        help: "Closure void returns: \"remove\" (default) or \"preserve\"",
        keyPath: \.closureVoidReturn
    )
    let enumNamespaces = OptionDescriptor(
        argumentName: "enumnamespaces",
        displayName: "Convert namespaces types to enum",
        help: "Change type to enum: \"always\" (default) or \"structs-only\"",
        keyPath: \.enumNamespaces
    )
    let removeStartOrEndBlankLinesFromTypes = OptionDescriptor(
        argumentName: "typeblanklines",
        displayName: "Remove blank lines from types",
        help: "\"remove\" (default) or \"preserve\" blank lines from types",
        keyPath: \.removeStartOrEndBlankLinesFromTypes,
        trueValues: ["remove"],
        falseValues: ["preserve"]
    )
    let genericTypes = OptionDescriptor(
        argumentName: "generictypes",
        displayName: "Additional generic types",
        help: "Semicolon-delimited list of generic types and type parameters",
        keyPath: \.genericTypes,
        fromArgument: { $0 },
        toArgument: { $0 }
    )
    let useSomeAny = OptionDescriptor(
        argumentName: "someAny",
        displayName: "Use `some Any`",
        help: "Use `some Any` types: \"true\" (default) or \"false\"",
        keyPath: \.useSomeAny,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
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
        argumentName: "conflictmarkers",
        displayName: "Conflict Markers",
        help: "Merge-conflict markers: \"reject\" (default) or \"ignore\"",
        keyPath: \.ignoreConflictMarkers,
        trueValues: ["ignore", "true", "enabled"],
        falseValues: ["reject", "false", "disabled"]
    )
    let swiftVersion = OptionDescriptor(
        argumentName: "swiftversion",
        displayName: "Swift Version",
        help: "The version of Swift used in the files being formatted",
        keyPath: \.swiftVersion
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
        argumentName: "insertlines",
        displayName: "Insert Lines",
        help: "deprecated",
        deprecationMessage: "Use '--enable blankLinesBetweenScopes' or '--enable blankLinesAroundMark' or '--disable blankLinesBetweenScopes' or '--disable blankLinesAroundMark' instead.",
        keyPath: \.insertBlankLines,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    let removeBlankLines = OptionDescriptor(
        argumentName: "removelines",
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

    // MARK: - RENAMED

    let empty = OptionDescriptor(
        argumentName: "empty",
        displayName: "Empty",
        help: "deprecated",
        deprecationMessage: "Use --voidtype instead.",
        keyPath: \.useVoid,
        trueValues: ["void"],
        falseValues: ["tuple", "tuples"]
    ).renamed(to: "useVoid")

    let hexLiterals = OptionDescriptor(
        argumentName: "hexliterals",
        displayName: "hexliterals",
        help: "deprecated",
        deprecationMessage: "Use --hexliteralcase instead.",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    ).renamed(to: "uppercaseHex")

    let wrapElements = OptionDescriptor(
        argumentName: "wrapelements",
        displayName: "Wrap Elements",
        help: "deprecated",
        deprecationMessage: "Use --wrapcollections instead.",
        keyPath: \.wrapCollections
    ).renamed(to: "wrapCollections")

    let specifierOrder = OptionDescriptor(
        argumentName: "specifierorder",
        displayName: "Specifier Order",
        help: "deprecated",
        deprecationMessage: "Use --modifierorder instead.",
        keyPath: \FormatOptions.modifierOrder,
        validate: {
            guard _FormatRules.mapModifiers($0) != nil else {
                throw FormatError.options("'\($0)' is not a valid specifier")
            }
        }
    ).renamed(to: "modifierOrder")
}
