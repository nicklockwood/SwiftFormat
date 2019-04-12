//
//  Parser.swift
//  Parsing
//
//  Created by Nick Lockwood on 03/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: interface

public enum Statement: Equatable {
    case declaration(name: String, value: Expression)
    case print(Expression)
}

public indirect enum Expression: Equatable {
    case number(Double)
    case string(String)
    case variable(String)
    case addition(lhs: Expression, rhs: Expression)
}

public enum ParserError: Error, Equatable {
    case unexpectedToken(Token)
}

public func parse(_ input: String) throws -> [Statement] {
    var tokens = try ArraySlice(tokenize(input))
    var statements: [Statement] = []
    while let statement = tokens.readStatement() {
        statements.append(statement)
    }
    if let token = tokens.first {
        throw ParserError.unexpectedToken(token)
    }
    return statements
}

// MARK: implementation

private extension ArraySlice where Element == Token {

    mutating func readOperand() -> Expression? {
        let start = self
        switch self.popFirst() {
        case Token.identifier(let variable)?:
            return Expression.variable(variable)
        case Token.number(let double)?:
            return Expression.number(double)
        case Token.string(let string)?:
            return Expression.string(string)
        default:
            self = start
            return nil
        }
    }

    mutating func readExpression() -> Expression? {
        guard let lhs = readOperand() else {
            return nil
        }
        let start = self
        guard self.popFirst() == .plus, let rhs = readExpression() else {
            self = start
            return lhs
        }
        return Expression.addition(lhs: lhs, rhs: rhs)
    }

    mutating func readDeclaration() -> Statement? {
        let start = self
        guard self.popFirst() == .let,
            case Token.identifier(let name)? = self.popFirst(),
            self.popFirst() == .assign,
            let value = self.readExpression()
        else {
            self = start
            return nil
        }
        return Statement.declaration(name: name, value: value)
    }

    mutating func readPrintStatement() -> Statement? {
        let start = self
        guard self.popFirst() == .print, let value = self.readExpression() else {
            self = start
            return nil
        }
        return Statement.print(value)
    }

    mutating func readStatement() -> Statement? {
        return self.readDeclaration() ?? self.readPrintStatement()
    }
}
