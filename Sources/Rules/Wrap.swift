//
//  Wrap.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/17/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrap = FormatRule(
        help: "Wrap lines that exceed the specified maximum width.",
        options: ["maxwidth", "nowrapoperators", "assetliterals", "wrapternary"],
        sharedOptions: ["wraparguments", "wrapparameters", "wrapcollections", "closingparen", "callsiteparen", "indent",
                        "trimwhitespace", "linebreaks", "tabwidth", "maxwidth", "smarttabs", "wrapreturntype",
                        "wrapconditions", "wraptypealiases", "wrapternary", "wrapeffects", "conditionswrap"]
    ) { formatter in
        let maxWidth = formatter.options.maxWidth
        guard maxWidth > 0 else { return }

        // Wrap collections first to avoid conflict
        formatter.wrapCollectionsAndArguments(completePartialWrapping: false,
                                              wrapSingleArguments: false)

        // Wrap other line types
        var currentIndex = 0
        var indent = ""
        var alreadyLinewrapped = false

        func isLinewrapToken(_ token: Token?) -> Bool {
            switch token {
            case .delimiter?, .operator(_, .infix)?:
                return true
            default:
                return false
            }
        }

        formatter.forEachToken(onlyWhereEnabled: false) { i, token in
            if i < currentIndex {
                return
            }
            if token.isLinebreak {
                indent = formatter.currentIndentForLine(at: i + 1)
                alreadyLinewrapped = isLinewrapToken(formatter.last(.nonSpaceOrComment, before: i))
                currentIndex = i + 1
            } else if let breakPoint = formatter.indexWhereLineShouldWrapInLine(at: i) {
                if !alreadyLinewrapped {
                    indent += formatter.linewrapIndent(at: breakPoint)
                }
                alreadyLinewrapped = true
                if formatter.isEnabled {
                    let spaceAdded = formatter.insertSpace(indent, at: breakPoint + 1)
                    formatter.insertLinebreak(at: breakPoint + 1)
                    currentIndex = breakPoint + spaceAdded + 2
                } else {
                    currentIndex = breakPoint + 1
                }
            } else {
                currentIndex = formatter.endOfLine(at: i)
            }
        }

        formatter.wrapCollectionsAndArguments(completePartialWrapping: true,
                                              wrapSingleArguments: true)
    } examples: {
        nil
    }
}
