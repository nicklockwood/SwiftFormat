//
//  BenchmarkUtils.swift
//  Expression
//
//  Created by Nick Lockwood on 13/02/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Expression
import Foundation

#if os(iOS) || os(macOS)
    import JavaScriptCore
#endif

let symbols: [Expression.Symbol: Expression.SymbolEvaluator] = [
    .variable("a"): { _ in 5 },
    .variable("b"): { _ in 6 },
    .variable("c"): { _ in 7 },
    .variable("hello"): { _ in -5 },
    .variable("world"): { _ in -3 },
    .function("foo", arity: 0): { _ in .pi },
    .function("foo", arity: 2): { $0[0] - $0[1] },
    .function("bar", arity: 1): { $0[0] - 2 },
]

let anySymbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = {
    var anySymbols = [AnyExpression.Symbol: AnyExpression.SymbolEvaluator]()
    for (symbol, fn) in symbols {
        anySymbols[symbol] = { args in
            try fn(args.map {
                guard let arg = $0 as? Double else {
                    throw AnyExpression.Error.message("Type mismatch")
                }
                return arg
            })
        }
    }
    return anySymbols
}()

let shortExpressions = [
    "5",
    "a",
    "foo()",
    "hello",
    "67",
    "3.5",
    "pi",
]

let mediumExpressions = [
    "5 + 7",
    "a + b",
    "foo(5, 6)",
    "hello + world",
    "67 * 2",
    "3.5 / 6",
    "pi + 15",
]

let longExpressions = [
    "5 + min(a, b * 10)",
    "max(a + b, b + c)",
    "foo(5, 6 + bar(6))",
    "hello + world",
    "(67 * 2) + (68 * 3)",
    "3.5 / 6 + 1234 * 54",
    "pi * -56.4 + (5 + 4)",
]

let reallyLongExpression: String = {
    var parts = [String]()
    for i in 0 ..< 100 {
        parts.append("\(i)")
    }
    return "foo(" + parts.joined(separator: "+") + " + bar(5), a) + b"
}()

let booleanExpressions = [
    "true && false",
    "a == b",
    "foo(5, 6) != foo(5, 6)",
    "a ? hello : world",
    "false || true",
    "pi > 3",
]

// MARK: Expression support

func buildExpressions(_ expressions: [String]) -> [Expression] {
    return expressions.map {
        let parsedExpression = Expression.parse($0, usingCache: false)
        return Expression(parsedExpression, options: .pureSymbols, symbols: symbols)
    }
}

func evaluateExpressions(_ expressions: [Expression]) -> Double? {
    var result: Double?
    for _ in 0 ..< evalRepetitions {
        for expression in expressions {
            result = try! expression.evaluate()
        }
    }
    return result
}

func evaluateExpressions(_ expressions: [String]) -> Double? {
    var result: Double?
    for _ in 0 ..< parseRepetitions {
        for exp in expressions {
            let parsedExpression = Expression.parse(exp, usingCache: false)
            let expression = Expression(parsedExpression, options: .pureSymbols, symbols: symbols)
            result = try! expression.evaluate()
        }
    }
    return result
}

func buildAnyExpressions(_ expressions: [String]) -> [AnyExpression] {
    return expressions.map {
        let parsedExpression = Expression.parse($0, usingCache: false)
        return AnyExpression(parsedExpression, options: .pureSymbols, symbols: anySymbols)
    }
}

func evaluateAnyExpressions(_ expressions: [AnyExpression]) -> Double? {
    var result: Any?
    for _ in 0 ..< evalRepetitions {
        for expression in expressions {
            result = try! expression.evaluate()
        }
    }
    return (result as? NSNumber).map(Double.init(truncating:))
}

func evaluateAnyExpressions(_ expressions: [String]) -> Double? {
    var result: Any?
    for _ in 0 ..< parseRepetitions {
        for exp in expressions {
            let parsedExpression = Expression.parse(exp, usingCache: false)
            let expression = AnyExpression(parsedExpression, options: .noOptimize, symbols: anySymbols)
            result = try! expression.evaluate()
        }
    }
    return (result as? NSNumber).map(Double.init(truncating:))
}

// MARK: NSExpression support

