//
//  PreferNonfailableStringConversions.swift
//  SwiftFormat
//
//  Created by Yang Bai on 17/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace failable UTF-8 String/Data conversions with their nonfailable equivalents
    static let preferNonfailableStringConversions = FormatRule(
        help: """
        Replace unwrapped `data(using: .utf8)` and `String(data:encoding: .utf8)` conversions \
        with the nonfailable `Data(_:)` and `String(decoding:as:)` equivalents.
        """,
        disabledByDefault: true
    ) { formatter in
        formatter.forEachToken(where: { $0 == .identifier("data") || $0 == .identifier("String") }) { i, _ in
            guard let conversion = formatter.failableUTF8Conversion(at: i) else { return }
            let range = conversion.range

            if formatter.token(at: range.upperBound + 1) == .operator("!", .postfix) {
                // `string.data(using: .utf8)!` or `String(data: data, encoding: .utf8)!`
                formatter.removeToken(at: range.upperBound + 1)
                formatter.replaceWithNonfailableConversion(conversion)
            } else if let (tryIndex, closeParenIndex) = formatter.tryUnwrapIndices(around: range),
                      formatter.isSimpleUTF8ConversionOperand(conversion.operand)
            {
                // `try XCTUnwrap(...)` or `try #require(...)`. The `try` is removed too, so the
                // operand mustn't contain any calls, property getters or subscripts that might throw.
                formatter.removeTokens(in: range.upperBound + 1 ... closeParenIndex)
                formatter.replaceWithNonfailableConversion(conversion)
                formatter.removeTokens(in: tryIndex ..< range.lowerBound)
            } else if let (guardIndex, letIndex, endOfElseScope) = formatter.guardIndices(around: range) {
                // `guard let string = String(data: data, encoding: .utf8) else { ... }`
                formatter.removeTokens(in: range.upperBound + 1 ... endOfElseScope)
                formatter.replaceWithNonfailableConversion(conversion)
                formatter.removeTokens(in: guardIndex ..< letIndex)
            }
        }
    } examples: {
        """
        ```diff
        - let data = string.data(using: .utf8)!
        + let data = Data(string.utf8)

        - let string = String(data: data, encoding: .utf8)!
        + let string = String(decoding: data, as: UTF8.self)

        - let data = try XCTUnwrap(string.data(using: .utf8))
        + let data = Data(string.utf8)

        - guard let string = String(data: data, encoding: .utf8) else { return }
        + let string = String(decoding: data, as: UTF8.self)
        ```
        """
    }
}

extension Formatter {
    /// A failable UTF-8 conversion between `String` and `Data`
    enum FailableUTF8Conversion {
        /// `receiver.data(using: .utf8)`
        case data(receiver: Range<Int>, closeParenIndex: Int)
        /// `String(data: value, encoding: .utf8)`
        case string(stringIndex: Int, dataLabelIndex: Int, value: ClosedRange<Int>,
                    encodingLabelIndex: Int, encoding: ClosedRange<Int>, closeParenIndex: Int)

        var range: ClosedRange<Int> {
            switch self {
            case let .data(receiver, closeParenIndex):
                return receiver.lowerBound ... closeParenIndex
            case let .string(stringIndex, _, _, _, _, closeParenIndex):
                return stringIndex ... closeParenIndex
            }
        }

        /// The range of the string or data being converted
        var operand: Range<Int> {
            switch self {
            case let .data(receiver, _):
                return receiver
            case let .string(_, _, value, _, _, _):
                return value.lowerBound ..< value.upperBound + 1
            }
        }
    }

    /// Parses a failable UTF-8 conversion at the `data` or `String` identifier at the given index
    func failableUTF8Conversion(at i: Int) -> FailableUTF8Conversion? {
        guard let openParenIndex = index(of: .nonSpaceOrComment, after: i),
              tokens[openParenIndex] == .startOfScope("("),
              let closeParenIndex = endOfScope(at: openParenIndex),
              !tokens[i ... closeParenIndex].contains(where: \.isComment)
        else { return nil }

        let arguments = parseFunctionCallArguments(startOfScope: openParenIndex)
        let utf8 = [".utf8", "String.Encoding.utf8"]
        let previousIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i)

