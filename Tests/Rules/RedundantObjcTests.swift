//
//  RedundantObjcTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 1/30/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class RedundantObjcTests: XCTestCase {
    func testRedundantObjcRemovedFromBeforeOutlet() {
        let input = """
        @objc @IBOutlet var label: UILabel!
        """
        let output = """
        @IBOutlet var label: UILabel!
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }

    func testRedundantObjcRemovedFromAfterOutlet() {
        let input = """
        @IBOutlet @objc var label: UILabel!
        """
        let output = """
        @IBOutlet var label: UILabel!
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }

    func testRedundantObjcRemovedFromLineBeforeOutlet() {
        let input = """
        @objc
        @IBOutlet var label: UILabel!
        """
        let output = """

        @IBOutlet var label: UILabel!
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }

    func testRedundantObjcCommentNotRemoved() {
        let input = """
        @objc /// an outlet
        @IBOutlet var label: UILabel!
        """
        let output = """
        /// an outlet
        @IBOutlet var label: UILabel!
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }

    func testObjcNotRemovedFromNSCopying() {
        let input = """
        @objc @NSCopying var foo: String!
        """
        testFormatting(for: input, rule: .redundantObjc)
    }

    func testRenamedObjcNotRemoved() {
        let input = """
        @IBOutlet @objc(uiLabel) var label: UILabel!
        """
        testFormatting(for: input, rule: .redundantObjc)
    }

    func testObjcRemovedOnObjcMembersClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc var foo: String
        }
        """
        let output = """
        @objcMembers class Foo: NSObject {
            var foo: String
        }
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }

    func testObjcRemovedOnRenamedObjcMembersClass() {
        let input = """
        @objcMembers @objc(OCFoo) class Foo: NSObject {
            @objc var foo: String
        }
        """
        let output = """
        @objcMembers @objc(OCFoo) class Foo: NSObject {
            var foo: String
        }
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }

    func testObjcNotRemovedOnNestedClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc class Bar: NSObject {}
        }
        """
        testFormatting(for: input, rule: .redundantObjc)
    }

    func testObjcNotRemovedOnRenamedPrivateNestedClass() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private class Bar: NSObject {}
        }
        """
        testFormatting(for: input, rule: .redundantObjc)
    }

    func testObjcNotRemovedOnNestedEnum() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc enum Bar: Int {}
        }
        """
        testFormatting(for: input, rule: .redundantObjc)
    }

    func testObjcRemovedOnObjcExtensionVar() {
        let input = """
        @objc extension Foo {
            @objc var foo: String {}
        }
        """
        let output = """
        @objc extension Foo {
            var foo: String {}
        }
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }

    func testObjcRemovedOnObjcExtensionFunc() {
        let input = """
        @objc extension Foo {
            @objc func foo() -> String {}
        }
        """
        let output = """
        @objc extension Foo {
            func foo() -> String {}
        }
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }

    func testObjcNotRemovedOnPrivateFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private func bar() {}
        }
        """
        testFormatting(for: input, rule: .redundantObjc)
    }

    func testObjcNotRemovedOnFileprivateFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc fileprivate func bar() {}
        }
        """
        testFormatting(for: input, rule: .redundantObjc)
    }

    func testObjcRemovedOnPrivateSetFunc() {
        let input = """
        @objcMembers class Foo: NSObject {
            @objc private(set) func bar() {}
        }
        """
        let output = """
        @objcMembers class Foo: NSObject {
            private(set) func bar() {}
        }
        """
        testFormatting(for: input, output, rule: .redundantObjc)
    }
}
