//
//  NoExplicitOwnership.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 8/27/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let noExplicitOwnership = FormatRule(
        help: "Don't use explicit ownership modifiers (borrowing / consuming).",
        disabledByDefault: true
    ) { formatter in
        // Ownership modifiers can't be removed from noncopyable types
        let noncopyableTypeNames = formatter.noncopyableTypeNames()
        func isNoncopyableType(named name: String?) -> Bool {
            guard let name else { return false }
            if noncopyableTypeNames.contains(name) {
                return true
            }
            guard let fileURL = formatter.currentFileURL else { return false }
            return formatter.projectIndex(requiring: [.declarations])?.isNoncopyableType(
                named: name,
                visibleFrom: fileURL
            ) ?? false
        }

        formatter.forEachToken { keywordIndex, token in
            guard [.identifier("borrowing"), .identifier("consuming")].contains(token),
                  let nextTokenIndex = formatter.index(of: .nonSpaceOrLinebreak, after: keywordIndex)
            else { return }

            // `consuming(...)` and `.consuming` are a declaration, a call or a member named `consuming`,
            // like `case consuming(Int)` or `.consuming(value)`, rather than an ownership modifier
            if formatter.token(at: keywordIndex + 1) == .startOfScope("(")
                || formatter.last(.nonSpaceOrCommentOrLinebreak, before: keywordIndex)?.isOperator(".") == true
            {
                return
            }

            // Use of `borrowing` and `consuming` as ownership modifiers
            // immediately precede a valid type, or the `func` keyword.
            // You could also simply use these names as a property,
            // like `let borrowing = foo` or `func myFunc(borrowing foo: Foo)`.
            // As a simple heuristic to detect the difference, attempt to parse the
            // following tokens as a type, and require that it doesn't start with lower-case letter.
            let isValidOwnershipModifier: Bool
            if formatter.tokens[nextTokenIndex] == .keyword("func") {
                // A `consuming` method of a noncopyable type can consume or mutate `self`
                if token == .identifier("consuming"),
                   let type = formatter.parseEnclosingType(containing: keywordIndex),
                   formatter.containsCopyableSuppression(in: type.keywordIndex ..< type.openBraceIndex)
                   || isNoncopyableType(named: type.name?.unqualifiedTypeName)
                {
                    return
                }
                isValidOwnershipModifier = true
            }

            else if let type = formatter.parseType(at: nextTokenIndex),
                    type.string.first?.isLowercase == false
            {
                // A parameter of a noncopyable type must specify its ownership
                if isNoncopyableType(named: type.nominalTypeName) {
                    return
                }
                isValidOwnershipModifier = true
            }

            else {
                isValidOwnershipModifier = false
            }

            if isValidOwnershipModifier {
                formatter.removeTokens(in: keywordIndex ..< nextTokenIndex)
            }
        }
    } examples: {
        """
        ```diff
        - borrowing func foo(_ bar: consuming Bar) { ... }
        + func foo(_ bar: Bar) { ... }
        ```
        """
    }
}

extension Formatter {
    /// The names of the types and generic parameters in this file that suppress `Copyable`,
    /// e.g. `Foo` in `struct Foo: Sendable, ~Copyable` or `T` in `<T: ~Copyable>` and `where T: ~Copyable`.
    func noncopyableTypeNames() -> Set<String> {
        var names = Set<String>()
        forEach(.operator("~", .prefix)) { i, _ in
            guard isCopyableSuppression(at: i),
                  let previousToken = last(.nonSpaceOrCommentOrLinebreak, before: i),
                  [.delimiter(":"), .delimiter(","), .operator("&", .infix)].contains(previousToken),
                  let colonIndex = index(of: .delimiter(":"), before: i),
                  var nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: colonIndex)
            else { return }

            // Skip over the generic parameters in `struct Foo<T>: ~Copyable`
            if tokens[nameIndex] == .endOfScope(">"),
               let startOfGenericParameters = index(of: .startOfScope("<"), before: nameIndex),
               let typeNameIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: startOfGenericParameters)
            {
                nameIndex = typeNameIndex
            }

            if tokens[nameIndex].isIdentifier {
                names.insert(tokens[nameIndex].string)
            }
        }
        return names
    }

    /// Whether the given range contains a `~Copyable` suppression,
    /// e.g. the declaration of `struct Foo: ~Copyable` or `extension Foo where Self: ~Copyable`
    func containsCopyableSuppression(in range: Range<Int>) -> Bool {
        range.contains { isCopyableSuppression(at: $0) }
    }

    /// Whether the token at the given index is the `~` of a `~Copyable` suppression
    func isCopyableSuppression(at index: Int) -> Bool {
        tokens[index] == .operator("~", .prefix)
            && next(.nonSpaceOrCommentOrLinebreak, after: index) == .identifier("Copyable")
    }
}

extension TypeName {
    /// The unqualified name of the nominal type, e.g. `Bar` for `Foo.Bar<Baz>?`
    var nominalTypeName: String? {
        guard tokens.first?.isIdentifier == true else { return nil }
        return tokens.prefix { $0 != .startOfScope("<") }.last(where: \.isIdentifier)?.string
    }
}
