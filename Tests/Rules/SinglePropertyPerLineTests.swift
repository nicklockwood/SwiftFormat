//
//  SinglePropertyPerLineTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 6/27/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SinglePropertyPerLineTests: XCTestCase {
    func testSeparateLetDeclarations() {
        let input = """
        let a: Int, b: Int
        """
        let output = """
        let a: Int
        let b: Int
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateVarDeclarations() {
        let input = """
        var x = 10, y = 20
        """
        let output = """
        var x = 10
        var y = 20
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePublicVarDeclarations() {
        let input = """
        public var c = 10, d = false, e = \"string\"
        """
        let output = """
        public var c = 10
        public var d = false
        public var e = "string"
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateObjcVarDeclarations() {
        let input = """
        @objc var f = true, g: Bool
        """
        let output = """
        @objc var f = true
        @objc var g: Bool
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine, exclude: [.propertyTypes])
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
        let input = """
        let dict: [String: Int], array: [String]
        """
        let output = """
        let dict: [String: Int]
        let array: [String]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateDeclarationsWithGenericTypes() {
        let input = """
        var optional: Optional<String>, result: Result<Int, Error>
        """
        let output = """
        var optional: Optional<String>
        var result: Result<Int, Error>
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateDeclarationsWithClosureTypes() {
        let input = """
        let callback: () -> Void, handler: (String) -> Int
        """
        let output = """
        let callback: () -> Void
        let handler: (String) -> Int
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparateDeclarationsWithTupleTypes() {
        let input = """
        let point: (Int, Int), size: (width: Int, height: Int)
        """
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
        let input = """
        @available(iOS 13.0, *) @objc private var a = 1, b = 2
        """
        let output = """
        @available(iOS 13.0, *) @objc private var a = 1
        @available(iOS 13.0, *) @objc private var b = 2
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testNoChangeForSingleProperty() {
        let input = """
        let single: String = \"value\"
        """
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
        let input = """
        let result = someFunction(param1, param2, param3)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testIgnoreCommasInArrayLiterals() {
        let input = """
        let array = [1, 2, 3, 4, 5]
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testIgnoreCommasInDictionaryLiterals() {
        let input = """
        let dict = [\"a\": 1, \"b\": 2, \"c\": 3]
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testIgnoreCommasInTuples() {
        let input = """
        let tuple = (1, 2, 3)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithComplexInitializers() {
        let input = """
        let a = [1, 2, 3], b = (x: 1, y: 2)
        """
        let output = """
        let a = [1, 2, 3]
        let b = (x: 1, y: 2)
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithFunctionCallInitializers() {
        let input = """
        let result1 = process(data, options), result2 = transform(input)
        """
        let output = """
        let result1 = process(data, options)
        let result2 = transform(input)
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

    func testSeparatePropertiesWithArrayTypes() {
        let input = """
        let numbers: [Int], strings: [String], optionals: [Int?]
        """
        let output = """
        let numbers: [Int]
        let strings: [String]
        let optionals: [Int?]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithDictionaryTypes() {
        let input = """
        var userMap: [String: User], settingsMap: [String: Any], counters: [String: Int]
        """
        let output = """
        var userMap: [String: User]
        var settingsMap: [String: Any]
        var counters: [String: Int]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithArrayLiteralValues() {
        let input = """
        let primes = [2, 3, 5, 7], evens = [2, 4, 6, 8], odds = [1, 3, 5, 7]
        """
        let output = """
        let primes = [2, 3, 5, 7]
        let evens = [2, 4, 6, 8]
        let odds = [1, 3, 5, 7]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithDictionaryLiteralValues() {
        let input = """
        let colors = [\"red\": 0xFF0000, \"green\": 0x00FF00], settings = [\"theme\": \"dark\", \"language\": \"en\"]
        """
        let output = """
        let colors = ["red": 0xFF0000, "green": 0x00FF00]
        let settings = ["theme": "dark", "language": "en"]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithMultilineArrayLiterals() {
        let input = """
        let config = [
            "api": "v1",
            "timeout": 30
        ], credentials = ["username": user, "password": pass]
        """
        let output = """
        let config = [
            "api": "v1",
            "timeout": 30
        ]
        let credentials = ["username": user, "password": pass]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine, exclude: [.trailingCommas])
    }

    func testSeparatePropertiesWithNestedArrayTypes() {
        let input = """
        let matrix: [[Int]], jaggedArray: [[String?]], coordinates: [(Double, Double)]
        """
        let output = """
        let matrix: [[Int]]
        let jaggedArray: [[String?]]
        let coordinates: [(Double, Double)]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithComplexGenericTypes() {
        let input = """
        var publisher: AnyPublisher<String, Error>, subject: PassthroughSubject<Int, Never>
        """
        let output = """
        var publisher: AnyPublisher<String, Error>
        var subject: PassthroughSubject<Int, Never>
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithOptionalArrayTypes() {
        let input = """
        let optionalArray: [String]?, arrayOfOptionals: [String?], bothOptional: [String?]?
        """
        let output = """
        let optionalArray: [String]?
        let arrayOfOptionals: [String?]
        let bothOptional: [String?]?
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithFunctionTypes() {
        let input = """
        let transformer: (String) -> Int, validator: (String) -> Bool, processor: ([Int]) -> [String]
        """
        let output = """
        let transformer: (String) -> Int
        let validator: (String) -> Bool
        let processor: ([Int]) -> [String]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithEscapingClosureTypes() {
        let input = """
        var onSuccess: (@escaping (Data) -> Void)?, onError: (@escaping (Error) -> Void)?
        """
        let output = """
        var onSuccess: (@escaping (Data) -> Void)?
        var onError: (@escaping (Error) -> Void)?
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithSetValues() {
        let input = """
        let vowels: Set = [\"a\", \"e\", \"i\", \"o\", \"u\"], consonants: Set<Character> = [\"b\", \"c\", \"d\"]
        """
        let output = """
        let vowels: Set = ["a", "e", "i", "o", "u"]
        let consonants: Set<Character> = ["b", "c", "d"]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithTupleValues() {
        let input = """
        let point = (x: 10, y: 20), size = (width: 100, height: 200), origin = (0, 0)
        """
        let output = """
        let point = (x: 10, y: 20)
        let size = (width: 100, height: 200)
        let origin = (0, 0)
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithObjectInitializers() {
        let input = """
        let url = URL(string: \"https://api.example.com\")!, client = HTTPClient(session: .shared), config = AppConfig.default
        """
        let output = """
        let url = URL(string: "https://api.example.com")!
        let client = HTTPClient(session: .shared)
        let config = AppConfig.default
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine, exclude: [.propertyTypes])
    }

    func testSeparatePropertiesWithChainedMethodCalls() {
        let input = """
        let trimmed = input.trimmingCharacters(in: .whitespaces), uppercased = text.uppercased().replacingOccurrences(of: \" \", with: \"_\")
        """
        let output = """
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        let uppercased = text.uppercased().replacingOccurrences(of: " ", with: "_")
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithConditionalValues() {
        let input = """
        let result = condition ? value1 : value2, fallback = optional ?? defaultValue
        """
        let output = """
        let result = condition ? value1 : value2
        let fallback = optional ?? defaultValue
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSeparatePropertiesWithTypeInference() {
        let input = """
        let items = [\"apple\", \"banana\", \"cherry\"], counts = [1: \"one\", 2: \"two\"], flags = [true, false, true]
        """
        let output = """
        let items = ["apple", "banana", "cherry"]
        let counts = [1: "one", 2: "two"]
        let flags = [true, false, true]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testIgnoreGuardStatements() {
        let input = """
        guard let foo, foo, bar, let baaz: Baaz else { return }
        """
        let output = """
        guard let foo, foo, bar, let baaz: Baaz else {
            return
        }
        """
        testFormatting(for: input, [output], rules: [.singlePropertyPerLine, .wrapConditionalBodies])
    }

    func testIgnoreIfStatements() {
        let input = """
        if let animator, animator.state != .inactive {
            animator.stopAnimation(true)
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testSharedTypeAnnotation() {
        let input = """
        let itemPosition, itemSize, viewportSize, minContentOffset, maxContentOffset: CGFloat
        """
        let output = """
        let itemPosition: CGFloat
        let itemSize: CGFloat
        let viewportSize: CGFloat
        let minContentOffset: CGFloat
        let maxContentOffset: CGFloat
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSharedTypeAnnotationWithModifiers() {
        let input = """
        private let width, height, depth: Double
        """
        let output = """
        private let width: Double
        private let height: Double
        private let depth: Double
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSharedComplexTypeAnnotation() {
        let input = """
        let first, second, third: [String: Int]
        """
        let output = """
        let first: [String: Int]
        let second: [String: Int]
        let third: [String: Int]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testMixedDeclarationsWithAndWithoutTypes() {
        let input = """
        let a = 5, b: Int, c = 10
        """
        let output = """
        let a = 5
        let b: Int
        let c = 10
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testGuardWithMultipleConditions() {
        let input = """
        guard let user = user,
              user.isActive,
              let token = user.token else {
            return
        }
        """
        let output = """
        guard let user = user,
              user.isActive,
              let token = user.token
        else {
            return
        }
        """
        testFormatting(for: input, [output], rules: [.singlePropertyPerLine, .elseOnSameLine, .wrapMultilineStatementBraces])
    }

    func testIfWithMultipleConditions() {
        let input = """
        if let data = data,
           let result = process(data),
           result.isValid {
            handle(result)
        }
        """
        let output = """
        if let data = data,
           let result = process(data),
           result.isValid
        {
            handle(result)
        }
        """
        testFormatting(for: input, [output], rules: [.singlePropertyPerLine, .wrapMultilineStatementBraces])
    }

    func testWhileWithMultipleConditions() {
        let input = """
        while let item = iterator.next(),
              item.isValid {
            process(item)
        }
        """
        let output = """
        while let item = iterator.next(),
              item.isValid
        {
            process(item)
        }
        """
        testFormatting(for: input, [output], rules: [.singlePropertyPerLine, .wrapMultilineStatementBraces])
    }

    func testSwitchCaseWithMultipleBindings() {
        let input = """
        switch value {
        case let (a, b, c):
            return
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testSharedTypeAnnotationDuplication() {
        let input = """
        let itemPosition, itemSize, viewportSize, minContentOffset, maxContentOffset: CGFloat
        """
        let output = """
        let itemPosition: CGFloat
        let itemSize: CGFloat
        let viewportSize: CGFloat
        let minContentOffset: CGFloat
        let maxContentOffset: CGFloat
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSwitchCaseWithOptionalBindings() {
        let input = """
        switch value {
        case (let leading?, nil, nil):
            return
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testSwitchCaseWithMultipleConditions() {
        let input = """
        let fromFrame, toFrame: CGRect
        switch (containerType, destinationContentMode) {
        case (.source, _), (_, .fill):
            break
        }
        """
        let output = """
        let fromFrame: CGRect
        let toFrame: CGRect
        switch (containerType, destinationContentMode) {
        case (.source, _), (_, .fill):
            break
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine, exclude: [.sortSwitchCases, .wrapSwitchCases])
    }

    // TODO: Fix tuple parsing - parseExpressionRange doesn't handle tuples correctly
    // func testSimpleTupleValues() {
    //     let input = "let a = (1, 2), b = (3, 4)"
    //     let output = """
    //     let a = (1, 2)
    //     let b = (3, 4)
    //     """
    //     testFormatting(for: input, output, rule: .singlePropertyPerLine)
    // }

    func testBasicCommaDetection() {
        // Test if parseExpressionRange is working correctly for simple cases
        let input = """
        let x = 5, y = 10
        """
        let output = """
        let x = 5
        let y = 10
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testSimpleSharedType() {
        let input = """
        let a, b: Int
        """
        let output = """
        let a: Int
        let b: Int
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testEnumDeclarationWithConformances() {
        let input = """
        enum DiagnosticFailure: Error, CustomStringConvertible { }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.emptyBraces])
    }

    func testIfLetWithTupleDestructuring() {
        let input = """
        if let (cacheKey, cachedHeight) = cachedHeight, cacheKey == newCacheKey {
            return cachedHeight
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testGuardCaseWithBinding() {
        let input = """
        guard case .link(let url, _) = tappableContent else {
            return
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet])
    }

    func testIfLetWithMultipleConditions() {
        let input = """
        if let (cacheKey, cachedHeight) = cachedHeight, cacheKey == newCacheKey {
            return cachedHeight
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testClassDeclarationWithMultipleInheritance() {
        let input = """
        public final class PrimaryButton: BaseMarginView, ConstellationView, PrimaryActionLoggable { }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.emptyBraces])
    }

    func testSwitchCaseWithMultipleLetBindings() {
        let input = """
        switch value {
        case .remote(url: let url, placeholder: let placeholder, aspectRatio: let aspectRatio):
            break
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet, .wrapSwitchCases])
    }

    func testSwitchCaseWithMixedPatterns() {
        let input = """
        switch content {
        case .link(let title, _, _), .text(let title, _):
            return title
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet, .wrapSwitchCases])
    }

    func testCasePatternWithParentheses() {
        let input = """
        switch value {
        case .remote(let url, placeholder):
            break
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.hoistPatternLet])
    }

    func testEnumWithProtocolConformanceListFollowingProperty() {
        let input = """
        public let foo = "bar"

        enum MyEnum: Error, CustomStringConvertible {
            case foo
            case bar
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testSimpleTupleDestructuring() {
        let input = """
        let (foo, bar, baaz) = (1, 2, 3)
        """
        let output = """
        let foo = 1
        let bar = 2
        let baaz = 3
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithVarKeyword() {
        let input = """
        var (x, y, z) = (10, 20, 30)
        """
        let output = """
        var x = 10
        var y = 20
        var z = 30
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithSpaces() {
        let input = """
        let ( a , b , c ) = ( 1 , 2 , 3 )
        """
        let output = """
        let a = 1
        let b = 2
        let c = 3
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithComplexValues() {
        let input = """
        let (name, age, active) = (\"John\", 25, true)
        """
        let output = """
        let name = "John"
        let age = 25
        let active = true
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithModifiers() {
        let input = """
        private let (width, height) = (100.0, 200.0)
        """
        let output = """
        private let width = 100.0
        private let height = 200.0
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithAttributes() {
        let input = """
        @available(iOS 15, *) let (feature1, feature2) = (true, false)
        """
        let output = """
        @available(iOS 15, *) let feature1 = true
        @available(iOS 15, *) let feature2 = false
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithNestedValues() {
        let input = """
        let (array, dict) = ([1, 2, 3], [\"key\": \"value\"])
        """
        let output = """
        let array = [1, 2, 3]
        let dict = ["key": "value"]
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithFunctionCalls() {
        let input = """
        let (min, max) = (calculateMin(), calculateMax())
        """
        let output = """
        let min = calculateMin()
        let max = calculateMax()
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringInsideFunction() {
        let input = """
        func process() {
            let (result, error) = (try? getData(), nil)
        }
        """
        let output = """
        func process() {
            let result = try? getData()
            let error = nil
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testPreserveTupleDestructuringWithSingleValue() {
        let input = """
        let (result) = (42)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine, exclude: [.redundantParens])
    }

    func testPreserveTupleDestructuringWithNonTupleRHS() {
        let input = """
        let (foo, bar, baz) = someFunction()
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testPreserveTupleDestructuringWithMethodCall() {
        let input = """
        let (x, y) = point.coordinates()
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testPreserveTupleDestructuringWithPropertyAccess2() {
        let input = """
        let (width, height) = view.size
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithIndentation() {
        let input = """
        class Example {
            func test() {
                let (a, b, c) = (1, 2, 3)
            }
        }
        """
        let output = """
        class Example {
            func test() {
                let a = 1
                let b = 2
                let c = 3
            }
        }
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithSwitchTuple() {
        let input = """
        switch value {
        case let (x, y, z):
            break
        }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithTypeAnnotation() {
        let input = """
        let (a, b): (Int, Bool)
        """
        let output = """
        let a: Int
        let b: Bool
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithTypeAnnotationAndValues() {
        let input = """
        let (c, d): (String, Bool) = ("hello", false)
        """
        let output = """
        let c: String = \"hello\"
        let d: Bool = false
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithComplexTypes() {
        let input = """
        let (items, count): ([String], Int)
        """
        let output = """
        let items: [String]
        let count: Int
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithOptionalTypes() {
        let input = """
        var (name, age): (String?, Int?)
        """
        let output = """
        var name: String?
        var age: Int?
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithModifiersAndTypeAnnotation() {
        let input = """
        private let (width, height): (Double, Double)
        """
        let output = """
        private let width: Double
        private let height: Double
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithAttributesAndTypeAnnotation() {
        let input = """
        @available(iOS 15, *) let (x, y): (CGFloat, CGFloat)
        """
        let output = """
        @available(iOS 15, *) let x: CGFloat
        @available(iOS 15, *) let y: CGFloat
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithFunctionTypes() {
        let input = """
        let (handler, validator): ((String) -> Void, (Int) -> Bool)
        """
        let output = """
        let handler: (String) -> Void
        let validator: (Int) -> Bool
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithNestedTupleTypes() {
        let input = """
        let (point, size): ((Int, Int), (Int, Int))
        """
        let output = """
        let point: (Int, Int)
        let size: (Int, Int)
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testTupleDestructuringWithTypeAnnotationAndPartialValues() {
        let input = """
        let (result, error): (String?, Error?) = (getValue(), nil)
        """
        let output = """
        let result: String? = getValue()
        let error: Error? = nil
        """
        testFormatting(for: input, output, rule: .singlePropertyPerLine)
    }

    func testPreserveTupleDestructuringWithConditionalExpression() {
        let input = """
        let (foo, bar) =
            if baaz {
                (true, false)
            } else {
                (false, true)
            }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testPreserveTupleDestructuringWithFunctionCall() {
        let input = """
        let (result, _): DecodedResponseWithContextCompletionArgument<Response> = castQueryResponse(from: query)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testPreserveTupleDestructuringWithClosureLiteral() {
        let input = """
        let (_, observers): (Value?, Observers<Value>) = storage.mutate { storage in (nil, storage.observers) }
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testPreserveTupleDestructuringWithPropertyAccess() {
        let input = """
        let (width, height) = view.bounds.size
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }

    func testPreserveTupleDestructuringWithComplexExpression() {
        let input = """
        let (min, max) = array.isEmpty ? (0, 0) : (array.min()!, array.max()!)
        """
        testFormatting(for: input, rule: .singlePropertyPerLine)
    }
}
