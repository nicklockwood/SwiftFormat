//
//  EnumNamespaces.swift
//  SwiftFormat
//
//  Created by Facundo Menzella on 9/20/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Converts types used for hosting only static members into enums to avoid instantiation.
    static let enumNamespaces = FormatRule(
        help: """
        Convert types used for hosting only static members into enums (an empty enum is
        the canonical way to create a namespace in Swift as it can't be instantiated).
        """,
        options: ["enum-namespaces"]
    ) { formatter in
        formatter.forEachToken(where: { [.keyword("class"), .keyword("struct")].contains($0) }) { i, token in
            if token == .keyword("class") {
                guard let next = formatter.next(.nonSpaceOrCommentOrLinebreak, after: i),
                      // exit if structs only
                      formatter.options.enumNamespaces != .structsOnly,
                      // exit if class is a type modifier
                      !(next.isKeywordOrAttribute || next.isModifierKeyword),
                      // exit for class as protocol conformance
                      formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .delimiter(":"),
                      // exit if not closed for extension
                      formatter.modifiersForDeclaration(at: i, contains: "final")
                else {
                    return
                }
            }
            guard let braceIndex = formatter.index(of: .startOfScope("{"), after: i),
                  // exit if import statement
                  formatter.last(.nonSpaceOrCommentOrLinebreak, before: i) != .keyword("import"),
                  // exit if has attribute(s)
                  !formatter.modifiersForDeclaration(at: i, contains: { $1.hasPrefix("@") }),
                  // exit if type is conforming any other types
                  !formatter.tokens[i ... braceIndex].contains(.delimiter(":")),
                  let endIndex = formatter.index(of: .endOfScope("}"), after: braceIndex),
                  case let .identifier(name)? = formatter.next(.identifier, after: i + 1)
            else {
                return
            }
            let range = braceIndex + 1 ..< endIndex
            if formatter.rangeHostsOnlyStaticMembersAtTopLevel(range),
               !formatter.rangeContainsTypeInit(name, in: range), !formatter.rangeContainsSelfAssignment(range)
            {
                formatter.replaceToken(at: i, with: .keyword("enum"))

                if let finalIndex = formatter.indexOfModifier("final", forDeclarationAt: i),
                   let nextIndex = formatter.index(of: .nonSpace, after: finalIndex)
                {
                    formatter.removeTokens(in: finalIndex ..< nextIndex)
                }
            }
        }
    } examples: {
        """
        ```diff
        - class FeatureConstants {
        + enum FeatureConstants {
              static let foo = "foo"
              static let bar = "bar"
          }
        ```
        """
    }
}

extension Formatter {
    func rangeHostsOnlyStaticMembersAtTopLevel(_ range: Range<Int>) -> Bool {
        // exit for empty declarations
        guard next(.nonSpaceOrCommentOrLinebreak, in: range) != nil else {
            return false
        }

        var j = range.startIndex
        while j < range.endIndex, let token = token(at: j) {
            if token == .startOfScope("{"),
               let skip = index(of: .endOfScope("}"), after: j)
            {
                j = skip
                continue
            }
            // exit if there's a explicit init
            if token == .keyword("init") {
                return false
            } else if [.keyword("let"),
                       .keyword("var"),
                       .keyword("func")].contains(token),
                !modifiersForDeclaration(at: j, contains: "static")
            {
                return false
            }
            j += 1
        }
        return true
    }

    func rangeContainsTypeInit(_ type: String, in range: Range<Int>) -> Bool {
        for i in range {
            guard case let .identifier(name) = tokens[i],
                  [type, "Self", "self"].contains(name)
            else {
                continue
            }
            if let nextIndex = index(of: .nonSpaceOrComment, after: i),
               let nextToken = token(at: nextIndex), nextToken == .startOfScope("(") ||
               (nextToken == .operator(".", .infix) && [.identifier("init"), .identifier("self")]
                   .contains(next(.nonSpaceOrComment, after: nextIndex) ?? .space("")))
            {
                return true
            }
        }
        return false
    }

    func rangeContainsSelfAssignment(_ range: Range<Int>) -> Bool {
        for i in range {
            guard case .identifier("self") = tokens[i] else {
                continue
            }
            if let token = last(.nonSpaceOrCommentOrLinebreak, before: i),
               [.operator("=", .infix), .delimiter(":"), .startOfScope("(")].contains(token)
            {
                return true
            }
        }
        return false
    }
}
