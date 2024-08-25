//
//  MarkTypesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 9/27/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class MarkTypesTests: XCTestCase {
    func testAddsMarkBeforeTypes() {
        let input = """
        struct Foo {}
        class Bar {}
        enum Baz {}
        protocol Quux {}
        """

        let output = """
        // MARK: - Foo

        struct Foo {}

        // MARK: - Bar

        class Bar {}

        // MARK: - Baz

        enum Baz {}

        // MARK: - Quux

        protocol Quux {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testDoesntAddMarkBeforeStructWithExistingMark() {
        let input = """
        // MARK: - Foo

        struct Foo {}
        extension Foo {}
        """

        testFormatting(for: input, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testCorrectsTypoInTypeMark() {
        let input = """
        // mark: foo

        struct Foo {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo

        struct Foo {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testUpdatesMarkAfterTypeIsRenamed() {
        let input = """
        // MARK: - FooBarControllerFactory

        struct FooBarControllerBuilder {}
        extension FooBarControllerBuilder {}
        """

        let output = """
        // MARK: - FooBarControllerBuilder

        struct FooBarControllerBuilder {}
        extension FooBarControllerBuilder {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testAddsMarkBeforeTypeWithDocComment() {
        let input = """
        /// This is a doc comment with several
        /// lines of prose at the start
        ///  - And then, after the prose,
        ///  - a few bullet points just for fun
        actor Foo {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo

        /// This is a doc comment with several
        /// lines of prose at the start
        ///  - And then, after the prose,
        ///  - a few bullet points just for fun
        actor Foo {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testCustomTypeMark() {
        let input = """
        struct Foo {}
        extension Foo {}
        """

        let output = """
        // TYPE DEFINITION: Foo

        struct Foo {}
        extension Foo {}
        """

        testFormatting(
            for: input, output, rule: .markTypes,
            options: FormatOptions(typeMarkComment: "TYPE DEFINITION: %t"),
            exclude: [.emptyExtension]
        )
    }

    func testDoesNothingForExtensionWithoutProtocolConformance() {
        let input = """
        extension Foo {}
        extension Foo {}
        """

        testFormatting(for: input, rule: .markTypes, exclude: [.emptyExtension])
    }

    func preservesExistingCommentForExtensionWithNoConformances() {
        let input = """
        // MARK: Description of extension

        extension Foo {}
        extension Foo {}
        """

        testFormatting(for: input, rule: .markTypes)
    }

    func testAddsMarkCommentForExtensionWithConformance() {
        let input = """
        extension Foo: BarProtocol {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo + BarProtocol

        extension Foo: BarProtocol {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testUpdatesExtensionMarkToCorrectMark() {
        let input = """
        // MARK: - BarProtocol

        extension Foo: BarProtocol {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo + BarProtocol

        extension Foo: BarProtocol {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testAddsMarkCommentForExtensionWithMultipleConformances() {
        let input = """
        extension Foo: BarProtocol, BazProtocol {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo + BarProtocol, BazProtocol

        extension Foo: BarProtocol, BazProtocol {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testUpdatesMarkCommentWithCorrectConformances() {
        let input = """
        // MARK: - Foo + BarProtocol

        extension Foo: BarProtocol, BazProtocol {}
        extension Foo {}
        """

        let output = """
        // MARK: - Foo + BarProtocol, BazProtocol

        extension Foo: BarProtocol, BazProtocol {}
        extension Foo {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testCustomExtensionMarkComment() {
        let input = """
        struct Foo {}
        extension Foo: BarProtocol {}
        extension String: BarProtocol {}
        """

        let output = """
        // MARK: - Foo

        struct Foo {}

        // EXTENSION: - BarProtocol

        extension Foo: BarProtocol {}

        // EXTENSION: - String: BarProtocol

        extension String: BarProtocol {}
        """

        testFormatting(
            for: input, output, rule: .markTypes,
            options: FormatOptions(
                extensionMarkComment: "EXTENSION: - %t: %c",
                groupedExtensionMarkComment: "EXTENSION: - %c"
            )
        )
    }

    func testTypeAndExtensionMarksTogether() {
        let input = """
        struct Foo {}
        extension Foo: Bar {}
        extension String: Bar {}
        """

        let output = """
        // MARK: - Foo

        struct Foo {}

        // MARK: Bar

        extension Foo: Bar {}

        // MARK: - String + Bar

        extension String: Bar {}
        """

        testFormatting(for: input, output, rule: .markTypes)
    }

    func testFullyQualifiedTypeNames() {
        let input = """
        extension MyModule.Foo: MyModule.MyNamespace.BarProtocol, QuuxProtocol {}
        extension MyModule.Foo {}
        """

        let output = """
        // MARK: - MyModule.Foo + MyModule.MyNamespace.BarProtocol, QuuxProtocol

        extension MyModule.Foo: MyModule.MyNamespace.BarProtocol, QuuxProtocol {}
        extension MyModule.Foo {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testWhereClauseConformanceWithExactConstraint() {
        let input = """
        extension Array: BarProtocol where Element == String {}
        extension Array {}
        """

        let output = """
        // MARK: - Array + BarProtocol

        extension Array: BarProtocol where Element == String {}
        extension Array {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testWhereClauseConformanceWithConformanceConstraint() {
        let input = """
        extension Array: BarProtocol where Element: BarProtocol {}
        extension Array {}
        """

        let output = """
        // MARK: - Array + BarProtocol

        extension Array: BarProtocol where Element: BarProtocol {}
        extension Array {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testWhereClauseWithExactConstraint() {
        let input = """
        extension Array where Element == String {}
        extension Array {}
        """

        testFormatting(for: input, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testWhereClauseWithConformanceConstraint() {
        let input = """
        // MARK: [BarProtocol] helpers

        extension Array where Element: BarProtocol {}
        extension Rules {}
        """

        testFormatting(for: input, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testPlacesMarkAfterImports() {
        let input = """
        import Foundation
        import os

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        let output = """
        import Foundation
        import os

        // MARK: - Rules

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testPlacesMarkAfterFileHeader() {
        let input = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        let output = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        // MARK: - Rules

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testPlacesMarkAfterFileHeaderAndImports() {
        let input = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        import Foundation
        import os

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        let output = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        import Foundation
        import os

        // MARK: - Rules

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        extension Rules {}
        """

        testFormatting(for: input, output, rule: .markTypes, exclude: [.emptyExtension])
    }

    func testDoesNothingIfOnlyOneDeclaration() {
        let input = """
        //  Created by Nick Lockwood on 12/08/2016.
        //  Copyright 2016 Nick Lockwood

        import Foundation
        import os

        /// All of SwiftFormat's Rule implementation
        class Rules {}
        """

        testFormatting(for: input, rule: .markTypes)
    }

    func testMultipleExtensionsOfSameType() {
        let input = """
        extension Foo: BarProtocol {}
        extension Foo: QuuxProtocol {}
        """

        let output = """
        // MARK: - Foo + BarProtocol

        extension Foo: BarProtocol {}

        // MARK: - Foo + QuuxProtocol

        extension Foo: QuuxProtocol {}
        """

        testFormatting(for: input, output, rule: .markTypes)
    }

    func testNeverMarkTypes() {
        let input = """
        struct EmptyFoo {}
        struct EmptyBar { }
        struct EmptyBaz {

        }
        struct Quux {
            let foo = 1
        }
        """

        let options = FormatOptions(markTypes: .never)
        testFormatting(
            for: input, rule: .markTypes, options: options,
            exclude: [.emptyBraces, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .blankLinesBetweenScopes]
        )
    }

    func testMarkTypesIfNotEmpty() {
        let input = """
        struct EmptyFoo {}
        struct EmptyBar { }
        struct EmptyBaz {

        }
        struct Quux {
            let foo = 1
        }
        """

        let output = """
        struct EmptyFoo {}
        struct EmptyBar { }
        struct EmptyBaz {

        }

        // MARK: - Quux

        struct Quux {
            let foo = 1
        }
        """

        let options = FormatOptions(markTypes: .ifNotEmpty)
        testFormatting(
            for: input, output, rule: .markTypes, options: options,
            exclude: [.emptyBraces, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .blankLinesBetweenScopes]
        )
    }

    func testNeverMarkExtensions() {
        let input = """
        extension EmptyFoo: FooProtocol {}
        extension EmptyBar: BarProtocol { }
        extension EmptyBaz: BazProtocol {

        }
        extension Quux: QuuxProtocol {
            let foo = 1
        }
        """

        let options = FormatOptions(markExtensions: .never)
        testFormatting(
            for: input, rule: .markTypes, options: options,
            exclude: [.emptyBraces, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .blankLinesBetweenScopes]
        )
    }

    func testMarkExtensionsIfNotEmpty() {
        let input = """
        extension EmptyFoo: FooProtocol {}
        extension EmptyBar: BarProtocol { }
        extension EmptyBaz: BazProtocol {

        }
        extension Quux: QuuxProtocol {
            let foo = 1
        }
        """

        let output = """
        extension EmptyFoo: FooProtocol {}
        extension EmptyBar: BarProtocol { }
        extension EmptyBaz: BazProtocol {

        }

        // MARK: - Quux + QuuxProtocol

        extension Quux: QuuxProtocol {
            let foo = 1
        }
        """

        let options = FormatOptions(markExtensions: .ifNotEmpty)
        testFormatting(
            for: input, output, rule: .markTypes, options: options,
            exclude: [.emptyBraces, .blankLinesAtStartOfScope, .blankLinesAtEndOfScope, .blankLinesBetweenScopes]
        )
    }

    func testMarkExtensionsDisabled() {
        let input = """
        extension Foo: FooProtocol {}

        // swiftformat:disable markTypes

        extension Bar: BarProtocol {}

        // swiftformat:enable markTypes

        extension Baz: BazProtocol {}

        extension Quux: QuuxProtocol {}
        """

        let output = """
        // MARK: - Foo + FooProtocol

        extension Foo: FooProtocol {}

        // swiftformat:disable markTypes

        extension Bar: BarProtocol {}

        // MARK: - Baz + BazProtocol

        // swiftformat:enable markTypes

        extension Baz: BazProtocol {}

        // MARK: - Quux + QuuxProtocol

        extension Quux: QuuxProtocol {}
        """

        testFormatting(for: input, output, rule: .markTypes)
    }

    func testExtensionMarkWithImportOfSameName() {
        let input = """
        import MagazineLayout

        // MARK: - MagazineLayout + FooProtocol

        extension MagazineLayout: FooProtocol {}

        // MARK: - MagazineLayout + BarProtocol

        extension MagazineLayout: BarProtocol {}
        """

        testFormatting(for: input, rule: .markTypes)
    }

    func testDoesntUseGroupedMarkTemplateWhenSeparatedByOtherType() {
        let input = """
        // MARK: - MyComponent

        class MyComponent {}

        // MARK: - MyComponentContent

        struct MyComponentContent {}

        // MARK: - MyComponent + ContentConfigurableView

        extension MyComponent: ContentConfigurableView {}
        """

        testFormatting(for: input, rule: .markTypes)
    }

    func testUsesGroupedMarkTemplateWhenSeparatedByExtensionOfSameType() {
        let input = """
        // MARK: - MyComponent

        class MyComponent {}

        // MARK: Equatable

        extension MyComponent: Equatable {}

        // MARK: ContentConfigurableView

        extension MyComponent: ContentConfigurableView {}
        """

        testFormatting(for: input, rule: .markTypes)
    }

    func testDoesntUseGroupedMarkTemplateWhenSeparatedByExtensionOfOtherType() {
        let input = """
        // MARK: - MyComponent

        class MyComponent {}

        // MARK: - OtherComponent + Equatable

        extension OtherComponent: Equatable {}

        // MARK: - MyComponent + ContentConfigurableView

        extension MyComponent: ContentConfigurableView {}
        """

        testFormatting(for: input, rule: .markTypes)
    }

    func testAddsMarkBeforeTypesWithNoBlankLineAfterMark() {
        let input = """
        struct Foo {}
        class Bar {}
        enum Baz {}
        protocol Quux {}
        """

        let output = """
        // MARK: - Foo
        struct Foo {}

        // MARK: - Bar
        class Bar {}

        // MARK: - Baz
        enum Baz {}

        // MARK: - Quux
        protocol Quux {}
        """
        let options = FormatOptions(lineAfterMarks: false)
        testFormatting(for: input, output, rule: .markTypes, options: options)
    }

    func testAddsMarkForTypeInExtension() {
        let input = """
        enum Foo {}

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }
        }
        """

        let output = """
        // MARK: - Foo

        enum Foo {}

        // MARK: Foo.Bar

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }
        }
        """

        testFormatting(for: input, output, rule: .markTypes)
    }

    func testDoesntAddsMarkForMultipleTypesInExtension() {
        let input = """
        enum Foo {}

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }

            struct Quux {
                let baaz: Baaz
            }
        }
        """

        let output = """
        // MARK: - Foo

        enum Foo {}

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }

            struct Quux {
                let baaz: Baaz
            }
        }
        """

        testFormatting(for: input, output, rule: .markTypes)
    }

    func testAddsMarkForTypeInExtensionNotFollowingTypeBeingExtended() {
        let input = """
        struct Baaz {}

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }
        }
        """

        let output = """
        // MARK: - Baaz

        struct Baaz {}

        // MARK: - Foo.Bar

        extension Foo {
            struct Bar {
                let baaz: Baaz
            }
        }
        """

        testFormatting(for: input, output, rule: .markTypes)
    }

    func testHandlesMultipleLayersOfExtensionNesting() {
        let input = """
        enum Foo {}

        extension Foo {
            enum Bar {}
        }

        extension Foo {
            extension Bar {
                struct Baaz {
                    let quux: Quux
                }
            }
        }
        """

        let output = """
        // MARK: - Foo

        enum Foo {}

        // MARK: Foo.Bar

        extension Foo {
            enum Bar {}
        }

        // MARK: Foo.Bar.Baaz

        extension Foo {
            extension Bar {
                struct Baaz {
                    let quux: Quux
                }
            }
        }
        """

        testFormatting(for: input, output, rule: .markTypes)
    }

    func testMarkTypeLintReturnsErrorAsExpected() throws {
        let input = """
        struct MyStruct {}

        extension MyStruct {}
        """

        // Initialize rule names
        let _ = FormatRules.byName
        let changes = try lint(input, rules: [.markTypes])
        XCTAssertEqual(changes, [
            .init(line: 1, rule: .markTypes, filePath: nil, isMove: false),
            .init(line: 2, rule: .markTypes, filePath: nil, isMove: false),
        ])
    }
}
