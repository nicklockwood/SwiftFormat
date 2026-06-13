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

            // Determine whether or not this is the start of a list of sequential declarations, like:
            //
            //   // The placeholder names we use in test cases
            //   case foo
            //   case bar
            //   case baaz
            //
            // In these cases it's not obvious whether or not the comment refers to the property or
            // the entire group, so we preserve the existing formatting.
            var preserveRegularComments = false
            if useDocComment,
               let declarationKeyword = formatter.index(after: endOfComment, where: \.isDeclarationTypeKeyword),
               let endOfDeclaration = formatter._endOfDeclarationInTypeBody(atDeclarationKeyword: declarationKeyword),
               let nextDeclarationKeyword = formatter.index(
                   after: endOfDeclaration,
                   where: \.isDeclarationTypeKeyword
               )
            {
                let linebreaksBetweenDeclarations = formatter.tokens[declarationKeyword ... nextDeclarationKeyword]
                    .filter(\.isLinebreak).count

                // If there is only a single line break between the start of this declaration and the subsequent declaration,
                // then they are written sequentially in a block. In this case, don't convert regular comments to doc comments.
                if linebreaksBetweenDeclarations == 1 {
                    preserveRegularComments = true
                }
            }

            // Also preserve regular comments when this comment is continuous (no blank lines) with
            // a preceding block whose comment is itself a regular comment. This handles cases like:
            //
            //   // Group of cases (preserved, since consecutive cases follow)
            //   case foo
            //   case bar
            //   // Another group (should also be preserved: continuous with prior preserved comment)
            //   case baz, qux
            //
            if !preserveRegularComments, useDocComment {
                preserveRegularComments = formatter.hasPrecedingRegularCommentBlock(before: commentIndices.min()!)
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

    /// Checks whether the comment starting at the given index is immediately preceded
    /// (with no blank lines in between) by a block of declarations that is itself
    /// preceded by a regular (non-doc) comment. This is used to preserve consistent
    /// comment style across consecutive declaration groups.
    internal func hasPrecedingRegularCommentBlock(before index: Int) -> Bool {
        // Track nesting depth for `{`, `(`, and `[` scopes so we don't accidentally
        // look inside nested bodies (function bodies, closures, etc.).
        var depth = 0
        var i = index - 1
        while i >= 0 {
            let token = tokens[i]
            if token == .endOfScope("}") || token == .endOfScope(")") || token == .endOfScope("]") {
                depth += 1
            } else if token == .startOfScope("{") || token == .startOfScope("(") || token == .startOfScope("[") {
                if depth > 0 {
                    depth -= 1
                } else {
                    // We've stepped outside the enclosing scope — stop searching.
                    return false
                }
            } else if depth == 0 {
                if token.isLinebreak {
                    // A blank line separates this comment from any preceding regular comment.
                    if let prevNonSpace = self.index(of: .nonSpace, before: i),
                       tokens[prevNonSpace].isLinebreak
                    {
                        return false
                    }
                } else if token == .startOfScope("//") || token == .startOfScope("/*") {
                    return !isDocComment(startOfComment: i)
                }
            }
            i -= 1
        }
        return false
    }
}
