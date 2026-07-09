//
//  RedundantOptionalBinding.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 8/1/22.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantOptionalBinding = FormatRule(
        help: "Remove redundant identifiers in optional binding conditions.",
        // We can convert `if let foo = self.foo` to just `if let foo`,
        // but only if `redundantSelf` can first remove the `self.`.
        orderAfter: [.redundantSelf],
        options: ["redundant-optional-binding"]
    ) { formatter in
        formatter.forEachToken { i, token in
            // `if let foo` conditions were added in Swift 5.7 (SE-0345)
            guard formatter.options.swiftVersion >= "5.7",
                  [.keyword("let"), .keyword("var")].contains(token),
                  formatter.isConditionalStatement(at: i),

                  let identifierIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                  case let .identifier(bindingName) = formatter.tokens[identifierIndex],

                  let equalsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: identifierIndex, if: {
                      $0 == .operator("=", .infix)
                  }),

                  let rhsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
                  case let .identifier(rhsName) = formatter.tokens[rhsIndex],

                  let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: rhsIndex),
                  [.startOfScope("{"), .delimiter(","), .keyword("else")].contains(nextToken)
            else { return }

            if bindingName == rhsName {
                // `if let foo = foo` → `if let foo`
                formatter.removeTokens(in: identifierIndex + 1 ... rhsIndex)
            } else if formatter.options.redundantOptionalBinding == .always, !rhsName.hasPrefix("$") {
                // `if let foo = bar` → `if let bar` when the names don't conflict
                // (skip when rhs is a closure shorthand parameter like `$0`,
                // since `if let $0` is invalid Swift)
                formatter.tryConvertDifferentNameBinding(
                    bindingName: bindingName,
                    rhsName: rhsName,
                    identifierIndex: identifierIndex,
                    rhsIndex: rhsIndex,
                    ifLetKeywordIndex: i
                )
            }
        }
    } examples: {
        """
        ```diff
        - if let foo = foo {
        + if let foo {
              print(foo)
          }

        - guard let self = self else {
        + guard let self else {
              return
          }
        ```

        ```diff
          // With --redundant-optional-binding always (default)
        - if let f = foo {
        -     print(f)
        + if let foo {
        +     print(foo)
          }
        ```
        """
    }
}

extension Formatter {
    /// Attempts to convert `if let foo = bar` to `if let bar`, renaming `foo` → `bar`
    /// in subsequent conditions and the body. For `guard`, also renames in the continuation
    /// after the `}`, but only when the guard is a direct child of a function or var body —
    /// otherwise the binding's scope is hard to determine correctly (e.g. inside switch cases,
    /// the continuation can extend past sibling declarations).
    /// Skips the transformation if `rhsName` already appears in the rename range, since
    /// the new binding would shadow it.
    func tryConvertDifferentNameBinding(
        bindingName: String,
        rhsName: String,
        identifierIndex: Int,
        rhsIndex: Int,
        ifLetKeywordIndex: Int
    ) {
        guard let startOfConditional = startOfConditionalStatement(at: ifLetKeywordIndex),
              let startBrace = index(of: .startOfScope("{"), after: ifLetKeywordIndex),
              let endBrace = endOfScope(at: startBrace)
        else { return }

        var renameRanges: [Range<Int>] = []

        if tokens[startOfConditional] == .keyword("guard") {
            guard let enclosingScopeStart = index(of: .startOfScope("{"), before: startOfConditional),
                  isFunctionOrComputedPropertyBody(at: enclosingScopeStart),
                  let enclosingScopeEnd = endOfScope(at: enclosingScopeStart)
            else { return }

            // Subsequent conditions: from after the rhs to the `else` keyword
            if let elseIndex = index(of: .keyword("else"), after: rhsIndex), elseIndex < startBrace {
                renameRanges.append((rhsIndex + 1) ..< elseIndex)
            }

            // Else body: must not contain `bindingName` (we can't rename uses we don't own there)
            let elseBodyRange = (startBrace + 1) ..< endBrace
            guard !containsIdentifier(bindingName, in: elseBodyRange) else { return }

            // Continuation: from after the guard's `}` to the end of the enclosing function/var body
            renameRanges.append((endBrace + 1) ..< enclosingScopeEnd)
        } else {
            // For if/while: subsequent conditions + body
            renameRanges.append((rhsIndex + 1) ..< endBrace)
        }

        // Skip if `rhsName` is referenced in any rename range. After renaming, the new binding
        // shadows the outer `rhsName`, so any reference to the outer variable would silently
        // become a reference to the binding instead — a semantic change.
        for range in renameRanges {
            if containsIdentifier(rhsName, in: range) {
                return
            }
        }

        for range in renameRanges {
            renameIdentifier(bindingName, to: rhsName, in: range)
        }

        // Replace `bindingName = rhsName` with just `rhsName`
        replaceToken(at: identifierIndex, with: .identifier(rhsName))
        removeTokens(in: identifierIndex + 1 ... rhsIndex)
    }

    /// Returns true if the `{` at `idx` is the body of a function (`func`, `init`, `subscript`,
    /// `deinit`) or a computed property (`var name: Type { ... }`).
    func isFunctionOrComputedPropertyBody(at idx: Int) -> Bool {
        guard tokens[idx] == .startOfScope("{"), !isStartOfClosure(at: idx) else { return false }
        guard let keywordIndex = indexOfLastSignificantKeyword(at: idx, excluding: ["where"]) else {
            return false
        }
        switch tokens[keywordIndex].string {
        case "func", "init", "subscript", "deinit", "var":
            return true
        default:
            return false
        }
    }

    /// Returns true if `name` appears as a value reference (not a member access or argument label)
    /// anywhere in the given range.
    func containsIdentifier(_ name: String, in range: Range<Int>) -> Bool {
        range.contains(where: { isValueReference(name, at: $0) })
    }

    /// Renames all value references to `name` (excluding member accesses and argument labels)
    /// to `newName` within the given range.
    func renameIdentifier(_ name: String, to newName: String, in range: Range<Int>) {
        for idx in stride(from: range.upperBound - 1, through: range.lowerBound, by: -1) {
            if isValueReference(name, at: idx) {
                replaceToken(at: idx, with: .identifier(newName))
            }
        }
    }

    /// Returns true if the token at `idx` is identifier `name` used as a value reference,
    /// i.e., not a member access (`.name`) and not a function call argument label (`name:`).
    func isValueReference(_ name: String, at idx: Int) -> Bool {
        guard tokens[idx] == .identifier(name) else { return false }
        // Exclude member accesses: `foo.name` (infix dot) and `.name` implicit member (prefix dot).
        if let prev = index(of: .nonSpaceOrCommentOrLinebreak, before: idx),
           case let .operator(".", _) = tokens[prev]
        {
            return false
        }
        // Exclude function call argument labels (e.g. `foo(name: value)`)
        if isArgumentPosition(at: idx) {
            return false
        }
        return true
    }
}
