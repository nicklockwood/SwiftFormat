//
//  RedundantMemberwiseInit.swift
//  SwiftFormat
//
//  Created by Miguel Jimenez on 6/17/25.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

/// Helper function to check if a function argument has a default value
private func checkForDefaultValue(arg: Formatter.FunctionArgument, in formatter: Formatter) -> Bool {
    // Start searching after the internal label index
    let searchIndex = arg.internalLabelIndex + 1
    
    // Find the colon
    guard let colonIndex = formatter.index(of: .delimiter(":"), after: searchIndex - 1) else {
        return false
    }
    
    // Find the end of the type after the colon
    guard let typeStartIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex) else {
        return false  
    }
    
    // Parse the type to find its end
    guard let typeInfo = formatter.parseType(at: typeStartIndex) else {
        return false
    }
    let typeEndIndex = typeInfo.range.upperBound
    
    // Look for '=' token after the type
    if let equalsIndex = formatter.index(of: .operator("=", .infix), after: typeEndIndex),
       formatter.index(of: .nonSpaceOrCommentOrLinebreak, in: typeEndIndex + 1 ..< equalsIndex) == nil {
        return true
    }
    
    return false
}

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
            
            // Collect stored properties from the struct body
            let storedProperties = structDeclaration.body.compactMap { childDeclaration -> (name: String, type: String)? in
                guard ["var", "let"].contains(childDeclaration.keyword),
                      let property = formatter.parsePropertyDeclaration(atIntroducerIndex: childDeclaration.keywordIndex),
                      let typeInfo = property.type,
                      property.body == nil, // Only stored properties (no computed properties or observers)
                      !formatter.modifiersForDeclaration(at: childDeclaration.keywordIndex, contains: { _, modifier in
                          ["static", "private", "fileprivate", "public", "open"].contains(modifier)
                      })
                else { return nil }
                
                // Additional check: ensure no property observers (didSet, willSet)
                let propertyEnd = childDeclaration.range.upperBound
                var checkIndex = childDeclaration.keywordIndex + 1
                while checkIndex <= propertyEnd {
                    if let token = formatter.token(at: checkIndex) {
                        if token == .identifier("didSet") || token == .identifier("willSet") {
                            return nil // Has property observers, not a simple stored property
                        }
                    }
                    checkIndex += 1
                }
                
                return (name: property.identifier, type: typeInfo.name)
            }
            
            guard !storedProperties.isEmpty else { continue }
            
            // Find init declarations in the struct body
            for initDeclaration in structDeclaration.body where initDeclaration.keyword == "init" {
                // Skip if has explicit access modifier
                guard !formatter.modifiersForDeclaration(at: initDeclaration.keywordIndex, contains: { _, modifier in
                    ["private", "fileprivate", "public", "open"].contains(modifier)
                }) else { continue }
                
                // Parse the init function using the parseFunctionDeclaration helper
                guard let functionDecl = formatter.parseFunctionDeclaration(keywordIndex: initDeclaration.keywordIndex),
                      let bodyRange = functionDecl.bodyRange
                else { continue }
                
                // Check if parameters match stored properties exactly
                let parameters = functionDecl.arguments.compactMap { arg -> (name: String, type: String, externalLabel: String?, hasDefaultValue: Bool)? in
                    guard let name = arg.internalLabel else { return nil }
                    
                    // Check for default value by looking for '=' after the type
                    let hasDefaultValue = checkForDefaultValue(arg: arg, in: formatter)
                    
                    return (name: name, type: arg.type, externalLabel: arg.externalLabel, hasDefaultValue: hasDefaultValue)
                }
                
                // Don't remove if any parameter has a default value
                guard !parameters.contains(where: { $0.hasDefaultValue }) else { continue }
                
                // Don't remove if any parameter has different external and internal labels
                // This includes cases where external label is explicitly different or uses underscore
                guard !parameters.contains(where: { param in
                    // If externalLabel is nil, it means underscore was used (different from internal name)
                    // If externalLabel exists and is different from internal name, it's also different
                    param.externalLabel == nil || (param.externalLabel != nil && param.externalLabel != param.name)
                }) else { continue }
                
                guard parameters.count == storedProperties.count,
                      zip(parameters, storedProperties).allSatisfy({ $0.name == $1.name && $0.type == $1.type })
                else { continue }
                
                // Check if body only contains memberwise assignments
                let bodyStart = bodyRange.lowerBound + 1
                let bodyEnd = bodyRange.upperBound
                var isRedundant = true
                var bodyIndex = bodyStart
                var assignmentCount = 0
                
                // Check for any comments in the body first - if present, don't remove
                for tokenIndex in bodyStart..<bodyEnd {
                    let token = formatter.tokens[tokenIndex]
                    if token.isComment {
                        isRedundant = false
                        break
                    }
                }
                
                if isRedundant {
                    while let nextToken = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: bodyIndex - 1),
                          nextToken < bodyEnd {
                        
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
                }
                
                // Remove redundant init if all assignments match
                if isRedundant && assignmentCount == storedProperties.count {
                    let startRemovalIndex = formatter.startOfModifiers(at: initDeclaration.keywordIndex, includingAttributes: false)
                    let endRemovalIndex = bodyRange.upperBound
                    
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
                    
                    formatter.removeTokens(in: actualStartIndex...actualEndIndex)
                    return
                }
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
