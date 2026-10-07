//
//  WrapTaskBodies.swift
//  SwiftFormat
//
//  Created by Kim De Vos on 10/6/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Wrap single-line Task and Task.detached closure bodies onto multiple lines.
    static let wrapTaskBodies = FormatRule(
        help: "Wrap single-line Task and Task.detached closure bodies onto multiple lines.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "indent", "wrap-string-interpolation"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { index, _ in
            guard formatter.isTaskClosure(at: index) else { return }
            formatter.wrapTaskClosureBody(at: index)
        }
    } examples: {
        """
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
    /// Whether this closure is a direct argument to a Task initializer or Task.detached.
    func isTaskClosure(at index: Int) -> Bool {
        guard isStartOfClosure(at: index),
              let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index)
        else { return false }

        if tokens[previous] == .endOfScope(")"),
           let openParen = startOfScope(at: previous),
           let callee = self.index(of: .nonSpaceOrCommentOrLinebreak, before: openParen)
        {
            return isTaskCallee(endingAt: callee)
        }

        if isTaskCallee(endingAt: previous) {
            return true
        }

        // A parenthesized closure must be the whole argument, rather than a
        // closure nested in another expression passed to Task.
        guard let openParen = startOfScope(at: index), tokens[openParen] == .startOfScope("("),
              let callee = self.index(of: .nonSpaceOrCommentOrLinebreak, before: openParen),
              isTaskCallee(endingAt: callee),
              let closeBrace = endOfScope(at: index)
        else { return false }

        return parseFunctionCallArguments(startOfScope: openParen).contains { argument in
            self.index(of: .nonSpaceOrCommentOrLinebreak, in: Range(argument.valueRange)) == index &&
                lastIndex(of: .nonSpaceOrCommentOrLinebreak, in: Range(argument.valueRange)) == closeBrace
        }
    }

    /// Recognizes Task, Swift.Task, and their detached methods, including generic arguments.
    func isTaskCallee(endingAt index: Int) -> Bool {
        if tokens[index] == .endOfScope(">"),
           let openAngle = startOfScope(at: index),
           let identifier = self.index(of: .nonSpaceOrCommentOrLinebreak, before: openAngle)
        {
            return isTaskCallee(endingAt: identifier)
        }

        if tokens[index] == .identifier("detached"),
           let dot = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
           tokens[dot] == .operator(".", .infix),
           let receiver = self.index(of: .nonSpaceOrCommentOrLinebreak, before: dot),
           tokens[receiver] != .identifier("detached")
        {
            return isTaskCallee(endingAt: receiver)
        }

        guard tokens[index] == .identifier("Task") else { return false }
        guard let dot = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
              tokens[dot] == .operator(".", .infix)
        else { return true }
        guard let module = self.index(of: .nonSpaceOrCommentOrLinebreak, before: dot),
              tokens[module] == .identifier("Swift")
        else { return false }
        return last(.nonSpaceOrCommentOrLinebreak, before: module) != .operator(".", .infix)
    }

    /// Wraps a nonempty single-line closure without moving its signature or removing comments.
    func wrapTaskClosureBody(at index: Int) {
        guard !isInStringLiteralWithWrappingDisabled(at: index),
              let end = endOfScope(at: index), onSameLine(index, end)
        else { return }
        let bodyStart = startOfBody(atStartOfScope: index)
        guard let content = self.index(of: .nonSpaceOrCommentOrLinebreak, after: bodyStart), content < end,
              let first = self.index(of: .nonSpace, after: bodyStart),
              let last = self.index(of: .nonSpace, before: end)
        else { return }

        let indent = currentIndentForLine(at: index)
        replaceTokens(in: last + 1 ..< end, with: linebreakToken(for: end))
        insertSpace(indent, at: last + 2)
        replaceTokens(in: bodyStart + 1 ..< first, with: [linebreakToken(for: index), .space(indent + options.indent)])
    }
}
