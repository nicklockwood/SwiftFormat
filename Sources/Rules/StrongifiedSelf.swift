//
//  StrongifiedSelf.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 1/24/19.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Removed backticks from `self` when strongifying
    static let strongifiedSelf = FormatRule(
        help: "Remove backticks around `self` in Optional unwrap expressions.",
        examples: """
        ```diff
        - guard let `self` = self else { return }
        + guard let self = self else { return }
        ```

        **NOTE:** assignment to un-escaped `self` is only supported in Swift 4.2 and
        above, so the `strongifiedSelf` rule is disabled unless the Swift version is
        set to 4.2 or above.
        """
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