let shortNSExpressions: [String] = shortExpressions.map {
    switch $0 {
    case "foo()":
        return "FUNCTION(0, 'foo')"
    default:
        return $0
    }
}

let mediumNSExpressions: [String] = mediumExpressions.map {
    switch $0 {
    case "foo(5, 6)":
        return "FUNCTION(5, 'foo:', 6)"
    default:
        return $0
    }
}

let longNSExpressions: [String] = longExpressions.map {
    switch $0 {
    case "5 + min(a, b * 10)":
        return "5 + FUNCTION(a, 'min:', b * 10)"
    case "max(a + b, b + c)":
        return "FUNCTION(a + b, 'max:', b + c)"
    case "foo(5, 6 + bar(6))":
        return "FUNCTION(5, 'foo:', 6 + FUNCTION(6, 'bar'))"
    default:
        return $0
    }
}

let nsSymbols = [
    "pi": Double.pi,
    "a": 5,
    "b": 6,
    "c": 7,
    "hello": -5,
    "world": -3,
]

extension NSNumber {
    @objc func foo() -> NSNumber {
        return Double.pi as NSNumber
    }

    @objc func foo(_ other: NSNumber) -> NSNumber {
        return (Double(truncating: self) + Double(truncating: other)) as NSNumber
    }

    @objc func bar() -> NSNumber {
        return (Double(truncating: self) + 2) as NSNumber
    }

    @objc func min(_ other: NSNumber) -> NSNumber {
        return Swift.min(Double(truncating: self), Double(truncating: other)) as NSNumber
    }

    @objc func max(_ other: NSNumber) -> NSNumber {
        return Swift.max(Double(truncating: self), Double(truncating: other)) as NSNumber
    }
}

func buildNSExpressions(_ expressions: [String]) -> [NSExpression] {
    return expressions.map { NSExpression(format: $0) }
}

func evaluateNSExpressions(_ expressions: [NSExpression]) -> NSNumber? {
    var result: NSNumber?
    for _ in 0 ..< evalRepetitions {
        for expression in expressions {
            result = expression.expressionValue(with: nsSymbols, context: nil) as? NSNumber
        }
    }
    return result
}

func evaluateNSExpressions(_ expressions: [String]) -> NSNumber? {
    var result: NSNumber?
    for _ in 0 ..< parseRepetitions {
        for exp in expressions {
            let expression = NSExpression(format: exp)
            result = expression.expressionValue(with: nsSymbols, context: nil) as? NSNumber
        }
    }
    return result
}

#if os(iOS) || os(macOS)

    // MARK: JS symbols

    private let foo: @convention(block) (Double, Double) -> Double = { a, b in
        if a.isNaN {
            return Double.pi
        }
        return a + b
    }

    private let bar: @convention(block) (Double) -> Double = {
        $0 - 2
    }

    let jsSymbols: [String: Any] = [
        "pi": Double.pi,
        "a": 5,
        "b": 6,
        "c": 7,
        "hello": -5,
        "world": -3,
        "foo": foo,
        "bar": bar,
    ]

    func makeJSContext(symbols: [String: Any]) -> JSContext {
        let context: JSContext = JSContext()
        for (key, value) in symbols {
            context.globalObject.setValue(value, forProperty: key)
        }
        return context
    }

    func buildJSExpressions(_ expressions: [String]) -> [() -> JSValue] {
        return expressions.map { exp -> (() -> JSValue) in
            let context = makeJSContext(symbols: jsSymbols)
            // Note: it may seem unfair to be evaluating the script inside the block
            // however, I tried wrapping the script as a function and storing the
            // evaluated result in a JSValue to be executed in the block, and that
            // was at least an order of magnitude slower than this approac
            return { context.evaluateScript(exp) }
        }
    }

    func evaluateJSExpressions(_ expressions: [() -> JSValue]) -> JSValue? {
        var result: JSValue?
        for _ in 0 ..< evalRepetitions {
            for expression in expressions {
                result = expression()
            }
        }
        return result
    }

    func evaluateJSExpressions(_ expressions: [String]) -> JSValue? {
        var result: JSValue?
        for _ in 0 ..< parseRepetitions {
            let context = makeJSContext(symbols: jsSymbols)
            for exp in expressions {
                result = context.evaluateScript(exp)
            }
        }
        return result
    }

#endif
