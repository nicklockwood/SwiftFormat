//
//  WrapLoopBodies.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 1/3/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let wrapLoopBodies = FormatRule(
        help: "Wrap the bodies of inline loop statements onto a new line.",
        orderAfter: [.preferForLoop],
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken(where: { [
            .keyword("for"),
            .keyword("while"),
            .keyword("repeat"),
        ].contains($0) }) { i, token in
            if let startIndex = formatter.index(of: .startOfScope("{"), after: i) {
                formatter.wrapStatementBody(at: startIndex)
            } else if token == .keyword("for") {
                return formatter.fatalError("Expected {", at: i)
            }
        }
    } examples: {
        """
        ```diff
        - for foo in array { print(foo) }
        + for foo in array {
        +     print(foo)
        + }
        ```

        ```diff
        - while let foo = bar.next() { print(foo) }
        + while let foo = bar.next() {
        +     print(foo)
        + }
        ```
        """
    }
}
