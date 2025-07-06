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
        orderAfter: [.wrap],
        options: ["wrap-arguments", "wrap-parameters", "wrap-collections", "closing-paren", "call-site-paren",
                  "wrap-return-type", "wrap-conditions", "wrap-type-aliases", "wrap-effects", "wrap-string-interpolation"],
        sharedOptions: ["indent", "trim-whitespace", "line-breaks",
                        "tab-width", "max-width", "smart-tabs", "asset-literals", "wrap-ternary"]
    ) { formatter in
        formatter.wrapCollectionsAndArguments(completePartialWrapping: true,
                                              wrapSingleArguments: false)
    } examples: {
        """
        **NOTE:** For backwards compatibility with previous versions, if no value is
        provided for `--wrap-parameters`, the value for `--wrap-arguments` will be used.

        `--wrap-arguments before-first`

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

        `--wrap-parameters after-first`

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

        `--wrap-collections before-first`:

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
        """
    }
}
