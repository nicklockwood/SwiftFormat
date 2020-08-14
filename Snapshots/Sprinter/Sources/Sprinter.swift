//
//  Sprinter.swift
//  Sprinter
//
//  Version 0.2.1
//
//  Created by Nick Lockwood on 20/11/2017.
//  Copyright © 2017 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Sprinter
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

/// An opaque type used to wrap a parsed format string
/// Can be used to efficiently perform operations such as formatting and validation
public struct FormatString {
    enum Flag: Unicode.Scalar {
        case groupThousands = "'"
        case leftJustified = "-"
        case alwaysShowSign = "+"
        case padToSignedWidth = " "
        case alternativeForm = "#"
        case leadingZeros = "0"

        fileprivate init?(_ input: inout String.UnicodeScalarView.SubSequence) {
            guard let flag = input.first.flatMap({ Flag(rawValue: $0) }) else {
                return nil
            }
            input.removeFirst()
            self = flag
        }
    }

    enum FieldWidth: CustomStringConvertible {
        case parameter(UInt)
        case constant(UInt)

        var index: UInt? {
            switch self {
            case let .parameter(index): return index
            case .constant: return nil
            }
        }

        var description: String {
            switch self {
            case .parameter:
                return "*"
            case let .constant(width):
                return "\(width)"
            }
        }

        fileprivate init?(_ input: inout String.UnicodeScalarView.SubSequence, _ index: inout UInt) throws {
            if input.readCharacter("*") {
                if let index = try input.readPositiveInt() {
                    guard input.readCharacter("$") else {
                        if let first = input.first {
                            throw FormatString.Error.unexpectedToken(Character(first))
                        }
                        throw FormatString.Error.unexpectedEndOfString
                    }
                    self = .parameter(index)
                    return
                }
                self = .parameter(index)
                index += 1
                return
            }
            if let index = try input.readUInt() {
                self = .constant(index)
                return
            }
            return nil
        }
    }

    enum LengthModifier: String {
        case char = "hh"
        case short = "h"
        case long = "l"
        case longLong = "ll"
        case intmax = "j"
        case size = "z"
        case ptrdiff = "t"
        case longDouble = "L"
        // Apple-specific
        case quadword = "q" // equivalent to ll

        fileprivate init?(_ input: inout String.UnicodeScalarView.SubSequence) {
            guard let first = input.first else {
                return nil
            }
            switch first {
            case "h":
                input.removeFirst()
                if input.readCharacter("h") {
                    self = .char
                    return
                }
                self = .short
            case "l":
                input.removeFirst()
                if input.readCharacter("l") {
                    self = .longLong
                    return
                }
                self = .long
            default:
                if let modifier = LengthModifier(rawValue: String(Character(first))) {
                    input.removeFirst()
                    self = modifier
                    return
                }
                return nil
            }
        }
    }

    enum ConversionSpecifier: Unicode.Scalar {
        case decimal = "d"
        case int = "i" // equivalent to d
        case octal = "o"
        case unsigned = "u"
        case hex = "x"
        case uppercaseHex = "X"
        case float = "f"
        case uppercaseFloat = "F" // equivalent to f
        case exponential = "e"
        case uppercaseExponential = "E"
        case variablePrecisionFloat = "g"
        case uppercasevariablePrecisionFloat = "G"
        case hexFloat = "a"
        case uppercaseHexFloat = "A"
        case char = "c"
        case string = "s"
        case pointer = "p"
        case bytesWritten = "n"
        case wideChar = "C" // equivalent to lc
        case wideString = "S" // equivalent to ls
        case percentChar = "%"
        // Apple-specific
        case uppercaseDecimal = "D" // equivalent to d
        case uppercaseOctal = "O" // equivalent to o
        case uppercaseUnsigned = "U" // equivalent to u
        case object = "@"

        fileprivate init(_ input: inout String.UnicodeScalarView.SubSequence) throws {
            guard let first = input.first else {
                throw Error.unexpectedEndOfString
            }
            guard let specifier = ConversionSpecifier(rawValue: first) else {
                throw Error.unexpectedToken(Character(first))
            }
            input.removeFirst()
            self = specifier
        }
    }

