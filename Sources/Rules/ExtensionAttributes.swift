//
//  ExtensionAttributes.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 9/8/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Hoist common attributes from extension members to the extension.
    static let extensionAttributes = FormatRule(
        help: "Hoist common member attributes onto the extension.",
        options: ["type-attributes"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard let extensionDeclaration = declaration.asTypeDeclaration,
                  extensionDeclaration.keyword == "extension",
                  extensionDeclaration.conformances.isEmpty
            else { return }

            let bodyDeclarations = extensionDeclaration.body.directDeclarationsExcludingTypeBodies
            guard !bodyDeclarations.isEmpty else { return }

            let extensionAttributes = Set(formatter.hoistableAttributes(for: extensionDeclaration).map(\.text))
            let bodyAttributes = bodyDeclarations.map { formatter.hoistableAttributes(for: $0) }
            let commonBodyAttributes = bodyAttributes
                .map { Set($0.map(\.text)) }
                .reduce(nil as Set<String>?) { commonAttributes, declarationAttributes in
                    commonAttributes?.intersection(declarationAttributes) ?? declarationAttributes
                } ?? []

            let attributesToRemove = commonBodyAttributes.union(extensionAttributes)
            let attributesToHoist = bodyAttributes[0].filter {
                commonBodyAttributes.contains($0.text) && !extensionAttributes.contains($0.text)
            }
            guard !attributesToHoist.isEmpty || !attributesToRemove.isEmpty else { return }

            if !attributesToHoist.isEmpty {
                let insertionIndex = extensionDeclaration.startOfModifiersIndex(includingAttributes: true)
                let insertionTokens = formatter.extensionAttributeTokens(
                    for: attributesToHoist,
                    at: insertionIndex
                )
                formatter.insert(insertionTokens, at: insertionIndex)
            }

            for bodyDeclaration in bodyDeclarations {
                let declarationAttributes = formatter.hoistableAttributes(for: bodyDeclaration).map(\.text)
                for attribute in declarationAttributes.filter(attributesToRemove.contains).reversed() {
                    formatter.removeHoistableAttribute(attribute, from: bodyDeclaration)
                }
            }
        }
    } examples: {
        """
        ```diff
        - extension Foo {
        -     @MainActor func bar() {}
        -     @MainActor func baz() {}
        - }

        + @MainActor
        + extension Foo {
        +     func bar() {}
        +     func baz() {}
        + }
        ```
        """
    }
}

struct HoistableAttribute {
    let text: String
    let tokens: [Token]
}

extension Formatter {
    /// Attributes where applying the attribute to an extension is equivalent to
    /// applying the exact same attribute to every direct member declaration.
    func hoistableAttributes(for declaration: Declaration) -> [HoistableAttribute] {
        var attributes = [HoistableAttribute]()

        _ = modifiersForDeclaration(at: declaration.keywordIndex) { index, modifier in
            guard isHoistableExtensionAttribute(modifier, for: declaration),
                  let endIndex = endOfAttribute(at: index)
            else { return false }

            attributes.append(HoistableAttribute(
                text: modifier,
                tokens: Array(tokens[index ... endIndex])
            ))

            return false
        }

        return attributes
    }

    func removeHoistableAttribute(_ attribute: String, from declaration: Declaration) {
        _ = modifiersForDeclaration(at: declaration.keywordIndex) { index, modifier in
            guard modifier == attribute,
                  let endIndex = endOfAttribute(at: index),
                  let removalRange = removableAttributeRange(from: index, to: endIndex)
            else { return false }

            removeTokens(in: removalRange)
            return true
        }
    }

    func isHoistableExtensionAttribute(_ attribute: String, for declaration: Declaration) -> Bool {
        if attribute == "@MainActor" {
            return !declaration.definesType
        }

        return attribute.hasPrefix("@available(")
    }

    func removableAttributeRange(from startIndex: Int, to endIndex: Int) -> Range<Int>? {
        var end = endIndex + 1

        while token(at: end)?.isSpace == true {
            end += 1
        }

        if token(at: end)?.isComment == true {
            return nil
        }

        if token(at: end)?.isLinebreak == true {
            end += 1

            var nextTokenIndex = end
            while token(at: nextTokenIndex)?.isSpace == true {
                nextTokenIndex += 1
            }

            if token(at: nextTokenIndex)?.isComment != true {
                end = nextTokenIndex
            }
        }

        return startIndex ..< end
    }

    func extensionAttributeTokens(for attributes: [HoistableAttribute], at insertionIndex: Int) -> [Token] {
        switch options.typeAttributes {
        case .sameLine:
            return attributes.flatMap { $0.tokens + [.space(" ")] }

        case .prevLine, .preserve:
            let indent = currentIndentForLine(at: insertionIndex)
            return attributes.flatMap { attribute -> [Token] in
                var tokens = attribute.tokens + [linebreakToken(for: insertionIndex)]
                if !indent.isEmpty {
                    tokens.append(.space(indent))
                }
                return tokens
            }
        }
    }
}

extension Collection<Declaration> {
    var directDeclarationsExcludingTypeBodies: [Declaration] {
        var declarations = [Declaration]()
        forEachRecursiveDeclarationExcludingTypeBodies { declaration in
            declarations.append(declaration)
        }
        return declarations
    }
}
