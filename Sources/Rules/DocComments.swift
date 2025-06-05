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
        disabledByDefault: true,
        orderAfter: [.fileHeader],
        options: ["doccomments"]
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

            let useDocComment = formatter.shouldBeDocComment(at: commentIndices, endOfComment: endOfComment)

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
                } else if !useDocComment || isTrailingComment, isDocComment, !formatter.options.preserveDocComments {
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
    ) -> Bool {
        guard let startIndex = indices.min(),
              let nextDeclarationIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: endOfComment)
        else { return false }

        // Check if this is a special type of comment that isn't documentation
        for index in indices {
            if case let .commentBody(body)? = next(.nonSpace, after: index), body.isCommentDirective {
                return false
            }
        }

        // Check if this token defines a declaration that supports doc comments
        var declarationToken = tokens[nextDeclarationIndex]
        if declarationToken.isAttribute || declarationToken.isModifierKeyword,
           let index = index(after: nextDeclarationIndex, where: { $0.isDeclarationTypeKeyword })
        {
            declarationToken = tokens[index]
        }
        guard declarationToken.isDeclarationTypeKeyword(excluding: ["import"]) else {
            return false
        }

        // Only use doc comments on declarations in type bodies, or top-level declarations
        if let startOfEnclosingScope = index(of: .startOfScope, before: startIndex) {
            switch tokens[startOfEnclosingScope] {
            case .startOfScope("#if"):
                break
            case .startOfScope("{"):
                guard let scope = lastSignificantKeyword(at: startOfEnclosingScope, excluding: ["where"]),
                      ["class", "actor", "struct", "enum", "protocol", "extension"].contains(scope)
                else {
                    return false
                }
            default:
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
}
