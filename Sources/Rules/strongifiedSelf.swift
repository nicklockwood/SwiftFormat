//
//  StrongifiedSelf.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Removed backticks from `self` when strongifying
    static let strongifiedSelf = FormatRule(
        help: "Remove backticks around `self` in Optional unwrap expressions."
    ) { formatter in
        formatter.forEach(.identifier("`self`")) { i, _ in
            guard formatter.options.swiftVersion >= "4.2",
                  let equalIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                      $0 == .operator("=", .infix)
                  }), formatter.next(.nonSpaceOrCommentOrLinebreak, after: equalIndex) == .identifier("self"),
                  formatter.isConditionalStatement(at: i)
            else {
                return
            }
            formatter.replaceToken(at: i, with: .identifier("self"))
        }
    }
}
