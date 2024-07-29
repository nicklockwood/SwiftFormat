//
//  DuplicateImportsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class DuplicateImportsTests: XCTestCase {
    func testRemoveDuplicateImport() {
        let input = "import Foundation\nimport Foundation"
        let output = "import Foundation"
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testRemoveDuplicateConditionalImport() {
        let input = "#if os(iOS)\n    import Foo\n    import Foo\n#else\n    import Bar\n    import Bar\n#endif"
        let output = "#if os(iOS)\n    import Foo\n#else\n    import Bar\n#endif"
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveOverlappingImports() {
        let input = "import MyModule\nimport MyModule.Private"
        testFormatting(for: input, rule: .duplicateImports)
    }

    func testNoRemoveCaseDifferingImports() {
        let input = "import Auth0.Authentication\nimport Auth0.authentication"
        testFormatting(for: input, rule: .duplicateImports)
    }

    func testRemoveDuplicateImportFunc() {
        let input = "import func Foo.bar\nimport func Foo.bar"
        let output = "import func Foo.bar"
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport() {
        let input = "import Foo\n@testable import Foo"
        let output = "\n@testable import Foo"
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveTestableDuplicateImport2() {
        let input = "@testable import Foo\nimport Foo"
        let output = "@testable import Foo"
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveExportedDuplicateImport() {
        let input = "import Foo\n@_exported import Foo"
        let output = "\n@_exported import Foo"
        testFormatting(for: input, output, rule: .duplicateImports)
    }

    func testNoRemoveExportedDuplicateImport2() {
        let input = "@_exported import Foo\nimport Foo"
        let output = "@_exported import Foo"
        testFormatting(for: input, output, rule: .duplicateImports)
    }
}
