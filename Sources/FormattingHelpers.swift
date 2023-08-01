//
//  FormattingHelpers.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 16/08/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: shared helper methods

extension Formatter {
    /// should brace be wrapped according to `wrapMultilineStatementBraces` rule?
    func shouldWrapMultilineStatementBrace(at index: Int) -> Bool {
        assert(tokens[index] == .startOfScope("{"))
        guard let endIndex = endOfScope(at: index),
              tokens[index + 1 ..< endIndex].contains(where: { $0.isLinebreak }),
              let prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: index),
              let prevToken = token(at: prevIndex), !prevToken.isStartOfScope,
              !prevToken.isDelimiter
        else {
            return false
        }
        let indent = indentForLine(at: prevIndex)
        guard isStartOfClosure(at: index) else {
            return indent > indentForLine(at: endIndex)
        }
        if prevToken == .endOfScope(")"),
           !tokens[startOfLine(at: prevIndex, excludingIndent: true)].is(.endOfScope),
           let startIndex = self.index(of: .startOfScope("("), before: prevIndex),
           indentForLine(at: startIndex) < indent
        {
            return !onSameLine(startIndex, prevIndex)
        }
        return false
    }

    /// remove self if possible
    func removeSelf(at i: Int, exclude: Set<String>, include: Set<String>? = nil) -> Bool {
        guard case let .identifier(selfKeyword) = tokens[i], ["self", "Self"].contains(selfKeyword) else {
            assertionFailure()
            return false
        }
        let staticSelf = selfKeyword == "Self"
        let exclusionList = exclude
            .union(_FormatRules.globalSwiftFunctions)
            .union(staticSelf ? [] : options.selfRequired)
        guard let dotIndex = index(of: .nonSpaceOrLinebreak, after: i, if: {
            $0 == .operator(".", .infix)
        }), !exclude.contains(selfKeyword),
        let nextIndex = index(of: .nonSpaceOrLinebreak, after: dotIndex),
        let token = token(at: nextIndex), token.isIdentifier,
        case let name = token.unescaped(), (include.map { $0.contains(name) } ?? true),
        !isSymbol(at: nextIndex, in: exclusionList),
        !backticksRequired(at: nextIndex, ignoreLeadingDot: true)
        else {
            return false
        }
        var index = i
        loop: while let scopeStart = self.index(of: .startOfScope, before: index) {
            switch tokens[scopeStart] {
            case .startOfScope("["):
                break
            case .startOfScope("("):
                if let prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: scopeStart),
                   isSymbol(at: prevIndex, in: staticSelf ? [] : options.selfRequired.union([
                       "expect", // Special case to support autoclosure arguments in the Nimble framework
                   ]))
                {
                    return false
                }
            case let token:
                if token.isStringDelimiter {
                    break
                }
                break loop
            }
            index = scopeStart
        }
        removeTokens(in: i ..< nextIndex)
        return true
    }

    /// gather declared variable names, starting at index after let/var keyword
    func processDeclaredVariables(at index: inout Int, names: inout Set<String>,
                                  removeSelfKeyword: String?, onlyLocal: Bool,
                                  scopeAllowsImplicitSelfRebinding: Bool)
    {
        let isConditional = isConditionalStatement(at: index)
        var declarationIndex: Int? = -1
        var scopeIndexStack = [Int]()
        var locals = Set<String>()
        while let token = token(at: index) {
            outer: switch token {
            case let .identifier(name) where last(.nonSpace, before: index)?.isOperator == false:
                if name == removeSelfKeyword, isEnabled, let nextIndex = self.index(
                    of: .nonSpaceOrCommentOrLinebreak,
                    after: index, if: { $0 == .operator(".", .infix) }
                ), case .identifier? = next(
                    .nonSpaceOrComment,
                    after: nextIndex
                ) {
                    _ = removeSelf(at: index, exclude: names.union(locals))
                    break
                }
                switch next(.nonSpaceOrCommentOrLinebreak, after: index) {
                case .delimiter(":")? where !scopeIndexStack.isEmpty, .operator(".", _)?:
                    break outer
                default:
                    break
                }
                let name = token.unescaped()

                // Whether or not this property is a `let self` definition
                // that rebinds implicit self for the remainder of scope.
                // This is only permitted in `weak self` closures when
                // unwrapping self like `let self = self`.
                var isPermittedImplicitSelfRebinding = false
                if name == "self",
                   scopeAllowsImplicitSelfRebinding,
                   let equalsIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index)
                {
                    // If we find the end of the condition instead of an = token,
                    // then this was a shorthand `if let self` condition.
                    if tokens[equalsIndex] == .startOfScope("{") || tokens[equalsIndex] == .delimiter(",") || tokens[equalsIndex] == .keyword("else") {
                        isPermittedImplicitSelfRebinding = true
                    } else if tokens[equalsIndex] == Token.operator("=", .infix),
                              let rhsSelfIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
                              tokens[rhsSelfIndex] == .identifier("self"),
                              let nextToken = next(.nonSpaceOrCommentOrLinebreak, after: rhsSelfIndex),
                              nextToken == .startOfScope("{") || nextToken == .delimiter(",") || nextToken == .keyword("else")
                    {
                        isPermittedImplicitSelfRebinding = true
                    }
                }

                if name != "_", declarationIndex != nil || !isConditional {
                    if isPermittedImplicitSelfRebinding {
                        assert(name == "self")
                        names.remove("self")
                    } else {
                        locals.insert(name)
                    }
                }
                inner: while let nextIndex = self.index(of: .nonSpace, after: index) {
                    let token = tokens[nextIndex]
                    if isStartOfStatement(at: nextIndex) {
                        names.formUnion(locals)
                    }
                    let removeSelfKeyword = isEnabled && (
                        options.swiftVersion >= "5.4" || isConditionalStatement(at: nextIndex)
                    ) ? removeSelfKeyword : nil
                    let include = onlyLocal ? locals : nil
                    switch token {
                    case .keyword("is"), .keyword("as"), .keyword("try"), .keyword("await"):
                        break
                    case .identifier(removeSelfKeyword ?? ""):
                        _ = removeSelf(at: nextIndex, exclude: names, include: include)
                    case .startOfScope("<"), .startOfScope("["), .startOfScope("("),
                         .startOfScope where token.isStringDelimiter:
                        guard let endIndex = endOfScope(at: nextIndex) else {
                            return fatalError("Expected end of scope", at: nextIndex)
                        }
                        if let removeSelfKeyword = removeSelfKeyword {
                            var i = endIndex - 1
                            while i > nextIndex {
                                switch tokens[i] {
                                case .endOfScope("}"):
                                    i = self.index(of: .startOfScope("{"), before: i) ?? i
                                case .identifier(removeSelfKeyword):
                                    _ = removeSelf(at: i, exclude: names, include: include)
                                default:
                                    break
                                }
                                i -= 1
                            }
                            index = endOfScope(at: nextIndex)!
                        } else {
                            index = endIndex
                        }
                        fallthrough
                    case .number, .identifier:
                        index = max(index, nextIndex)
                        if next(.nonSpaceOrCommentOrLinebreak, after: index, if: {
                            $0.isOperator(ofType: .infix) || $0.isOperator(ofType: .postfix) || [
                                .keyword("is"), .keyword("as"), .delimiter(","),
                                .startOfScope("["), .startOfScope("("),
                            ].contains($0)
                        }) == nil {
                            names.formUnion(locals)
                            return
                        }
                        continue
                    case .keyword("let"), .keyword("var"):
                        names.formUnion(locals)
                        declarationIndex = nextIndex
                        index = nextIndex
                        break inner
                    case .keyword, .startOfScope("{"), .endOfScope("}"), .startOfScope(":"):
                        names.formUnion(locals)
                        return
                    case .endOfScope(")"):
                        let scopeIndex = scopeIndexStack.popLast() ?? -1
                        if let d = declarationIndex, d > scopeIndex {
                            declarationIndex = nil
                        }
                    case .delimiter(","):
                        if let d = declarationIndex, d >= scopeIndexStack.last ?? -1 {
                            declarationIndex = nil
                        }
                        index = nextIndex
                        names.formUnion(locals)
                        break inner
                    case .startOfScope("//"), .startOfScope("/*"):
                        if case let .commentBody(comment)? = next(.nonSpace, after: nextIndex) {
                            processCommentBody(comment, at: nextIndex)
                            if token == .startOfScope("//") {
                                processLinebreak()
                            }
                        }
                        index = endOfScope(at: nextIndex) ?? (tokens.count - 1)
                        continue inner
                    case .linebreak:
                        processLinebreak()
                    default:
                        break
                    }
                    index = nextIndex
                }
            case .keyword("let"), .keyword("var"):
                declarationIndex = index
            case .startOfScope("("):
                guard declarationIndex == nil else {
                    scopeIndexStack.append(index)
                    break
                }
                guard let endIndex = self.index(of: .endOfScope(")"), after: index) else {
                    return fatalError("Expected )", at: index)
                }
                guard tokens[index ..< endIndex].contains(where: {
                    [.keyword("let"), .keyword("var")].contains($0)
                }) else {
                    index = endIndex
                    break
                }
                scopeIndexStack.append(index)
            case .startOfScope("{"):
                guard isStartOfClosure(at: index), let nextIndex = endOfScope(at: index) else {
                    index -= 1
                    names.formUnion(locals)
                    return
                }
                index = nextIndex
            case .startOfScope("//"), .startOfScope("/*"):
                if case let .commentBody(comment)? = next(.nonSpace, after: index) {
                    processCommentBody(comment, at: index)
                    if token == .startOfScope("//") {
                        processLinebreak()
                    }
                }
                index = endOfScope(at: index) ?? (tokens.count - 1)
            case .linebreak:
                processLinebreak()
            default:
                break
            }
            index += 1
        }
    }

    /// Shared wrap implementation
    func wrapCollectionsAndArguments(completePartialWrapping: Bool, wrapSingleArguments: Bool) {
        let maxWidth = options.maxWidth
        func removeLinebreakBeforeEndOfScope(at endOfScope: inout Int) {
            guard let lastIndex = index(of: .nonSpace, before: endOfScope, if: {
                $0.isLinebreak
            }) else {
                return
            }
            if case .commentBody? = last(.nonSpace, before: lastIndex) {
                return
            }
            // Remove linebreak
            removeTokens(in: lastIndex ..< endOfScope)
            endOfScope = lastIndex
            // Remove trailing comma
            if let prevCommaIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: endOfScope, if: {
                $0 == .delimiter(",")
            }) {
                removeToken(at: prevCommaIndex)
                endOfScope -= 1
            }
        }

        func keepParameterLabelsOnSameLine(startOfScope i: Int, endOfScope: inout Int) {
            var endIndex = endOfScope
            while let index = self.lastIndex(of: .linebreak, in: i + 1 ..< endIndex) {
                endIndex = index
                // Check if this linebreak sits between two identifiers
                // (e.g. the external and internal argument labels)
                guard let lastIndex = self.index(of: .nonSpaceOrLinebreak, before: index, if: {
                    $0.isIdentifier
                }), let nextIndex = self.index(of: .nonSpaceOrLinebreak, after: index, if: {
                    $0.isIdentifier
                }) else {
                    continue
                }
                // Remove linebreak
                let range = lastIndex + 1 ..< nextIndex
                let linebreakAndIndent = tokens[index ..< nextIndex]
                replaceTokens(in: range, with: .space(" "))
                endOfScope -= (range.count - 1)
                // Insert replacement linebreak after next comma
                if let nextComma = self.index(of: .delimiter(","), after: index) {
                    if token(at: nextComma + 1)?.isSpace == true {
                        replaceToken(at: nextComma + 1, with: linebreakAndIndent)
                        endOfScope += linebreakAndIndent.count - 1
                    } else {
                        insert(Array(linebreakAndIndent), at: nextComma + 1)
                        endOfScope += linebreakAndIndent.count
                    }
                }
            }
        }

        func wrapReturnAndEffectsIfNecessary(
            startOfScope: Int,
            endOfFunctionScope: Int
        ) {
            guard token(at: startOfScope) == .startOfScope("("),
                  let openBracket = index(of: .startOfScope, after: endOfFunctionScope),
                  token(at: openBracket) == .startOfScope("{")
            else { return }

            func wrap(before index: Int) {
                insertSpace(indentForLine(at: index), at: index)
                insertLinebreak(at: index)

                // Remove any trailing whitespace that is now orphaned on the previous line
                if tokens[index - 1].is(.space) {
                    removeToken(at: index - 1)
                }
            }

            if let effectIndex = index(after: endOfFunctionScope, where: {
                [.keyword("throws"), .identifier("async")].contains($0)
            }), effectIndex < openBracket {
                switch options.wrapEffects {
                case .preserve:
                    break
                case .ifMultiline:
                    // If the effect is on the same line as the closing paren, wrap it
                    if startOfLine(at: endOfFunctionScope) == startOfLine(at: effectIndex) {
                        wrap(before: effectIndex)

                        // When wrapping the effect, we should also un-wrap any return type
                        if let returnArrowIndex = index(of: .operator("->", .infix), after: endOfFunctionScope),
                           returnArrowIndex < openBracket,
                           let tokenBeforeArrowIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: returnArrowIndex),
                           startOfLine(at: tokenBeforeArrowIndex) != startOfLine(at: returnArrowIndex)
                        {
                            replaceTokens(in: endOfLine(at: tokenBeforeArrowIndex) ..< returnArrowIndex, with: [.space(" ")])
                        }
                    }
                case .never:
                    if startOfLine(at: endOfFunctionScope) != startOfLine(at: effectIndex) {
                        replaceTokens(in: endOfLine(at: endOfFunctionScope) ..< effectIndex, with: [.space(" ")])
                    }
                }
            }

            if let returnArrowIndex = index(of: .operator("->", .infix), after: endOfFunctionScope),
               returnArrowIndex < openBracket
            {
                switch options.wrapReturnType {
                case .preserve:
                    break
                case .ifMultiline:
                    // If the return arrow is on the same line as the closing paren, wrap it
                    if startOfLine(at: endOfFunctionScope) == startOfLine(at: returnArrowIndex) {
                        wrap(before: returnArrowIndex)
                    }
                }
            }
        }

        func wrapArgumentsBeforeFirst(startOfScope i: Int,
                                      endOfScope: Int,
                                      allowGrouping: Bool,
                                      endOfScopeOnSameLine: Bool)
        {
            // Get indent
            let indent = indentForLine(at: i)
            var endOfScope = endOfScope

            keepParameterLabelsOnSameLine(startOfScope: i,
                                          endOfScope: &endOfScope)

            if endOfScopeOnSameLine {
                removeLinebreakBeforeEndOfScope(at: &endOfScope)
            } else {
                // Insert linebreak before closing paren
                if let lastIndex = self.index(of: .nonSpace, before: endOfScope) {
                    endOfScope += insertSpace(indent, at: lastIndex + 1)
                    if !tokens[lastIndex].isLinebreak {
                        insertLinebreak(at: lastIndex + 1)
                        endOfScope += 1
                    }
                }
            }

            // Insert linebreak after each comma
            var index = self.index(of: .nonSpaceOrCommentOrLinebreak, before: endOfScope)!
            if tokens[index] != .delimiter(",") {
                index += 1
            }
            while let commaIndex = self.lastIndex(of: .delimiter(","), in: i + 1 ..< index),
                  var linebreakIndex = self.index(of: .nonSpaceOrComment, after: commaIndex)
            {
                if let index = self.index(of: .nonSpace, before: linebreakIndex) {
                    linebreakIndex = index + 1
                }
                if !isCommentedCode(at: linebreakIndex + 1) {
                    if tokens[linebreakIndex].isLinebreak,
                       next(.nonSpace, after: linebreakIndex).map({ !$0.isLinebreak }) ?? false
                    {
                        endOfScope += insertSpace(indent + options.indent, at: linebreakIndex + 1)
                    } else if !allowGrouping || (maxWidth > 0 &&
                        lineLength(at: linebreakIndex) > maxWidth &&
                        lineLength(upTo: linebreakIndex) <= maxWidth)
                    {
                        insertLinebreak(at: linebreakIndex)
                        endOfScope += 1 + insertSpace(indent + options.indent, at: linebreakIndex + 1)
                    }
                }
                index = commaIndex
            }

            // Insert linebreak and indent after opening paren
            if let nextIndex = self.index(of: .nonSpaceOrComment, after: i) {
                if !tokens[nextIndex].isLinebreak {
                    insertLinebreak(at: nextIndex)
                    endOfScope += 1
                }
                if nextIndex + 1 < endOfScope, next(.nonSpace, after: nextIndex)?.isLinebreak == false {
                    var indent = indent
                    if (self.index(of: .nonSpace, after: nextIndex) ?? 0) < endOfScope {
                        indent += options.indent
                    }
                    endOfScope += insertSpace(indent, at: nextIndex + 1)
                }
            }

            wrapReturnAndEffectsIfNecessary(
                startOfScope: i,
                endOfFunctionScope: endOfScope
            )
        }
        func wrapArgumentsAfterFirst(startOfScope i: Int, endOfScope: Int, allowGrouping: Bool) {
            guard var firstArgumentIndex = index(of: .nonSpaceOrLinebreak, in: i + 1 ..< endOfScope) else {
                return
            }

            var endOfScope = endOfScope
            keepParameterLabelsOnSameLine(startOfScope: i,
                                          endOfScope: &endOfScope)

            // Remove linebreak after opening paren
            removeTokens(in: i + 1 ..< firstArgumentIndex)
            endOfScope -= (firstArgumentIndex - (i + 1))
            firstArgumentIndex = i + 1
            // Get indent
            let start = startOfLine(at: i)
            let indent = spaceEquivalentToTokens(from: start, upTo: firstArgumentIndex)
            removeLinebreakBeforeEndOfScope(at: &endOfScope)
            // Insert linebreak after each comma
            var lastBreakIndex: Int?
            var index = firstArgumentIndex
            while let commaIndex = self.index(of: .delimiter(","), in: index ..< endOfScope),
                  var linebreakIndex = self.index(of: .nonSpaceOrComment, after: commaIndex)
            {
                if let index = self.index(of: .nonSpace, before: linebreakIndex) {
                    linebreakIndex = index + 1
                }
                if maxWidth > 0, lineLength(upTo: commaIndex) >= maxWidth, let breakIndex = lastBreakIndex {
                    endOfScope += 1 + insertSpace(indent, at: breakIndex)
                    insertLinebreak(at: breakIndex)
                    lastBreakIndex = nil
                    index = commaIndex + 1
                    continue
                }
                if tokens[linebreakIndex].isLinebreak {
                    if linebreakIndex + 1 != endOfScope, !isCommentedCode(at: linebreakIndex + 1) {
                        endOfScope += insertSpace(indent, at: linebreakIndex + 1)
                    }
                } else if !allowGrouping {
                    insertLinebreak(at: linebreakIndex)
                    endOfScope += 1 + insertSpace(indent, at: linebreakIndex + 1)
                } else {
                    lastBreakIndex = linebreakIndex
                }
                index = commaIndex + 1
            }
            if maxWidth > 0, let breakIndex = lastBreakIndex, lineLength(at: breakIndex) > maxWidth {
                insertSpace(indent, at: breakIndex)
                insertLinebreak(at: breakIndex)
            }

            wrapReturnAndEffectsIfNecessary(
                startOfScope: i,
                endOfFunctionScope: endOfScope
            )
        }

        var lastIndex = -1
        forEachToken(onlyWhereEnabled: false) { i, token in
            guard case let .startOfScope(string) = token else {
                return
            }
            guard ["(", "[", "<"].contains(string) else {
                lastIndex = i
                return
            }

            if lastIndex < i, let i = (lastIndex + 1 ..< i).last(where: {
                tokens[$0].isLinebreak
            }) {
                lastIndex = i
            }

            guard let endOfScope = endOfScope(at: i) else {
                return
            }

            let mode: WrapMode
            var endOfScopeOnSameLine = false
            let hasMultipleArguments = index(of: .delimiter(","), in: i + 1 ..< endOfScope) != nil
            var isParameters = false
            switch string {
            case "(":
                // Don't wrap color/image literals due to Xcode bug
                guard let prevToken = self.token(at: i - 1),
                      prevToken != .keyword("#colorLiteral"),
                      prevToken != .keyword("#imageLiteral")
                else {
                    return
                }
                guard hasMultipleArguments || wrapSingleArguments ||
                    index(in: i + 1 ..< endOfScope, where: { $0.isComment }) != nil
                else {
                    // Not an argument list, or only one argument
                    lastIndex = i
                    return
                }

                endOfScopeOnSameLine = options.closingParenOnSameLine
                isParameters = isParameterList(at: i)
                if isParameters, options.wrapParameters != .default {
                    mode = options.wrapParameters
                } else {
                    mode = options.wrapArguments
                }
            case "<":
                mode = options.wrapArguments
            case "[":
                mode = options.wrapCollections
            default:
                return
            }
            guard mode != .disabled, let firstIdentifierIndex =
                index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                !isInSingleLineStringLiteral(at: i)
            else {
                lastIndex = i
                return
            }

            guard isEnabled else {
                lastIndex = i
                return
            }

            if completePartialWrapping,
               let firstLinebreakIndex = index(of: .linebreak, in: i + 1 ..< endOfScope)
            {
                switch mode {
                case .beforeFirst:
                    wrapArgumentsBeforeFirst(startOfScope: i,
                                             endOfScope: endOfScope,
                                             allowGrouping: firstIdentifierIndex > firstLinebreakIndex,
                                             endOfScopeOnSameLine: endOfScopeOnSameLine)
                case .preserve where firstIdentifierIndex > firstLinebreakIndex:
                    wrapArgumentsBeforeFirst(startOfScope: i,
                                             endOfScope: endOfScope,
                                             allowGrouping: true,
                                             endOfScopeOnSameLine: endOfScopeOnSameLine)
                case .afterFirst, .preserve:
                    wrapArgumentsAfterFirst(startOfScope: i,
                                            endOfScope: endOfScope,
                                            allowGrouping: true)
                case .disabled, .default:
                    assertionFailure() // Shouldn't happen
                }

            } else if maxWidth > 0, hasMultipleArguments || wrapSingleArguments {
                func willWrapAtStartOfReturnType(maxWidth: Int) -> Bool {
                    isInReturnType(at: i) && maxWidth < lineLength(at: i)
                }

                func startOfNextScopeNotInReturnType() -> Int? {
                    let endOfLine = self.endOfLine(at: i)
                    guard endOfScope < endOfLine else { return nil }

                    var startOfLastScopeOnLine = endOfScope

                    repeat {
                        guard let startOfNextScope = index(
                            of: .startOfScope,
                            in: startOfLastScopeOnLine + 1 ..< endOfLine
                        ) else {
                            return nil
                        }

                        startOfLastScopeOnLine = startOfNextScope
                    } while isInReturnType(at: startOfLastScopeOnLine)

                    return startOfLastScopeOnLine
                }

                func indexOfNextWrap() -> Int? {
                    let startOfNextScopeOnLine = startOfNextScopeNotInReturnType()
                    let nextNaturalWrap = indexWhereLineShouldWrap(from: endOfScope + 1)

                    switch (startOfNextScopeOnLine, nextNaturalWrap) {
                    case let (.some(startOfNextScopeOnLine), .some(nextNaturalWrap)):
                        return min(startOfNextScopeOnLine, nextNaturalWrap)
                    case let (nil, .some(nextNaturalWrap)):
                        return nextNaturalWrap
                    case let (.some(startOfNextScopeOnLine), nil):
                        return startOfNextScopeOnLine
                    case (nil, nil):
                        return nil
                    }
                }

                func wrapArgumentsWithoutPartialWrapping() {
                    switch mode {
                    case .preserve, .beforeFirst:
                        wrapArgumentsBeforeFirst(startOfScope: i,
                                                 endOfScope: endOfScope,
                                                 allowGrouping: false,
                                                 endOfScopeOnSameLine: endOfScopeOnSameLine)
                    case .afterFirst:
                        wrapArgumentsAfterFirst(startOfScope: i,
                                                endOfScope: endOfScope,
                                                allowGrouping: true)
                    case .disabled, .default:
                        assertionFailure() // Shouldn't happen
                    }
                }

                if currentRule == FormatRules.wrap {
                    let nextWrapIndex = indexOfNextWrap() ?? endOfLine(at: i)
                    if nextWrapIndex > lastIndex,
                       maxWidth < lineLength(upTo: nextWrapIndex),
                       !willWrapAtStartOfReturnType(maxWidth: maxWidth)
                    {
                        wrapArgumentsWithoutPartialWrapping()
                        lastIndex = nextWrapIndex
                        return
                    }
                } else if maxWidth < lineLength(upTo: endOfScope) {
                    wrapArgumentsWithoutPartialWrapping()
                }
            }

            lastIndex = i
        }

        // -- wrapconditions
        forEach(.keyword) { index, token in
            let indent: String
            let endOfConditionsToken: Token
            switch token {
            case .keyword("guard"):
                endOfConditionsToken = .keyword("else")
                indent = "      "
            case .keyword("if"):
                endOfConditionsToken = .startOfScope("{")
                indent = "   "
            case .keyword("while"):
                endOfConditionsToken = .startOfScope("{")
                indent = "      "
            default:
                return
            }

            // Only wrap when this is a control flow condition that spans multiple lines
            guard let endIndex = self.index(of: endOfConditionsToken, after: index),
                  let nextTokenIndex = self.index(of: .nonSpaceOrLinebreak, after: index),
                  !(onSameLine(index, endIndex) || self.index(of: .nonSpaceOrLinebreak, after: endOfLine(at: index)) == endIndex)
            else { return }

            switch options.wrapConditions {
            case .preserve, .disabled, .default:
                break
            case .beforeFirst:
                // Wrap if the next non-whitespace-or-comment
                // is on the same line as the control flow keyword
                if onSameLine(index, nextTokenIndex) {
                    insertLinebreak(at: index + 1)
                }
                // Re-indent lines
                var linebreakIndex: Int? = index + 1
                let indent = indentForLine(at: index) + options.indent
                while let index = linebreakIndex, index < endIndex {
                    insertSpace(indent, at: index + 1)
                    linebreakIndex = self.index(of: .linebreak, after: index)
                }
            case .afterFirst:
                // Unwrap if the next non-whitespace-or-comment
                // is not on the same line as the control flow keyword
                if !onSameLine(index, nextTokenIndex),
                   let linebreakIndex = self.index(of: .linebreak, in: index ..< nextTokenIndex)
                {
                    removeToken(at: linebreakIndex)
                }
                // Make sure there is exactly one space after control flow keyword
                insertSpace(" ", at: index + 1)
                // Re-indent lines
                var lastIndex = index + 1
                let indent = spaceEquivalentToTokens(from: startOfLine(at: index), upTo: index) + indent
                while let index = self.index(of: .linebreak, after: lastIndex), index < endIndex {
                    insertSpace(indent, at: index + 1)
                    lastIndex = index
                }
            }
        }

        // Wraps / re-wraps a multi-line statement where each delimiter index
        // should be the first token on its line, if the statement
        // is longer than the max width or there is already a linebreak
        // adjacent to one of the delimiters
        @discardableResult
        func wrapMultilineStatement(
            startIndex: Int,
            delimiterIndices: [Int],
            endIndex: Int
        ) -> Bool {
            // ** Decide whether or not this statement needs to be wrapped / re-wrapped
            let range = startOfLine(at: startIndex) ... endIndex
            let length = tokens[range].map { $0.string }.joined().count

            // Only wrap if this line if longer than the max width...
            let overMaximumWidth = maxWidth > 0 && length > maxWidth

            // ... or if there is at least one delimiter currently adjacent to a linebreak,
            // which means this statement is already being wrapped in some way
            // and should be re-wrapped to the expected way if necessary
            let delimitersAdjacentToLinebreak = delimiterIndices.filter { delimiterIndex in
                last(.nonSpaceOrComment, before: delimiterIndex)?.is(.linebreak) == true
                    || next(.nonSpaceOrComment, after: delimiterIndex)?.is(.linebreak) == true
            }.count

            if !(overMaximumWidth || delimitersAdjacentToLinebreak > 0) {
                return false
            }

            // ** Now that we know this is supposed to wrap,
            //    make sure each delimiter is the start of a line
            let indent = indentForLine(at: startIndex) + options.indent

            for indexToWrap in delimiterIndices.reversed() {
                // if this item isn't already on its own line, then wrap it
                if last(.nonSpaceOrComment, before: indexToWrap)?.is(.linebreak) == false {
                    // Remove the space immediately before this token if present,
                    // so it isn't orphaned on the previous line once we wrap
                    if tokens[indexToWrap - 1].isSpace {
                        removeToken(at: indexToWrap - 1)
                    }

                    insertSpace(indent, at: indexToWrap - 1)
                    insertLinebreak(at: indexToWrap - 1)

                    // While we're here, make sure there's exactly one space after the delimiter
                    let updatedAndIndex = indexToWrap + 1
                    if let nextExpressionIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: updatedAndIndex) {
                        replaceTokens(
                            in: (updatedAndIndex + 1) ..< nextExpressionIndex,
                            with: .space(" ")
                        )
                    }
                }
            }

            return true
        }

        // -- wraptypealiases
        forEach(.keyword("typealias")) { typealiasIndex, _ in
            guard options.wrapTypealiases == .beforeFirst || options.wrapTypealiases == .afterFirst,
                  let (equalsIndex, andTokenIndices, lastIdentifierIndex) = parseProtocolCompositionTypealias(at: typealiasIndex)
            else { return }

            // Decide which indices to wrap at
            //  - We always wrap at each `&`
            //  - For `beforeFirst`, we also wrap before the `=`
            let wrapIndices: [Int]
            switch options.wrapTypealiases {
            case .afterFirst:
                wrapIndices = andTokenIndices
            case .beforeFirst:
                wrapIndices = [equalsIndex] + andTokenIndices
            case .default, .disabled, .preserve:
                return
            }

            let didWrap = wrapMultilineStatement(
                startIndex: typealiasIndex,
                delimiterIndices: wrapIndices,
                endIndex: lastIdentifierIndex
            )

            guard didWrap else { return }

            // If we're using `afterFirst` and there was unexpectedly a linebreak
            // between the `typealias` and the `=`, we need to remove it
            let rangeBetweenTypealiasAndEquals = (typealiasIndex + 1) ..< equalsIndex
            if options.wrapTypealiases == .afterFirst,
               let linebreakIndex = rangeBetweenTypealiasAndEquals.first(where: { tokens[$0].isLinebreak })
            {
                removeToken(at: linebreakIndex)
                if tokens[linebreakIndex].isSpace, tokens[linebreakIndex] != .space(" ") {
                    replaceToken(at: linebreakIndex, with: .space(" "))
                }
            }
        }

        // --wrapternary
        forEach(.operator("?", .infix)) { conditionIndex, _ in
            guard options.wrapTernaryOperators != .default,
                  let expressionStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: conditionIndex),
                  !isInSingleLineStringLiteral(at: conditionIndex)
            else { return }

            // Find the : operator that separates the true and false branches
            // of this ternary operator
            //  - You can have nested ternary operators, so the immediate-next colon
            //    is not necessarily the colon of _this_ ternary operator.
            //  - To track nested ternary operators, we maintain a count of
            //    the unterminated `?` tokens that we've seen.
            //  - This ternary's colon token is the first colon we find
            //    where there isn't an unterminated `?`.
            var unterimatedTernaryCount = 0
            var currentIndex = conditionIndex + 1
            var foundColonIndex: Int?

            while foundColonIndex == nil,
                  currentIndex < tokens.count
            {
                switch tokens[currentIndex] {
                case .operator("?", .infix):
                    unterimatedTernaryCount += 1
                case .operator(":", .infix):
                    if unterimatedTernaryCount == 0 {
                        foundColonIndex = currentIndex
                    } else {
                        unterimatedTernaryCount -= 1
                    }
                default:
                    break
                }

                currentIndex += 1
            }

            guard let colonIndex = foundColonIndex,
                  let endOfElseExpression = endOfExpression(at: colonIndex, upTo: [])
            else { return }

            wrapMultilineStatement(
                startIndex: expressionStartIndex,
                delimiterIndices: [conditionIndex, colonIndex],
                endIndex: endOfElseExpression
            )
        }
    }

    /// Wrap a single-line statement body onto multiple lines
    func wrapStatementBody(at i: Int) {
        assert(token(at: i) == .startOfScope("{"))
        var openBraceIndex = i

        // We need to make sure to move past any closures in the conditional
        while isStartOfClosure(at: openBraceIndex) {
            guard let endOfClosureIndex = index(of: .endOfScope("}"), after: openBraceIndex),
                  let nextOpenBrace = index(of: .startOfScope("{"), after: endOfClosureIndex + 1)
            else {
                return
            }
            openBraceIndex = nextOpenBrace
        }

        guard var indexOfFirstTokenInNewScope = index(of: .nonSpaceOrComment, after: openBraceIndex),
              // If the scope is empty we don't need to do anything
              !tokens[indexOfFirstTokenInNewScope].isEndOfScope,
              // If there is already a newline after the brace we can just stop
              !tokens[indexOfFirstTokenInNewScope].isLinebreak
        else {
            return
        }

        insertLinebreak(at: indexOfFirstTokenInNewScope)

        if tokens[indexOfFirstTokenInNewScope - 1].isSpace {
            // We left behind a trailing space on the previous line so we should clean it up
            removeToken(at: indexOfFirstTokenInNewScope - 1)
            indexOfFirstTokenInNewScope -= 1
        }

        let movedTokenIndex = indexOfFirstTokenInNewScope + 1

        // We want the token to be indented one level more than the conditional is
        let indent = indentForLine(at: i) + options.indent
        insertSpace(indent, at: movedTokenIndex)

        guard var closingBraceIndex = index(of: .endOfScope("}"), after: movedTokenIndex),
              !(movedTokenIndex ..< closingBraceIndex).contains(where: { tokens[$0].isLinebreak })
        else {
            // The closing brace is already on its own line so we don't need to do anything else
            return
        }

        insertLinebreak(at: closingBraceIndex)

        let lineBreakIndex = closingBraceIndex
        closingBraceIndex += 1

        let previousIndex = lineBreakIndex - 1
        if tokens[previousIndex].isSpace {
            // We left behind a trailing space on the previous line so we should clean it up
            removeToken(at: previousIndex)
            closingBraceIndex -= 1
        }

        // We want the closing brace at the same indentation level as conditional
        insertSpace(indentForLine(at: i), at: closingBraceIndex)
    }

    func removeParen(at index: Int) {
        func tokenOutsideParenRequiresSpacing(at index: Int) -> Bool {
            guard let token = token(at: index) else { return false }
            switch token {
            case .identifier, .keyword, .number, .startOfScope("#if"):
                return true
            default:
                return false
            }
        }

        func tokenInsideParenRequiresSpacing(at index: Int) -> Bool {
            guard let token = token(at: index) else { return false }
            switch token {
            case .operator, .startOfScope("{"), .endOfScope("}"):
                return true
            default:
                return tokenOutsideParenRequiresSpacing(at: index)
            }
        }

        let isStartOfScope = tokens[index].isStartOfScope
        let spaceBefore = token(at: index - 1)?.isSpace == true
        let spaceAfter = token(at: index + 1)?.isSpaceOrLinebreak == true
        removeToken(at: index)
        if isStartOfScope {
            if tokenOutsideParenRequiresSpacing(at: index - 1),
               tokenInsideParenRequiresSpacing(at: index)
            {
                if !spaceBefore, !spaceAfter {
                    // Need to insert one
                    insert(.space(" "), at: index)
                }
            } else if spaceAfter, spaceBefore {
                removeToken(at: index - 1)
            }
        } else {
            if tokenInsideParenRequiresSpacing(at: index - 1),
               tokenOutsideParenRequiresSpacing(at: index)
            {
                if !spaceBefore, !spaceAfter {
                    // Need to insert one
                    insert(.space(" "), at: index)
                }
            } else if spaceBefore {
                removeToken(at: index - 1)
            }
        }
    }

    /// Common implementation for the `hoistTry` and `hoistAwait` rules
    /// Hoists the first keyword of the specified type out of the specified scope
    func hoistEffectKeyword(
        _ keyword: String,
        inScopeAt scopeStart: Int,
        isEffectCapturingAt: (Int) -> Bool
    ) {
        assert([.startOfScope("("), .startOfScope("[")].contains(tokens[scopeStart]))
        assert(["try", "await"].contains(keyword))

        func insertEffectKeyword(at index: Int) {
            var index = index
            while tokens[index].isSpaceOrLinebreak {
                index += 1
            }

            if tokens[index] == .keyword(keyword) {
                return
            }

            insert([.keyword(keyword)], at: index)

            if let nextToken = token(at: index + 1), !nextToken.isSpace {
                insertSpace(" ", at: index + 1)
            } else {
                insertSpace(" ", at: index)
            }
        }

        func removeKeyword(at index: Int) {
            removeToken(at: index)
            if token(at: index)?.isSpace == true {
                removeToken(at: index)
            }
        }

        var indicesToRemove = [Int]()
        var prev = scopeStart
        while let i = index(of: .keyword(keyword), after: prev) {
            if token(at: i + 1)?.isUnwrapOperator == false {
                indicesToRemove.append(i)
            }
            prev = i
        }
        if indicesToRemove.isEmpty {
            return
        }

        var insertIndex = scopeStart
        loop: while let i = index(of: .nonSpace, before: insertIndex) {
            let prevToken = tokens[insertIndex]
            switch tokens[i] {
            case .identifier where [.startOfScope("("), .startOfScope("[")].contains(prevToken):
                if isEffectCapturingAt(i) {
                    return
                }
            case let .operator(name, .infix) where name != "=":
                if [.startOfScope("("), .startOfScope("[")].contains(prevToken), isEffectCapturingAt(i) {
                    return
                }
            case let .keyword(name) where ["is", "as", "try", "await"].contains(name):
                break
            case .operator(_, .prefix), .stringBody,
                 .endOfScope(")") where prevToken.isStringBody ||
                     (prevToken.isEndOfScope && prevToken.isStringDelimiter),
                 .startOfScope where tokens[i].isStringDelimiter,
                 .endOfScope where tokens[i].isStringDelimiter:
                break
            case _ where tokens[i].isUnwrapOperator:
                if last(.nonSpaceOrComment, before: i) == .keyword("try") {
                    if keyword == "try" {
                        // Can't merge try? and try
                        return
                    }
                    break loop
                }
                if prevToken != .startOfScope("("), prevToken != .startOfScope("[") {
                    fallthrough
                }
            case .operator(_, .postfix), .identifier, .number,
                 .endOfScope(">"), .endOfScope("]"), .endOfScope(")"):
                switch prevToken {
                case .operator(_, .infix), .operator(_, .postfix), .stringBody,
                     .startOfScope("<"), .startOfScope("["), .startOfScope("("),
                     _ where currentScope(at: i + 1)?.isMultilineStringDelimiter == true:
                    break
                default:
                    break loop
                }
                if tokens[i].isEndOfScope {
                    insertIndex = startOfScope(at: i) ?? i
                    continue
                }
            case .linebreak:
                if prevToken.isOperator(ofType: .infix) {
                    insertIndex = index(of: .nonSpaceOrLinebreak, before: i) ?? i
                    continue
                }
            default:
                break loop
            }
            insertIndex = i
        }

        indicesToRemove.reversed().forEach(removeKeyword(at:))
        insertEffectKeyword(at: insertIndex)
    }

    /// Whether or not the code block starting at the given `.startOfScope` token
    /// has a single statement. This makes it eligible to be used with implicit return.
    func blockBodyHasSingleStatement(
        atStartOfScope startOfScopeIndex: Int,
        includingConditionalStatements: Bool,
        includingReturnStatements: Bool,
        includingReturnInConditionalStatements: Bool? = nil
    ) -> Bool {
        guard let endOfScopeIndex = endOfScope(at: startOfScopeIndex) else { return false }
        let startOfBody = self.startOfBody(atStartOfScope: startOfScopeIndex)

        // The body should contain exactly one expression.
        // We can confirm this by parsing the body with `parseExpressionRange`,
        // and checking that the token after that expression is just the end of the scope.
        guard var firstTokenInBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfBody) else {
            return false
        }

        // Skip over any optional `return` keyword
        if includingReturnStatements, tokens[firstTokenInBody] == .keyword("return") {
            guard let tokenAfterReturnKeyword = index(of: .nonSpaceOrCommentOrLinebreak, after: firstTokenInBody) else { return false }
            firstTokenInBody = tokenAfterReturnKeyword
        }

        // In Swift 5.9+, if and switch statements where each branch is a single statement
        // are also considered single statements
        if options.swiftVersion >= "5.9",
           includingConditionalStatements,
           let conditionalBranches = conditionalBranches(at: firstTokenInBody)
        {
            let isSupportedSingleStatement = conditionalBranches.allSatisfy { branch in
                // In Swift 5.9, there's a bug that prevents you from writing an
                // if or switch expression using an `as?` on one of the branches:
                // https://github.com/apple/swift/issues/68764
                //
                //  if condition {
                //    foo as? String
                //  } else {
                //    "bar"
                //  }
                //
                if conditionalBranchHasUnsupportedCastOperator(startOfScopeIndex: branch.startOfBranch) {
                    return false
                }

                return blockBodyHasSingleStatement(
                    atStartOfScope: branch.startOfBranch,
                    includingConditionalStatements: true,
                    includingReturnStatements: includingReturnInConditionalStatements ?? includingReturnStatements,
                    includingReturnInConditionalStatements: includingReturnInConditionalStatements
                )
            }

            let endOfStatement = conditionalBranches.last?.endOfBranch ?? firstTokenInBody
            let isOnlyStatement = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfStatement) == endOfScopeIndex

            return isSupportedSingleStatement && isOnlyStatement
        }

        guard let expressionRange = parseExpressionRange(startingAt: firstTokenInBody),
              let nextIndexAfterExpression = index(of: .nonSpaceOrCommentOrLinebreak, after: expressionRange.upperBound)
        else {
            return false
        }

        return nextIndexAfterExpression == endOfScopeIndex
    }

    /// The token before the body of the scope following the given `startOfScopeIndex`.
    /// If this is a closure, the body starts after any `in` clause that may exist.
    func startOfBody(atStartOfScope startOfScopeIndex: Int) -> Int {
        // If this is a closure that has an `in` clause, the body scope starts after that
        if isStartOfClosure(at: startOfScopeIndex),
           let endOfScopeIndex = endOfScope(at: startOfScopeIndex),
           let inToken = index(of: .keyword("in"), in: (startOfScopeIndex + 1) ..< endOfScopeIndex),
           !indexIsWithinNestedClosure(inToken, startOfScopeIndex: startOfScopeIndex)
        {
            return inToken
        } else {
            return startOfScopeIndex
        }
    }

    typealias ConditionalBranch = (startOfBranch: Int, endOfBranch: Int)

    /// If `index` is the start of an `if` or `switch` statement,
    /// finds and returns all of the statement branches.
    func conditionalBranches(at index: Int) -> [ConditionalBranch]? {
        switch tokens[index] {
        case .keyword("await"):
            // Skip over any `try`, `try?`, `try!`, or `await` token,
            // which are valid before an if/switch expression.
            if let nextToken = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                return conditionalBranches(at: nextToken)
            }
            return nil
        case .keyword("try"):
            if let tokenAfterTry = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                if tokens[tokenAfterTry] == .operator("!", .postfix) || tokens[tokenAfterTry] == .operator("?", .postfix),
                   let tokenAfterOperator = self.index(of: .nonSpaceOrCommentOrLinebreak, after: tokenAfterTry)
                {
                    return conditionalBranches(at: tokenAfterOperator)
                } else {
                    return conditionalBranches(at: tokenAfterTry)
                }
            }
            return nil
        case .keyword("if"):
            return ifStatementBranches(at: index)
        case .keyword("switch"):
            return switchStatementBranches(at: index)
        default:
            return nil
        }
    }

    /// Finds all of the branch bodies in an if statement.
    /// Returns the index of the `startOfScope` and `endOfScope` of each branch.
    func ifStatementBranches(at ifIndex: Int) -> [ConditionalBranch] {
        assert(tokens[ifIndex] == .keyword("if"))
        var branches = [(startOfBranch: Int, endOfBranch: Int)]()
        var nextConditionalBranchIndex: Int? = ifIndex

        while let conditionalBranchIndex = nextConditionalBranchIndex,
              conditionalBranchIndex == ifIndex || tokens[conditionalBranchIndex] == .keyword("else"),
              let startOfBody = index(of: .startOfScope("{"), after: conditionalBranchIndex),
              let endOfBody = endOfScope(at: startOfBody)
        {
            branches.append((startOfBranch: startOfBody, endOfBranch: endOfBody))
            nextConditionalBranchIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfBody)
        }

        return branches
    }

    /// Finds all of the branch bodies in a switch statement.
    /// Returns the index of the `startOfScope` and `endOfScope` of each branch.
    func switchStatementBranches(at switchIndex: Int) -> [ConditionalBranch]? {
        assert(tokens[switchIndex] == .keyword("switch"))
        guard let startOfSwitchScope = index(of: .startOfScope("{"), after: switchIndex),
              let firstCaseIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfSwitchScope),
              tokens[firstCaseIndex].isSwitchCaseOrDefault
        else { return nil }

        var branches = [(startOfBranch: Int, endOfBranch: Int)]()
        var nextConditionalBranchIndex: Int? = firstCaseIndex

        while let conditionalBranchIndex = nextConditionalBranchIndex,
              tokens[conditionalBranchIndex].isSwitchCaseOrDefault,
              let startOfBody = index(of: .startOfScope(":"), after: conditionalBranchIndex),
              let endOfBody = endOfScope(at: startOfBody)
        {
            branches.append((startOfBranch: startOfBody, endOfBranch: endOfBody))

            if tokens[endOfBody].isSwitchCaseOrDefault {
                nextConditionalBranchIndex = endOfBody
            } else if tokens[startOfBody ..< endOfBody].contains(.startOfScope("#if")) {
                return nil
            } else {
                break
            }
        }

        return branches
    }

    /// In Swift 5.9, there's a bug that prevents you from writing an
    /// if or switch expression using an `as?` on one of the branches:
    /// https://github.com/apple/swift/issues/68764
    ///
    ///  if condition {
    ///    foo as? String
    ///  } else {
    ///    "bar"
    ///  }
    ///
    /// This helper returns whether or not the branch starting at the given `startOfScopeIndex`
    /// includes an `as?` operator, so wouldn't be permitted in a if/switch exprssion in Swift 5.9
    func conditionalBranchHasUnsupportedCastOperator(startOfScopeIndex: Int) -> Bool {
        if options.swiftVersion == "5.9",
           let asIndex = index(of: .keyword("as"), after: startOfScopeIndex),
           let endOfScopeIndex = endOfScope(at: startOfScopeIndex),
           asIndex < endOfScopeIndex,
           next(.nonSpaceOrCommentOrLinebreak, after: asIndex) == .operator("?", .postfix),
           // Make sure the as? is at the top level, not nested in some
           // inner scope like a function call or closure
           startOfScope(at: asIndex) == startOfScopeIndex
        {
            return true
        }

        return false
    }

    /// Performs a closure for each conditional branch in the given conditional statement,
    /// including any recursive conditional inside an individual branch.
    /// Iterates backwards to support removing tokens in `handle`.
    func forEachRecursiveConditionalBranch(
        in branches: [ConditionalBranch],
        _ handle: (ConditionalBranch) -> Void
    ) {
        for branch in branches.reversed() {
            if let tokenAfterEquals = index(of: .nonSpaceOrCommentOrLinebreak, after: branch.startOfBranch),
               let conditionalBranches = conditionalBranches(at: tokenAfterEquals)
            {
                forEachRecursiveConditionalBranch(in: conditionalBranches, handle)
            } else {
                handle(branch)
            }
        }
    }

    /// Performs a check for each conditional branch in the given conditional statement,
    /// including any recursive conditional inside an individual branch
    func allRecursiveConditionalBranches(
        in branches: [ConditionalBranch],
        satisfy branchSatisfiesCondition: (ConditionalBranch) -> Bool
    )
        -> Bool
    {
        var allSatisfy = true
        forEachRecursiveConditionalBranch(in: branches) { branch in
            if !branchSatisfiesCondition(branch) {
                allSatisfy = false
            }
        }
        return allSatisfy
    }

    /// Whether the given index is directly within the body of the given scope, or part of a nested closure
    func indexIsWithinNestedClosure(_ index: Int, startOfScopeIndex: Int) -> Bool {
        let startOfScopeAtIndex: Int
        if token(at: index)?.isStartOfScope == true {
            startOfScopeAtIndex = index
        } else if let previousStartOfScope = self.index(of: .startOfScope, before: index) {
            startOfScopeAtIndex = previousStartOfScope
        } else {
            return false
        }

        if startOfScopeAtIndex <= startOfScopeIndex {
            return false
        }

        if isStartOfClosureOrFunctionBody(at: startOfScopeAtIndex) {
            return startOfScopeAtIndex != startOfScopeIndex
        } else if token(at: startOfScopeAtIndex)?.isStartOfScope == true {
            return indexIsWithinNestedClosure(startOfScopeAtIndex - 1, startOfScopeIndex: startOfScopeIndex)
        } else {
            return false
        }
    }

    func isStartOfClosureOrFunctionBody(at startOfScopeIndex: Int) -> Bool {
        guard tokens[startOfScopeIndex] == .startOfScope("{") else { return false }

        // An open brace is always one of:
        //  - a statement with a keyword, like `if x { ...`
        //  - a declaration with keyword, like `func x() { ... ` or `var x: String { ...`
        //  - a closure, which won't have an associated keyword, like `value.map { ...`.
        if isStartOfClosure(at: startOfScopeIndex) {
            return true
        } else {
            // Since this isn't a closure, it should be either the start of a statement
            // like `if x { ...` _or_ a declaration like `func x() { ... `.
            // All of these cases have a keyword, so the last significant keyword
            // should be part of the same declaration / statement as the brace itself.
            return last(.keyword, before: startOfScopeIndex) == .keyword("func")
        }
    }
}

