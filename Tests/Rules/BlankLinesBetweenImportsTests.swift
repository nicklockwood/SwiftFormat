//
//  BlankLinesBetweenImportsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class BlankLinesBetweenImportsTests: XCTestCase {
    func testBlankLinesBetweenImportsShort() {
        let input = """
        import ModuleA

        import ModuleB
        """
        let output = """
        import ModuleA
        import ModuleB
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenImports)
    }

    func testBlankLinesBetweenImportsLong() {
        let input = """
        import ModuleA
        import ModuleB

        import ModuleC
        import ModuleD
        import ModuleE

        import ModuleF

        import ModuleG
        import ModuleH
        """
        let output = """
        import ModuleA
        import ModuleB
        import ModuleC
        import ModuleD
        import ModuleE
        import ModuleF
        import ModuleG
        import ModuleH
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenImports)
    }

    func testBlankLinesBetweenImportsWithTestable() {
        let input = """
        import ModuleA

        @testable import ModuleB
        import ModuleC

        @testable import ModuleD
        @testable import ModuleE

        @testable import ModuleF
        """
        let output = """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @testable import ModuleE
        @testable import ModuleF
        """
        testFormatting(for: input, output, rule: .blankLinesBetweenImports)
    }
}
