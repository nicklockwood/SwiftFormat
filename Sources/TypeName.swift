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
    let range: ClosedRange<Int>
    private let formatter: Formatter

    init(range: ClosedRange<Int>, formatter: Formatter) {
        self.range = range
        self.formatter = formatter
    }

    /// The string representation of this type, excluding linebreaks or comments
    var string: String {
        tokens.stringExcludingLinebreaksAndComments
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

        return formatter.index(of: .delimiter(","), in: (openParen + 1) ..< closingParen) != nil
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

    /// Whether or not this type is a dictionary.
    var isDictionary: Bool {
        guard let openBrace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound - 1),
              formatter.tokens[openBrace] == .startOfScope("["),
              let closingBrace = formatter.endOfScope(at: openBrace),
              openBrace + 1 != closingBrace
        else { return false }

        // [] would be an array, not a dictionary
        return formatter.index(of: .delimiter(":"), in: (openBrace + 1) ..< closingBrace) != nil
    }

    /// Whether or not this type is a generic type with the given name.
    func isGenericType(named typeName: String) -> Bool {
        guard let firstToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: range.lowerBound - 1),
              formatter.tokens[firstToken] == .identifier(typeName),
              let openAngleBrace = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: firstToken),
              formatter.tokens[openAngleBrace] == .startOfScope("<"),
              let closingAngleBrace = formatter.endOfScope(at: openAngleBrace),
              openAngleBrace + 1 != closingAngleBrace
        else { return false }

        return true
    }

    /// Whether or not this type is a set.
    var isSet: Bool {
        isGenericType(named: "Set")
    }

    /// Whether or not this type is a closure
    var isClosure: Bool {
        formatter.isStartOfClosureType(at: range.lowerBound)
    }

    /// If this type is wrapped in redundant parens, returns the inner type.
    func withoutParens() -> TypeName {
        // If this type is a tuple, then the parens aren't redundant
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

    /// Whether this type has a top-level optional suffix (`?` or `!`) applied to it.
    var isOptionalType: Bool {
        guard hasTopLevelUnwrapOperator else { return false }
        return !containsTopLevelFunctionArrow
    }

    private var hasTopLevelUnwrapOperator: Bool {
        guard var index = formatter
            .index(of: .nonSpaceOrCommentOrLinebreak, before: range.upperBound + 1),
            formatter.tokens[index].isUnwrapOperator
        else { return false }

        repeat {
            index -= 1
        } while index >= range.lowerBound && formatter.tokens[index].isUnwrapOperator

        return true
    }

    private var containsTopLevelFunctionArrow: Bool {
        formatter.index(of: .operator("->", .infix),
                        in: range.lowerBound ..< range.upperBound + 1) != nil
    }
}
