//
//  RedundantNilInit.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/5/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove or insert  redundant `= nil` initialization for Optional properties
    static let redundantNilInit = FormatRule(
        help: "Remove/insert redundant `nil` default value (Optional vars are nil by default).",
        options: ["nilinit"]
    ) { formatter in
        // Check modifiers don't include `lazy`
        formatter.forEach(.keyword("var")) { i, _ in
            if formatter.modifiersForDeclaration(at: i, contains: {
                $1 == "lazy" || ($1 != "@objc" && $1.hasPrefix("@"))
            }) || formatter.isInResultBuilder(at: i) {
                return // Can't remove the init
            }
            // Check this isn't a Codable
            if let scopeIndex = formatter.index(of: .startOfScope("{"), before: i) {
                var prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: scopeIndex)
                loop: while let index = prevIndex {
                    switch formatter.tokens[index] {
                    case .identifier("Codable"), .identifier("Decodable"):
                        return // Can't safely remove the default value
                    case .keyword("struct") where formatter.options.swiftVersion < "5.2":
                        if formatter.index(of: .keyword("init"), after: scopeIndex) == nil {
                            return // Can't safely remove the default value
                        }
                        break loop
                    case .keyword:
                        break loop
                    default:
                        break
                    }
                    prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: index)
                }
            }
            // Find the nil
            formatter.search(from: i, isStoredProperty: formatter.isStoredProperty(atIntroducerIndex: i))
        }
    }
}

extension Formatter {
    func search(from index: Int, isStoredProperty: Bool) {
        if let optionalIndex = self.index(of: .unwrapOperator, after: index) {
            if self.index(of: .endOfStatement, in: index + 1 ..< optionalIndex) != nil {
                return
            }
            let previousToken = tokens[optionalIndex - 1]
            if !previousToken.isSpaceOrCommentOrLinebreak, previousToken != .keyword("as") {
                let equalsIndex = self.index(of: .nonSpaceOrLinebreak, after: optionalIndex, if: {
                    $0 == .operator("=", .infix)
                })
                switch options.nilInit {
                case .remove:
                    if let equalsIndex = equalsIndex, let nilIndex = self.index(of: .nonSpaceOrLinebreak, after: equalsIndex, if: {
                        $0 == .identifier("nil")
                    }) {
                        removeTokens(in: optionalIndex + 1 ... nilIndex)
                    }
                case .insert:
                    if isStoredProperty, equalsIndex == nil {
                        let tokens: [Token] = [.space(" "), .operator("=", .infix), .space(" "), .identifier("nil")]
                        insert(tokens, at: optionalIndex + 1)
                    }
                }
            }
            search(from: optionalIndex, isStoredProperty: isStoredProperty)
        }
    }
}
