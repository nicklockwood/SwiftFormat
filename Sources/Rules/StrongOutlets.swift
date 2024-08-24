//
//  StrongOutlets.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Strip unnecessary `weak` from @IBOutlet properties (except delegates and datasources)
    static let strongOutlets = FormatRule(
        help: "Remove `weak` modifier from `@IBOutlet` properties.",
        examples: """
        As per Apple's recommendation
        (https://developer.apple.com/videos/play/wwdc2015/407/ @ 32:30).

        ```diff
        - @IBOutlet weak var label: UILabel!
        + @IBOutlet var label: UILabel!
        ```
        """
    ) { formatter in
        formatter.forEach(.keyword("@IBOutlet")) { i, _ in
            guard let varIndex = formatter.index(of: .keyword("var"), after: i),
                  let weakIndex = (i ..< varIndex).first(where: { formatter.tokens[$0] == .identifier("weak") }),
                  case let .identifier(name)? = formatter.next(.identifier, after: varIndex)
            else {
                return
            }
            let lowercased = name.lowercased()
            if lowercased.hasSuffix("delegate") || lowercased.hasSuffix("datasource") {
                return
            }
            if formatter.tokens[weakIndex + 1].isSpace {
                formatter.removeToken(at: weakIndex + 1)
            } else if formatter.tokens[weakIndex - 1].isSpace {
                formatter.removeToken(at: weakIndex - 1)
            }
            formatter.removeToken(at: weakIndex)
        }
    }
}
