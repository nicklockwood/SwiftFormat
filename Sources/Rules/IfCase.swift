//
//  IfCase.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 10/23/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let ifCase = FormatRule(
        help: "Convert if case chains matching the same value to switch statements or expressions.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "indent", "indent-case", "wrap-string-interpolation"]
    ) { formatter in
        formatter.forEach(.keyword("if")) { ifIndex, _ in
            formatter.convertIfCaseToSwitch(at: ifIndex)
        }
    } examples: {
        """
        ```diff
        - if case let .success(value) = result {
        + switch result {
        + case let .success(value):
              handle(value)
        - } else {
        + default:
              handle(fallback)
          }
        ```

        ```diff
        - if case let .success(value) = result {
        + switch result {
        + case let .success(value):
              handle(value)
        + default:
        +     break
          }
        ```
        """
    }
}

extension Formatter {
    struct IfCaseBranch {
        var keywordIndex: Int
        var pattern: ClosedRange<Int>?
        var subject: ClosedRange<Int>?
        var body: ConditionalBranch
    }

    func ifCaseBranches(at ifIndex: Int) -> [IfCaseBranch]? {
        guard next(.nonSpaceOrCommentOrLinebreak, after: ifIndex) == .keyword("case"),
              last(.nonSpaceOrCommentOrLinebreak, before: ifIndex) != .keyword("else"),
              !isInStringLiteralWithWrappingDisabled(at: ifIndex)
        else { return nil }

        var branches = [IfCaseBranch]()
        var keywordIndex = ifIndex
        for body in ifStatementBranches(at: ifIndex) {
            var branch = IfCaseBranch(keywordIndex: keywordIndex, body: body)
            var conditionIndex = keywordIndex
            if tokens[keywordIndex] == .keyword("else"),
               let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex)
            {
                conditionIndex = nextIndex
            }

            if tokens[conditionIndex] == .keyword("if") {
                let conditions = parseConditionalStatement(at: conditionIndex)
                guard conditions.count == 1,
                      case let .patternMatching(range) = conditions[0],
                      let equalsIndex = index(of: .operator("=", .infix), in: range),
                      let patternEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: equalsIndex),
                      index(of: .delimiter(":"), in: range.lowerBound ... patternEnd) == nil,
                      let subjectStart = index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
                      let subjectEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: body.startOfBranch),
                      subjectStart <= subjectEnd
                else { return nil }
                branch.pattern = range.lowerBound ... patternEnd
                branch.subject = subjectStart ... subjectEnd
            } else if tokens[conditionIndex] != .startOfScope("{") {
                return nil
            }

            // Keep comments in headers and between branches in their original positions.
            guard !tokens[keywordIndex ..< body.startOfBranch].contains(where: \.isComment),
                  !ifCaseBodyContainsOuterBreak(at: body.startOfBranch)
            else { return nil }
            branches.append(branch)

            if let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: body.endOfBranch),
               tokens[nextIndex] == .keyword("else")
            {
                guard !tokens[(body.endOfBranch + 1) ..< nextIndex].contains(where: \.isComment) else {
                    return nil
                }
                keywordIndex = nextIndex
            }
        }

        guard let firstSubject = branches.first?.subject else { return nil }
        let subjectTokens = tokens[firstSubject].filter { !$0.isSpaceOrLinebreak }
        guard branches.allSatisfy({ branch in
            branch.subject.map { tokens[$0].filter { !$0.isSpaceOrLinebreak } == subjectTokens } ?? true
        }) else { return nil }

        // A switch evaluates its subject once, so don't merge repeated calls or subscripts.
        if branches.filter({ $0.subject != nil }).count > 1,
           subjectTokens.contains(where: { $0.isStartOfScope || $0 == .keyword("await") || $0 == .keyword("try") })
        {
            return nil
        }
        return branches
    }

    func convertIfCaseToSwitch(at ifIndex: Int) {
        guard var branches = ifCaseBranches(at: ifIndex) else { return }
        if let defaultBranch = addIfCaseDefaultReturnBranch(at: ifIndex, branches: branches) {
            branches.append(defaultBranch)
        }
        let needsBreak = branches.last?.pattern != nil || branches.contains {
            tokens[($0.body.startOfBranch + 1) ..< $0.body.endOfBranch].allSatisfy(\.isSpaceOrCommentOrLinebreak)
        }
        if needsBreak, isIfCaseInResultBuilder(at: ifIndex) {
            return
        }
        guard let subject = branches.first?.subject,
              let lastBranch = branches.last
        else { return }

        let subjectTokens = tokens[subject]
        let indent = currentIndentForLine(at: ifIndex)
        let caseIndent = indent + (options.indentCase ? options.indent : "")
        let bodyIndent = caseIndent + options.indent
        let linebreak = linebreakToken(for: ifIndex)
        var nextKeywordIndex: Int?

        for branch in branches.reversed() {
            let body = branch.body
            let contentRange = (body.startOfBranch + 1) ..< body.endOfBranch
            let firstContent = tokens[contentRange].firstIndex(where: { !$0.isSpaceOrLinebreak })
            let lastContent = tokens[contentRange].lastIndex(where: { !$0.isSpaceOrLinebreak })
            let trailingStart = lastContent.map { $0 + 1 } ?? body.endOfBranch
            let breakTokens: [Token] = firstContent != nil && tokens[contentRange].allSatisfy(\.isSpaceOrCommentOrLinebreak)
                ? [linebreak, .space(bodyIndent), .keyword("break")] : []

            if let nextKeywordIndex {
                replaceTokens(in: trailingStart ..< nextKeywordIndex,
                              with: breakTokens + [linebreak, .space(caseIndent)])
            } else if lastBranch.pattern != nil {
                replaceTokens(in: trailingStart ..< body.endOfBranch, with: breakTokens + [
                    linebreak,
                    .space(caseIndent), .endOfScope("default"), .startOfScope(":"),
                    linebreak, .space(bodyIndent), .keyword("break"), linebreak, .space(indent),
                ])
            } else {
                replaceTokens(in: trailingStart ..< body.endOfBranch,
                              with: breakTokens + [linebreak, .space(indent)])
            }

            if options.indentCase, let firstContent, let lastContent {
                indentIfCaseBody(in: firstContent ... lastContent)
            }

            replaceTokens(in: body.startOfBranch ..< (firstContent ?? body.endOfBranch), with:
                [.startOfScope(":"), linebreak, .space(bodyIndent)] + (firstContent == nil ? [.keyword("break")] : []))

            if let pattern = branch.pattern {
                removeTokens(in: (pattern.upperBound + 1) ..< body.startOfBranch)
                replaceToken(at: pattern.lowerBound, with: .endOfScope("case"))
                removeTokens(in: branch.keywordIndex ..< pattern.lowerBound)
            } else {
                replaceTokens(in: branch.keywordIndex ..< body.startOfBranch, with: .endOfScope("default"))
            }
            nextKeywordIndex = branch.keywordIndex
        }

        insert([.space(" "), .startOfScope("{"), linebreak, .space(caseIndent)], at: ifIndex)
        insert(subjectTokens, at: ifIndex)
        insert([.keyword("switch"), .space(" ")], at: ifIndex)
    }

    func addIfCaseDefaultReturnBranch(at ifIndex: Int, branches: [IfCaseBranch]) -> IfCaseBranch? {
        guard let lastBranch = branches.last, lastBranch.pattern != nil,
              branches.allSatisfy({ branch in
                  lastIndex(of: .keyword("return"), in: (branch.body.startOfBranch + 1) ..< branch.body.endOfBranch)
                      .map { ifCaseReturnEndsScope(at: $0) } ?? false
              }),
              let returnIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: lastBranch.body.endOfBranch),
              ifCaseReturnEndsScope(at: returnIndex),
              let scopeEnd = endOfScope(at: returnIndex),
              let contentEnd = tokens[returnIndex ..< scopeEnd].lastIndex(where: { !$0.isSpaceOrLinebreak })
        else { return nil }

        // Form an else branch so the normal switch conversion can preserve its contents.
        let indent = currentIndentForLine(at: ifIndex)
        let returnEnd = contentEnd.autoUpdating(in: self)
        insert([linebreakToken(for: ifIndex), .space(indent), .endOfScope("}")], at: contentEnd + 1)
        insert([.space(" "), .keyword("else"), .space(" "), .startOfScope("{")], at: lastBranch.body.endOfBranch + 1)

        let body = ifStatementBranches(at: ifIndex).last!
        let bodyRange = (body.startOfBranch ... body.endOfBranch).autoUpdating(in: self)
        indentIfCaseBody(in: body.startOfBranch ... returnEnd.index)
        return IfCaseBranch(keywordIndex: lastBranch.body.endOfBranch + 2,
                            body: (bodyRange.lowerBound, bodyRange.upperBound))
    }

    func ifCaseReturnEndsScope(at returnIndex: Int) -> Bool {
        guard tokens[returnIndex] == .keyword("return"),
              let expressionStart = index(of: .nonSpaceOrCommentOrLinebreak, after: returnIndex),
              let expression = parseExpressionRange(startingAt: expressionStart, allowConditionalExpressions: true),
              let scopeEnd = endOfScope(at: returnIndex),
              let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: expression.upperBound)
        else { return false }
        if tokens[nextIndex] == .delimiter(";") {
            return index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex) == scopeEnd
        }
        return nextIndex == scopeEnd
    }

    func indentIfCaseBody(in range: ClosedRange<Int>) {
        var endIndex = range.upperBound
        while let linebreakIndex = tokens[range.lowerBound ..< endIndex].lastIndex(where: \.isLinebreak) {
            if let token = token(at: linebreakIndex + 1), !token.isLinebreak {
                insertSpace(options.indent + (token.isSpace ? token.string : ""), at: linebreakIndex + 1)
            }
            endIndex = linebreakIndex
        }
    }

    func ifCaseBodyContainsOuterBreak(at bodyStart: Int) -> Bool {
        var index = bodyStart
        while let nextIndex = self.index(after: index, where: {
            $0 == .keyword("break") || $0 == .startOfScope("{") || $0 == .startOfScope("#if")
        }) {
            if tokens[nextIndex] == .keyword("break") {
                if next(.nonSpaceOrComment, after: nextIndex)?.isIdentifier != true {
                    return true
                }
            } else if tokens[nextIndex] == .startOfScope("#if") {
                if ifCaseBodyContainsOuterBreak(at: nextIndex) {
                    return true
                }
            } else if !isStartOfClosure(at: nextIndex),
                      !["for", "while", "repeat", "switch", "func"].contains(lastSignificantKeyword(at: nextIndex, excluding: ["where"]) ?? ""),
                      ifCaseBodyContainsOuterBreak(at: nextIndex)
            {
                return true
            }
            index = tokens[nextIndex].isStartOfScope ? (endOfScope(at: nextIndex) ?? nextIndex) : nextIndex
        }
        return false
    }

    func isIfCaseInResultBuilder(at ifIndex: Int) -> Bool {
        var scope = startOfScope(at: ifIndex)
        while let scopeIndex = scope {
            if isStartOfClosure(at: scopeIndex) {
                return isInResultBuilder(at: ifIndex)
            }
            if isStartOfDeclarationBody(at: scopeIndex),
               let keywordIndex = indexOfLastSignificantKeyword(at: scopeIndex, excluding: ["where", "throws", "rethrows"]),
               ["func", "var", "subscript"].contains(tokens[keywordIndex].string)
            {
                let modifiers = startOfModifiers(at: keywordIndex, includingAttributes: true)
                let hasBuilderAttribute = tokens[modifiers ..< keywordIndex].contains {
                    $0.isAttribute && $0.string.hasSuffix("Builder")
                }
                let hasOpaqueReturnType = tokens[keywordIndex ..< scopeIndex].contains(.identifier("some"))
                return (hasBuilderAttribute || (hasOpaqueReturnType && isInResultBuilder(at: ifIndex)))
                    && scopeBodySupportsResultBuilder(at: scopeIndex)
            }
            scope = startOfScope(at: scopeIndex)
        }
        return false
    }
}
