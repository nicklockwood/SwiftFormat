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
    func testModifyingDeclarations() {
        let input = """
        import FooLib

        class Foo{
            internal var bar: Bar
            public var baaz: Baaz
        }
        """

        let formatter = Formatter(tokenize(input))
        let declarations = formatter.parseDeclarations()

        let fooType = declarations[1] as! TypeDeclaration
        let barProperty = fooType.body[0] as! SimpleDeclaration
        let baazProperty = fooType.body[1] as! SimpleDeclaration

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
}
