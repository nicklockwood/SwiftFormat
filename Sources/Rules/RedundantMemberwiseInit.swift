//
//  RedundantMemberwiseInit.swift
//  SwiftFormat
//
//  Created by Miguel Jimenez on 6/17/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant explicit memberwise initializers from structs
    static let redundantMemberwiseInit = FormatRule(
        help: "Remove explicit internal memberwise initializers that are redundant.",
        orderAfter: [.redundantInit]
    ) { formatter in
        formatter.forEach(.keyword("struct")) { structIndex, _ in
            guard let structBraceIndex = formatter.index(of: .startOfScope("{"), after: structIndex),
                  let structEndIndex = formatter.endOfScope(at: structBraceIndex)
            else { return }

            // Collect stored properties
            var storedProperties: [(name: String, type: String)] = []

            var searchIndex = structBraceIndex + 1
            while let varOrLetIndex = formatter.index(of: .keyword, after: searchIndex - 1, if: {
                ["var", "let"].contains($0.string)
            }), varOrLetIndex < structEndIndex {
                guard let property = formatter.parsePropertyDeclaration(atIntroducerIndex: varOrLetIndex),
                      let typeInfo = property.type,
                      property.body == nil, // Only stored properties
                      !formatter.modifiersForDeclaration(at: varOrLetIndex, contains: { _, modifier in
                          ["static", "private", "fileprivate", "public", "open"].contains(modifier)
                      })
                else {
                    searchIndex = varOrLetIndex + 1
                    continue
                }

                storedProperties.append((name: property.identifier, type: typeInfo.name))
                searchIndex = property.range.upperBound + 1
            }

            guard !storedProperties.isEmpty else { return }

            // Find redundant memberwise inits
            searchIndex = structBraceIndex + 1
            while let initIndex = formatter.index(of: .keyword("init"), after: searchIndex - 1),
                  initIndex < structEndIndex
            {
                // Skip if has explicit access modifier
                guard !formatter.modifiersForDeclaration(at: initIndex, contains: { _, modifier in
                    ["private", "fileprivate", "public", "open"].contains(modifier)
                }) else {
                    searchIndex = initIndex + 1
                    continue
                }

                guard let openParenIndex = formatter.index(of: .startOfScope("("), after: initIndex),
                      let closeParenIndex = formatter.endOfScope(at: openParenIndex),
                      let initBodyIndex = formatter.index(of: .startOfScope("{"), after: closeParenIndex),
                      let initBodyEndIndex = formatter.endOfScope(at: initBodyIndex)
                else {
                    searchIndex = initIndex + 1
                    continue
                }

                // Parse parameters
                var parameters: [(name: String, type: String)] = []
                var paramIndex = openParenIndex + 1

                while let nextParamIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: paramIndex - 1),
                      nextParamIndex < closeParenIndex,
                      let paramToken = formatter.token(at: nextParamIndex),
                      paramToken.isIdentifier
                {
                    guard let colonIndex = formatter.index(of: .delimiter(":"), after: nextParamIndex),
                          colonIndex < closeParenIndex,
                          let typeStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex),
                          let typeInfo = formatter.parseType(at: typeStartIndex)
                    else {
                        paramIndex = nextParamIndex + 1
                        continue
                    }

                    parameters.append((name: paramToken.string, type: typeInfo.name))

                    if let commaIndex = formatter.index(of: .delimiter(","), after: typeInfo.range.upperBound),
                       commaIndex < closeParenIndex
                    {
                        paramIndex = commaIndex + 1
                    } else {
                        break
                    }
                }

                // Check if parameters match stored properties
                guard parameters.count == storedProperties.count,
                      zip(parameters, storedProperties).allSatisfy({ $0.name == $1.name && $0.type == $1.type })
                else {
                    searchIndex = initIndex + 1
                    continue
                }

                // Check if body only contains memberwise assignments
                var isRedundant = true
                var bodyIndex = initBodyIndex + 1
                var assignmentCount = 0

                while let nextToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: bodyIndex - 1),
                      nextToken < initBodyEndIndex
                {
                    let token = formatter.tokens[nextToken]

                    if token == .identifier("self") {
                        guard let dotIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextToken, if: {
                            $0.isOperator(".")
                        }),
                            let propIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: dotIndex),
                            let propToken = formatter.token(at: propIndex),
                            propToken.isIdentifier,
                            let equalsIndex = formatter.index(of: .operator("=", .infix), after: propIndex),
                            let valueIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex),
                            let valueToken = formatter.token(at: valueIndex),
                            valueToken.isIdentifier,
                            propToken.string == valueToken.string,
                            storedProperties.contains(where: { $0.name == propToken.string })
                        else {
                            isRedundant = false
                            break
                        }

                        assignmentCount += 1
                        bodyIndex = valueIndex + 1
                    } else {
                        isRedundant = false
                        break
                    }
                }

                // Remove redundant init if all assignments match
                if isRedundant, assignmentCount == storedProperties.count {
                    let startRemovalIndex = formatter.startOfModifiers(at: initIndex, includingAttributes: false)
                    let endRemovalIndex = initBodyEndIndex

                    // Find the range including preceding and trailing whitespace
                    var actualStartIndex = startRemovalIndex
                    var actualEndIndex = endRemovalIndex

                    // Include preceding spaces and blank line
                    while let prevToken = formatter.token(at: actualStartIndex - 1), prevToken.isSpace {
                        actualStartIndex -= 1
                    }
                    if let prevToken = formatter.token(at: actualStartIndex - 1), prevToken.isLinebreak {
                        actualStartIndex -= 1
                    }

                    // Include trailing newlines and any orphaned indentation
                    while let next = formatter.token(at: actualEndIndex + 1), next.isSpaceOrLinebreak {
                        actualEndIndex += 1
                    }

                    formatter.removeTokens(in: actualStartIndex ... actualEndIndex)
                    return
                }

                searchIndex = initIndex + 1
            }
        }
    } examples: {
        """
        ```diff
        struct Person {
            var name: String
            var age: Int

        -   init(name: String, age: Int) {
        -       self.name = name
        -       self.age = age
        -   }
        }
        ```
        """
    }
}
