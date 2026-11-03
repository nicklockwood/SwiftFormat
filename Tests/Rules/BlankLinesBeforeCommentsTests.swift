//
//  BlankLinesBeforeCommentsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 11/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class BlankLinesBeforeCommentsTests: XCTestCase {
    func testBlankLineBeforeComment() {
        let input = """
        let destination = solarSystem.planets[0]
        // Refuel before departing for the next planet.
        spacecraft.refuel()
        spacecraft.launch(toward: destination)
        """
        let output = """
        let destination = solarSystem.planets[0]

        // Refuel before departing for the next planet.
        spacecraft.refuel()
        spacecraft.launch(toward: destination)
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
        testFormatting(for: input, [output], rules: [.blankLinesBeforeComments, .blankLinesAroundMultilineStatements])
    }

    func testConsecutiveCommentedStatements() {
        let input = """
        func frobnicateFoo() {
            let bar = foo.bar
            // Every bar also has a quux.
            let quux = bar.quux
            // Finally, frobnicate them both.
            frobnicate(bar, quux)
        }
        """
        let output = """
        func frobnicateFoo() {
            let bar = foo.bar

            // Every bar also has a quux.
            let quux = bar.quux

            // Finally, frobnicate them both.
            frobnicate(bar, quux)
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testCommentGroupAfterTrailingComment() {
        let input = """
        prepare() // Load the orders.
        // Only process ready orders.
        // Other orders can wait.
        process()
        finish()
        """
        let output = """
        prepare() // Load the orders.

        // Only process ready orders.
        // Other orders can wait.
        process()
        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testBlockComment() {
        let input = """
        func prepareOrders() {
            prepare()
            /* Load the pending orders. */
            let orders = loadOrders()
            process(orders)
        }
        """
        let output = """
        func prepareOrders() {
            prepare()

            /* Load the pending orders. */
            let orders = loadOrders()
            process(orders)
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testDocCommentsBeforeDeclarations() {
        let input = """
        struct SolarSystem {
            /// The inner terrestrial planets
            let innerPlanets = [mercury, venus, earth, mars]
            /// The outer gas giants
            let outerPlanets = [jupiter, saturn, uranus, neptune]
            /// Minor dwarf planets in the asteroid belt and kuiper belt
            let dwarfPlanets = [ceres, pluto, eris]
        }
        """
        let output = """
        struct SolarSystem {
            /// The inner terrestrial planets
            let innerPlanets = [mercury, venus, earth, mars]

            /// The outer gas giants
            let outerPlanets = [jupiter, saturn, uranus, neptune]

            /// Minor dwarf planets in the asteroid belt and kuiper belt
            let dwarfPlanets = [ceres, pluto, eris]
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testMultilineBlockComment() {
        let input = """
        let destination = solarSystem.planets[0]
        /*
         Refuel before departing for the next planet.
         Leave enough fuel for the return trip.
         */
        spacecraft.refuel()
        spacecraft.launch(toward: destination)
        """
        let output = """
        let destination = solarSystem.planets[0]

        /*
         Refuel before departing for the next planet.
         Leave enough fuel for the return trip.
         */
        spacecraft.refuel()
        spacecraft.launch(toward: destination)
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testMultilineBlockDocCommentsBeforeDeclarations() {
        let input = """
        struct SolarSystem {
            /**
             The inner terrestrial planets.
             Ordered by distance from the sun.
             */
            let innerPlanets = [mercury, venus, earth, mars]
            /**
             The outer gas giants.
             Ordered by distance from the sun.
             */
            let outerPlanets = [jupiter, saturn, uranus, neptune]
            let dwarfPlanets = [ceres, pluto, eris]
        }
        """
        let output = """
        struct SolarSystem {
            /**
             The inner terrestrial planets.
             Ordered by distance from the sun.
             */
            let innerPlanets = [mercury, venus, earth, mars]

            /**
             The outer gas giants.
             Ordered by distance from the sun.
             */
            let outerPlanets = [jupiter, saturn, uranus, neptune]
            let dwarfPlanets = [ceres, pluto, eris]
        }
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testMultilineBlockCommentAndLineCommentStayTogether() {
        let input = """
        prepare()
        /*
         Load the pending orders.
         */
        // Other orders can wait.
        process()
        finish()
        """
        let output = """
        prepare()

        /*
         Load the pending orders.
         */
        // Other orders can wait.
        process()
        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testEmptyComment() {
        let input = """
        prepare()
        //
        process()
        finish()
        """
        let output = """
        prepare()

        //
        process()
        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testExistingBlankLinesAndScopeBoundaries() {
        let input = """
        /// Prepare the pending orders.
        func prepareOrders() {
            // Load the pending orders.
            let orders = loadOrders()

            // Process the pending orders.
            process(orders)
        }
        """
        testFormatting(for: input, rule: .blankLinesBeforeComments)
    }

    func testTrailingAndInlineComments() {
        let input = """
        let destination = solarSystem.planets[0] // Visit the first planet.
        spacecraft.refuel( /* Full tank. */ )
        spacecraft.launch(toward: destination)
        """
        testFormatting(for: input, rule: .blankLinesBeforeComments)
    }

    func testCommentsInsideExpressionsAndHeaders() {
        let input = """
        let orders = [
            first,
            // Process this order last.
            second,
        ]
        process(
            orders,
            // Process immediately.
            immediately: true
        )
        if let order = orders.first,
           // Only process ready orders.
           order.isReady
        {
            process(order)
        }

        let result = orders
            // Only process ready orders.
            .filter(\\.isReady)
        """
        testFormatting(for: input, rule: .blankLinesBeforeComments)
    }

    func testClosureAndConditionalCompilationBoundaries() {
        let input = """
        process { order in
            // Process this order.
            prepare(order)
        }

        #if DEBUG
            // Report debug information.
            reportDebugInfo()
        #else
            // Report the status.
            reportStatus()
        #endif
        """
        testFormatting(for: input, rule: .blankLinesBeforeComments)
    }

    func testCommentedMultilineStatement() {
        let input = """
        let order = loadOrder()
        // Only process ready orders.
        if order.isReady {
            process(order)
        }

        finish()
        """
        let output = """
        let order = loadOrder()

        // Only process ready orders.
        if order.isReady {
            process(order)
        }

        finish()
        """
        testFormatting(for: input, output, rule: .blankLinesBeforeComments)
    }

    func testCommentsBetweenControlFlowBranches() {
        let input = """
        if isReady {
            run()
        }
        // Otherwise, wait for the next order.
        else {
            wait()
        }

        do {
            try process()
        }
        // Report any errors.
        catch {
            report(error)
        }

        repeat {
            processNext()
        }
        // Continue until all orders have been processed.
        while hasMoreWork
        """
        testFormatting(for: input, rule: .blankLinesBeforeComments)
    }

    func testCRLFLinebreaks() {
        let input = """
        prepare()
        // Process the pending orders.
        process()
        """.replacingOccurrences(of: "\n", with: "\r\n")
        let output = """
        prepare()

        // Process the pending orders.
        process()
        """.replacingOccurrences(of: "\n", with: "\r\n")
        testFormatting(for: input, output, rule: .blankLinesBeforeComments, options: FormatOptions(linebreak: "\r\n"))
    }
}
