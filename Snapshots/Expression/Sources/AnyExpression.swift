//
//  AnyExpression.swift
//  Expression
//
//  Version 0.12.12
//
//  Created by Nick Lockwood on 18/04/2017.
//  Copyright © 2017 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Expression
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

/// Wrapper for Expression that works with any type of value
public struct AnyExpression: CustomStringConvertible {
    private let expression: Expression
    private let describer: () -> String
    private let evaluator: () throws -> Any

    /// Evaluator for individual symbols
    public typealias SymbolEvaluator = (_ args: [Any]) throws -> Any

    /// Symbols that make up an expression
    public typealias Symbol = Expression.Symbol

    /// Runtime error when parsing or evaluating an expression
    public typealias Error = Expression.Error

    /// Options for configuring an expression
    public typealias Options = Expression.Options

    /// Creates an AnyExpression instance from a string
    /// Optionally accepts some or all of:
    /// - A set of options for configuring expression behavior
    /// - A dictionary of constants for simple static values (including arrays)
    /// - A dictionary of symbols, for implementing custom functions and operators
    public init(
        _ expression: String,
        options: Options = .boolSymbols,
        constants: [String: Any] = [:],
        symbols: [Symbol: SymbolEvaluator] = [:]
    ) {
        self.init(
            Expression.parse(expression),
            options: options,
            constants: constants,
            symbols: symbols
        )
    }

    /// Alternative constructor that accepts a pre-parsed expression
    public init(
        _ expression: ParsedExpression,
        options: Options = [],
        constants: [String: Any] = [:],
        symbols: [Symbol: SymbolEvaluator] = [:]
    ) {
        // Options
        let pureSymbols = options.contains(.pureSymbols)

        self.init(
            expression,
            options: options,
            impureSymbols: { symbol in
                switch symbol {
                case let .variable(name):
                    if constants[name] == nil {
                        return symbols[symbol]
                    }
                case let .array(name):
                    // TODO: should we support overloading variables and arrays like this?
                    if !(constants[name].map(AnyExpression.isSubscriptable) ?? false) {
                        return symbols[symbol]
                    }
                default:
                    if !pureSymbols {
                        return symbols[symbol]
                    }
                }
                return nil
            },
            pureSymbols: { symbol in
                switch symbol {
                case let .variable(name):
                    return constants[name].map { value in { _ in value } }
                case let .array(name) where constants[name] != nil:
                    return nil // Ensure constant array takes precedence over symbols
                default:
                    return symbols[symbol]
                }
            }
        )
    }

    /// Alternative constructor for advanced usage
    /// Allows for dynamic symbol lookup or generation without any performance overhead
    /// Note that standard library symbols are all enabled by default - to disable them
    /// return `{ _ in throw AnyExpression.Error.undefinedSymbol(symbol) }` from your lookup function
    public init(
        _ expression: ParsedExpression,
        impureSymbols: (Symbol) -> SymbolEvaluator?,
        pureSymbols: (Symbol) -> SymbolEvaluator? = { _ in nil }
    ) {
        self.init(
            expression,
            options: .boolSymbols,
            impureSymbols: impureSymbols,
            pureSymbols: pureSymbols
        )
    }

    /// Alternative constructor with only pure symbols
    public init(_ expression: ParsedExpression, pureSymbols: (Symbol) -> SymbolEvaluator?) {
        self.init(expression, impureSymbols: { _ in nil }, pureSymbols: pureSymbols)
    }

