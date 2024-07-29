//
//  BlankLineAfterSwitchCaseTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class BlankLineAfterSwitchCaseTests: XCTestCase {
    func testAddsBlankLineAfterMultilineSwitchCases() {
        let input = """
        func handle(_ action: SpaceshipAction) {
            switch action {
            // The warp drive can be engaged by pressing a button on the control panel
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()
            // Triggered automatically whenever we detect an energy blast was fired in our direction
            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()
            }
        }
        """

        let output = """
        func handle(_ action: SpaceshipAction) {
            switch action {
            // The warp drive can be engaged by pressing a button on the control panel
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()

            // Triggered automatically whenever we detect an energy blast was fired in our direction
            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLineAfterSwitchCase)
    }

    func testRemovesBlankLineAfterLastSwitchCase() {
        let input = """
        func handle(_ action: SpaceshipAction) {
            switch action {
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()

            case let .scanPlanet(planet):
                scanner.target = planet
                scanner.scanAtmosphere()
                scanner.scanBiosphere()
                scanner.scanForArticialLife()

            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()

            }
        }
        """

        let output = """
        func handle(_ action: SpaceshipAction) {
            switch action {
            case .engageWarpDrive:
                navigationComputer.destination = targetedDestination
                await warpDrive.spinUp()
                warpDrive.activate()

            case let .scanPlanet(planet):
                scanner.target = planet
                scanner.scanAtmosphere()
                scanner.scanBiosphere()
                scanner.scanForArticialLife()

            case .handleIncomingEnergyBlast:
                await energyShields.prepare()
                energyShields.engage()
            }
        }
        """
        testFormatting(for: input, output, rule: .blankLineAfterSwitchCase)
    }

    func testDoesntAddBlankLineAfterSingleLineSwitchCase() {
        let input = """
        var planetType: PlanetType {
            switch self {
            case .mercury, .venus, .earth, .mars:
                // The terrestrial planets are smaller and have a solid, rocky surface
                .terrestrial
            case .jupiter, .saturn, .uranus, .neptune:
                // The gas giants are huge and lack a solid surface
                .gasGiant
            }
        }

        var planetType: PlanetType {
            switch self {
            // The terrestrial planets are smaller and have a solid, rocky surface
            case .mercury, .venus, .earth, .mars:
                .terrestrial
            // The gas giants are huge and lack a solid surface
            case .jupiter, .saturn, .uranus, .neptune:
                .gasGiant
            }
        }

        var name: PlanetType {
            switch self {
            // The planet closest to the sun
            case .mercury:
                "Mercury"
            case .venus:
                "Venus"
            // The best planet, where everything cool happens
            case .earth:
                "Earth"
            // This planet is entirely inhabited by robots.
            // There are cool landers, rovers, and even a helicopter.
            case .mars:
                "Mars"
            case .jupiter:
                "Jupiter"
            case .saturn:
                // Other planets have rings, but satun's are the best.
                // It's rings are the only once that are usually visible in photos.
                "Saturn"
            case .uranus:
                /*
                 * The pronunciation of this planet's name is subject of scholarly debate
                 */
                "Uranus"
            case .neptune:
                "Neptune"
            }
        }
        """

        testFormatting(for: input, rule: .blankLineAfterSwitchCase, exclude: [.sortSwitchCases, .wrapSwitchCases, .blockComments])
    }

    func testMixedSingleLineAndMultiLineCases() {
        let input = """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()
        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case let .scanPlanet(planet):
            scanner.target = planet
            scanner.scanAtmosphere()
            scanner.scanBiosphere()
            scanner.scanForArtificialLife()
        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        let output = """
        switch action {
        case .engageWarpDrive:
            navigationComputer.destination = targetedDestination
            await warpDrive.spinUp()
            warpDrive.activate()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)
        case let .scanPlanet(planet):
            scanner.target = planet
            scanner.scanAtmosphere()
            scanner.scanBiosphere()
            scanner.scanForArtificialLife()

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """
        testFormatting(for: input, output, rule: .blankLineAfterSwitchCase, exclude: [.consistentSwitchCaseSpacing])
    }

    func testAllowsBlankLinesAfterSingleLineCases() {
        let input = """
        switch action {
        case .engageWarpDrive:
            warpDrive.engage()

        case .enableArtificialGravity:
            artificialGravityEngine.enable(strength: .oneG)

        case let .scanPlanet(planet):
            scanner.scan(planet)

        case .handleIncomingEnergyBlast:
            energyShields.engage()
        }
        """

        testFormatting(for: input, rule: .blankLineAfterSwitchCase)
    }
}
