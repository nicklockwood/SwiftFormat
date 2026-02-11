//
//  SortImportsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 8/13/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class SortImportsTests: XCTestCase {
    func testSortImportsSimpleCase() {
        let input = """
        import Foo
        import Bar
        """
        let output = """
        import Bar
        import Foo
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testSortImportsKeepsPreviousCommentWithImport() {
        let input = """
        import Foo
        // important comment
        // (very important)
        import Bar
        """
        let output = """
        // important comment
        // (very important)
        import Bar
        import Foo
        """
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testSortImportsKeepsPreviousCommentWithImport2() {
        let input = """
        // important comment
        // (very important)
        import Foo
        import Bar
        """
        let output = """
        import Bar
        // important comment
        // (very important)
        import Foo
        """
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testSortImportsDoesntMoveHeaderComment() {
        let input = """
        // header comment

        import Foo
        import Bar
        """
        let output = """
        // header comment

        import Bar
        import Foo
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testSortImportsDoesntMoveHeaderCommentFollowedByImportComment() {
        let input = """
        // header comment

        // important comment
        import Foo
        import Bar
        """
        let output = """
        // header comment

        import Bar
        // important comment
        import Foo
        """
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testSortImportsOnSameLine() {
        let input = """
        import Foo; import Bar
        import Baz
        """
        let output = """
        import Baz
        import Foo; import Bar
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testSortImportsWithSemicolonAndCommentOnSameLine() {
        let input = """
        import Foo; // foobar
        import Bar
        import Baz
        """
        let output = """
        import Bar
        import Baz
        import Foo; // foobar
        """
        testFormatting(for: input, output, rule: .sortImports, exclude: [.semicolons])
    }

    func testSortImportEnum() {
        let input = """
        import enum Foo.baz
        import Foo.bar
        """
        let output = """
        import Foo.bar
        import enum Foo.baz
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testSortImportFunc() {
        let input = """
        import func Foo.baz
        import Foo.bar
        """
        let output = """
        import Foo.bar
        import func Foo.baz
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testAlreadySortImportsDoesNothing() {
        let input = """
        import Bar
        import Foo
        """
        testFormatting(for: input, rule: .sortImports)
    }

    func testPreprocessorSortImports() {
        let input = """
        #if os(iOS)
            import Foo2
            import Bar2
        #else
            import Foo1
            import Bar1
        #endif
        import Foo3
        import Bar3
        """
        let output = """
        #if os(iOS)
            import Bar2
            import Foo2
        #else
            import Bar1
            import Foo1
        #endif
        import Bar3
        import Foo3
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testTestableSortImports() {
        let input = """
        @testable import Foo3
        import Bar3
        """
        let output = """
        import Bar3
        @testable import Foo3
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testLengthSortImports() {
        let input = """
        import Foo
        import Module
        import Bar3
        """
        let output = """
        import Foo
        import Bar3
        import Module
        """
        let options = FormatOptions(importGrouping: .length)
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testTestableImportsWithTestableOnPreviousLine() {
        let input = """
        @testable
        import Foo3
        import Bar3
        """
        let output = """
        import Bar3
        @testable
        import Foo3
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testTestableImportsWithGroupingTestableBottom() {
        let input = """
        @testable import Bar
        import Foo
        @testable import UIKit
        """
        let output = """
        import Foo
        @testable import Bar
        @testable import UIKit
        """
        let options = FormatOptions(importGrouping: .testableLast)
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testTestableImportsWithGroupingTestableTop() {
        let input = """
        @testable import Bar
        import Foo
        @testable import UIKit
        """
        let output = """
        @testable import Bar
        @testable import UIKit
        import Foo
        """
        let options = FormatOptions(importGrouping: .testableFirst)
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testCaseInsensitiveSortImports() {
        let input = """
        import Zlib
        import lib
        """
        let output = """
        import lib
        import Zlib
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testCaseInsensitiveCaseDifferingSortImports() {
        let input = """
        import c
        import B
        import A.a
        import A.A
        """
        let output = """
        import A.A
        import A.a
        import B
        import c
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testNoDeleteCodeBetweenImports() {
        let input = """
        import Foo
        func bar() {}
        import Bar
        """
        testFormatting(for: input, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testNoDeleteCodeBetweenImports2() {
        let input = """
        import Foo
        import Bar
        foo = bar
        import Bar
        """
        let output = """
        import Bar
        import Foo
        foo = bar
        import Bar
        """
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testNoDeleteCodeBetweenImports3() {
        let input = """
        import Z

        // one

        #if FLAG
            print("hi")
        #endif

        import A
        """
        testFormatting(for: input, rule: .sortImports)
    }

    func testSortContiguousImports() {
        let input = """
        import Foo
        import Bar
        func bar() {}
        import Quux
        import Baz
        """
        let output = """
        import Bar
        import Foo
        func bar() {}
        import Baz
        import Quux
        """
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testNoMangleImportsPrecededByComment() {
        let input = """
        // evil comment

        #if canImport(Foundation)
            import Foundation
            #if canImport(UIKit) && canImport(AVFoundation)
                import UIKit
                import AVFoundation
            #endif
        #endif
        """
        let output = """
        // evil comment

        #if canImport(Foundation)
            import Foundation
            #if canImport(UIKit) && canImport(AVFoundation)
                import AVFoundation
                import UIKit
            #endif
        #endif
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testNoMangleFileHeaderNotFollowedByLinebreak() {
        let input = """
        //
        //  Code.swift
        //  Module
        //
        //  Created by Someone on 4/30/20.
        //
        import AModuleUI
        import AModule
        import AModuleHelper
        import SomeOtherModule
        """
        let output = """
        //
        //  Code.swift
        //  Module
        //
        //  Created by Someone on 4/30/20.
        //
        import AModule
        import AModuleHelper
        import AModuleUI
        import SomeOtherModule
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testNoMoveSwiftToolsVersionLine() {
        let input = """
        // swift-tools-version: 6.2
        import PackageDescription
        import CompilerPluginSupport
        """
        let output = """
        // swift-tools-version: 6.2
        import CompilerPluginSupport
        import PackageDescription
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testAccessControlSortImports() {
        let input = """
        import Foo
        private import Bar
        public import Baz
        """
        let output = """
        public import Baz
        private import Bar
        import Foo
        """
        var options = FormatOptions.default
        options.importSortByAccessControl = true
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testAccessControlSortAlphaWithinLevel() {
        let input = """
        public import Zebra
        public import Alpha
        public import Middle
        """
        let output = """
        public import Alpha
        public import Middle
        public import Zebra
        """
        var options = FormatOptions.default
        options.importSortByAccessControl = true
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testAccessControlWithTestableFirst() {
        // With testableFirst + importSortByAccessControl: testable group first, then by access within each group
        let input = """
        import Foo
        @testable import Bar
        public import Baz
        @testable public import Qux
        """
        let output = """
        @testable import Bar
        public import Baz
        import Foo
        @testable public import Qux
        """
        var options = FormatOptions.default
        options.importGrouping = .testableFirst
        options.importSortByAccessControl = true
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testAccessControlWithTestableLast() {
        let input = """
        public import Baz
        @testable import Bar
        import Foo
        """
        let output = """
        public import Baz
        import Foo
        @testable import Bar
        """
        var options = FormatOptions.default
        options.importGrouping = .testableLast
        options.importSortByAccessControl = true
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }
}
