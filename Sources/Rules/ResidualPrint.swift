//
//  ResidualPrint.swift
//  SwiftFormat
//
//  Created by Yang Bai on 29/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove `print` and `debugPrint` statements left over from debugging
    static let residualPrint = FormatRule(
        help: "Remove `print(...)` and `debugPrint(...)` statements left over from debugging.",
        disabledByDefault: true
    ) { formatter in
        // A file that declares its own `print` or `debugPrint` may be calling that instead
        var declaresPrintFunction = false
        formatter.forEach(.keyword("func")) { i, _ in
            if let name = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i), name.isPrintFunction {
                declaresPrintFunction = true
            }
        }
        guard !declaresPrintFunction else { return }

        formatter.forEachToken(where: \.isPrintFunction) { i, _ in
            guard let range = formatter.residualPrintStatementRange(at: i) else { return }
            formatter.removeTokens(in: range)
        }
    } examples: {
        """
        ```diff
          func loadUser(id: String) async throws -> User {
              let user = try await api.user(id: id)
        -     print("loaded user:", user)
              return user
          }
        ```

        A `print` that is the only statement in its scope, a `print` at the top level or inside
        an `#if` block, and a `print(_:to:)` call that writes to a stream are left alone.
        """
    }
}

extension Token {
    var isPrintFunction: Bool {
        self == .identifier("print") || self == .identifier("debugPrint")
    }
}

extension Formatter {
    /// The range of lines to remove for a `print(...)` or `debugPrint(...)` statement at the given index,
    /// or `nil` if the call isn't a residual print statement that can be removed safely.
    func residualPrintStatementRange(at printIndex: Int) -> ClosedRange<Int>? {
        let openParenIndex = printIndex + 1
        guard token(at: openParenIndex) == .startOfScope("("),
              let closeParenIndex = endOfScope(at: openParenIndex),
              // The call must be a statement of its own, on its own lines
              last(.nonSpace, before: printIndex)?.isLinebreak == true,
              next(.nonSpace, after: closeParenIndex)?.isLinebreak == true,
              isStartOfStatement(at: printIndex),
              // Inside a function, closure or switch case. A `print` at the top level of
              // a script, or inside an `#if` block, is probably intentional.
              let scope = currentScope(at: printIndex),
              scope == .startOfScope("{") || scope == .startOfScope(":"),
              let previousToken = last(.nonSpaceOrCommentOrLinebreak, before: printIndex),
              let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: closeParenIndex)
        else { return nil }

        // Removing the only statement in a scope could leave a switch case empty
        // or change the type of a closure
        if [.startOfScope("{"), .startOfScope(":"), .keyword("in")].contains(previousToken),
           nextToken.isEndOfScope
        {
            return nil
        }

        // `print(_:to:)` writes to a stream, which isn't debug output
        let arguments = parseFunctionCallArguments(startOfScope: openParenIndex)
        if arguments.contains(where: { $0.label == "to" }) {
            return nil
        }

        // Removing the only use of an anonymous closure argument would break the closure
        if tokens[openParenIndex ... closeParenIndex].contains(where: {
            $0.isIdentifier && $0.string.hasPrefix("$") && $0.string.dropFirst().allSatisfy(\.isNumber)
        }) {
            return nil
        }

        return startOfLine(at: printIndex) ... endOfLine(at: closeParenIndex)
    }
}
