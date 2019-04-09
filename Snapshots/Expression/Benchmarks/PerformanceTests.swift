//
//  PerformanceTests.swift
//  ExpressionTests
//
//  Created by Nick Lockwood on 24/05/2017.
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

import Expression
import XCTest

class PerformanceTests: XCTestCase {
    private let parseRepetitions = 500
    private let evalRepetitions = 5000

    // MARK: parsing

    func testParsingShortExpressions() {
        measure { parseExpressions(shortExpressions) }
    }

    func testParsingMediumExpressions() {
        measure { parseExpressions(mediumExpressions) }
    }

    func testParsingLongExpressions() {
        measure { parseExpressions(longExpressions) }
    }

    func testParsingReallyLongExpressions() {
        measure { parseExpressions([reallyLongExpression]) }
    }

    func testParsingBooleanExpressions() {
        measure { parseExpressions(booleanExpressions) }
    }

    // MARK: optimizing

    func testOptimizingShortExpressions() {
        let expressions = shortExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressions(expressions) }
    }

    func testOptimizingShortExpressionsWithNewInitializer() {
        let expressions = shortExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressionsWithNewInitializer(expressions) }
    }

    func testOptimizingShortAnyExpressions() {
        let expressions = shortExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeAnyExpressions(expressions) }
    }

    func testOptimizingShortAnyExpressionsWithNewInitializer() {
        let expressions = shortExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeAnyExpressionsWithNewInitializer(expressions) }
    }

    func testOptimizingMediumExpressions() {
        let expressions = mediumExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressions(expressions) }
    }

    func testOptimizingMediumExpressionsWithNewInitializer() {
        let expressions = mediumExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressionsWithNewInitializer(expressions) }
    }

    func testOptimizingMediumAnyExpressions() {
        let expressions = mediumExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeAnyExpressions(expressions) }
    }

    func testOptimizingMediumAnyExpressionsWithNewInitializer() {
        let expressions = mediumExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressionsWithNewInitializer(expressions) }
    }

    func testOptimizingLongExpressions() {
        let expressions = longExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressions(expressions) }
    }

    func testOptimizingLongExpressionsWithNewInitializer() {
        let expressions = longExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressionsWithNewInitializer(expressions) }
    }

    func testOptimizingLongAnyExpressions() {
        let expressions = longExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeAnyExpressions(expressions) }
    }

    func testOptimizingLongAnyExpressionsWithNewInitializer() {
        let expressions = longExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeAnyExpressionsWithNewInitializer(expressions) }
    }

    func testOptimizingReallyLongExpression() {
        let exp = Expression.parse(reallyLongExpression, usingCache: false)
        measure { optimizeExpressions([exp]) }
    }

    func testOptimizinReallyLongExpressionWithNewInitializer() {
        let exp = Expression.parse(reallyLongExpression, usingCache: false)
        measure { optimizeExpressionsWithNewInitializer([exp]) }
    }

    func testOptimizingReallyLongAnyExpression() {
        let exp = Expression.parse(reallyLongExpression, usingCache: false)
        measure { optimizeAnyExpressions([exp]) }
    }

    func testOptimizingReallyLongAnyExpressionWithNewInitializer() {
        let exp = Expression.parse(reallyLongExpression, usingCache: false)
        measure { optimizeAnyExpressionsWithNewInitializer([exp]) }
    }

    func testOptimizingBooleanExpressions() {
        let expressions = booleanExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressions(expressions) }
    }

    func testOptimizingBooleanExpressionsWithNewInitializer() {
        let expressions = booleanExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeExpressionsWithNewInitializer(expressions) }
    }

    func testOptimizingBooleanAnyExpressions() {
        let expressions = booleanExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeAnyExpressions(expressions) }
    }

    func testOptimizingBooleanAnyExpressionsWithNewInitializer() {
        let expressions = booleanExpressions.map { Expression.parse($0, usingCache: false) }
        measure { optimizeAnyExpressionsWithNewInitializer(expressions) }
    }

    // MARK: evaluating

    func testEvaluatingShortExpressions() {
        let expressions = shortExpressions.map { Expression($0, options: .pureSymbols, symbols: symbols) }
        measure { evaluateExpressions(expressions) }
    }

    func testEvaluatingShortAnyExpressions() {
        let expressions = shortExpressions.map { AnyExpression($0, options: .pureSymbols, symbols: anySymbols) }
        measure { evaluateExpressions(expressions) }
    }

    func testEvaluatingMediumExpressions() {
        let expressions = mediumExpressions.map { Expression($0, options: .pureSymbols, symbols: symbols) }
        measure { evaluateExpressions(expressions) }
    }

    func testEvaluatingMediumAnyExpressions() {
        let expressions = mediumExpressions.map { AnyExpression($0, options: .pureSymbols, symbols: anySymbols) }
        measure { evaluateExpressions(expressions) }
    }

    func testEvaluatingLongExpressions() {
        let expressions = mediumExpressions.map { Expression($0, options: .pureSymbols, symbols: symbols) }
        measure { evaluateExpressions(expressions) }
    }

    func testEvaluatingLongAnyExpressions() {
        let expressions = mediumExpressions.map { AnyExpression($0, options: .pureSymbols, symbols: anySymbols) }
        measure { evaluateExpressions(expressions) }
    }

    func testEvaluatingReallyLongExpression() {
        let exp = Expression(reallyLongExpression, options: .pureSymbols, symbols: symbols)
        measure { evaluateExpressions([exp]) }
    }

    func testEvaluatingReallyLongAnyExpression() {
        let exp = AnyExpression(reallyLongExpression, options: .pureSymbols, symbols: anySymbols)
        measure { evaluateExpressions([exp]) }
    }

    func testEvaluatingBooleanExpressions() {
        let expressions = booleanExpressions.map { Expression($0, options: [.boolSymbols, .pureSymbols], symbols: symbols) }
        measure { evaluateExpressions(expressions) }
    }

    func testEvaluatingBooleanAnyExpressions() {
        let expressions = booleanExpressions.map { AnyExpression($0, options: [.boolSymbols, .pureSymbols], symbols: anySymbols) }
        measure { evaluateExpressions(expressions) }
    }

    // MARK: == performance

    func testEquateDoubles() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in 5 },
            .variable("b"): { _ in 6 },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure { evaluateExpressions([equalExpression, unequalExpression]) }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateBools() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in true },
            .variable("b"): { _ in false },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure { evaluateExpressions([equalExpression, unequalExpression]) }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateStrings() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in "a" },
            .variable("b"): { _ in "b" },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure { evaluateExpressions([equalExpression, unequalExpression]) }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateNSObjects() {
        let objectA = NSObject()
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in objectA },
            .variable("b"): { _ in NSObject() },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure { evaluateExpressions([equalExpression, unequalExpression]) }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateArrays() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in ["hello"] },
            .variable("b"): { _ in ["goodbye"] },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure { evaluateExpressions([equalExpression, unequalExpression]) }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testEquateHashables() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in HashableStruct(foo: 5) },
            .variable("b"): { _ in HashableStruct(foo: 6) },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure { evaluateExpressions([equalExpression, unequalExpression]) }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    func testCompareAgainstNil() {
        let symbols: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
            .variable("a"): { _ in NSNull() },
            .variable("b"): { _ in 5 },
        ]
        let equalExpression = AnyExpression("a == a", symbols: symbols)
        let unequalExpression = AnyExpression("a == b", symbols: symbols)
        measure { evaluateExpressions([equalExpression, unequalExpression]) }
        XCTAssertTrue(try equalExpression.evaluate())
        XCTAssertFalse(try unequalExpression.evaluate())
    }

    // MARK: Utility functions

    private func parseExpressions(_ expressions: [String]) {
        for _ in 0 ..< parseRepetitions {
            for exp in expressions {
                _ = Expression.parse(exp, usingCache: false)
            }
        }
    }

    private func optimizeExpressions(_ expressions: [ParsedExpression]) {
        for _ in 0 ..< parseRepetitions {
            for exp in expressions {
                _ = Expression(exp, options: [.pureSymbols, .boolSymbols], symbols: symbols)
            }
        }
    }

    private func optimizeExpressionsWithNewInitializer(_ expressions: [ParsedExpression]) {
        for _ in 0 ..< parseRepetitions {
            for exp in expressions {
                _ = Expression(exp, pureSymbols: { symbols[$0] })
            }
        }
    }

    private func optimizeAnyExpressions(_ expressions: [ParsedExpression]) {
        for _ in 0 ..< parseRepetitions {
            for exp in expressions {
                _ = AnyExpression(exp, options: [.pureSymbols, .boolSymbols], symbols: anySymbols)
            }
        }
    }

    private func optimizeAnyExpressionsWithNewInitializer(_ expressions: [ParsedExpression]) {
        for _ in 0 ..< parseRepetitions {
            for exp in expressions {
                _ = AnyExpression(exp, pureSymbols: { anySymbols[$0] })
            }
        }
    }

    private func evaluateExpressions(_ expressions: [Expression]) {
        for _ in 0 ..< evalRepetitions {
            for exp in expressions {
                _ = try! exp.evaluate()
            }
        }
    }

    private func evaluateExpressions(_ expressions: [AnyExpression]) {
        for _ in 0 ..< evalRepetitions {
            for exp in expressions {
                _ = try! exp.evaluate() as Any
            }
        }
    }

    private struct HashableStruct: Hashable {
        let foo: Int
        var hashValue: Int {
            return foo.hashValue
        }

        static func == (lhs: HashableStruct, rhs: HashableStruct) -> Bool {
            return lhs.foo == rhs.foo
        }
    }
}
