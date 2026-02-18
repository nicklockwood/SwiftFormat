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
        help: "Remove redundant @Suite attribute with no arguments.",
        orderAfter: [.swiftTestingTestCaseNames]
    ) { formatter in
        guard formatter.hasImport("Testing") else { return }

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
            }

            // Remove the @Suite attribute
            var attributeEndIndex = attrIndex

            // Check if there are parentheses after @Suite
            if let nextTokenIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: attrIndex),
               formatter.tokens[nextTokenIndex] == .startOfScope("("),
               let endOfScope = formatter.endOfScope(at: nextTokenIndex)
            {
                attributeEndIndex = endOfScope
            }

            var startIndex = attrIndex
            var endIndex = attributeEndIndex

            // Check if there's a leading space (between another attribute and this one)
            let hasLeadingSpace = attrIndex > 0 && formatter.tokens[attrIndex - 1].isSpace
            let leadingSpaceIsAfterAttribute = hasLeadingSpace && attrIndex > 1 && !formatter.tokens[attrIndex - 2].isLinebreak

            let nextNonSpaceIndex = formatter.index(of: .nonSpace, after: attributeEndIndex)
            let hasTrailingLinebreak = nextNonSpaceIndex != nil && formatter.tokens[nextNonSpaceIndex!].isLinebreak
            let hasTrailingSpace = attributeEndIndex + 1 < formatter.tokens.count && formatter.tokens[attributeEndIndex + 1].isSpace

            if leadingSpaceIsAfterAttribute {
                // Remove the space before @Suite (space between attributes)
                startIndex = attrIndex - 1
                // Don't remove trailing linebreak - preserve the line structure
                // Don't remove trailing space - it separates from the next token
            } else if hasTrailingLinebreak, let nextIndex = nextNonSpaceIndex {
                // @Suite is at the start of the line (possibly with indentation)
                endIndex = nextIndex
                // Also remove leading indentation
                if hasLeadingSpace, attrIndex > 1, formatter.tokens[attrIndex - 2].isLinebreak {
                    startIndex = attrIndex - 1
                }
            } else if hasTrailingSpace {
                endIndex = attributeEndIndex + 1
            }

            formatter.removeTokens(in: startIndex ... endIndex)
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
