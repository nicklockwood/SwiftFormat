//
//  RedundantStateInit.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 2026-06-04.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Removes redundant explicit initialization of SwiftUI property wrapper storage,
    /// e.g. `_foo = State(wrappedValue: x)` in favor of `foo = x`.
    static let redundantStateInit = FormatRule(
        help: "Remove explicit initialization of SwiftUI property wrapper storage that can be assigned directly."
    ) { formatter in
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard let typeDeclaration = declaration.asTypeDeclaration else { return }

            // The property wrappers whose backing storage can instead be assigned directly.
            // `@StateObject` is intentionally excluded: its wrapped value can't be assigned
            // directly, so `_bar = StateObject(wrappedValue:)` is required.
            let directlyAssignableProperties = formatter.directlyAssignablePropertyWrapperNames(in: typeDeclaration.body)
            guard !directlyAssignableProperties.isEmpty else { return }

            for initDeclaration in typeDeclaration.body where initDeclaration.keyword == "init" {
                guard let bodyRange = formatter.parseFunctionDeclaration(keywordIndex: initDeclaration.keywordIndex)?.bodyRange
                else { continue }

                // Process the top-level assignments in the init body from back to front so that
                // the indices of earlier statements remain valid as we rewrite later ones.
                var searchEnd = bodyRange.upperBound
                while let assignmentIndex = formatter.lastIndex(in: (bodyRange.lowerBound + 1) ..< searchEnd, where: {
                    $0.isOperator("=", .infix)
                }) {
                    // The left-hand side must be a bare `_property` identifier at the start of a statement.
                    guard let lhsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: assignmentIndex),
                          case let .identifier(lhsName) = formatter.tokens[lhsIndex],
                          lhsName.hasPrefix("_"), lhsName.count > 1,
                          let beforeLhsIndex = formatter.index(of: .nonSpaceOrComment, before: lhsIndex),
                          formatter.tokens[beforeLhsIndex].isLinebreak
                          || formatter.tokens[beforeLhsIndex] == .startOfScope("{")
                          || formatter.tokens[beforeLhsIndex] == .delimiter(";"),
                          directlyAssignableProperties.contains(String(lhsName.dropFirst())),
                          let rhsStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: assignmentIndex)
                    else {
                        searchEnd = assignmentIndex
                        continue
                    }

                    // The right-hand side must be either an implicit `.init(...)` or an explicit
                    // `State(...)` / `ObservedObject(...)` (optionally module-qualified or generic) call.
                    var openParenIndex: Int?
                    if formatter.tokens[rhsStartIndex].isOperator(".") {
                        if let initIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: rhsStartIndex, if: { $0 == .identifier("init") }) {
                            openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: initIndex, if: { $0 == .startOfScope("(") })
                        }
                    } else if let type = formatter.parseType(at: rhsStartIndex),
                              let baseName = type.string.components(separatedBy: ".").last?.components(separatedBy: "<").first,
                              baseName == "State" || baseName == "ObservedObject"
                    {
                        openParenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: type.range.upperBound, if: { $0 == .startOfScope("(") })
                    }

                    guard let openParenIndex,
                          let closeParenIndex = formatter.endOfScope(at: openParenIndex)
                    else {
                        searchEnd = assignmentIndex
                        continue
                    }

                    // The call must have exactly one argument labeled `initialValue:` or `wrappedValue:`.
                    let arguments = formatter.parseFunctionCallArguments(startOfScope: openParenIndex)
                    guard let argument = arguments.first, arguments.count == 1,
                          argument.label == "initialValue" || argument.label == "wrappedValue"
                    else {
                        searchEnd = assignmentIndex
                        continue
                    }

                    // Replace the wrapper initialization with the wrapped value, and insert an explicit
                    // `self.` so the assignment refers to the property rather than an argument or local
                    // that shadows its name (e.g. `init(foo:) { _foo = ... }`). The `redundantSelf` rule
                    // runs afterwards and removes the `self.` where unnecessary.
                    formatter.replaceTokens(in: rhsStartIndex ... closeParenIndex, with: Array(formatter.tokens[argument.valueRange]))
                    formatter.replaceToken(at: lhsIndex, with: [
                        .identifier("self"), .operator(".", .infix), .identifier(String(lhsName.dropFirst())),
                    ])

                    searchEnd = lhsIndex
                }
            }
        }
    } examples: {
        """
        ```diff
          struct ContentView: View {
              @State private var foo: String
              @ObservedObject private var bar: MyObservableObject

              init() {
        -         _foo = State(wrappedValue: "foo")
        +         foo = "foo"
        -         _bar = .init(wrappedValue: MyObservableObject())
        +         bar = MyObservableObject()
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// The names of properties in the given declarations using a property wrapper whose
    /// backing storage can be assigned directly (`@State` or `@ObservedObject`).
    /// Recurses into conditional compilation blocks but not into nested types.
    func directlyAssignablePropertyWrapperNames(in declarations: [Declaration]) -> Set<String> {
        var names = Set<String>()
        for member in declarations {
            // Don't look at properties of nested types
            if member.asTypeDeclaration != nil {
                continue
            }

            // Recurse into conditional compilation blocks (`#if ... #endif`)
            if let body = member.body {
                names.formUnion(directlyAssignablePropertyWrapperNames(in: body))
                continue
            }

            guard member.keyword == "var" || member.keyword == "let",
                  let property = member.parsePropertyDeclaration(),
                  member.attributes.contains("@State") || member.attributes.contains("@ObservedObject"),
                  // A direct assignment (`self.foo = x`) has no effect when the property has a default value,
                  // whereas the backing-storage form (`_foo = .init(initialValue: x)`) does override it.
                  property.value == nil
            else { continue }

            names.insert(property.identifier)
        }
        return names
    }
}
