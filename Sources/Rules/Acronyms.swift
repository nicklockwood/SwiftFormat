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
        usesProjectContext: true,
        options: ["acronyms", "preserve-acronyms", "acronym-visibility"]
    ) { formatter in
        func capitalizingAcronyms(in text: String) -> String {
            guard !formatter.options.preserveAcronyms.contains(text) else { return text }
            var updatedText = text

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

            // Find ranges of preserved acronyms within the text
            let preservedRanges = formatter.preservedAcronymRanges(in: updatedText)

            // Replace all Titlecase acronyms with UPPERCASE
            // TODO: for comments, should we replace lowercase acronyms too?
            outer: while index < updatedText.endIndex {
                for acronym in acronyms where updatedText[index] == acronym.first {
                    if let indexAfter = match(acronym) {
                        if preservedRanges.contains(where: { $0.contains(index) }) {
                            index = indexAfter
                        } else {
                            updatedText.replaceSubrange(index ..< indexAfter, with: acronym.uppercased())
                            index = indexAfter
                        }
                        continue outer
                    } else if let indexAfter = match(acronym.uppercased()) {
                        index = indexAfter
                        continue outer
                    }
                }
                index = updatedText.index(after: index)
            }
            return updatedText
        }

        var declaredNames = Set<String>()
        var protectedNames = Set<String>()
        var eligibleNames = Set<String>()
        let projectDeclarationNames: ProjectIndex.DeclarationNames? = formatter.currentFileURL.flatMap { fileURL in
            guard formatter.options.acronymVisibility > .fileprivate else { return nil }
            return formatter.projectIndex?.declarationNames(
                upTo: formatter.options.acronymVisibility,
                visibleFrom: fileURL
            )
        }
        if let projectDeclarationNames {
            declaredNames.formUnion(projectDeclarationNames.declared)
            protectedNames.formUnion(projectDeclarationNames.protected)
            eligibleNames.formUnion(projectDeclarationNames.eligible)
        }
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            let names = formatter.namesInDeclaration(at: declaration.keywordIndex)
                ?? declaration.name.map { [$0] }
                ?? []
            declaredNames.formUnion(names)

            let functionArgumentNames: [String]
            if declaration.keyword.isFunctionDeclarationKeyword,
               let function = formatter.parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
            {
                functionArgumentNames = function.arguments.flatMap { argument in
                    [argument.externalLabel, argument.internalLabel].compactMap { $0 }
                }
                declaredNames.formUnion(functionArgumentNames)
            } else {
                functionArgumentNames = []
            }

            if formatter.declarationCanBeRenamed(
                declaration,
                upTo: formatter.options.acronymVisibility
            ) {
                eligibleNames.formUnion(names)
                eligibleNames.formUnion(functionArgumentNames)
            } else {
                protectedNames.formUnion(names)
                protectedNames.formUnion(functionArgumentNames)
            }
        }

        // Local declarations aren't included in the declaration tree, but are safe to rename.
        formatter.forEachToken { index, token in
            guard case .keyword = token,
                  formatter.declarationScope(at: index) == .local,
                  let names = formatter.namesInDeclaration(at: index)
            else { return }
            declaredNames.formUnion(names)
            eligibleNames.formUnion(names)
            if token.isFunctionDeclarationKeyword,
               let function = formatter.parseFunctionDeclaration(keywordIndex: index)
            {
                let argumentNames = function.arguments.flatMap { argument in
                    [argument.externalLabel, argument.internalLabel].compactMap { $0 }
                }
                declaredNames.formUnion(argumentNames)
                eligibleNames.formUnion(argumentNames)
            }
        }

        var renames = [String: String]()
        var capitalizedNames = [String: [String]]()
        for name in eligibleNames.subtracting(protectedNames) {
            let capitalizedName = capitalizingAcronyms(in: name)
            guard capitalizedName != name else { continue }
            capitalizedNames[capitalizedName, default: []].append(name)
        }

        // Avoid introducing an ambiguous reference or combining two distinct declarations.
        for (capitalizedName, names) in capitalizedNames
            where names.count == 1 && !declaredNames.contains(capitalizedName)
        {
            renames[names[0]] = capitalizedName
        }

        formatter.forEachToken { index, token in
            switch token {
            case let .identifier(name):
                let capitalizedName: String
                if let renamed = renames[name] {
                    capitalizedName = renamed
                } else if formatter.options.acronymVisibility > .fileprivate,
                          projectDeclarationNames == nil,
                          !declaredNames.contains(name)
                {
                    capitalizedName = capitalizingAcronyms(in: name)
                } else {
                    return
                }
                guard capitalizedName != name else { return }
                formatter.replaceToken(at: index, with: .identifier(capitalizedName))
            case let .commentBody(comment):
                let capitalizedComment = capitalizingAcronyms(in: comment)
                guard capitalizedComment != comment else { return }
                formatter.replaceToken(at: index, with: .commentBody(capitalizedComment))
            default:
                break
            }
        }
    } examples: {
        """
        ```diff
        - let destinationUrl: URL
        + let destinationURL: URL
        ```

        ```diff
        - let screenIds: [String]
        + let screenIDs: [String]
        ```

        ```diff
        - let entityUuid: UUID
        + let entityUUID: UUID
        ```
        """
    }
}

extension Formatter {
    /// Returns ranges within `text` that match any of the `preserveAcronyms` values.
    func preservedAcronymRanges(in text: String) -> [Range<String.Index>] {
        guard !options.preserveAcronyms.isEmpty else { return [] }
        var ranges = [Range<String.Index>]()
        for preserved in options.preserveAcronyms {
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let range = text.range(of: preserved, range: searchStart ..< text.endIndex)
            {
                ranges.append(range)
                searchStart = range.upperBound
            }
        }
        return ranges
    }
}