        switch tokens[i] {
        case .identifier("data"):
            guard let dotIndex = previousIndex,
                  tokens[dotIndex] == .operator(".", .infix),
                  !tokens[dotIndex ..< i].contains(where: \.isComment),
                  arguments.count == 1,
                  arguments[0].label == "using",
                  utf8.contains(arguments[0].value),
                  let receiverStart = startOfUTF8ConversionReceiver(endingAt: dotIndex),
                  receiverStart < dotIndex
            else { return nil }

            return .data(receiver: receiverStart ..< dotIndex, closeParenIndex: closeParenIndex)

        case .identifier("String"):
            // Exclude qualified names like `Swift.String`
            guard previousIndex.map({ tokens[$0] != .operator(".", .infix) }) ?? true,
                  arguments.count == 2,
                  arguments[0].label == "data",
                  let dataLabelIndex = arguments[0].labelIndex,
                  // `String(decoding:as:)` is generic, so an implicit member like `.init()` wouldn't resolve
                  !tokens[arguments[0].valueRange.lowerBound].isOperator("."),
                  arguments[1].label == "encoding",
                  let encodingLabelIndex = arguments[1].labelIndex,
                  utf8.contains(arguments[1].value)
            else { return nil }

            return .string(
                stringIndex: i,
                dataLabelIndex: dataLabelIndex,
                value: arguments[0].valueRange,
                encodingLabelIndex: encodingLabelIndex,
                encoding: arguments[1].valueRange,
                closeParenIndex: closeParenIndex
            )

        default:
            return nil
        }
    }

    /// The start of the receiver of a `.data(using:)` call whose dot is at the given index.
    /// Returns nil if the receiver can't be wrapped in `Data(...)`, e.g. because it uses optional chaining.
    func startOfUTF8ConversionReceiver(endingAt dotIndex: Int) -> Int? {
        guard let start = startOfMemberCallReceiver(endingAt: dotIndex) else { return nil }
        guard tokens[start].isOperator(".") else { return start }

        // The receiver walk stops at the dot after a string literal root,
        // e.g. `"foo".data(using: .utf8)` or `"foo".lowercased().data(using: .utf8)`
        guard let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: start),
              tokens[prevIndex].isStringDelimiter
        else { return nil }
        return startOfScope(at: prevIndex)
    }

    /// Whether the given operand is a single identifier or a string literal without interpolation,
    /// so it can't contain a call, property getter or subscript that might throw
    func isSimpleUTF8ConversionOperand(_ operand: Range<Int>) -> Bool {
        guard let lastIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: operand.upperBound) else {
            return false
        }
        if lastIndex == operand.lowerBound {
            return tokens[lastIndex].isIdentifier
        }
        return tokens[operand.lowerBound].isStringDelimiter
            && endOfScope(at: operand.lowerBound) == lastIndex
            && !tokens[operand].contains(.startOfScope("("))
    }

    /// Replaces the given failable conversion with the nonfailable equivalent
    func replaceWithNonfailableConversion(_ conversion: FailableUTF8Conversion) {
        switch conversion {
        case let .data(receiver, closeParenIndex):
            // `receiver.data(using: .utf8)` -> `Data(receiver.utf8)`
            replaceTokens(in: receiver.upperBound ... closeParenIndex, with: [
                .operator(".", .infix), .identifier("utf8"), .endOfScope(")"),
            ])
            insert([.identifier("Data"), .startOfScope("(")], at: receiver.lowerBound)

        case let .string(_, dataLabelIndex, _, encodingLabelIndex, encoding, _):
            // `String(data: value, encoding: .utf8)` -> `String(decoding: value, as: UTF8.self)`
            replaceTokens(in: encoding, with: [
                .identifier("UTF8"), .operator(".", .infix), .identifier("self"),
            ])
            replaceToken(at: encodingLabelIndex, with: .identifier("as"))
            replaceToken(at: dataLabelIndex, with: .identifier("decoding"))
        }
    }

    /// Returns the indices of the `try` keyword and the closing paren if the given range is the only
    /// argument of a `try XCTUnwrap(...)` or `try #require(...)` call, and that call is the whole expression.
    func tryUnwrapIndices(around range: ClosedRange<Int>) -> (tryIndex: Int, closeParenIndex: Int)? {
        guard let openParenIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: range.lowerBound),
              tokens[openParenIndex] == .startOfScope("("),
              let closeParenIndex = endOfScope(at: openParenIndex),
              index(of: .nonSpaceOrCommentOrLinebreak, after: range.upperBound) == closeParenIndex,
              let unwrapIndex = index(of: .nonSpaceOrComment, before: openParenIndex),
              [.identifier("XCTUnwrap"), .keyword("#require")].contains(tokens[unwrapIndex]),
              let tryIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: unwrapIndex),
              tokens[tryIndex] == .keyword("try"),
              endOfExpression(at: openParenIndex, upTo: []) == closeParenIndex,
              !tokens[tryIndex ... closeParenIndex].contains(where: \.isComment)
        else { return nil }

        return (tryIndex, closeParenIndex)
    }

    /// Returns the indices of the `guard` keyword, the `let` or `var` keyword, and the end of the
    /// `else` scope if the given range is the value of the only condition in a guard statement,
    /// e.g. `guard let foo = <range> else { ... }`.
    func guardIndices(around range: ClosedRange<Int>) -> (guardIndex: Int, letIndex: Int, endOfElseScope: Int)? {
        guard let equalsIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: range.lowerBound),
              tokens[equalsIndex] == .operator("=", .infix),
              let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: equalsIndex),
              tokens[nameIndex].isIdentifier,
              let letIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: nameIndex),
              [.keyword("let"), .keyword("var")].contains(tokens[letIndex]),
              let guardIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: letIndex),
              tokens[guardIndex] == .keyword("guard"),
              let elseIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: range.upperBound),
              tokens[elseIndex] == .keyword("else"),
              let startOfElseScope = index(of: .nonSpaceOrCommentOrLinebreak, after: elseIndex),
              tokens[startOfElseScope] == .startOfScope("{"),
              let endOfElseScope = endOfScope(at: startOfElseScope),
              !tokens[guardIndex ... endOfElseScope].contains(where: \.isComment)
        else { return nil }

        return (guardIndex, letIndex, endOfElseScope)
    }
}