    /// Private initializer implementation
    private init(
        _ expression: ParsedExpression,
        options: Options,
        impureSymbols: (Symbol) -> SymbolEvaluator?,
        pureSymbols: (Symbol) -> SymbolEvaluator?
    ) {
        let box = NanBox()

        func loadNumber(_ arg: Double) -> Double? {
            return box.loadIfStored(arg).map {
                ($0 as? NSNumber).map(Double.init(truncating:))
            } ?? arg
        }
        func argsToDouble(_ args: [Double], for symbol: Symbol) throws -> [Double] {
            return try args.map {
                guard let doubleValue = loadNumber($0) else {
                    throw Error.typeMismatch(symbol, args.map(box.load))
                }
                return doubleValue
            }
        }
        func equalArgs(_ lhs: Double, _ rhs: Double) throws -> Bool {
            switch (AnyExpression.unwrap(box.load(lhs)), AnyExpression.unwrap(box.load(rhs))) {
            case (nil, nil):
                return true
            case (nil, _),
                 (_, nil):
                return false
            case let (lhs as Double, rhs as Double):
                return lhs == rhs
            case let (lhs as AnyHashable, rhs as AnyHashable):
                return lhs == rhs
            case let (lhs as [AnyHashable], rhs as [AnyHashable]):
                return lhs == rhs
            case let (lhs as [AnyHashable: AnyHashable], rhs as [AnyHashable: AnyHashable]):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable), rhs as (AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable, AnyHashable),
                      rhs as (AnyHashable, AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable),
                      rhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable),
                      rhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable),
                      rhs as (AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable, AnyHashable)):
                return lhs == rhs
            case let (lhs?, rhs?):
                throw Error.typeMismatch(.infix("=="), [lhs, rhs])
            }
        }
        func unwrapString(_ name: String) -> String? {
            guard name.count >= 2, "'\"".contains(name.first!) else {
                return nil
            }
            return String(name.dropFirst().dropLast())
        }
        func arrayEvaluator(for symbol: Symbol, _ value: Any) -> SymbolEvaluator {
            // TODO: should arrayEvaluator call the `.infix("[]")` implementation,
            // rather than vice-versa?
            switch value {
            case let array as _Array:
                return { args in
                    switch args[0] {
                    case let index as NSNumber: // TODO: should Bool be explicitly disallowed?
                        let values = array.values
                        let index = Int(truncating: index) // TODO: should this use Int(exactly:)?
                        if (0 ..< values.count).contains(index) {
                            return values[index]
                        }
                        throw Error.arrayBounds(symbol, Double(index))
                    case let range as _Range:
                        return try range.slice(of: array, for: symbol)
                    case let index:
                        throw Error.typeMismatch(symbol, [array, index])
                    }
                }
            case let dictionary as _Dictionary:
                return { args in
                    guard let value = dictionary.value(for: args[0]) else {
                        throw Error.typeMismatch(symbol, [dictionary, args[0]])
                    }
                    return value
                }
            case let string as _String:
                return { args in
                    switch args[0] {
                    case let offset as NSNumber:
                        let substring = string.substring
                        let offset = Int(truncating: offset)
                        guard (0 ..< substring.count).contains(offset) else {
                            throw Error.stringBounds(String(substring), offset)
                        }
                        return substring[substring.index(substring.startIndex, offsetBy: offset)]
                    case let index as String.Index:
                        let substring = string.substring
                        guard substring.indices.contains(index) else {
                            throw Error.stringBounds(substring, index)
                        }
                        return substring[index]
                    case let range as _Range:
                        return try range.slice(of: string, for: symbol)
                    case let index:
                        throw Error.typeMismatch(symbol, [string, index])
                    }
                }
            case let value:
                return { throw Error.typeMismatch(symbol, [value] + $0) }
            }
        }
        func funcEvaluator(for symbol: Symbol, _ value: Any) -> Expression.SymbolEvaluator? {
            // TODO: should funcEvaluator call the `.infix("()")` implementation?
            switch value {
            case let fn as SymbolEvaluator:
                return { args in
                    try box.store(fn(args.map(box.load)))
                }
            case let fn as Expression.SymbolEvaluator:
                return { args in
                    try fn(argsToDouble(args, for: symbol))
                }
            default:
                return nil
            }
        }

        // Set description based on the parsed expression, prior to
        // performing optimizations. This avoids issues with inlined
        // constants and string literals being converted to `nan`
        describer = { expression.description }

        // Options
        let boolSymbols = options.contains(.boolSymbols) ? Expression.boolSymbols : [:]
        let shouldOptimize = !options.contains(.noOptimize)

        // Evaluators
        func defaultEvaluator(for symbol: Symbol) -> Expression.SymbolEvaluator? {
            if let fn = AnyExpression.standardSymbols[symbol] {
                return fn
            } else if let fn = Expression.mathSymbols[symbol] {
                switch symbol {
                case .infix("+"):
                    return { args in
                        switch (box.load(args[0]), box.load(args[1])) {
                        case let (lhs as Double, rhs as Double):
                            return lhs + rhs
                        case let (lhs as _String, any):
                            guard let rhs = AnyExpression.unwrap(any) else {
                                throw Error.typeMismatch(symbol, [lhs, any])
                            }
                            return box.store("\(lhs)\(AnyExpression.stringify(rhs))")
                        case let (any, rhs as _String):
                            guard let lhs = AnyExpression.unwrap(any) else {
                                throw Error.typeMismatch(symbol, [any, rhs])
                            }
                            return box.store("\(AnyExpression.stringify(lhs))\(rhs)")
                        case let (lhs as _Array, rhs as _Array):
                            return box.store(lhs.values + rhs.values)
                        case let (lhs as NSNumber, rhs as NSNumber):
                            return Double(truncating: lhs) + Double(truncating: rhs)
                        case let (lhs, rhs):
                            throw Error.typeMismatch(symbol, [lhs, rhs])
                        }
                    }
                default:
                    return { args in
                        // We potentially lose precision by converting all numbers to doubles
                        // TODO: find alternative approach that doesn't lose precision
                        try fn(argsToDouble(args, for: symbol))
                    }
                }
            } else if let fn = boolSymbols[symbol] {
                switch symbol {
                case .infix("=="):
                    return { try equalArgs($0[0], $0[1]) ? NanBox.trueValue : NanBox.falseValue }
                case .infix("!="):
                    return { try equalArgs($0[0], $0[1]) ? NanBox.falseValue : NanBox.trueValue }
                case .infix("?:"):
                    return { args in
                        guard args.count == 3 else {
                            throw Error.undefinedSymbol(symbol)
                        }
                        guard let doubleValue = loadNumber(args[0]) else {
                            throw Error.typeMismatch(symbol, args.map(box.load))
                        }
                        return doubleValue != 0 ? args[1] : args[2]
                    }
                default:
                    return { args in
                        try fn(argsToDouble(args, for: symbol)) == 0 ?
                            NanBox.falseValue : NanBox.trueValue
                    }
                }
            } else {
                switch symbol {
                case .infix("[]"):
                    return { args in
                        let fn = arrayEvaluator(for: symbol, box.load(args[0]))
                        return try box.store(fn([box.load(args[1])]))
                    }
                case .infix("..."):
                    return { args in
                        switch (box.load(args[0]), box.load(args[1])) {
                        case let (lhs as NSNumber, rhs as NSNumber):
                            let lhs = Int(truncating: lhs), rhs = Int(truncating: rhs)
                            guard lhs <= rhs else { throw Error.invalidRange(lhs, rhs) }
                            return box.store(lhs ... rhs)
                        case let (lhs as String.Index, rhs as String.Index):
                            guard lhs <= rhs else { throw Error.invalidRange(lhs, rhs) }
                            return box.store(lhs ... rhs)
                        case let (lhs, rhs):
                            throw Error.typeMismatch(symbol, [lhs, rhs])
                        }
                    }
                case .postfix("..."):
                    return { args in
                        switch box.load(args[0]) {
                        case let index as NSNumber:
                            return box.store(Int(truncating: index)...)
                        case let index as String.Index:
                            return box.store(index...)
                        case let index:
                            throw Error.typeMismatch(symbol, [index])
                        }
                    }
                case .prefix("..."):
                    return { args in
                        switch box.load(args[0]) {
                        case let index as NSNumber:
                            return box.store(...Int(truncating: index))
                        case let index as String.Index:
                            return box.store(...index)
                        case let index:
                            throw Error.typeMismatch(symbol, [index])
                        }
                    }
                case .infix("..<"):
                    return { args in
                        switch (box.load(args[0]), box.load(args[1])) {
                        case let (lhs as NSNumber, rhs as NSNumber):
                            let lhs = Int(truncating: lhs), rhs = Int(truncating: rhs)
                            guard lhs < rhs else { throw Error.invalidRange(lhs, rhs) }
                            return box.store(lhs ..< rhs)
                        case let (lhs as String.Index, rhs as String.Index):
                            guard lhs < rhs else { throw Error.invalidRange(lhs, rhs) }
                            return box.store(lhs ..< rhs)
                        case let (lhs, rhs):
                            throw Error.typeMismatch(symbol, [lhs, rhs])
                        }
                    }
                case .prefix("..<"):
                    return { args in
                        switch box.load(args[0]) {
                        case let index as NSNumber:
                            return box.store(..<Int(truncating: index))
                        case let index as String.Index:
                            return box.store(..<index)
                        case let index:
                            throw Error.typeMismatch(symbol, [index])
                        }
                    }
                case .function("[]", _):
                    return { box.store($0.map(box.load)) }
                case let .variable(name):
                    guard let string = unwrapString(name) else {
                        return { _ in throw Error.undefinedSymbol(symbol) }
                    }
                    let stringRef = box.store(string)
                    return { _ in stringRef }
                case let .array(name):
                    guard let string = unwrapString(name) else {
                        return { _ in throw Error.undefinedSymbol(symbol) }
                    }
                    let fn = arrayEvaluator(for: symbol, string)
                    return { try box.store(fn([box.load($0[0])])) }
                default:
                    return nil
                }
            }
        }

        // Build Expression
        var _pureSymbols = [Symbol: Expression.SymbolEvaluator]()
        let expression = Expression(
            expression,
            impureSymbols: { symbol in
                if let fn = impureSymbols(symbol) {
                    return { try box.store(fn($0.map(box.load))) }
                } else if let fn = pureSymbols(symbol) {
                    switch symbol {
                    case .variable,
                         .function(_, arity: 0):
                        do {
                            let value = try box.store(fn([]))
                            _pureSymbols[symbol] = { _ in value }
                        } catch {
                            return { _ in throw error }
                        }
                    default:
                        _pureSymbols[symbol] = { try box.store(fn($0.map(box.load))) }
                    }
                } else if case let .array(name) = symbol {
                    if let fn = impureSymbols(.variable(name)) {
                        return { args in
                            let fn = try arrayEvaluator(for: symbol, fn([]))
                            return try box.store(fn(args.map(box.load)))
                        }
                    } else if let fn = pureSymbols(.variable(name)) {
                        let evaluator: SymbolEvaluator
                        do {
                            evaluator = try arrayEvaluator(for: symbol, fn([]))
                        } catch {
                            return { _ in throw error }
                        }
                        // This is outside do/catch catch in order to fix codecov glitch
                        _pureSymbols[symbol] = { try box.store(evaluator($0.map(box.load))) }
                    }
                } else if case .infix("()") = symbol {
                    // TODO: check for pure `.infix("()")` implementation, and use as
                    // fallback if the lhs isn't a SymbolEvaluator?
                    return { args in
                        switch box.load(args[0]) {
                        case let fn as SymbolEvaluator:
                            return try box.store(fn(args.dropFirst().map(box.load)))
                        case let fn as Expression.SymbolEvaluator:
                            return try fn(argsToDouble(Array(args.dropFirst()), for: symbol))
                        default:
                            throw Error.typeMismatch(symbol, args.map(box.load))
                        }
                    }
                } else if case let .function(name, _) = symbol {
                    if let fn = defaultEvaluator(for: symbol) {
                        _pureSymbols[symbol] = fn
                    } else if let fn = impureSymbols(.variable(name)) {
                        return { args in
                            let value = try fn([])
                            if let fn = funcEvaluator(for: symbol, value) {
                                return try fn(args)
                            }
                            throw Error.typeMismatch(
                                .infix("()"), [value] + [args.map(box.load)]
                            )
                        }
                    } else if let fn = pureSymbols(.variable(name)) {
                        do {
                            if let fn = try funcEvaluator(for: symbol, fn([])) {
                                return fn
                            }
                        } catch {
                            return { _ in throw error }
                        }
                    }
                }
                if !shouldOptimize {
                    return _pureSymbols[symbol] ?? defaultEvaluator(for: symbol)
                }
                return nil
            },
            pureSymbols: { symbol in
                guard let fn = _pureSymbols[symbol] ?? defaultEvaluator(for: symbol) else {
                    if case let .function(name, _) = symbol {
                        // TODO: check for pure `.infix("()")` implementation?
                        for i in 0 ... 10 {
                            let symbol = Symbol.function(name, arity: .exactly(i))
                            if impureSymbols(symbol) ?? pureSymbols(symbol) != nil {
                                return { _ in throw Error.arityMismatch(symbol) }
                            }
                        }
                        if let fn = pureSymbols(.variable(name)) {
                            return { args in
                                let value = try fn([])
                                throw Error.typeMismatch(.infix("()"), [value] + [args.map(box.load)])
                            }
                        }
                    }
                    return Expression.errorEvaluator(for: symbol)
                }
                return fn
            }
        )

        // These are constant values that won't change between evaluations
        // and won't be re-stored, so must not be cleared
        let literals = box.values

        // Evaluation isn't thread-safe due to shared values
        // so we use objc_sync_enter/exit to prevent re-entrancy
        // Beware that these objc mutexes are not available on Linux
        evaluator = {
            #if !os(Linux)
                objc_sync_enter(box)
            #endif
            defer {
                box.values = literals
                #if !os(Linux)
                    objc_sync_exit(box)
                #endif
            }
            let value = try expression.evaluate()
            return box.load(value)
        }
        self.expression = expression
    }

    /// Evaluate the expression
    public func evaluate<T>() throws -> T {
        let anyValue = try evaluator()
        guard let value: T = AnyExpression.cast(anyValue) else {
            switch T.self {
            case _ where AnyExpression.isNil(anyValue):
                break // Fall through
            case is _String.Type,
                 is NSString?.Type,
                 is String?.Type,
                 is Substring?.Type:
                // TODO: should we stringify any type like this?
                return (AnyExpression.cast(AnyExpression.stringify(anyValue)) as T?)!
            case is Bool.Type,
                 is Bool?.Type:
                // TODO: should we boolify numeric types like this?
                if let value = AnyExpression.cast(anyValue) as Double? {
                    return (value != 0) as! T
                }
            default:
                // TODO: should we numberify Bool values like this?
                if let boolValue = anyValue as? Bool,
                   let value: T = AnyExpression.cast(boolValue ? 1 : 0)
                {
                    return value
                }
            }
            throw Error.resultTypeMismatch(T.self, anyValue)
        }
        return value
    }

    /// All symbols used in the expression
    public var symbols: Set<Symbol> { return expression.symbols }

    /// Returns the optmized, pretty-printed expression if it was valid
    /// Otherwise, returns the original (invalid) expression string
    public var description: String { return describer() }
}

