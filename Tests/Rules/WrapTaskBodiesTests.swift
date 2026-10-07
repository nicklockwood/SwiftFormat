//
//  WrapTaskBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Kim De Vos on 10/6/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapTaskBodiesTests: XCTestCase {
    func testTask() {
        let input = """
        Task { await someOperation() }
        """
        let output = """
        Task {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testDetached() {
        let input = """
        Task.detached { await someOperation() }
        """
        let output = """
        Task.detached {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testPriority() {
        let input = """
        Task(priority: .high) { await someOperation() }
        """
        let output = """
        Task(priority: .high) {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testDetachedPriority() {
        let input = """
        Task.detached(priority: .high) { await someOperation() }
        """
        let output = """
        Task.detached(priority: .high) {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testQualifiedGenericTask() {
        let input = """
        Swift.Task<Void, Never> { await someOperation() }
        """
        let output = """
        Swift.Task<Void, Never> {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testGenericDetachedTask() {
        let input = """
        Task<Void, Never>.detached { await someOperation() }
        """
        let output = """
        Task<Void, Never>.detached {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testQualifiedTaskWithArguments() {
        let input = """
        Swift.Task<Void, Never>(priority: .high) { await someOperation() }
        """
        let output = """
        Swift.Task<Void, Never>(priority: .high) {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testParenthesizedClosure() {
        let input = """
        Task(operation: { await someOperation() })
        """
        let output = """
        Task(operation: {
            await someOperation()
        })
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testParenthesizedDetachedClosure() {
        let input = """
        Task.detached(priority: .high, operation: { await someOperation() })
        """
        let output = """
        Task.detached(priority: .high, operation: {
            await someOperation()
        })
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testCommentBeforeParenthesizedClosure() {
        let input = """
        Task(operation: /* comment */ { await someOperation() })
        """
        let output = """
        Task(operation: /* comment */ {
            await someOperation()
        })
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testCommentAfterParenthesizedDetachedClosure() {
        let input = """
        Task.detached(operation: { await someOperation() } /* comment */ )
        """
        let output = """
        Task.detached(operation: {
            await someOperation()
        } /* comment */ )
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testCaptureList() {
        let input = """
        Task { [weak self] in await self?.someOperation() }
        """
        let output = """
        Task { [weak self] in
            await self?.someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testActorAnnotation() {
        let input = """
        Task { @MainActor [weak self] in await self?.someOperation() }
        """
        let output = """
        Task { @MainActor [weak self] in
            await self?.someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testComments() {
        let input = """
        Task { /* before */ await someOperation() /* after */ }
        """
        let output = """
        Task {
            /* before */ await someOperation() /* after */
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testNestedTasks() {
        let input = """
        Task { Task { await someOperation() } }
        """
        let output = """
        Task {
            Task {
                await someOperation()
            }
        }
        """
        testFormatting(for: input, output, rule: .wrapTaskBodies)
    }

    func testEmptyBodies() {
        let input = """
        Task {}
        Task { @MainActor in }
        Task { /* comment */ }
        """
        testFormatting(for: input, rule: .wrapTaskBodies)
    }

    func testAlreadyMultiline() {
        let input = """
        Task {
            await someOperation()
        }
        """
        testFormatting(for: input, rule: .wrapTaskBodies)
    }

    func testUnrelatedClosures() {
        let input = """
        values.map { $0.id }
        Task.withGroup { someOperation() }
        Other.Task { someOperation() }
        let operation = { someOperation() }
        """
        testFormatting(for: input, rule: .wrapTaskBodies)
    }

    func testNestedArgumentClosure() {
        let input = """
        Task(operation: makeOperation { someOperation() })
        """
        testFormatting(for: input, rule: .wrapTaskBodies)
    }

    func testStringInterpolation() {
        let input = """
        let text = "\\(Task { someOperation() })"
        """
        testFormatting(for: input, rule: .wrapTaskBodies)
    }

    func testInterpolationOptionDoesNotTriggerUnusedOptionWarning() {
        let warnings = warningsForArguments([
            "rules": "wrapTaskBodies",
            "wrap-string-interpolation": "true",
        ])
        XCTAssertEqual(warnings, [])
    }

    func testConfiguredIndentAndLinebreaks() {
        let input = """
        Task { await someOperation() }
        """
        let output = """
        Task {
          await someOperation()
        }
        """
        testFormatting(for: input, output.replacingOccurrences(of: "\n", with: "\r\n"),
                       rule: .wrapTaskBodies, options: FormatOptions(indent: "  ", linebreak: "\r\n"))
    }

    func testTrailingClosures() {
        let input = """
        Task({ await someOperation() })
        """
        let output = """
        Task {
            await someOperation()
        }
        """
        testFormatting(for: input, [output], rules: [.wrapTaskBodies, .trailingClosures])
    }
}
