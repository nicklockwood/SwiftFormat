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
        // Parse all struct declarations
        let allDeclarations = formatter.parseDeclarations()

        for declaration in allDeclarations where declaration.keyword == "struct" {
            guard case let .type(structDeclaration) = declaration.kind else { continue }

            // Get the struct's access level
            let structAccessLevel = declaration.accessLevel()

            // Check if there are any private properties (which would make synthesized init private)
            var hasPrivateStoredProperties = false
            for childDeclaration in structDeclaration.body {
                guard ["var", "let"].contains(childDeclaration.keyword) else { continue }

                let propertyAccessLevel = childDeclaration.accessLevel()
                if propertyAccessLevel == .private || propertyAccessLevel == .fileprivate {
                    hasPrivateStoredProperties = true
                    break
                }
            }

            // Collect stored properties from the struct body
            var storedProperties = [(name: String, type: TypeName)]()

            for childDeclaration in structDeclaration.body {
                guard ["var", "let"].contains(childDeclaration.keyword),
                      let property = formatter.parsePropertyDeclaration(atIntroducerIndex: childDeclaration.keywordIndex),
                      let type = property.type,
                      childDeclaration.isStoredInstanceProperty
                else { continue }
                storedProperties.append((name: property.identifier, type: type))
            }

            guard !storedProperties.isEmpty else { continue }

            // Find all init declarations in the struct body
            let allInitDeclarations = structDeclaration.body.filter { $0.keyword == "init" }

            // If there are multiple inits, don't remove any memberwise init
            // as the compiler won't synthesize it
            guard allInitDeclarations.count == 1 else { continue }

            // Find init declarations in the struct body
            for initDeclaration in structDeclaration.body where initDeclaration.keyword == "init" {
                // Get the init's access level
                let initAccessLevel = initDeclaration.accessLevel()

                // Don't remove public or package inits
                // (compiler won't generate public memberwise init)
                if initAccessLevel == .public || initAccessLevel == .package {
                    continue
                }

                // Handle private property access level implications
                if hasPrivateStoredProperties {
                    // If there are ANY private properties, the synthesized init will be private
                    // Don't remove the explicit init if it's more accessible than private
                    if initAccessLevel != .private {
                        continue
                    }
                    // If both the current init and synthesized init would be private,
                    // it's safe to remove (no access level change)
                } else {
                    // No private properties, so synthesized init would match struct access level
                    // Don't remove private inits if synthesized would be more accessible
                    if initAccessLevel == .private || initAccessLevel == .fileprivate {
                        continue
                    }
                }

                // Check if the init has documentation comments
                var hasDocumentation = false

                // Start from the init keyword and look backwards
                let initKeywordIndex = initDeclaration.keywordIndex
                var checkIndex = initKeywordIndex - 1

                // Look backwards from the init keyword to find documentation comments
                while checkIndex >= 0 {
                    let token = formatter.tokens[checkIndex]

                    if token.isComment {
                        let commentText = token.string

                        // Check if it's documentation comment (/// or /** */)
                        if commentText.hasPrefix("///") || commentText.hasPrefix("/**") {
                            hasDocumentation = true
                            break
                        }

                        // Also check for the case where SwiftFormat splits /// into separate tokens
                        // Look for // followed by / (indicating the third slash for ///)
                        if commentText == "//", checkIndex + 1 < formatter.tokens.count {
                            let nextToken = formatter.tokens[checkIndex + 1]
                            // Must be exactly "/" (the third slash) followed by content, not just any / content
                            // For ///, SwiftFormat splits it as "//" + "/ content"
                            if nextToken.isComment, nextToken.string.hasPrefix("/ ") {
                                // This is /// split as // + / content (note the space after /)
                                hasDocumentation = true
                                break
                            }
                        }

                        // Also check for block comments that start with /**
                        if commentText.contains("/**") {
                            hasDocumentation = true
                            break
                        }

                        // Check for split block comment pattern: /* followed by *
                        if commentText == "/*", checkIndex + 1 < formatter.tokens.count {
                            let nextToken = formatter.tokens[checkIndex + 1]
                            if nextToken.isComment, nextToken.string == "*" {
                                hasDocumentation = true
                                break
                            }
                        }
                    } else if !token.isSpaceOrLinebreak {
                        // Hit non-whitespace, non-comment token, stop looking
                        break
                    }

                    checkIndex -= 1
                }

                // Don't remove init if it has documentation
                if hasDocumentation {
                    continue
                }

                // Don't remove failable inits (init? or init!)
                // Check if there's a ? or ! after the init keyword
                if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: initDeclaration.keywordIndex),
                   let nextToken = formatter.token(at: nextIndex),
                   nextToken.isOperator("?") || nextToken.isOperator("!")
                {
                    continue
                }

                // Parse the init function using the parseFunctionDeclaration helper
                guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: initDeclaration.keywordIndex),
                      let bodyRange = functionDecl.bodyRange
                else { continue }

                // Check if parameters match stored properties exactly
                let parameters = functionDecl.arguments.compactMap { arg -> (name: String, type: TypeName, externalLabel: String?, hasDefaultValue: Bool)? in
                    guard let name = arg.internalLabel else { return nil }

                    // Check for default value by looking for '=' after the type
                    let hasDefaultValue = formatter.checkForDefaultValue(arg: arg)

                    return (name: name, type: arg.type, externalLabel: arg.externalLabel, hasDefaultValue: hasDefaultValue)
                }

                // Don't remove if any parameter has a default value
                guard !parameters.contains(where: \.hasDefaultValue) else { continue }

                // Don't remove if any parameter has different external and internal labels
                // This includes cases where external label is explicitly different or uses underscore
                guard !parameters.contains(where: { param in
                    // If externalLabel is nil, it means underscore was used (different from internal name)
                    // If externalLabel exists and is different from internal name, it's also different
                    param.externalLabel == nil || (param.externalLabel != nil && param.externalLabel != param.name)
                }) else { continue }

                // Only consider properties that don't have default values for memberwise init comparison
                // Properties with default values are optional in memberwise init
                let propertiesWithoutDefaults = storedProperties.filter { prop in
                    // Check if this stored property has a default value
                    !formatter.hasDefaultValue(propertyName: prop.name, in: structDeclaration)
                }

                guard parameters.count == propertiesWithoutDefaults.count,
                      zip(parameters, propertiesWithoutDefaults).allSatisfy({ $0.name == $1.name && $0.type == $1.type })
                else { continue }

                // Check if body only contains memberwise assignments
                let bodyStart = bodyRange.lowerBound + 1
                let bodyEnd = bodyRange.upperBound
                var isRedundant = true
                var bodyIndex = bodyStart
                var assignmentCount = 0

                // Check for any comments in the body first - if present, don't remove
                for tokenIndex in bodyStart ..< bodyEnd {
                    let token = formatter.tokens[tokenIndex]
                    if token.isComment {
                        isRedundant = false
                        break
                    }
                }

                if isRedundant {
                    while let nextToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: bodyIndex - 1),
                          nextToken < bodyEnd
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
                                propertiesWithoutDefaults.contains(where: { $0.name == propToken.string })
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
                }

                // Remove redundant init if all assignments match (only for properties without defaults)
                if isRedundant, assignmentCount == propertiesWithoutDefaults.count {
                    // Use the declaration's range which includes leading comments
                    let startRemovalIndex = initDeclaration.range.lowerBound
                    let endRemovalIndex = bodyRange.upperBound

                    // Find the range including preceding whitespace, but be conservative about trailing
                    var actualStartIndex = startRemovalIndex
                    var actualEndIndex = endRemovalIndex

                    // Include preceding spaces and blank line
                    while actualStartIndex > 0 {
                        if let prevToken = formatter.token(at: actualStartIndex - 1), prevToken.isSpace {
                            actualStartIndex -= 1
                        } else {
                            break
                        }
                    }
                    if actualStartIndex > 0 {
                        if let prevToken = formatter.token(at: actualStartIndex - 1), prevToken.isLinebreak {
                            actualStartIndex -= 1
                        }
                    }

                    // Include trailing spaces and one newline to clean up properly
                    while actualEndIndex + 1 < formatter.tokens.count {
                        let next = formatter.token(at: actualEndIndex + 1)!
                        if next.isSpace {
                            actualEndIndex += 1
                        } else if next.isLinebreak {
                            // Include one newline to clean up, but stop there
                            actualEndIndex += 1
                            break
                        } else {
                            break
                        }
                    }

                    formatter.removeTokens(in: actualStartIndex ... actualEndIndex)
                }
            }
        }
    } examples: {
        """
        ```diff
          struct Person {
              var name: String
              var age: Int

        -     init(name: String, age: Int) {
        -         self.name = name
        -         self.age = age
        -     }
          }
        ```
        """
    }
}

