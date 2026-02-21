//
//  DeclarationV2Tests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 10/27/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class DeclarationTests: XCTestCase {
    func testModifyingDeclarations() throws {
        let input = """
        import FooLib

        class Foo{
            internal var bar: Bar
            public var baaz: Baaz
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        let fooType = try XCTUnwrap(declarations[1] as? TypeDeclaration)
        let barProperty = try XCTUnwrap(fooType.body[0] as? SimpleDeclaration)
        let baazProperty = try XCTUnwrap(fooType.body[1] as? SimpleDeclaration)

        XCTAssertEqual(barProperty.tokens.string, """
            internal var bar: Bar\n
        """)

        XCTAssertEqual(baazProperty.tokens.string, """
            public var baaz: Baaz\n
        """)

        XCTAssertEqual(fooType.tokens.string, """
        class Foo{
            internal var bar: Bar
            public var baaz: Baaz
        }
        """)

        let fooIndex = fooType.keywordIndex
        formatter.insert(.space(" "), at: fooIndex + 3)
        formatter.insert([.keyword("final"), .space(" ")], at: fooIndex)

        for property in fooType.body {
            if let internalModifier = formatter.indexOfModifier("internal", forDeclarationAt: property.keywordIndex) {
                formatter.removeTokens(in: internalModifier ... internalModifier + 1)
            }
        }

        XCTAssertEqual(barProperty.tokens.string, """
            var bar: Bar\n
        """)

        XCTAssertEqual(baazProperty.tokens.string, """
            public var baaz: Baaz\n
        """)

        XCTAssertEqual(fooType.tokens.string, """
        final class Foo {
            var bar: Bar
            public var baaz: Baaz
        }
        """)
    }

    func testParseDeclarationsWithModuleSelectorAttribute() throws {
        let input = """
        struct Foo {
            @SwiftUI::State var foo: Int
            @SwiftUI::Environment(\\.bar) var bar: Bar
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        let fooType = try XCTUnwrap(declarations[0] as? TypeDeclaration)
        XCTAssertEqual(fooType.body.count, 2)

        let fooProperty = try XCTUnwrap(fooType.body[0] as? SimpleDeclaration)
        XCTAssertEqual(fooProperty.keyword, "var")
        XCTAssertEqual(fooProperty.modifiers, ["@SwiftUI::State"])

        let barProperty = try XCTUnwrap(fooType.body[1] as? SimpleDeclaration)
        XCTAssertEqual(barProperty.keyword, "var")
        XCTAssertEqual(barProperty.modifiers, ["@SwiftUI::Environment(\\.bar)"])
    }

    func testParseDeclarationsWithModuleSelectorAttributeOnFunc() throws {
        let input = """
        struct Foo {
            @MyModule::MyAttribute(foo, bar) func myFunction() {}
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        let fooType = try XCTUnwrap(declarations[0] as? TypeDeclaration)
        XCTAssertEqual(fooType.body.count, 1)

        let funcDecl = try XCTUnwrap(fooType.body[0] as? SimpleDeclaration)
        XCTAssertEqual(funcDecl.keyword, "func")
        XCTAssertEqual(funcDecl.modifiers, ["@MyModule::MyAttribute(foo, bar)"])
    }

    func testSwiftUIPropertyWrapperWithModuleSelector() throws {
        let input = """
        struct MyView: View {
            @SwiftUI::State var count: Int
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        let viewType = try XCTUnwrap(declarations[0] as? TypeDeclaration)
        let countProperty = try XCTUnwrap(viewType.body[0] as? SimpleDeclaration)
        XCTAssertNotNil(countProperty.swiftUIPropertyWrapper)
        XCTAssertEqual(countProperty.swiftUIPropertyWrapper, "@SwiftUI::State")
    }

    func testSwiftUIPropertyWrapperWithModuleSelectorAndArgs() throws {
        let input = """
        struct MyView: View {
            @SwiftUI::Environment(\\.colorScheme) var colorScheme
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        let viewType = try XCTUnwrap(declarations[0] as? TypeDeclaration)
        let property = try XCTUnwrap(viewType.body[0] as? SimpleDeclaration)
        XCTAssertNotNil(property.swiftUIPropertyWrapper)
        XCTAssertEqual(property.swiftUIPropertyWrapper, "@SwiftUI::Environment(\\.colorScheme)")
    }

    func testSwiftUIPropertyWrapperWithModuleSelectorCustomAttribute() throws {
        let input = """
        struct MyView: View {
            @SwiftUI::CustomWrapper var value: Int
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        let viewType = try XCTUnwrap(declarations[0] as? TypeDeclaration)
        let property = try XCTUnwrap(viewType.body[0] as? SimpleDeclaration)
        // Should match because it starts with @SwiftUI::, even if not in swiftUIPropertyWrappers list
        XCTAssertNotNil(property.swiftUIPropertyWrapper)
        XCTAssertEqual(property.swiftUIPropertyWrapper, "@SwiftUI::CustomWrapper")
    }
}
