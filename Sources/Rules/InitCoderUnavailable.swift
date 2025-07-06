//
//  InitCoderUnavailable.swift
//  SwiftFormat
//
//  Created by Facundo Menzella on 8/20/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Add @available(*, unavailable) to init?(coder aDecoder: NSCoder)
    static let initCoderUnavailable = FormatRule(
        help: """
        Add `@available(*, unavailable)` attribute to required `init(coder:)` when
        it hasn't been implemented.
        """,
        options: ["init-coder-nil"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        let unavailableTokens = tokenize("@available(*, unavailable)")
        formatter.forEach(.identifier("required")) { i, _ in
            // look for required init?(coder
            guard var initIndex = formatter.index(of: .keyword("init"), after: i) else { return }
            if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: initIndex, if: {
                $0 == .operator("?", .postfix)
            }) {
                initIndex = nextIndex
            }

            guard let parenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: initIndex, if: {
                $0 == .startOfScope("(")
            }), let coderIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: parenIndex, if: {
                $0 == .identifier("coder")
            }), let endParenIndex = formatter.index(of: .endOfScope(")"), after: coderIndex),
            let braceIndex = formatter.index(of: .startOfScope("{"), after: endParenIndex)
            else { return }

            // make sure the implementation is empty or fatalError
            guard let firstTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: braceIndex, if: {
                [.endOfScope("}"), .identifier("fatalError")].contains($0)
            }) else { return }

            if formatter.options.initCoderNil,
               formatter.token(at: firstTokenIndex) == .identifier("fatalError"),
               let fatalParenEndOfScope = formatter.index(of: .endOfScope, after: firstTokenIndex + 1)
            {
                formatter.replaceTokens(in: firstTokenIndex ... fatalParenEndOfScope, with: [.identifier("nil")])
            }

            // avoid adding attribute if it's already there
            if formatter.modifiersForDeclaration(at: i, contains: "@available") { return }

            let startIndex = formatter.startOfModifiers(at: i, includingAttributes: true)
            formatter.insert(.space(formatter.currentIndentForLine(at: startIndex)), at: startIndex)
            formatter.insertLinebreak(at: startIndex)
            formatter.insert(unavailableTokens, at: startIndex)
        }
    } examples: {
        """
        ```diff
        + @available(*, unavailable)
          required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        ```
        """
    }
}
