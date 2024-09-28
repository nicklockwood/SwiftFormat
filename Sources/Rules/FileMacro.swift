//
//  FileMacro.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 9/14/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let fileMacro = FormatRule(
        help: "Prefer either #file or #fileID, which have the same behavior in Swift 6 and later.",
        options: ["filemacro"]
    ) { formatter in
        // In the Swift 6 lanaguage mode and later, `#file` and `#fileID` have the same behavior.
        guard formatter.options.languageMode >= "6" else {
            return
        }

        if formatter.options.preferFileMacro {
            formatter.forEach(.keyword("#fileID")) { index, _ in
                formatter.replaceToken(at: index, with: .keyword("#file"))
            }
        } else {
            formatter.forEach(.keyword("#file")) { index, _ in
                formatter.replaceToken(at: index, with: .keyword("#fileID"))
            }
        }
    } examples: {
        """
        ```diff
        // --filemacro #file
        - func foo(file: StaticString = #fileID) { ... }
        + func foo(file: StaticString = #file) { ... }

        // --filemacro #fileID
        - func foo(file: StaticString = #file) { ... }
        + func foo(file: StaticString = #fileID) { ... }
        ```
        """
    }
}