    struct Placeholder {
        private(set) var index: UInt = 0
        private(set) var flags = [Flag]()
        private(set) var fieldWidth: FieldWidth?
        private(set) var precision: FieldWidth?
        private(set) var modifier: LengthModifier?
        let specifier: ConversionSpecifier

        private var formatter: NumberFormatter?
        private var formatString = ""

        func getSwiftType() throws -> Any.Type? {
            switch specifier {
            case .decimal,
                 .uppercaseDecimal,
                 .int,
                 .octal,
                 .uppercaseOctal,
                 .hex,
                 .uppercaseHex:
                guard let modifier = modifier else { return Int.self } // spec says Int32
                switch modifier {
                case .char: return CChar.self
                case .short: return CShort.self
                case .long: return CLong.self
                case .longLong,
                     .quadword: return CLongLong.self
                case .intmax: return intmax_t.self
                case .size: return size_t.self
                case .ptrdiff: return ptrdiff_t.self
                case .longDouble: throw Error.modifierMismatch(modifier.rawValue, Character(specifier.rawValue))
                }
            case .unsigned,
                 .uppercaseUnsigned:
                guard let modifier = modifier else { return UInt.self } // spec says UInt32
                switch modifier {
                case .char: return CUnsignedChar.self
                case .short: return CUnsignedShort.self
                case .long: return CUnsignedLong.self
                case .longLong,
                     .quadword: return CUnsignedLongLong.self
                case .intmax: return uintmax_t.self
                case .size: return UInt.self
                case .ptrdiff: return UInt.self
                case .longDouble: throw Error.modifierMismatch(modifier.rawValue, Character(specifier.rawValue))
                }
            case .float,
                 .uppercaseFloat,
                 .variablePrecisionFloat,
                 .uppercasevariablePrecisionFloat,
                 .exponential,
                 .uppercaseExponential,
                 .hexFloat,
                 .uppercaseHexFloat:
                guard let modifier = modifier else { return Double.self }
                switch modifier {
                case .longDouble:
                    #if os(macOS)
                    return Float80.self
                    #else
                    return Double.self
                    #endif
                default: throw Error.modifierMismatch(modifier.rawValue, Character(specifier.rawValue))
                }
            case .char:
                guard let modifier = modifier else { return Character.self } // spec says CChar
                switch modifier {
                case .long: return Character.self // IEEE says wint_t, Apple says unichar
                default: throw Error.modifierMismatch(modifier.rawValue, Character(specifier.rawValue))
                }
            case .wideChar:
                try modifier.map { throw Error.modifierMismatch($0.rawValue, Character(specifier.rawValue)) }
                return Character.self // IEEE says wint_t, Apple says unichar
            case .string:
                guard let modifier = modifier else { return String.self } // spec says UnsafePointer<CChar>
                switch modifier {
                case .long: return String.self // IEEE says wchar_t*, Apple says Unichar*
                default: throw Error.modifierMismatch(modifier.rawValue, Character(specifier.rawValue))
                }
            case .wideString:
                try modifier.map { throw Error.modifierMismatch($0.rawValue, Character(specifier.rawValue)) }
                return String.self // IEEE says wchar_t*, Apple says Unichar*
            case .pointer:
                try modifier.map { throw Error.modifierMismatch($0.rawValue, Character(specifier.rawValue)) }
                return AnyObject.self
            case .bytesWritten:
                throw Error.unsupportedSpecifier(Character(specifier.rawValue))
            case .percentChar:
                return nil
            case .object:
                try modifier.map { throw Error.modifierMismatch($0.rawValue, Character(specifier.rawValue)) }
                return Any.self
            }
        }

        func buildFormatString() -> String {
            var format = "%"
            format += flags.map { "\($0.rawValue)" }.joined()
            fieldWidth.map { format += "\($0)" }
            precision.map { format += ".\($0)" }
            if let modifier = modifier {
                format += "\(modifier.rawValue)\(specifier.rawValue)"
            } else {
                switch specifier {
                case .int,
                     .decimal:
                    format += "zd"
                case .uppercaseDecimal:
                    format += "zD"
                case .unsigned:
                    format += "tu"
                case .uppercaseUnsigned:
                    format += "tU"
                case .hex:
                    format += "tx"
                case .uppercaseHex:
                    format += "tX"
                case .octal:
                    format += "to"
                case .uppercaseOctal:
                    format += "tO"
                default:
                    format += "\(specifier.rawValue)"
                }
            }
            return format
        }

