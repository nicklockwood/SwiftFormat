//
//  BlankLinesBeforeComments.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Insert blank lines before comments that appear before statements or declarations.
    static let blankLinesBeforeComments = FormatRule(
        help: "Insert blank lines before comments that appear before statements or declarations.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.startOfScope) { i, token in
            guard token == .startOfScope("//") || token == .startOfScope("/*"),
                  formatter.commentIntroducesStatement(at: i)
            else { return }
            formatter.insertBlankLineBeforeStatement(at: i)
        }
    } examples: {
        """
        ```diff
          let destination = solarSystem.planets[0]
        +
          // Refuel before departing for the next planet.
          spacecraft.refuel()
          spacecraft.launch(toward: destination)
        ```

        ```diff
          struct SolarSystem {
              /// The inner terrestrial planets
              let innerPlanets = [mercury, venus, earth, mars]
        +
              /// The outer gas giants
              let outerPlanets = [jupiter, saturn, uranus, neptune]
        +
              /// Minor dwarf planets in the asteroid belt and kuiper belt
              let dwarfPlanets = [ceres, pluto, eris]
          }
        ```
        """
    }
}

extension Formatter {
    /// Whether this begins a standalone comment group attached to a statement or declaration.
    func commentIntroducesStatement(at index: Int) -> Bool {
        if case let .commentBody(body)? = next(.nonSpaceOrLinebreak, after: index), body.isCommentDirective {
            return false
        }
        guard let statement = self.index(of: .nonSpaceOrCommentOrLinebreak, in: index ..< tokens.count),
              startOfStatementIncludingComments(at: statement) == index,
              currentScope(at: index).map({ $0 == .startOfScope("{") }) ?? true,
              !isInClosureArguments(at: statement),
              isStartOfStatement(at: statement),
              let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
              !blankLineSeparatesConnectedSyntax(previous, statement)
        else { return false }
        return true
    }
}
