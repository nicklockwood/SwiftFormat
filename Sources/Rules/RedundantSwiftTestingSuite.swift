//
//  RedundantSwiftTestingSuite.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 2/18/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantSwiftTestingSuite = FormatRule(
        help: "Remove redundant @Suite attribute with no arguments."
    ) { formatter in
        guard formatter.hasImport("Testing") else { return }

        // Collect all @Suite attributes to remove first (to avoid re-entrancy issues)
        var attributeIndicesToRemove = [Int]()

        // Find all @Suite attributes
        formatter.forEach(.attribute) { attrIndex, token in
            guard token.string == "@Suite" else { return }

            // Check what comes after @Suite
            guard let nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: attrIndex)
            else { return }

            let nextToken = formatter.tokens[nextTokenIndex]

            // If there's a parenthesis after @Suite, check if it has arguments
            if nextToken == .startOfScope("(") {
                guard let endOfScope = formatter.endOfScope(at: nextTokenIndex) else { return }

                // Check if there are any non-whitespace/comment tokens between the parens
                if let firstTokenInParens = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nextTokenIndex),
                   firstTokenInParens < endOfScope
                {
                    // Has arguments - keep it
                    return
                }

                // Empty parens @Suite() - remove the entire attribute
                attributeIndicesToRemove.append(attrIndex)
            } else {
                // No parens after @Suite - remove the entire attribute
                attributeIndicesToRemove.append(attrIndex)
            }
        }

        // Remove the attributes in reverse order to not invalidate indices
        for attrIndex in attributeIndicesToRemove.reversed() {
            formatter.removeSuiteAttribute(at: attrIndex)
        }
    } examples: {
        """
        ```diff
          import Testing

        - @Suite
          struct MyFeatureTests {
              @Test func myFeature() {
                  #expect(true)
              }
          }

        - @Suite()
          struct OtherTests {
              @Test func otherFeature() {
                  #expect(true)
              }
          }

          // Not redundant - @Suite has arguments
          @Suite(.serialized)
          struct SerializedTests {
              @Test func feature() {
                  #expect(true)
              }
          }
        ```
        """
    }
}

extension Formatter {
    /// Removes a @Suite attribute at the given index, including the trailing linebreak if on its own line
    func removeSuiteAttribute(at atSuiteIndex: Int) {
        var attributeEndIndex = atSuiteIndex

        // Check if there are parentheses after @Suite
        if let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: atSuiteIndex),
           tokens[nextTokenIndex] == .startOfScope("("),
           let endOfScope = endOfScope(at: nextTokenIndex)
        {
            attributeEndIndex = endOfScope
        }

        var startIndex = atSuiteIndex
        var endIndex = attributeEndIndex

        // Check if there's a leading space (between another attribute and this one)
        let hasLeadingSpace = atSuiteIndex > 0 && tokens[atSuiteIndex - 1].isSpace
        let leadingSpaceIsAfterAttribute = hasLeadingSpace && atSuiteIndex > 1 && !tokens[atSuiteIndex - 2].isLinebreak

        let nextNonSpaceIndex = index(of: .nonSpace, after: attributeEndIndex)
        let hasTrailingLinebreak = nextNonSpaceIndex != nil && tokens[nextNonSpaceIndex!].isLinebreak
        let hasTrailingSpace = attributeEndIndex + 1 < tokens.count && tokens[attributeEndIndex + 1].isSpace

        if leadingSpaceIsAfterAttribute {
            // Remove the space before @Suite (space between attributes)
            startIndex = atSuiteIndex - 1
            // Don't remove trailing linebreak - preserve the line structure
            // Don't remove trailing space - it separates from the next token
        } else if hasTrailingLinebreak, let nextIndex = nextNonSpaceIndex {
            // @Suite is at the start of the line (possibly with indentation)
            endIndex = nextIndex
            // Also remove leading indentation
            if hasLeadingSpace, atSuiteIndex > 1, tokens[atSuiteIndex - 2].isLinebreak {
                startIndex = atSuiteIndex - 1
            }
        } else if hasTrailingSpace {
            endIndex = attributeEndIndex + 1
        }

        removeTokens(in: startIndex ... endIndex)
    }
}
