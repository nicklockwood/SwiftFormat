//
//  BlankLinesAroundMultilineStatements.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 11/2/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Separate multiline statements, keeping single-line variable declarations with statements that use them.
    static let blankLinesAroundMultilineStatements = FormatRule(
        help: """
        Insert blank lines before and after multiline statements, except between a
        single-line variable declaration and an uncommented multiline statement that uses that variable.
        Attached leading comments count as part of a statement.
        """,
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEachToken(where: { !$0.isSpaceOrCommentOrLinebreak }) { i, _ in
            guard let statement = formatter.multilineStatementRange(at: i) else { return }
            formatter.insertBlankLineAfterStatement(at: statement.upperBound)
            formatter.insertBlankLineBeforeStatement(in: statement)
        }
    } examples: {
        """
        ```diff
          func prepareOrders() {
              let orders = loadOrders(
                  from: warehouse,
                  limit: 100
              )
        +
              guard !orders.isEmpty else {
                  return
              }
        +
              for order in orders {
                  order.prepare()
              }
          }
        ```

        ```diff
          let bar = foo.bar
        +
          // every bar also has a quux
          let quux = bar.quux
        +
          // Finally, frobnicate them both
          frobnicate(bar, quux)
        ```
        """
    }
}

extension Formatter {
    /// Parse a complete statement, excluding expressions within arguments, collections, and statement headers.
    func multilineStatementRange(at index: Int) -> ClosedRange<Int>? {
        guard let token = token(at: index),
              isStartOfStatement(at: index),
              currentScope(at: index).map({ ["{", ":", "#if"].contains($0.string) }) ?? true,
              token != .startOfScope("{") || isStartOfClosure(at: index)
        else { return nil }

        if let scope = startOfScope(at: index), tokens[scope] == .startOfScope("{"),
           isStartOfClosure(at: scope),
           let arguments = parseClosureArguments(at: scope), index <= arguments.inKeywordIndex
        {
            return nil
        }

        let range: ClosedRange<Int>
        if ["if", "guard", "for", "while", "repeat", "switch", "do", "defer"].contains(token.string) {
            guard let statement = controlFlowStatementRange(at: index) else { return nil }
            range = statement
        } else if token == .keyword("let") || token == .keyword("var") {
            guard let propertyRange = variableDeclarationRange(at: index) else { return nil }
            range = propertyRange
        } else if token.isFunctionDeclarationKeyword {
            guard let function = parseFunctionDeclaration(keywordIndex: index) else { return nil }
            range = startOfModifiers(at: index, includingAttributes: true) ... function.range.upperBound
        } else if Token.swiftTypeKeywords.contains(token.string) {
            guard let body = self.index(of: .startOfScope("{"), after: index),
                  let end = endOfScope(at: body)
            else { return nil }
            range = startOfModifiers(at: index, includingAttributes: true) ... end
        } else if token == .keyword("typealias"),
                  let equals = self.index(of: .operator("=", .infix), after: index),
                  let typeStart = self.index(of: .nonSpaceOrCommentOrLinebreak, after: equals),
                  let type = parseType(at: typeStart)
        {
            range = startOfModifiers(at: index, includingAttributes: true) ... type.range.upperBound
        } else {
            let expressionStart: Int
            if token == .keyword("return") || token == .keyword("throw") {
                guard let next = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) else { return nil }
                expressionStart = next
            } else {
                expressionStart = index
            }
            guard let expression = parseExpressionRange(startingAt: expressionStart, allowConditionalExpressions: true) else { return nil }
            var end = expression.upperBound
            if let equals = self.index(of: .nonSpaceOrCommentOrLinebreak, after: end),
               tokens[equals] == .operator("=", .infix),
               let value = self.index(of: .nonSpaceOrCommentOrLinebreak, after: equals),
               let valueExpression = parseExpressionRange(startingAt: value, allowConditionalExpressions: true)
            {
                end = valueExpression.upperBound
            }
            range = index ... end
        }

