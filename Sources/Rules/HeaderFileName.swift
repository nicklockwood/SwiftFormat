//
//  HeaderFileName.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 5/3/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Ensure file name reference in header matches actual file name
    static let headerFileName = FormatRule(
        help: "Ensure file name in header comment matches the actual file name.",
        runOnceOnly: true,
        orderAfter: [.fileHeader]
    ) { formatter in
        guard let fileName = formatter.options.fileInfo.fileName,
              let headerRange = formatter.headerCommentTokenRange(includingDirectives: ["*"]),
              fileName.hasSuffix(".swift")
        else {
            return
        }

        for i in headerRange {
            guard case let .commentBody(body) = formatter.tokens[i] else {
                continue
            }
            if body.hasSuffix(".swift"), body != fileName, !body.contains(where: { " /".contains($0) }) {
                formatter.replaceToken(at: i, with: .commentBody(fileName))
            }
        }
    } examples: {
        """
        For a file named `Bar.swift`:

        ```diff
        - //  Foo.swift
        + //  Bar.swift
          //  SwiftFormat
          //
          //  Created by Nick Lockwood on 5/3/23.

          struct Bar {}
        ```
        """
    }
}
