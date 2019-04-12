//
//  Lexer.swift
//  Parsing
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: interface

public enum Token: Equatable {
    case assign // = operator
    case plus // + operator
    case identifier(String) // letter followed by one or more alphanumeric chars
    case number(Double) // any valid floating point number
    case string(String) // a string literal surrounded by ""
    case `let` // let keyword
    case print // print keyword
}

public enum LexerError: Error, Equatable {
    case unrecognizedInput(String)
}

public func tokenize(_ input: String) throws -> [Token] {
    let whitespace = try NSRegularExpression(pattern: "(\\s|\\n)+")
    let assign = try NSRegularExpression(pattern: "=")
    let plus = try NSRegularExpression(pattern: "\\+")
    let identifier = try NSRegularExpression(pattern: "[a-z][a-z0-9]*", options: .caseInsensitive)
    let number = try NSRegularExpression(pattern: "[0-9.]+")
    let string = try NSRegularExpression(pattern: "\"(\\\\\"|\\\\\\\\|[^\"\\\\])*\"") // !!!

    // this part is nasty because NSRange indices don't map directly to String indices
    var range = NSRange(location: 0, length: input.utf16.count)
    func readToken(_ regex: NSRegularExpression) -> String? {
        guard let match = regex.firstMatch(in: input, options: .anchored, range: range) else {
            return nil
        }
        range.location += match.range.length
        range.length -= match.range.length
        return (input as NSString).substring(with: match.range)
    }

    func readToken() -> Token? {
        _ = readToken(whitespace) // skip whitespace
        if readToken(assign) != nil {
            return .assign
        }
        if readToken(plus) != nil {
            return .plus
        }
        if let name = readToken(identifier) {
            switch name {
            case "let":
                return .let
            case "print":
                return .print
            default:
                return .identifier(name)
            }
        }
        let start = range
        if let digits = readToken(number), let double = Double(digits) {
            return .number(double)
        } else {
            range = start
        }
        if let string = readToken(string) {
            let unescapedString = String(string.dropFirst().dropLast())
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
            return .string(unescapedString)
        }
        return nil
    }

    var tokens: [Token] = []
    while let token = readToken() {
        tokens.append(token)
    }
    if range.length != 0 {
        throw LexerError.unrecognizedInput((input as NSString).substring(with: range))
    }
    return tokens
}
