//
//  WrapIfStatementBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 6/10/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapIfStatementBodiesTests: XCTestCase {
    func testIfElseReturnsWrap() {
        let input = """
        if foo { return bar } else if baz { return qux } else { return quux }
        """
        let output = """
        if foo {
            return bar
        } else if baz {
            return qux
        } else {
            return quux
        }
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies)
    }

    func testIfElseBodiesWrap() {
        let input = """
        if foo { bar } else if baz { qux } else { quux }
        """
        let output = """
        if foo {
            bar
        } else if baz {
            qux
        } else {
            quux
        }
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies)
    }

    func testIfElsesWithClosuresDontWrapClosures() {
        let input = """
        if foo { $0.bar } { baz } else if qux { $0.quux } { quuz } else { corge }
        """
        let output = """
        if foo { $0.bar } {
            baz
        } else if qux { $0.quux } {
            quuz
        } else {
            corge
        }
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies)
    }

    func testEmptyIfElseBodiesWithSpaceDoNothing() {
        let input = """
        if foo { } else if baz { } else { }
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies,
                       exclude: [.emptyBraces])
    }

    func testEmptyIfElseBodiesWithoutSpaceDoNothing() {
        let input = """
        if foo {} else if baz {} else {}
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies,
                       exclude: [.emptyBraces])
    }

    func testIfElseBracesStartingOnDifferentLines() {
        let input = """
        if foo
            { return bar }
        else if baz
            { return qux }
        else
            { return quux }
        """
        let output = """
        if foo
            {
                return bar
            }
        else if baz
            {
                return qux
            }
        else
            {
                return quux
            }
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies,
                       exclude: [.braces, .indent, .elseOnSameLine])
    }

    func testDoesNotWrapGuardBodies() {
        let input = """
        guard let foo = bar else { return }
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies,
                       exclude: [.wrapGuardStatementBodies])
    }

    func testDoesNotWrapMultilineGuardElse() {
        let input = """
        for item in items {
            guard
                let foo = item.foo,
                let bar = item.bar
            else { continue }
        }
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies,
                       exclude: [.wrapGuardStatementBodies])
    }

    func testWrapsIfInsideClosureOnSameLine() {
        let input = """
        XCTAssertTrue(items.contains { if case .presented = $0 { return true }
            return false
        })
        """
        let output = """
        XCTAssertTrue(items.contains {
            if case .presented = $0 {
                return true
            }
            return false
        })
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies)
    }

    func testDoesNotWrapIfExpressionFollowingAssignment() {
        let input = """
        let foo = if condition { bar } else { baz }
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testDoesNotWrapIfExpressionInFunctionBody() {
        let input = """
        func foo() -> String {
            if condition { "bar" } else { "baz" }
        }
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testDoesNotWrapIfExpressionInVarBody() {
        let input = """
        var foo: String {
            if condition { "bar" } else { "baz" }
        }
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testDoesNotWrapIfExpressionInClosureBody() {
        let input = """
        let foo = items.map { if $0 > 0 { "positive" } else { "negative" } }
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies,
                       exclude: [.wrapIfExpressionBodies])
    }

    func testWrapsIfStatementInVoidFunction() {
        let input = """
        private func setTitleText(_ titleText: StylableText?) {
            if let titleText { titleText.set(on: titleLabel) }
            else { titleLabel.text = nil }
        }
        """
        let output = """
        private func setTitleText(_ titleText: StylableText?) {
            if let titleText {
                titleText.set(on: titleLabel)
            }
            else {
                titleLabel.text = nil
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies,
                       exclude: [.elseOnSameLine])
    }

    func testWrapsIfStatementWithoutElse() {
        let input = """
        for subview in root.subviews {
            if let found = findView(withIdentifier: id, in: subview) { return found }
        }
        """
        let output = """
        for subview in root.subviews {
            if let found = findView(withIdentifier: id, in: subview) {
                return found
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies)
    }

    func testWrapsIfStatementInForLoop() {
        let input = """
        for item in items {
            if item.isValid { process(item) } else { skip(item) }
        }
        """
        let output = """
        for item in items {
            if item.isValid {
                process(item)
            } else {
                skip(item)
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies)
    }

    func testInsideStringLiteralDoesNothing() {
        let input = """
        "\\(list.map { if $0 % 2 == 0 { return 0 } else { return 1 } })"
        """
        testFormatting(for: input, rule: .wrapIfStatementBodies)
    }

    func testNestedIfElseStatementsPutOnNewline() {
        let input = """
        if foo { if bar { baz } else { qux } } else { quux }
        """
        let output = """
        if foo {
            if bar {
                baz
            } else {
                qux
            }
        } else {
            quux
        }
        """
        testFormatting(for: input, output, rule: .wrapIfStatementBodies)
    }
}
