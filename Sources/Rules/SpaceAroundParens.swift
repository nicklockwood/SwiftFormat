//
//  SpaceAroundParens.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Implement the following rules with respect to the spacing around parens:
    /// * There is no space between an opening paren and the preceding identifier,
    ///   unless the identifier is one of the specified keywords
    /// * There is no space between an opening paren and the preceding closing brace
    /// * There is no space between an opening paren and the preceding closing square bracket
    /// * There is space between a closing paren and following identifier
    /// * There is space between a closing paren and following opening brace
    /// * There is no space between a closing paren and following opening square bracket
    static let spaceAroundParens = FormatRule(
        help: "Add or remove space around parentheses."
    ) { formatter in
        formatter.forEach(.startOfScope("(")) { i, _ in
            let i = i - 1
            switch formatter.token(at: i) {
            case _ where formatter.shouldInsertSpaceAfterToken(at: i) == true:
                formatter.insertSpace(" ", at: i + 1)
            case .space where formatter.shouldInsertSpaceAfterToken(at: i - 1) == false:
                formatter.removeToken(at: i)
            default:
                break
            }
        }
        formatter.forEach(.endOfScope(")")) { i, _ in
            let i = i + 1
            switch formatter.token(at: i) {
            case .identifier, .keyword, .startOfScope("{"):
                formatter.insertSpace(" ", at: i)
            case .space where formatter.token(at: i + 1) == .startOfScope("["):
                formatter.removeToken(at: i)
            default:
                break
            }
        }
    } examples: {
        """
        ```diff
        - init (foo)
        + init(foo)
        ```

        ```diff
        - switch(x){
        + switch (x) {
        ```
        """
    }
}

extension Formatter {
    func shouldInsertSpaceAfterToken(at index: Int) -> Bool? {
        switch token(at: index) {
        case let .keyword(keywordOrAttribute):
            switch keywordOrAttribute {
            case "@autoclosure":
                if options.swiftVersion < "3",
                   let nextIndex = self.index(of: .nonSpaceOrLinebreak, after: index),
                   next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .identifier("escaping")
                {
                    assert(tokens[nextIndex] == .startOfScope("("))
                    return false
                }
                return true
            case "@escaping", "@noescape", "@Sendable":
                return true
            case _ where keywordOrAttribute.isAttribute:
                if let i = self.index(of: .startOfScope("("), after: index) {
                    return isParameterList(at: i)
                }
                return false
            case "private", "fileprivate", "internal", "init", "subscript", "throws":
                return false
            case "await":
                return options.swiftVersion >= "5.5" || options.swiftVersion == .undefined
            default:
                return !keywordOrAttribute.isMacroOrAttribute
            }
        case let .identifier(name):
            return name.isKeywordInTypeContext && isTypePosition(at: index)
        case .endOfScope("]"):
            return isInClosureArguments(at: index)
        case .endOfScope(")"):
            return isAttribute(at: index)
        case .number, .endOfScope("}"), .endOfScope(">"):
            return false
        default:
            return nil
        }
    }
}