// MARK: Internal API

extension AnyExpression.Error {
    /// Standard error message for mismatched argument types
    static func typeMismatch(_ symbol: AnyExpression.Symbol, _ args: [Any]) -> AnyExpression.Error {
        let types = args.map {
            AnyExpression.stringify(AnyExpression.isNil($0) ? $0 : type(of: $0))
        }
        switch symbol {
        case .infix("[]") where types.count == 2:
            if AnyExpression.isSubscriptable(args[0]) {
                return .message("Attempted to subscript \(types[0]) with incompatible index type \(types[1])")
            } else {
                return .message("Attempted to subscript \(types[0]) value")
            }
        case .array where types.count == 2:
            if AnyExpression.isSubscriptable(args[0]) {
                fallthrough
            } else {
                return .message("Attempted to subscript \(types[0]) value \(symbol.escapedName)")
            }
        case .array where !types.isEmpty:
            return .message("Attempted to subscript \(symbol.escapedName) with incompatible index type \(types.last!)")
        case .infix("()") where !types.isEmpty:
            switch type(of: args[0]) {
            case is Expression.SymbolEvaluator.Type,
                 is AnyExpression.SymbolEvaluator.Type:
                return .message("Attempted to call function with incompatible arguments (\(types.dropFirst().joined(separator: ", ")))")
            case _ where types[0].contains("->"):
                return .message("Attempted to call non SymbolEvaluator function type \(types[0])")
            default:
                return .message("Attempted to call non function type \(types[0])")
            }
        case .infix("==") where types.count == 2 && types[0] == types[1]:
            return .message("Arguments for \(symbol) must conform to the Hashable protocol")
        case _ where types.count == 1:
            return .message("Argument of type \(types[0]) is not compatible with \(symbol)")
        default:
            return .message("Arguments of type (\(types.joined(separator: ", "))) are not compatible with \(symbol)")
        }
    }

