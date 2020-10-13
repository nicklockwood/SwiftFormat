//
//  repl.swift
//  REPL
//
//  Created by Nick Lockwood on 02/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: API

public class State {
    fileprivate var variables = [String: Any]()
}

public func evaluate(_ input: String, state: State) throws -> Any? {
    let match = try command.match(input)
    return match.transform { label, values in
        switch label {
        case .bool:
            return values[0] as! String == "true"
        case .number:
            return Double(values[0] as! String) ?? 0
        case .string:
            return values[0] as! String
        case .variable:
            return state.variables[values[0] as! String] ?? (nil as Any? as Any)
        case .factor:
            if values[0] as? String == "-" {
                guard let value = values[1] as? Double else {
                    return Double.nan
                }
                return -value
            }
            return values[0]
        case .term, .expression:
            if values.count == 1 {
                return values[0]
            }
            let op = values[1] as! String
            guard let lhs = values[0] as? Double,
                  let rhs = values[2] as? Double
            else {
                if op == "+", values[0] is String || values[2] is String {
                    return "\(values[0])\(values[2])"
                }
                return Double.nan
            }
            switch op {
            case "+":
                return lhs + rhs
            case "-":
                return lhs - rhs
            case "*":
                return lhs * rhs
            case "/":
                return lhs / rhs
            default:
                preconditionFailure()
            }
        case .assignment:
            let lhs = values[0] as! String
            let rhs = values[1]
            state.variables[lhs] = rhs
            return rhs
        case .command:
            return values[0]
        }
    }
}

// MARK: Implementation

private enum Label: String {
    case bool
    case number
    case string
    case variable
    case factor
    case term
    case expression
    case assignment
    case command
}

// boolean
private let bool: Consumer<Label> = .label(.bool, "true" | "false")

// number
private let zeroToNine: Consumer<Label> = .character(in: "0" ... "9")
private let oneToNine: Consumer<Label> = .character(in: "1" ... "9")
private let integer: Consumer<Label> = "0" | [oneToNine, .zeroOrMore(zeroToNine)]
private let decimal: Consumer<Label> = [integer, .optional([".", .oneOrMore(zeroToNine)])]
private let number: Consumer<Label> = .label(.number, .flatten(decimal))

// string
private let string: Consumer<Label> = .label(.string, .flatten([
    .discard("\""),
    .zeroOrMore(.any([
        .replace("\\\"", "\""),
        .replace("\\\\", "\\"),
        .replace("\\n", "\n"),
        .replace("\\r", "\r"),
        .replace("\\t", "\t"),
        .discard("\\"),
        .anyCharacter(except: "\"", "\\"),
    ])),
    .discard("\""),
]))

// identifier
private let alpha: Consumer<Label> = .character(in: .letters)
private let alphanumeric: Consumer<Label> = .character(in: .alphanumerics)
private let identifier: Consumer<Label> = .flatten([alpha, .zeroOrMore(alphanumeric)])

// rvalues
private let literal: Consumer<Label> = number | bool | string
private let variable: Consumer<Label> = .label(.variable, identifier)
private let subexpression: Consumer<Label> = [
    .discard("("), .reference(.expression), .discard(")"),
]
private let factor: Consumer<Label> = .label(.factor, [
    .optional("-"), literal | variable | subexpression,
])
private let term: Consumer<Label> = .label(.term, [
    factor, .optional(["*" | "/", .reference(.term)]),
])
private let expression: Consumer<Label> = .label(.expression, [
    term, .optional(["+" | "-", .reference(.expression)]),
])

// assignment
private let assignment: Consumer<Label> = .label(.assignment, [
    identifier, .discard("="), expression,
])

// comments and white space
private let space: Consumer<Label> = .character(in: .whitespacesAndNewlines)
private let comment1: Consumer<Label> = ["//", .zeroOrMore(.anyCharacter(except: "\r", "\n"))]
private let comment2: Consumer<Label> = ["/*", .zeroOrMore([.not("*/"), .anyCharacter()]), "*/"]
private let spaceOrComment: Consumer<Label> = .discard(.zeroOrMore(space | comment1 | comment2))

// root
private let command: Consumer<Label> =
    .label(.command, .ignore(spaceOrComment, in: assignment | expression))
