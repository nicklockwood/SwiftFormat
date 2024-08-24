//
//  WrapMultilineStatementBraces.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapMultilineStatementBraces = FormatRule(
        help: "Wrap the opening brace of multiline statements.",
        examples: """
        ```diff
          if foo,
        -   bar {
            // ...
          }

          if foo,
        +   bar
        + {
            // ...
          }
        ```

        ```diff
          guard foo,
        -   bar else {
            // ...
          }

          guard foo,
        +   bar else
        + {
            // ...
          }
        ```

        ```diff
          func foo(
            bar: Int,
        -   baz: Int) {
            // ...
          }

          func foo(
            bar: Int,
        +   baz: Int)
        + {
            // ...
          }
        ```

        ```diff
          class Foo: NSObject,
        -   BarProtocol {
            // ...
          }

          class Foo: NSObject,
        +   BarProtocol
        + {
            // ...
          }
        ```
        """,
        orderAfter: [.braces, .indent, .wrapArguments],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            guard formatter.last(.nonSpaceOrComment, before: i)?.isLinebreak == false,
                  formatter.shouldWrapMultilineStatementBrace(at: i),
                  let endIndex = formatter.endOfScope(at: i)
            else {
                return
            }
            let indent = formatter.currentIndentForLine(at: endIndex)
            // Insert linebreak
            formatter.insertLinebreak(at: i)
            // Align the opening brace with closing brace
            formatter.insertSpace(indent, at: i + 1)
            // Clean up trailing space on the previous line
            if case .space? = formatter.token(at: i - 1) {
                formatter.removeToken(at: i - 1)
            }
        }
    }
}