    /// Standard error message for subscripting outside of a string's bounds
    static func stringBounds(_ string: String, _ index: Int) -> AnyExpression.Error {
        let escapedString = Expression.Symbol.variable("'\(string)'").escapedName
        return .message("Character index \(index) out of bounds for string \(escapedString)")
    }

    static func stringBounds(_ string: Substring, _ index: String.Index) -> AnyExpression.Error {
        var _string = string
        while index > _string.endIndex {
            // Double the length until it fits
            // TODO: is there a better solution for this?
            _string += _string
        }
        let offset = _string.distance(from: _string.startIndex, to: index)
        return stringBounds(String(string), offset)
    }

    /// Standard error message for invalid range
    static func invalidRange<T: Comparable>(_ lhs: T, _ rhs: T) -> AnyExpression.Error {
        if lhs > rhs {
            return .message("Cannot form range with lower bound > upper bound")
        }
        return .message("Cannot form half-open range with lower bound == upper bound")
    }

    /// Standard error message for mismatched return type
    static func resultTypeMismatch(_ type: Any.Type, _ value: Any) -> AnyExpression.Error {
        let valueType = AnyExpression.stringify(AnyExpression.unwrap(value).map { Swift.type(of: $0) } as Any)
        return .message("Result type \(valueType) is not compatible with expected type \(AnyExpression.stringify(type))")
    }
}

