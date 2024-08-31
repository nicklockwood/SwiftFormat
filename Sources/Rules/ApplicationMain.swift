//
//  ApplicationMain.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 5/20/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace the obsolete `@UIApplicationMain` and `@NSApplicationMain`
    /// attributes with `@main` in Swift 5.3 and above, per SE-0383
    static let applicationMain = FormatRule(
        help: """
        Replace obsolete @UIApplicationMain and @NSApplicationMain attributes
        with @main for Swift 5.3 and above.
        """
    ) { formatter in
        guard formatter.options.swiftVersion >= "5.3" else {
            return
        }
        formatter.forEachToken(where: {
            [
                .keyword("@UIApplicationMain"),
                .keyword("@NSApplicationMain"),
            ].contains($0)
        }) { i, _ in
            formatter.replaceToken(at: i, with: .keyword("@main"))
        }
    }
}
