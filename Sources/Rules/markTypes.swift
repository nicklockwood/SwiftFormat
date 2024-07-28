//
//  markTypes.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    static let markTypes = FormatRule(
        help: "Add a MARK comment before top-level types and extensions.",
        runOnceOnly: true,
        disabledByDefault: true,
        options: ["marktypes", "typemark", "markextensions", "extensionmark", "groupedextension"],
        sharedOptions: ["lineaftermarks"]
    ) { formatter in
        var declarations = formatter.parseDeclarations()

        // Do nothing if there is only one top-level declaration in the file (excluding imports)
        let declarationsWithoutImports = declarations.filter { $0.keyword != "import" }
        guard declarationsWithoutImports.count > 1 else {
            return
        }

        for (index, declaration) in declarations.enumerated() {
            guard case let .type(kind, open, body, close, _) = declaration else { continue }

            guard var typeName = declaration.name else {
                continue
            }

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
                    commentTemplate = "// \(formatter.options.groupedExtensionMarkComment)"
                    isGroupedExtension = true
                } else {
                    commentTemplate = "// \(formatter.options.extensionMarkComment)"
                    isGroupedExtension = false
                }
            default:
                markMode = formatter.options.markTypes
                commentTemplate = "// \(formatter.options.typeMarkComment)"
                isGroupedExtension = false
            }

            switch markMode {
            case .always:
                break
            case .never:
                continue
            case .ifNotEmpty:
                guard !body.isEmpty else {
                    continue
                }
            }

            declarations[index] = formatter.mapOpeningTokens(in: declarations[index]) { openingTokens -> [Token] in
                var openingFormatter = Formatter(openingTokens)

                guard let keywordIndex = openingFormatter.index(after: -1, where: {
                    $0.string == declaration.keyword
                }) else { return openingTokens }

                // If this declaration is extension, check if it has any conformances
                var conformanceNames: String?
                if declaration.keyword == "extension",
                   var conformanceSearchIndex = openingFormatter.index(of: .delimiter(":"), after: keywordIndex)
                {
                    var conformances = [String]()

                    let endOfConformances = openingFormatter.index(of: .keyword("where"), after: keywordIndex)
                        ?? openingFormatter.index(of: .startOfScope("{"), after: keywordIndex)
                        ?? openingFormatter.tokens.count

                    while let token = openingFormatter.token(at: conformanceSearchIndex),
                          conformanceSearchIndex < endOfConformances
                    {
                        if token.isIdentifier {
                            let (fullyQualifiedName, next) = openingFormatter.fullyQualifiedName(startingAt: conformanceSearchIndex)
                            conformances.append(fullyQualifiedName)
                            conformanceSearchIndex = next
                        }

                        conformanceSearchIndex += 1
                    }

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
                    let extensionNames = extensions.compactMap { $0.name }.joined(separator: ".")

                    if let extensionBody = innermostExtension.body,
                       extensionBody.count == 1,
                       let nestedType = extensionBody.first,
                       nestedType.definesType,
                       let nestedTypeName = nestedType.name
                    {
                        let fullyQualifiedName = "\(extensionNames).\(nestedTypeName)"

                        if isGroupedExtension {
                            markForType = "// \(formatter.options.groupedExtensionMarkComment)"
                                .replacingOccurrences(of: "%c", with: fullyQualifiedName)
                        } else {
                            markForType = "// \(formatter.options.typeMarkComment)"
                                .replacingOccurrences(of: "%t", with: fullyQualifiedName)
                        }
                    }
                }

                guard let expectedComment = markForType else {
                    return openingFormatter.tokens
                }

                // Remove any lines that have the same prefix as the comment template
                //  - We can't really do exact matches here like we do for `organizeDeclaration`
                //    category separators, because there's a much wider variety of options
                //    that a user could use for the type name (orphaned renames, etc.)
                var commentPrefixes = Set(["// MARK: ", "// MARK: - "])

                if let typeNameSymbolIndex = commentTemplate.firstIndex(of: "%") {
                    commentPrefixes.insert(String(commentTemplate.prefix(upTo: typeNameSymbolIndex)))
                }

                openingFormatter.forEach(.startOfScope("//")) { index, _ in
                    let startOfLine = openingFormatter.startOfLine(at: index)
                    let endOfLine = openingFormatter.endOfLine(at: index)

                    let commentLine = sourceCode(for: Array(openingFormatter.tokens[index ... endOfLine]))

                    for commentPrefix in commentPrefixes {
                        if commentLine.lowercased().hasPrefix(commentPrefix.lowercased()) {
                            // If we found a line that matched the comment prefix,
                            // remove it and any linebreak immediately after it.
                            if openingFormatter.token(at: endOfLine + 1)?.isLinebreak == true {
                                openingFormatter.removeToken(at: endOfLine + 1)
                            }

                            openingFormatter.removeTokens(in: startOfLine ... endOfLine)
                            break
                        }
                    }
                }

                // When inserting a mark before the first declaration,
                // we should make sure we place it _after_ the file header.
                var markInsertIndex = 0
                if index == 0 {
                    // Search for the end of the file header, which ends when we hit a
                    // blank line or any non-space/comment/lintbreak
                    var endOfFileHeader = 0

                    while openingFormatter.token(at: endOfFileHeader)?.isSpaceOrCommentOrLinebreak == true {
                        endOfFileHeader += 1

                        if openingFormatter.token(at: endOfFileHeader)?.isLinebreak == true,
                           openingFormatter.next(.nonSpace, after: endOfFileHeader)?.isLinebreak == true
                        {
                            markInsertIndex = endOfFileHeader + 2
                            break
                        }
                    }
                }

                // Insert the expected comment at the start of the declaration
                let endMarkDeclaration = formatter.options.lineAfterMarks ? "\n\n" : "\n"
                openingFormatter.insert(tokenize("\(expectedComment)\(endMarkDeclaration)"), at: markInsertIndex)

                // If the previous declaration doesn't end in a blank line,
                // add an additional linebreak to balance the mark.
                if index != 0 {
                    declarations[index - 1] = formatter.mapClosingTokens(in: declarations[index - 1]) {
                        formatter.endingWithBlankLine($0)
                    }
                }

                return openingFormatter.tokens
            }
        }

        let updatedTokens = declarations.flatMap { $0.tokens }
        formatter.replaceTokens(in: 0 ..< formatter.tokens.count, with: updatedTokens)
    }
}