extension AnyExpression {
    /// Cast a value to the specified type
    static func cast<T>(_ anyValue: Any) -> T? {
        if let value = anyValue as? T {
            return value
        }
        var type: Any.Type = T.self
        if let optionalType = type as? _Optional.Type {
            type = optionalType.wrappedType
        }
        switch type {
        case let numericType as _Numeric.Type:
            if anyValue is Bool { return nil }
            return (anyValue as? NSNumber).map { numericType.init(truncating: $0) as! T }
        case let arrayType as _SwiftArray.Type:
            return arrayType.cast(anyValue) as? T
        case is String.Type:
            return (anyValue as? _String).map { String($0.substring) as! T }
        case is Substring.Type:
            return (anyValue as? _String)?.substring as! T?
        default:
            return nil
        }
    }

    /// Convert any value to a printable string
    static func stringify(_ value: Any) -> String {
        switch value {
        case let number as NSNumber:
            /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
            switch UnicodeScalar(UInt8(number.objCType.pointee)) {
            case "c",
                 "B":
                return number == 0 ? "false" : "true"
            default:
                break
            }
            if let int = Int64(exactly: number) {
                return "\(int)"
            }
            if let uint = UInt64(exactly: number) {
                return "\(uint)"
            }
            return "\(number)"
        case let array as _Array:
            return "[" + array.values.map(stringify).joined(separator: ", ") + "]"
        case let dictionary as [AnyHashable: Any]:
            return "[" + dictionary.enumerated().map {
                stringify($0.element.key) + ": " + stringify($0.element.value)
            }.joined(separator: ", ") + "]"
        case let range as PartialRangeUpTo<Int>:
            return "..<\(range.upperBound)"
        case let range as PartialRangeThrough<Int>:
            return "...\(range.upperBound)"
        case let range as PartialRangeFrom<Int>:
            return "\(range.lowerBound)..."
        #if !swift(>=3.4) || (swift(>=4) && !swift(>=4.1.5))
            case let range as CountablePartialRangeFrom<Int>:
                return "\(range.lowerBound)..."
        #endif
        case is Any.Type:
            return "\(value)"
        case let value:
            return unwrap(value).map { "\($0)" } ?? "nil"
        }
    }

