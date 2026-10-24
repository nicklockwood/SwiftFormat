//
//  InitStyle.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 23/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Controls constructor spelling when the surrounding context supplies its type.
    static let initStyle = FormatRule(
        help: "Use named constructors or contextual `.init()` calls.",
        orderAfter: [.redundantType, .propertyTypes, .redundantStaticMemberType, .redundantReturn],
        options: ["explicit-types", "init-type-min-length"]
    ) { formatter in
        formatter.formatContextualInitializers()
    } examples: {
        """
        ```diff
          // --explicit-types auto
          func makeView() -> CustomView {
        -     CustomView()
        +     .init()
          }

          // --explicit-types always
          func makeView() -> CustomView {
        -     .init()
        +     CustomView()
          }
        ```

        By default, `auto` shortens constructors in explicit return-type contexts. `inferred` uses type
        info where available, including from other files and modules. Unresolved or ambiguous types are preserved.
        `--init-type-min-length` sets the minimum type name length for shortening to `.init` (defaults to 5).
        """
    }
}

extension Formatter {
    func formatContextualInitializers() {
        var functionNames = Set<String>()
        forEach(.keyword("func")) { i, _ in
            if let name = parseFunctionDeclaration(keywordIndex: i)?.name {
                functionNames.insert(name)
            }
        }
        forEachContextualType(policy: options.explicitTypes, includingInitializers: true, includingShorthand: true) { i, expectedType in
            guard !functionNames.contains(tokens[i].string),
                  !functionNames.contains(expectedType) else { return }
            formatContextualInitializer(at: i, expectedType: expectedType)
        }
    }

    func formatContextualInitializer(at start: Int, expectedType: String) {
        let typeTokens = tokenize(expectedType).filter { !$0.isSpaceOrLinebreak }
        // Optional promotion, generics and existential types need compiler type checking.
        guard !typeTokens.isEmpty,
              typeTokens.allSatisfy({ $0.isIdentifier || $0.isOperator(".") }),
              !typeTokens.contains(.identifier("Self")),
              let expression = parseExpressionRange(startingAt: start)
        else { return }

        if tokens[start].isOperator(".", .prefix) {
            guard options.explicitTypes == .always,
                  let member = index(of: .nonSpace, after: start), tokens[member] == .identifier("init"),
                  let open = index(of: .nonSpace, after: member), tokens[open] == .startOfScope("("),
                  endOfScope(at: open) == expression.upperBound
            else { return }
            replaceTokens(in: start ... member, with: typeTokens)
        } else {
            guard shouldOmitTypeQualifier(typeTokens.string, isInitializer: true)
            else { return }
            var cursor = start
            for token in typeTokens {
                guard tokens[cursor] == token,
                      let next = index(of: .nonSpace, after: cursor)
                else { return }
                cursor = next
            }
            // Only rewrite complete constructor calls, not a receiver within a larger expression.
            guard tokens[cursor] == .startOfScope("("), endOfScope(at: cursor) == expression.upperBound else {
                return
            }
            replaceTokens(in: start ..< cursor, with: [.operator(".", .prefix), .identifier("init")])
        }
    }
}
