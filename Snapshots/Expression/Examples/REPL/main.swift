//
//  main.swift
//  REPL
//
//  Created by Nick Lockwood on 23/02/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

// Prevent control characters confusing expression
private let start = UnicodeScalar(63232)!
private let end = UnicodeScalar(63235)!
private let cursorCharacters = CharacterSet(charactersIn: start ... end)

// Previously defined variables
private var variables = [String: Any]()

func evaluate(_ parsed: ParsedExpression) throws -> Any {
    let expression = AnyExpression(parsed, constants: variables)
    return try expression.evaluate()
}

while true {
    print("> ", terminator: "")
    guard var input = readLine() else { break }
    input = String(input.unicodeScalars.filter { !cursorCharacters.contains($0) })
    do {
        var parsed = Expression.parse(input)
        if parsed.symbols.contains(where: { $0 == .infix("=") || $0 == .prefix("=") }) {
            let range = input.range(of: " = ") ?? input.range(of: "= ") ?? input.range(of: "=")!
            parsed = Expression.parse(String(input[range.upperBound...]))
            let identifier = input[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            let symbols = Expression.parse(identifier).symbols
            if symbols.count == 1 {
                switch symbols.first! {
                case let .variable(name):
                    variables[name] = try evaluate(parsed)
                case let .function(name, _):
                    let expression = AnyExpression(parsed, constants: variables)
                    variables[name] = { (args: [Any]) throws -> Any in
                        try expression.evaluate()
                    }
                default:
                    print("error: Invalid variable name '\(identifier)'")
                }
            } else {
                print("error: Invalid left side for = expression: '\(identifier)'")
            }
        } else {
            try print(AnyExpression.stringify(evaluate(parsed)))
        }
    } catch {
        print("error: \(error)")
    }
}
