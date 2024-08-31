//
//  RedundantSelf.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 3/13/17.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Insert or remove redundant self keyword
    static let redundantSelf = FormatRule(
        help: "Insert/remove explicit `self` where applicable.",
        options: ["self", "selfrequired"]
    ) { formatter in
        _ = formatter.options.selfRequired
        _ = formatter.options.explicitSelf
        formatter.addOrRemoveSelf(static: false)
    } examples: {
        """
        ```diff
          func foobar(foo: Int, bar: Int) {
            self.foo = foo
            self.bar = bar
        -   self.baz = 42
          }

          func foobar(foo: Int, bar: Int) {
            self.foo = foo
            self.bar = bar
        +   baz = 42
          }
        ```

        In the rare case of functions with `@autoclosure` arguments, `self` may be
        required at the call site, but SwiftFormat is unable to detect this
        automatically. You can use the `--selfrequired` command-line option to specify
        a list of such methods, and the `redundantSelf` rule will then ignore them.

        An example of such a method is the `expect()` function in the Nimble unit
        testing framework (https://github.com/Quick/Nimble), which is common enough that
        SwiftFormat excludes it by default.

        There is also an option to always use explicit `self` but *only* inside `init`,
        by using `--self init-only`:

        ```diff
          init(foo: Int, bar: Int) {
            self.foo = foo
            self.bar = bar
        -   baz = 42
          }

          init(foo: Int, bar: Int) {
            self.foo = foo
            self.bar = bar
        +   self.baz = 42
          }
        ```
        """
    }
}
