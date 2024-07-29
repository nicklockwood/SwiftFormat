//
//  RedundantInternalTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantInternalTests: XCTestCase {
    func testRemoveRedundantInternalACL() {
        let input = """
        internal class Foo {
            internal let bar: String

            internal func baaz() {}

            internal init() {
                bar = "bar"
            }
        }
        """

        let output = """
        class Foo {
            let bar: String

            func baaz() {}

            init() {
                bar = "bar"
            }
        }
        """

        testFormatting(for: input, output, rule: .redundantInternal)
    }

    func testPreserveInternalInNonInternalExtensionExtension() {
        let input = """
        extension Foo {
            /// internal is redundant here since the extension is internal
            internal func bar() {}

            public func baaz() {}

            /// internal is redundant here since the extension is internal
            internal func bar() {}
        }

        public extension Foo {
            /// internal is not redundant here since the extension is public
            internal func bar() {}

            public func baaz() {}

            /// internal is not redundant here since the extension is public
            internal func bar() {}
        }
        """

        let output = """
        extension Foo {
            /// internal is redundant here since the extension is internal
            func bar() {}

            public func baaz() {}

            /// internal is redundant here since the extension is internal
            func bar() {}
        }

        public extension Foo {
            /// internal is not redundant here since the extension is public
            internal func bar() {}

            public func baaz() {}

            /// internal is not redundant here since the extension is public
            internal func bar() {}
        }
        """

        testFormatting(for: input, output, rule: .redundantInternal, exclude: [.redundantExtensionACL])
    }

    func testPreserveInternalImport() {
        let input = "internal import MyPackage"
        testFormatting(for: input, rule: .redundantInternal)
    }

    func testPreservesInternalInPublicExtensionWithWhereClause() {
        let input = """
        public extension SomeProtocol where SomeAssociatedType == SomeOtherType {
            internal func fun1() {}
            func fun2() {}
        }

        public extension OtherProtocol<GenericArgument> {
            internal func fun1() {}
            func fun2() {}
        }
        """
        testFormatting(for: input, rule: .redundantInternal)
    }
}