/// Helpers for recursively traversing the declaration hierarchy
extension Formatter {
    /// Applies `mapRecursiveDeclarations` in place
    func mapRecursiveDeclarations(with transform: (Declaration) -> Declaration) {
        let updatedDeclarations = mapRecursiveDeclarations(parseDeclarations()) { declaration, _ in
            transform(declaration)
        }
        let updatedTokens = updatedDeclarations.flatMap { $0.tokens }
        replaceTokens(in: tokens.indices, with: updatedTokens)
    }

    /// Applies `transform` to every recursive declaration of the given declarations
    func mapRecursiveDeclarations(
        _ declarations: [Declaration], in stack: [Declaration] = [],
        with transform: (Declaration, _ stack: [Declaration]) -> Declaration
    ) -> [Declaration] {
        declarations.map { declaration in
            let mapped = transform(declaration, stack)
            switch mapped {
            case let .type(kind, open, body, close):
                return .type(
                    kind: kind,
                    open: open,
                    body: mapRecursiveDeclarations(body, in: stack + [mapped], with: transform),
                    close: close
                )

            case let .conditionalCompilation(open, body, close):
                return .conditionalCompilation(
                    open: open,
                    body: mapRecursiveDeclarations(body, in: stack + [mapped], with: transform),
                    close: close
                )

            case .declaration:
                return declaration
            }
        }
    }

