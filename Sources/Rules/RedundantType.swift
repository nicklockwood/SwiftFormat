//
//  RedundantType.swift
//  SwiftFormat
//
//  Created by Facundo Menzella on 8/20/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Removes explicit type declarations from initialization declarations
    static let redundantType = FormatRule(
        help: "Remove redundant type from variable declarations.",
        deprecationMessage: "Use propertyTypes with --property-types-mode redundant-only instead.",
        options: ["property-types"],
        sharedOptions: ["init-types", "init-type-min-length"]
    ) { formatter in
        formatter.removeRedundantPropertyTypes(legacyQualifiers: true)
    } examples: {
        """
        ```diff
          // with --propertytypes inferred
        - let view: UIView = UIView()
        + let view = UIView()

          // with --propertytypes explicit
        - let view: UIView = UIView()
        + let view: UIView = .init()

          // with --propertytypes infer-locals-only
          class Foo {
        -     let view: UIView = UIView()
        +     let view: UIView = .init()

              func method() {
        -         let view: UIView = UIView()
        +         let view = UIView()
              }
          }
        ```
        """
    }
}
