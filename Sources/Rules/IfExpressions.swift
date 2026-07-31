//
//  IfExpressions.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/31/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Convert ternary expressions to if expressions in functions and computed properties.
    static let ifExpressions = FormatRule(
        help: "Prefer if expressions over ternary operators in functions and computed properties.",
        orderAfter: [.redundantReturn],
        options: ["single-line-ternary"],
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        // If / switch expressions were added in Swift 5.9 (SE-0380)
        guard formatter.options.swiftVersion >= "5.9" else {
            return
        }

        formatter.forEach(.startOfScope("{")) { startOfScopeIndex, _ in
            // We only apply this rule to functions, computed vars, subscripts, and inits
            // (not closures) because if expressions have different type inference than
            // ternaries. In functions and computed vars the return type is always explicit,
            // so this difference doesn't matter.
            let isClosure = formatter.isStartOfClosure(at: startOfScopeIndex)
            guard !isClosure else { return }

            let lastKeyword = formatter.lastSignificantKeyword(
                at: startOfScopeIndex,
                excluding: ["throws", "where"]
            )

            guard ["func", "var", "subscript", "init"].contains(lastKeyword ?? "") else {
                return
            }

            // For func/subscript/init, verify there's a return type (-> before the body).
            // Void functions can't use if expressions as their body value.
            if ["func", "subscript", "init"].contains(lastKeyword ?? "") {
                guard formatter.index(of: .operator("->", .infix), before: startOfScopeIndex) != nil else {
                    return
                }
            }

            // Make sure the body is a single statement (the same check redundantReturn uses)
            guard formatter.blockBodyHasSingleStatement(
                atStartOfScope: startOfScopeIndex,
                includingConditionalStatements: false,
                includingReturnStatements: true
            ) else {
                return
            }

            // Find the first token in the body
            let startOfBody = formatter.startOfBody(atStartOfScope: startOfScopeIndex)
            guard var firstTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: startOfBody) else {
                return
            }

            // Skip optional `return` keyword
            let hasReturnKeyword: Bool
            if formatter.tokens[firstTokenIndex] == .keyword("return") {
                hasReturnKeyword = true
                guard let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: firstTokenIndex) else {
                    return
                }
                firstTokenIndex = nextIndex
            } else {
                hasReturnKeyword = false
            }

            // Check if the expression is a ternary
            guard let ternary = formatter.parseTernaryExpression(startingAt: firstTokenIndex) else {
                return
            }

            // Determine if the ternary itself was originally single-line
            let ternaryEnd = formatter.falseBranchEnd(of: ternary)
            let isSingleLine = !formatter.tokens[firstTokenIndex ... ternaryEnd]
                .contains(where: \.isLinebreak)

            // If it's single-line and we're preserving, skip it
            if isSingleLine, formatter.options.singleLineTernary == .preserve {
                return
            }

            // Convert the ternary to an if expression
            formatter.convertTernaryToIfExpression(
                ternary: ternary,
                firstTokenIndex: firstTokenIndex,
                hasReturnKeyword: hasReturnKeyword,
                isSingleLine: isSingleLine && formatter.options.singleLineTernary == .convert
            )
        }
    } examples: {
        """
        ```diff
          func foo(_ condition: Bool) -> String {
        -     condition ? "foo" : "bar"
        +     if condition {
        +         "foo"
        +     } else {
        +         "bar"
        +     }
          }
        ```
        """
    }
}

// MARK: - Ternary Parsing

extension Formatter {
    /// A parsed representation of a ternary expression, possibly with nested ternaries.
    struct TernaryExpression {
        /// The range of the condition tokens
        var conditionRange: ClosedRange<Int>
        /// The true branch, which may itself be a nested ternary
        var trueBranch: TernaryBranch
        /// The false branch, which may itself be a nested ternary
        var falseBranch: TernaryBranch
    }

    indirect enum TernaryBranch {
        case expression(ClosedRange<Int>)
        case nestedTernary(TernaryExpression)
    }

