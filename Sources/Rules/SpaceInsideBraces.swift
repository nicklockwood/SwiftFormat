//
//  SpaceInsideBraces.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 8/22/16.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Ensure that there is space immediately inside braces
    static let spaceInsideBraces = FormatRule(
        help: "Add space inside curly braces.",
        examples: """
        ```diff
        - foo.filter {return true}
        + foo.filter { return true }
        ```
        """
    ) { formatter in
        formatter.forEach(.startOfScope("{")) { i, _ in
            if let nextToken = formatter.token(at: i + 1) {
                if !nextToken.isSpaceOrLinebreak,
                   ![.endOfScope("}"), .startOfScope("{")].contains(nextToken)
                {
                    formatter.insert(.space(" "), at: i + 1)
                }
            }
        }
        formatter.forEach(.endOfScope("}")) { i, _ in
            if let prevToken = formatter.token(at: i - 1) {
                if !prevToken.isSpaceOrLinebreak,
                   ![.endOfScope("}"), .startOfScope("{")].contains(prevToken)
                {
                    formatter.insert(.space(" "), at: i)
                }
            }
        }
    }
}
