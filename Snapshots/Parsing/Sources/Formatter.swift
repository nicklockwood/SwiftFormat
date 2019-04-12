//
//  Formatter.swift
//  Parsing
//
//  Created by Nick Lockwood on 04/09/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: interface

public func format(_ program: [Statement]) -> String {
    var output = ""
    for statement in program {
        output.append(statement.description + "\n")
    }
    return output
}

// MARK: implementation

extension Statement: CustomStringConvertible {

    public var description: String {
        switch self {
        case .declaration(name: let name, value: let expression):
            return "let \(name) = \(expression)"
        case .print(let expression):
            return "print \(expression)"
        }
    }
}

extension Expression: CustomStringConvertible {

    public var description: String {
        switch self {
        case .number(let double):
            return String(format: "%g", double)
        case .string(let string):
            let escapedString = string
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escapedString)\""
        case .variable(let name):
            return name
        case .addition(lhs: let lhs, rhs: let rhs):
            return "\(lhs) + \(rhs)"
        }
    }
}