    /// Parses a ternary expression starting at the given index.
    /// Returns nil if the expression starting at `index` is not a ternary.
    func parseTernaryExpression(startingAt index: Int) -> TernaryExpression? {
        // Find the ternary ? operator for this expression.
        // We need to find the first infix ? that is at the same scope level.
        guard let questionMarkIndex = findTernaryOperator(after: index) else {
            return nil
        }

        let conditionRange = index ... (self.index(of: .nonSpaceOrCommentOrLinebreak, before: questionMarkIndex) ?? index)

        // Parse the true branch (between ? and :)
        guard let trueStart = self.index(of: .nonSpaceOrCommentOrLinebreak, after: questionMarkIndex) else {
            return nil
        }

        guard let colonIndex = findTernaryColon(after: questionMarkIndex) else {
            return nil
        }

        let trueEnd = self.index(of: .nonSpaceOrCommentOrLinebreak, before: colonIndex) ?? trueStart

        // Parse the false branch (after :)
        guard let falseStart = self.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex) else {
            return nil
        }

        // Find the end of the false branch by finding the end of the overall expression
        guard let expressionRange = parseExpressionRange(startingAt: index) else {
            return nil
        }

        let falseEnd = expressionRange.upperBound

        // Check for nested ternaries in the true branch
        let trueBranch: TernaryBranch
        if let nestedTernary = parseTernaryExpression(startingAt: trueStart),
           nestedTernary.conditionRange.lowerBound >= trueStart,
           falseBranchEnd(of: nestedTernary) <= trueEnd
        {
            trueBranch = .nestedTernary(nestedTernary)
        } else {
            trueBranch = .expression(trueStart ... trueEnd)
        }

        // Check for nested ternaries in the false branch
        let falseBranch: TernaryBranch
        if let nestedTernary = parseTernaryExpression(startingAt: falseStart),
           nestedTernary.conditionRange.lowerBound >= falseStart,
           falseBranchEnd(of: nestedTernary) <= falseEnd
        {
            falseBranch = .nestedTernary(nestedTernary)
        } else {
            falseBranch = .expression(falseStart ... falseEnd)
        }