        func buildFormatter(fieldWidth w: Int?, precision p: Int?, locale: Locale?) -> NumberFormatter? {
            let fieldWidth: Int?
            if let width = self.fieldWidth {
                switch width {
                case .parameter where w == nil:
                    return nil // Can't build formatter
                case .parameter:
                    fieldWidth = w
                case let .constant(value):
                    fieldWidth = Int(value)
                }
            } else {
                fieldWidth = nil
            }
            let precision: Int?
            if let width = self.precision {
                switch width {
                case .parameter where p == nil:
                    return nil // Can't build formatter
                case .parameter:
                    precision = p
                case let .constant(value):
                    precision = Int(value)
                }
            } else {
                precision = nil
            }
            let formatter: NumberFormatter
            switch specifier {
            case .decimal,
                 .uppercaseDecimal,
                 .int,
                 .unsigned,
                 .uppercaseUnsigned:
                if !flags.contains(.groupThousands) {
                    return nil // Prefer `String(format:)` for performance
                }
                formatter = NumberFormatter()
                formatter.allowsFloats = false
                formatter.minimumIntegerDigits = precision ?? 1
            case .float,
                 .uppercaseFloat:
                if !flags.contains(.groupThousands) {
                    return nil // Prefer `String(format:)` for performance
                }
                formatter = NumberFormatter()
                formatter.minimumIntegerDigits = 1
                formatter.minimumFractionDigits = precision ?? 6
                formatter.maximumFractionDigits = precision ?? 6
                formatter.alwaysShowsDecimalSeparator = flags.contains(.alternativeForm)
            case .variablePrecisionFloat,
                 .uppercasevariablePrecisionFloat:
                if !flags.contains(.groupThousands) {
                    return nil // Prefer `String(format:)` for performance
                }
                formatter = NumberFormatter()
                formatter.minimumIntegerDigits = 1
                formatter.minimumFractionDigits = 0
                if flags.contains(.alternativeForm) {
                    formatter.minimumSignificantDigits = precision ?? 6
                } else {
                    formatter.maximumSignificantDigits = precision ?? 6
                }
            case .octal,
                 .uppercaseOctal,
                 .hex,
                 .uppercaseHex,
                 .exponential,
                 .uppercaseExponential,
                 .hexFloat,
                 .uppercaseHexFloat,
                 .char,
                 .string,
                 .wideChar,
                 .wideString,
                 .pointer,
                 .bytesWritten,
                 .percentChar,
                 .object:
                return nil // Not handled by NumberFormatter
            }
            formatter.locale = locale
            let infinity = String(format: "%\(specifier.rawValue)", locale: locale, Double.infinity)
            formatter.positiveInfinitySymbol = infinity
            formatter.negativeInfinitySymbol = "-\(infinity)"
            formatter.formatWidth = fieldWidth ?? 0
            formatter.numberStyle = .decimal
            if flags.contains(.leftJustified) {
                formatter.paddingPosition = .afterSuffix
            } else if flags.contains(.leadingZeros) {
                formatter.paddingCharacter = formatter.zeroSymbol ?? "0"
            }
            if flags.contains(.alwaysShowSign) {
                formatter.positivePrefix = formatter.plusSign
            } else if flags.contains(.padToSignedWidth) {
                formatter.positivePrefix = " "
            }
            return formatter
        }