    /// Performs some declaration mapping for each body declaration in this declaration
    /// (including any declarations nested in conditional compilation blocks,
    ///  but not including declarations dested within child types).
    func mapBodyDeclarations(
        in declaration: Declaration,
        with transform: (Declaration) -> Declaration
    ) -> Declaration {
        switch declaration {
        case let .type(kind, open, body, close):
            return .type(
                kind: kind,
                open: open,
                body: mapBodyDeclarations(body, with: transform),
                close: close
            )

        case let .conditionalCompilation(open, body, close):
            return .conditionalCompilation(
                open: open,
                body: mapBodyDeclarations(body, with: transform),
                close: close
            )

        case .declaration:
            // No work to do, because plain declarations don't have bodies
            return declaration
        }
    }

    private func mapBodyDeclarations(
        _ body: [Declaration],
        with transform: (Declaration) -> Declaration
    ) -> [Declaration] {
        body.map { bodyDeclaration in
            // Apply `mapBodyDeclaration` to each declaration in the body
            switch bodyDeclaration {
            case .declaration, .type:
                return transform(bodyDeclaration)

            // Recursively step through conditional compilation blocks
            // since their body tokens are effectively body tokens of the parent type
            case .conditionalCompilation:
                return mapBodyDeclarations(in: bodyDeclaration, with: transform)
            }
        }
    }

