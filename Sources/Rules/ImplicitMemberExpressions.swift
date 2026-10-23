//
//  ImplicitMemberExpressions.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 22/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Controls contextual qualifiers independently of declaration annotations.
    static let implicitMemberExpressions = FormatRule(
        help: "Control explicit type qualifiers on static members and constructors.",
        orderAfter: [.redundantType, .propertyTypes, .redundantReturn, .redundantInit],
        options: ["init-types", "init-type-min-length"]
    ) { formatter in
        formatter.formatImplicitMemberExpressions()
    } examples: {
        """
        Shortens static members such as `Bar.member` to `.member` whenever the expected
        type can be resolved, including assignments and function arguments. The type can
        come from the current file or the project index.

        ```diff
          // Static members are shortened with any --init-types setting
          var value: Bar
        - value = Bar.member
        + value = .member

          // --init-types auto
          func makeView() -> CustomView {
        -     CustomView()
        +     .init()
          }

          // auto leaves separate assignments unchanged
          var view: CustomView
          view = CustomView()

          // --init-types inferred also shortens separate assignments
          var view: CustomView
        - view = CustomView()
        + view = .init()

          // --init-types always
          func makeView() -> CustomView {
        -     .init()
        +     CustomView()
          }
        ```

        The `--init-types` option controls constructor calls only:

        - `auto` (default): use `.init()` when the type is written in the enclosing
          declaration, such as a function's return type or a variable's type annotation.
        - `inferred`: shorten assignments and function arguments when their expected
          type can be found elsewhere in the file or project.
        - `always`: always write the constructor type name explicitly, expanding `.init()`
          to `CustomView()` when the type can be determined.

        Expressions are left unchanged if the expected type is unknown or ambiguous.

        Constructor shortening is only applied to type names of >= 5 characters by default.
        Change this with `--init-type-min-length`, or set it to `0` to allow any length.
        This limit does not apply to static members.
        """
    }
}
