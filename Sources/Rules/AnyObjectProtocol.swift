//
//  AnyObjectProtocol.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Prefer `AnyObject` over `class` for class-based protocols
    static let anyObjectProtocol = FormatRule(
        help: "Prefer `AnyObject` over `class` in protocol definitions.",
        examples: """
        ```diff
        - protocol Foo: class {}
        + protocol Foo: AnyObject {}
        ```

        **NOTE:** The guideline to use `AnyObject` instead of `class` was only
        introduced in Swift 4.1, so the `anyObjectProtocol` rule is disabled unless the
        swift version is set to 4.1 or above.
        """
    ) { formatter in
        formatter.forEach(.keyword("protocol")) { i, _ in
            guard formatter.options.swiftVersion >= "4.1",
                  let nameIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i, if: {
                      $0.isIdentifier
                  }), let colonIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: nameIndex, if: {
                      $0 == .delimiter(":")
                  }), let classIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: colonIndex, if: {
                      $0 == .keyword("class")
                  })
            else {
                return
            }
            formatter.replaceToken(at: classIndex, with: .identifier("AnyObject"))
        }
    }
}
