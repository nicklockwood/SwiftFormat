//
//  RedundantSendable.swift
//  SwiftFormat
//
//  Created by Nacho Soto on 2/20/2026.
//

import Foundation

public extension FormatRule {
    static let redundantSendable = FormatRule(
        help: "Remove redundant explicit Sendable conformance from non-public structs and enums."
    ) { formatter in
        let declarations = formatter.parseDeclarations()

        declarations.forEachRecursiveDeclaration { declaration in
            guard let typeDeclaration = declaration.asTypeDeclaration,
                  typeDeclaration.keyword == "struct" || typeDeclaration.keyword == "enum"
            else { return }

            switch typeDeclaration.visibility() {
            case .public, .open:
                return
            case .internal, .package, .fileprivate, .private:
                break
            case nil:
                // A type with no explicit access modifier inside a public extension is effectively public
                let isInPublicExtension = typeDeclaration.parentDeclarations.last.map {
                    $0.keyword == "extension" && $0.visibility() == .public
                } ?? false
                if isInPublicExtension {
                    return
                }
            }

            guard let sendableConformance = typeDeclaration.conformances.first(where: {
                formatter.isRedundantSendableConformance($0.conformance)
            }) else { return }

            formatter.removeConformance(
                at: sendableConformance.index,
                range: sendableConformance.conformance.range
            )
        }
    } examples: {
        """
        ```diff
        - struct CacheEntry: Sendable {
        + struct CacheEntry {
              let id: String
          }

        - fileprivate enum ParsingState: Sendable {
        + fileprivate enum ParsingState {
              case idle
              case running
          }
        ```
        """
    }
}

extension Formatter {
    func isRedundantSendableConformance(_ conformance: TypeName) -> Bool {
        let significantTokens = conformance.tokens.filter { !$0.isSpaceOrCommentOrLinebreak }

        guard !significantTokens.contains(where: { $0.isAttribute && $0.string == "@unchecked" }) else {
            return false
        }

        if significantTokens == [.identifier("Sendable")] {
            return true
        }

        guard significantTokens.count == 3,
              significantTokens[0] == .identifier("Swift"),
              significantTokens[2] == .identifier("Sendable")
        else {
            return false
        }

        let dotToken = significantTokens[1]
        return dotToken.isOperator(".") || dotToken == .delimiter(".")
    }

    func removeConformance(at conformanceIndex: Int, range conformanceRange: ClosedRange<Int>) {
        guard let previousTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: conformanceIndex),
              let nextTokenIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: conformanceRange.upperBound)
        else { return }

        let removalRange: ClosedRange<Int>
        if tokens[nextTokenIndex] == .delimiter(",") {
            let upperBound: Int
            if token(at: nextTokenIndex + 1)?.isSpace == true {
                upperBound = nextTokenIndex + 1
            } else {
                upperBound = nextTokenIndex
            }
            removalRange = conformanceIndex ... upperBound
        } else {
            // When removing all conformances, also strip any space tokens immediately
            // before the colon to avoid leaving a trailing double space
            // (e.g. `enum Bar : Sendable {` → `enum Bar {`, not `enum Bar  {`).
            var lower = previousTokenIndex
            if tokens[lower] == .delimiter(":") {
                while lower > 0, token(at: lower - 1)?.isSpace == true {
                    lower -= 1
                }
            }
            removalRange = lower ... conformanceRange.upperBound
        }

        // Avoid removing inline comments attached to the conformance list.
        guard !tokens[removalRange].contains(where: \.isComment) else {
            return
        }

        removeTokens(in: removalRange)
    }
}