        if let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: range.lowerBound),
           !tokens[previous].isStartOfScope
        {
            guard !onSameLine(previous, range.lowerBound) || tokens[previous] == .delimiter(";"),
                  isEndOfStatement(at: previous), isStartOfStatement(at: range.lowerBound),
                  !blankLineSeparatesConnectedSyntax(previous, range.lowerBound)
            else { return nil }
        }
        let start = startOfStatementIncludingComments(at: range.lowerBound)
        return onSameLine(start, range.upperBound) ? nil : start ... range.upperBound
    }

    /// The complete range of a control flow statement, including any branches or label.
    func controlFlowStatementRange(at index: Int) -> ClosedRange<Int>? {
        let keyword = tokens[index].string
        guard !isConditionalAssignment(at: index) else { return nil }

        let previous = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index)
        var start = index
        if let previous, tokens[previous] == .delimiter(":"),
           let label = self.index(of: .nonSpaceOrCommentOrLinebreak, before: previous),
           isLabel(at: label)
        {
            start = label
        }
        if let previous {
            // An else-if branch and the condition of a repeat-while belong to the preceding statement.
            if tokens[previous] == .keyword("else") {
                return nil
            }
            if keyword == "while", tokens[previous] == .endOfScope("}"),
               let openBrace = startOfScope(at: previous),
               last(.nonSpaceOrCommentOrLinebreak, before: openBrace) == .keyword("repeat")
            {
                return nil
            }
            if start == index,
               [.keyword("return"), .keyword("throw")].contains(tokens[previous])
               || !isEndOfStatement(at: previous) && !tokens[previous].isStartOfScope
            {
                return nil
            }
        }

        let end: Int
        if keyword == "if" {
            guard let lastBranch = ifStatementBranches(at: index).last else { return nil }
            end = lastBranch.endOfBranch
        } else {
            let bodyStart: Int?
            if keyword == "guard" {
                bodyStart = self.index(of: .keyword("else"), after: index)
                    .flatMap { self.index(of: .startOfScope("{"), after: $0) }
            } else {
                bodyStart = startOfConditionalBranchBody(after: index)
            }
            guard let bodyStart, var bodyEnd = endOfScope(at: bodyStart) else { return nil }

            if keyword == "do" {
                while let catchIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: bodyEnd),
                      tokens[catchIndex] == .keyword("catch"),
                      let catchBody = startOfConditionalBranchBody(after: catchIndex),
                      let catchEnd = endOfScope(at: catchBody)
                {
                    bodyEnd = catchEnd
                }
            } else if keyword == "repeat" {
                guard let whileIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: bodyEnd),
                      tokens[whileIndex] == .keyword("while"),
                      let conditionStart = self.index(of: .nonSpaceOrCommentOrLinebreak, after: whileIndex),
                      let condition = parseExpressionRange(startingAt: conditionStart)
                else { return nil }
                bodyEnd = condition.upperBound
            }
            end = bodyEnd
        }
        return start ... end
    }

    /// The full range of a variable declaration, including tuple patterns and multiple bindings.
    func variableDeclarationRange(at index: Int) -> ClosedRange<Int>? {
        guard let range = parseMultiplePropertyDeclaration(at: index)?.range
            ?? parsePropertyDeclaration(atIntroducerIndex: index)?.range
            ?? parseTuplePropertyDeclaration(at: index)?.range
        else { return nil }
        return startOfModifiers(at: index, includingAttributes: true) ... range.upperBound
    }

    /// Whether an uncommented statement uses a variable declared on a single line immediately before it.
    func precedingVariableIsReferenced(in statement: ClosedRange<Int>) -> Bool {
        guard !tokens[statement.lowerBound].isComment,
              let previous = index(of: .nonSpaceOrCommentOrLinebreak, before: statement.lowerBound),
              let introducer = index(before: statement.lowerBound, where: {
                  $0 == .keyword("let") || $0 == .keyword("var")
              }),
              let declaration = variableDeclarationRange(at: introducer),
              declaration.upperBound == previous,
              onSameLine(declaration.lowerBound, declaration.upperBound),
              let names = namesInDeclaration(at: introducer)
        else { return false }
        return tokens[statement].contains { $0.isIdentifier && names.contains($0.unescaped()) }
    }

    /// Include contiguous standalone leading comments in the following statement.
    func startOfStatementIncludingComments(at index: Int) -> Int {
        guard self.index(of: .nonSpaceOrCommentOrLinebreak, in: startOfLine(at: index) ..< index) == nil else { return index }
        var start = index
        while let linebreak = self.index(of: .linebreak, before: startOfLine(at: start)),
              let commentEnd = self.index(of: .nonSpace, before: linebreak),
              tokens[commentEnd].isComment,
              let commentStart = tokens[commentEnd].isStartOfScope ? commentEnd : startOfScope(at: commentEnd),
              startOfLine(at: commentStart, excludingIndent: true) == commentStart
        {
            start = commentStart
        }
        return start
    }

    /// Keep standalone leading comments attached to the statement they describe.
    func insertBlankLineBeforeStatement(in statement: ClosedRange<Int>) {
        let start = statement.lowerBound
        guard !precedingVariableIsReferenced(in: statement),
              index(of: .nonSpaceOrCommentOrLinebreak, in: startOfLine(at: start) ..< start) == nil,
              let previous = index(of: .nonSpaceOrCommentOrLinebreak, before: start),
              !tokens[previous].isStartOfScope,
              ![.keyword("in"), .keyword("#else"), .keyword("#elseif")].contains(tokens[previous]),
              ![.startOfScope("#if"), .keyword("#elseif")].contains(tokens[startOfLine(at: previous, excludingIndent: true)]),
              isEndOfStatement(at: previous),
              let linebreak = index(of: .linebreak, in: previous + 1 ..< start),
              index(of: .linebreak, in: linebreak + 1 ..< start) == nil
        else { return }
        insertLinebreak(at: startOfLine(at: start))
    }

    /// Insert after any trailing comment, and only when another statement follows on a later line.
    func insertBlankLineAfterStatement(at index: Int) {
        guard let next = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
              isStartOfStatement(at: next),
              !tokens[next].isEndOfScope,
              ![.keyword("else"), .keyword("catch"), .keyword("#else"), .keyword("#elseif"), .startOfScope("#if")].contains(tokens[next]),
              let linebreak = self.index(of: .nonSpaceOrComment, after: index),
              tokens[linebreak].isLinebreak,
              let nextContent = self.index(of: .nonSpaceOrLinebreak, after: linebreak),
              self.index(of: .linebreak, in: linebreak + 1 ..< nextContent) == nil
        else { return }
        if let nextStatement = multilineStatementRange(at: next),
           precedingVariableIsReferenced(in: nextStatement)
        {
            return
        }
        insertLinebreak(at: linebreak)
    }
}