    /// Unwraps a potentially optional value
    static func unwrap(_ value: Any) -> Any? {
        switch value {
        case let optional as _Optional:
            guard let value = optional.value else {
                fallthrough
            }
            return unwrap(value)
        case is NSNull:
            return nil
        default:
            return value
        }
    }

    /// Test if a value is nil
    static func isNil(_ value: Any) -> Bool {
        if let optional = value as? _Optional {
            guard let value = optional.value else {
                return true
            }
            return isNil(value)
        }
        return value is NSNull
    }

    /// Test if a value supports subscripting
    static func isSubscriptable(_ value: Any) -> Bool {
        return value is _Array || value is _Dictionary || value is _String
    }
}

// MARK: Private API

private extension AnyExpression {
    /// Value storage
    final class NanBox {
        private static let mask = (-Double.nan).bitPattern
        private static let indexOffset = 4
        private static let nilBits = bitPattern(for: -1)
        private static let falseBits = bitPattern(for: -2)
        private static let trueBits = bitPattern(for: -3)

        private static func bitPattern(for index: Int) -> UInt64 {
            assert(index > -indexOffset)
            return UInt64(index + indexOffset) | mask
        }

        /// Literal values
        public static let nilValue = Double(bitPattern: nilBits)
        public static let trueValue = Double(bitPattern: trueBits)
        public static let falseValue = Double(bitPattern: falseBits)

        /// The values stored in the box
        public var values = [Any]()

        /// Store a value in the box
        public func store(_ value: Any) -> Double {
            switch value {
            case let doubleValue as Double:
                return doubleValue
            case let boolValue as Bool:
                return boolValue ? NanBox.trueValue : NanBox.falseValue
            case let floatValue as Float:
                return Double(floatValue)
            case is Int,
                 is UInt,
                 is Int32,
                 is UInt32:
                return Double(truncating: value as! NSNumber)
            case let uintValue as UInt64:
                if uintValue <= 9007199254740992 as UInt64 {
                    return Double(uintValue)
                }
            case let intValue as Int64:
                if intValue <= 9007199254740992 as Int64, intValue >= -9223372036854775808 as Int64 {
                    return Double(intValue)
                }
            case let numberValue as NSNumber:
                // Hack to avoid losing type info for UIFont.Weight, etc
                if "\(value)".contains("rawValue") {
                    break
                }
                return Double(truncating: numberValue)
            case _ where AnyExpression.isNil(value):
                return NanBox.nilValue
            default:
                break
            }
            values.append(value)
            return Double(bitPattern: NanBox.bitPattern(for: values.count - 1))
        }

        /// Retrieve a value from the box, if it exists
        func loadIfStored(_ arg: Double) -> Any? {
            switch arg.bitPattern {
            case NanBox.nilBits:
                return nil as Any? as Any
            case NanBox.trueBits:
                return true
            case NanBox.falseBits:
                return false
            case let bits:
                guard var index = Int(exactly: bits ^ NanBox.mask) else {
                    return nil
                }
                index -= NanBox.indexOffset
                return values.indices.contains(index) ? values[index] : nil
            }
        }

        /// Retrieve a value if it exists, else return the argument
        func load(_ arg: Double) -> Any {
            return loadIfStored(arg) ?? arg
        }
    }

    /// Standard symbols
    static let standardSymbols: [Symbol: Expression.SymbolEvaluator] = [
        // Math symbols
        .variable("pi"): { _ in .pi },
        // Boolean symbols
        .variable("true"): { _ in NanBox.trueValue },
        .variable("false"): { _ in NanBox.falseValue },
        // Optionals
        .variable("nil"): { _ in NanBox.nilValue },
        .infix("??"): { $0[0].bitPattern == NanBox.nilValue.bitPattern ? $0[1] : $0[0] },
    ]

    /// Cast an array
    static func arrayCast<T>(_ anyValue: Any) -> [T]? {
        guard let array = (anyValue as? _Array).map({ $0.values }) else {
            return nil
        }
        var value = [T]()
        for element in array {
            guard let element: T = cast(element) else {
                return nil
            }
            value.append(element)
        }
        return value
    }
}

/// Used for casting numeric values
private protocol _Numeric {
    init(truncating: NSNumber)
}

extension Int: _Numeric {}
extension Int8: _Numeric {}
extension Int16: _Numeric {}
extension Int32: _Numeric {}
extension Int64: _Numeric {}

extension UInt: _Numeric {}
extension UInt8: _Numeric {}
extension UInt16: _Numeric {}
extension UInt32: _Numeric {}
extension UInt64: _Numeric {}

