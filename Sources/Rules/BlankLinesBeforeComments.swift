//
//  BlankLinesBeforeComments.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/3/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Insert blank lines before standalone comments that introduce statements.
    static let blankLinesBeforeComments = FormatRule(
        help: "Insert blank lines before standalone comments that introduce statements.",
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
        """
    }
}

extension Formatter {
    /// Whether this begins a standalone comment group attached to a new statement.
    func commentIntroducesStatement(at index: Int) -> Bool {
        guard let statement = self.index(of: .nonSpaceOrCommentOrLinebreak, in: index ..< tokens.count),
              startOfStatementIncludingComments(at: statement) == index,
              currentScope(at: index).map({ ["{", ":", "#if"].contains($0.string) }) ?? true,
              !isInClosureArguments(at: statement),
              isStartOfStatement(at: statement),
              ![.keyword("else"), .keyword("catch")].contains(tokens[statement]),
              let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
              !blankLineSeparatesConnectedSyntax(previous, statement)
        else { return false }
        if tokens[statement] == .keyword("while"), tokens[previous] == .endOfScope("}"),
           let body = startOfScope(at: previous),
           last(.nonSpaceOrCommentOrLinebreak, before: body) == .keyword("repeat")
        {
            return false
        }
        return true
    }
}