    /// Performs some generic mapping for each declaration in the given array,
    /// stepping through conditional compilation blocks (but not into the body
    /// of other nested types)
    func mapDeclarations<T>(
        _ declarations: [Declaration],
        with transform: (Declaration) -> T
    ) -> [T] {
        declarations.flatMap { declaration -> [T] in
            switch declaration {
            case .declaration, .type:
                return [transform(declaration)]
            case let .conditionalCompilation(_, body, _):
                return mapDeclarations(body, with: transform)
            }
        }
    }

    /// Maps the first group of tokens in this declaration
    ///  - For declarations with a body, this maps the `open` tokens
    ///  - For declarations without a body, this maps the entire declaration's tokens
    func mapOpeningTokens(
        in declaration: Declaration,
        with transform: ([Token]) -> [Token]
    ) -> Declaration {
        switch declaration {
        case let .type(kind, open, body, close):
            return .type(
                kind: kind,
                open: transform(open),
                body: body,
                close: close
            )

        case let .conditionalCompilation(open, body, close):
            return .conditionalCompilation(
                open: transform(open),
                body: body,
                close: close
            )

        case let .declaration(kind, tokens):
            return .declaration(
                kind: kind,
                tokens: transform(tokens)
            )
        }
    }

    /// Maps the last group of tokens in this declaration
    ///  - For declarations with a body, this maps the `close` tokens
    ///  - For declarations without a body, this maps the entire declaration's tokens
    func mapClosingTokens(
        in declaration: Declaration,
        with transform: ([Token]) -> [Token]
    ) -> Declaration {
        switch declaration {
        case let .type(kind, open, body, close):
            return .type(
                kind: kind,
                open: open,
                body: body,
                close: transform(close)
            )

        case let .conditionalCompilation(open, body, close):
            return .conditionalCompilation(
                open: open,
                body: body,
                close: transform(close)
            )

        case let .declaration(kind, tokens):
            return .declaration(
                kind: kind,
                tokens: transform(tokens)
            )
        }
    }
}

/// Utility functions used by organizeDeclarations rule
// TODO: find a better place to put this
extension Formatter {
    /// Categories of declarations within an individual type
    enum Category: String, CaseIterable {
        case beforeMarks
        case lifecycle
        case open
        case `public`
        case package
        case `internal`
        case `fileprivate`
        case `private`

        init(from visibility: Visibility) {
            switch visibility {
            case .open:
                self = .open
            case .public:
                self = .public
            case .package:
                self = .package
            case .internal:
                self = .internal
            case .fileprivate:
                self = .fileprivate
            case .private:
                self = .private
            }
        }

        /// The comment tokens that should precede all declarations in this category
        func markComment(from template: String) -> String? {
            switch self {
            case .beforeMarks:
                return nil
            default:
                return "// \(template.replacingOccurrences(of: "%c", with: rawValue.capitalized))"
            }
        }
    }

    /// The visibility of a declaration
    enum Visibility: String, CaseIterable, Comparable {
        case open
        case `public`
        case package
        case `internal`
        case `fileprivate`
        case `private`

        static func < (lhs: Visibility, rhs: Visibility) -> Bool {
            allCases.firstIndex(of: lhs)! > allCases.firstIndex(of: rhs)!
        }
    }

    /// Types of declarations that can be present within an individual category
    enum DeclarationType {
        case nestedType
        case staticProperty
        case staticPropertyWithBody
        case classPropertyWithBody
        case instanceProperty
        case instancePropertyWithBody
        case staticMethod
        case classMethod
        case instanceMethod
    }

    static let categoryOrdering: [Category] = [
        .beforeMarks, .lifecycle, .open, .public, .package, .internal, .fileprivate, .private,
    ]

    static let categorySubordering: [DeclarationType] = [
        .nestedType, .staticProperty, .staticPropertyWithBody, .classPropertyWithBody,
        .instanceProperty, .instancePropertyWithBody, .staticMethod, .classMethod, .instanceMethod,
    ]

    /// The `Category` of the given `Declaration`
    func category(of declaration: Declaration) -> Category {
        switch declaration {
        case let .declaration(keyword, tokens), let .type(keyword, open: tokens, _, _):
            guard let keywordIndex = tokens.firstIndex(of: .keyword(keyword)) else {
                // This should never happen (the declaration's `keyword` will always be present in the tokens)
                return .internal
            }

            // Enum cases don't fit into any of the other categories,
            // so they should go in the initial top section.
            //  - The user can also provide other declaration types to place in this category
            if keyword == "case" || options.beforeMarks.contains(keyword) {
                return .beforeMarks
            }

            let parser = Formatter(tokens)
            if Formatter.categoryOrdering.contains(.lifecycle) {
                // `init` and `deinit` always go in Lifecycle if it's present
                if ["init", "deinit"].contains(keyword) {
                    return .lifecycle
                }

                // The user can also provide specific instance method names to place in Lifecycle
                //  - In the function declaration grammar, the function name always
                //    immediately follows the `func` keyword:
                //    https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_function-name
                if keyword == "func",
                   let methodName = parser.next(.nonSpaceOrCommentOrLinebreak, after: keywordIndex),
                   options.lifecycleMethods.contains(methodName.string)
                {
                    return .lifecycle
                }
            }

            // Other than `beforeMarks` and `lifecycle`, the category is just the visibility level
            return Category(from: visibility(of: declaration) ?? .internal)

        case let .conditionalCompilation(_, body, _):
            // Conditional compilation blocks themselves don't have a category or visbility-level,
            // but we still have to assign them a category for the sorting algorithm to function.
            // A reasonable heuristic here is to simply use the category of the first declaration
            // inside the conditional compilation block.
            if let firstDeclarationInBlock = body.first {
                return category(of: firstDeclarationInBlock)
            } else {
                return .beforeMarks
            }
        }
    }

