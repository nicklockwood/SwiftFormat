//
//  Rules.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 21/10/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
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
    case disabled
}

/// Argument type for stripping
public enum ArgumentType: String {
    case unnamedOnly = "unnamed-only"
    case closureOnly = "closure-only"
    case all = "always"
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
            var parts = rawValue.components(separatedBy: ",")
            if parts.count == 1 {
                parts.append(parts[0])
            }
            guard let group = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                let threshold = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
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

    public static func ==(lhs: Grouping, rhs: Grouping) -> Bool {
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
    public var useVoid: Bool
    public var trailingCommas: Bool
    public var indentComments: Bool
    public var truncateBlankLines: Bool
    public var insertBlankLines: Bool
    public var removeBlankLines: Bool
    public var allmanBraces: Bool
    public var fileHeader: String?
    public var ifdefIndent: IndentMode
    public var wrapArguments: WrapMode
    public var wrapElements: WrapMode
    public var uppercaseHex: Bool
    public var uppercaseExponent: Bool
    public var decimalGrouping: Grouping
    public var binaryGrouping: Grouping
    public var octalGrouping: Grouping
    public var hexGrouping: Grouping
    public var hoistPatternLet: Bool
    public var stripUnusedArguments: ArgumentType
    public var removeSelf: Bool
    public var experimentalRules: Bool
    public var fragment: Bool

    // Doesn't really belong here, but hard to put elsewhere
    public var ignoreConflictMarkers: Bool

    public init(indent: String = "    ",
                linebreak: String = "\n",
                allowInlineSemicolons: Bool = true,
                spaceAroundRangeOperators: Bool = true,
                useVoid: Bool = true,
                trailingCommas: Bool = true,
                indentComments: Bool = true,
                truncateBlankLines: Bool = true,
                insertBlankLines: Bool = true,
                removeBlankLines: Bool = true,
                allmanBraces: Bool = false,
                fileHeader: String? = nil,
                ifdefIndent: IndentMode = .indent,
                wrapArguments: WrapMode = .disabled,
                wrapElements: WrapMode = .beforeFirst,
                uppercaseHex: Bool = true,
                uppercaseExponent: Bool = false,
                decimalGrouping: Grouping = .group(3, 6),
                binaryGrouping: Grouping = .group(4, 8),
                octalGrouping: Grouping = .group(4, 8),
                hexGrouping: Grouping = .group(4, 8),
                hoistPatternLet: Bool = true,
                stripUnusedArguments: ArgumentType = .all,
                removeSelf: Bool = true,
                experimentalRules: Bool = false,
                fragment: Bool = false,
                ignoreConflictMarkers: Bool = false) {

        self.indent = indent
        self.linebreak = linebreak
        self.allowInlineSemicolons = allowInlineSemicolons
        self.spaceAroundRangeOperators = spaceAroundRangeOperators
        self.useVoid = useVoid
        self.trailingCommas = trailingCommas
        self.indentComments = indentComments
        self.truncateBlankLines = truncateBlankLines
        self.insertBlankLines = insertBlankLines
        self.removeBlankLines = removeBlankLines
        self.allmanBraces = allmanBraces
        self.fileHeader = fileHeader
        self.ifdefIndent = ifdefIndent
        self.wrapArguments = wrapArguments
        self.wrapElements = wrapElements
        self.uppercaseHex = uppercaseHex
        self.uppercaseExponent = uppercaseExponent
        self.decimalGrouping = decimalGrouping
        self.binaryGrouping = binaryGrouping
        self.octalGrouping = octalGrouping
        self.hexGrouping = hexGrouping
        self.hoistPatternLet = hoistPatternLet
        self.stripUnusedArguments = stripUnusedArguments
        self.removeSelf = removeSelf
        self.experimentalRules = experimentalRules
        self.fragment = fragment
        self.ignoreConflictMarkers = ignoreConflictMarkers
    }

    public var description: String {
        let allowedCharacters = CharacterSet.newlines.inverted
        return Mirror(reflecting: self).children.map({
            "\($0.value);".addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
        }).joined()
    }
}

/// Infer default options by examining the existing source
public func inferOptions(from tokens: [Token]) -> FormatOptions {
    let formatter = Formatter(tokens)
    var options = FormatOptions()

    options.indent = {
        var indents = [(indent: String, count: Int)]()
        func increment(_ indent: String) {
            for (i, element) in indents.enumerated() {
                if element.indent == indent {
                    indents[i] = (indent, element.count + 1)
                    return
                }
            }
            indents.append((indent, 0))
        }
        formatter.forEach(.linebreak) { i, _ in
            let start = formatter.startOfLine(at: i)
            if case let .space(string) = formatter.tokens[start] {
                if string.hasPrefix("\t") {
                    increment("\t")
                } else {
                    let length = string.characters.count
                    for i in [8, 4, 3, 2, 1] {
                        if length % i == 0 {
                            increment(String(repeating: " ", count: i))
                            break
                        }
                    }
                }
            }
        }
        return indents.sorted(by: { $0.count > $1.count }).first.map({ $0.indent }) ?? options.indent
    }()

    options.linebreak = {
        var cr: Int = 0, lf: Int = 0, crlf: Int = 0
        formatter.forEachToken { _, token in
            switch token {
            case .linebreak("\n"):
                lf += 1
            case .linebreak("\r"):
                cr += 1
            case .linebreak("\r\n"):
                crlf += 1
            default:
                break
            }
        }
        var max = lf
        var linebreak = "\n"
        if cr > max {
            max = cr
            linebreak = "\r"
        }
        if crlf > max {
            max = crlf
            linebreak = "\r\n"
        }
        return linebreak
    }()

    // No way to infer this
    options.allowInlineSemicolons = true

    options.spaceAroundRangeOperators = {
        var spaced = 0, unspaced = 0
        formatter.forEachToken { i, token in
            if token.isRangeOperator {
                if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) {
                    if nextToken.string != ")" && nextToken.string != "," {
                        if formatter.token(at: i + 1)?.isSpaceOrLinebreak == true {
                            spaced += 1
                        } else {
                            unspaced += 1
                        }
                    }
                }
            }
        }
        return spaced >= unspaced
    }()

