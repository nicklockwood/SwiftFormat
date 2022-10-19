//
//  Consumer.swift
//  Consumer
//
//  Created by Nick Lockwood on 03/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Consumer
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

// Compiles the consumer into the source code for a Swift function.
// Currently only works if the `Label` type is `String` or `RawRepresentable<String>`

// The optional `functionName` argument specifies a name for the compiled transform function.

// The optional `transformFunction` argument is the name of a function that will be
// called by the parser to transform the generic AST into an app-specific data structure.

// The `transformFunction` should have the same signature as the `Consumer<Label>.Transform` callback.
// If `transformFunction` is omitted, the function will generate a `Consumer<Label>.Match`,
// and the resultant function will require the target application to include the Consumer framework.

public extension Consumer where Label: RawRepresentable, Label.RawValue == String {
    func compile(_ functionName: String = "parse", transformFunction: String? = nil) -> String {
        return _compile(functionName, transformFunction: transformFunction) {
            $0.rawValue
        }
    }
}

public extension Consumer where Label == String {
    func compile(_ functionName: String = "parse", transformFunction: String? = nil) -> String {
        return _compile(functionName, transformFunction: transformFunction, rawValueGetter: nil)
    }
}

private extension Consumer {
    func _compile(_ functionName: String, transformFunction: String?, rawValueGetter: ((Label) -> String)?) -> String {
        var functions = [String: String]()
        var sanitizedNames = [Label: String]()
        var charsetRanges = [Charset: String]()
        var consumersByName = [Label: Consumer]()

        let nilCoalescingLimit = 4

        let isRawRepresentable = (rawValueGetter != nil)
        func _rawValue(for label: Label) -> String {
            return rawValueGetter?(label) ?? "\(label)"
        }

        func _ranges(for charset: Charset) -> String {
            if let ranges = charsetRanges[charset] {
                return ranges
            }
            var ranges: [CountableClosedRange<UInt32>]
            if charset.inverted {
                ranges = []
                var start: UInt32 = 0
                for range in charset.ranges {
                    ranges.append(start ... range.lowerBound - 1)
                    start = range.upperBound + 1
                }
                ranges.append(start ... UInt32.max)
            } else {
                ranges = charset.ranges
            }
            let string = "[" + ranges.map {
                "\($0.lowerBound) ... \($0.upperBound)"
            }.joined(separator: ", ") + "]"
            charsetRanges[charset] = string
            return string
        }

        func _character(for charset: Charset) -> UnicodeScalar? {
            let ranges = _ranges(for: charset)
            if !ranges.contains(","), let range = charset.ranges.first,
               range.lowerBound == range.upperBound
            {
                return UnicodeScalar(range.lowerBound)
            }
            return nil
        }

        func alternateName(_ name: String) -> String {
            var number = ""
            var name = Substring(name)
            while let digit = name.last.map(String.init), Double(digit) != nil {
                number = digit + number
                name.removeLast()
            }
            if let number = Int(number) {
                return name + String(number + 1)
            }
            return name + "2"
        }

        func sanitizedName(_ label: Label) -> String {
            if let name = sanitizedNames[label] {
                return name
            }
            let scalars = _rawValue(for: label).unicodeScalars
            var result = ""
            let identifier = CharacterSet(charactersIn: "a" ... "z")
                .union(CharacterSet(charactersIn: "A" ... "Z"))
                .union(CharacterSet(charactersIn: "0123456789_"))
            for char in scalars where identifier.contains(char) {
                result.append(Character(char))
            }
            if !result.hasPrefix("_") {
                result = "_\(result)"
            }
            if result == "_" {
                result = "_name"
            }
            while sanitizedNames.values.contains(result) || functions[result] != nil {
                result = alternateName(result)
            }
            sanitizedNames[label] = result
            return result
        }

        func declare(_ name: String, _ body: String) -> String {
            if let previous = functions[name] {
                if previous == body {
                    return name
                }
                return declare(alternateName(name), body)
            } else if name == transformFunction {
                return declare(alternateName(name), body)
            }
            functions[name] = body
            return name
        }

        func _compileSkipString() -> String {
            return declare("_skipString", """
            (_ string: String) -> Bool {
                    let scalars = string.unicodeScalars
                    var newIndex = index
                    for c in scalars {
                        guard newIndex < input.endIndex, input[newIndex] == c else {
                            return false
                        }
                        newIndex = input.index(after: newIndex)
                    }
                    index = newIndex
                    return true
                }
            """)
        }

        func _compileSkipCharacter(_ charset: Charset? = nil) -> String {
            if let charset = charset {
                if let char = _character(for: charset) {
                    let name = declare("_skipCharacter", """
                    (_ char: UnicodeScalar) -> Bool {
                            if index >= input.endIndex { return false }
                            if char == input[index] {
                                index = input.index(after: index)
                                return true
                            }
                            return false
                        }
                    """)
                    return "\(name)(\(escapeString(String(char))))"
                }
                let ranges = _ranges(for: charset)
                return declare("_skipCharacter", """
                () -> Bool { return \(_compileSkipCharacter())(\(ranges)) }
                """) + "()"
            }
            return declare("_skipCharacter", """
            (_ ranges: [CountableClosedRange<UInt32>]) -> Bool {
                    if index >= input.endIndex { return false }
                    let value = input[index].value
                    for range in ranges {
                        if range.lowerBound > value { break }
                        if range.upperBound >= value {
                            index = input.index(after: index)
                            return true
                        }
                    }
                    return false
                }
            """)
        }

        func _compileSkipCharacters(_: Charset) -> String {
            return declare("_skipZeroOrMoreCharacters", """
            (_ ranges: [CountableClosedRange<UInt32>]) -> Bool {
                    loop: while index < input.endIndex {
                        let value = input[index].value
                        for range in ranges {
                            if range.lowerBound > value { break }
                            if range.upperBound >= value {
                                index = input.index(after: index)
                                continue loop
                            }
                        }
                        break loop
                    }
                    return true
                }
            """)
        }

        func _compileFlattenCharacter(_ charset: Charset) -> String {
            if let char = _character(for: charset) {
                return declare("_character", """
                () -> String? { return (\(_compileSkipCharacter(charset)) ? \(escapeString(String(char))) : nil) }
                """) + "()"
            } else {
                let name = declare("_character", """
                (_ ranges: [CountableClosedRange<UInt32>]) -> String? {
                        let startIndex = index
                        return \(_compileSkipCharacter())(ranges) ? String(input[startIndex]) : nil
                    }
                """)
                return declare("_character", """
                () -> _Match? { return \(name)(\(_ranges(for: charset))) }
                """) + "()"
            }
        }

        func _compileMatchCharacter(_ charset: Charset) -> String {
            if let char = _character(for: charset) {
                return declare("_character", """
                () -> _Match? { return (\(_compileSkipCharacter(charset)) ? _Match.token(\(escapeString(String(char))), input.index(before: index) ..< index) : nil) }
                """) + "()"

            } else {
                let name = declare("_character", """
                (_ ranges: [CountableClosedRange<UInt32>]) -> _Match? {
                        let startIndex = index
                        return \(_compileSkipCharacter())(ranges) ? .token(String(input[startIndex]), startIndex ..< index) : nil
                    }
                """)
                return declare("_character", """
                () -> _Match? { return \(name)(\(_ranges(for: charset))) }
                """) + "()"
            }
        }

        func _compileLabel(_ name: Label, _ consumer: Consumer) -> String {
            let label = declare("_label", """
            (_ name: String, _ match: _Match?) -> _Match? {
                    return match.map { match in
                        switch match {
                        case let .node(_name, matches):
                            return .node(name, _name == nil ? matches : [match])
                        default:
                            return .node(name, [match])
                        }
                    }
                }
            """)
            return declare(sanitizedName(name), """
            () -> _Match? { return \(label)(\(escapeString(_rawValue(for: name))), \(_compile(consumer))) }
            """)
        }

        func _compileSkipAppend(_ consumer: Consumer) -> String {
            if consumer.isOptional {
                return _compileSkip(consumer)
            }
            let skip = declare("_skipAppend", """
            (_ match: Bool, _ _expected: String) -> Bool {
                    if !match {
                        if index >= bestIndex {
                            bestIndex = index
                            expected = _expected
                        }
                        return false
                    }
                    return true
                }
            """)
            return declare("_skipAppend", """
            () -> Bool { return \(skip)(\(_compileSkip(consumer)), \(escapeString(consumer.description))) }
            """) + "()"
        }

        func _compileSkipNot(_ consumer: Consumer) -> String {
            return declare("_not", """
            () -> Bool {
                    let startIndex = index
                    if \(_compileSkip(consumer)) {
                        index = startIndex
                        return false
                    }
                    return true
                }
            """) + "()"
        }

        func _compileSkip(_ consumer: Consumer) -> String {
            switch consumer {
            case let .label(name, consumer):
                _ = _compileLabel(name, consumer)
                return _compileSkip(consumer)
            case let .reference(name):
                return "\(sanitizedName(name))()"
            case let .string(string):
                return declare("_skipString", """
                () -> Bool { return \(_compileSkipString())(\(escapeString(string))) }
                """) + "()"
            case let .charset(charset):
                return _compileSkipCharacter(charset)
            case let .any(consumers):
                if consumers.count <= 1 {
                    if let first = consumers.first {
                        return _compileSkip(first)
                    }
                    return "true"
                }
                var body = ""
                var containsOptional = false
                for consumer in consumers {
                    if consumer.isOptional {
                        containsOptional = true
                        body.append("""
                                if \(_compileSkip(consumer)) {
                                    if index > startIndex { return true }
                                    matched = true
                                }

                        """)
                    } else {
                        body.append("""
                                if \(_compileSkip(consumer)) { return true }

                        """)
                    }
                }
                if containsOptional {
                    body = """
                    () -> Bool {
                            var matched = false
                            let startIndex = index
                    \(body)        return matched
                        }
                    """
                } else {
                    body = """
                    () -> Bool { return \(consumers.map(_compileSkip).joined(separator: " || ")) }
                    """
                }
                return "\(declare("_any", body))()"
            case let .sequence(consumers):
                if consumers.count <= 1 {
                    if let first = consumers.first {
                        return _compileSkip(first)
                    }
                    return "true"
                }
                var leading = ""
                var guarded = consumers
                var trailing = ""
                while guarded.first?.isOptional == true {
                    var consumer = guarded.removeFirst()
                    while case let .optional(_consumer) = consumer {
                        consumer = _consumer
                    }
                    leading.append("_ = \(_compileSkip(consumer))\n        ")
                }
                while guarded.last?.isOptional == true {
                    var consumer = guarded.removeLast()
                    while case let .optional(_consumer) = consumer {
                        consumer = _consumer
                    }
                    trailing = "_ = \(_compileSkip(consumer))\n        \(trailing)"
                }
                let name: String
                switch guarded.count {
                case 0:
                    name = declare("_skipSequence", """
                    () -> Bool {
                            \(leading)\(trailing)return true
                        }
                    """)
                case 1:
                    name = declare("_skipSequence", """
                    () -> Bool {
                            \(leading)guard \(_compileSkip(guarded[0])) else { return false }
                            \(trailing)return true
                        }
                    """)
                default:
                    name = declare("_skipSequence", """
                    () -> Bool {
                            let startIndex = index
                            \(leading)guard
                                \(guarded.map { _compileSkipAppend($0) }.joined(separator: ",\n            "))
                            else {
                                index = startIndex
                                return false
                            }
                            \(trailing)return true
                        }
                    """)
                }
                return "\(name)()"
            case let .optional(.oneOrMore(consumer)):
                switch consumer {
                case let .charset(charset):
                    let ranges = _ranges(for: charset)
                    if ranges.contains(",") {
                        return declare("_skipZeroOrMore", """
                        () -> Bool { return \(_compileSkipCharacters(charset))(\(ranges)) }
                        """) + "()"
                    }
                    return "\(_compileSkipCharacters(charset))(\(ranges))"
                case _ where consumer.isOptional:
                    return declare("_skipZeroOrMore", """
                    () -> Bool {
                            var lastIndex = index
                            while \(_compileSkip(consumer)), index > lastIndex {
                                lastIndex = index
                            }
                            return true
                        }
                    """) + "()"
                default:
                    return declare("_skipZeroOrMore", """
                    () -> Bool {
                            while \(_compileSkip(consumer)) {}
                            return true
                        }
                    """) + "()"
                }
            case let .oneOrMore(consumer):
                switch consumer {
                case let .charset(charset):
                    let name = declare("_skipOneOrMoreCharacters", """
                    (_ ranges: [CountableClosedRange<UInt32>]) -> Bool {
                            let startIndex = index
                            _ = \(_compileSkipCharacters(charset))(ranges)
                            return index > startIndex
                        }
                    """)
                    let ranges = _ranges(for: charset)
                    if ranges.contains(",") {
                        return declare("_skipOneOrMoreCharacters", """
                        () -> Bool { return \(name)(\(ranges)) }
                        """) + "()"
                    }
                    return "\(name)(\(ranges))"
                case _ where consumer.isOptional:
                    return declare("_skipOneOrMore", """
                    () -> Bool {
                            let startIndex = index
                            var lastIndex = index
                            while \(_compileSkip(consumer)) {
                                if index == lastIndex {
                                    return true
                                }
                                lastIndex = index
                            }
                            return index > startIndex
                        }
                    """) + "()"
                default:
                    return declare("_skipOneOrMore", """
                    () -> Bool {
                            let startIndex = index
                            while \(_compileSkip(consumer)) {}
                            return index > startIndex
                        }
                    """) + "()"
                }
            case let .optional(consumer):
                return declare("_skipOptional", """
                () -> Bool { return (\(_compileSkip(consumer)) || true) }
                """) + "()"
            case let .not(consumer):
                return _compileSkipNot(consumer)
            case let .flatten(consumer),
                 let .discard(consumer),
                 let .replace(consumer, _):
                return _compileSkip(consumer)
            }
        }

        func _isContiguous(_ consumer: Consumer) -> Bool {
            switch consumer {
            case .string, .charset, .not:
                return true
            case let .any(consumers),
                 let .sequence(consumers):
                return !consumers.contains { !_isContiguous($0) }
            case let .optional(consumer),
                 let .oneOrMore(consumer),
                 let .flatten(consumer):
                return _isContiguous(consumer)
            case .discard, .replace:
                return false
            case let .label(name, consumer):
                consumersByName[name] = consumer
                return _isContiguous(consumer)
            case let .reference(name):
                guard let consumer = consumersByName[name] else {
                    preconditionFailure("Undefined reference for consumer '\(name)'")
                }
                return _isContiguous(consumer)
            }
        }

        func _compileFlatten(_ consumer: Consumer) -> String {
            switch consumer {
            case let .label(name, consumer):
                _ = _compileLabel(name, consumer)
                return _compileFlatten(consumer)
            case let .reference(name):
                return "\(sanitizedName(name))()"
            case let .string(string):
                let stringFn = declare("_string", """
                (_ string: String) -> String? {
                        return \(_compileSkipString())(string) ? string: nil
                    }
                """)
                return declare("_string", """
                () -> String? { return \(stringFn)(\(escapeString(string))) }
                """) + "()"
            case let .charset(charset):
                return _compileFlattenCharacter(charset)
            case let .any(consumers):
                if consumers.count <= 1 {
                    if let first = consumers.first {
                        return _compileFlatten(first)
                    }
                    return "(\"\" as String?)"
                }
                var body = ""
                var containsOptional = false
                for consumer in consumers {
                    if consumer.isOptional {
                        containsOptional = true
                        body.append("""
                                if let match = \(_compileFlatten(consumer)) {
                                    if index > startIndex { return match }
                                    firstMatch = firstMatch ?? match
                                }

                        """)
                    } else {
                        body.append("""
                                if let match = \(_compileFlatten(consumer)) { return match }

                        """)
                    }
                }
                if containsOptional {
                    body = """
                    () -> String? {
                            var firstMatch: String?
                            let startIndex = index
                    \(body)        return firstMatch
                        }
                    """
                } else if consumers.count <= nilCoalescingLimit {
                    body = """
                    () -> String? { return \(consumers.map(_compileFlatten).joined(separator: " ?? ")) }
                    """
                } else {
                    var i = 0
                    body = """
                    () -> String? {

                    """
                    for consumer in consumers {
                        if i % nilCoalescingLimit == 0 {
                            if i > 0 {
                                body += " { return match }\n"
                            }
                            body += """
                                    if let match = \(_compileFlatten(consumer))
                            """
                        } else {
                            body += " ?? \(_compileFlatten(consumer))"
                        }
                        i += 1
                    }
                    if i > 0 {
                        body += " { return match }\n"
                    }
                    body += """
                            return nil
                        }
                    """
                }
                return "\(declare("_any", body))()"
            case let .sequence(consumers):
                if consumers.count <= 1 {
                    if let first = consumers.first {
                        return _compileFlatten(first)
                    }
                    return "(\"\" as String?)"
                }
                if _isContiguous(consumer) {
                    return declare("_flatten", """
                    () -> String? {
                            let startIndex = index
                            return \(_compileSkip(consumer)) ? String(input[startIndex ..< index]) : nil
                        }
                    """) + "()"
                }
                let append = declare("_appendString", """
                (_ match: String?, _ result: inout String, _ _expected: String) -> Bool {
                        if let match = match {
                            result += match
                            return true
                        } else {
                            if index >= bestIndex {
                                bestIndex = index
                                expected = _expected
                            }
                            return false
                        }
                    }
                """)
                let body = consumers.map {
                    if case .discard = $0 {
                        return _compileSkipAppend($0)
                    }
                    let append2 = declare("_appendString", """
                    (_ result: inout String) -> Bool { return \(append)(\(_compileFlatten($0)), &result, \(escapeString($0.description))) }
                    """)
                    return "\(append2)(&result)"
                }.joined(separator: ",\n            ")
                return declare("_flattenSequence", """
                () -> String? {
                        let startIndex = index
                        var result = ""
                        guard
                            \(body)
                        else {
                            index = startIndex
                            return nil
                        }
                        return result
                    }
                """) + "()"
            case let .optional(.oneOrMore(consumer)):
                if consumer.isOptional {
                    return declare("_flattenZeroOrMore", """
                    () -> String? {
                            var result = ""
                            while let match = \(_compileFlatten(consumer)) {
                                result.append(match)
                                if index == lastIndex {
                                    return result
                                }
                                lastIndex = index
                            }
                            return result
                        }
                    """) + "()"
                } else {
                    let name: String
                    if _isContiguous(consumer) {
                        name = declare("_flattenZeroOrMore", """
                        () -> String? {
                                let startIndex = index
                                while \(_compileSkip(consumer)) {}
                                return String(input[startIndex ..< index])
                            }
                        """)
                    } else {
                        name = declare("_flattenZeroOrMore", """
                        () -> String? {
                                var result = ""
                                while let match = \(_compileFlatten(consumer)) {
                                    result.append(match)
                                }
                                return result
                            }
                        """)
                    }
                    return "\(name)()"
                }
            case let .oneOrMore(consumer):
                if consumer.isOptional {
                    return declare("_flattenOneOrMore", """
                    () -> String? {
                            var result = ""
                            var matched = false
                            var lastIndex = index
                            while let match = \(_compileFlatten(consumer)) {
                                result.append(match)
                                if index == lastIndex {
                                    return result
                                }
                                lastIndex = index
                                matched = true
                            }
                            return matched ? result : nil
                        }
                    """) + "()"
                } else {
                    let name: String
                    if _isContiguous(consumer) {
                        name = declare("_flattenOneOrMore", """
                        () -> String? {
                                let startIndex = index
                                while \(_compileSkip(consumer)) {}
                                return index > startIndex ? String(input[startIndex ..< index]) : nil
                            }
                        """)
                    } else {
                        name = declare("_flattenOneOrMore", """
                        () -> String? {
                                var result = ""
                                let startIndex = index
                                while let match = \(_compileFlatten(consumer)) {
                                    result.append(match)
                                }
                                return index > startIndex ? result : nil
                            }
                        """)
                    }
                    return "\(name)()"
                }
            case let .optional(consumer):
                return declare("_flattenOptional", """
                () -> String? { return (\(_compileFlatten(consumer)) ?? \"\" as String?) }
                """) + "()"
            case let .not(consumer):
                return declare("_flattenNot", """
                () -> String? { return (\(_compileSkipNot(consumer)) ? \"\" : nil) }
                """) + "()"
            case let .flatten(consumer):
                return _compileFlatten(consumer)
            case let .discard(consumer):
                return declare("_discard", """
                () -> String? { return (\(_compileSkip(consumer)) ? \"\" : nil) }
                """) + "()"
            case let .replace(consumer, replacement):
                return declare("_replace", """
                () -> String? { return (\(_compileSkip(consumer)) ? \(escapeString(replacement)) : nil) }
                """) + "()"
            }
        }

        func _compile(_ consumer: Consumer) -> String {
            switch consumer {
            case let .label(name, consumer):
                return "\(_compileLabel(name, consumer))()"
            case let .reference(name):
                return "\(sanitizedName(name))()"
            case let .string(string):
                let stringFn = declare("_string", """
                (_ string: String) -> _Match? {
                        let startIndex = index
                        return \(_compileSkipString())(string) ? .token(string, startIndex ..< index) : nil
                    }
                """)
                return declare("_string", """
                () -> _Match? { return \(stringFn)(\(escapeString(string))) }
                """) + "()"
            case let .charset(charset):
                return _compileMatchCharacter(charset)
            case let .any(consumers):
                if consumers.count <= 1 {
                    if let first = consumers.first {
                        return _compile(first)
                    }
                    return "(.node(nil, []) as _Match?)"
                }
                var body = ""
                var containsOptional = false
                for consumer in consumers {
                    if consumer.isOptional {
                        containsOptional = true
                        body.append("""
                                if let match = \(_compile(consumer)) {
                                    if index > startIndex { return match }
                                    firstMatch = firstMatch ?? match
                                }

                        """)
                    } else {
                        body.append("""
                                if let match = \(_compile(consumer)) { return match }

                        """)
                    }
                }
                if containsOptional {
                    body = """
                    () -> _Match? {
                            var firstMatch: _Match?
                            let startIndex = index
                    \(body)        return firstMatch
                        }
                    """
                } else if consumers.count <= nilCoalescingLimit {
                    body = """
                    () -> _Match? { return \(consumers.map(_compile).joined(separator: " ?? ")) }
                    """
                } else {
                    var i = 0
                    body = """
                    () -> _Match? {

                    """
                    for consumer in consumers {
                        if i % nilCoalescingLimit == 0 {
                            if i > 0 {
                                body += " { return match }\n"
                            }
                            body += """
                                    if let match = \(_compile(consumer))
                            """
                        } else {
                            body += " ?? \(_compile(consumer))"
                        }
                        i += 1
                    }
                    if i > 0 {
                        body += " { return match }\n"
                    }
                    body += """
                            return nil
                        }
                    """
                }
                return "\(declare("_any", body))()"
            case let .sequence(consumers):
                if consumers.count <= 1 {
                    if let first = consumers.first {
                        return _compile(first)
                    }
                    return "(.node(nil, []) as _Match?)"
                }
                let append = declare("_append", """
                (_ match: _Match?, _ matches: inout [_Match], _ _expected: String) -> Bool {
                        if let match = match {
                            switch match {
                            case let .node(name, _matches):
                                if name != nil {
                                    fallthrough
                                }
                                matches += _matches
                            case .token:
                                matches.append(match)
                            }
                            return true
                        } else {
                            if index >= bestIndex {
                                bestIndex = index
                                expected = _expected
                            }
                            return false
                        }
                    }
                """)
                let body = consumers.map {
                    if case .discard = $0 {
                        return _compileSkipAppend($0)
                    }
                    let append2 = declare("_append", """
                    (_ matches: inout [_Match]) -> Bool { return \(append)(\(_compile($0)), &matches, \(escapeString($0.description))) }
                    """)
                    return "\(append2)(&matches)"
                }.joined(separator: ",\n            ")
                return declare("_sequence", """
                () -> _Match? {
                        let startIndex = index
                        var matches = [_Match]()
                        guard
                            \(body)
                        else {
                            index = startIndex
                            return nil
                        }
                        return .node(nil, matches)
                    }
                """) + "()"
            case let .optional(.oneOrMore(consumer)):
                let append = declare("_append", """
                (_ match: _Match?, _ matches: inout [_Match]) -> Bool {
                        if let match = match {
                            switch match {
                            case let .node(name, _matches):
                                if name != nil {
                                    fallthrough
                                }
                                matches += _matches
                            case .token:
                                matches.append(match)
                            }
                            return true
                        } else {
                            return false
                        }
                    }
                """)
                if consumer.isOptional {
                    return declare("_zeroOrMore", """
                    () -> _Match? {
                            var matches = [_Match]()
                            var lastIndex = index
                            while \(append)(\(_compile(consumer)), &matches), index > lastIndex {
                                lastIndex = index
                            }
                            return .node(nil, matches)
                        }
                    """) + "()"
                } else {
                    return declare("_zeroOrMore", """
                    () -> _Match? {
                            var matches = [_Match]()
                            while \(append)(\(_compile(consumer)), &matches) {}
                            return .node(nil, matches)
                        }
                    """) + "()"
                }
            case let .oneOrMore(consumer):
                let append = declare("_append", """
                (_ match: _Match?, _ matches: inout [_Match]) -> Bool {
                        if let match = match {
                            switch match {
                            case let .node(name, _matches):
                                if name != nil {
                                    fallthrough
                                }
                                matches += _matches
                            case .token:
                                matches.append(match)
                            }
                            return true
                        } else {
                            return false
                        }
                    }
                """)
                if consumer.isOptional {
                    return declare("_oneOrMore", """
                    () -> _Match? {
                            var matches = [_Match]()
                            var matched = false
                            var lastIndex = index
                            while \(append)(\(_compile(consumer)), &matches) {
                                if index == lastIndex {
                                    return .node(nil, matches)
                                }
                                lastIndex = index
                                matched = true
                            }
                            return matched ? .node(nil, matches) : nil
                        }
                    """) + "()"
                } else {
                    return declare("_oneOrMore", """
                    () -> _Match? {
                            var matches = [_Match]()
                            let startIndex = index
                            while \(append)(\(_compile(consumer)), &matches) {}
                            return index > startIndex ? .node(nil, matches) : nil
                        }
                    """) + "()"
                }
            case let .optional(consumer):
                return "(\(_compile(consumer)) ?? .node(nil, []) as _Match?)"
            case let .not(consumer):
                return declare("_not", """
                () -> String? { return (\(_compileSkipNot(consumer)) ? .node(nil, []) : nil) }
                """) + "()"
            case let .flatten(consumer):
                if case let .charset(charset) = consumer {
                    return declare("_flatten", """
                        () -> _Match? { return (\(_compileFlattenCharacter(charset)).map { _Match.token($0, input.index(before: index) ..< index) }) }
                    """) + "()"
                }
                if _isContiguous(consumer) {
                    return declare("_flatten", """
                    () -> _Match? {
                            let startIndex = index
                            return \(_compileSkip(consumer)) ? .token(String(input[startIndex ..< index]), startIndex ..< index) : nil
                        }
                    """) + "()"
                }
                return declare("_flatten", """
                () -> _Match? {
                        let startIndex = index
                        return \(_compileFlatten(consumer)).map { .token($0, startIndex ..< index) }
                    }
                """) + "()"
            case let .discard(consumer):
                return declare("_discard", """
                () -> _Match? { return (\(_compileSkip(consumer)) ? _Match.node(nil, []) : nil) }
                """) + "()"
            case let .replace(consumer, replacement):
                if case let .charset(charset) = consumer {
                    return declare("_replaceCharacter", """
                        () -> _Match? { return (\(_compileSkipCharacter(charset)) ? _Match.token(\(escapeString(replacement)), input.index(before: index) ..< index) : nil) }
                    """) + "()"
                }
                return declare("_replace", """
                () -> _Match? {
                        let startIndex = index
                        return \(_compileSkip(consumer)) ? .token(\(escapeString(replacement)), startIndex ..< index) : nil
                    }
                """) + "()"
            }
        }

        let labelType: String
        let nameBinding: String
        if isRawRepresentable {
            var type = "\(Label.self)"
            if type.hasPrefix("("), let range = type.range(of: " ") {
                type = String(type[type.index(after: type.startIndex) ..< range.lowerBound])
            }
            labelType = type
            nameBinding = "name.map { \(labelType)(rawValue: $0)! }"
        } else {
            labelType = "String"
            nameBinding = "name"
        }

        let indexToOffset = declare("_indexToOffset", """
        (_ index: String.Index) -> String {
                var line = 1
                var column = 1
                var wasReturn = false
                for c in input[..<index] {
                    switch c {
                    case "\\n" where wasReturn:
                        continue
                    case "\\r", "\\n":
                        line += 1
                        column = 1
                    default:
                        column += 1
                    }
                    wasReturn = (c == "\\r")
                }
                return "\\(line):\\(column)"
            }
        """)

        let _transform: String
        let returnType: String
        if let fn = transformFunction {
            returnType = "Any?"
            _transform = declare("_transform", """
            (_ match: _Match) throws -> Any? {
                    do {
                        switch match {
                        case let .token(string, _):
                            return string
                        case let .node(name, matches):
                            let values = try Array(matches.compactMap(_transform))
                            return try \(nameBinding).map { try \(fn)($0, values) } ?? values
                        }
                    } catch let error as _Error {
                        throw error
                    } catch {
                        var match = match
                        while case let .node(_, matches) = match, !matches.isEmpty {
                            match = matches[0]
                        }
                        if case let .token(_, range) = match {
                            throw _Error(string: \"\\(error) at \\(\(indexToOffset)(range.lowerBound))\")
                        }
                        throw _Error(string: \"\\(error)\")
                    }
                }
            """)
        } else {
            returnType = "Consumer<\(labelType)>.Match"
            _transform = declare("_transform", """
            (_ match: _Match) throws -> Consumer<\(labelType)>.Match {
                    switch match {
                    case let .token(string, range):
                        return .token(string, .at(range, in: input))
                    case let .node(name, matches):
                        return try .node(\(nameBinding), matches.map(_transform))
                    }
                }
            """)
        }
        if _transform != "_transform" {
            functions[_transform] = functions[_transform]?
                .replacingOccurrences(of: "(_transform)", with: "(\(_transform))")
        }

        let tokenAtIndex = declare("_tokenAtIndex", """
        (_ index: String.Index) -> String {
                var remaining = input[index...]
                var token = ""
                let whitespace = " \\t\\n\\r".unicodeScalars
                if let first = remaining.first, whitespace.contains(first) {
                    token = String(first)
                } else {
                    while let char = remaining.popFirst(), !whitespace.contains(char) {
                        token.append(Character(char))
                    }
                }
                return token.isEmpty ? "" : " '\\(token)'"
            }
        """)

        var body = """
            if let match = \(_compile(self)) {
                if index < input.endIndex {
                    if bestIndex > index, let expected = expected {
                        let token = \(tokenAtIndex)(bestIndex)
                        throw _Error(string: "Unexpected token\\(token) at \\(\(indexToOffset)(bestIndex)) (expected \\(expected))")
                    }
                    let token = \(tokenAtIndex)(index)
                    throw _Error(string: "Unexpected token\\(token) at \\(\(indexToOffset)(index))")
                }
                return try \(_transform)(match)
            } else {
                let token = \(tokenAtIndex)(bestIndex)
                let expected = expected ?? \(escapeString(description))
                if token.isEmpty {
                    throw _Error(string: "Expected \\(expected) at \\(\(indexToOffset)(bestIndex))")
                } else {
                    throw _Error(string: "Unexpected token\\(token) at \\(\(indexToOffset)(bestIndex)) (expected \\(expected))")
                }
            }
        """
        for name in functions.keys.sorted() {
            body = """
                func \(name)\(functions[name]!)

            """ + body
        }
        var result = """
        // Parser function generated by the Consumer compiler
        func \(functionName)(_ input: String) throws -> \(returnType) {
            indirect enum _Match {
                case token(String, Range<String.Index>)
                case node(String?, [_Match])
            }

            struct _Error: Swift.Error, CustomStringConvertible {
                var string: String
                var description: String { return string }
            }

            let input = input.unicodeScalars
            var index = input.startIndex

            var bestIndex = input.startIndex
            var expected: String?

        \(body)
        }

        """
        func rangeOf(_ name: String, in source: String, after: String.Index) -> Range<String.Index>? {
            let _range = after ..< source.endIndex
            guard let range =
                source.range(of: "\(name)()", range: _range) ??
                source.range(of: "\(name)(&matches)", range: _range) ??
                source.range(of: "\(name)(&result)", range: _range)
            else {
                return nil
            }
            if source[..<range.lowerBound].hasSuffix("func ") {
                return rangeOf(name, in: source, after: range.upperBound)
            }
            return range
        }
        func replace(_ name: String, with body: String, in source: String) -> String? {
            guard let range = rangeOf(name, in: source, after: source.startIndex) else {
                return nil
            }
            var source = source
            source.replaceSubrange(range, with: { () -> Substring in
                let start = body.range(of: "return ")
                let end = body.range(of: " }", options: .backwards)
                return body[start!.upperBound ..< end!.lowerBound]
            }())
            return source
        }
        // Inline functions
        for name in functions.keys {
            let body = functions[name]!
            guard !body.contains("\n"),
                  let firstRange = rangeOf(name, in: result, after: result.startIndex)
            else {
                continue // Not inlinable
            }
            if rangeOf(name, in: result, after: firstRange.upperBound) != nil {
                continue // Called more than once
            }
            // Inline function call
            for (_name, source) in functions {
                if let _source = replace(name, with: body, in: source) {
                    functions[_name] = _source
                }
            }
            if let _result = replace(name, with: body, in: result) {
                result = _result
            }
            // Remove function declaration
            if let range = result.range(of: "    func \(name)\(body)\n") {
                result.replaceSubrange(range, with: "")
            }
        }
        return result
    }

    /// Source-safe string
    func escapeString<T: StringProtocol>(_ string: T) -> String {
        var result = "\""
        for char in string.unicodeScalars {
            switch char.value {
            case 0:
                result.append("\\0")
            case 9:
                result.append("\\t")
            case 10:
                result.append("\\n")
            case 13:
                result.append("\\r")
            case 34, 92:
                result.append("\\\(String(char))")
            case let codePoint where CharacterSet.controlCharacters.contains(char):
                result.append("\\u{\(String(codePoint, radix: 16, uppercase: true))}")
            default:
                result.append(Character(char))
            }
        }
        return result + "\""
    }
}