    /// The access control `Visibility` of the given `Declaration`
    func visibility(of declaration: Declaration) -> Visibility? {
        switch declaration {
        case let .declaration(keyword, tokens), let .type(keyword, open: tokens, _, _):
            guard let keywordIndex = tokens.firstIndex(of: .keyword(keyword)) else {
                return nil
            }

            // Search for a visibility keyword in the tokens before the primary keyword,
            // making sure we exclude groups like private(set).
            var searchIndex = 0
            let parser = Formatter(tokens)
            while searchIndex < keywordIndex {
                if let visibility = Visibility(rawValue: parser.tokens[searchIndex].string),
                   parser.next(.nonSpaceOrComment, after: searchIndex) != .startOfScope("(")
                {
                    return visibility
                }

                searchIndex += 1
            }

            return nil
        case .conditionalCompilation:
            return nil
        }
    }

    /// The `DeclarationType` of the given `Declaration`
    func type(of declaration: Declaration) -> DeclarationType? {
        switch declaration {
        case .type:
            return .nestedType

        case let .declaration(keyword, tokens):
            guard let declarationTypeTokenIndex = tokens.firstIndex(of: .keyword(keyword)) else {
                return nil
            }

            let declarationParser = Formatter(tokens)
            let declarationTypeToken = declarationParser.tokens[declarationTypeTokenIndex]

            let isStaticDeclaration = declarationParser.index(
                of: .keyword("static"),
                before: declarationTypeTokenIndex
            ) != nil

            let isClassDeclaration = declarationParser.index(
                of: .keyword("class"),
                before: declarationTypeTokenIndex
            ) != nil

            switch declarationTypeToken {
            // Properties and property-like declarations
            case .keyword("let"), .keyword("var"),
                 .keyword("case"), .keyword("operator"), .keyword("precedencegroup"):

                var hasBody: Bool
                // If there is a code block at the end of the declaration that is _not_ a closure,
                // then this declaration has a body.
                if let lastClosingBraceIndex = declarationParser.index(of: .endOfScope("}"), before: declarationParser.tokens.count),
                   let lastOpeningBraceIndex = declarationParser.index(of: .startOfScope("{"), before: lastClosingBraceIndex),
                   declarationTypeTokenIndex < lastOpeningBraceIndex,
                   declarationTypeTokenIndex < lastClosingBraceIndex,
                   !declarationParser.isStartOfClosure(at: lastOpeningBraceIndex)
                {
                    hasBody = true
                } else {
                    hasBody = false
                }

                if isStaticDeclaration {
                    if hasBody {
                        return .staticPropertyWithBody
                    } else {
                        return .staticProperty
                    }
                } else if isClassDeclaration {
                    // Interestingly, Swift does not support stored class properties
                    // so there's no such thing as a class property without a body.
                    // https://forums.swift.org/t/class-properties/16539/11
                    return .classPropertyWithBody
                } else {
                    if hasBody {
                        return .instancePropertyWithBody
                    } else {
                        return .instanceProperty
                    }
                }

            // Functions and function-like declarations
            case .keyword("func"), .keyword("init"), .keyword("deinit"), .keyword("subscript"):
                if isStaticDeclaration {
                    return .staticMethod
                } else if isClassDeclaration {
                    return .classMethod
                } else {
                    return .instanceMethod
                }

            // Type-like declarations
            case .keyword("typealias"):
                return .nestedType

            default:
                return nil
            }

        case .conditionalCompilation:
            return nil
        }
    }

    /// Updates the given declaration tokens so it ends with at least one blank like
    /// (e.g. so it ends with at least two newlines)
    func endingWithBlankLine(_ tokens: [Token]) -> [Token] {
        let parser = Formatter(tokens)

        // Determine how many trailing linebreaks there are in this declaration
        var numberOfTrailingLinebreaks = 0
        var searchIndex = parser.tokens.count - 1

        while searchIndex > 0,
              let token = parser.token(at: searchIndex),
              token.isSpaceOrCommentOrLinebreak
        {
            if token.isLinebreak {
                numberOfTrailingLinebreaks += 1
            }

            searchIndex -= 1
        }

        // Make sure there are at least two newlines,
        // so we get a blank line between individual declaration types
        while numberOfTrailingLinebreaks < 2 {
            parser.insertLinebreak(at: parser.tokens.count)
            numberOfTrailingLinebreaks += 1
        }

        return parser.tokens
    }

    /// Removes any existing category separators from the given declarations
    func removeExistingCategorySeparators(from typeBody: [Declaration]) -> [Declaration] {
        var typeBody = typeBody

        for (declarationIndex, declaration) in typeBody.enumerated() {
            let tokensToInspect: [Token]
            switch declaration {
            case let .declaration(_, tokens):
                tokensToInspect = tokens
            case let .type(_, open, _, _), let .conditionalCompilation(open, _, _):
                // Only inspect the opening tokens of declarations with a body
                tokensToInspect = open
            }

            let potentialCategorySeparators = Category.allCases.flatMap {
                Array(Set([
                    // The user's specific category separator template
                    $0.markComment(from: options.categoryMarkComment),
                    // Other common variants that we would want to replace with the correct variant
                    $0.markComment(from: "%c"),
                    $0.markComment(from: "// MARK: %c"),
                ]))
            }.compactMap { $0 }

            let parser = Formatter(tokensToInspect)

            parser.forEach(.startOfScope("//")) { commentStartIndex, _ in
                // Only look at top-level comments inside of the type body
                guard parser.currentScope(at: commentStartIndex) == nil else {
                    return
                }

                // Check if this comment matches an expected category separator comment
                for potentialSeparatorComment in potentialCategorySeparators {
                    let potentialCategorySeparator = tokenize(potentialSeparatorComment)
                    let potentialSeparatorRange = commentStartIndex ..< (commentStartIndex + potentialCategorySeparator.count)

                    guard parser.tokens.indices.contains(potentialSeparatorRange.upperBound),
                          let nextNonwhitespaceIndex = parser.index(of: .nonSpaceOrLinebreak, after: potentialSeparatorRange.upperBound)
                    else { continue }

                    // Check the edit distance of this existing comment with the potential
                    // valid category separators for this category. If they are similar or identical,
                    // we'll want to replace the existing comment with the correct comment.
                    let existingComment = sourceCode(for: Array(parser.tokens[potentialSeparatorRange]))
                    let minimumEditDistance = Int(0.2 * Float(existingComment.count))

                    guard existingComment.lowercased().editDistance(from: potentialSeparatorComment.lowercased())
                        <= minimumEditDistance
                    else { continue }

                    // Makes sure there are only whitespace or other comments before this comment.
                    // Otherwise, we don't want to remove it.
                    let tokensBeforeComment = parser.tokens[0 ..< commentStartIndex]
                    guard !tokensBeforeComment.contains(where: { !$0.isSpaceOrCommentOrLinebreak }) else {
                        continue
                    }

                    // If we found a matching comment, remove it and all subsequent empty lines
                    let startOfCommentLine = parser.startOfLine(at: commentStartIndex)
                    let startOfNextDeclaration = parser.startOfLine(at: nextNonwhitespaceIndex)
                    parser.removeTokens(in: startOfCommentLine ..< startOfNextDeclaration)

                    // Move any tokens from before the category separator into the previous declaration.
                    // This makes sure that things like comments stay grouped in the same category.
                    if declarationIndex != 0, startOfCommentLine != 0 {
                        // Remove the tokens before the category separator from this declaration...
                        let rangeBeforeComment = 0 ..< startOfCommentLine
                        let tokensBeforeCommentLine = Array(parser.tokens[rangeBeforeComment])
                        parser.removeTokens(in: rangeBeforeComment)

                        // ... and append them to the end of the previous declaration
                        typeBody[declarationIndex - 1] = mapClosingTokens(in: typeBody[declarationIndex - 1]) {
                            $0 + tokensBeforeCommentLine
                        }
                    }

                    // Apply the updated tokens back to this declaration
                    typeBody[declarationIndex] = mapOpeningTokens(in: typeBody[declarationIndex]) { _ in
                        parser.tokens
                    }
                }
            }
        }

        return typeBody
    }

    /// Organizes the flat list of declarations based on category and type
    func organizeType(
        _ typeDeclaration: (kind: String, open: [Token], body: [Declaration], close: [Token])
    ) -> (kind: String, open: [Token], body: [Declaration], close: [Token]) {
        guard options.organizeTypes.contains(typeDeclaration.kind) else {
            return typeDeclaration
        }

        // Make sure this type's body is longer than the organization threshold
        let organizationThreshold: Int
        switch typeDeclaration.kind {
        case "class", "actor":
            organizationThreshold = options.organizeClassThreshold
        case "struct":
            organizationThreshold = options.organizeStructThreshold
        case "enum":
            organizationThreshold = options.organizeEnumThreshold
        case "extension":
            organizationThreshold = options.organizeExtensionThreshold
        default:
            organizationThreshold = 0
        }

        // Count the number of lines in this declaration
        let lineCount = typeDeclaration.body
            .flatMap { $0.tokens }
            .filter { $0.isLinebreak }
            .count

        // Don't organize this type's body if it is shorter than the minimum organization threshold
        if lineCount < organizationThreshold {
            return typeDeclaration
        }

        var typeOpeningTokens = typeDeclaration.open
        let typeClosingTokens = typeDeclaration.close

        // Remove all of the existing category separators, so they can be readded
        // at the correct location after sorting the declarations.
        let bodyWithoutCategorySeparators = removeExistingCategorySeparators(from: typeDeclaration.body)

        // Categorize each of the declarations into their primary groups
        typealias CategorizedDeclarations = [(declaration: Declaration, category: Category, type: DeclarationType?)]

        let categorizedDeclarations = bodyWithoutCategorySeparators.map {
            (declaration: $0, category: category(of: $0), type: type(of: $0))
        }

        // If this type has a leading :sort directive, we sort alphabetically
        // within the subcategories (where ordering is otherwise undefined)
        let sortAlphabeticallyWithinSubcategories = typeDeclaration.open.contains(where: {
            $0.isComment && $0.string.contains("swiftformat:sort") && !$0.string.contains(":sort:")
        })

        // Sorts the given categoried declarations based on their derived metadata
        func sortDeclarations(
            _ declarations: CategorizedDeclarations,
            byCategory sortByCategory: Bool,
            byType sortByType: Bool
        ) -> CategorizedDeclarations {
            declarations.enumerated()
                .sorted(by: { lhs, rhs in
                    let (lhsOriginalIndex, lhs) = lhs
                    let (rhsOriginalIndex, rhs) = rhs

                    // Sort primarily by category
                    if sortByCategory,
                       let lhsCategorySortOrder = Formatter.categoryOrdering.firstIndex(of: lhs.category),
                       let rhsCategorySortOrder = Formatter.categoryOrdering.firstIndex(of: rhs.category),
                       lhsCategorySortOrder != rhsCategorySortOrder
                    {
                        return lhsCategorySortOrder < rhsCategorySortOrder
                    }

                    // Within individual categories (excluding .beforeMarks), sort by the declaration type
                    if sortByType,
                       lhs.category != .beforeMarks,
                       rhs.category != .beforeMarks,
                       let lhsType = lhs.type,
                       let rhsType = rhs.type,
                       let lhsTypeSortOrder = Formatter.categorySubordering.firstIndex(of: lhsType),
                       let rhsTypeSortOrder = Formatter.categorySubordering.firstIndex(of: rhsType),
                       lhsTypeSortOrder != rhsTypeSortOrder
                    {
                        return lhsTypeSortOrder < rhsTypeSortOrder
                    }

                    // If this type had a :sort directive, we sort alphabetically
                    // within the subcategories (where ordering is otherwise undefined)
                    if sortAlphabeticallyWithinSubcategories,
                       let lhsName = lhs.declaration.name,
                       let rhsName = rhs.declaration.name,
                       lhsName != rhsName
                    {
                        return lhsName.localizedCompare(rhsName) == .orderedAscending
                    }

                    // Respect the original declaration ordering when the categories and types are the same
                    return lhsOriginalIndex < rhsOriginalIndex
                })
                .map { $0.element }
        }

        // Sort the declarations based on their category and type
        var sortedDeclarations = sortDeclarations(categorizedDeclarations, byCategory: true, byType: true)

        // The compiler will synthesize a memberwise init for `struct`
        // declarations that don't have an `init` declaration.
        // We have to take care to not reorder any properties (but reordering functions etc is ok!)
        if typeDeclaration.kind == "struct",
           !typeDeclaration.body.contains(where: { $0.keyword == "init" })
        {
            // Whether or not this declaration is an instance property that can affect
            // the parameters struct's synthesized memberwise initializer
            func affectsSynthesizedMemberwiseInitializer(
                _ declaration: Declaration,
                _ type: DeclarationType?
            ) -> Bool {
                switch type {
                case .instanceProperty?:
                    return true

                case .instancePropertyWithBody?:
                    // `instancePropertyWithBody` represents some stored properties,
                    // but also computed properties. Only stored properties,
                    // not computed properties, affect the synthesized init.
                    //
                    // This is a stored property if and only if
                    // the declaration body has a `didSet` or `willSet` keyword,
                    // based on the grammar for a variable declaration:
                    // https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_variable-declaration
                    let parser = Formatter(declaration.tokens)

                    if let bodyOpenBrace = parser.index(of: .startOfScope("{"), after: -1),
                       let nextToken = parser.next(.nonSpaceOrCommentOrLinebreak, after: bodyOpenBrace),
                       [.identifier("willSet"), .identifier("didSet")].contains(nextToken)
                    {
                        return true
                    }

                    return false

                default:
                    return false
                }
            }

            // Whether or not the two given declaration orderings preserve
            // the same synthesized memberwise initializer
            func preservesSynthesizedMemberwiseInitializer(
                _ lhs: CategorizedDeclarations,
                _ rhs: CategorizedDeclarations
            ) -> Bool {
                let lhsPropertiesOrder = lhs
                    .filter { affectsSynthesizedMemberwiseInitializer($0.declaration, $0.type) }
                    .map { $0.declaration }

                let rhsPropertiesOrder = rhs
                    .filter { affectsSynthesizedMemberwiseInitializer($0.declaration, $0.type) }
                    .map { $0.declaration }

                return lhsPropertiesOrder == rhsPropertiesOrder
            }

            if !preservesSynthesizedMemberwiseInitializer(categorizedDeclarations, sortedDeclarations) {
                // If sorting by category and by type could cause compilation failures
                // by not correctly preserving the synthesized memberwise initializer,
                // try to sort _only_ by category (so we can try to preserve the correct category separators)
                sortedDeclarations = sortDeclarations(categorizedDeclarations, byCategory: true, byType: false)

                // If sorting _only_ by category still changes the synthesized memberwise initializer,
                // then there's nothing we can do to organize this struct.
                if !preservesSynthesizedMemberwiseInitializer(categorizedDeclarations, sortedDeclarations) {
                    return typeDeclaration
                }
            }
        }

        // Insert comments to separate the categories
        let numberOfCategories = Formatter.categoryOrdering.filter { category in
            sortedDeclarations.contains(where: { $0.category == category })
        }.count

        for category in Formatter.categoryOrdering {
            guard let indexOfFirstDeclaration = sortedDeclarations
                .firstIndex(where: { $0.category == category })
            else { continue }

            // Build the MARK declaration, but only when there is more than one category present.
            if options.markCategories,
               numberOfCategories > 1,
               let markComment = category.markComment(from: options.categoryMarkComment)
            {
                let firstDeclaration = sortedDeclarations[indexOfFirstDeclaration].declaration
                let declarationParser = Formatter(firstDeclaration.tokens)
                let indentation = declarationParser.indentForLine(at: 0)

                let endMarkDeclaration = options.lineAfterMarks ? "\n\n" : "\n"
                let markDeclaration = tokenize("\(indentation)\(markComment)\(endMarkDeclaration)")

                sortedDeclarations.insert(
                    (.declaration(kind: "comment", tokens: markDeclaration), category, nil),
                    at: indexOfFirstDeclaration
                )

                // If this declaration is the first declaration in the type scope,
                // make sure the type's opening sequence of tokens ends with
                // at least one blank line so the category separator appears balanced
                if indexOfFirstDeclaration == 0 {
                    typeOpeningTokens = endingWithBlankLine(typeOpeningTokens)
                }
            }

            // Insert newlines to separate declaration types
            for declarationType in Formatter.categorySubordering {
                guard let indexOfLastDeclarationWithType = sortedDeclarations
                    .lastIndex(where: { $0.category == category && $0.type == declarationType }),
                    indexOfLastDeclarationWithType != sortedDeclarations.indices.last
                else { continue }

                sortedDeclarations[indexOfLastDeclarationWithType].declaration = mapClosingTokens(
                    in: sortedDeclarations[indexOfLastDeclarationWithType].declaration)
                { endingWithBlankLine($0) }
            }
        }

        return (
            kind: typeDeclaration.kind,
            open: typeOpeningTokens,
            body: sortedDeclarations.map { $0.declaration },
            close: typeClosingTokens
        )
    }

