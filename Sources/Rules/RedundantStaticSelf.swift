//
//  RedundantStaticSelf.swift
//  SwiftFormat
//
//  Created by Šimon Javora on 4/29/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove redundant Self keyword
    static let redundantStaticSelf = FormatRule(
        help: "Remove explicit `Self` where applicable."
    ) { formatter in
        formatter.addOrRemoveSelf(static: true)
    } examples: {
        """
        ```diff
          enum Foo {
              static let bar = Bar()

              static func baaz() -> Bar {
        -         Self.bar()
        +         bar()
              }
          }
        ```
        """
    }
}
