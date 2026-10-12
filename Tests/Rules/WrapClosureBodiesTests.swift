//
//  WrapClosureBodiesTests.swift
//  SwiftFormatTests
//
//  Created by Kim De Vos on 10/6/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class WrapClosureBodiesTests: XCTestCase {
    func testTask() {
        let input = """
        Task { await someOperation() }
        """
        let output = """
        Task {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
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
        testFormatting(for: input, output, rule: .wrapClosureBodies)
    }

    func testEmptyBodies() {
        let input = """
        Task {}
        Task { @MainActor in }
        Task { /* comment */ }
        """
        testFormatting(for: input, rule: .wrapClosureBodies)
    }

    func testAlreadyMultiline() {
        let input = """
        Task {
            await someOperation()
        }
        """
        testFormatting(for: input, rule: .wrapClosureBodies)
    }

    func testUnrelatedClosures() {
        let input = """
        values.map { $0.id }
        Task.withGroup { someOperation() }
        let operation = { someOperation() }
        """
        testFormatting(for: input, rule: .wrapClosureBodies)
    }

    func testNestedArgumentClosure() {
        let input = """
        Task(operation: makeOperation { someOperation() })
        """
        testFormatting(for: input, rule: .wrapClosureBodies)
    }

    func testStringInterpolation() {
        let input = """
        let text = "\\(Task { someOperation() })"
        """
        testFormatting(for: input, rule: .wrapClosureBodies)
    }

    func testInterpolationOptionDoesNotTriggerUnusedOptionWarning() {
        let warnings = warningsForArguments([
            "rules": "wrapClosureBodies",
            "wrap-closure-bodies": "perform",
            "wrap-string-interpolation": "true",
        ])
        XCTAssertEqual(warnings, [])
    }

    func testMultilineStringInterpolationWrappingEnabled() {
        let input = """
        \"""
        \\(Task { someOperation() })
        \"""
        """
        let output = """
        \"""
        \\(Task {
            someOperation()
        })
        \"""
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapStringInterpolation: true))
    }

    func testMultilineStringInterpolationWrappingDisabled() {
        let input = """
        \"""
        \\(Task { someOperation() })
        \"""
        """
        testFormatting(for: input, rule: .wrapClosureBodies, options: FormatOptions(wrapStringInterpolation: false))
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
                       rule: .wrapClosureBodies, options: FormatOptions(indent: "  ", linebreak: "\r\n"))
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
        testFormatting(for: input, [output], rules: [.wrapClosureBodies, .trailingClosures])
    }

    func testDefaultMatchesOtherQualifiedTask() {
        let input = """
        Other.Task { await someOperation() }
        """
        let output = """
        Other.Task {
            await someOperation()
        }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies)
    }

    func testCustomListReplacesDefaults() {
        let input = """
        Task { await someOperation() }
        values.map { $0.id }

        perform { start() }
        """
        let output = """
        Task { await someOperation() }
        values.map {
            $0.id
        }

        perform {
            start()
        }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["map", "perform"]))
    }

    func testDottedSuffixWithGenerics() {
        let input = """
        Library.Service<Model>.run { start() }

        OtherService.run { start() }
        Library.Service<Model>.other { start() }
        """
        let output = """
        Library.Service<Model>.run {
            start()
        }

        OtherService.run { start() }
        Library.Service<Model>.other { start() }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["Service.run"]))
    }

    func testGenericFunction() {
        let input = """
        perform<Model> { start() }
        """
        let output = """
        perform<Model> {
            start()
        }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["perform"]))
    }

    func testCommentsInCallee() {
        let input = """
        Library.Service<Model> /* type */ .run { start() }
        """
        let output = """
        Library.Service<Model> /* type */ .run {
            start()
        }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["Service.run"]))
    }

    func testMultipleParenthesizedArguments() {
        let input = """
        perform(first: { start() }, second: { finish() })
        """
        let output = """
        perform(first: {
            start()
        }, second: {
            finish()
        })
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["perform"]))
    }

    func testMultipleTrailingClosures() {
        let input = """
        perform { start() } completion: { finish() }
        """
        let output = """
        perform {
            start()
        } completion: {
            finish()
        }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["perform"]))
    }

    func testParenthesizedAndTrailingArguments() {
        let input = """
        perform(first: { start() }) { finish() }
        """
        let output = """
        perform(first: {
            start()
        }) {
            finish()
        }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["perform"]))
    }

    func testDoesNotSelectArgumentLabels() {
        let input = """
        fetch(completion: { finish() })
        fetch { start() } completion: { finish() }
        """
        testFormatting(for: input, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["completion"]))
    }

    func testEmptyConfiguration() {
        let input = """
        Task { await someOperation() }
        Task.detached { await someOperation() }
        """
        testFormatting(for: input, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: []))
    }

    func testAlwaysWrapsAssignedAndMapClosures() {
        let input = """
        let operation = { start() }

        values.map { $0.id }
        """
        let output = """
        let operation = {
            start()
        }

        values.map {
            $0.id
        }
        """
        testFormatting(for: input, output, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["always"]))
    }

    func testAlwaysPreservesOtherBraceBodies() {
        let input = """
        struct Example {}
        let operation = {}
        if enabled {}
        func example() {
            start()
        }
        """
        testFormatting(for: input, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["always"]))
    }

    func testMatchesComponentBoundaries() {
        let input = """
        MyTask { start() }
        Task.other { start() }
        Task.detachedOther { start() }
        """
        testFormatting(for: input, rule: .wrapClosureBodies)
    }

    func testCustomCalleeDoesNotSelectNestedArgumentClosure() {
        let input = """
        perform(operation: makeOperation { start() })
        """
        testFormatting(for: input, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["perform"]))
    }

    func testDoesNotSelectDefaultArgumentsInDeclarations() {
        let input = """
        func perform(operation _: () -> Void = { start() }) {}
        """
        testFormatting(for: input, rule: .wrapClosureBodies, options: FormatOptions(wrapClosureBodies: ["perform"]))
    }
}
