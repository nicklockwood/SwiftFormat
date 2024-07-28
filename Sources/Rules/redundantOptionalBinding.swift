//
//  redundantOptionalBinding.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantOptionalBinding = FormatRule(
        help: "Remove redundant identifiers in optional binding conditions.",
        // We can convert `if let foo = self.foo` to just `if let foo`,
        // but only if `redundantSelf` can first remove the `self.`.
        orderAfter: ["redundantSelf"]
    ) { formatter in
        formatter.forEachToken { i, token in
            // `if let foo` conditions were added in Swift 5.7 (SE-0345)
            if formatter.options.swiftVersion >= "5.7",

               [.keyword("let"), .keyword("var")].contains(token),
               formatter.isConditionalStatement(at: i),

               let identiferIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
               let identifier = formatter.token(at: identiferIndex),

               let equalsIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: identiferIndex, if: {
                   $0 == .operator("=", .infix)
               }),

               let nextIdentifierIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: equalsIndex, if: {
                   $0 == identifier
               }),

               let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: nextIdentifierIndex),
               [.startOfScope("{"), .delimiter(","), .keyword("else")].contains(nextToken)
            {
                formatter.removeTokens(in: identiferIndex + 1 ... nextIdentifierIndex)
            }
        }
    }
}
