//
//  RedundantInternal.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let redundantInternal = FormatRule(
        help: "Remove redundant internal access control."
    ) { formatter in
        formatter.forEach(.keyword("internal")) { internalKeywordIndex, _ in
            // Don't remove import acl
            if formatter.next(.nonSpaceOrComment, after: internalKeywordIndex) == .keyword("import") {
                return
            }

            // If we're inside an extension, then `internal` is only redundant if the extension itself is `internal`.
            if let startOfScope = formatter.startOfScope(at: internalKeywordIndex),
               let typeKeywordIndex = formatter.indexOfLastSignificantKeyword(at: startOfScope, excluding: ["where"]),
               formatter.tokens[typeKeywordIndex] == .keyword("extension"),
               // In the language grammar, the ACL level always directly precedes the
               // `extension` keyword if present.
               let previousToken = formatter.last(.nonSpaceOrCommentOrLinebreak, before: typeKeywordIndex),
               ["public", "package", "internal", "private", "fileprivate"].contains(previousToken.string),
               previousToken.string != "internal"
            {
                // The extension has an explicit ACL other than `internal`, so is not internal.
                // We can't remove the `internal` keyword since the declaration would change
                // to the ACL of the extension.
                return
            }

            guard formatter.token(at: internalKeywordIndex + 1)?.isSpace == true else { return }

            formatter.removeTokens(in: internalKeywordIndex ... (internalKeywordIndex + 1))
        }
    }
}
