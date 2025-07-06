//
//  ModifierOrder.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 7/28/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Standardise the order of property modifiers
    static let modifierOrder = FormatRule(
        help: "Use consistent ordering for member modifiers.",
        options: ["modifier-order"]
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
            for modifier in formatter.preferredModifierOrder {
                if let tokens = modifiers[modifier] {
                    sortedModifiers += tokens
                }
            }
            formatter.replaceTokens(in: lastIndex ..< i, with: sortedModifiers)
        }
    } examples: {
        """
        ```diff
        - lazy public weak private(set) var foo: UIView?
        + public private(set) lazy weak var foo: UIView?
        ```

        ```diff
        - final public override func foo()
        + override public final func foo()
        ```

        ```diff
        - convenience private init()
        + private convenience init()
        ```

        **NOTE:** If the `--modifier-order` option isn't set, the default order will be:
        `\(_FormatRules.defaultModifierOrder.flatMap { $0 }.joined(separator: "`, `"))`
        """
    }
}

extension Formatter {
    /// Swift modifier keywords, in preferred order
    var preferredModifierOrder: [String] {
        var priorities = [String: Int]()
        for (i, modifiers) in _FormatRules.defaultModifierOrder.enumerated() {
            for modifier in modifiers {
                priorities[modifier] = i
            }
        }
        var order = options.modifierOrder.flatMap { _FormatRules.mapModifiers($0) ?? [] }
        for (i, modifiers) in _FormatRules.defaultModifierOrder.enumerated() {
            let insertionPoint = order.firstIndex(where: { modifiers.contains($0) }) ??
                order.firstIndex(where: { (priorities[$0] ?? 0) > i }) ?? order.count
            order.insert(contentsOf: modifiers.filter { !order.contains($0) }, at: insertionPoint)
        }
        return order
    }
}
