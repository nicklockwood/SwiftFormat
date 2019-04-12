//
//  Transpiler.swift
//  Parsing
//
//  Created by Nick Lockwood on 19/03/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: interface

public enum TranspilerError: Error, Equatable {
    case undefinedVariable(String)
}

public func transpile(_ program: [Statement]) throws -> String {
    let context = Context()
    for statement in program {
        try statement.transpile(in: context)
    }
    return context.output
}

// MARK: implementation

enum Type {
    case number
    case string
}

class Context {
    var variables: [String: Type] = [:]
    var output = ""
}

extension Statement {

    func transpile(in context: Context) throws {
        switch self {
        case .declaration(name: let name, value: let expression):
            let (type, value) = try expression.transpile(in: context)
            context.variables[name] = type
            // TODO: escape reserved names
            context.output.append("let \(name) = \(value)\n")
        case .print(let expression):
            let (_, value) = try expression.transpile(in: context)
            context.output.append("print(\(value))\n")
        }
    }
}

extension Expression {

    func transpile(in context: Context) throws -> (Type, String) {
        switch self {
        case .number(let double):
            return (.number, String(double))
        case .string(let string):
            let escapedString = string
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return (.string, "\"\(escapedString)\"")
        case .variable(let name):
            guard let type = context.variables[name] else {
                throw TranspilerError.undefinedVariable(name)
            }
            // TODO: escape reserved names
            return (type, name)
        case .addition(lhs: let expression1, rhs: let expression2):
            let (type1, lhs) = try expression1.transpile(in: context)
            let (type2, rhs) = try expression2.transpile(in: context)
            switch (type1, type2) {
            case (.number, .number):
                return (.number, "\(lhs) + \(rhs)")
            case (.string, _), (_, .string):
                return (.string, "\"\\(\(lhs))\\(\(rhs))\"")
            }
        }
    }
}
