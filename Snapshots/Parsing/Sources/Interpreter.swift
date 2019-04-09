//
//  Interpreter.swift
//  ParsingTests
//
//  Created by Nick Lockwood on 04/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: interface

public enum RuntimeError: Error, Equatable {
    case undefinedVariable(String)
}

public func evaluate(_ program: [Statement]) throws -> String {
    let environment = Environment()
    for statement in program {
        try statement.evaluate(in: environment)
    }
    return environment.output
}

// MARK: implementation

enum Value: CustomStringConvertible, Equatable {
    case number(Double)
    case string(String)

    var description: String {
        switch self {
        case .number(let double):
            return String(format: "%g", double)
        case .string(let string):
            return string
        }
    }
}

class Environment {
    var variables: [String: Value] = [:]
    var output = ""
}

extension Statement {

    func evaluate(in environment: Environment) throws {
        switch self {
        case .declaration(name: let name, value: let expression):
            let value = try expression.evaluate(in: environment)
            environment.variables[name] = value
        case .print(let expression):
            let value = try expression.evaluate(in: environment)
            environment.output.append("\(value)\n")
        }
    }
}

extension Expression {

    func evaluate(in environment: Environment) throws -> Value {
        switch self {
        case .number(let double):
            return .number(double)
        case .string(let string):
            return .string(string)
        case .variable(let name):
            guard let value = environment.variables[name] else {
                throw RuntimeError.undefinedVariable(name)
            }
            return value
        case .addition(lhs: let expression1, rhs: let expression2):
            let value1 = try expression1.evaluate(in: environment)
            let value2 = try expression2.evaluate(in: environment)
            switch (value1, value2) {
            case (.number(let lhs), .number(let rhs)):
                return .number(lhs + rhs)
            case (.string, _), (_, .string):
                return .string("\(value1)\(value2)")
            }
        }
    }
}
