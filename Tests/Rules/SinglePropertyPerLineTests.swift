//
//  SinglePropertyPerLineTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 12/26/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SinglePropertyPerLineTests: XCTestCase {
    func testSeparateLetDeclarations() {
        let input = "let a: Int, b: Int"
        let output = """
        let a: Int
        let b: Int
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateVarDeclarations() {
        let input = "var x = 10, y = 20"
        let output = """
        var x = 10
        var y = 20
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePublicVarDeclarations() {
        let input = "public var c = 10, d = false, e = \"string\""
        let output = """
        public var c = 10
        public var d = false
        public var e = "string"
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateObjcVarDeclarations() {
        let input = "@objc var f = true, g: Bool"
        let output = """
        @objc var f = true
        @objc var g: Bool
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePrivateStaticDeclarations() {
        let input = """
        public enum Namespace {
            public static let a = 1, b = 2, c = 3
        }
        """
        let output = """
        public enum Namespace {
            public static let a = 1
            public static let b = 2
            public static let c = 3
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateDeclarationsWithComplexTypes() {
        let input = "let dict: [String: Int], array: [String]"
        let output = """
        let dict: [String: Int]
        let array: [String]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateDeclarationsWithGenericTypes() {
        let input = "var optional: Optional<String>, result: Result<Int, Error>"
        let output = """
        var optional: Optional<String>
        var result: Result<Int, Error>
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateDeclarationsWithClosureTypes() {
        let input = "let callback: () -> Void, handler: (String) -> Int"
        let output = """
        let callback: () -> Void
        let handler: (String) -> Int
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateDeclarationsWithTupleTypes() {
        let input = "let point: (Int, Int), size: (width: Int, height: Int)"
        let output = """
        let point: (Int, Int)
        let size: (width: Int, height: Int)
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testPreserveIndentation() {
        let input = """
        class Foo {
            let a: Int, b: Int
        }
        """
        let output = """
        class Foo {
            let a: Int
            let b: Int
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testPreserveMultipleAttributes() {
        let input = "@available(iOS 13.0, *) @objc private var a = 1, b = 2"
        let output = """
        @available(iOS 13.0, *) @objc private var a = 1
        @available(iOS 13.0, *) @objc private var b = 2
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testNoChangeForSingleProperty() {
        let input = "let single: String = \"value\""
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testNoChangesForComputedProperties() {
        let input = """
        var computed: Int {
            return value1 + value2
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testIgnoreCommasInFunctionCalls() {
        let input = "let result = someFunction(param1, param2, param3)"
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testIgnoreCommasInArrayLiterals() {
        let input = "let array = [1, 2, 3, 4, 5]"
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testIgnoreCommasInDictionaryLiterals() {
        let input = "let dict = [\"a\": 1, \"b\": 2, \"c\": 3]"
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testIgnoreCommasInTuples() {
        let input = "let tuple = (1, 2, 3)"
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithComplexInitializers() {
        let input = "let a = [1, 2, 3], b = (x: 1, y: 2)"
        let output = """
        let a = [1, 2, 3]
        let b = (x: 1, y: 2)
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithFunctionCallInitializers() {
        let input = "let result1 = process(data, options), result2 = transform(input)"
        let output = """
        let result1 = process(data, options)
        let result2 = transform(input)
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testPreserveCommentsBetweenProperties() {
        let input = "let a = 1, /* comment */ b = 2"
        let output = """
        let a = 1
        let b = 2
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testInsideClassBody() {
        let input = """
        class MyClass {
            let a: Int, b: Int
            private var x = 1, y = 2
        }
        """
        let output = """
        class MyClass {
            let a: Int
            let b: Int
            private var x = 1
            private var y = 2
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testInsideStructBody() {
        let input = """
        struct Point {
            let x: Double, y: Double
            var label: String, isVisible: Bool
        }
        """
        let output = """
        struct Point {
            let x: Double
            let y: Double
            var label: String
            var isVisible: Bool
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testInsideFunctionBody() {
        let input = """
        func processData() {
            let start = 0, end = 100
            var temp: String, result: Int
        }
        """
        let output = """
        func processData() {
            let start = 0
            let end = 100
            var temp: String
            var result: Int
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testInsideClosureBody() {
        let input = """
        let closure = {
            let a = 1, b = 2
            var x: Int, y: Int
        }
        """
        let output = """
        let closure = {
            let a = 1
            let b = 2
            var x: Int
            var y: Int
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testInsideEnumBody() {
        let input = """
        enum Configuration {
            case light(let brightness: Float, contrast: Float)

            static let defaultBrightness = 1.0, defaultContrast = 0.8
        }
        """
        let output = """
        enum Configuration {
            case light(let brightness: Float, contrast: Float)

            static let defaultBrightness = 1.0
            static let defaultContrast = 0.8
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testInsideInitializer() {
        let input = """
        init() {
            let temp1 = getValue(), temp2 = getOtherValue()
            var config: Config, settings: Settings
        }
        """
        let output = """
        init() {
            let temp1 = getValue()
            let temp2 = getOtherValue()
            var config: Config
            var settings: Settings
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testNestedIndentation() {
        let input = """
        class Outer {
            func method() {
                if condition {
                    let a = 1, b = 2
                    var x: String, y: String
                }
            }
        }
        """
        let output = """
        class Outer {
            func method() {
                if condition {
                    let a = 1
                    let b = 2
                    var x: String
                    var y: String
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }
}
