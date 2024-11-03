//
//  DocCommentsBeforeModifiers.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/22/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let docCommentsBeforeModifiers = FormatRule(
        help: "Place doc comments before any declaration modifiers or attributes.",
        orderAfter: [.docComments]
    ) { formatter in
        formatter.forEachToken(where: \.isDeclarationTypeKeyword) { keywordIndex, _ in
            let startOfModifiers = formatter.startOfModifiers(at: keywordIndex, includingAttributes: true)
            guard startOfModifiers < keywordIndex else { return }

            var insertionPoint = startOfModifiers
            var startIndex = startOfModifiers
            while let index = formatter.index(of: .startOfScope, in: startIndex ..< keywordIndex),
                  var endIndex = formatter.endOfScope(at: index)
            {
                if formatter.isDocComment(startOfComment: index) {
                    // Extend range to include trailing white space
                    while formatter.token(at: endIndex + 1)?.isSpaceOrLinebreak ?? false {
                        endIndex += 1
                    }
                    let commentRange = index ... endIndex
                    formatter.moveTokens(in: commentRange, to: insertionPoint)
                    insertionPoint += commentRange.count
                }
                startIndex = endIndex + 1
            }
        }
    } examples: {
        """
        ```diff
        + /// Doc comment on this function declaration
          @MainActor
        - /// Doc comment on this function declaration
          func foo() {}
        ```
        """
    }
}
