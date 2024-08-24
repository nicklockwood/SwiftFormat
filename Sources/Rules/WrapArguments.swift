//
//  WrapArguments.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 11/23/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Normalize argument wrapping style
    static let wrapArguments = FormatRule(
        help: "Align wrapped function arguments or collection elements.",
        examples: """
        **NOTE:** For backwards compatibility with previous versions, if no value is
        provided for `--wrapparameters`, the value for `--wraparguments` will be used.

        `--wraparguments before-first`

        ```diff
        - foo(bar: Int,
        -     baz: String)

        + foo(
        +   bar: Int,
        +   baz: String
        + )
        ```

        ```diff
        - class Foo<Bar,
        -           Baz>

        + class Foo<
        +   Bar,
        +   Baz
        + >
        ```

        `--wrapparameters after-first`

        ```diff
        - func foo(
        -   bar: Int,
        -   baz: String
        - ) {
            ...
          }

        + func foo(bar: Int,
        +          baz: String)
        + {
            ...
          }
        ```

        `--wrapcollections before-first`:

        ```diff
        - let foo = [bar,
                     baz,
        -            quuz]

        + let foo = [
        +   bar,
            baz,
        +   quuz
        + ]
        ```

        `--conditionswrap auto`:

        ```diff
        - guard let foo = foo, let bar = bar, let third = third
        + guard let foo = foo,
        +       let bar = bar,
        +       let third = third
          else {}
        ```

        """,
        orderAfter: [.wrap],
        options: ["wraparguments", "wrapparameters", "wrapcollections", "closingparen", "callsiteparen",
                  "wrapreturntype", "wrapconditions", "wraptypealiases", "wrapeffects", "conditionswrap"],
        sharedOptions: ["indent", "trimwhitespace", "linebreaks",
                        "tabwidth", "maxwidth", "smarttabs", "assetliterals", "wrapternary"]
    ) { formatter in
        formatter.wrapCollectionsAndArguments(completePartialWrapping: true,
                                              wrapSingleArguments: false)
    }
}
