//
//  ExplicitTypes.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 22/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Controls contextual qualifiers independently of declaration annotations.
    static let explicitTypes = FormatRule(
        help: "Control explicit type qualifiers on static members and constructors.",
        orderAfter: [.redundantType, .propertyTypes, .redundantReturn, .redundantInit],
        options: ["explicit-types", "init-type-min-length"]
    ) { formatter in
        formatter.formatExplicitTypes()
    } examples: {
        """
        ```diff
          // --explicit-types inferred
          func foo() -> Bar {
        -     Bar.value
        +     .value
          }

          // --explicit-types auto
          func makeView() -> CustomView {
        -     CustomView()
        +     .init()
          }

          // --explicit-types always
          func makeView() -> CustomView {
        -     .init()
        +     CustomView()
          }
        ```

        `always` expands safely resolvable shorthand. `auto` omits qualifiers when the
        expected type is explicitly stated in the enclosing function or property declaration.
        `inferred` also uses resolved assignment and parameter types, including the project
        index when available. Ambiguous or unresolved expressions are preserved.

        `--init-type-min-length` sets the minimum type name length for shortening to `.init`
        (defaults to 5; use 0 for any length). `propertyTypes` controls whether
        variable declarations have type annotations; it runs before this rule.
        """
    }
}