        func print(_ value: Any, _ fieldWidth: Int?, _ precision: Int?, locale: Locale?) -> String {
            if let formatter = formatter ?? buildFormatter(
                fieldWidth: fieldWidth,
                precision: precision,
                locale: locale
            ), let number = value as? NSNumber {
                // Seems like this can never be nil, but better to be safe
                return formatter.string(from: number) ?? ""
            }
            switch specifier {
            case .decimal,
                 .uppercaseDecimal,
                 .int,
                 .octal,
                 .uppercaseOctal,
                 .hex,
                 .uppercaseHex,
                 .unsigned,
                 .uppercaseUnsigned:
                let value = Int(truncating: value as! NSNumber)
                if let fieldWidth = fieldWidth, let precision = precision {
                    return String(format: formatString, locale: locale, fieldWidth, precision, value)
                } else if let width = fieldWidth ?? precision {
                    return String(format: formatString, locale: locale, width, value)
                }
                return String(format: formatString, locale: locale, value)
            case .float,
                 .uppercaseFloat,
                 .variablePrecisionFloat,
                 .uppercasevariablePrecisionFloat,
                 .exponential,
                 .uppercaseExponential,
                 .hexFloat,
                 .uppercaseHexFloat:
                #if os(macOS)
                if let value = value as? Float80 {
                    return "\(value)" // TODO: respect formatting options
                }
                #endif
                if let fieldWidth = fieldWidth, let precision = precision {
                    return String(format: formatString, locale: locale, fieldWidth, precision, value as! Double)
                } else if let width = fieldWidth ?? precision {
                    return String(format: formatString, locale: locale, width, value as! Double)
                }
                return String(format: formatString, locale: locale, value as! Double)
            case .pointer:
                return String(format: formatString, locale: locale, (value as AnyObject).hash)
            case .bytesWritten,
                 .percentChar, // Shouldn't actually happen
                 .object,
                 .string,
                 .wideString,
                 .char,
                 .wideChar:
                return "\(value)"
            }
        }

        fileprivate init?(
            _ input: inout String.UnicodeScalarView.SubSequence,
            _ index: inout UInt,
            locale: Locale?
        ) throws {
            guard input.readCharacter("%") else { return nil }
            guard let first = input.first else {
                throw Error.unexpectedEndOfString
            }
            // index, flag, field width, precision
            if let int = try input.readPositiveInt() {
                if input.readCharacter("$") {
                    self.index = int
                    flags = try input.readFlags()
                    fieldWidth = try FieldWidth(&input, &index)
                } else {
                    fieldWidth = .constant(int)
                }
            } else {
                flags = try input.readFlags()
                fieldWidth = try FieldWidth(&input, &index)
            }
            if input.readCharacter(".") {
                precision = try FieldWidth(&input, &index) ?? .constant(0)
            }
            if self.index == 0, first != "%" {
                self.index = index
                index += 1
            }
            // modifier modifier
            modifier = LengthModifier(&input)
            // conversion specifier
            specifier = try ConversionSpecifier(&input)
            if specifier == .percentChar, first != "%" {
                throw Error.modifierMismatch("\(first)", "%")
            }
            // set up formatter
            formatter = buildFormatter(fieldWidth: nil, precision: nil, locale: locale)
            if formatter == nil {
                formatString = buildFormatString()
            }
        }
    }

    enum Token {
        case string(String)
        case placeholder(Placeholder)
    }

    public enum Error: Swift.Error, LocalizedError, CustomStringConvertible, Equatable {
        case unexpectedEndOfString
        case unexpectedToken(Character)
        case duplicateFlag(Character)
        case unsupportedFlag(Character)
        case unsupportedSpecifier(Character)
        case modifierMismatch(String, Character)
        case typeMismatch(Int, Any.Type, Any.Type)
        case argumentMismatch(Int, Any.Type, Any.Type)
        case missingArgument(Int)

        public var errorDescription: String? {
            return description
        }

        public var description: String {
            switch self {
            case .unexpectedEndOfString:
                return "Format string ended unexpectedly"
            case let .unexpectedToken(char):
                return "Unexpected character '\(char)' in format string"
            case let .duplicateFlag(char):
                return "Format string contains duplicate flag '\(char)'"
            case let .unsupportedFlag(char):
                return "Formatting flag '\(char)' is not currently supported"
            case let .unsupportedSpecifier(char):
                return "The format specifier '\(char)' is not currently supported"
            case let .modifierMismatch(modifier, specifier):
                return "Length modifier '\(modifier)' cannot be used with format specifier '\(specifier)'"
            case let .typeMismatch(index, type1, type2):
                return "Type mismatch for placeholders with index #\(index): '\(type1)' vs '\(type2)'"
            case let .argumentMismatch(index, type1, type2):
                return "Type mismatch for argument #\(index): '\(type1)' vs '\(type2)'"
            case let .missingArgument(index):
                return "Missing argument #\(index)"
            }
        }

