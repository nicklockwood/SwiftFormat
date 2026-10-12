//
//  WrapClosureBodies.swift
//  SwiftFormat
//
//  Created by Kim de Vos on 10/12/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Wrap single-line closure bodies for configured functions onto multiple lines.
    static let wrapClosureBodies = FormatRule(
        help: "Wrap single-line closure bodies for configured functions onto multiple lines.",
        disabledByDefault: true,
        options: ["wrap-closure-bodies"],
        sharedOptions: ["linebreaks", "indent", "wrap-string-interpolation"]
    ) { formatter in
        let names = formatter.options.wrapClosureBodies
        if names.contains("always") {
            formatter.forEach(.startOfScope("{")) { index, _ in
                guard formatter.isStartOfClosure(at: index) else { return }
                formatter.wrapClosureBody(at: index)
            }
        } else if !names.isEmpty {
            formatter.forEach(.identifier) { index, _ in
                guard formatter.closureBodyCalleeMatches(names, endingAt: index),
                      let scope = formatter.closureBodyCallScope(after: index)
                else { return }

                formatter.wrapClosureArguments(in: scope)
            }
        }
    } examples: {
        """
        The default `--wrap-closure-bodies Task,Task.detached` wraps Task closures.
        Supply a comma-delimited list of function names to select other closures,
        or use `--wrap-closure-bodies always` to wrap all closure bodies.
        Names match by dotted-component suffix, so `Task` also matches `Swift.Task`.

        ```diff
        - Task { await someOperation() }
        + Task {
        +     await someOperation()
        + }
        ```
        """
    }
}

extension Formatter {
    /// Wraps direct closure arguments, preserving comments around each argument.
    func wrapClosureArguments(in scope: Int) {
        for argument in parseFunctionCallArguments(startOfScope: scope).reversed() {
            guard let first = index(of: .nonSpaceOrCommentOrLinebreak, in: Range(argument.valueRange)),
                  let last = lastIndex(of: .nonSpaceOrCommentOrLinebreak, in: Range(argument.valueRange)),
                  isStartOfClosure(at: first), endOfScope(at: first) == last
            else { continue }
            wrapClosureBody(at: first)
        }
    }

    /// Matches a dotted callee suffix, ignoring comments and generic argument clauses.
    func closureBodyCalleeMatches(_ names: Set<String>, endingAt index: Int) -> Bool {
        var index = index
        var name = tokens[index].unescaped()
        while !names.contains(name) {
            guard let dot = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
                  tokens[dot] == .operator(".", .infix),
                  var receiver = self.index(of: .nonSpaceOrCommentOrLinebreak, before: dot)
            else { return false }

            if tokens[receiver] == .endOfScope(">") {
                guard let start = startOfScope(at: receiver),
                      let identifier = self.index(of: .nonSpaceOrCommentOrLinebreak, before: start)
                else { return false }
                receiver = identifier
            }
            guard tokens[receiver].isIdentifier else { return false }
            name = tokens[receiver].unescaped() + "." + name
            index = receiver
        }
        return true
    }

    /// Finds a call's argument scope, excluding declarations and non-closure brace bodies.
    func closureBodyCallScope(after index: Int) -> Int? {
        guard var scope = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) else { return nil }
        if tokens[scope] == .startOfScope("<") {
            guard let end = endOfScope(at: scope),
                  let next = self.index(of: .nonSpaceOrCommentOrLinebreak, after: end)
            else { return nil }
            scope = next
        }
        switch tokens[scope] {
        case .startOfScope("(") where !isParameterList(at: scope):
            return scope
        case .startOfScope("{") where isStartOfClosure(at: scope):
            return scope
        default:
            return nil
        }
    }

    /// Wraps a nonempty single-line closure without moving its signature or removing comments.
    func wrapClosureBody(at index: Int) {
        guard !isInStringLiteralWithWrappingDisabled(at: index),
              let end = endOfScope(at: index), onSameLine(index, end)
        else { return }
        let bodyStart = startOfBody(atStartOfScope: index)
        guard let content = self.index(of: .nonSpaceOrCommentOrLinebreak, after: bodyStart), content < end,
              let first = self.index(of: .nonSpace, after: bodyStart)
        else { return }

        let indent = currentIndentForLine(at: index)
        wrapLine(before: end)
        replaceTokens(in: bodyStart + 1 ..< first, with: [linebreakToken(for: index), .space(indent + options.indent)])
    }
}
