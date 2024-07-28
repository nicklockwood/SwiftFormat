//
//  acronyms.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    static let acronyms = FormatRule(
        help: "Capitalize acronyms when the first character is capitalized.",
        disabledByDefault: true,
        options: ["acronyms"]
    ) { formatter in
        formatter.forEachToken { index, token in
            guard token.is(.identifier) || token.isComment else { return }

            var updatedText = token.string

            for acronym in formatter.options.acronyms {
                let find = acronym.capitalized
                let replace = acronym.uppercased()

                for replaceCandidateRange in token.string.ranges(of: find) {
                    let acronymShouldBeCapitalized: Bool

                    if replaceCandidateRange.upperBound < token.string.indices.last! {
                        let indexAfterMatch = replaceCandidateRange.upperBound
                        let characterAfterMatch = token.string[indexAfterMatch]

                        // Only treat this as an acronym if the next character is uppercased,
                        // to prevent "Id" from matching strings like "Identifier".
                        if characterAfterMatch.isUppercase || characterAfterMatch.isWhitespace {
                            acronymShouldBeCapitalized = true
                        }

                        // But if the next character is 's', and then the character after the 's' is uppercase,
                        // allow the acronym to be capitalized (to handle the plural case, `Ids` to `IDs`)
                        else if characterAfterMatch == Character("s") {
                            if indexAfterMatch < token.string.indices.last! {
                                let characterAfterNext = token.string[token.string.index(after: indexAfterMatch)]
                                acronymShouldBeCapitalized = (characterAfterNext.isUppercase || characterAfterNext.isWhitespace)
                            } else {
                                acronymShouldBeCapitalized = true
                            }
                        } else {
                            acronymShouldBeCapitalized = false
                        }
                    } else {
                        acronymShouldBeCapitalized = true
                    }

                    if acronymShouldBeCapitalized {
                        updatedText.replaceSubrange(replaceCandidateRange, with: replace)
                    }
                }
            }

            if token.string != updatedText {
                let updatedToken: Token
                switch token {
                case .identifier:
                    updatedToken = .identifier(updatedText)
                case .commentBody:
                    updatedToken = .commentBody(updatedText)
                default:
                    return
                }

                formatter.replaceToken(at: index, with: updatedToken)
            }
        }
    }
}
