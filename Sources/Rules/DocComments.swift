//
//  DocComments.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 10/19/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let docComments = FormatRule(
        help: "Use doc comments for API declarations, otherwise use regular comments.",
        orderAfter: [.fileHeader],
        options: ["doc-comments"]
    ) { formatter in
        formatter.forEach(.startOfScope) { index, token in
            guard [.startOfScope("//"), .startOfScope("/*")].contains(token),
                  let endOfComment = formatter.endOfScope(at: index)
            else { return }

            var commentIndices = [index]

            // Check if this is a trailing comment (has non-space tokens before it on the same line)
            let isTrailingComment: Bool
            if let previousToken = formatter.index(of: .nonSpaceOrLinebreak, before: index) {
                let commentLine = formatter.startOfLine(at: index)
                let previousTokenLine = formatter.startOfLine(at: previousToken)
                isTrailingComment = (commentLine == previousTokenLine)
            } else {
                isTrailingComment = false
            }

            // Only group comments if this is not a trailing comment
            if token == .startOfScope("//"), !isTrailingComment {
                var i = index
                while let prevLineIndex = formatter.index(of: .linebreak, before: i),
                      case let lineStartIndex = formatter.startOfLine(at: prevLineIndex, excludingIndent: true),
                      formatter.token(at: lineStartIndex) == .startOfScope("//")
                {
                    commentIndices.append(lineStartIndex)
                    i = lineStartIndex
                }
                i = index
                while let nextLineIndex = formatter.index(of: .linebreak, after: i),
                      let lineStartIndex = formatter.index(of: .nonSpace, after: nextLineIndex),
                      formatter.token(at: lineStartIndex) == .startOfScope("//")
                {
                    commentIndices.append(lineStartIndex)
                    i = lineStartIndex
                }
            }

            guard let useDocComment = formatter.shouldBeDocComment(at: commentIndices, endOfComment: endOfComment) else {
                return
            }

            // Determine whether or not this comment is a group-header rather than a doc comment.
            // Group-headers precede a consecutive block of declarations (no blank lines between them),
            // or are themselves continuous with a preceding group-header comment.
            // In these cases it's not obvious whether or not the comment refers to the property or
            // the entire group, so we preserve the existing formatting.
            var preserveRegularComments = false
            if useDocComment {
                preserveRegularComments = formatter.isPreservedByConsecutiveDeclarations(after: endOfComment) ||
                    formatter.isPrecededByContinuousPreservedCommentGroup(before: commentIndices.min()!)
            }

            // Doc comment tokens like `///` and `/**` aren't parsed as a
            // single `.startOfScope` token -- they're parsed as:
            // `.startOfScope("//"), .commentBody("/ ...")` or
            // `.startOfScope("/*"), .commentBody("* ...")`
            let startOfDocCommentBody: String
            switch token.string {
            case "//":
                startOfDocCommentBody = "/"
            case "/*":
                startOfDocCommentBody = "*"
            default:
                return
            }

            let isDocComment = formatter.isDocComment(startOfComment: index)

            if let commentBody = formatter.token(at: index + 1),
               commentBody.isCommentBody
            {
                if useDocComment, !isDocComment, !preserveRegularComments {
                    let updatedCommentBody = "\(startOfDocCommentBody)\(commentBody.string)"
                    formatter.replaceToken(at: index + 1, with: .commentBody(updatedCommentBody))
                } else if !useDocComment || isTrailingComment, isDocComment, formatter.options.docComments != .preserve {
                    let prefix = commentBody.string.prefix(while: { String($0) == startOfDocCommentBody })

                    // Do nothing if this is a unusual comment like `//////////////////`
                    // or `/****************`. We can't just remove one of the tokens, because
                    // that would make this rule have a different output each time, but we
                    // shouldn't remove all of them since that would be unexpected.
                    if prefix.count > 1 {
                        return
                    }

                    formatter.replaceToken(
                        at: index + 1,
                        with: .commentBody(String(commentBody.string.dropFirst()))
                    )
                }

            } else if useDocComment, !preserveRegularComments {
                formatter.insert(.commentBody(startOfDocCommentBody), at: index + 1)
            }
        }
    } examples: {
        """
        ```diff
        - // A placeholder type used to demonstrate syntax rules
        + /// A placeholder type used to demonstrate syntax rules
          class Foo {
        -     // This function doesn't really do anything
        +     /// This function doesn't really do anything
              func bar() {
        -         /// TODO: implement Foo.bar() algorithm
        +         // TODO: implement Foo.bar() algorithm
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// Whether or not the comment at this index can be a doc comment,
    /// considering the following type declaration and surrounding context.
    func shouldBeDocComment(
        at indices: [Int],
        endOfComment: Int
    ) -> Bool? {
        guard let startIndex = indices.min(),
              let nextDeclarationIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfComment)
        else { return false }

        // Check if this is a directive like MARK or swiftformat:disable etc.
        // In that case just preserve the comment as-is.
        for index in indices {
            if case let .commentBody(body)? = next(.nonSpace, after: index), body.isCommentDirective {
                return nil
            }
        }

        // Check if this token defines a declaration that supports doc comments
        var declarationToken = tokens[nextDeclarationIndex]
        if declarationToken.isAttribute || isModifier(at: nextDeclarationIndex),
           let index = index(after: nextDeclarationIndex, where: { $0.isDeclarationTypeKeyword })
        {
            declarationToken = tokens[index]
        }
        guard declarationToken.isDeclarationTypeKeyword(excluding: ["import"]) else {
            return false
        }

        // For local declarations, use standard comments.
        // In before-non-local-declarations mode, all local declarations use regular comments.
        // In before-declarations mode, only local non-func declarations use regular comments.
        if declarationScope(at: startIndex) == .local {
            if options.docComments == .beforeNonLocalDeclarations || declarationToken != .keyword("func") {
                return false
            }
        }

        // If there are blank lines between comment and declaration, comment is not treated as doc comment
        let trailingTokens = tokens[(endOfComment - 1) ... nextDeclarationIndex]
        let lines = trailingTokens.split(omittingEmptySubsequences: false, whereSeparator: \.isLinebreak)
        if lines.contains(where: { $0.allSatisfy(\.isSpace) }) {
            return false
        }

        // Only comments at the start of a line can be doc comments
        if let previousToken = index(of: .nonSpaceOrLinebreak, before: startIndex) {
            let commentLine = startOfLine(at: startIndex)
            let previousTokenLine = startOfLine(at: previousToken)

            if commentLine == previousTokenLine {
                return false
            }
        }

        // Comments inside conditional statements are not doc comments
        return !isConditionalStatement(at: startIndex)
    }

    /// Returns true if the declaration block immediately following `endOfComment` is consecutive
    /// (no blank lines between successive declarations), which indicates the comment is a group
    /// header rather than a doc comment for a specific declaration.
    func isPreservedByConsecutiveDeclarations(after endOfComment: Int) -> Bool {
        guard let declarationKeyword = index(after: endOfComment, where: \.isDeclarationTypeKeyword),
              let endOfDeclaration = _endOfDeclarationInTypeBody(atDeclarationKeyword: declarationKeyword),
              let nextDeclarationKeyword = index(after: endOfDeclaration, where: \.isDeclarationTypeKeyword)
        else { return false }

        let linebreaks = tokens[declarationKeyword ... nextDeclarationKeyword].filter(\.isLinebreak).count
        return linebreaks == 1
    }

    /// Returns true if the comment at `commentStart` is continuous (no blank lines) with a preceding
    /// `//` comment at the same indentation that is itself preserved as a regular comment — either
    /// because it precedes consecutive declarations, or because it is itself preceded by such a comment.
    func isPrecededByContinuousPreservedCommentGroup(before commentStart: Int) -> Bool {
        let currentIndent = currentIndentForLine(at: commentStart)
        var lineStart = startOfLine(at: commentStart)

        // Scan backward line by line, stopping at blank lines, until we find a // comment
        // at the same indentation level.
        while lineStart > 0 {
            guard let prevLinebreak = index(of: .linebreak, before: lineStart) else { break }
            let prevLineStart = startOfLine(at: prevLinebreak)

            // Stop at blank lines — the block is no longer continuous.
            guard index(of: .nonSpace, in: prevLineStart ..< prevLinebreak) != nil else { break }

            let prevLineContent = startOfLine(at: prevLinebreak, excludingIndent: true)

            if tokens[prevLineContent] == .startOfScope("//"),
               currentIndentForLine(at: prevLinebreak) == currentIndent
            {
                // Found a // comment at the same indentation. It is preserved if either it has
                // consecutive declarations following it, or it is itself preceded by a preserved
                // comment group (supporting chains of multiple groups).
                guard let prevCommentEnd = endOfScope(at: prevLineContent) else { break }
                return isPreservedByConsecutiveDeclarations(after: prevCommentEnd) ||
                    isPrecededByContinuousPreservedCommentGroup(before: prevLineContent)
            }

            lineStart = prevLineStart
        }

        return false
    }
}
