//
//  BlankLineSpacingTests.swift
//  SwiftFormatTests
//
//  Created by Kim de Vos on 11/27/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlankLineSpacingTests: XCTestCase {
    func testIfFollowedByGuard() {
        let input = """
        func record(_ item: Item?, paused: Bool) {
            if paused {
                return
            }
            guard let item else {
                return
            }

            save(item)
        }
        """
        let output = """
        func record(_ item: Item?, paused: Bool) {
            if paused {
                return
            }

            guard let item else {
                return
            }

            save(item)
        }
        """
        testFormatting(for: input, output, rule: .blankLineSpacing, options: FormatOptions(blankLinesAfter: ["if"]))
    }

    func testIfChainAndNestedStatements() throws {
        let input = """
        if enabled {
            if ready {
                start()
            }
            log()
        } else if waiting {
            pause()
        } else {
            reset()
        } /* finished
        checking */
        // Record the outcome.
        report()
        """
        let output = """
        if enabled {
            if ready {
                start()
            }

            log()
        } else if waiting {
            pause()
        } else {
            reset()
        } /* finished
        checking */

        // Record the outcome.
        report()
        """
        try assertSpacing(input, output, selecting: ["if"])
    }

    func testControlFlowAtStatementBoundaries() throws {
        let input = """
        if ready { start() }; report()
        if ready { start() };
        report()
        if ready { start() }

        report()
        switch state {
        case .ready:
            if ready { start() }
        @unknown default:
            if ready { reset() }
        }
        #if DEBUG
            if ready { start() }
        #endif
        """
        let output = """
        if ready { start() }; report()
        if ready { start() };

        report()
        if ready { start() }

        report()
        switch state {
        case .ready:
            if ready { start() }
        @unknown default:
            if ready { reset() }
        }
        #if DEBUG
            if ready { start() }
        #endif
        """
        try assertSpacing(input, output, selecting: ["if"])
    }

    func testConditionalExpressionsAndDisabledElseIfChain() throws {
        let input = """
        let status = if ready { "ready" } else if pending { "pending" } else { "idle" }
        log(status)
        let label = switch state {
        case .ready: "ready"
        default: "idle"
        }
        log(label)
        func prepare() async throws {
            let result = try await if ready { load() } else { fallback() }
            log(result)
        }
        func result() -> Int {
            return if ready { 1 } else { 0 }
            log()
        }
        func count() -> Int? {
            return try? switch state {
            case .ready: 1
            default: 0
            }
            log()
        }
        // swiftformat:disable:next blankLineSpacing
        if ready {
            start()
        } else if waiting {
            pause()
        }
        report()
        """
        for version: Version in [.undefined, "5.9"] {
            try assertSpacing(input, input, selecting: ["if", "switch"], swiftVersion: version)
        }
    }

    func testTrailingClosuresInStatementHeaders() throws {
        let statements = [
            """
            if values.contains { $0 > 0 } && enabled {
                record()
            }
            """,
            """
            if values.contains { $0 > 0 }, enabled {
                record()
            }
            """,
            """
            switch values.map { $0 + 1 } + values {
            case []:
                reset()
            default:
                record()
            }
            """,
            """
            for value in values.map { $0 + 1 } where value > 0 {
                record(value)
            }
            """,
            """
            for value in values.map { $0 + 1 } + values {
                record(value)
            }
            """,
            """
            for value in makeValues { [1, 2] }[0...] {
                record(value)
            }
            """,
            """
            do {
                try start()
            } catch let error where values.allSatisfy { $0 > 0 } {
                record(error)
            } catch {
                reset()
            }
            """,
            """
            do {
                try start()
            } catch SampleError.empty where values.allSatisfy { $0 > 0 }, SampleError.invalid {
                record()
            } catch {
                reset()
            }
            """,
        ]
        for statement in statements {
            try assertSpacing(statement + "\nreport()", statement + "\n\nreport()",
                              selecting: ["if", "switch", "for", "do-catch"])
        }
    }

    func testLoopFormsAndStandaloneDo() throws {
        let input = """
        do {
            open()
        }
        for case let .some(value) in values {
            record(value)
        }
        for try await item in stream {
            record(item)
        }
        finish()
        """
        let output = """
        do {
            open()
        }
        for case let .some(value) in values {
            record(value)
        }

        for try await item in stream {
            record(item)
        }

        finish()
        """
        try assertSpacing(input, output, selecting: ["for", "do-catch"])
    }

    func testStatementsFollowedByImmediatelyCalledClosures() throws {
        let statements = [
            """
            if ready {
                start()
            }
            """,
            """
            for item in items {
                record(item)
            }
            """,
            """
            if ready {
                start()
            } else {
                reset()
            }
            """,
            """
            switch state {
            case .ready: start()
            default: reset()
            }
            """,
            """
            do {
                try start()
            } catch {
                report(error)
            }
            """,
        ]
        for statement in statements {
            try assertSpacing(statement + "\n{ finish() }()", statement + "\n\n{ finish() }()",
                              selecting: ["if", "switch", "do-catch", "for"])
        }
    }

    func testLineRelativeDirectivesKeepTheirTargets() throws {
        let input = """
        if ready { start() } // swiftformat:disable:next redundantInit
        let item = Item.init()
        if ready { record(Item.init()) }
        // swiftformat:disable:previous redundantInit
        record(item)
        """
        try assertSpacing(input, input, selecting: ["if"], additionalRules: [.redundantInit])
    }

    func testGuardSettingsMatchLegacyEntryPoint() throws {
        let input = """
        guard let first else { return }

        guard let second else { return }
        record(first, second)
        """
        for betweenGuards in [false, true] {
            let options = FormatOptions(lineBetweenConsecutiveGuards: betweenGuards, blankLinesAfter: ["guard"])
            let expected = try format(input, rules: [.blankLinesAfterGuardStatements], options: options).output
            XCTAssertEqual(try format(input, rules: [.blankLineSpacing], options: options).output, expected)
            XCTAssertEqual(try format(input, rules: [.blankLinesAfterGuardStatements, .blankLineSpacing], options: options).output, expected)
        }
    }

    func testGuardEntryPointsKeepTheirOwnDirectives() throws {
        let input = """
        // swiftformat:disable blankLineSpacing,blankLinesAfterGuardStatements
        // swiftformat:enable:next blankLineSpacing
        guard let first else { return }
        record(first)
        // swiftformat:enable:next blankLinesAfterGuardStatements
        guard let second else { return }
        record(second)
        guard let third else { return }
        record(third)
        """
        let output = """
        // swiftformat:disable blankLineSpacing,blankLinesAfterGuardStatements
        // swiftformat:enable:next blankLineSpacing
        guard let first else { return }

        record(first)
        // swiftformat:enable:next blankLinesAfterGuardStatements
        guard let second else { return }

        record(second)
        guard let third else { return }
        record(third)
        """
        try assertSpacing(input, output, selecting: ["guard"], additionalRules: [.blankLinesAfterGuardStatements])
    }

    func testGuardAndCaseOverlapMatchesLegacyEntryPoints() throws {
        let input = """
        switch state {
        case .ready:
            guard let item else { return }


        default:
            reset()
        }
        """
        let output = """
        switch state {
        case .ready:
            guard let item else { return }
        default:
            reset()
        }
        """
        for (rules, selection) in [
            ([FormatRule.blankLinesAfterGuardStatements, .blankLineAfterSwitchCase], Set<String>()),
            ([.blankLineSpacing], ["guard", "case"]),
            ([.blankLineSpacing, .blankLineAfterSwitchCase], ["guard"]),
            ([.blankLinesAfterGuardStatements, .blankLineSpacing], ["case"]),
            ([.blankLinesAfterGuardStatements, .blankLineAfterSwitchCase, .blankLineSpacing], ["guard", "case"]),
        ] {
            let options = FormatOptions(blankLineAfterSwitchCase: .never, blankLinesAfter: selection)
            XCTAssertEqual(try format(input, rules: rules, options: options).output, output)
        }
    }

    func testSwitchAndCaseSelectionsAreIndependent() throws {
        let input = """
        switch values.map { $0 + 1 }.count {
        case 0:
            reset()
            record()
        default:
            start()
        }
        report()
        """
        let caseOutput = """
        switch values.map { $0 + 1 }.count {
        case 0:
            reset()
            record()

        default:
            start()
        }
        report()
        """
        let switchOutput = """
        switch values.map { $0 + 1 }.count {
        case 0:
            reset()
            record()
        default:
            start()
        }

        report()
        """
        try assertSpacing(input, caseOutput, selecting: ["case"])
        try assertSpacing(input, switchOutput, selecting: ["switch"])

        let legacyRules: [FormatRule] = [.blankLineAfterSwitchCase, .consistentSwitchCaseSpacing]
        XCTAssertEqual(try format(input, rules: legacyRules).output, input)
    }

    func testSpacingAfterIfCaseBecomesSwitch() throws {
        let input = """
        func update(_ outcome: Outcome) {
            if case .ready = outcome {
                prepare()
            } else {
                reset()
            }
            finish()
        }
        """
        let output = """
        func update(_ outcome: Outcome) {
            switch outcome {
            case .ready:
                prepare()

            default:
                reset()
            }

            finish()
        }
        """
        try assertSpacing(input, output, selecting: ["switch", "case"], caseMode: .always,
                          additionalRules: [.ifCase])
    }

    func testCaseSettingsMatchLegacyEntryPoint() throws {
        let input = """
        switch state {
        case .open:
            prepare()
            start()
        case .closed:
            reset()


        default:
            report()
        }
        """
        for mode in BlankLineAfterSwitchCase.allCases {
            let options = FormatOptions(blankLineAfterSwitchCase: mode, blankLinesAfter: ["case"])
            let expected = try format(input, rules: [.blankLineAfterSwitchCase, .consistentSwitchCaseSpacing], options: options).output
            try assertSpacing(input, expected, selecting: ["case"], caseMode: mode,
                              additionalRules: [.consistentSwitchCaseSpacing])
            try assertSpacing(input, expected, selecting: ["case"], caseMode: mode,
                              additionalRules: [.blankLineAfterSwitchCase, .consistentSwitchCaseSpacing])
        }
    }

    func testCaseConsistencyHonorsScopedActivation() throws {
        let body = """
        switch state {
        case .open:
            prepare()
            start()
        case .closed:
            reset()
        case .paused:
            pause()
        default:
            report()
        }
        """
        let spaced = """
        switch state {
        case .open:
            prepare()
            start()

        case .closed:
            reset()

        case .paused:
            pause()

        default:
            report()
        }
        """
        let disable = """
        // swiftformat:disable:next blankLineSpacing

        """
        try assertSpacing(disable + body, disable + body, selecting: ["case"], additionalRules: [.consistentSwitchCaseSpacing])
        let select = """
        // swiftformat:options:next --blank-lines-after case

        """
        try assertSpacing(select + body, select + spaced, selecting: [], additionalRules: [.consistentSwitchCaseSpacing])
    }

    func testLegacyCaseSpacingStillRunsBeforeRedundantClosure() throws {
        let input = """
        switch state {
        case .open:
            let item = {
                makeItem()
            }()
        case .closed:
            reset()
        case .paused:
            pause()
        default:
            report()
        }
        """
        let output = """
        switch state {
        case .open:
            let item = makeItem()

        case .closed:
            reset()

        case .paused:
            pause()

        default:
            report()
        }
        """
        let rules: [FormatRule] = [.blankLineAfterSwitchCase, .consistentSwitchCaseSpacing, .redundantClosure]
        XCTAssertEqual(try format(input, rules: rules).output, output)
    }

    func testAllSelectionsWithMultilineSpacing() throws {
        let input = """
        guard let first else { return }
        guard let second else { return }
        if ready { start() }
        switch state {
        case .open:
            prepare()
            start()
        default:
            reset()
        }
        do { try record(first) } catch { report() }
        for item in second { record(item) }
        finish()
        """
        let output = """
        guard let first else { return }
        guard let second else { return }

        if ready { start() }

        switch state {
        case .open:
            prepare()
            start()

        default:
            reset()
        }

        do { try record(first) } catch { report() }

        for item in second { record(item) }

        finish()
        """
        try assertSpacing(input, output, selecting: ["guard", "if", "switch", "case", "do-catch", "for"],
                          additionalRules: [.blankLinesAroundMultilineStatements])
    }

    private func assertSpacing(_ input: String, _ expected: String, selecting selection: Set<String>,
                               swiftVersion: Version = .undefined, caseMode: BlankLineAfterSwitchCase = .multilineOnly,
                               additionalRules: [FormatRule] = [],
                               file: StaticString = #filePath, line: UInt = #line) throws
    {
        let rules = [.blankLineSpacing] + additionalRules
        let options = FormatOptions(blankLineAfterSwitchCase: caseMode, blankLinesAfter: selection, swiftVersion: swiftVersion)
        let formatted = try format(input, rules: rules, options: options).output
        XCTAssertEqual(formatted, expected, file: file, line: line)
        XCTAssertEqual(try format(formatted, rules: rules, options: options).output, expected, file: file, line: line)
    }
}
