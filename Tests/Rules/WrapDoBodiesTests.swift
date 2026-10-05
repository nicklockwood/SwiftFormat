//
//  WrapDoBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Kim de Vos on 10/5/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapDoBodiesTests: XCTestCase {
    func testWrapDoBody() {
        let input = """
        do { try performOperation() }
        """
        let output = """
        do {
            try performOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapDoBodies)
    }

    func testWrapAsyncDoBody() {
        let input = """
        do { _ = try await performOperation() }
        """
        let output = """
        do {
            _ = try await performOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapDoBodies)
    }

    func testWrapTypedThrowsDoBody() {
        let input = """
        do throws(OperationError) { try performOperation() }
        """
        let output = """
        do throws(OperationError) {
            try performOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapDoBodies)
    }

    func testWrapDoCatchBodies() {
        let input = """
        do { try performOperation() } catch { handleError(error) }
        """
        let output = """
        do {
            try performOperation()
        } catch {
            handleError(error)
        }
        """
        testFormatting(for: input, output, rule: .wrapDoBodies)
    }

    func testWrapMultipleCatchBodies() {
        let input = """
        do { try performOperation() } catch OperationError.failed { retry() } catch let failure { handleError(failure) }
        """
        let output = """
        do {
            try performOperation()
        } catch OperationError.failed {
            retry()
        } catch let failure {
            handleError(failure)
        }
        """
        testFormatting(for: input, output, rule: .wrapDoBodies)
    }

    func testWrapCatchWithWhereClause() {
        let input = """
        do { try performOperation() } catch let error where error.shouldRetry { retry() }
        """
        let output = """
        do {
            try performOperation()
        } catch let error where error.shouldRetry {
            retry()
        }
        """
        testFormatting(for: input, output, rule: .wrapDoBodies)
    }

    func testWrapNestedDoBody() {
        let input = """
        do {
            do { try performOperation() }
        }
        """
        let output = """
        do {
            do {
                try performOperation()
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapDoBodies)
    }

    func testPreserveComments() {
        let input = """
        do { /* perform operation */ try performOperation() /* finished */ } catch { /* handle failure */ handleError(error) }
        """
        let output = """
        do { /* perform operation */
            try performOperation() /* finished */
        } catch { /* handle failure */
            handleError(error)
        }
        """
        testFormatting(for: input, output, rule: .wrapDoBodies)
    }

    func testPreserveLineComment() {
        let input = """
        do { // perform operation
            try performOperation()
        }
        """
        testFormatting(for: input, rule: .wrapDoBodies)
    }

    func testEmptyBodiesUnchanged() {
        let input = """
        do {} catch {}
        do { /* empty */ } catch { /* empty */ }
        """
        testFormatting(for: input, rule: .wrapDoBodies)
    }

    func testMultilineBodiesUnchanged() {
        let input = """
        do {
            try performOperation()
        } catch {
            handleError(error)
        }
        """
        testFormatting(for: input, rule: .wrapDoBodies)
    }

    func testConfiguredIndentAndLinebreaks() {
        let input = """
        do { try performOperation() }
        """
        let output = """
        do {
          try performOperation()
        }
        """
        let options = FormatOptions(indent: "  ", linebreak: "\r\n")
        testFormatting(for: input, output.replacingOccurrences(of: "\n", with: "\r\n"),
                       rule: .wrapDoBodies, options: options)
    }

    func testCatchOnNextLine() {
        let input = """
        do { try performOperation() } catch { handleError(error) }
        """
        let output = """
        do {
            try performOperation()
        }
        catch {
            handleError(error)
        }
        """
        testFormatting(for: input, [output], rules: [.wrapDoBodies, .indent, .elseOnSameLine],
                       options: FormatOptions(elsePosition: .nextLine))
    }

    func testSingleLineStringInterpolationUnchanged() {
        let input = """
        "\\(values.map { value in do { return value } })"
        """
        testFormatting(for: input, rule: .wrapDoBodies)
    }

    func testMultilineStringInterpolationWithWrappingDisabled() {
        let input = #"""
        """
        \(values.map { value in do { return value } })
        """
        """#
        testFormatting(for: input, rule: .wrapDoBodies,
                       options: FormatOptions(wrapStringInterpolation: false))
    }

    func testDisabledByDefault() {
        XCTAssertTrue(FormatRules.disabledByDefault.contains(.wrapDoBodies))
        XCTAssertFalse(FormatRules.default.contains(.wrapDoBodies))
    }
}
