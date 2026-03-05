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
        let isSwiftTestingFile = formatter.hasImport("Testing")
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard let typeDeclaration = declaration.asTypeDeclaration,
                  ["struct", "class"].contains(typeDeclaration.keyword),
                  // exit if structs only
                  !(typeDeclaration.keyword == "class" && formatter.options.enumNamespaces == .structsOnly),
                  // exit if class without final modifier
                  !(typeDeclaration.keyword == "class" && !typeDeclaration.hasModifier("final")),
                  // exit if has attribute(s)
                  typeDeclaration.attributes.isEmpty,
                  // exit if type is conforming to any other types
                  typeDeclaration.conformances.isEmpty
            else { return }

            let i = typeDeclaration.keywordIndex
            guard let name = typeDeclaration.name else { return }

            let body = typeDeclaration.body
            guard !body.isEmpty, body.hostsOnlyStaticMembers else { return }

            guard let braceIndex = formatter.index(of: .startOfScope("{"), after: i),
                  let endIndex = formatter.index(of: .endOfScope("}"), after: braceIndex)
            else { return }

            let range = braceIndex + 1 ..< endIndex
            guard !formatter.rangeContainsTypeInit(name, in: range),
                  !formatter.rangeContainsSelfAssignment(range),
                  !(isSwiftTestingFile && body.contains(where: { $0.keyword == "func" && $0.hasModifier("@Test") }))
            else { return }

            formatter.replaceToken(at: i, with: .keyword("enum"))

            if let finalIndex = formatter.indexOfModifier("final", forDeclarationAt: i),
               let nextIndex = formatter.index(of: .nonSpace, after: finalIndex)
            {
                formatter.removeTokens(in: finalIndex ..< nextIndex)
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

extension Collection<Declaration> {
    /// Whether this collection of declarations contains only static members,
    /// including members inside conditional compilation blocks.
    var hostsOnlyStaticMembers: Bool {
        for declaration in self {
            switch declaration.kind {
            case let .declaration(simple):
                switch simple.keyword {
                case "init":
                    return false
                case "let", "var", "func", "subscript":
                    if !simple.hasModifier("static") { return false }
                default:
                    break
                }
            case .type:
                break
            case let .conditionalCompilation(block):
                if !block.body.hostsOnlyStaticMembers { return false }
            }
        }
        return true
    }
}
