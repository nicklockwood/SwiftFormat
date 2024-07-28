//
//  noExplicitOwnership.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    static let noExplicitOwnership = FormatRule(
        help: "Don't use explicit ownership modifiers (borrowing / consuming).",
        disabledByDefault: true
    ) { formatter in
        formatter.forEachToken { keywordIndex, token in
            guard [.identifier("borrowing"), .identifier("consuming")].contains(token),
                  let nextTokenIndex = formatter.index(of: .nonSpaceOrLinebreak, after: keywordIndex)
            else { return }

            // Use of `borrowing` and `consuming` as ownership modifiers
            // immediately precede a valid type, or the `func` keyword.
            // You could also simply use these names as a property,
            // like `let borrowing = foo` or `func myFunc(borrowing foo: Foo)`.
            // As a simple heuristic to detect the difference, attempt to parse the
            // following tokens as a type, and require that it doesn't start with lower-case letter.
            let isValidOwnershipModifier: Bool
            if formatter.tokens[nextTokenIndex] == .keyword("func") {
                isValidOwnershipModifier = true
            }

            else if let type = formatter.parseType(at: nextTokenIndex),
                    type.name.first?.isLowercase == false
            {
                isValidOwnershipModifier = true
            }

            else {
                isValidOwnershipModifier = false
            }

            if isValidOwnershipModifier {
                formatter.removeTokens(in: keywordIndex ..< nextTokenIndex)
            }
        }
    }
}
