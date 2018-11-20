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
            case binary(true: [String], false: [String]) // index 0 should be the official value, while others are tolerable values
            case list([String])
            case text
        }

        let argumentName: String // command-line argument; must not change
        let propertyName: String // internal property; ok to change this
        let displayName: String
        let toOptions: (String, inout FormatOptions) throws -> Void
        let fromOptions: (FormatOptions) -> String
        private(set) var type: ArgumentType

        var deprecationMessage: String? {
            return FormatOptions.Descriptor.deprecatedMessage[argumentName]
        }

        var isDeprecated: Bool {
            return deprecationMessage != nil
        }

        var defaultArgument: String {
            return fromOptions(FormatOptions.default)
        }

        func validateArgument(_ arg: String) -> Bool {
            var options = FormatOptions.default
            return (try? toOptions(arg, &options)) != nil
        }

        init(argumentName: String,
             propertyName: String,
             displayName: String,
             keyPath: WritableKeyPath<FormatOptions, Bool>,
             trueValues: [String],
             falseValues: [String]) {
            self.argumentName = argumentName
            self.propertyName = propertyName
            self.displayName = displayName
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

        init(argumentName: String,
             propertyName: String,
             displayName: String,
             keyPath: WritableKeyPath<FormatOptions, String>,
             fromArgument: @escaping (String) -> String?,
             toArgument: @escaping (String) -> String) {
            self.argumentName = argumentName
            self.propertyName = propertyName
            self.displayName = displayName
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
             keyPath: WritableKeyPath<FormatOptions, String>,
             options: DictionaryLiteral<String, String>) {
            let map: [String: String] = Dictionary(options.map { ($0, $1) }, uniquingKeysWith: { $1 })
            let keys = Array(map.keys)
            self.init(argumentName: argumentName,
                      propertyName: propertyName,
                      displayName: displayName,
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
            type = .list(keys)
        }

        init<T: RawRepresentable>(argumentName: String,
                                  propertyName: String,
                                  displayName: String,
                                  keyPath: WritableKeyPath<FormatOptions, T>) where T.RawValue == String {
            self.argumentName = argumentName
            self.propertyName = propertyName
            self.displayName = displayName
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
                                  keyPath: WritableKeyPath<FormatOptions, T>,
                                  options: [String]) where T.RawValue == String {
            self.init(
                argumentName: argumentName,
                propertyName: propertyName,
                displayName: displayName,
                keyPath: keyPath
            )
            type = .list(options)
        }
    }
}

extension FormatOptions.Descriptor {
    static let formatting: [FormatOptions.Descriptor] = [
        indentation,
        lineBreak,
        allowInlineSemicolons,
        spaceAroundRangeOperators,
        spaceAroundOperatorDeclarations,
        useVoid,
        indentCase,
        trailingCommas,
        indentComments,
        truncateBlankLines,
        allmanBraces,
        fileHeader,
        ifdefIndent,
        wrapArguments,
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
        removeSelf,
        importGrouping,

        // Deprecated
        insertBlankLines,
        removeBlankLines,

        // Renamed
        hexLiterals,
        wrapElements,
    ]