extension Double: _Numeric {}
extension Float: _Numeric {}

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    import CoreGraphics
    extension CGFloat: _Numeric {}
#endif

/// Used for subscripting
private protocol _Range {
    func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any>
    func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring
}

extension ClosedRange: _Range {
    fileprivate func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any> {
        guard let range = self as? ClosedRange<Int> else {
            throw AnyExpression.Error.typeMismatch(symbol, [array, self])
        }
        let values = array.values
        guard values.indices.contains(range.lowerBound) else {
            throw AnyExpression.Error.arrayBounds(symbol, Double(range.lowerBound))
        }
        guard range.upperBound < values.count else {
            throw AnyExpression.Error.arrayBounds(symbol, Double(range.upperBound))
        }
        return array.values[range]
    }

    fileprivate func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring {
        let substring = string.substring
        switch self {
        case let range as ClosedRange<Int>:
            guard range.lowerBound >= 0, range.lowerBound < substring.count else {
                throw AnyExpression.Error.stringBounds(String(substring), range.lowerBound)
            }
            guard range.upperBound < substring.count else {
                throw AnyExpression.Error.stringBounds(String(substring), range.upperBound)
            }
            let startIndex = substring.index(substring.startIndex, offsetBy: range.lowerBound)
            let endIndex = substring.index(startIndex, offsetBy: range.count - 1)
            return try (startIndex ... endIndex).slice(of: substring, for: symbol)
        case let range:
            let range = range as! ClosedRange<String.Index>
            guard substring.indices.contains(range.lowerBound) else {
                throw AnyExpression.Error.stringBounds(substring, range.lowerBound)
            }
            guard range.upperBound < substring.endIndex else {
                throw AnyExpression.Error.stringBounds(substring, range.upperBound)
            }
            return substring[range]
        }
    }
}

#if !swift(>=3.4) || (swift(>=4) && !swift(>=4.1.5))

    extension CountableClosedRange: _Range {
        fileprivate func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any> {
            return try ClosedRange(self).slice(of: array, for: symbol)
        }

        fileprivate func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring {
            return try ClosedRange(self).slice(of: string, for: symbol)
        }
    }

#endif

extension Range: _Range {
    fileprivate func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any> {
        guard let range = self as? Range<Int> else {
            throw AnyExpression.Error.typeMismatch(symbol, [array, self])
        }
        return try (range.lowerBound ... range.upperBound - 1).slice(of: array, for: symbol)
    }

    fileprivate func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring {
        switch self {
        case let range as Range<Int>:
            return try (range.lowerBound ... range.upperBound - 1).slice(of: string, for: symbol)
        case let range:
            let range = range as! Range<String.Index>
            let substring = string.substring
            guard substring.indices.contains(range.lowerBound) else {
                throw AnyExpression.Error.stringBounds(substring, range.lowerBound)
            }
            guard range.upperBound > substring.startIndex, range.upperBound <= substring.endIndex else {
                throw AnyExpression.Error.stringBounds(substring, range.upperBound)
            }
            let endIndex = substring.index(before: range.upperBound)
            return try (range.lowerBound ... endIndex).slice(of: substring, for: symbol)
        }
    }
}

#if !swift(>=3.4) || (swift(>=4) && !swift(>=4.1.5))

    extension CountableRange: _Range {
        fileprivate func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any> {
            return try Range(self).slice(of: array, for: symbol)
        }

        fileprivate func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring {
            return try Range(self).slice(of: string, for: symbol)
        }
    }

#endif

extension PartialRangeThrough: _Range {
    fileprivate func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any> {
        guard let range = self as? PartialRangeThrough<Int> else {
            throw AnyExpression.Error.typeMismatch(symbol, [array, self])
        }
        let array = array.values
        guard range.upperBound >= 0 else {
            throw AnyExpression.Error.arrayBounds(symbol, Double(range.upperBound))
        }
        return try Range(0 ... range.upperBound).slice(of: array, for: symbol)
    }

    fileprivate func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring {
        let substring = string.substring
        switch self {
        case let range as PartialRangeThrough<Int>:
            guard range.upperBound >= 0 else {
                throw AnyExpression.Error.stringBounds(String(substring), range.upperBound)
            }
            return try (0 ... range.upperBound).slice(of: string, for: symbol)
        case let range:
            let range = range as! PartialRangeThrough<String.Index>
            guard range.upperBound >= substring.startIndex else {
                throw AnyExpression.Error.stringBounds(substring, range.upperBound)
            }
            return try (substring.startIndex ... range.upperBound).slice(of: string, for: symbol)
        }
    }
}

