//
//  WrapAttributes.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 7/26/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapAttributes = FormatRule(
        help: "Wrap @attributes onto a separate line, or keep them on the same line.",
        options: ["func-attributes", "type-attributes", "var-attributes", "stored-var-attributes", "computed-var-attributes", "complex-attributes", "non-complex-attributes"],
        sharedOptions: ["line-breaks", "max-width"]
    ) { formatter in
        formatter.forEach(.attribute) { i, _ in
            // Ignore sequential attributes
            guard let endIndex = formatter.endOfAttribute(at: i),
                  var keywordIndex = formatter.index(
                      of: .nonSpaceOrCommentOrLinebreak,
                      after: endIndex, if: { $0.isKeyword || $0.isModifierKeyword }
                  )
            else {
                return
            }

            // Skip modifiers
            while formatter.isModifier(at: keywordIndex),
                  let nextIndex = formatter.index(of: .keyword, after: keywordIndex)
            {
                keywordIndex = nextIndex
            }

            // Check which `AttributeMode` option to use
            var attributeMode: AttributeMode
            switch formatter.tokens[keywordIndex].string {
            case "func", "init", "subscript":
                attributeMode = formatter.options.funcAttributes
            case "class", "actor", "struct", "enum", "protocol", "extension":
                attributeMode = formatter.options.typeAttributes
            case "var", "let":
                let storedOrComputedAttributeMode: AttributeMode
                if formatter.isStoredProperty(atIntroducerIndex: keywordIndex) {
                    storedOrComputedAttributeMode = formatter.options.storedVarAttributes
                } else {
                    storedOrComputedAttributeMode = formatter.options.computedVarAttributes
                }

                // If the relevant `storedvarattrs` or `computedvarattrs` option hasn't been configured,
                // fall back to the previous (now deprecated) `varattributes` option.
                if storedOrComputedAttributeMode == .preserve {
                    attributeMode = formatter.options.varAttributes
                } else {
                    attributeMode = storedOrComputedAttributeMode
                }
            default:
                return
            }

            // If the complexAttributes option is configured, it takes precedence over other options
            // if this is a complex attributes with arguments.
            let attributeName = formatter.tokens[i].string
            let isComplexAttribute = formatter.isComplexAttribute(at: i)
                && !formatter.options.complexAttributesExceptions.contains(attributeName)

            if isComplexAttribute, formatter.options.complexAttributes != .preserve {
                attributeMode = formatter.options.complexAttributes
            }

            // Apply the `AttributeMode`
            switch attributeMode {
            case .preserve:
                return
            case .prevLine:
                // Make sure there's a newline immediately following the attribute
                if let nextIndex = formatter.index(of: .nonSpaceOrComment, after: endIndex),
                   formatter.token(at: nextIndex)?.isLinebreak != true
                {
                    formatter.insertSpace(formatter.currentIndentForLine(at: i), at: nextIndex)
                    formatter.insertLinebreak(at: nextIndex)
                    // Remove any trailing whitespace left on the line with the attributes
                    if let prevToken = formatter.token(at: nextIndex - 1), prevToken.isSpace {
                        formatter.removeToken(at: nextIndex - 1)
                    }
                }
            case .sameLine:
                // Make sure there isn't a newline immediately following the attribute
                if let nextIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: endIndex),
                   formatter.tokens[(endIndex + 1) ..< nextIndex].contains(where: \.isLinebreak)
                {
                    // If unwrapping the attribute causes the line to exceed the max width,
                    // leave it as-is. The existing formatting is likely better than how
                    // this would be re-unwrapped by the wrap rule.
                    let startOfLine = formatter.startOfLine(at: i)
                    let endOfLine = formatter.endOfLine(at: i)
                    let startOfNextLine = formatter.startOfLine(at: nextIndex, excludingIndent: true)
                    let endOfNextLine = formatter.endOfLine(at: nextIndex)
                    let combinedLine = formatter.tokens[startOfLine ... endOfLine].map(\.string).joined()
                        + formatter.tokens[startOfNextLine ..< endOfNextLine].map(\.string).joined()

                    if formatter.options.maxWidth > 0, combinedLine.count > formatter.options.maxWidth {
                        return
                    }

                    // Replace the newline with a space so the attribute doesn't
                    // merge with the next token.
                    formatter.replaceTokens(in: (endIndex + 1) ..< nextIndex, with: .space(" "))
                }
            }
        }
    } examples: {
        """
        `--func-attributes prev-line`

        ```diff
        - @objc func foo() {}

        + @objc
        + func foo() { }
        ```

        `--func-attributes same-line`

        ```diff
        - @objc
        - func foo() { }

        + @objc func foo() {}
        ```

        `--type-attributes prev-line`

        ```diff
        - @objc class Foo {}

        + @objc
        + class Foo { }
        ```

        `--type-attributes same-line`

        ```diff
        - @objc
        - enum Foo { }

        + @objc enum Foo {}
        ```
        """
    }
}

extension Formatter {
    /// Whether or not the attribute starting at the given index is complex. That is, has:
    ///  - any named arguments
    ///  - more than one unnamed argument
    func isComplexAttribute(at attributeIndex: Int) -> Bool {
        assert(tokens[attributeIndex].string.hasPrefix("@"))

        guard let startOfScopeIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: attributeIndex),
              tokens[startOfScopeIndex] == .startOfScope("("),
              let firstTokenInBody = index(of: .nonSpaceOrCommentOrLinebreak, after: startOfScopeIndex),
              let endOfScopeIndex = endOfScope(at: startOfScopeIndex),
              firstTokenInBody != endOfScopeIndex
        else { return false }

        // If the first argument is named with a parameter label, then this is a complex attribute:
        if tokens[firstTokenInBody].isIdentifierOrKeyword,
           let followingToken = index(of: .nonSpaceOrCommentOrLinebreak, after: firstTokenInBody),
           tokens[followingToken] == .delimiter(":")
        {
            return true
        }

        // If there are any commas in the attribute body, then this attribute has
        // multiple arguments and is thus complex:
        for index in startOfScopeIndex ... endOfScopeIndex {
            if tokens[index] == .delimiter(","), startOfScope(at: index) == startOfScopeIndex {
                return true
            }
        }

        return false
    }
}