extension Declaration {
    /// Helper function to get the access level of a declaration
    func accessLevel() -> Visibility {
        visibility() ?? .internal
    }
}

extension Formatter {
    /// Helper function to check if a stored property has a default value
    func hasDefaultValue(propertyName: String, in structDeclaration: TypeDeclaration) -> Bool {
        for childDeclaration in structDeclaration.body {
            guard ["var", "let"].contains(childDeclaration.keyword),
                  let property = parsePropertyDeclaration(atIntroducerIndex: childDeclaration.keywordIndex),
                  property.identifier == propertyName,
                  property.value != nil
            else { continue }
            return true
        }
        return false
    }

    /// Helper function to check if a function argument has a default value
    func checkForDefaultValue(arg: Formatter.FunctionArgument) -> Bool {
        // Start searching after the internal label index
        let searchIndex = arg.internalLabelIndex + 1

        // Find the colon
        guard let colonIndex = index(of: .delimiter(":"), after: searchIndex - 1) else {
            return false
        }

        // Find the end of the type after the colon
        guard let typeStartIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex) else {
            return false
        }

        // Parse the type to find its end
        guard let typeInfo = parseType(at: typeStartIndex) else {
            return false
        }
        let typeEndIndex = typeInfo.range.upperBound

        // Look for '=' token after the type
        if let equalsIndex = index(of: .operator("=", .infix), after: typeEndIndex),
           index(of: .nonSpaceOrCommentOrLinebreak, in: typeEndIndex + 1 ..< equalsIndex) == nil
        {
            return true
        }

        return false
    }
}
