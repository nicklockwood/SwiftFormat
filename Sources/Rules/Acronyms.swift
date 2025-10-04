//
//  Acronyms.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/28/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let acronyms = FormatRule(
        help: "Capitalize acronyms when the first character is capitalized.",
        disabledByDefault: true,
        options: ["acronyms", "preserve-acronyms"]
    ) { formatter in
        formatter.forEachToken { i, token in
            let isComment: Bool
            var updatedText: String
            switch token {
            case let .identifier(text) where !formatter.options.preserveAcronyms.contains(text):
                isComment = false
                updatedText = text
            case let .commentBody(text):
                isComment = true
                updatedText = text
            default:
                return
            }

            // Match acronym and return index after
            var index = updatedText.startIndex
            func match(_ acronym: String) -> String.Index? {
                guard updatedText[index...].hasPrefix(acronym) else {
                    return nil
                }
                let indexAfterMatch = updatedText.index(index, offsetBy: acronym.count)
                guard indexAfterMatch < updatedText.endIndex else {
                    return indexAfterMatch
                }

                // Only treat this as an acronym if the next character is uppercased,
                // to prevent "Id" from matching strings like "Identifier".
                let characterAfterMatch = updatedText[indexAfterMatch]
                if characterAfterMatch.isUppercase || characterAfterMatch.isWhitespace {
                    return indexAfterMatch
                }

                // But if the next character is 's', and then the character after the 's' is uppercase,
                // allow the acronym to be capitalized (to handle the plural case, `Ids` to `IDs`)
                else if characterAfterMatch == "s" {
                    guard indexAfterMatch < updatedText.indices.last! else {
                        return indexAfterMatch
                    }
                    let characterAfterNext = updatedText[updatedText.index(after: indexAfterMatch)]
                    return characterAfterNext.isUppercase || characterAfterNext.isWhitespace ? indexAfterMatch : nil
                }

                return nil
            }

            // Sort in descending order and convert to Titlecase
            let acronyms = formatter.options.acronyms
                .sorted(by: { $0.count > $1.count })
                .filter { !$0.isEmpty }
                .map(\.capitalized)

            // Replace all Titlecase acronyms with UPPERCASE
            // TODO: for comments, should we replace lowercase acronyms too?
            outer: while index < updatedText.endIndex {
                for acronym in acronyms where updatedText[index] == acronym.first {
                    if let indexAfter = match(acronym) {
                        updatedText.replaceSubrange(index ..< indexAfter, with: acronym.uppercased())
                        index = indexAfter
                        continue outer
                    } else if let indexAfter = match(acronym.uppercased()) {
                        index = indexAfter
                        continue outer
                    }
                }
                index = updatedText.index(after: index)
            }

            // Replace token
            if isComment {
                formatter.replaceToken(at: i, with: .commentBody(updatedText))
            } else {
                formatter.replaceToken(at: i, with: .identifier(updatedText))
            }
        }
    } examples: {
        """
        ```diff
        - let destinationUrl: URL
        - let urlRouter: UrlRouter
        - let screenIds: [String]
        - let entityUuid: UUID

        + let destinationURL: URL
        + let urlRouter: URLRouter
        + let screenIDs: [String]
        + let entityUUID: UUID
        ```
        """
    }
}
