//
//  BlankLineAfterImportsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class BlankLineAfterImportsTests: XCTestCase {
    func testBlankLineAfterImport() {
        let input = """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @_exported import ModuleE
        @_implementationOnly import ModuleF
        @_spi(SPI) import ModuleG
        @_spiOnly import ModuleH
        @preconcurrency import ModuleI
        class foo {}
        """
        let output = """
        import ModuleA
        @testable import ModuleB
        import ModuleC
        @testable import ModuleD
        @_exported import ModuleE
        @_implementationOnly import ModuleF
        @_spi(SPI) import ModuleG
        @_spiOnly import ModuleH
        @preconcurrency import ModuleI

        class foo {}
        """
        testFormatting(for: input, output, rule: .blankLineAfterImports)
    }

    func testBlankLinesBetweenConditionalImports() {
        let input = """
        #if foo
            import ModuleA
        #else
            import ModuleB
        #endif
        import ModuleC
        func foo() {}
        """
        let output = """
        #if foo
            import ModuleA
        #else
            import ModuleB
        #endif
        import ModuleC

        func foo() {}
        """
        testFormatting(for: input, output, rule: .blankLineAfterImports)
    }

    func testBlankLinesBetweenNestedConditionalImports() {
        let input = """
        #if foo
            import ModuleA
            #if bar
                import ModuleB
            #endif
        #else
            import ModuleC
        #endif
        import ModuleD
        func foo() {}
        """
        let output = """
        #if foo
            import ModuleA
            #if bar
                import ModuleB
            #endif
        #else
            import ModuleC
        #endif
        import ModuleD

        func foo() {}
        """
        testFormatting(for: input, output, rule: .blankLineAfterImports)
    }

    func testBlankLineAfterScopedImports() {
        let input = """
        internal import UIKit
        internal import Foundation
        private import Time
        public class Foo {}
        """
        let output = """
        internal import UIKit
        internal import Foundation
        private import Time

        public class Foo {}
        """
        testFormatting(for: input, output, rule: .blankLineAfterImports)
    }
}