        public static func == (lhs: Error, rhs: Error) -> Bool {
            switch (lhs, rhs) {
            case (.unexpectedEndOfString, .unexpectedEndOfString):
                return true
            case let (.unexpectedToken(lhs), .unexpectedToken(rhs)),
                 let (.duplicateFlag(lhs), .duplicateFlag(rhs)),
                 let (.unsupportedFlag(lhs), .unsupportedFlag(rhs)),
                 let (.unsupportedSpecifier(lhs), .unsupportedSpecifier(rhs)):
                return lhs == rhs
            case let (.modifierMismatch(lmodifier, lspecifier), .modifierMismatch(rmodifier, rspecifier)):
                return lmodifier == rmodifier && lspecifier == rspecifier
            case let (.typeMismatch(lindex, ltype1, ltype2), .typeMismatch(rindex, rtype1, rtype2)),
                 let (.argumentMismatch(lindex, ltype1, ltype2), .argumentMismatch(rindex, rtype1, rtype2)):
                return lindex == rindex && ltype1 == rtype1 && ltype2 == rtype2
            case let (.missingArgument(lindex), .missingArgument(rindex)):
                return lindex == rindex
            case (.unexpectedEndOfString, _),
                 (.unexpectedToken, _),
                 (.duplicateFlag, _),
                 (.unsupportedFlag, _),
                 (.unsupportedSpecifier, _),
                 (.modifierMismatch, _),
                 (.typeMismatch, _),
                 (.argumentMismatch, _),
                 (.missingArgument, _):
                return false
            }
        }
    }

    // Internal representation
    let locale: Locale?
    let tokens: [Token]

    // Just the placeholder values - useful for testing
    var placeholders: [Placeholder] {
        return tokens.flatMap { (token: Token) -> [Placeholder] in
            if case let .placeholder(placeholder) = token {
                return [placeholder]
            }
            return []
        }
    }

    /// The required argument types for formatting
    public let types: [Any.Type]

    /// Parse the format string, and create a FormatString wrapper if valid
    public init(_ format: String, locale: Locale? = nil) throws {
        var characters = String.UnicodeScalarView.SubSequence(format.unicodeScalars)
        var tokens = [Token]()
        var typesByIndex = [UInt: Any.Type]()
        var index: UInt = 1
        while !characters.isEmpty {
            if let placeholder = try Placeholder(&characters, &index, locale: locale) {
                tokens.append(.placeholder(placeholder))
                guard let type = try placeholder.getSwiftType() else {
                    continue
                }
                if let fieldWidthIndex = placeholder.fieldWidth?.index {
                    typesByIndex[fieldWidthIndex] = Int.self
                }
                if let precisionIndex = placeholder.precision?.index {
                    typesByIndex[precisionIndex] = Int.self
                }
                let typeIndex = placeholder.index
                if let oldType = typesByIndex[typeIndex], oldType != type {
                    throw Error.typeMismatch(Int(typeIndex), oldType, type)
                }
                typesByIndex[typeIndex] = type
            }
            var string = ""
            while let first = characters.first {
                if first == "%" { break }
                characters.removeFirst()
                string.append(Character(first))
            }
            if !string.isEmpty {
                tokens.append(.string(string))
            }
        }
        self.locale = locale
        self.tokens = tokens
        if typesByIndex.isEmpty {
            types = []
        } else {
            var types = [Any.Type]()
            let indexes = typesByIndex.keys.sorted()
            for index in 1 ... indexes.last! {
                types.append(typesByIndex[index] ?? Any.self)
            }
            self.types = types
        }
    }

    /// Print the formatted string with the specified arguments
    public func print(arguments: [Any]) throws -> String {
        return try tokens.map { token -> String in
            switch token {
            case let .string(string):
                return string
            case let .placeholder(placeholder):
                if placeholder.specifier == .percentChar {
                    return "%"
                }
                let value = try argument(at: placeholder.index, in: arguments)
                let fieldWidth = try placeholder.fieldWidth?.index.map {
                    try argument(at: $0, in: arguments)
                } as? Int
                let precision = try placeholder.precision?.index.map {
                    try argument(at: $0, in: arguments)
                } as? Int
                return placeholder.print(value, fieldWidth, precision, locale: locale)
            }
        }.joined()
    }

