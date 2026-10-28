//
//  DuplicateImportsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 2/7/18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class DuplicateImportsTests: XCTestCase {
    func testRemoveDuplicateImportsBelowCode() {
        let input = """
        import Foundation

        struct Foo {}

        import Foundation

        struct Bar {}
        """
        let output = """
        import Foundation

        struct Foo {}

        struct Bar {}
        """
        testFormatting(for: input, output, rule: .duplicateImports)
        testFormatting(for: input, output, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testRemoveDuplicateImportsBetweenDeclarations() {
        let input = """
        import Foundation

        struct Foo {}

        import Foundation

        struct Bar {}

        import Foundation

        struct Baz {}
        """
        let output = """
        import Foundation

        struct Foo {}

        struct Bar {}

        struct Baz {}
        """
        testFormatting(for: input, output, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testKeepImportsInDifferentConditions() {
        let input = """
        #if os(iOS)
            import Foundation
        #endif

        struct Foo {}

        #if os(macOS)
            import Foundation
        #endif
        """
        testFormatting(for: input, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testKeepConditionalAndUnconditionalImports() {
        let input = """
        import Foundation

        struct Foo {}

        #if canImport(Foundation)
            import Foundation
        #else
            import Foundation
        #endif

        struct Bar {}
        """
        testFormatting(for: input, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testKeepImportsSeparatedByCodeInsideCondition() {
        let input = """
        #if os(iOS)
            import Foundation

            struct Foo {}

            import Foundation

            struct Bar {}
        #endif
        """
        testFormatting(for: input, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testKeepAttributedImportsAcrossGroups() {
        let input = """
        @testable import Foundation

        struct Foo {}

        import Foundation

        struct Bar {}

        @_spi(Testing) import Foundation

        struct Baz {}
        """
        testFormatting(for: input, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testKeepImportAccessLevelsAcrossGroups() {
        let input = """
        public import Foundation

        struct Foo {}

        internal import Foundation

        struct Bar {}

        import Foundation

        struct Baz {}
        """
        testFormatting(for: input, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testKeepCommentsOnDuplicateImportsAcrossGroups() {
        let input = """
        import Foundation

        struct Foo {}

        // Keep this explanation.
        import Foundation // Used below.

        struct Bar {}
        """
        testFormatting(for: input, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testKeepSelectiveImportsAcrossGroups() {
        let input = """
        import func Foo.bar

        struct First {}

        import var Foo.bar

        struct Second {}
        """
        testFormatting(for: input, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testKeepImportsAcrossGroupsInFragment() {
        let input = """
        import Foundation

        struct Foo {}

        import Foundation

        struct Bar {}
        """
        let options = FormatOptions(hoistImports: false, fragment: true)
        testFormatting(for: input, rule: .duplicateImports, options: options)
    }

    func testKeepCodeOnDuplicateImportLine() {
        let input = """
        import Foundation

        struct Foo {}

        import Foundation; let value = 1

        struct Bar {}
        """
        testFormatting(for: input, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

    func testRemoveDuplicateImportAfterCommentedImport() {
        let input = """
        // Module dependencies.
        import Foundation

        struct Foo {}

        import Foundation

        struct Bar {}
        """
        let output = """
        // Module dependencies.
        import Foundation

        struct Foo {}

        struct Bar {}
        """
        testFormatting(for: input, output, rule: .duplicateImports, options: FormatOptions(hoistImports: false))
    }

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

    func testNoRemoveImportsWithDifferentAttributes() {
        let input = """
        @testable import Foo
        @_spi(Bar) import Foo
        """
        testFormatting(for: input, rule: .duplicateImports)
    }

    func testNoRemoveImportsWithDifferentAttributes2() {
        let input = """
        @_spi(Bar) import Foo
        @testable import Foo
        """
        testFormatting(for: input, rule: .duplicateImports)
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
