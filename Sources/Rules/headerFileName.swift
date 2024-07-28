//
//  headerFileName.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

public extension FormatRule {
    /// Ensure file name reference in header matches actual file name
    static let headerFileName = FormatRule(
        help: "Ensure file name in header comment matches the actual file name.",
        runOnceOnly: true,
        orderAfter: ["fileHeader"]
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
    }
}