    /// Removes the given visibility keyword from the given declaration
    func remove(_ visibilityKeyword: Visibility, from declaration: Declaration) -> Declaration {
        mapOpeningTokens(in: declaration) { openTokens in
            guard let visibilityKeywordIndex = openTokens
                .firstIndex(of: .keyword(visibilityKeyword.rawValue))
            else {
                return openTokens
            }

            let openTokensFormatter = Formatter(openTokens)
            openTokensFormatter.removeToken(at: visibilityKeywordIndex)

            while openTokensFormatter.token(at: visibilityKeywordIndex)?.isSpace == true {
                openTokensFormatter.removeToken(at: visibilityKeywordIndex)
            }

            return openTokensFormatter.tokens
        }
    }

    /// Adds the given visibility keyword to the given declaration,
    /// replacing any existing visibility keyword.
    func add(_ visibilityKeyword: Visibility, to declaration: Declaration) -> Declaration {
        var declaration = declaration

        if let existingVisibilityKeyword = visibility(of: declaration) {
            declaration = remove(existingVisibilityKeyword, from: declaration)
        }

        return mapOpeningTokens(in: declaration) { openTokens in
            guard let indexOfKeyword = openTokens
                .firstIndex(of: .keyword(declaration.keyword))
            else {
                return openTokens
            }

            let openTokensFormatter = Formatter(openTokens)
            let startOfModifiers = openTokensFormatter
                .startOfModifiers(at: indexOfKeyword, includingAttributes: false)

            openTokensFormatter.insert(
                tokenize("\(visibilityKeyword.rawValue) "),
                at: startOfModifiers
            )

            return openTokensFormatter.tokens
        }
    }
}

extension Formatter {
    // A generic type parameter for a method
    class GenericType {
        /// The name of the generic parameter. For example with `<T: Fooable>` the generic parameter `name` is `T`.
        let name: String
        /// The source range within angle brackets where the generic parameter is defined
        let definitionSourceRange: ClosedRange<Int>
        /// Conformances and constraints applied to this generic parameter
        var conformances: [GenericConformance]
        /// Whether or not this generic parameter can be removed and replaced with an opaque generic parameter
        var eligibleToRemove = true

        /// A constraint or conformance that applies to a generic type
        struct GenericConformance: Hashable {
            enum ConformanceType {
                /// A protocol constraint like `T: Fooable`
                case protocolConstraint
                /// A concrete type like `T == Foo`
                case concreteType
            }

            /// The name of the type being used in the constraint. For example with `T: Fooable`
            /// the constraint name is `Fooable`
            let name: String
            /// The name of the type being constrained. For example with `T: Fooable` the
            /// `typeName` is `T`. This can correspond exactly to the `name` of a `GenericType`,
            /// but can also be something like `T.AssociatedType` where `T` is the `name` of a `GenericType`.
            let typeName: String
            /// The type of conformance or constraint represented by this value.
            let type: ConformanceType
            /// The source range in the angle brackets or where clause where this conformance is defined.
            let sourceRange: ClosedRange<Int>
        }

        init(name: String, definitionSourceRange: ClosedRange<Int>, conformances: [GenericConformance] = []) {
            self.name = name
            self.definitionSourceRange = definitionSourceRange
            self.conformances = conformances
        }

        /// The opaque parameter syntax that represents this generic type,
        /// if the constraints can be expressed using this syntax
        func asOpaqueParameter(useSomeAny: Bool) -> [Token]? {
            // Protocols with primary associated types that can be used with
            // opaque parameter syntax. In the future we could make this extensible
            // so users can add their own types here.
            let knownProtocolsWithAssociatedTypes: [(name: String, primaryAssociatedType: String)] = [
                (name: "Collection", primaryAssociatedType: "Element"),
                (name: "Sequence", primaryAssociatedType: "Element"),
            ]

            let constraints = conformances.filter { $0.type == .protocolConstraint }
            let concreteTypes = conformances.filter { $0.type == .concreteType }

            // If we have no type requirements at all, this is an
            // unconstrained generic and is equivalent to `some Any`
            if constraints.isEmpty, concreteTypes.isEmpty {
                guard useSomeAny else { return nil }
                return tokenize("some Any")
            }

            if constraints.isEmpty {
                // If we have no constraints but exactly one concrete type (e.g. `== String`)
                // then we can just substitute for that type. This sort of generic same-type
                // requirement (`func foo<T>(_ t: T) where T == Foo`) is actually no longer
                // allowed in Swift 6, since it's redundant.
                if concreteTypes.count == 1 {
                    return tokenize(concreteTypes[0].name)
                }

                // If there are multiple same-type type requirements,
                // the code should fail to compile
                else {
                    return nil
                }
            }

            var primaryAssociatedTypes = [GenericConformance: GenericConformance]()

            // Validate that all of the conformances can be represented using this syntax
            for conformance in conformances {
                if conformance.typeName.contains(".") {
                    switch conformance.type {
                    case .protocolConstraint:
                        // Constraints like `Foo.Bar: Barable` cannot be represented using
                        // opaque generic parameter syntax
                        return nil

                    case .concreteType:
                        // Concrete type constraints like `Foo.Element == Bar` can be
                        // represented using opaque generic parameter syntax if we know
                        // that it's using a primary associated type of the base protocol
                        // (e.g. if `Foo` is a `Collection` or `Sequence`)
                        let typeElements = conformance.typeName.components(separatedBy: ".")
                        guard typeElements.count == 2 else { return nil }

                        let associatedTypeName = typeElements[1]

                        // Look up if the generic param conforms to any of the protocols
                        // with a primary associated type matching the one we found
                        let matchingProtocolWithAssociatedType = constraints.first(where: { genericConstraint in
                            let knownProtocol = knownProtocolsWithAssociatedTypes.first(where: { $0.name == genericConstraint.name })
                            return knownProtocol?.primaryAssociatedType == associatedTypeName
                        })

                        if let matchingProtocolWithAssociatedType = matchingProtocolWithAssociatedType {
                            primaryAssociatedTypes[matchingProtocolWithAssociatedType] = conformance
                        } else {
                            // If this isn't the primary associated type of a protocol constraint, then we can't use it
                            return nil
                        }
                    }
                }
            }

            let constraintRepresentations = constraints.map { constraint -> String in
                if let primaryAssociatedType = primaryAssociatedTypes[constraint] {
                    return "\(constraint.name)<\(primaryAssociatedType.name)>"
                } else {
                    return constraint.name
                }
            }

            return tokenize("some \(constraintRepresentations.joined(separator: " & "))")
        }
    }

