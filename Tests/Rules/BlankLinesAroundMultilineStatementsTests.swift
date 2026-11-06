//
//  BlankLinesAroundMultilineStatementsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/2/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlankLinesAroundMultilineStatementsTests: XCTestCase {
    func testPrepareOrders() {
        let input = """
        func prepareOrders() {
            let orders = loadOrders(
                from: warehouse,
                limit: 100
            )
            guard !orders.isEmpty else {
                return
            }
            for order in orders {
                order.prepare()
            }
        }
        """
        let output = """
        func prepareOrders() {
            let orders = loadOrders(
                from: warehouse,
                limit: 100
            )

            guard !orders.isEmpty else {
                return
            }

            for order in orders {
                order.prepare()
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testAdjacentMultilineStatements() {
        let input = """
        if isReady {
            prepare()
        }
        while hasMoreWork {
            processNext()
        }
        """
        let output = """
        if isReady {
            prepare()
        }

        while hasMoreWork {
            processNext()
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testElseIfBranchesStayTogether() {
        let input = """
        prepare()
        if isReady {
            run()
        } else if needsSetup {
            setUp()
        } else {
            wait()
        }
        finish()
        """
        let output = """
        prepare()

        if isReady {
            run()
        } else if needsSetup {
            setUp()
        } else {
            wait()
        }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testDoCatchBranchesStayTogether() {
        let input = """
        prepare()
        do {
            try run()
        } catch TaskError.cancelled {
            cancel()
        } catch {
            report(error)
        }
        finish()
        """
        let output = """
        prepare()

        do {
            try run()
        } catch TaskError.cancelled {
            cancel()
        } catch {
            report(error)
        }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testRepeatWhileStaysTogether() {
        let input = """
        prepare()
        repeat {
            processNext()
        } while hasMoreWork
        finish()
        """
        let output = """
        prepare()

        repeat {
            processNext()
        } while hasMoreWork

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testMultilineRepeatCondition() {
        let input = """
        prepare()
        repeat {
            processNext()
        } while hasMoreWork &&
            shouldContinue
        finish()
        """
        let output = """
        prepare()

        repeat {
            processNext()
        } while hasMoreWork &&
            shouldContinue

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testSwitchAndNestedStatements() {
        let input = """
        prepare()
        switch state {
        case .ready:
            if shouldRun {
                run()
            }
            finish()

        default:
            wait()
        }
        cleanUp()
        """
        let output = """
        prepare()

        switch state {
        case .ready:
            if shouldRun {
                run()
            }

            finish()

        default:
            wait()
        }

        cleanUp()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testDefer() {
        let input = """
        begin()
        defer {
            finish()
        }
        run()
        """
        let output = """
        begin()

        defer {
            finish()
        }

        run()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testScopeBoundariesAndExistingBlankLines() {
        let input = """
        func process() {
            if isReady {
                while hasMoreWork {
                    processNext()
                }
            }

            finish()
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }

    func testSingleLineStatements() {
        let input = """
        prepare()
        guard isReady else { return }

        if needsSetup { setUp() }
        finish()
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }

    func testMultilineConditionWithInlineBody() {
        let input = """
        prepare()
        if isReady,
           shouldRun { run() }
        finish()
        """
        let output = """
        prepare()

        if isReady,
           shouldRun { run() }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testCommentsStayAttached() {
        let input = """
        prepare()
        // Only process ready orders.
        // Other orders can wait.
        if isReady {
            run()
        } // Finished processing.
        // Clean up temporary files.
        finish()
        """
        let output = """
        prepare()

        // Only process ready orders.
        // Other orders can wait.
        if isReady {
            run()
        } // Finished processing.

        // Clean up temporary files.
        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testBlockCommentsStayAttached() {
        let input = """
        prepare()
        /* Process ready orders. */
        if isReady {
            run()
        } /* Finished. */
        finish()
        """
        let output = """
        prepare()

        /* Process ready orders. */
        if isReady {
            run()
        } /* Finished. */

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testClosuresInConditions() {
        let input = """
        prepare()
        if orders.contains(where: { $0.isReady }) {
            run()
        }
        finish()
        """
        let output = """
        prepare()

        if orders.contains(where: { $0.isReady }) {
            run()
        }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testStatementsInClosure() {
        let input = """
        process(orders) { order in
            if order.isReady {
                order.prepare()
            }
            order.finish()
        }
        """
        let output = """
        process(orders) { order in
            if order.isReady {
                order.prepare()
            }

            order.finish()
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testMultilineCallsAndAssignments() {
        let input = """
        prepare()
        let orders = loadOrders(
            from: database,
            limit: 10
        )
        process(
            orders,
            immediately: true
        )
        finish()
        """
        let output = """
        prepare()

        let orders = loadOrders(
            from: database,
            limit: 10
        )

        process(
            orders,
            immediately: true
        )

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testMultilineConditionalAssignment() {
        let input = """
        func reportStatus() {
            let message =
                if isReady {
                    "Ready"
                } else {
                    "Waiting"
                }
            print(message)
        }
        """
        let output = """
        func reportStatus() {
            let message =
                if isReady {
                    "Ready"
                } else {
                    "Waiting"
                }

            print(message)
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements,
                       options: FormatOptions(swiftVersion: "5.9"))
    }

    func testConditionalCompilationBoundaries() {
        let input = """
        #if DEBUG
            if isReady {
                run()
            }
        #else
            while hasMoreWork {
                processNext()
            }
        #endif
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }

    func testLabeledLoop() {
        let input = """
        prepare()
        orders: for order in pendingOrders {
            process(order)
        }
        finish()
        """
        let output = """
        prepare()

        orders: for order in pendingOrders {
            process(order)
        }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testConsecutiveGuards() {
        let input = """
        func processOrders() {
            guard let orders else {
                return
            }
            guard isReady else {
                return
            }
            process(orders)
        }
        """
        let output = """
        func processOrders() {
            guard let orders else {
                return
            }

            guard isReady else {
                return
            }

            process(orders)
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements,
                       exclude: [.blankLinesAfterGuardStatements])
    }

    func testReturnedConditionalExpression() {
        let input = """
        func status() -> String {
            print("Checking status")
            return if isReady {
                "Ready"
            } else {
                "Waiting"
            }
        }
        """
        let output = """
        func status() -> String {
            print("Checking status")

            return if isReady {
                "Ready"
            } else {
                "Waiting"
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements,
                       options: FormatOptions(swiftVersion: "5.9"))
    }

    func testMultilineBlockComment() {
        let input = """
        prepare()
        /*
         Process ready orders.
         */
        if isReady {
            run()
        }
        finish()
        """
        let output = """
        prepare()

        /*
         Process ready orders.
         */
        if isReady {
            run()
        }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testLeadingCommentAfterTrailingComment() {
        let input = """
        prepare() // Load the orders.
        // Only process ready orders.
        if isReady {
            run()
        }
        """
        let output = """
        prepare() // Load the orders.

        // Only process ready orders.
        if isReady {
            run()
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testEmptyLeadingComment() {
        let input = """
        prepare()
        //
        if isReady {
            run()
        }
        """
        let output = """
        prepare()

        //
        if isReady {
            run()
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testAssignmentAndChainedCalls() {
        let input = """
        prepare()
        orders = pendingOrders
            .filter(\\.isReady)
            .sorted()
        report()
        orders
            .map(\\.identifier)
            .forEach(report)
        finish()
        """
        let output = """
        prepare()

        orders = pendingOrders
            .filter(\\.isReady)
            .sorted()

        report()

        orders
            .map(\\.identifier)
            .forEach(report)

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testCollectionAndDestructuringAssignments() {
        let input = """
        prepare()
        let statuses = [
            "Ready",
            "Waiting",
        ]
        let (first, second) = loadStatuses(
            from: statuses,
            count: 2
        )
        report(first, second)
        """
        let output = """
        prepare()

        let statuses = [
            "Ready",
            "Waiting",
        ]

        let (first, second) = loadStatuses(
            from: statuses,
            count: 2
        )

        report(first, second)
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testReturnMultilineCall() {
        let input = """
        func loadOrders() -> [Order] {
            prepare()
            return database.load(
                matching: .ready,
                limit: 100
            )
        }
        """
        let output = """
        func loadOrders() -> [Order] {
            prepare()

            return database.load(
                matching: .ready,
                limit: 100
            )
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testWrappedTrailingClosureStaysAttachedToMultilineCall() {
        let input = """
        prepare()
        withAnimation(.easeInOut(duration: duration)
            .repeatForever(autoreverses: true))
        {
            opacity = 0.85
        }
        finish()
        """
        let output = """
        prepare()

        withAnimation(.easeInOut(duration: duration)
            .repeatForever(autoreverses: true))
        {
            opacity = 0.85
        }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testTrailingClosureWrappedByWrapMultilineStatementBraces() {
        let input = """
        onAppear {
            // Animate the overlay while the operation is in progress.
            withAnimation(.easeInOut(duration: duration)
                .repeatForever(autoreverses: true)) {
                opacity = 0.85
            }
        }
        """
        let output = """
        onAppear {
            // Animate the overlay while the operation is in progress.
            withAnimation(.easeInOut(duration: duration)
                .repeatForever(autoreverses: true))
            {
                opacity = 0.85
            }
        }
        """
        testFormatting(for: input, [output], rules: [.blankLinesAroundMultilineStatements, .wrapMultilineStatementBraces])
    }

    func testMultipleTrailingClosures() {
        let input = """
        prepare()
        loadOrders {
            report("Loading")
        } completion: { orders in
            process(orders)
        }
        finish()
        """
        let output = """
        prepare()

        loadOrders {
            report("Loading")
        } completion: { orders in
            process(orders)
        }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testClosureAssignmentWithMultilineSignature() {
        let input = """
        prepare()
        let process = { (
            order: Order,
            immediately: Bool
        ) in
            report(order, immediately)
        }
        process(order, true)
        """
        let output = """
        prepare()

        let process = { (
            order: Order,
            immediately: Bool
        ) in
            report(order, immediately)
        }

        process(order, true)
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testDeclarationAttributesStayAttached() {
        let input = """
        struct OrderProcessor {
            let database: Database
            @MainActor
            func prepareOrders() {
                database.prepareOrders()
            }

            func finish() {}
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }

    func testMultipleBindingsStayTogether() {
        let input = """
        prepare()
        let first = loadOrder(
            at: 0
        ), second = loadOrder(
            at: 1
        )
        report(first, second)
        """
        let output = """
        prepare()

        let first = loadOrder(
            at: 0
        ), second = loadOrder(
            at: 1
        )

        report(first, second)
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements,
                       exclude: [.singlePropertyPerLine])
    }

    func testMultilineTypealias() {
        let input = """
        typealias OrderID = String
        typealias OrderHandler = (
            Order,
            Status
        ) -> Void
        let handler: OrderHandler = makeHandler()
        """
        let output = """
        typealias OrderID = String

        typealias OrderHandler = (
            Order,
            Status
        ) -> Void

        let handler: OrderHandler = makeHandler()
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testVariableAssignedInConditionalStaysAttached() {
        let input = """
        func prepareOrder() {
            let order: Order?
            if usePreferredOrder {
                print("Using preferred order")
                order = orderService.preferredOrder
            } else {
                order = nil
            }
            process(order)
        }
        """
        let output = """
        func prepareOrder() {
            let order: Order?
            if usePreferredOrder {
                print("Using preferred order")
                order = orderService.preferredOrder
            } else {
                order = nil
            }

            process(order)
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testVariableUsedInLoopStaysAttached() {
        let input = """
        var smallest = 0
        for value in list {
            if value < smallest {
                smallest = value
            }
        }
        report(smallest)
        """
        let output = """
        var smallest = 0
        for value in list {
            if value < smallest {
                smallest = value
            }
        }

        report(smallest)
        """
        let outputWithOtherRules = """
        var smallest = 0
        for value in list where value < smallest {
            smallest = value
        }

        report(smallest)
        """
        testFormatting(for: input, [output, outputWithOtherRules], rules: [.blankLinesAroundMultilineStatements])
    }

    func testUnrelatedVariableStillSeparated() {
        let input = """
        let smallest = 0
        for value in list {
            // Report "smallest" separately.
            report("smallest", value)
        }
        """
        let output = """
        let smallest = 0

        for value in list {
            // Report "smallest" separately.
            report("smallest", value)
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testInterveningStatementStillSeparated() {
        let input = """
        var smallest = 0
        prepare()
        for value in list where value < smallest {
            smallest = value
        }
        """
        let output = """
        var smallest = 0
        prepare()

        for value in list where value < smallest {
            smallest = value
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testExistingBlankLineAfterReferencedVariablePreserved() {
        let input = """
        var smallest = 0

        for value in list where value < smallest {
            smallest = value
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }

    func testCommentBeforeSingleLineVariableStaysAttached() {
        let input = """
        func prepareOrders() {
            // Load the pending orders.
            let orders = loadOrders()
            for order in orders {
                order.prepare()
            }

            // Find the smallest value in the array.
            var smallest = Int.max
            for value in list where value < smallest {
                smallest = value
            }
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }

    func testLeadingCommentsDoNotMakeStatementsMultiline() {
        let input = """
        func prepareOrders() {
            let destination = solarSystem.planets[0]
            // Refuel before departing for the next planet.
            spacecraft.refuel()
            spacecraft.launch(toward: destination)
            /* Report the remaining fuel. */
            spacecraft.reportFuel()
            finish()
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }

    func testLeadingCommentOverridesReferencedVariableException() {
        let input = """
        func process() {
            let foo = bar
            // Frobnicate if needed
            if foo.shouldFrobnicate {
                foo.frobnicate()
            }
        }
        """
        let output = """
        func process() {
            let foo = bar

            // Frobnicate if needed
            if foo.shouldFrobnicate {
                foo.frobnicate()
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLinesAroundMultilineStatements)
    }

    func testTrailingCommentDoesNotMakeStatementMultiline() {
        let input = """
        let bar = foo.bar // Every foo has a bar.
        let quux = bar.quux
        frobnicate(bar, quux)
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }

    func testCommentBeforeLastStatementDoesNotAddScopePadding() {
        let input = """
        func prepareOrders() {
            // Prepare the pending orders.
            prepare()
        }
        """
        testFormatting(for: input, rule: .blankLinesAroundMultilineStatements)
    }
}
