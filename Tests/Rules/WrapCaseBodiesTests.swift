//
//  WrapCaseBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Kim de Vos on 3/23/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapCaseBodiesTests: XCTestCase {
    func testWrapSingleLineCaseBody() {
        let input = """
        switch foo {
        case .bar: return bar
        default: return baz
        }
        """
        let output = """
        switch foo {
        case .bar:
            return bar
        default:
            return baz
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies)
    }

    func testAlreadyWrappedCaseBodiesUnchanged() {
        let input = """
        switch foo {
        case .bar:
            return bar
        default:
            return baz
        }
        """
        testFormatting(for: input, rule: .wrapCaseBodies)
    }

    func testWrapDefaultCaseBody() {
        let input = """
        switch foo {
        case .bar: break
        default: return baz
        }
        """
        let output = """
        switch foo {
        case .bar:
            break
        default:
            return baz
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies)
    }

    func testWrapMultiPatternCaseBody() {
        let input = """
        switch foo {
        case .bar, .baz: return quux
        default: break
        }
        """
        let output = """
        switch foo {
        case .bar, .baz:
            return quux
        default:
            break
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies,
                       exclude: [.wrapSwitchCases])
    }

    func testWrapCaseWithWhereClause() {
        let input = """
        switch foo {
        case let x where x > 0: return x
        default: return 0
        }
        """
        let output = """
        switch foo {
        case let x where x > 0:
            return x
        default:
            return 0
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies)
    }

    func testCaseWithCommentAfterColonUnchanged() {
        let input = """
        switch foo {
        case .bar: // comment
            return bar
        default:
            return baz
        }
        """
        testFormatting(for: input, rule: .wrapCaseBodies,
                       exclude: [.blankLineAfterSwitchCase])
    }

    func testWrapUnknownDefaultCaseBody() {
        let input = """
        switch foo {
        case .bar: return bar
        @unknown default: return baz
        }
        """
        let output = """
        switch foo {
        case .bar:
            return bar
        @unknown default:
            return baz
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies)
    }

    func testWrapNestedSwitchCaseBodies() {
        let input = """
        switch foo {
        case .bar:
            switch baz {
            case .a: return a
            case .b: return b
            default: return c
            }
        default: return other
        }
        """
        let output = """
        switch foo {
        case .bar:
            switch baz {
            case .a:
                return a
            case .b:
                return b
            default:
                return c
            }
        default:
            return other
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies,
                       exclude: [.blankLineAfterSwitchCase])
    }

    func testWrapCaseBodiesFullExample() {
        let input = """
        extension Int {
            var foo: String {
                switch self {
                case 0: return "zero"
                case 1: return "one"
                case 2: return "two"
                default: return "other"
                }
            }
        }
        """
        let output = """
        extension Int {
            var foo: String {
                switch self {
                case 0:
                    return "zero"
                case 1:
                    return "one"
                case 2:
                    return "two"
                default:
                    return "other"
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies)
    }

    func testWrapCaseBodyWithAssignment() {
        let input = """
        switch foo {
        case .bar: baz = true
        default: baz = false
        }
        """
        let output = """
        switch foo {
        case .bar:
            baz = true
        default:
            baz = false
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies)
    }

    func testWrapSwitchExpressionCaseBodies() {
        let input = """
        extension Int {
            var foo: String {
                return switch self {
                case 0: "zero"
                case 1: "one"
                case 2: "two"
                default: "other"
                }
            }
        }
        """
        let output = """
        extension Int {
            var foo: String {
                return switch self {
                case 0:
                    "zero"
                case 1:
                    "one"
                case 2:
                    "two"
                default:
                    "other"
                }
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapCaseBodies)
    }
}
