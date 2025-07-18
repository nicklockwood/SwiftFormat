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
        Insert a blank line after switch cases (excluding the last case,
        which is followed by a closing brace).
        """,
        disabledByDefault: true,
        orderAfter: [.redundantBreak],
        options: ["blank-line-after-switch-case"]
    ) { formatter in
        formatter.forEach(.keyword("switch")) { switchIndex, _ in
            guard let switchCases = formatter.switchStatementBranchesWithSpacingInfo(at: switchIndex) else { return }

            let shouldAlwaysInsertBlankLineAfterSwitchCase = formatter.options.blankLineAfterSwitchCase == .always
            for switchCase in switchCases.reversed() {
                // Any switch statement should be followed by a blank line, depending on the
                // `blankLineAfterSwitchCase` option.
                // (excluding the last case, which is followed by a closing brace).
                if shouldAlwaysInsertBlankLineAfterSwitchCase || switchCase.spansMultipleLines,
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
        `--blank-line-after-switch-case multiline-only` (default)

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

        ```diff
          func handle(_ action: SpaceshipAction) {
              switch action {
              case .engageWarpDrive:
                  warpDrive.activate()

              case let .scanPlanet(planet):
                  scanner.scanForArticialLife()

              case .handleIncomingEnergyBlast:
                  energyShields.engage()
              }
          }
        ```
        `--blank-line-after-switch-case always` 

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

        ```diff
          func handle(_ action: SpaceshipAction) {
              switch action {
              case .engageWarpDrive:
                  warpDrive.activate()
        +
              case let .scanPlanet(planet):
                  scanner.scanForArticialLife()
        +
              case .handleIncomingEnergyBlast:
                  energyShields.engage()
              }
          }
        ```
        """#
    }
}
