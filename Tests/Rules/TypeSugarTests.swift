//
//  TypeSugarTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 2/2/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class TypeSugarTests: XCTestCase {
    // arrays

    func testArrayTypeConvertedToSugar() {
        let input = """
        var foo: Array<String>
        """
        let output = """
        var foo: [String]
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    func testSwiftArrayTypeConvertedToSugar() {
        let input = """
        var foo: Swift.Array<String>
        """
        let output = """
        var foo: [String]
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    func testArrayNestedTypeAliasNotConvertedToSugar() {
        let input = """
        typealias Indices = Array<Foo>.Indices
        """
        testFormatting(for: input, rule: .typeSugar)
    }

    func testArrayTypeReferenceConvertedToSugar() {
        let input = """
        let type = Array<Foo>.Type
        """
        let output = """
        let type = [Foo].Type
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    func testSwiftArrayTypeReferenceConvertedToSugar() {
        let input = """
        let type = Swift.Array<Foo>.Type
        """
        let output = """
        let type = [Foo].Type
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    func testArraySelfReferenceConvertedToSugar() {
        let input = """
        let type = Array<Foo>.self
        """
        let output = """
        let type = [Foo].self
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    func testSwiftArraySelfReferenceConvertedToSugar() {
        let input = """
        let type = Swift.Array<Foo>.self
        """
        let output = """
        let type = [Foo].self
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    func testArrayDeclarationNotConvertedToSugar() {
        let input = """
        struct Array<Element> {}
        """
        testFormatting(for: input, rule: .typeSugar)
    }

    func testExtensionTypeSugar() {
        let input = """
        extension Array<Foo> {}
        extension Optional<Foo> {}
        extension Dictionary<Foo, Bar> {}
        extension Optional<Array<Dictionary<Foo, Array<Bar>>>> {}
        """

        let output = """
        extension [Foo] {}
        extension Foo? {}
        extension [Foo: Bar] {}
        extension [[Foo: [Bar]]]? {}
        """
        testFormatting(for: input, output, rule: .typeSugar, exclude: [.emptyExtensions])
    }

    // dictionaries

    func testDictionaryTypeConvertedToSugar() {
        let input = """
        var foo: Dictionary<String, Int>
        """
        let output = """
        var foo: [String: Int]
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    func testSwiftDictionaryTypeConvertedToSugar() {
        let input = """
        var foo: Swift.Dictionary<String, Int>
        """
        let output = """
        var foo: [String: Int]
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    // optionals

    func testOptionalPropertyTypeNotConvertedToSugarByDefault() {
        let input = """
        var bar: Optional<String>
        """
        testFormatting(for: input, rule: .typeSugar)
    }

    func testOptionalTypeConvertedToSugar() {
        let input = """
        var foo: Optional<String>
        """
        let output = """
        var foo: String?
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testSwiftOptionalTypeConvertedToSugar() {
        let input = """
        var foo: Swift.Optional<String>
        """
        let output = """
        var foo: String?
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testOptionalClosureParenthesizedConvertedToSugar() {
        let input = """
        var foo: Optional<(Int) -> String>
        """
        let output = """
        var foo: ((Int) -> String)?
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testOptionalTupleWrappedInParensConvertedToSugar() {
        let input = """
        let foo: Optional<(foo: Int, bar: String)>
        """
        let output = """
        let foo: (foo: Int, bar: String)?
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testOptionalComposedProtocolWrappedInParensConvertedToSugar() {
        let input = """
        let foo: Optional<UIView & Foo>
        """
        let output = """
        let foo: (UIView & Foo)?
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testSwiftOptionalClosureParenthesizedConvertedToSugar() {
        let input = """
        var foo: Swift.Optional<(Int) -> String>
        """
        let output = """
        var foo: ((Int) -> String)?
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testStrippingSwiftNamespaceInOptionalTypeWhenConvertedToSugar() {
        let input = """
        Swift.Optional<String>
        """
        let output = """
        String?
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    func testStrippingSwiftNamespaceDoesNotStripPreviousSwiftNamespaceReferences() {
        let input = """
        let a: Swift.String = Optional<String>
        """
        let output = """
        let a: Swift.String = String?
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testOptionalTypeInsideCaseConvertedToSugar() {
        let input = """
        if case .some(Optional<Any>.some(let foo)) = bar else {}
        """
        let output = """
        if case .some(Any?.some(let foo)) = bar else {}
        """
        testFormatting(for: input, output, rule: .typeSugar, exclude: [.hoistPatternLet])
    }

    func testSwitchCaseOptionalNotReplaced() {
        let input = """
        switch foo {
        case Optional<Any>.none:
        }
        """
        testFormatting(for: input, rule: .typeSugar)
    }

    func testCaseOptionalNotReplaced2() {
        let input = """
        if case Optional<Any>.none = foo {}
        """
        testFormatting(for: input, rule: .typeSugar)
    }

    func testUnwrappedOptionalSomeParenthesized() {
        let input = """
        func foo() -> Optional<some Publisher<String, Never>> {}
        """
        let output = """
        func foo() -> (some Publisher<String, Never>)? {}
        """
        testFormatting(for: input, output, rule: .typeSugar)
    }

    // swift parser bug

    func testAvoidSwiftParserBugWithClosuresInsideArrays() {
        let input = """
        var foo = Array<(_ image: Data?) -> Void>()
        """
        testFormatting(for: input, rule: .typeSugar, options: FormatOptions(shortOptionals: .always), exclude: [.propertyTypes])
    }

    func testAvoidSwiftParserBugWithClosuresInsideDictionaries() {
        let input = """
        var foo = Dictionary<String, (_ image: Data?) -> Void>()
        """
        testFormatting(for: input, rule: .typeSugar, options: FormatOptions(shortOptionals: .always), exclude: [.propertyTypes])
    }

    func testAvoidSwiftParserBugWithClosuresInsideOptionals() {
        let input = """
        var foo = Optional<(_ image: Data?) -> Void>()
        """
        testFormatting(for: input, rule: .typeSugar, options: FormatOptions(shortOptionals: .always), exclude: [.propertyTypes])
    }

    func testDontOverApplyBugWorkaround() {
        let input = """
        var foo: Array<(_ image: Data?) -> Void>
        """
        let output = """
        var foo: [(_ image: Data?) -> Void]
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testDontOverApplyBugWorkaround2() {
        let input = """
        var foo: Dictionary<String, (_ image: Data?) -> Void>
        """
        let output = """
        var foo: [String: (_ image: Data?) -> Void]
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testDontOverApplyBugWorkaround3() {
        let input = """
        var foo: Optional<(_ image: Data?) -> Void>
        """
        let output = """
        var foo: ((_ image: Data?) -> Void)?
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options)
    }

    func testDontOverApplyBugWorkaround4() {
        let input = """
        var foo = Array<(image: Data?) -> Void>()
        """
        let output = """
        var foo = [(image: Data?) -> Void]()
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options, exclude: [.propertyTypes])
    }

    func testDontOverApplyBugWorkaround5() {
        let input = """
        var foo = Array<(Data?) -> Void>()
        """
        let output = """
        var foo = [(Data?) -> Void]()
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options, exclude: [.propertyTypes])
    }

    func testDontOverApplyBugWorkaround6() {
        let input = """
        var foo = Dictionary<Int, Array<(_ image: Data?) -> Void>>()
        """
        let output = """
        var foo = [Int: Array<(_ image: Data?) -> Void>]()
        """
        let options = FormatOptions(shortOptionals: .always)
        testFormatting(for: input, output, rule: .typeSugar, options: options, exclude: [.propertyTypes])
    }
}