extension PartialRangeUpTo: _Range {
    fileprivate func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any> {
        guard let partialRange = self as? PartialRangeUpTo<Int> else {
            throw AnyExpression.Error.typeMismatch(symbol, [array, self])
        }
        let array = array.values
        guard partialRange.upperBound > 0 else {
            throw AnyExpression.Error.arrayBounds(symbol, Double(partialRange.upperBound))
        }
        let range: Range = 0 ..< partialRange.upperBound
        return try range.slice(of: array, for: symbol)
    }

    fileprivate func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring {
        let substring = string.substring
        switch self {
        case let range as PartialRangeUpTo<Int>:
            guard range.upperBound > 0 else {
                throw AnyExpression.Error.stringBounds(String(substring), range.upperBound)
            }
            return try (0 ..< range.upperBound).slice(of: string, for: symbol)
        case let range:
            let range = range as! PartialRangeUpTo<String.Index>
            guard range.upperBound > substring.startIndex else {
                throw AnyExpression.Error.stringBounds(substring, range.upperBound)
            }
            return try (substring.startIndex ..< range.upperBound).slice(of: string, for: symbol)
        }
    }
}

extension PartialRangeFrom: _Range {
    fileprivate func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any> {
        guard let partialRange = self as? PartialRangeFrom<Int> else {
            throw AnyExpression.Error.typeMismatch(symbol, [array, self])
        }
        let array = array.values
        guard partialRange.lowerBound < array.count else {
            throw AnyExpression.Error.arrayBounds(symbol, Double(partialRange.lowerBound))
        }
        let range = partialRange.lowerBound ..< array.endIndex
        return try range.slice(of: array, for: symbol)
    }

    fileprivate func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring {
        let substring = string.substring
        switch self {
        case let range as PartialRangeFrom<Int>:
            guard range.lowerBound < substring.count else {
                throw AnyExpression.Error.stringBounds(String(substring), range.lowerBound)
            }
            return try (range.lowerBound ..< substring.count).slice(of: string, for: symbol)
        case let range:
            let range = range as! PartialRangeFrom<String.Index>
            guard range.lowerBound < substring.endIndex else {
                throw AnyExpression.Error.stringBounds(substring, range.lowerBound)
            }
            return try (range.lowerBound ..< substring.endIndex).slice(of: string, for: symbol)
        }
    }
}

#if !swift(>=3.4) || (swift(>=4) && !swift(>=4.1.5))

    extension CountablePartialRangeFrom: _Range {
        fileprivate func slice(of array: _Array, for symbol: Expression.Symbol) throws -> ArraySlice<Any> {
            return try PartialRangeFrom(lowerBound).slice(of: array, for: symbol)
        }

        fileprivate func slice(of string: _String, for symbol: Expression.Symbol) throws -> Substring {
            return try PartialRangeFrom(lowerBound).slice(of: string, for: symbol)
        }
    }

#endif

/// Used for string values
private protocol _String {
    var substring: Substring { get }
}

extension String: _String {
    var substring: Substring {
        return Substring(self)
    }
}

extension Substring: _String {
    var substring: Substring {
        return self
    }
}

extension NSString: _String {
    var substring: Substring {
        return Substring(self as String)
    }
}

/// Used for array values
private protocol _Array {
    var values: [Any] { get }
}

private protocol _SwiftArray: _Array {
    static func cast(_ value: Any) -> Any?
}

extension Array: _SwiftArray {
    fileprivate var values: [Any] {
        return self
    }

    fileprivate static func cast(_ value: Any) -> Any? {
        return AnyExpression.arrayCast(value) as [Element]?
    }
}

extension ArraySlice: _SwiftArray {
    fileprivate var values: [Any] {
        return Array(self)
    }

    static func cast(_ value: Any) -> Any? {
        return (AnyExpression.arrayCast(value) as [Element]?).map(self.init)
    }
}

extension NSArray: _Array {
    fileprivate var values: [Any] {
        return Array(self)
    }
}

/// Used for dictionary values
private protocol _Dictionary {
    func value(for key: Any) -> Any?
}

extension Dictionary: _Dictionary {
    fileprivate func value(for key: Any) -> Any? {
        guard let key = AnyExpression.cast(key) as Key? else {
            return nil // Type mismatch
        }
        return self[key] as Any
    }
}

extension NSDictionary: _Dictionary {
    fileprivate func value(for key: Any) -> Any? {
        return self[key] as Any
    }
}

/// Used to test if a value is Optional
private protocol _Optional {
    var value: Any? { get }
    static var wrappedType: Any.Type { get }
}

extension Optional: _Optional {
    fileprivate var value: Any? { return self }
    fileprivate static var wrappedType: Any.Type { return Wrapped.self }
}

#if !swift(>=3.4) || (swift(>=4) && !swift(>=4.1.5))

    extension ImplicitlyUnwrappedOptional: _Optional {
        fileprivate var value: Any? { return self }
        fileprivate static var wrappedType: Any.Type { return Wrapped.self }
    }

#endif