    options.useVoid = {
        var voids = 0, tuples = 0
        formatter.forEach(.identifier("Void")) { i, _ in
            if let prevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: i),
                [.operator(".", .prefix), .operator(".", .infix), .keyword("typealias")].contains(prevToken) {
                return
            }
            voids += 1
        }
        formatter.forEach(.startOfScope("(")) { i, _ in
            if let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                let prevToken = formatter.token(at: prevIndex), prevToken == .operator("->", .infix),
                let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: i),
                let nextToken = formatter.token(at: nextIndex), nextToken.string == ")",
                formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) != .operator("->", .infix) {
                tuples += 1
            }
        }
        return voids >= tuples
    }()

    options.trailingCommas = {
        var trailing = 0, noTrailing = 0
        formatter.forEach(.endOfScope("]")) { i, token in
            if let linebreakIndex = formatter.index(of: .nonSpaceOrComment, before: i),
                case .linebreak = formatter.tokens[linebreakIndex] {
                if let prevTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: linebreakIndex + 1), let token = formatter.token(at: prevTokenIndex) {
                    switch token.string {
                    case "[", ":":
                        break // do nothing
                    case ",":
                        trailing += 1
                    default:
                        noTrailing += 1
                    }
                }
            }
        }
        return trailing >= noTrailing
    }()

    options.indentComments = {
        var shouldIndent = true
        var nestedComments = 0
        var prevIndent: Int?
        var lastTokenWasLinebreak = false
        for token in formatter.tokens {
            switch token {
            case .startOfScope:
                if token.string == "/*" {
                    nestedComments += 1
                }
                prevIndent = nil
            case .endOfScope:
                if token.string == "*/" {
                    if nestedComments > 0 {
                        if lastTokenWasLinebreak {
                            if prevIndent != nil && prevIndent! >= 2 {
                                shouldIndent = false
                                break
                            }
                            prevIndent = 0
                        }
                        nestedComments -= 1
                    } else {
                        break // might be fragment, or syntax error
                    }
                }
                prevIndent = nil
            case .space:
                if lastTokenWasLinebreak, nestedComments > 0 {
                    let indent = token.string.characters.count
                    if prevIndent != nil && abs(prevIndent! - indent) >= 2 {
                        shouldIndent = false
                        break
                    }
                    prevIndent = indent
                }
            case .commentBody:
                if lastTokenWasLinebreak, nestedComments > 0 {
                    if prevIndent != nil && prevIndent! >= 2 {
                        shouldIndent = false
                        break
                    }
                    prevIndent = 0
                }
            default:
                break
            }
            lastTokenWasLinebreak = token.isLinebreak
        }
        return shouldIndent
    }()

    options.truncateBlankLines = {
        var truncated = 0, untruncated = 0
        var scopeStack = [Token]()
        formatter.forEachToken { i, token in
            switch token {
            case .startOfScope:
                scopeStack.append(token)
            case .linebreak:
                if let nextToken = formatter.token(at: i + 1) {
                    switch nextToken {
                    case .space:
                        if let nextToken = formatter.token(at: i + 2) {
                            if case .linebreak = nextToken {
                                untruncated += 1
                            }
                        } else {
                            untruncated += 1
                        }
                    case .linebreak:
                        truncated += 1
                    default:
                        break
                    }
                }
            default:
                if let scope = scopeStack.last, token.isEndOfScope(scope) {
                    scopeStack.removeLast()
                }
            }
        }
        return truncated >= untruncated
    }()

    // We can't infer these yet, so default them to false
    options.insertBlankLines = false
    options.removeBlankLines = false

    options.allmanBraces = {
        var allman = 0, knr = 0
        formatter.forEach(.startOfScope("{")) { i, _ in
            // Check this isn't an inline block
            guard let nextLinebreakIndex = formatter.index(of: .linebreak, after: i),
                let closingBraceIndex = formatter.index(of: .endOfScope("}"), after: i),
                nextLinebreakIndex < closingBraceIndex else { return }
            // Check if brace is wrapped
            if let prevTokenIndex = formatter.index(of: .nonSpace, before: i),
                let prevToken = formatter.token(at: prevTokenIndex) {
                switch prevToken {
                case .identifier, .keyword, .endOfScope, .operator("?", .postfix), .operator("!", .postfix):
                    knr += 1
                case .linebreak:
                    allman += 1
                default:
                    break
                }
            }
        }
        return allman > knr
    }()

    options.ifdefIndent = {
        var indented = 0, notIndented = 0, outdented = 0
        formatter.forEach(.startOfScope("#if")) { i, _ in
            if let indent = formatter.token(at: i - 1), case let .space(string) = indent,
                !string.isEmpty {
                // Indented, check next line
                if let nextLineIndex = formatter.index(of: .linebreak, after: i),
                    let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nextLineIndex) {
                    switch formatter.tokens[nextIndex - 1] {
                    case let .space(innerString):
                        if innerString.isEmpty {
                            // Error?
                            return
                        } else if innerString == string {
                            notIndented += 1
                        } else {
                            // Assume more indented, as less would be a mistake
                            indented += 1
                        }
                    case .linebreak:
                        // Could be noindent or outdent
                        notIndented += 1
                        outdented += 1
                    default:
                        break
                    }
                }
                // Error?
                return
            }
            // Not indented, check next line
            if let nextLineIndex = formatter.index(of: .linebreak, after: i),
                let nextIndex = formatter.index(of: .nonSpaceOrLinebreak, after: nextLineIndex) {
                switch formatter.tokens[nextIndex - 1] {
                case let .space(string):
                    if string.isEmpty {
                        fallthrough
                    } else if string == formatter.options.indent {
                        // Could be indent or outdent
                        indented += 1
                        outdented += 1
                    } else {
                        // Assume more indented, as less would be a mistake
                        outdented += 1
                    }
                case .linebreak:
                    // Could be noindent or outdent
                    notIndented += 1
                    outdented += 1
                default:
                    break
                }
            }
            // Error?
        }
        if notIndented > indented {
            return outdented > notIndented ? .outdent : .noIndent
        } else {
            return outdented > indented ? .outdent : .indent
        }
    }()

    func wrapMode(for scopes: String..., allowGrouping: Bool) -> WrapMode {
        var beforeFirst = 0, afterFirst = 0, neither = 0
        formatter.forEachToken(where: { $0.isStartOfScope && scopes.contains($0.string) }) { i, _ in
            if let closingBraceIndex = formatter.endOfScope(at: i),
                let linebreakIndex = formatter.index(of: .linebreak, after: i),
                linebreakIndex < closingBraceIndex,
                let firstCommaIndex = formatter.index(of: .delimiter(","), after: i),
                firstCommaIndex < closingBraceIndex {
                if !allowGrouping {
                    // Check for two consecutive arguments on the same line
                    var index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: closingBraceIndex)!
                    if formatter.tokens[index] != .delimiter(",") {
                        index += 1
                    }
                    while index > i {
                        guard let commaIndex = formatter.index(of: .delimiter(","), before: index) else {
                            break
                        }
                        if formatter.next(.nonSpaceOrComment, after: commaIndex)?.isLinebreak == false {
                            neither += 1
                            return
                        }
                        index = commaIndex
                    }
                }
                // Check if linebreak is after opening paren or first comma
                if formatter.next(.nonSpaceOrComment, after: i)?.isLinebreak == true {
                    beforeFirst += 1
                } else {
                    assert(allowGrouping ||
                        formatter.next(.nonSpaceOrComment, after: firstCommaIndex)?.isLinebreak == true)
                    afterFirst += 1
                }
            }
        }
        if beforeFirst > afterFirst + neither {
            return .beforeFirst
        } else if afterFirst > beforeFirst + neither {
            return .afterFirst
        } else {
            return .disabled
        }
    }
    options.wrapArguments = wrapMode(for: "(", "<", allowGrouping: false)
    options.wrapElements = wrapMode(for: "[", allowGrouping: true)

    options.uppercaseHex = {
        let prefix = "0x"
        var uppercase = 0, lowercase = 0
        formatter.forEachToken { _, token in
            if case var .number(string, .hex) = token {
                string = string
                    .replacingOccurrences(of: "p", with: "")
                    .replacingOccurrences(of: "P", with: "")
                if string == string.lowercased() {
                    lowercase += 1
                } else {
                    let value = string.substring(from: prefix.endIndex)
                    if value == value.uppercased() {
                        uppercase += 1
                    }
                }
            }
        }
        return uppercase >= lowercase
    }()

    options.uppercaseExponent = {
        var uppercase = 0, lowercase = 0
        formatter.forEachToken { _, token in
            switch token {
            case let .number(string, .decimal):
                let characters = string.unicodeScalars
                if characters.contains("e") {
                    lowercase += 1
                } else if characters.contains("E") {
                    uppercase += 1
                }
            case let .number(string, .hex):
                let characters = string.unicodeScalars
                if characters.contains("p") {
                    lowercase += 1
                } else if characters.contains("P") {
                    uppercase += 1
                }
            default:
                break
            }
        }
        return uppercase > lowercase
    }()

    func grouping(for numberType: NumberType) -> Grouping {
        var grouping = [(group: Int, threshold: Int, count: Int)](), lowest = Int.max
        formatter.forEachToken { _, token in
            guard case let .number(number, type) = token else {
                return
            }
            guard numberType == type || numberType == .decimal && type == .integer else {
                return
            }
            // Strip prefix/suffix
            let digits: String.CharacterView
            let prefix = "0x"
            switch type {
            case .integer:
                digits = number.characters
            case .binary, .octal:
                digits = number.characters.suffix(from: prefix.endIndex)
            case .hex:
                let endIndex =
                    number.characters.index { [".", "p", "P"].contains($0) } ?? number.endIndex
                digits = number.characters[prefix.endIndex ..< endIndex]
            case .decimal:
                let endIndex =
                    number.characters.index { [".", "e", "E"].contains($0) } ?? number.endIndex
                digits = number.characters.prefix(upTo: endIndex)
            }
            // Get the group for this number
            var count = 0
            var index = digits.endIndex
            var group = 0
            repeat {
                index = digits.index(before: index)
                if digits[index] == "_" {
                    if group == 0, count > 0 {
                        group = count
                        lowest = min(lowest, group + 1)
                    }
                } else {
                    count += 1
                }
            } while index != digits.startIndex
            // Add To groups list
            var found = false
            if group > 0 {
                for (i, g) in grouping.enumerated() {
                    if g.group == group {
                        grouping[i] = (group, min(g.threshold, count), g.count + 1)
                        found = true
                        break
                    }
                }
            }
            if !found {
                grouping.append((group, count, 1))
            }
        }
        // Only count none values whose threshold > lowest group value
        var none = 0, maxCount = 0, total = 0
        var group = (group: 0, threshold: 0, count: 0)
        grouping = grouping.filter {
            if $0.group == 0 {
                if $0.threshold >= lowest {
                    none += 1
                }
                return false
            }
            total += $0.count
            if $0.count > maxCount {
                maxCount = $0.count
                group = $0
            }
            return true
        }
        // Return most common
        if group.count >= max(1, none) {
            if group.count > total / 2 {
                return .group(group.group, group.threshold)
            }
            return .ignore
        }
        return .none
    }
    options.decimalGrouping = grouping(for: .decimal)
    options.binaryGrouping = grouping(for: .binary)
    options.octalGrouping = grouping(for: .octal)
    options.hexGrouping = grouping(for: .hex)

    options.hoistPatternLet = {
        var hoisted = 0, unhoisted = 0

        func hoistable(_ keyword: String, in range: CountableRange<Int>) -> Bool {
            var found = 0, keywordFound = false, identifierFound = false
            for index in range {
                switch formatter.tokens[index] {
                case .keyword(keyword):
                    keywordFound = true
                    found += 1
                case .identifier("_"):
                    break
                case .identifier where formatter.last(.nonSpaceOrComment, before: index)?.string != ".":
                    identifierFound = true
                case .delimiter(","):
                    guard keywordFound || !identifierFound else { return false }
                    keywordFound = false
                    identifierFound = false
                case .startOfScope("{"):
                    return false
                default:
                    break
                }
            }
            return (keywordFound || !identifierFound) && found > 0
        }

        formatter.forEach(.startOfScope("(")) { i, _ in
            // Check if pattern starts with let/var
            var startIndex = i
            guard let endIndex = formatter.index(of: .endOfScope(")"), after: i) else { return }
            if var prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: i) {
                if case .identifier = formatter.tokens[prevIndex] {
                    prevIndex = formatter.index(of: .spaceOrCommentOrLinebreak, before: prevIndex) ?? -1
                    startIndex = prevIndex + 1
                    prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: startIndex) ?? 0
                }
                let prevToken = formatter.tokens[prevIndex]
                switch prevToken {
                case .keyword("let"), .keyword("var"):
                    guard let prevPrevToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: prevIndex),
                        [.keyword("case"), .endOfScope("case"), .delimiter(",")].contains(prevPrevToken) else {
                        // Tuple assignment, not a pattern
                        return
                    }
                    hoisted += 1
                case .keyword("case"), .endOfScope("case"), .delimiter(","):
                    if hoistable("let", in: i + 1 ..< endIndex) || hoistable("var", in: i + 1 ..< endIndex) {
                        unhoisted += 1
                    }
                default:
                    return
                }
            }
        }
        return hoisted >= unhoisted
    }()

    options.stripUnusedArguments = {
        var functionArgsRemoved = 0, functionArgsKept = 0
        var unnamedFunctionArgsRemoved = 0, unnamedFunctionArgsKept = 0

        func removeUsed<T>(from argNames: inout [String], with associatedData: inout [T], in range: Range<Int>) {
            for i in range.lowerBound ..< range.upperBound {
                let token = formatter.tokens[i]
                if case .identifier = token, let index = argNames.index(of: token.unescaped()),
                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: i)?.isOperator(".") == false,
                    (formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) != .delimiter(":") ||
                        formatter.currentScope(at: i) == .startOfScope("[")) {
                    argNames.remove(at: index)
                    associatedData.remove(at: index)
                    if argNames.isEmpty {
                        break
                    }
                }
            }
        }
        // Function arguments
        formatter.forEachToken { i, token in
            guard case let .keyword(keyword) = token, ["func", "init", "subscript"].contains(keyword),
                let startIndex = formatter.index(of: .startOfScope("("), after: i),
                let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex) else { return }
            let isOperator = (keyword == "subscript") ||
                (keyword == "func" && formatter.next(.nonSpaceOrCommentOrLinebreak, after: i)?.isOperator == true)
            var index = startIndex
            var argNames = [String]()
            var nameIndices = [Int]()
            while index < endIndex {
                guard let externalNameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                    if case .identifier = $0 { return true }
                    // Probably an empty argument list
                    return false
                }) else { return }
                guard let nextIndex =
                    formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: externalNameIndex) else { return }
                let nextToken = formatter.tokens[nextIndex]
                switch nextToken {
                case let .identifier(name):
                    if name == "_" {
                        functionArgsRemoved += 1
                        let externalNameToken = formatter.tokens[externalNameIndex]
                        if case .identifier("_") = externalNameToken {
                            unnamedFunctionArgsRemoved += 1
                        }
                    } else {
                        argNames.append(nextToken.unescaped())
                        nameIndices.append(externalNameIndex)
                    }
                case .delimiter(":"):
                    let externalNameToken = formatter.tokens[externalNameIndex]
                    if case .identifier("_") = externalNameToken {
                        functionArgsRemoved += 1
                        unnamedFunctionArgsRemoved += 1
                    } else {
                        argNames.append(externalNameToken.unescaped())
                        nameIndices.append(externalNameIndex)
                    }
                default:
                    return
                }
                index = formatter.index(of: .delimiter(","), after: index) ?? endIndex
            }
            guard !argNames.isEmpty, let bodyStartIndex = formatter.index(after: endIndex, where: {
                switch $0 {
                case .startOfScope("{"): // What we're looking for
                    return true
                case .keyword("throws"),
                     .keyword("rethrows"),
                     .keyword("where"),
                     .keyword("is"):
                    return false // Keep looking
                case .keyword:
                    return true // Not valid between end of arguments and start of body
                default:
                    return false // Keep looking
                }
            }), formatter.tokens[bodyStartIndex] == .startOfScope("{"),
                let bodyEndIndex = formatter.index(of: .endOfScope("}"), after: bodyStartIndex) else {
                return
            }
            removeUsed(from: &argNames, with: &nameIndices, in: bodyStartIndex + 1 ..< bodyEndIndex)
            for index in nameIndices.reversed() {
                functionArgsKept += 1
                if case .identifier("_") = formatter.tokens[index] {
                    unnamedFunctionArgsKept += 1
                }
            }
        }
        if functionArgsRemoved >= functionArgsKept {
            return .all
        } else if unnamedFunctionArgsRemoved >= unnamedFunctionArgsKept {
            return .unnamedOnly
        } else {
            // TODO: infer not removing args at all
            return .closureOnly
        }
    }()

    options.removeSelf = {
        var removed = 0, unremoved = 0

        func processDeclaredVariables(at index: inout Int, names: inout Set<String>) {
            while let token = formatter.token(at: index) {
                switch token {
                case .identifier where
                    formatter.last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == false:
                    let name = token.unescaped()
                    if name != "_" {
                        names.insert(name)
                    }
                    inner: while let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                        switch formatter.tokens[nextIndex] {
                        case .keyword("as"), .keyword("is"), .keyword("try"):
                            break
                        case .startOfScope("<"), .startOfScope("["), .startOfScope("("):
                            guard let endIndex = formatter.endOfScope(at: nextIndex) else {
                                return // error
                            }
                            index = endIndex
                            continue
                        case .keyword, .startOfScope("{"), .startOfScope(":"):
                            return
                        case .delimiter(","):
                            index = nextIndex
                            break inner
                        default:
                            break
                        }
                        index = nextIndex
                    }
                default:
                    break
                }
                index += 1
            }
        }
        func processBody(at index: inout Int, localNames: Set<String>, members: Set<String>, isTypeRoot: Bool) {
            assert({ formatter.currentScope(at: index).map {
                [.startOfScope("{"), .startOfScope(":")].contains($0)
            } ?? true }())
            // Gather members & local variables
            var members = members
            var classMembers = Set<String>()
            var localNames = localNames
            do {
                var i = index
                var classOrStatic = false
                outer: while let token = formatter.token(at: i) {
                    switch token {
                    case .keyword("class"), .keyword("static"):
                        classOrStatic = true
                    case .keyword("repeat"):
                        guard let nextIndex = formatter.index(of: .keyword("while"), after: i) else {
                            return // error
                        }
                        i = nextIndex
                    case .keyword("if"), .keyword("while"):
                        guard let nextIndex = formatter.index(of: .startOfScope("{"), after: i) else {
                            return // error
                        }
                        i = nextIndex
                        continue
                    case .keyword("var"), .keyword("let"):
                        i += 1
                        if isTypeRoot {
                            if classOrStatic {
                                processDeclaredVariables(at: &i, names: &classMembers)
                                classOrStatic = false
                            } else {
                                processDeclaredVariables(at: &i, names: &members)
                            }
                        } else {
                            processDeclaredVariables(at: &i, names: &localNames)
                        }
                    case .keyword("func"):
                        if let nameToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i) {
                            if isTypeRoot {
                                if classOrStatic {
                                    classMembers.insert(nameToken.unescaped())
                                    classOrStatic = false
                                } else {
                                    members.insert(nameToken.unescaped())
                                }
                            } else {
                                localNames.insert(nameToken.unescaped())
                            }
                        }
                    case .startOfScope("("), .endOfScope(")"):
                        break
                    case .startOfScope:
                        classOrStatic = false
                        i = formatter.endOfScope(at: i) ?? (formatter.tokens.count - 1)
                    case .endOfScope("}"):
                        i += 1
                        break outer
                    default:
                        break
                    }
                    i += 1
                }
            }
            // Detect self
            var scopeStack = [Token]()
            var lastKeyword = ""
            var classOrStatic = false
            while let token = formatter.token(at: index) {
                switch token {
                case .keyword("is"), .keyword("as"), .keyword("try"):
                    break
                case .keyword("func"), .keyword("init"), .keyword("subscript"):
                    lastKeyword = ""
                    if classOrStatic {
                        assert(isTypeRoot)
                        processFunction(at: &index, localNames: localNames, members: classMembers)
                        classOrStatic = false
                    } else {
                        processFunction(at: &index, localNames: localNames, members: members)
                    }
                case .keyword("static"):
                    classOrStatic = true
                case .keyword("class"):
                    if formatter.next(.nonSpaceOrCommentOrLinebreak, after: index)?.isIdentifier == true {
                        fallthrough
                    }
                    classOrStatic = true
                case .keyword("extension"), .keyword("struct"), .keyword("enum"):
                    guard formatter.last(.nonSpaceOrCommentOrLinebreak, before: index) != .keyword("import"),
                        let scopeStart = formatter.index(of: .startOfScope("{"), after: index) else { return }
                    index = scopeStart + 1
                    processBody(at: &index, localNames: ["init"], members: [], isTypeRoot: true)
                case .keyword("var"), .keyword("let"):
                    index += 1
                    switch lastKeyword {
                    case "lazy":
                        loop: while let nextIndex =
                            formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                            switch formatter.tokens[nextIndex] {
                            case .keyword("as"), .keyword("is"), .keyword("try"):
                                break
                            case .keyword, .startOfScope("{"):
                                break loop
                            default:
                                break
                            }
                            index = nextIndex
                        }
                        lastKeyword = ""
                    case "if", "while", "guard":
                        assert(!isTypeRoot)
                        // Guard is included because it's an error to reference guard vars in body
                        var scopedNames = localNames
                        processDeclaredVariables(at: &index, names: &scopedNames)
                        guard let startIndex = formatter.index(of: .startOfScope("{"), after: index) else {
                            return // error
                        }
                        index = startIndex + 1
                        processBody(at: &index, localNames: scopedNames, members: members, isTypeRoot: false)
                        lastKeyword = ""
                    default:
                        lastKeyword = token.string
                    }
                    classOrStatic = false
                case .keyword("while") where lastKeyword == "repeat":
                    lastKeyword = ""
                case let .keyword(name):
                    lastKeyword = name
                case .startOfScope("("):
                    scopeStack.append(token)
                case .startOfScope("{") where lastKeyword == "catch":
                    lastKeyword = ""
                    var localNames = localNames
                    localNames.insert("error") // Implicit error argument
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false)
                    continue
                case .startOfScope("{") where lastKeyword == "in":
                    lastKeyword = ""
                    var localNames = localNames
                    guard let keywordIndex = formatter.index(of: .keyword, before: index),
                        let prevKeywordIndex = formatter.index(of: .keyword, before: keywordIndex),
                        let prevKeywordToken = formatter.token(at: prevKeywordIndex),
                        case .keyword("for") = prevKeywordToken else { return }
                    for token in formatter.tokens[prevKeywordIndex + 1 ..< keywordIndex] {
                        if case let .identifier(name) = token, name != "_" {
                            localNames.insert(token.unescaped())
                        }
                    }
                    index += 1
                    if classOrStatic {
                        assert(isTypeRoot)
                        processBody(at: &index, localNames: localNames, members: classMembers, isTypeRoot: false)
                        classOrStatic = false
                    } else {
                        processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false)
                    }
                    continue
                case .startOfScope(":"),
                     .startOfScope("{") where ["for", "where", "if", "else", "while", "do", "switch"].contains(lastKeyword):
                    lastKeyword = ""
                    fallthrough
                case .startOfScope("{") where lastKeyword == "repeat":
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false)
                    continue
                case .startOfScope("{") where lastKeyword == "var":
                    lastKeyword = ""
                    var prevIndex = index - 1
                    while let token = formatter.token(at: prevIndex), token != .keyword("var") {
                        if token == .operator("=", .infix) || (token.isLvalue && formatter.nextToken(after: prevIndex, where: {
                            !$0.isSpaceOrCommentOrLinebreak && !$0.isStartOfScope
                        }).map({ $0.isRvalue && !$0.isOperator(".") }) == true) {
                            // It's a closure
                            fallthrough
                        }
                        prevIndex -= 1
                    }
                    processAccessors(["get", "set", "willSet", "didSet"], at: &index, localNames: localNames, members: members)
                    continue
                case .startOfScope:
                    index = (formatter.endOfScope(at: index) ?? (formatter.tokens.count - 1)) + 1
                    continue
                case .identifier("self") where !isTypeRoot:
                    if formatter.last(.nonSpaceOrCommentOrLinebreak, before: index)?.isOperator(".") == false,
                        let dotIndex = formatter.index(of: .nonSpaceOrLinebreak, after: index, if: {
                            $0 == .operator(".", .infix)
                        }), let token = formatter.next(.nonSpaceOrLinebreak, after: dotIndex), token.isIdentifier {
                        let name = token.unescaped()
                        if !localNames.contains(name) {
                            unremoved += 1
                        }
                    }
                case .identifier where !isTypeRoot:
                    let name = token.unescaped()
                    if members.contains(name), !localNames.contains(name), !["for", "var", "let"].contains(lastKeyword) {
                        if let lastToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index),
                            lastToken.isOperator(".") {
                            break
                        }
                        if let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: index),
                            nextToken.isIdentifierOrKeyword || nextToken == .delimiter(":") {
                            break
                        }
                        removed += 1
                        index += 1
                        continue
                    }
                case .endOfScope:
                    if let scope = scopeStack.last {
                        assert(token.isEndOfScope(scope))
                        scopeStack.removeLast()
                    } else {
                        assert(token.isEndOfScope(formatter.currentScope(at: index)!))
                        index += 1
                        return
                    }
                default:
                    break
                }
                index += 1
            }
        }
        func processAccessors(_ names: [String], at index: inout Int, localNames: Set<String>, members: Set<String>) {
            var foundAccessors = false
            while let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                if case let .identifier(name) = $0, names.contains(name) { return true } else { return false }
            }), let startIndex = formatter.index(of: .startOfScope("{"), after: nextIndex) {
                foundAccessors = true
                index = startIndex + 1
                var localNames = localNames
                if let parenStart = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex, if: {
                    $0 == .startOfScope("(")
                }), let varToken = formatter.next(.identifier, after: parenStart) {
                    localNames.insert(varToken.unescaped())
                } else {
                    switch formatter.tokens[nextIndex].string {
                    case "set", "willSet":
                        localNames.insert("newValue")
                    case "didSet":
                        localNames.insert("oldValue")
                    default:
                        break
                    }
                }
                processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false)
            }
            if foundAccessors {
                guard let endIndex = formatter.index(of: .endOfScope("}"), after: index) else { return }
                index = endIndex
            } else {
                index += 1
                processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false)
            }
        }
        func processFunction(at index: inout Int, localNames: Set<String>, members: Set<String>) {
            let isSubscript = (formatter.tokens[index] == .keyword("subscript"))
            var localNames = localNames
            guard let startIndex = formatter.index(of: .startOfScope("("), after: index),
                let endIndex = formatter.index(of: .endOfScope(")"), after: startIndex) else { return }
            // Get argument names
            index = startIndex
            while index < endIndex {
                guard let externalNameIndex = formatter.index(of: .identifier, after: index),
                    let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: externalNameIndex)
                else { break }
                let token = formatter.tokens[nextIndex]
                switch token {
                case let .identifier(name) where name != "_":
                    localNames.insert(token.unescaped())
                case .delimiter(":"):
                    let externalNameToken = formatter.tokens[externalNameIndex]
                    if case let .identifier(name) = externalNameToken, name != "_" {
                        localNames.insert(externalNameToken.unescaped())
                    }
                default:
                    break
                }
                index = formatter.index(of: .delimiter(","), after: index) ?? endIndex
            }
            guard let bodyStartIndex = formatter.index(after: endIndex, where: {
                switch $0 {
                case .startOfScope("{"): // What we're looking for
                    return true
                case .keyword("throws"),
                     .keyword("rethrows"),
                     .keyword("where"),
                     .keyword("is"):
                    return false // Keep looking
                case .keyword:
                    return true // Not valid between end of arguments and start of body
                default:
                    return false // Keep looking
                }
            }), formatter.tokens[bodyStartIndex] == .startOfScope("{") else {
                return
            }
            if isSubscript {
                index = bodyStartIndex
                processAccessors(["get", "set"], at: &index, localNames: localNames, members: members)
            } else {
                index = bodyStartIndex + 1
                processBody(at: &index, localNames: localNames, members: members, isTypeRoot: false)
            }
        }
        var index = 0
        processBody(at: &index, localNames: ["init"], members: [], isTypeRoot: false)
        return removed > unremoved // if both zero, should be false
    }()

    return options
}
