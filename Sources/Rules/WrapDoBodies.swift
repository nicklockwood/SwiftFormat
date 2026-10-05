//
//  WrapDoBodies.swift
//  SwiftFormat
//
//  Created by Kim de Vos on 10/5/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Wrap inline do and catch bodies onto multiple lines.
    static let wrapDoBodies = FormatRule(
        help: "Wrap the bodies of inline do and catch statements onto multiple lines.",
        disabledByDefault: true,
        sharedOptions: ["linebreaks", "indent"]
    ) { formatter in
        formatter.forEachToken(where: { [.keyword("do"), .keyword("catch")].contains($0) }) { i, _ in
            if let startIndex = formatter.index(of: .startOfScope("{"), after: i) {
                formatter.wrapStatementBody(at: startIndex)
            }
        }
    } examples: {
        """
        ```diff
        - do { try performOperation() } catch { handleError(error) }
        + do {
        +     try performOperation()
        + } catch {
        +     handleError(error)
        + }
        ```
        """
    }
}
