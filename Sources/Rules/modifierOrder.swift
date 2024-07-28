//
//  modifierOrder.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Standardise the order of property modifiers
    static let modifierOrder = FormatRule(
        help: "Use consistent ordering for member modifiers.",
        options: ["modifierorder"]
    ) { formatter in
        formatter.forEach(.keyword) { i, token in
            switch token.string {
            case "let", "func", "var", "class", "actor", "extension", "init", "enum",
                 "struct", "typealias", "subscript", "associatedtype", "protocol":
                break
            default:
                return
            }
            var modifiers = [String: [Token]]()
            var lastModifier: (name: String, tokens: [Token])?
            func pushModifier() {
                lastModifier.map { modifiers[$0.name] = $0.tokens }
            }
            var lastIndex = i
            var previousIndex = lastIndex
            loop: while let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: lastIndex) {
                switch formatter.tokens[index] {
                case .operator(_, .prefix), .operator(_, .infix), .keyword("case"):
                    // Last modifier was invalid
                    lastModifier = nil
                    lastIndex = previousIndex
                    break loop
                case let token where token.isModifierKeyword:
                    pushModifier()
                    lastModifier = (token.string, [Token](formatter.tokens[index ..< lastIndex]))
                    previousIndex = lastIndex
                    lastIndex = index
                case .endOfScope(")"):
                    if case let .identifier(param)? = formatter.last(.nonSpaceOrCommentOrLinebreak, before: index),
                       let openParenIndex = formatter.index(of: .startOfScope("("), before: index),
                       let index = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: openParenIndex),
                       let token = formatter.token(at: index), token.isModifierKeyword
                    {
                        pushModifier()
                        let modifier = token.string + (param == "set" ? "(set)" : "")
                        lastModifier = (modifier, [Token](formatter.tokens[index ..< lastIndex]))
                        previousIndex = lastIndex
                        lastIndex = index
                    } else {
                        break loop
                    }
                default:
                    // Not a modifier
                    break loop
                }
            }
            pushModifier()
            guard !modifiers.isEmpty else { return }
            var sortedModifiers = [Token]()
            for modifier in formatter.modifierOrder {
                if let tokens = modifiers[modifier] {
                    sortedModifiers += tokens
                }
            }
            formatter.replaceTokens(in: lastIndex ..< i, with: sortedModifiers)
        }
    }
}