    /// Parses generic types between the angle brackets of a function declaration, or in a where clause
    func parseGenericTypes(
        from genericSignatureStartIndex: Int,
        to genericSignatureEndIndex: Int,
        into genericTypes: inout [GenericType],
        qualifyGenericTypeName: (String) -> String = { $0 }
    ) {
        var currentIndex = genericSignatureStartIndex

        while currentIndex < genericSignatureEndIndex - 1 {
            guard let genericTypeNameIndex = index(of: .identifier, after: currentIndex),
                  genericTypeNameIndex < genericSignatureEndIndex
            else { break }

            let typeEndIndex: Int
            let nextCommaIndex = index(of: .delimiter(","), after: genericTypeNameIndex)
            if let nextCommaIndex = nextCommaIndex, nextCommaIndex < genericSignatureEndIndex {
                typeEndIndex = nextCommaIndex
            } else {
                typeEndIndex = genericSignatureEndIndex - 1
            }

            // Include all whitespace and comments in the conformance's source range,
            // so if we remove it later all of the extra whitespace will get cleaned up
            let sourceRangeEnd: Int
            if let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: typeEndIndex) {
                sourceRangeEnd = nextTokenIndex - 1
            } else {
                sourceRangeEnd = typeEndIndex
            }

            // The generic constraint could have syntax like `Foo`, `Foo: Fooable`,
            // `Foo.Element == Fooable`, etc. Create a reference to this specific
            // generic parameter (`Foo` in all of these examples) that can store
            // the constraints and conformances that we encounter later.
            let fullGenericTypeName = qualifyGenericTypeName(tokens[genericTypeNameIndex].string)
            let baseGenericTypeName = fullGenericTypeName.components(separatedBy: ".")[0]

            let genericType: GenericType
            if let existingType = genericTypes.first(where: { $0.name == baseGenericTypeName }) {
                genericType = existingType
            } else {
                genericType = GenericType(
                    name: baseGenericTypeName,
                    definitionSourceRange: genericTypeNameIndex ... sourceRangeEnd
                )
                genericTypes.append(genericType)
            }

            // Parse the constraint after the type name if present
            var delineatorIndex: Int?
            var conformanceType: GenericType.GenericConformance.ConformanceType?

            // This can either be a protocol constraint of the form `T: Fooable`
            if let colonIndex = index(of: .delimiter(":"), after: genericTypeNameIndex),
               colonIndex < typeEndIndex
            {
                delineatorIndex = colonIndex
                conformanceType = .protocolConstraint
            }

            // or a concrete type of the form `T == Foo`
            else if let equalsIndex = index(after: genericTypeNameIndex, where: { $0.isOperator("==") }),
                    equalsIndex < typeEndIndex
            {
                delineatorIndex = equalsIndex
                conformanceType = .concreteType
            }

            if let delineatorIndex = delineatorIndex, let conformanceType = conformanceType {
                let constrainedTypeName = tokens[genericTypeNameIndex ..< delineatorIndex]
                    .map { $0.string }
                    .joined()
                    .trimmingCharacters(in: .init(charactersIn: " \n\r,{}"))

                let conformanceName = tokens[(delineatorIndex + 1) ... typeEndIndex]
                    .map { $0.string }
                    .joined()
                    .trimmingCharacters(in: .init(charactersIn: " \n\r,{}"))

                genericType.conformances.append(.init(
                    name: conformanceName,
                    typeName: qualifyGenericTypeName(constrainedTypeName),
                    type: conformanceType,
                    sourceRange: genericTypeNameIndex ... sourceRangeEnd
                ))
            }

            currentIndex = typeEndIndex
        }
    }

    /// Add or remove self or Self
    func addOrRemoveSelf(static staticSelf: Bool) {
        let selfKeyword = staticSelf ? "Self" : "self"

        // Must be applied to the entire file to work reliably
        guard !options.fragment else { return }

        func processBody(at index: inout Int,
                         localNames: Set<String>,
                         members: Set<String>,
                         typeStack: inout [(name: String, keyword: String)],
                         closureStack: inout [(allowsImplicitSelf: Bool, selfCapture: String?)],
                         membersByType: inout [String: Set<String>],
                         classMembersByType: inout [String: Set<String>],
                         usingDynamicLookup: Bool,
                         classOrStatic: Bool,
                         isTypeRoot: Bool,
                         isInit: Bool)
        {
            var explicitSelf: SelfMode { staticSelf ? .remove : options.explicitSelf }
            let isWhereClause = index > 0 && tokens[index - 1] == .keyword("where")
            assert(isWhereClause || currentScope(at: index).map { token -> Bool in
                [.startOfScope("{"), .startOfScope(":"), .startOfScope("#if")].contains(token)
            } ?? true)
            let isCaseClause = !isWhereClause && index > 0 && tokens[index - 1].isSwitchCaseOrDefault
            if explicitSelf == .remove {
                // Check if scope actually includes self before we waste a bunch of time
                var scopeStack: [Token] = []
                loop: for i in index ..< tokens.count {
                    let token = tokens[i]
                    switch token {
                    case .identifier(selfKeyword):
                        break loop // Contains self
                    case .startOfScope("{") where isWhereClause && scopeStack.isEmpty:
                        return // Does not contain self
                    case .startOfScope("{"), .startOfScope("("),
                         .startOfScope("["), .startOfScope(":"):
                        scopeStack.append(token)
                    case .endOfScope("}"), .endOfScope(")"), .endOfScope("]"),
                         .endOfScope("case"), .endOfScope("default"):
                        if scopeStack.isEmpty || (scopeStack == [.startOfScope(":")] && isCaseClause) {
                            index = i + 1
                            return // Does not contain self
                        }
                        _ = scopeStack.popLast()
                    default:
                        break
                    }
                }
            }
            let inClosureDisallowingImplicitSelf = !staticSelf && closureStack.last?.allowsImplicitSelf == false
            // Starting in Swift 5.8, self can be rebound using a `let self = self` unwrap condition
            // within a weak self closure. This is the only place where defining a property
            // named self affects the behavior of implicit self.
            let scopeAllowsImplicitSelfRebinding = !staticSelf && options.swiftVersion >= "5.8"
                && closureStack.last?.selfCapture == "weak self"

            // Gather members & local variables
            let type = (isTypeRoot && typeStack.count == 1) ? typeStack.first : nil
            var members = (type?.name).flatMap { membersByType[$0] } ?? members
            var classMembers = (type?.name).flatMap { classMembersByType[$0] } ?? Set<String>()
            var localNames = localNames
            if !isTypeRoot || explicitSelf != .remove {
                var i = index
                var classOrStatic = false
                outer: while let token = token(at: i) {
                    switch token {
                    case .keyword("import"):
                        guard let nextIndex = self.index(of: .identifier, after: i) else {
                            return fatalError("Expected identifier", at: i)
                        }
                        i = nextIndex
                    case .keyword("class"), .keyword("static"):
                        classOrStatic = true
                    case .keyword("repeat"):
                        if next(.nonSpaceOrCommentOrLinebreak, after: i) == .startOfScope("{") {
                            guard let nextIndex = self.index(of: .keyword("while"), after: i) else {
                                return fatalError("Expected while", at: i)
                            }
                            i = nextIndex
                        } else {
                            // Probably a parameter pack
                            break
                        }
                    case .keyword("if"), .keyword("for"), .keyword("while"):
                        if explicitSelf == .insert {
                            break
                        }
                        guard let nextIndex = self.index(of: .startOfScope("{"), after: i) else {
                            return fatalError("Expected {", at: i)
                        }
                        i = nextIndex
                        continue
                    case .keyword("switch"):
                        guard let nextIndex = self.index(of: .startOfScope("{"), after: i) else {
                            return fatalError("Expected {", at: i)
                        }
                        guard var endIndex = self.index(of: .endOfScope, after: nextIndex) else {
                            return fatalError("Expected }", at: i)
                        }
                        while tokens[endIndex] != .endOfScope("}") {
                            guard let nextIndex = self.index(of: .startOfScope(":"), after: endIndex) else {
                                return fatalError("Expected :", at: i)
                            }
                            guard let _endIndex = self.index(of: .endOfScope, after: nextIndex) else {
                                return fatalError("Expected end of scope", at: i)
                            }
                            endIndex = _endIndex
                        }
                        i = endIndex
                    case .keyword("var"), .keyword("let"):
                        i += 1
                        if isTypeRoot {
                            if classOrStatic {
                                processDeclaredVariables(at: &i, names: &classMembers)
                                classOrStatic = false
                            } else {
                                processDeclaredVariables(at: &i, names: &members)
                            }
                        } else {
                            let removeSelf = explicitSelf != .insert && !usingDynamicLookup && (
                                (staticSelf && classOrStatic) || (!staticSelf && !inClosureDisallowingImplicitSelf)
                            )
                            processDeclaredVariables(at: &i, names: &localNames,
                                                     removeSelfKeyword: removeSelf ? selfKeyword : nil,
                                                     onlyLocal: options.swiftVersion < "5",
                                                     scopeAllowsImplicitSelfRebinding: scopeAllowsImplicitSelfRebinding)
                        }
                    case .keyword("func"):
                        guard let nameToken = next(.nonSpaceOrCommentOrLinebreak, after: i) else {
                            break
                        }
                        if isTypeRoot {
                            if classOrStatic {
                                classMembers.insert(nameToken.unescaped())
                                classOrStatic = false
                            } else {
                                members.insert(nameToken.unescaped())
                            }
                        } else {
                            localNames.insert(nameToken.unescaped())
                        }
                    case .startOfScope("("), .startOfScope("#if"), .startOfScope(":"):
                        break
                    case .startOfScope("//"), .startOfScope("/*"):
                        if case let .commentBody(comment)? = next(.nonSpace, after: i) {
                            processCommentBody(comment, at: i)
                            if token == .startOfScope("//") {
                                processLinebreak()
                            }
                        }
                        i = endOfScope(at: i) ?? (tokens.count - 1)
                    case .startOfScope:
                        classOrStatic = false
                        i = endOfScope(at: i) ?? (tokens.count - 1)
                    case .endOfScope("}"), .endOfScope("case"), .endOfScope("default"):
                        break outer
                    case .linebreak:
                        processLinebreak()
                    default:
                        break
                    }
                    i += 1
                }
            }
            if let type = type {
                membersByType[type.name] = members
                classMembersByType[type.name] = classMembers
            }
            // Remove or add `self`
            var lastKeyword = ""
            var lastKeywordIndex = 0
            var classOrStatic = classOrStatic
            var scopeStack = [(token: Token.space(""), dynamicMemberTypes: Set<String>())]

            // TODO: restructure this to use forEachToken to avoid exposing processCommentBody mechanism
            while let token = token(at: index) {
                switch token {
                case .keyword("is"), .keyword("as"), .keyword("try"), .keyword("await"):
                    break
                case .keyword("init"), .keyword("subscript"),
                     .keyword("func") where lastKeyword != "import":
                    lastKeyword = ""
                    let members = classOrStatic ? classMembers : members
                    processFunction(at: &index, localNames: localNames, members: members,
                                    typeStack: &typeStack, closureStack: &closureStack, membersByType: &membersByType,
                                    classMembersByType: &classMembersByType,
                                    usingDynamicLookup: usingDynamicLookup,
                                    classOrStatic: classOrStatic)
                    classOrStatic = false
                    continue
                case .keyword("static"):
                    if !isTypeRoot {
                        return fatalError("Unexpected static keyword", at: index)
                    }
                    classOrStatic = true
                case .keyword("class") where
                    next(.nonSpaceOrCommentOrLinebreak, after: index)?.isIdentifier == false:
                    if last(.nonSpaceOrCommentOrLinebreak, before: index) != .delimiter(":") {
                        if !isTypeRoot {
                            return fatalError("Unexpected class keyword", at: index)
                        }
                        classOrStatic = true
                    }
                case .keyword("where") where lastKeyword == "protocol", .keyword("protocol"):
                    if let startIndex = self.index(of: .startOfScope("{"), after: index),
                       let endIndex = endOfScope(at: startIndex)
                    {
                        index = endIndex
                    }
                case .keyword("extension"), .keyword("struct"), .keyword("enum"), .keyword("class"), .keyword("actor"),
                     .keyword("where") where ["extension", "struct", "enum", "class", "actor"].contains(lastKeyword):
                    let keyword = tokens[index].string
                    guard last(.nonSpaceOrCommentOrLinebreak, before: index) != .keyword("import") else {
                        break
                    }
                    guard let scopeStart = self.index(of: .startOfScope("{"), after: index),
                          case let .identifier(name)? = next(.identifier, after: index)
                    else {
                        return
                    }
                    var usingDynamicLookup = modifiersForDeclaration(
                        at: index,
                        contains: "@dynamicMemberLookup"
                    )
                    if usingDynamicLookup {
                        scopeStack[scopeStack.count - 1].dynamicMemberTypes.insert(name)
                    } else if [token.string, lastKeyword].contains("extension"),
                              scopeStack.last!.dynamicMemberTypes.contains(name)
                    {
                        usingDynamicLookup = true
                    }
                    index = scopeStart + 1
                    typeStack.append((name: name, keyword: keyword))
                    processBody(at: &index, localNames: ["init"], members: [],
                                typeStack: &typeStack, closureStack: &closureStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                                isTypeRoot: true, isInit: false)
                    index -= 1
                    typeStack.removeLast()
                case .keyword("case") where ["if", "while", "guard", "for"].contains(lastKeyword):
                    break
                case .keyword("var"), .keyword("let"):
                    lastKeywordIndex = index
                    index += 1
                    switch lastKeyword {
                    case "lazy" where options.swiftVersion < "4":
                        loop: while let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index) {
                            switch tokens[nextIndex] {
                            case .keyword("as"), .keyword("is"), .keyword("try"), .keyword("await"):
                                break
                            case .keyword, .startOfScope("{"):
                                break loop
                            default:
                                break
                            }
                            index = nextIndex
                        }
                        lastKeyword = ""
                    case "if", "while", "guard", "for":
                        assert(!isTypeRoot)
                        // Guard is included because it's an error to reference guard vars in body
                        var scopedNames = localNames
                        let removeSelf = explicitSelf != .insert && !usingDynamicLookup && (
                            (staticSelf && classOrStatic) || (!staticSelf && !inClosureDisallowingImplicitSelf)
                        )
                        processDeclaredVariables(
                            at: &index, names: &scopedNames,
                            removeSelfKeyword: removeSelf ? selfKeyword : nil,
                            onlyLocal: false,
                            scopeAllowsImplicitSelfRebinding: scopeAllowsImplicitSelfRebinding
                        )
                        while let scope = currentScope(at: index) ?? self.token(at: index),
                              case let .startOfScope(name) = scope,
                              ["[", "("].contains(name) || scope.isStringDelimiter,
                              let endIndex = endOfScope(at: index)
                        {
                            // TODO: find less hacky workaround
                            index = endIndex + 1
                        }
                        while scopeStack.last?.token == .startOfScope("(") {
                            scopeStack.removeLast()
                        }
                        guard var startIndex = self.token(at: index) == .startOfScope("{") ?
                            index : self.index(of: .startOfScope("{"), after: index)
                        else {
                            return fatalError("Expected {", at: index)
                        }
                        while isStartOfClosure(at: startIndex) {
                            guard let i = self.index(of: .endOfScope("}"), after: startIndex) else {
                                return fatalError("Expected }", at: startIndex)
                            }
                            guard let j = self.index(of: .startOfScope("{"), after: i) else {
                                return fatalError("Expected {", at: i)
                            }
                            startIndex = j
                        }
                        index = startIndex + 1
                        processBody(at: &index, localNames: scopedNames, members: members,
                                    typeStack: &typeStack, closureStack: &closureStack,
                                    membersByType: &membersByType, classMembersByType: &classMembersByType,
                                    usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                                    isTypeRoot: false, isInit: isInit)
                        index -= 1
                        lastKeyword = ""
                    default:
                        lastKeyword = token.string
                    }
                    classOrStatic = false
                case .keyword("where") where lastKeyword == "in",
                     .startOfScope("{") where lastKeyword == "in" && !isStartOfClosure(at: index):
                    lastKeyword = ""
                    var localNames = localNames
                    guard let keywordIndex = self.index(of: .keyword("in"), before: index),
                          let prevKeywordIndex = self.index(of: .keyword("for"), before: keywordIndex)
                    else {
                        return fatalError("Expected for keyword", at: index)
                    }
                    for token in tokens[prevKeywordIndex + 1 ..< keywordIndex] {
                        if case let .identifier(name) = token, name != "_" {
                            localNames.insert(token.unescaped())
                        }
                    }
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members,
                                typeStack: &typeStack, closureStack: &closureStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                                isTypeRoot: false, isInit: isInit)
                    continue
                case .keyword("while") where lastKeyword == "repeat":
                    lastKeyword = ""
                case let .keyword(name):
                    lastKeyword = name
                    lastKeywordIndex = index
                case .startOfScope("//"), .startOfScope("/*"):
                    if case let .commentBody(comment)? = next(.nonSpace, after: index) {
                        processCommentBody(comment, at: index)
                        if token == .startOfScope("//") {
                            processLinebreak()
                        }
                    }
                    index = endOfScope(at: index) ?? (tokens.count - 1)
                case .startOfScope where token.isStringDelimiter, .startOfScope("#if"),
                     .startOfScope("["), .startOfScope("("):
                    scopeStack.append((token, []))
                case .startOfScope(":"):
                    lastKeyword = ""
                case .startOfScope("{") where lastKeyword == "catch":
                    lastKeyword = ""
                    var localNames = localNames
                    localNames.insert("error") // Implicit error argument
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members,
                                typeStack: &typeStack, closureStack: &closureStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                                isTypeRoot: false, isInit: isInit)
                    continue
                case .startOfScope("{") where isWhereClause && scopeStack.count == 1:
                    return
                case .startOfScope("{") where lastKeyword == "switch":
                    lastKeyword = ""
                    index += 1
                    loop: while let token = self.token(at: index) {
                        index += 1
                        switch token {
                        case .endOfScope("case"), .endOfScope("default"):
                            let localNames = localNames
                            processBody(at: &index, localNames: localNames, members: members,
                                        typeStack: &typeStack, closureStack: &closureStack,
                                        membersByType: &membersByType, classMembersByType: &classMembersByType,
                                        usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                                        isTypeRoot: false, isInit: isInit)
                            index -= 1
                        case .endOfScope("}"):
                            break loop
                        default:
                            break
                        }
                    }
                case .startOfScope("{") where ["for", "where", "if", "else", "while", "do"].contains(lastKeyword):
                    if let scopeIndex = self.index(of: .startOfScope, before: index), scopeIndex > lastKeywordIndex {
                        index = endOfScope(at: index) ?? (tokens.count - 1)
                        break
                    }
                    lastKeyword = ""
                    fallthrough
                case .startOfScope("{") where lastKeyword == "repeat":
                    index += 1
                    processBody(at: &index, localNames: localNames, members: members,
                                typeStack: &typeStack, closureStack: &closureStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                                isTypeRoot: false, isInit: isInit)
                    continue
                case .startOfScope("{") where lastKeyword == "var":
                    lastKeyword = ""
                    if isStartOfClosure(at: index, in: scopeStack.last?.token) {
                        fallthrough
                    }
                    var prevIndex = index - 1
                    var name: String?
                    while let token = self.token(at: prevIndex), token != .keyword("var") {
                        if token.isLvalue, let nextToken = nextToken(after: prevIndex, where: {
                            !$0.isSpaceOrCommentOrLinebreak && !$0.isStartOfScope
                        }), nextToken.isRvalue, !nextToken.isOperator(".") {
                            // It's a closure
                            fallthrough
                        }
                        if case let .identifier(_name) = token {
                            // Is the declared variable
                            name = _name
                        }
                        prevIndex -= 1
                    }
                    let classOrStatic = modifiersForDeclaration(at: lastKeywordIndex, contains: { _, string in
                        ["static", "class"].contains(string)
                    })
                    if let name = name, classOrStatic || !staticSelf {
                        processAccessors(["get", "set", "willSet", "didSet"], for: name,
                                         at: &index, localNames: localNames, members: members,
                                         typeStack: &typeStack, closureStack: &closureStack,
                                         membersByType: &membersByType,
                                         classMembersByType: &classMembersByType,
                                         usingDynamicLookup: usingDynamicLookup,
                                         classOrStatic: classOrStatic)
                    } else {
                        index = (endOfScope(at: index) ?? index) + 1
                    }
                    continue
                case .startOfScope("{") where isStartOfClosure(at: index):
                    let inIndex = self.index(of: .keyword, after: index, if: {
                        $0 == .keyword("in")
                    })

                    // Parse the capture list and arguments list,
                    // and record the type of `self` capture used in the closure
                    var captureList: [Token]?
                    var parameterList: [Token]?

                    // Handle a capture list followed by an optional parameter list:
                    // `{ [self, foo] bar in` or `{ [self, foo] in` etc.
                    if let inIndex = inIndex,
                       let captureListStartIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
                       tokens[captureListStartIndex] == .startOfScope("["),
                       let captureListEndIndex = endOfScope(at: captureListStartIndex)
                    {
                        captureList = Array(tokens[(captureListStartIndex + 1) ..< captureListEndIndex])
                        parameterList = Array(tokens[(captureListEndIndex + 1) ..< inIndex])
                    }

                    // Handle a parameter list if present without a capture list
                    // e.g. `{ foo, bar in`
                    else if let inIndex = inIndex,
                            let firstTokenInClosure = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
                            isInClosureArguments(at: firstTokenInClosure)
                    {
                        parameterList = Array(tokens[firstTokenInClosure ..< inIndex])
                    }

                    var captureListEntries = (captureList ?? []).split(separator: .delimiter(","), omittingEmptySubsequences: true)
                    let parameterListEntries = (parameterList ?? []).split(separator: .delimiter(","), omittingEmptySubsequences: true)

                    let supportedSelfCaptures = Set([
                        "self",
                        "unowned self",
                        "unowned(safe) self",
                        "unowned(unsafe) self",
                        "weak self",
                    ])

                    let captureEntryStrings = captureListEntries.map { captureListEntry in
                        captureListEntry
                            .map { $0.string }
                            .joined()
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    let selfCapture = captureEntryStrings.first(where: {
                        supportedSelfCaptures.contains($0)
                    })

                    captureListEntries.removeAll(where: { captureListEntry in
                        let text = captureListEntry
                            .map { $0.string }
                            .joined()
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        return text == selfCapture
                    })

                    let localDefiningDeclarations = captureListEntries + parameterListEntries
                    var closureLocalNames = localNames

                    for tokens in localDefiningDeclarations {
                        guard let localIdentifier = tokens.first(where: {
                            $0.isIdentifier && !_FormatRules.ownershipModifiers.contains($0.string)
                        }), case let .identifier(name) = localIdentifier,
                        name != "_"
                        else {
                            continue
                        }
                        closureLocalNames.insert(name)
                    }

                    // Functions defined inside closures with `[weak self]` captures can
                    // only use implicit self once self has been unwrapped.
                    //
                    // When using `weak self` we add `self` to locals and will remove
                    // it again if we encounter a `guard let self`.
                    if options.swiftVersion >= "5.8", selfCapture == "weak self" {
                        closureLocalNames.insert("self")
                    }

                    // Whether or not the closure at the current index permits implicit self.
                    //
                    // SE-0269 (in Swift 5.3) allows implicit self when:
                    //  - the closure captures self explicitly using [self] or [unowned self]
                    //  - self is not a reference type
                    //
                    // SE-0365 (in Swift 5.8) additionally allows implicit self using
                    // [weak self] captures after self has been unwrapped.
                    func closureAllowsImplicitSelf() -> Bool {
                        guard options.swiftVersion >= "5.3" else {
                            return false
                        }

                        // If self is a reference type, capturing it won't create a retain cycle,
                        // so the compiler lets us use implicit self
                        if let enclosingTypeKeyword = typeStack.last?.keyword,
                           enclosingTypeKeyword == "struct" || enclosingTypeKeyword == "enum"
                        {
                            return true
                        }

                        guard let selfCapture = selfCapture else {
                            return false
                        }

                        // If self is captured strongly, or using `unowned`, then the compiler
                        // lets us use implicit self since it's already clear that this closure
                        // captures self strongly
                        if selfCapture == "self"
                            || selfCapture == "unowned self"
                            || selfCapture == "unowned(safe) self"
                            || selfCapture == "unowned(unsafe) self"
                        {
                            return true
                        }

                        // This is also supported for `weak self` captures, but only
                        // in Swift 5.8 or later
                        if selfCapture == "weak self", options.swiftVersion >= "5.8" {
                            return true
                        }

                        return false
                    }

                    closureStack.append((allowsImplicitSelf: closureAllowsImplicitSelf(), selfCapture: selfCapture))
                    index = (inIndex ?? index) + 1
                    processBody(at: &index, localNames: closureLocalNames, members: members,
                                typeStack: &typeStack, closureStack: &closureStack,
                                membersByType: &membersByType, classMembersByType: &classMembersByType,
                                usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                                isTypeRoot: false, isInit: isInit)
                    index -= 1
                    closureStack.removeLast()
                case .startOfScope:
                    index = endOfScope(at: index) ?? (tokens.count - 1)
                case .identifier(selfKeyword):
                    guard isEnabled, explicitSelf != .insert, !isTypeRoot, !usingDynamicLookup, !staticSelf || classOrStatic,
                          let dotIndex = self.index(of: .nonSpaceOrLinebreak, after: index, if: {
                              $0 == .operator(".", .infix)
                          }),
                          let nextIndex = self.index(of: .nonSpaceOrLinebreak, after: dotIndex)
                    else {
                        break
                    }
                    if explicitSelf == .insert {
                        break
                    } else if explicitSelf == .initOnly, isInit {
                        if next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .operator("=", .infix) {
                            break
                        } else if let scopeEnd = self.index(of: .endOfScope(")"), after: nextIndex),
                                  next(.nonSpaceOrCommentOrLinebreak, after: scopeEnd) == .operator("=", .infix)
                        {
                            break
                        }
                    }
                    if let closure = closureStack.last, !closure.allowsImplicitSelf {
                        break
                    }
                    _ = removeSelf(at: index, exclude: localNames)
                case .identifier("type"): // Special case for type(of:)
                    guard let parenIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                        $0 == .startOfScope("(")
                    }), next(.nonSpaceOrCommentOrLinebreak, after: parenIndex) == .identifier("of") else {
                        fallthrough
                    }
                case .identifier:
                    guard isEnabled && !isTypeRoot else {
                        break
                    }
                    if explicitSelf == .insert {
                        // continue
                    } else if explicitSelf == .initOnly, isInit {
                        if next(.nonSpaceOrCommentOrLinebreak, after: index) == .operator("=", .infix) {
                            // continue
                        } else if let scopeEnd = self.index(of: .endOfScope(")"), after: index),
                                  next(.nonSpaceOrCommentOrLinebreak, after: scopeEnd) == .operator("=", .infix)
                        {
                            // continue
                        } else {
                            if token.string == "lazy" {
                                lastKeyword = "lazy"
                                lastKeywordIndex = index
                            }
                            break
                        }
                    } else {
                        if token.string == "lazy" {
                            lastKeyword = "lazy"
                            lastKeywordIndex = index
                        }
                        break
                    }
                    let isAssignment: Bool
                    if ["for", "var", "let"].contains(lastKeyword),
                       let prevToken = last(.nonSpaceOrCommentOrLinebreak, before: index)
                    {
                        switch prevToken {
                        case .identifier, .number, .endOfScope,
                             .operator where ![
                                 .operator("=", .infix), .operator(".", .prefix)
                             ].contains(prevToken):
                            isAssignment = false
                            lastKeyword = ""
                        default:
                            isAssignment = true
                        }
                    } else {
                        isAssignment = false
                    }
                    if !isAssignment, token.string == "lazy" {
                        lastKeyword = "lazy"
                        lastKeywordIndex = index
                    }
                    let name = token.unescaped()
                    guard members.contains(name), !localNames.contains(name), !isAssignment ||
                        last(.nonSpaceOrCommentOrLinebreak, before: index) == .operator("=", .infix),
                        next(.nonSpaceOrComment, after: index) != .delimiter(":")
                    else {
                        break
                    }
                    if let lastToken = last(.nonSpaceOrCommentOrLinebreak, before: index),
                       lastToken.isOperator(".")
                    {
                        break
                    }
                    insert([.identifier("self"), .operator(".", .infix)], at: index)
                    index += 2
                case .endOfScope("case"), .endOfScope("default"):
                    return
                case .endOfScope:
                    if token == .endOfScope("#endif") {
                        while let scope = scopeStack.last?.token, scope != .space("") {
                            scopeStack.removeLast()
                            if scope != .startOfScope("#if") {
                                break
                            }
                        }
                    } else if let scope = scopeStack.last?.token, scope != .space("") {
                        // TODO: fix this bug
                        assert(token.isEndOfScope(scope))
                        scopeStack.removeLast()
                    } else {
                        assert(token.isEndOfScope(currentScope(at: index)!))
                        index += 1
                        return
                    }
                case .linebreak:
                    processLinebreak()
                default:
                    break
                }
                index += 1
            }
        }
        func processAccessors(_ names: [String], for name: String, at index: inout Int,
                              localNames: Set<String>, members: Set<String>,
                              typeStack: inout [(name: String, keyword: String)],
                              closureStack: inout [(allowsImplicitSelf: Bool, selfCapture: String?)],
                              membersByType: inout [String: Set<String>],
                              classMembersByType: inout [String: Set<String>],
                              usingDynamicLookup: Bool,
                              classOrStatic: Bool)
        {
            assert(tokens[index] == .startOfScope("{"))
            var foundAccessors = false
            var localNames = localNames
            while let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index, if: {
                if case let .identifier(name) = $0, names.contains(name) { return true } else { return false }
            }), let startIndex = self.index(of: .startOfScope("{"), after: nextIndex) {
                foundAccessors = true
                index = startIndex + 1
                if let parenStart = self.index(of: .nonSpaceOrCommentOrLinebreak, after: nextIndex, if: {
                    $0 == .startOfScope("(")
                }), let varToken = next(.identifier, after: parenStart) {
                    localNames.insert(varToken.unescaped())
                } else {
                    switch tokens[nextIndex].string {
                    case "get":
                        localNames.insert(name)
                    case "set":
                        localNames.insert(name)
                        localNames.insert("newValue")
                    case "willSet":
                        localNames.insert("newValue")
                    case "didSet":
                        localNames.insert("oldValue")
                    default:
                        break
                    }
                }
                processBody(at: &index, localNames: localNames, members: members,
                            typeStack: &typeStack, closureStack: &closureStack,
                            membersByType: &membersByType, classMembersByType: &classMembersByType,
                            usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                            isTypeRoot: false, isInit: false)
            }
            if foundAccessors {
                guard let endIndex = self.index(of: .endOfScope("}"), after: index) else { return }
                index = endIndex + 1
            } else {
                index += 1
                localNames.insert(name)
                processBody(at: &index, localNames: localNames, members: members,
                            typeStack: &typeStack, closureStack: &closureStack,
                            membersByType: &membersByType, classMembersByType: &classMembersByType,
                            usingDynamicLookup: usingDynamicLookup, classOrStatic: classOrStatic,
                            isTypeRoot: false, isInit: false)
            }
        }
        func processFunction(at index: inout Int, localNames: Set<String>, members: Set<String>,
                             typeStack: inout [(name: String, keyword: String)],
                             closureStack: inout [(allowsImplicitSelf: Bool, selfCapture: String?)],
                             membersByType: inout [String: Set<String>],
                             classMembersByType: inout [String: Set<String>],
                             usingDynamicLookup: Bool,
                             classOrStatic: Bool)
        {
            let startToken = tokens[index]
            var localNames = localNames
            guard let startIndex = self.index(of: .startOfScope("("), after: index),
                  let endIndex = self.index(of: .endOfScope(")"), after: startIndex)
            else {
                index += 1 // Prevent endless loop
                return
            }
            // Get argument names
            index = startIndex
            while index < endIndex {
                guard let externalNameIndex = self.index(of: .identifier, after: index),
                      let nextIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, after: externalNameIndex)
                else { break }
                let token = tokens[nextIndex]
                switch token {
                case let .identifier(name) where name != "_":
                    localNames.insert(token.unescaped())
                case .delimiter(":"):
                    let externalNameToken = tokens[externalNameIndex]
                    if case let .identifier(name) = externalNameToken, name != "_" {
                        localNames.insert(externalNameToken.unescaped())
                    }
                default:
                    break
                }
                index = self.index(of: .delimiter(","), after: index) ?? endIndex
            }
            guard let bodyStartIndex = self.index(after: endIndex, where: {
                switch $0 {
                case .startOfScope("{"): // What we're looking for
                    return true
                case .keyword("throws"),
                     .keyword("rethrows"),
                     .keyword("where"),
                     .keyword("is"):
                    return false // Keep looking
                case .keyword where !$0.isAttribute:
                    return true // Not valid between end of arguments and start of body
                default:
                    return false // Keep looking
                }
            }), tokens[bodyStartIndex] == .startOfScope("{") else {
                return
            }

            // Functions defined inside closures with `[weak self]` captures can
            // never use implicit self.
            //
            // When we encounter a `guard let self` in a `[weak self]` closure,
            // we remove `self` from the list of locals since that disables
            // implicit self. Now that we're moving into a function that doesn't
            // support implicit self, we can re-insert `self` into the list of
            // locals to disable implicit self again for this scope.
            if options.swiftVersion >= "5.8",
               closureStack.last?.selfCapture == "weak self"
            {
                localNames.insert("self")
            }

            if startToken == .keyword("subscript") {
                index = bodyStartIndex
                processAccessors(["get", "set"], for: "", at: &index, localNames: localNames,
                                 members: members, typeStack: &typeStack, closureStack: &closureStack, membersByType: &membersByType,
                                 classMembersByType: &classMembersByType,
                                 usingDynamicLookup: usingDynamicLookup,
                                 classOrStatic: classOrStatic)
            } else {
                index = bodyStartIndex + 1
                processBody(at: &index,
                            localNames: localNames,
                            members: members,
                            typeStack: &typeStack,
                            closureStack: &closureStack,
                            membersByType: &membersByType,
                            classMembersByType: &classMembersByType,
                            usingDynamicLookup: usingDynamicLookup,
                            classOrStatic: classOrStatic,
                            isTypeRoot: false,
                            isInit: startToken == .keyword("init"))
            }
        }
        var typeStack = [(name: String, keyword: String)]()
        var closureStack = [(allowsImplicitSelf: Bool, selfCapture: String?)]()
        var membersByType = [String: Set<String>]()
        var classMembersByType = [String: Set<String>]()
        var index = 0
        processBody(at: &index, localNames: [], members: [], typeStack: &typeStack,
                    closureStack: &closureStack, membersByType: &membersByType,
                    classMembersByType: &classMembersByType,
                    usingDynamicLookup: false, classOrStatic: false,
                    isTypeRoot: false, isInit: false)
    }
}
