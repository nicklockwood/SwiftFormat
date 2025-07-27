//
//  DuplicateImportsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 2/7/18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class DuplicateImportsTests: XCTestCase {
    func testRemoveDuplicateImport() {
        let input = """
        import Foundation
        import Foundation
        """
        let output = """
        import Foundation
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testRemoveDuplicateConditionalImport() {
        let input = """
        #if os(iOS)
            import Foo
            import Foo
        #else
            import Bar
            import Bar
        #endif
        """
        let output = """
        #if os(iOS)
            import Foo
        #else
            import Bar
        #endif
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveOverlappingImports() {
        let input = """
        import MyModule
        import MyModule.Private
        """
        testFormatting(for: input, rule: .duplicateImports)
    }

    func testNoRemoveCaseDifferingImports() {
        let input = """
        import Auth0.Authentication
        import Auth0.authentication
        """
        testFormatting(for: input, rule: .duplicateImports)
    }

    func testRemoveDuplicateImportFunc() {
        let input = """
        import func Foo.bar
        import func Foo.bar
        """
        let output = """
        import func Foo.bar
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport() {
        let input = """
        import Foo
        @testable import Foo
        """
        let output = """

        @testable import Foo
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport2() {
        let input = """
        @testable import Foo
        import Foo
        """
        let output = """
        @testable import Foo
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveExportedDuplicateImport() {
        let input = """
        import Foo
        @_exported import Foo
        """
        let output = """

        @_exported import Foo
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveExportedDuplicateImport2() {
        let input = """
        @_exported import Foo
        import Foo
        """
        let output = """
        @_exported import Foo
        """
        testFormatting(for: input, output, rule: .duplicateImports)
    }
}
