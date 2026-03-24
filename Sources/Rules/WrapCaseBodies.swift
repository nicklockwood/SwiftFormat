//
//  WrapCaseBodies.swift
//  SwiftFormat
//
//  Created by Kim de Vos on 3/23/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapCaseBodies = FormatRule(
        help: "Wrap the bodies of inline switch cases onto a new line.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEach(.endOfScope("case")) { i, _ in
            formatter.wrapCaseBody(at: i)
        }
        formatter.forEach(.endOfScope("default")) { i, _ in
            formatter.wrapCaseBody(at: i)
        }
    } examples: {
        """
        ```diff
        - case .foo: return bar
        + case .foo:
        +     return bar
        ```
        """
    }
}

extension Formatter {
    func wrapCaseBody(at caseIndex: Int) {
        guard let colonIndex = index(of: .startOfScope(":"), after: caseIndex),
              var firstTokenIndex = index(of: .nonSpaceOrComment, after: colonIndex),
              !tokens[firstTokenIndex].isLinebreak,
              !tokens[firstTokenIndex].isEndOfScope
        else { return }

        insertLinebreak(at: firstTokenIndex)

        if tokens[firstTokenIndex - 1].isSpace {
            removeToken(at: firstTokenIndex - 1)
            firstTokenIndex -= 1
        }

        let movedTokenIndex = firstTokenIndex + 1
        let indent = currentIndentForLine(at: caseIndex) + options.indent
        insertSpace(indent, at: movedTokenIndex)
    }
}
