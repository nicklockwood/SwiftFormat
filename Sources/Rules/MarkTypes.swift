//
//  MarkTypes.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/27/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let markTypes = FormatRule(
        help: "Add a MARK comment before top-level types and extensions.",
        runOnceOnly: true,
        disabledByDefault: true,
        options: ["marktypes", "typemark", "markextensions", "extensionmark", "groupedextension"],
        sharedOptions: ["lineaftermarks", "linebreaks"]
    ) { formatter in
        var declarations = formatter.parseDeclarationsV2()

        // Do nothing if there is only one top-level declaration in the file (excluding imports)
        let declarationsWithoutImports = declarations.filter { $0.keyword != "import" }
        guard declarationsWithoutImports.count > 1 else {
            return
        }

        for (index, declaration) in declarations.enumerated() {
            guard let typeDeclaration = declaration.asTypeDeclaration,
                  let typeName = typeDeclaration.name
            else { continue }

            let markMode: MarkMode
            let commentTemplate: String
            let isGroupedExtension: Bool
            switch declaration.keyword {
            case "extension":
                // TODO: this should be stored in declaration at parse time
                markMode = formatter.options.markExtensions

                // We provide separate mark comment customization points for
                // extensions that are "grouped" with (e.g. following) their extending type,
                // vs extensions that are completely separate.
                //
                //  struct Foo { }
                //  extension Foo { } // This extension is "grouped" with its extending type
                //  extension String { } // This extension is standalone (not grouped with any type)
                //
                let isGroupedWithExtendingType: Bool
                if let indexOfExtendingType = declarations[..<index].lastIndex(where: {
                    $0.name == typeName && $0.definesType
                }) {
                    let declarationsBetweenTypeAndExtension = declarations[indexOfExtendingType + 1 ..< index]
                    isGroupedWithExtendingType = declarationsBetweenTypeAndExtension.allSatisfy {
                        // Only treat the type and its extension as grouped if there aren't any other
                        // types or type-like declarations between them
                        if ["class", "actor", "struct", "enum", "protocol", "typealias"].contains($0.keyword) {
                            return false
                        }
                        // Extensions extending other types also break the grouping
                        if $0.keyword == "extension", $0.name != declaration.name {
                            return false
                        }
                        return true
                    }
                } else {
                    isGroupedWithExtendingType = false
                }

                if isGroupedWithExtendingType {
                    commentTemplate = formatter.options.groupedExtensionMarkComment
                    isGroupedExtension = true
                } else {
                    commentTemplate = formatter.options.extensionMarkComment
                    isGroupedExtension = false
                }
            default:
                markMode = formatter.options.markTypes
                commentTemplate = formatter.options.typeMarkComment
                isGroupedExtension = false
            }

            switch markMode {
            case .always:
                break
            case .never:
                continue
            case .ifNotEmpty:
                guard !typeDeclaration.body.isEmpty else {
                    continue
                }
            }

            // If this declaration is extension, check if it has any conformances
            var conformanceNames: String?
            if declaration.keyword == "extension" {
                let conformances = typeDeclaration.conformances.map(\.conformance)
                if !conformances.isEmpty {
                    conformanceNames = conformances.joined(separator: ", ")
                }
            }

            // Build the types expected mark comment by replacing `%t`s with the type name
            // and `%c`s with the list of conformances added in the extension (if applicable)
            var markForType: String?

            if !commentTemplate.contains("%c") {
                markForType = commentTemplate.replacingOccurrences(of: "%t", with: typeName)
            } else if commentTemplate.contains("%c"), let conformanceNames = conformanceNames {
                markForType = commentTemplate
                    .replacingOccurrences(of: "%t", with: typeName)
                    .replacingOccurrences(of: "%c", with: conformanceNames)
            }

            // If this is an extension without any conformances, but contains exactly
            // one body declaration (a type), we can mark the extension with the nested type's name
            // (e.g. `// MARK: Foo.Bar`).
            if declaration.keyword == "extension",
               conformanceNames == nil
            {
                // Find all of the nested extensions, so we can form the fully qualified
                // name of the inner-most type (e.g. `Foo.Bar.Baaz.Quux`).
                var extensions = [declaration]

                while let innerExtension = extensions.last,
                      let extensionBody = innerExtension.body,
                      extensionBody.count == 1,
                      extensionBody[0].keyword == "extension"
                {
                    extensions.append(extensionBody[0])
                }

                let innermostExtension = extensions.last!
                let extensionNames = extensions.compactMap(\.name).joined(separator: ".")

                if let extensionBody = innermostExtension.body,
                   extensionBody.count == 1,
                   let nestedType = extensionBody.first,
                   nestedType.definesType,
                   let nestedTypeName = nestedType.name
                {
                    let fullyQualifiedName = "\(extensionNames).\(nestedTypeName)"

                    if isGroupedExtension {
                        markForType = formatter.options.groupedExtensionMarkComment
                            .replacingOccurrences(of: "%c", with: fullyQualifiedName)
                    } else {
                        markForType = formatter.options.typeMarkComment
                            .replacingOccurrences(of: "%t", with: fullyQualifiedName)
                    }
                }
            }

            guard let expectedCommentBody = markForType else {
                return
            }

            // When inserting a mark before the first declaration,
            // we should make sure we place it _after_ the file header.
            var markInsertIndex = typeDeclaration.range.lowerBound
            if index == 0, let headerCommentRange = formatter.headerCommentTokenRange() {
                markInsertIndex = headerCommentRange.upperBound
            }

            // Remove any unexpected comments that have the same prefix as the comment template.
            var commentPrefixes = Set(["MARK: ", "MARK: - "])
            if let typeNameSymbolIndex = commentTemplate.firstIndex(of: "%") {
                commentPrefixes.insert(String(commentTemplate.prefix(upTo: typeNameSymbolIndex)))
            }

            var alreadyHasExpectedComment = false
            let potentialCommentRange = markInsertIndex ..< typeDeclaration.leadingCommentRange.upperBound

            let commentsToRemove = formatter.singleLineComments(in: potentialCommentRange, matching: { comment in
                // If we find the exact expected comment, preserve it.
                if comment == expectedCommentBody {
                    alreadyHasExpectedComment = true
                    return false
                }

                for commentPrefix in commentPrefixes {
                    if comment.lowercased().hasPrefix(commentPrefix.lowercased()) {
                        return true
                    }
                }

                return false
            })

            for commentToRemove in commentsToRemove.reversed() {
                let startOfLine = formatter.startOfLine(at: commentToRemove.lowerBound)
                let endOfLine = formatter.endOfLine(at: commentToRemove.lowerBound)

                if formatter.token(at: endOfLine + 1)?.isLinebreak == true {
                    formatter.removeToken(at: endOfLine + 1)
                }

                formatter.removeTokens(in: startOfLine ... endOfLine)
            }

            // Insert the expected comment and the correct number of linebreaks
            if !alreadyHasExpectedComment {
                // Insert the expected comment at the start of the declaration
                formatter.insertLinebreak(at: markInsertIndex)

                if formatter.options.lineAfterMarks {
                    formatter.insertLinebreak(at: markInsertIndex)
                }

                formatter.insert(tokenize("// \(expectedCommentBody)"), at: markInsertIndex)
            }

            // If the previous declaration doesn't end in a blank line,
            // add an additional linebreak to balance the mark.
            if index != 0 {
                let previousDeclaration = declarations[index - 1]
                previousDeclaration.addTrailingBlankLineIfNeeded()
            }
        }
    } examples: {
        """
        ```diff
        + // MARK: - FooViewController
        +
         final class FooViewController: UIViewController { }

        + // MARK: UICollectionViewDelegate
        +
         extension FooViewController: UICollectionViewDelegate { }

        + // MARK: - String + FooProtocol
        +
         extension String: FooProtocol { }
        ```
        """
    }
}
