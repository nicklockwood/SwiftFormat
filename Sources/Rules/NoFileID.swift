//
//  NoFileID.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/14/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let noFileID = FormatRule(
        help: "Prefer #file over #fileID.")
    { formatter in
        // In the Swift 6 lanaguage mode and later, `#file` and `#fileID` have the same behavior.
        guard formatter.options.languageMode >= "6" else {
            return
        }

        formatter.forEach(.keyword("#fileID")) { index, _ in
            formatter.replaceToken(at: index, with: .keyword("#file"))
        }
    } examples: {
        """
        In the Swift 6 language mode and later, #file has the same behavior as #fileID.
        In the Swift 5 language mode, #file matches the behavior of #filePath.

        ```diff
        - func foo(file: StaticString = #fileID) { ... }
        + func foo(file: StaticString = #file) { ... }
        ```
        """
    }
}
