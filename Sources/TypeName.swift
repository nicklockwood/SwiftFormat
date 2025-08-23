//
//  TypeName.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 8/22/25.
//  Copyright © 2025 Nick Lockwood. All rights reserved.
//

// MARK: - TypeName

/// A Swift type parsed by the `formatter.parseType(at:)` parsing helper
struct TypeName {
    var range: AutoUpdatingRange
    let formatter: Formatter

    init(range: ClosedRange<Int>, formatter: Formatter) {
        self.range = AutoUpdatingRange(range: range, formatter: formatter)
        self.formatter = formatter
    }

    /// The string representation of this type, excluding linebreaks or comments
    var string: String {
        formatter.tokens[range].stringExcludingLinebreaksAndComments
    }

    var tokens: ArraySlice<Token> {
        formatter.tokens[range]
    }
}

extension TypeName: Equatable {
    static func == (lhs: TypeName, rhs: TypeName) -> Bool {
        lhs.tokens == rhs.tokens
    }
}

extension TypeName: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        /* Type at \(range) */
        \(tokens.string)
        """
    }
}

// MARK: Helpers

extension TypeName {
    /// Whether or not this type is a tuple.
    var isTuple: Bool {
        // Tuple types start and end with parens and have a comma-separated list of elements.
        // (There are no single-element tuples).
        guard let openParen = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound - 1),
              formatter.tokens[openParen] == .startOfScope("("),
              let closingParen = formatter.endOfScope(at: openParen),
              openParen + 1 != closingParen
        else { return false }

        // The tuple could be optional, but otherwise the closing paren should be the last token.
        if let tokenAfterClosingParen = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: closingParen) {
            guard tokenAfterClosingParen > range.upperBound || formatter.tokens[tokenAfterClosingParen] == .operator("?", .postfix) else {
                return false
            }
        }

        let hasCommaInParens = formatter.index(of: .delimiter(","), in: (openParen + 1) ..< closingParen) != nil
        return hasCommaInParens
    }

    /// Whether or not this type is an array.
    var isArray: Bool {
        guard let openBrace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound - 1),
              formatter.tokens[openBrace] == .startOfScope("["),
              let closingBrace = formatter.endOfScope(at: openBrace),
              openBrace + 1 != closingBrace
        else { return false }

        // [:] would be a dictionary, not an array
        let hasColonInBraces = formatter.index(of: .delimiter(":"), in: (openBrace + 1) ..< closingBrace) != nil
        return !hasColonInBraces
    }

    /// Whether or not this type is an array.
    var isDictionary: Bool {
        guard let openBrace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound - 1),
              formatter.tokens[openBrace] == .startOfScope("["),
              let closingBrace = formatter.endOfScope(at: openBrace),
              openBrace + 1 != closingBrace
        else { return false }

        // [] would be a dictionary, not an array
        let hasColonInBraces = formatter.index(of: .delimiter(":"), in: (openBrace + 1) ..< closingBrace) != nil
        return hasColonInBraces
    }

    /// Whether or not this type is a closure
    var isClosure: Bool {
        formatter.isStartOfClosureType(at: range.lowerBound)
    }

    /// If this type is wrapped in redundant parens, returns the inner type.
    func withoutParens() -> TypeName {
        /// If this type is a tuple, then the parens aren't redundant
        if isTuple { return self }

        guard formatter.tokens[range.lowerBound] == .startOfScope("("),
              formatter.tokens[range.upperBound] == .endOfScope(")"),
              let tokenAfterFirst = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound),
              let tokenBeforeLast = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound),
              tokenAfterFirst <= tokenBeforeLast
        else { return self }

        let newType = TypeName(range: tokenAfterFirst ... tokenBeforeLast, formatter: formatter)
        return newType.withoutParens()
    }
}
