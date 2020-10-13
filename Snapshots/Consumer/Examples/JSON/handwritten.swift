//
//  handwritten.swift
//  Consumer
//
//  Created by Nick Lockwood on 05/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

/// Hand-written JSON parser
public func parseJSON2(_ input: String) throws -> Any {
    let input = input.unicodeScalars
    var index = input.startIndex
    var offset = 0

    var bestIndex = input.startIndex
    var expected: String?

    struct Error: Swift.Error, CustomStringConvertible {
        var string: String
        var description: String { return string }
    }

    func readChar(where fn: (UnicodeScalar) -> Bool = { _ in true }) -> Character? {
        if index < input.endIndex, fn(input[index]) {
            offset += 1
            defer { index = input.index(after: index) }
            return Character(input[index])
        }
        return nil
    }

    func readChar(from: UnicodeScalar, to: UnicodeScalar) -> Character? {
        return readChar { (from.value ... to.value).contains($0.value) }
    }

    func readChar(_ c: UnicodeScalar) -> Character? {
        return readChar { $0 == c }
    }

    func readString(_ string: String) -> Bool {
        let scalars = string.unicodeScalars
        var newOffset = offset
        var newIndex = index
        for c in scalars {
            guard newIndex < input.endIndex, input[newIndex] == c else {
                return false
            }
            newOffset += 1
            newIndex = input.index(after: newIndex)
        }
        index = newIndex
        offset = newOffset
        return true
    }

    func skipWhitespace() {
        while readChar(where: { " \t\n\r".unicodeScalars.contains($0) }) != nil {}
    }

    func boolean() -> Any? {
        if readString("true") {
            return true
        }
        if readString("false") {
            return false
        }
        return nil
    }

    func null() -> Any? {
        return readString("null") ? (Any?.none as Any) : nil
    }

    func number() throws -> Any? {
        var number = ""
        if readChar("-") != nil {
            number.append("-")
        }
        if readChar("0") != nil {
            number.append("0")
        } else if let c = readChar(from: "1", to: "9") {
            number.append(c)
            while let c = readChar(from: "0", to: "9") {
                number.append(c)
            }
        } else {
            if !number.isEmpty, index > bestIndex {
                bestIndex = index
                expected = "0 – 9"
            }
            return nil
        }
        if readChar(".") != nil {
            number.append(".")
            while let c = readChar(from: "0", to: "9") {
                number.append(c)
            }
        }
        if let c = readChar("e") ?? readChar("E") {
            number.append(c)
            if let c = readChar("+") ?? readChar("-") {
                number.append(c)
            }
            guard let c = readChar(from: "0", to: "9") else {
                if index > bestIndex {
                    bestIndex = index
                    expected = "'0' – '9'"
                }
                return nil
            }
            number.append(c)
            while let c = readChar(from: "0", to: "9") {
                number.append(c)
            }
        }
        guard let double = Double(number) else {
            throw Error(string: "\(number) is not a valid number")
        }
        return double
    }

    func readHex() -> String? {
        return (readChar(from: "0", to: "9") ??
            readChar(from: "A", to: "F") ??
            readChar(from: "a", to: "f")).map(String.init)
    }

    func string() throws -> String? {
        let start = index
        guard readChar("\"") != nil else { return nil }
        var string = ""
        while let char = readChar(where: { $0 != "\"" }) {
            if char == "\\" {
                guard let char = readChar() else {
                    throw Error(string: "Expected '\"' at \(offset)")
                }
                switch char {
                case "\"": string.append("\"")
                case "\\": string.append("\\")
                case "/": string.append("/")
                case "b": string.append("\u{8}")
                case "f": string.append("\u{C}")
                case "n": string.append("\n")
                case "r": string.append("\r")
                case "t": string.append("\t")
                case "u":
                    guard let a = readHex(), let b = readHex(),
                          let c = readHex(), let d = readHex()
                    else {
                        if index > bestIndex {
                            bestIndex = index
                            expected = "'0' – '9', 'A' - 'Z' or 'a' - 'z'"
                        }
                        return nil
                    }
                    let value = a + b + c + d
                    guard let hex = UInt32(value, radix: 16),
                          let char = UnicodeScalar(hex)
                    else {
                        throw Error(string: "Invalid code point \(value)")
                    }
                    string.append(String(char))
                default:
                    throw Error(string: "Unexpected token '\(char)' at \(offset)")
                }
            } else {
                string.append(char)
            }
        }
        guard readChar("\"") != nil else {
            if index > bestIndex {
                bestIndex = index
                expected = "'\\\"'"
            }
            index = start
            return nil
        }
        return string
    }

    func object() throws -> Any? {
        guard readChar("{") != nil else { return nil }
        var values = [(String, Any)]()
        while true {
            skipWhitespace()
            guard let key = try string() else { break }
            skipWhitespace()
            guard readChar(":") != nil else {
                if index > bestIndex {
                    bestIndex = index
                    expected = "':'"
                }
                return nil
            }
            guard let value = try json() else {
                if index > bestIndex {
                    bestIndex = index
                    expected = "json"
                }
                return nil
            }
            values.append((key, value))
            guard readChar(",") != nil else { break }
        }
        guard readChar("}") != nil else {
            if index > bestIndex {
                bestIndex = index
                expected = "'}'"
            }
            return nil
        }
        return Dictionary(values) { $1 }
    }

    func array() throws -> Any? {
        guard readChar("[") != nil else { return nil }
        var values = [Any]()
        while true {
            guard let value = try json() else { break }
            values.append(value)
            guard readChar(",") != nil else { break }
        }
        guard readChar("]") != nil else {
            if index > bestIndex {
                bestIndex = index
                expected = "']'"
            }
            return nil
        }
        return values
    }

    func json() throws -> Any? {
        skipWhitespace()
        if let value = try boolean() ?? null() ?? number() {
            skipWhitespace()
            return value
        }
        if let value = try string() ?? object() ?? array() {
            skipWhitespace()
            return value
        }
        expected = "boolean, null, number, string, object or array"
        return nil
    }

    func token() -> String {
        var remaining = input[index...]
        guard let first = remaining.first else { return "" }
        let whitespace = " \t\n\r".unicodeScalars
        var token = ""
        if whitespace.contains(first) {
            token = String(first)
        } else {
            while let char = remaining.popFirst(),
                  !whitespace.contains(char)
            {
                token.append(Character(char))
            }
        }
        return token
    }

    if let match = try json() {
        if index < input.endIndex {
            throw Error(string: "Unexpected token \(token()) at \(offset)")
        }
        return match
    } else if let expected = expected {
        throw Error(string: "Unexpected token \(token()) at \(offset) (expected \(expected))")
    } else {
        throw Error(string: "Unexpected token \(token()) at \(offset)")
    }
}
