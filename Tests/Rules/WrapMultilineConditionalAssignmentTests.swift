//
//  WrapMultilineConditionalAssignmentTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class WrapMultilineConditionalAssignmentTests: XCTestCase {
    func testWrapIfExpressionAssignment() {
        let input = """
        let foo = if let bar {
            bar
        } else {
            baaz
        }
        """

        let output = """
        let foo =
            if let bar {
                bar
            } else {
                baaz
            }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
    }

    func testUnwrapsAssignmentOperatorInIfExpressionAssignment() {
        let input = """
        let foo
            = if let bar {
                bar
            } else {
                baaz
            }
        """

        let output = """
        let foo =
            if let bar {
                bar
            } else {
                baaz
            }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
    }

    func testUnwrapsAssignmentOperatorInIfExpressionFollowingComment() {
        let input = """
        let foo
            // In order to unwrap the `=` here it has to move it to
            // before the comment, rather than simply unwrapping it.
            = if let bar {
                bar
            } else {
                baaz
            }
        """

        let output = """
        let foo =
            // In order to unwrap the `=` here it has to move it to
            // before the comment, rather than simply unwrapping it.
            if let bar {
                bar
            } else {
                baaz
            }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
    }

    func testWrapIfAssignmentWithoutIntroducer() {
        let input = """
        property = if condition {
            Foo("foo")
        } else {
            Foo("bar")
        }
        """

        let output = """
        property =
            if condition {
                Foo("foo")
            } else {
                Foo("bar")
            }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
    }

    func testWrapSwitchAssignmentWithoutIntroducer() {
        let input = """
        property = switch condition {
        case true:
            Foo("foo")
        case false:
            Foo("bar")
        }
        """

        let output = """
        property =
            switch condition {
            case true:
                Foo("foo")
            case false:
                Foo("bar")
            }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
    }

    func testWrapSwitchAssignmentWithComplexLValue() {
        let input = """
        property?.foo!.bar["baaz"] = switch condition {
        case true:
            Foo("foo")
        case false:
            Foo("bar")
        }
        """

        let output = """
        property?.foo!.bar["baaz"] =
            switch condition {
            case true:
                Foo("foo")
            case false:
                Foo("bar")
            }
        """

        testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
    }
}
