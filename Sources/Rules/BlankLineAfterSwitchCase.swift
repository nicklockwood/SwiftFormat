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
        which is followed by a closing brace), or remove them with
        `--blank-line-after-switch-case never`.
        """,
        disabledByDefault: true,
        orderAfter: [.redundantBreak],
        options: ["blank-line-after-switch-case"]
    ) { formatter in
        formatter.forEach(.keyword("switch")) { switchIndex, _ in
            formatter.applyBlankLinesAfterSwitchCases(at: switchIndex, spacing: formatter.options.blankLineAfterSwitchCase)
        }
    } examples: {
        #"""
        `--blank-line-after-switch-case multiline-only` (default)

        ```diff
          switch action {
          case .engageWarpDrive:
              navigationComputer.destination = targetedDestination
              warpDrive.activate()
        +
          case .handleIncomingEnergyBlast:
              energyShields.engage()
          }
        ```

        `--blank-line-after-switch-case always`

        ```diff
          switch action {
          case .engageWarpDrive:
              warpDrive.activate()
        +
          case .handleIncomingEnergyBlast:
              energyShields.engage()
          }
        ```

        `--blank-line-after-switch-case never`

        ```diff
          switch action {
          case .engageWarpDrive:
              navigationComputer.destination = targetedDestination
              warpDrive.activate()
        -
          case .handleIncomingEnergyBlast:
              energyShields.engage()
          }
        ```
        """#
    }
}
