//
//  redundantInit.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Strip redundant `.init` from type instantiations
    static let redundantInit = FormatRule(
        help: "Remove explicit `init` if not required.",
        orderAfter: ["propertyType"]
    ) { formatter in
        formatter.forEach(.identifier("init")) { initIndex, _ in
            guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: initIndex, if: {
                $0.isOperator(".")
            }), let openParenIndex = formatter.index(of: .nonSpaceOrLinebreak, after: initIndex, if: {
                $0 == .startOfScope("(")
            }), let closeParenIndex = formatter.index(of: .endOfScope(")"), after: openParenIndex),
            formatter.last(.nonSpaceOrCommentOrLinebreak, before: closeParenIndex) != .delimiter(":"),
            let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: dotIndex),
            let prevToken = formatter.token(at: prevIndex),
            formatter.isValidEndOfType(at: prevIndex),
            // Find and parse the type that comes before the .init call
            let startOfTypeIndex = Array(0 ..< dotIndex).reversed().last(where: { typeIndex in
                guard let type = formatter.parseType(at: typeIndex) else { return false }
                return (formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.upperBound) == dotIndex
                    // Since `Foo.init` is potentially a valid type, the `.init` may be parsed as part of the type name
                    || type.range.upperBound == initIndex)
                    // If this is actually a method call like `type(of: foo).init()`, the token before the "type"
                    // (which in this case looks like a tuple) will be an identifier.
                    && !(formatter.last(.nonSpaceOrComment, before: typeIndex)?.isIdentifier ?? false)
            }),
            let type = formatter.parseType(at: startOfTypeIndex),
            // Filter out values that start with a lowercase letter.
            // This covers edge cases like `super.init()`, where the `init` is not redundant.
            let firstChar = type.name.components(separatedBy: ".").last?.first,
            firstChar != "$",
            String(firstChar).uppercased() == String(firstChar)
            else { return }

            let lineStart = formatter.startOfLine(at: prevIndex, excludingIndent: true)
            if [.startOfScope("#if"), .keyword("#elseif")].contains(formatter.tokens[lineStart]) {
                return
            }
            var j = dotIndex
            while let prevIndex = formatter.index(
                of: prevToken, before: j
            ) ?? formatter.index(
                of: .startOfScope, before: j
            ) {
                j = prevIndex
                if prevToken == formatter.tokens[prevIndex],
                   let prevPrevToken = formatter.last(
                       .nonSpaceOrCommentOrLinebreak, before: prevIndex
                   ), [.keyword("let"), .keyword("var")].contains(prevPrevToken)
                {
                    return
                }
            }
            formatter.removeTokens(in: initIndex + 1 ..< openParenIndex)
            formatter.removeTokens(in: dotIndex ... initIndex)
        }
    }
}