    static let `internal`: [FormatOptions.Descriptor] = [
        experimentalRules,
        fragment,
        ignoreConflictMarkers,
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
        keyPath: \.indent,
        fromArgument: { arg in
            switch arg.lowercased() {
            case "tab", "tabs", "tabbed":
                return "\t"
            default:
                if let spaces = Int(arg.trimmingCharacters(in: .whitespaces)) {
                    return String(repeating: " ", count: spaces)
                }
                return nil
            }
        },
        toArgument: { option in
            if option == "\t" {
                return "tabs"
            }
            return String(option.count)
        }
    )
    static let lineBreak = FormatOptions.Descriptor(
        argumentName: "linebreaks",
        propertyName: "linebreak",
        displayName: "Linebreak Character",
        keyPath: \.linebreak,
        options: ["cr": "\r", "lf": "\n", "crlf": "\r\n"]
    )
    static let allowInlineSemicolons = FormatOptions.Descriptor(
        argumentName: "semicolons",
        propertyName: "allowInlineSemicolons",
        displayName: "Semicolons",
        keyPath: \.allowInlineSemicolons,
        trueValues: ["inline"],
        falseValues: ["never", "false"]
    )
    static let spaceAroundRangeOperators = FormatOptions.Descriptor(
        argumentName: "ranges",
        propertyName: "spaceAroundRangeOperators",
        displayName: "Ranges",
        keyPath: \.spaceAroundRangeOperators,
        trueValues: ["spaced", "space", "spaces"],
        falseValues: ["nospace"]
    )
    static let spaceAroundOperatorDeclarations = FormatOptions.Descriptor(
        argumentName: "operatorfunc",
        propertyName: "spaceAroundOperatorDeclarations",
        displayName: "Operator Functions",
        keyPath: \.spaceAroundOperatorDeclarations,
        trueValues: ["spaced", "space", "spaces"],
        falseValues: ["nospace"]
    )
    static let useVoid = FormatOptions.Descriptor(
        argumentName: "empty",
        propertyName: "useVoid",
        displayName: "Empty",
        keyPath: \.useVoid,
        trueValues: ["void"],
        falseValues: ["tuple", "tuples"]
    )
    static let indentCase = FormatOptions.Descriptor(
        argumentName: "indentcase",
        propertyName: "indentCase",
        displayName: "Indent Case",
        keyPath: \.indentCase,
        trueValues: ["true"],
        falseValues: ["false"]
    )
    static let trailingCommas = FormatOptions.Descriptor(
        argumentName: "commas",
        propertyName: "trailingCommas",
        displayName: "Commas",
        keyPath: \.trailingCommas,
        trueValues: ["always", "true"],
        falseValues: ["inline", "false"]
    )
    static let indentComments = FormatOptions.Descriptor(
        argumentName: "comments",
        propertyName: "indentComments",
        displayName: "Comments",
        keyPath: \.indentComments,
        trueValues: ["indent", "indented"],
        falseValues: ["ignore"]
    )
    static let truncateBlankLines = FormatOptions.Descriptor(
        argumentName: "trimwhitespace",
        propertyName: "truncateBlankLines",
        displayName: "Trim White Space",
        keyPath: \.truncateBlankLines,
        trueValues: ["always"],
        falseValues: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank",
                      "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"]
    )
    static let allmanBraces = FormatOptions.Descriptor(
        argumentName: "allman",
        propertyName: "allmanBraces",
        displayName: "Allman Braces",
        keyPath: \.allmanBraces,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    static let fileHeader = FormatOptions.Descriptor(
        argumentName: "header",
        propertyName: "fileHeader",
        displayName: "Header",
        keyPath: \.fileHeader
    )
    static let ifdefIndent = FormatOptions.Descriptor(
        argumentName: "ifdef",
        propertyName: "ifdefIndent",
        displayName: "Ifdef Indent",
        keyPath: \.ifdefIndent,
        options: ["indent", "noindent", "outdent"]
    )
    static let wrapArguments = FormatOptions.Descriptor(
        argumentName: "wraparguments",
        propertyName: "wrapArguments",
        displayName: "Wrap Arguments",
        keyPath: \.wrapArguments,
        options: ["beforefirst", "afterfirst", "preserve", "disabled"]
    )
    static let wrapCollections = FormatOptions.Descriptor(
        argumentName: "wrapcollections",
        propertyName: "wrapCollections",
        displayName: "Wrap Collections",
        keyPath: \.wrapCollections,
        options: ["beforefirst", "afterfirst", "preserve", "disabled"]
    )
    static let closingParen = FormatOptions.Descriptor(
        argumentName: "closingparen",
        propertyName: "closingParenOnSameLine",
        displayName: "Closing Paren Position",
        keyPath: \.closingParenOnSameLine,
        trueValues: ["same-line"],
        falseValues: ["balanced"]
    )
    static let hexLiteralCase = FormatOptions.Descriptor(
        argumentName: "hexliteralcase",
        propertyName: "uppercaseHex",
        displayName: "Hex Literal Case",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    static let exponentCase = FormatOptions.Descriptor(
        argumentName: "exponentcase",
        propertyName: "uppercaseExponent",
        displayName: "Exponent Case",
        keyPath: \.uppercaseExponent,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    static let decimalGrouping = FormatOptions.Descriptor(
        argumentName: "decimalgrouping",
        propertyName: "decimalGrouping",
        displayName: "Decimal Grouping",
        keyPath: \.decimalGrouping
    )
    static let fractionGrouping = FormatOptions.Descriptor(
        argumentName: "fractiongrouping",
        propertyName: "fractionGrouping",
        displayName: "Fraction Grouping",
        keyPath: \.fractionGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let exponentGrouping = FormatOptions.Descriptor(
        argumentName: "exponentgrouping",
        propertyName: "exponentGrouping",
        displayName: "Exponent Grouping",
        keyPath: \.exponentGrouping,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let binaryGrouping = FormatOptions.Descriptor(
        argumentName: "binarygrouping",
        propertyName: "binaryGrouping",
        displayName: "Binary Grouping",
        keyPath: \.binaryGrouping
    )
    static let octalGrouping = FormatOptions.Descriptor(
        argumentName: "octalgrouping",
        propertyName: "octalGrouping",
        displayName: "Octal Grouping",
        keyPath: \.octalGrouping
    )
    static let hexGrouping = FormatOptions.Descriptor(
        argumentName: "hexgrouping",
        propertyName: "hexGrouping",
        displayName: "Hex Grouping",
        keyPath: \.hexGrouping
    )
    static let letPatternPlacement = FormatOptions.Descriptor(
        argumentName: "patternlet",
        propertyName: "hoistPatternLet",
        displayName: "Pattern Let",
        keyPath: \.hoistPatternLet,
        trueValues: ["hoist"],
        falseValues: ["inline"]
    )
    static let stripUnusedArguments = FormatOptions.Descriptor(
        argumentName: "stripunusedargs",
        propertyName: "stripUnusedArguments",
        displayName: "Strip Unused Arguments",
        keyPath: \.stripUnusedArguments,
        options: ["unnamed-only", "closure-only", "always"]
    )
    static let elsePosition = FormatOptions.Descriptor(
        argumentName: "elseposition",
        propertyName: "elseOnNextLine",
        displayName: "Else Position",
        keyPath: \.elseOnNextLine,
        trueValues: ["next-line", "nextline"],
        falseValues: ["same-line", "sameline"]
    )
    static let removeSelf = FormatOptions.Descriptor(
        argumentName: "self",
        propertyName: "removeSelf",
        displayName: "Self",
        keyPath: \.removeSelf,
        trueValues: ["remove"],
        falseValues: ["insert"]
    )

    static let importGrouping = FormatOptions.Descriptor(
        argumentName: "importgrouping",
        propertyName: "importGrouping",
        displayName: "Import Grouping",
        keyPath: \FormatOptions.importGrouping,
        options: ["alphabetized", "testable-top", "testable-bottom"]
    )

    // MARK: - Internal

    static let experimentalRules = FormatOptions.Descriptor(
        argumentName: "experimental",
        propertyName: "experimentalRules",
        displayName: "Experimental Rules",
        keyPath: \.experimentalRules,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let fragment = FormatOptions.Descriptor(
        argumentName: "fragment",
        propertyName: "fragment",
        displayName: "Fragment",
        keyPath: \.fragment,
        trueValues: ["true", "enabled"],
        falseValues: ["false", "disabled"]
    )
    static let ignoreConflictMarkers = FormatOptions.Descriptor(
        argumentName: "conflictmarkers",
        propertyName: "ignoreConflictMarkers",
        displayName: "Conflict Markers",
        keyPath: \.ignoreConflictMarkers,
        trueValues: ["ignore", "true", "enabled"],
        falseValues: ["reject", "false", "disabled"]
    )

    // MARK: - DEPRECATED

    static let deprecatedMessage = [
        insertBlankLines.argumentName: "`--insertlines` option is deprecated. Use `--enable blankLinesBetweenScopes` or `--enable blankLinesAroundMark` or `--disable blankLinesBetweenScopes` or `--disable blankLinesAroundMark` instead.",
        removeBlankLines.argumentName: "`--removelines` option is deprecated. Use `--enable blankLinesAtStartOfScope` or `--enable blankLinesAtEndOfScope` or `--disable blankLinesAtStartOfScope` or `--disable blankLinesAtEndOfScope` instead",
        hexLiterals.argumentName: "`--hexliterals` option is deprecated. Use `--hexliteralcase` instead",
        wrapElements.argumentName: "`--wrapelements` option is deprecated. Use `--wrapcollections` instead",
    ]

    static let insertBlankLines = FormatOptions.Descriptor(
        argumentName: "insertlines",
        propertyName: "insertBlankLines",
        displayName: "Insert Lines",
        keyPath: \.insertBlankLines,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let removeBlankLines = FormatOptions.Descriptor(
        argumentName: "removelines",
        propertyName: "removeBlankLines",
        displayName: "Remove Lines",
        keyPath: \.removeBlankLines,
        trueValues: ["enabled", "true"],
        falseValues: ["disabled", "false"]
    )
    static let hexLiterals = FormatOptions.Descriptor(
        argumentName: "hexliterals",
        propertyName: "uppercaseHex",
        displayName: "hexliterals",
        keyPath: \.uppercaseHex,
        trueValues: ["uppercase", "upper"],
        falseValues: ["lowercase", "lower"]
    )
    static let wrapElements = FormatOptions.Descriptor(
        argumentName: "wrapelements",
        propertyName: "wrapCollections",
        displayName: "Wrap Elements",
        keyPath: \.wrapCollections,
        options: ["beforefirst", "afterfirst", "preserve", "disabled"]
    )
}