        return TernaryExpression(
            conditionRange: conditionRange,
            trueBranch: trueBranch,
            falseBranch: falseBranch
        )
    }

    /// Finds the last token index in the false branch of a ternary expression
    func falseBranchEnd(of ternary: TernaryExpression) -> Int {
        switch ternary.falseBranch {
        case let .expression(range):
            return range.upperBound
        case let .nestedTernary(nested):
            return falseBranchEnd(of: nested)
        }
    }

    /// Finds the infix `?` operator at the current scope level, starting search after `index`.
    func findTernaryOperator(after startIndex: Int) -> Int? {
        var scopeDepth = 0
        var i = startIndex

        while i < tokens.count {
            let token = tokens[i]
            switch token {
            case .startOfScope:
                scopeDepth += 1
            case .endOfScope:
                if scopeDepth == 0 {
                    return nil
                }
                scopeDepth -= 1
            case .operator("?", .infix) where scopeDepth == 0:
                return i
            default:
                break
            }
            i += 1
        }
        return nil
    }

    /// Finds the matching `:` for a ternary `?` operator.
    /// Handles nested ternaries by tracking `?`/`:` depth.
    func findTernaryColon(after questionIndex: Int) -> Int? {
        var ternaryDepth = 1
        var scopeDepth = 0
        var i = questionIndex + 1

        while i < tokens.count {
            let token = tokens[i]
            switch token {
            case .startOfScope:
                scopeDepth += 1
            case .endOfScope:
                if scopeDepth == 0 {
                    return nil
                }
                scopeDepth -= 1
            case .operator("?", .infix) where scopeDepth == 0:
                ternaryDepth += 1
            case .operator(":", .infix) where scopeDepth == 0:
                ternaryDepth -= 1
                if ternaryDepth == 0 {
                    return i
                }
            default:
                break
            }
            i += 1
        }
        return nil
    }

    /// Converts a parsed ternary expression to an if expression.
    func convertTernaryToIfExpression(
        ternary: TernaryExpression,
        firstTokenIndex: Int,
        hasReturnKeyword: Bool,
        isSingleLine: Bool
    ) {
        // Build the replacement tokens for the if expression
        var replacementTokens = [Token]()

        // The indent for the if expression itself is the indent of the line where the ternary starts
        let ifIndent = currentIndentForLine(at: firstTokenIndex)

        if isSingleLine {
            buildSingleLineIfExpression(from: ternary, into: &replacementTokens)
        } else {
            buildMultiLineIfExpression(from: ternary, into: &replacementTokens, indent: ifIndent)
        }

        // Determine the range to replace: from replaceStart to the end of the ternary expression
        let ternaryEnd = falseBranchEnd(of: ternary)
        var replaceStart = firstTokenIndex
        if hasReturnKeyword {
            // Also remove the `return` keyword and trailing space
            replaceStart = index(of: .keyword("return"), before: firstTokenIndex) ?? firstTokenIndex
        }

        // Replace the ternary expression with the if expression
        let rangeToReplace = replaceStart ... ternaryEnd
        replaceTokens(in: rangeToReplace, with: replacementTokens)
    }

    /// Builds tokens for a single-line if expression: `if condition { trueExpr } else { falseExpr }`
    func buildSingleLineIfExpression(from ternary: TernaryExpression, into tokens: inout [Token]) {
        tokens.append(.keyword("if"))
        tokens.append(.space(" "))

        // Condition
        appendTokens(in: ternary.conditionRange, to: &tokens)

        tokens.append(.space(" "))
        tokens.append(.startOfScope("{"))
        tokens.append(.space(" "))

        // True branch
        switch ternary.trueBranch {
        case let .expression(range):
            appendTokens(in: range, to: &tokens)
        case let .nestedTernary(nested):
            buildSingleLineIfExpression(from: nested, into: &tokens)
        }

        tokens.append(.space(" "))
        tokens.append(.endOfScope("}"))
        tokens.append(.space(" "))
        tokens.append(.keyword("else"))
        tokens.append(.space(" "))
        tokens.append(.startOfScope("{"))
        tokens.append(.space(" "))

        // False branch
        switch ternary.falseBranch {
        case let .expression(range):
            appendTokens(in: range, to: &tokens)
        case let .nestedTernary(nested):
            buildSingleLineIfExpression(from: nested, into: &tokens)
        }

        tokens.append(.space(" "))
        tokens.append(.endOfScope("}"))
    }

    /// Builds tokens for a multi-line if expression
    func buildMultiLineIfExpression(from ternary: TernaryExpression, into tokens: inout [Token], indent: String) {
        let bodyIndent = indent + options.indent
        let linebreak = Token.linebreak(options.linebreak, 0)

        tokens.append(.keyword("if"))
        tokens.append(.space(" "))

        // Condition
        appendTokens(in: ternary.conditionRange, to: &tokens)

        tokens.append(.space(" "))
        tokens.append(.startOfScope("{"))
        tokens.append(linebreak)
        tokens.append(.space(bodyIndent))

        // True branch
        switch ternary.trueBranch {
        case let .expression(range):
            appendTokens(in: range, to: &tokens)
        case let .nestedTernary(nested):
            buildMultiLineIfExpression(from: nested, into: &tokens, indent: bodyIndent)
        }

        tokens.append(linebreak)
        tokens.append(.space(indent))
        tokens.append(.endOfScope("}"))
        tokens.append(.space(" "))
        tokens.append(.keyword("else"))
        tokens.append(.space(" "))
        tokens.append(.startOfScope("{"))
        tokens.append(linebreak)
        tokens.append(.space(bodyIndent))

        // False branch
        switch ternary.falseBranch {
        case let .expression(range):
            appendTokens(in: range, to: &tokens)
        case let .nestedTernary(nested):
            buildMultiLineIfExpression(from: nested, into: &tokens, indent: bodyIndent)
        }

        tokens.append(linebreak)
        tokens.append(.space(indent))
        tokens.append(.endOfScope("}"))
    }

    /// Appends tokens from the given range (trimming surrounding whitespace) into the output array
    func appendTokens(in range: ClosedRange<Int>, to output: inout [Token]) {
        var start = range.lowerBound
        while start <= range.upperBound, tokens[start].isSpaceOrLinebreak {
            start += 1
        }
        var end = range.upperBound
        while end >= start, tokens[end].isSpaceOrLinebreak {
            end -= 1
        }
        guard start <= end else { return }
        output.append(contentsOf: tokens[start ... end])
    }
}
