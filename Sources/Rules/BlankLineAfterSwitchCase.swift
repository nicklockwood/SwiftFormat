//
//  BlankLineAfterSwitchCase.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 2/1/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let blankLineAfterSwitchCase = FormatRule(
        help: """
        Insert a blank line after multiline switch cases (excluding the last case,
        which is followed by a closing brace).
        """,
        disabledByDefault: true,
        orderAfter: [.redundantBreak]
    ) { formatter in
        formatter.forEach(.keyword("switch")) { switchIndex, _ in
            guard let switchCases = formatter.switchStatementBranchesWithSpacingInfo(at: switchIndex) else { return }

            for switchCase in switchCases.reversed() {
                // Any switch statement that spans multiple lines should be followed by a blank line
                // (excluding the last case, which is followed by a closing brace).
                if switchCase.spansMultipleLines,
                   !switchCase.isLastCase,
                   !switchCase.isFollowedByBlankLine
                {
                    switchCase.insertTrailingBlankLine(using: formatter)
                }

                // The last case should never be followed by a blank line, since it's
                // already followed by a closing brace.
                if switchCase.isLastCase,
                   switchCase.isFollowedByBlankLine
                {
                    switchCase.removeTrailingBlankLine(using: formatter)
                }
            }
        }
    } examples: {
        #"""
        ```diff
          func handle(_ action: SpaceshipAction) {
              switch action {
              case .engageWarpDrive:
                  navigationComputer.destination = targetedDestination
                  await warpDrive.spinUp()
                  warpDrive.activate()
        +
              case let .scanPlanet(planet):
                  scanner.target = planet
                  scanner.scanAtmosphere()
                  scanner.scanBiosphere()
                  scanner.scanForArticialLife()
        +
              case .handleIncomingEnergyBlast:
                  await energyShields.prepare()
                  energyShields.engage()
              }
          }
        ```
        """#
    }
}
