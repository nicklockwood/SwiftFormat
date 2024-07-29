//
//  docCommentsBeforeAttributes.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let docCommentsBeforeAttributes = FormatRule(
        help: "Place doc comments on declarations before any attributes.",
        orderAfter: [.docComments]
    ) { formatter in
        formatter.forEachToken(where: \.isDeclarationTypeKeyword) { keywordIndex, _ in
            // Parse the attributes on this declaration if present
            let startOfAttributes = formatter.startOfModifiers(at: keywordIndex, includingAttributes: true)
            guard formatter.tokens[startOfAttributes].isAttribute else { return }

            let attributes = formatter.attributes(startingAt: startOfAttributes)
            guard !attributes.isEmpty else { return }

            let attributesRange = attributes.first!.startIndex ... attributes.last!.endIndex

            // If there's a doc comment between the attributes and the rest of the declaration,
            // move it above the attributes.
            guard let linebreakAfterAttributes = formatter.index(of: .linebreak, after: attributesRange.upperBound),
                  let indexAfterAttributes = formatter.index(of: .nonSpaceOrLinebreak, after: linebreakAfterAttributes),
                  indexAfterAttributes < keywordIndex,
                  let restOfDeclaration = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: attributesRange.upperBound),
                  formatter.isDocComment(startOfComment: indexAfterAttributes)
            else { return }

            let commentRange = indexAfterAttributes ..< restOfDeclaration
            let comment = formatter.tokens[commentRange]

            formatter.removeTokens(in: commentRange)
            formatter.insert(comment, at: startOfAttributes)
        }
    }
}
