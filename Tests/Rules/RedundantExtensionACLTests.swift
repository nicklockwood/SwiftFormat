//
//  RedundantExtensionACLTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 2/3/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantExtensionACLTests: XCTestCase {
    func testPublicExtensionMemberACLStripped() {
        let input = """
        public extension Foo {
            public var bar: Int { 5 }
            private static let baz = "baz"
            public func quux() {}
        }
        """
        let output = """
        public extension Foo {
            var bar: Int { 5 }
            private static let baz = "baz"
            func quux() {}
        }
        """
        testFormatting(for: input, output, rule: .redundantExtensionACL)
    }

    func testPrivateExtensionMemberACLNotStrippedUnlessFileprivate() {
        let input = """
        private extension Foo {
            fileprivate var bar: Int { 5 }
            private static let baz = "baz"
            fileprivate func quux() {}
        }
        """
        let output = """
        private extension Foo {
            var bar: Int { 5 }
            private static let baz = "baz"
            func quux() {}
        }
        """
        testFormatting(for: input, output, rule: .redundantExtensionACL)
    }
}
