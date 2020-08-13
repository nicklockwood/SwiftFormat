//
//  OptionsDescriptor.swift
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

extension FormatOptions {
    struct Descriptor {
        enum ArgumentType: EnumAssociable {
            // index 0 is official value, others are acceptable
            case binary(true: [String], false: [String])
            case `enum`([String])
            case text
            case array
            case set
        }

        let argumentName: String // command-line argument; must not change
        let propertyName: String // internal property; ok to change this
        let displayName: String
        let help: String
        let toOptions: (String, inout FormatOptions) throws -> Void
        let fromOptions: (FormatOptions) -> String
        private(set) var type: ArgumentType

        var deprecationMessage: String? {
            return FormatOptions.Descriptor.deprecatedMessage[argumentName]
        }

        var isDeprecated: Bool {
            return deprecationMessage != nil
        }

        var isRenamed: Bool {
            return deprecationMessage != nil && FormatOptions.Descriptor.all.contains(where: {
                $0.propertyName == propertyName && $0.argumentName != argumentName
            })
        }

        var defaultArgument: String {
            return fromOptions(FormatOptions.default)
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
             propertyName: String,
             displayName: String,
             help: String,
             keyPath: WritableKeyPath<FormatOptions, Bool>,
             trueValues: [String],
             falseValues: [String])
        {
            assert(argumentName.count <= Options.maxArgumentNameLength)
            self.argumentName = argumentName
            self.propertyName = propertyName
            self.displayName = displayName
            self.help = help
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
                propertyName: String,
                displayName: String,
                help: String,
                keyPath: WritableKeyPath<FormatOptions, T>,
                fromArgument: @escaping (String) -> T?,
                toArgument: @escaping (T) -> String)
        {
            self.argumentName = argumentName
            self.propertyName = propertyName
            self.displayName = displayName
            self.help = help
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

        init(argumentName: String,
             propertyName: String,
             displayName: String,
             help: String,
             keyPath: WritableKeyPath<FormatOptions, String>,
             options: DictionaryLiteral<String, String>)
        {
            let map: [String: String] = Dictionary(options.map { ($0, $1) }, uniquingKeysWith: { $1 })
            let keys = Array(map.keys)
            self.init(argumentName: argumentName,
                      propertyName: propertyName,
                      displayName: displayName,
                      help: help,
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

        init<T: RawRepresentable>(argumentName: String,
                                  propertyName: String,
                                  displayName: String,
                                  help: String = "",
                                  keyPath: WritableKeyPath<FormatOptions, T>) where T.RawValue == String
        {
            self.argumentName = argumentName
            self.propertyName = propertyName
            self.displayName = displayName
            self.help = help
            type = .text
            toOptions = { value, options in
                guard let value = T(rawValue: value) ?? T(rawValue: value.lowercased()) else {
                    throw FormatError.options("")
                }
                options[keyPath: keyPath] = value
            }
            fromOptions = { options in
                options[keyPath: keyPath].rawValue
            }
        }

        init<T: RawRepresentable>(argumentName: String,
                                  propertyName: String,
                                  displayName: String,
                                  help: String = "",
                                  keyPath: WritableKeyPath<FormatOptions, T>,
                                  options: [String]) where T.RawValue == String
        {
            self.init(
                argumentName: argumentName,
                propertyName: propertyName,
                displayName: displayName,
                help: help,
                keyPath: keyPath
            )
            type = .enum(options)
        }

        init(argumentName: String,
             propertyName: String,
             displayName: String,
             help: String,
             keyPath: WritableKeyPath<FormatOptions, [String]>,
             validate: @escaping (String) throws -> Void = { _ in })
        {
            self.argumentName = argumentName
            self.propertyName = propertyName
            self.displayName = displayName
            self.help = help
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
             propertyName: String,
             displayName: String,
             help: String,
             keyPath: WritableKeyPath<FormatOptions, Set<String>>,
             validate: @escaping (String) throws -> Void = { _ in })
        {
            self.argumentName = argumentName
            self.propertyName = propertyName
            self.displayName = displayName
            self.help = help
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
}

extension FormatOptions.Descriptor {
    static let formatting: [FormatOptions.Descriptor] = [
        indentation,
        lineBreak,
        allowInlineSemicolons,
        spaceAroundOperatorDeclarations,
        useVoid,
        indentCase,
        trailingCommas,
        truncateBlankLines,
        allmanBraces,
        fileHeader,
        ifdefIndent,
        wrapArguments,
        wrapParameters,
        wrapCollections,
        closingParen,
        hexLiteralCase,
        exponentCase,
        decimalGrouping,
        binaryGrouping,
        octalGrouping,
        hexGrouping,
        fractionGrouping,
        exponentGrouping,
        letPatternPlacement,
        stripUnusedArguments,
        elsePosition,
        guardElse,
        explicitSelf,
        selfRequired,
        importGrouping,
        trailingClosures,
        xcodeIndentation,
        tabWidth,
        maxWidth,
        smartTabs,
        modifierOrder,
        noSpaceOperators,
        noWrapOperators,
        shortOptionals,
        funcAttributes,
        typeAttributes,
        varAttributes,
        yodaSwap,

        // Deprecated
        empty,
        indentComments,
        insertBlankLines,
        removeBlankLines,
        spaceAroundRangeOperators,
        specifierOrder,

        // Renamed
        // NOTE: these must go after the non-deprecated versions
        // to ensure OptionsStore loading works correctly
        hexLiterals,
        wrapElements,
    ]

    static let `internal`: [FormatOptions.Descriptor] = [
        experimentalRules,
        fragment,
        ignoreConflictMarkers,
        swiftVersion,
    ]

    /// An Array of all descriptors
    static let all = formatting + `internal`

    /// A Dictionary of descriptors by name
    public static let byName: [String: FormatOptions.Descriptor] = {
        var allOptions = [String: FormatOptions.Descriptor]()
        all.forEach { allOptions[$0.argumentName] = $0 }
        return allOptions
    }()

    static let indentation = FormatOptions.Descriptor(
        argumentName: "indent",
        propertyName: "indent",
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
    static let lineBreak = FormatOptions.Descriptor(
        argumentName: "linebreaks",
        propertyName: "linebreak",
        displayName: "Linebreak Character",
        help: "Linebreak character to use: \"cr\", \"crlf\" or \"lf\" (default)",
        keyPath: \.linebreak,
        options: ["cr": "\r", "lf": "\n", "crlf": "\r\n"]
    )
    static let allowInlineSemicolons = FormatOptions.Descriptor(
        argumentName: "semicolons",
        propertyName: "allowInlineSemicolons",
        displayName: "Semicolons",
        help: "Allow semicolons: \"never\" or \"inline\" (default)",
        keyPath: \.allowInlineSemicolons,
        trueValues: ["inline"],
        falseValues: ["never", "false"]
    )
    static let spaceAroundOperatorDeclarations = FormatOptions.Descriptor(
        argumentName: "operatorfunc",
        propertyName: "spaceAroundOperatorDeclarations",
        displayName: "Operator Functions",
        help: "Spacing for operator funcs: \"spaced\" (default) or \"no-space\"",
        keyPath: \.spaceAroundOperatorDeclarations,
        trueValues: ["spaced", "space", "spaces"],
        falseValues: ["no-space", "nospace"]
    )
    static let useVoid = FormatOptions.Descriptor(
        argumentName: "voidtype",
        propertyName: "useVoid",
        displayName: "Void Type",
        help: "How Void types are represented: \"void\" (default) or \"tuple\"",
        keyPath: \.useVoid,
        trueValues: ["void"],
        falseValues: ["tuple", "tuples", "()"]
    )
    static let indentCase = FormatOptions.Descriptor(
        argumentName: "indentcase",
        propertyName: "indentCase",
        displayName: "Indent Case",
        help: "Indent cases inside a switch: \"true\" or \"false\" (default)",
        keyPath: \.indentCase,
        trueValues: ["true"],
        falseValues: ["false"]
    )
    static let trailingCommas = FormatOptions.Descriptor(
        argumentName: "commas",
        propertyName: "trailingCommas",
        displayName: "Commas",
        help: "Commas in collection literals: \"always\" (default) or \"inline\"",
        keyPath: \.trailingCommas,
        trueValues: ["always", "true"],
        falseValues: ["inline", "false"]
    )
    static let truncateBlankLines = FormatOptions.Descriptor(
        argumentName: "trimwhitespace",
        propertyName: "truncateBlankLines",
        displayName: "Trim White Space",
        help: "Trim trailing space: \"always\" (default) or \"nonblank-lines\"",
        keyPath: \.truncateBlankLines,
        trueValues: ["always"],
        falseValues: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank",
                      "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"]
    )
    static let allmanBraces = FormatOptions.Descriptor(
        argumentName: "allman",
        propertyName: "allmanBraces",
        displayName: "Allman Braces",
        help: "Use allman indentation style: \"true\" or \"false\" (default)",
        keyPath: \.allmanBraces,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    static let fileHeader = FormatOptions.Descriptor(
        argumentName: "header",
        propertyName: "fileHeader",
        displayName: "Header",
        help: "Header comments: \"strip\", \"ignore\", or the text you wish use",
        keyPath: \.fileHeader
    )
    static let ifdefIndent = FormatOptions.Descriptor(
        argumentName: "ifdef",
        propertyName: "ifdefIndent",
        displayName: "Ifdef Indent",
        help: "#if indenting: \"indent\" (default), \"no-indent\" or \"outdent\"",
        keyPath: \.ifdefIndent,
        options: ["indent", "no-indent", "outdent"]
    )
    static let wrapArguments = FormatOptions.Descriptor(
        argumentName: "wraparguments",
        propertyName: "wrapArguments",
        displayName: "Wrap Arguments",
        help: "Wrap all arguments: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapArguments,
        options: ["before-first", "after-first", "preserve", "disabled"]
    )
    static let wrapParameters = FormatOptions.Descriptor(
        argumentName: "wrapparameters",
        propertyName: "wrapParameters",
        displayName: "Wrap Parameters",
        help: "Wrap func params: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapParameters,
        options: ["before-first", "after-first", "preserve", "disabled"]
    )
    static let wrapCollections = FormatOptions.Descriptor(
        argumentName: "wrapcollections",
        propertyName: "wrapCollections",
        displayName: "Wrap Collections",
        help: "Wrap array/dict: \"before-first\", \"after-first\", \"preserve\"",
        keyPath: \.wrapCollections,
        options: ["before-first", "after-first", "preserve", "disabled"]
    )
    static let closingParen = FormatOptions.Descriptor(
        argumentName: "closingparen",
        propertyName: "closingParenOnSameLine",
        displayName: "Closing Paren Position",
        help: "Closing paren position: \"balanced\" (default) or \"same-line\"",
        keyPath: \.closingParenOnSameLine,
        trueValues: ["same-line"],
        falseValues: ["balanced"]
    )
    static let hexLiteralCase = FormatOptions.Descriptor(
        argumentName: "hexliteralcase",
        propertyName: "uppercaseHex",
        displayName: "Hex Literal Case",
        help: "Casing for hex literals: \"uppercase\" (default) or \"lowercase\"",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    static let exponentCase = FormatOptions.Descriptor(
        argumentName: "exponentcase",
        propertyName: "uppercaseExponent",
        displayName: "Exponent Case",
        help: "Case of 'e' in numbers: \"lowercase\" or \"uppercase\" (default)",
        keyPath: \.uppercaseExponent,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    static let decimalGrouping = FormatOptions.Descriptor(
        argumentName: "decimalgrouping",
        propertyName: "decimalGrouping",
        displayName: "Decimal Grouping",
        help: "Decimal grouping,threshold (default: 3,6) or \"none\", \"ignore\"",
        keyPath: \.decimalGrouping
    )
    static let fractionGrouping = FormatOptions.Descriptor(
        argumentName: "fractiongrouping",
        propertyName: "fractionGrouping",
        displayName: "Fraction Grouping",
        help: "Group digits after '.': \"enabled\" or \"disabled\" (default)",
        keyPath: \.fractionGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let exponentGrouping = FormatOptions.Descriptor(
        argumentName: "exponentgrouping",
        propertyName: "exponentGrouping",
        displayName: "Exponent Grouping",
        help: "Group exponent digits: \"enabled\" or \"disabled\" (default)",
        keyPath: \.exponentGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let binaryGrouping = FormatOptions.Descriptor(
        argumentName: "binarygrouping",
        propertyName: "binaryGrouping",
        displayName: "Binary Grouping",
        help: "Binary grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.binaryGrouping
    )
    static let octalGrouping = FormatOptions.Descriptor(
        argumentName: "octalgrouping",
        propertyName: "octalGrouping",
        displayName: "Octal Grouping",
        help: "Octal grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.octalGrouping
    )
    static let hexGrouping = FormatOptions.Descriptor(
        argumentName: "hexgrouping",
        propertyName: "hexGrouping",
        displayName: "Hex Grouping",
        help: "Hex grouping,threshold (default: 4,8) or \"none\", \"ignore\"",
        keyPath: \.hexGrouping
    )
    static let letPatternPlacement = FormatOptions.Descriptor(
        argumentName: "patternlet",
        propertyName: "hoistPatternLet",
        displayName: "Pattern Let",
        help: "let/var placement in patterns: \"hoist\" (default) or \"inline\"",
        keyPath: \.hoistPatternLet,
        trueValues: ["hoist"],
        falseValues: ["inline"]
    )
    static let stripUnusedArguments = FormatOptions.Descriptor(
        argumentName: "stripunusedargs",
        propertyName: "stripUnusedArguments",
        displayName: "Strip Unused Arguments",
        help: "\"closure-only\", \"unnamed-only\" or \"always\" (default)",
        keyPath: \.stripUnusedArguments,
        options: ["unnamed-only", "closure-only", "always"]
    )
    static let elsePosition = FormatOptions.Descriptor(
        argumentName: "elseposition",
        propertyName: "elseOnNextLine",
        displayName: "Else Position",
        help: "Placement of else/catch: \"same-line\" (default) or \"next-line\"",
        keyPath: \.elseOnNextLine,
        trueValues: ["next-line", "nextline"],
        falseValues: ["same-line", "sameline"]
    )
    static let guardElse = FormatOptions.Descriptor(
        argumentName: "guardelse",
        propertyName: "guardElsePosition",
        displayName: "Guard Else Position",
        help: "Guard else: \"same-line\", \"next-line\" or \"auto\" (default)",
        keyPath: \.guardElsePosition
    )
    static let explicitSelf = FormatOptions.Descriptor(
        argumentName: "self",
        propertyName: "explicitSelf",
        displayName: "Self",
        help: "Explicit self: \"insert\", \"remove\" (default) or \"init-only\"",
        keyPath: \.explicitSelf,
        options: ["insert", "remove", "init-only"]
    )
    static let selfRequired = FormatOptions.Descriptor(
        argumentName: "selfrequired",
        propertyName: "selfRequired",
        displayName: "Self Required",
        help: "Comma-delimited list of functions with @autoclosure arguments",
        keyPath: \FormatOptions.selfRequired
    )
    static let importGrouping = FormatOptions.Descriptor(
        argumentName: "importgrouping",
        propertyName: "importGrouping",
        displayName: "Import Grouping",
        help: "\"testable-top\", \"testable-bottom\" or \"alphabetized\" (default)",
        keyPath: \FormatOptions.importGrouping,
        options: ["alphabetized", "testable-top", "testable-bottom"]
    )
    static let trailingClosures = FormatOptions.Descriptor(
        argumentName: "trailingclosures",
        propertyName: "trailingClosures",
        displayName: "Trailing Closure Functions",
        help: "Comma-delimited list of functions that use trailing closures",
        keyPath: \FormatOptions.trailingClosures
    )
    static let xcodeIndentation = FormatOptions.Descriptor(
        argumentName: "xcodeindentation",
        propertyName: "xcodeIndentation",
        displayName: "Xcode Indentation",
        help: "Xcode indent guard/enum: \"enabled\" or \"disabled\" (default)",
        keyPath: \.xcodeIndentation,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let tabWidth = FormatOptions.Descriptor(
        argumentName: "tabwidth",
        propertyName: "tabWidth",
        displayName: "Tab Width",
        help: "The width of a tab character. Defaults to \"unspecified\"",
        keyPath: \.tabWidth,
        fromArgument: { $0.lowercased() == "unspecified" ? 0 : Int($0).map { max(0, $0) } },
        toArgument: { $0 > 0 ? String($0) : "unspecified" }
    )
    static let maxWidth = FormatOptions.Descriptor(
        argumentName: "maxwidth",
        propertyName: "maxWidth",
        displayName: "Max Width",
        help: "Maximum length of a line before wrapping. defaults to \"none\"",
        keyPath: \.maxWidth,
        fromArgument: { $0.lowercased() == "none" ? 0 : Int($0).map { max(0, $0) } },
        toArgument: { $0 > 0 ? String($0) : "none" }
    )
    static let smartTabs = FormatOptions.Descriptor(
        argumentName: "smarttabs",
        propertyName: "smartTabs",
        displayName: "Smart Tabs",
        help: "Align code independently of tab width. defaults to \"enabled\"",
        keyPath: \.smartTabs,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let noSpaceOperators = FormatOptions.Descriptor(
        argumentName: "nospaceoperators",
        propertyName: "noSpaceOperators",
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
    static let noWrapOperators = FormatOptions.Descriptor(
        argumentName: "nowrapoperators",
        propertyName: "noWrapOperators",
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
    static let modifierOrder = FormatOptions.Descriptor(
        argumentName: "modifierorder",
        propertyName: "modifierOrder",
        displayName: "Modifier Order",
        help: "Comma-delimited list of modifiers in preferred order",
        keyPath: \FormatOptions.modifierOrder,
        validate: {
            guard _FormatRules.allModifiers.contains($0) else {
                throw FormatError.options("'\($0)' is not a valid modifier")
            }
        }
    )
    static let shortOptionals = FormatOptions.Descriptor(
        argumentName: "shortoptionals",
        propertyName: "shortOptionals",
        displayName: "Short Optional Syntax",
        help: "Use ? for Optionals \"always\" (default) or \"except-properties\"",
        keyPath: \.shortOptionals,
        options: ["always", "except-properties"]
    )

    // MARK: - Internal

    static let fragment = FormatOptions.Descriptor(
        argumentName: "fragment",
        propertyName: "fragment",
        displayName: "Fragment",
        help: "Input is part of a larger file: \"true\" or \"false\" (default)",
        keyPath: \.fragment,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    static let ignoreConflictMarkers = FormatOptions.Descriptor(
        argumentName: "conflictmarkers",
        propertyName: "ignoreConflictMarkers",
        displayName: "Conflict Markers",
        help: "Merge-conflict markers: \"reject\" (default) or \"ignore\"",
        keyPath: \.ignoreConflictMarkers,
        trueValues: ["ignore", "true", "enabled"],
        falseValues: ["reject", "false", "disabled"]
    )
    static let swiftVersion = FormatOptions.Descriptor(
        argumentName: "swiftversion",
        propertyName: "swiftVersion",
        displayName: "Swift Version",
        help: "The version of Swift used in the files being formatted",
        keyPath: \.swiftVersion
    )
    static let funcAttributes = FormatOptions.Descriptor(
        argumentName: "funcattributes",
        propertyName: "funcAttributes",
        displayName: "Function Attributes",
        help: "Function @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.funcAttributes
    )
    static let typeAttributes = FormatOptions.Descriptor(
        argumentName: "typeattributes",
        propertyName: "typeAttributes",
        displayName: "Type Attributes",
        help: "Type @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.typeAttributes
    )
    static let varAttributes = FormatOptions.Descriptor(
        argumentName: "varattributes",
        propertyName: "varAttributes",
        displayName: "Var Attributes",
        help: "Property @attributes: \"preserve\", \"prev-line\", or \"same-line\"",
        keyPath: \.varAttributes
    )
    static let yodaSwap = FormatOptions.Descriptor(
        argumentName: "yodaswap",
        propertyName: "yodaSwap",
        displayName: "Yoda Swap",
        help: "Swap yoda values: \"always\" (default) or \"literals-only\"",
        keyPath: \.yodaSwap
    )

    // MARK: - DEPRECATED

    static let deprecatedMessage = [
        empty.argumentName: "--empty option is deprecated. Use --voidtype instead.",
        indentComments.argumentName: "--comments option is deprecated. Relative indent within multiline comments is now preserved by default.",
        insertBlankLines.argumentName: "--insertlines option is deprecated. Use '--enable blankLinesBetweenScopes' or '--enable blankLinesAroundMark' or '--disable blankLinesBetweenScopes' or '--disable blankLinesAroundMark' instead.",
        removeBlankLines.argumentName: "--removelines option is deprecated. Use '--enable blankLinesAtStartOfScope' or '--enable blankLinesAtEndOfScope' or '--disable blankLinesAtStartOfScope' or '--disable blankLinesAtEndOfScope' instead.",
        hexLiterals.argumentName: "--hexliterals option is deprecated. Use --hexliteralcase instead.",
        wrapElements.argumentName: "--wrapelements option is deprecated. Use --wrapcollections instead.",
        experimentalRules.argumentName: "--experimentalRules option is deprecated. Use --enable to opt-in to rules individually.",
        spaceAroundRangeOperators.argumentName: "--ranges option is deprecated. Use --nospaceoperators instead.",
        specifierOrder.argumentName: "--specifierorder option is deprecated. Use --modifierorder instead.",
    ]

    static let empty = FormatOptions.Descriptor(
        argumentName: "empty",
        propertyName: "empty",
        displayName: "Empty",
        help: "deprecated",
        keyPath: \.useVoid,
        trueValues: ["void"],
        falseValues: ["tuple", "tuples"]
    )
    static let indentComments = FormatOptions.Descriptor(
        argumentName: "comments",
        propertyName: "indentComments",
        displayName: "Comments",
        help: "Indenting of comment bodies: \"indent\" (default) or \"ignore\"",
        keyPath: \.indentComments,
        trueValues: ["indent", "indented"],
        falseValues: ["ignore"]
    )
    static let insertBlankLines = FormatOptions.Descriptor(
        argumentName: "insertlines",
        propertyName: "insertBlankLines",
        displayName: "Insert Lines",
        help: "deprecated",
        keyPath: \.insertBlankLines,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let removeBlankLines = FormatOptions.Descriptor(
        argumentName: "removelines",
        propertyName: "removeBlankLines",
        displayName: "Remove Lines",
        help: "deprecated",
        keyPath: \.removeBlankLines,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let hexLiterals = FormatOptions.Descriptor(
        argumentName: "hexliterals",
        propertyName: "uppercaseHex",
        displayName: "hexliterals",
        help: "deprecated",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    static let wrapElements = FormatOptions.Descriptor(
        argumentName: "wrapelements",
        propertyName: "wrapCollections",
        displayName: "Wrap Elements",
        help: "deprecated",
        keyPath: \.wrapCollections,
        options: ["before-first", "after-first", "preserve", "disabled"]
    )
    static let experimentalRules = FormatOptions.Descriptor(
        argumentName: "experimental",
        propertyName: "experimentalRules",
        displayName: "Experimental Rules",
        help: "Experimental rules: \"enabled\" or \"disabled\" (default)",
        keyPath: \.experimentalRules,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let spaceAroundRangeOperators = FormatOptions.Descriptor(
        argumentName: "ranges",
        propertyName: "spaceAroundRangeOperators",
        displayName: "Ranges",
        help: "Spacing for ranges: \"spaced\" (default) or \"no-space\"",
        keyPath: \.spaceAroundRangeOperators,
        trueValues: ["spaced", "space", "spaces"],
        falseValues: ["no-space", "nospace"]
    )
    static let specifierOrder = FormatOptions.Descriptor(
        argumentName: "specifierorder",
        propertyName: "modifierOrder",
        displayName: "Specifier Order",
        help: "deprecated",
        keyPath: \FormatOptions.modifierOrder,
        validate: {
            guard _FormatRules.allModifiers.contains($0) else {
                throw FormatError.options("'\($0)' is not a valid specifier")
            }
        }
    )
}