    /// Variadic form of the print function
    public func print(_ arguments: Any...) throws -> String {
        if arguments.count == 1, let array = arguments.first as? [Any], array.count == types.count {
            // If only argument is an array, and count matches types, treat as argument array
            return try print(arguments: array)
        }
        return try print(arguments: arguments)
    }

    // MARK: private

    private func argument(at index: UInt, in arguments: [Any]) throws -> Any {
        let zeroBasedIndex = Int(index) - 1
        if index > arguments.count {
            throw Error.missingArgument(Int(index))
        }
        let argument = arguments[zeroBasedIndex]
        let expectedType = types[zeroBasedIndex]
        guard let value = cast(argument, as: expectedType) else {
            throw Error.argumentMismatch(Int(index), Swift.type(of: argument), expectedType)
        }
        return value
    }

    private func cast(_ value: Any, as type: Any.Type) -> Any? {
        if type == Swift.type(of: value) {
            return value
        }
        switch (type, value) {
        // Integer promotion
        case (is Int.Type, let value as Int32):
            return Int(value)
        case (is Int.Type, let value as Int16):
            return Int(value)
        case (is Int.Type, let value as UInt16):
            return Int(value)
        case (is Int.Type, let value as Int8):
            return Int(value)
        case (is Int.Type, let value as UInt8):
            return Int(value)
        // Double promotion
        case (is Double.Type, let value as NSNumber):
            return Double(truncating: value)
        // Character promotion
        case (is Character.Type, let value as String):
            return value.first
        case (is Character.Type, let value as Unicode.Scalar):
            return Character(value)
        case (is Character.Type, let value as Int):
            return UnicodeScalar(value).map(Character.init)
        case (is Character.Type, let value as UInt32):
            return UnicodeScalar(value).map(Character.init)
        case (is Character.Type, let value as UInt16):
            return UnicodeScalar(value).map(Character.init)
        case (is Character.Type, let value as UInt8):
            return Character(UnicodeScalar(value))
        case (is Character.Type, let value as Int8):
            return Character(UnicodeScalar(UInt8(value)))
        // String promotion
        case (is String.Type, let value as NSString):
            return value as String
        // Pointer promotion
        case _ where type == AnyObject.self:
            return value as AnyObject
        // Any promotion
        case _ where type == Any.self:
            return value
        default: // Any
            return nil
        }
    }
}

private extension String.UnicodeScalarView.SubSequence {
    mutating func readCharacter(_ character: Unicode.Scalar) -> Bool {
        if first == character {
            removeFirst()
            return true
        }
        return false
    }

    mutating func readCharacter(_ matching: (Unicode.Scalar) -> Bool) -> Unicode.Scalar? {
        if first.map(matching) == true {
            return popFirst()
        }
        return nil
    }

    mutating func readUInt() throws -> UInt? {
        if readCharacter("0") {
            return 0
        }
        return try readPositiveInt()
    }

    mutating func readPositiveInt() throws -> UInt? {
        var intString = ""
        if let digit = readCharacter({ "123456789".unicodeScalars.contains($0) }) {
            intString.append(Character(digit))
            while let digit = readCharacter({ "0123456789".unicodeScalars.contains($0) }) {
                intString.append(Character(digit))
            }
        }
        if intString.isEmpty {
            return nil
        }
        guard let int = UInt(intString) else {
            throw FormatString.Error.unexpectedToken(intString.first!)
        }
        return int
    }

    mutating func readFlags() throws -> [FormatString.Flag] {
        var flags = [FormatString.Flag]()
        while let flag = FormatString.Flag(&self) {
            if flags.contains(flag) {
                throw FormatString.Error.duplicateFlag(Character(flag.rawValue))
            }
            flags.append(flag)
        }
        return flags
    }
}

// Specification references:
// https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
// http://pubs.opengroup.org/onlinepubs/009695399/functions/printf.html
