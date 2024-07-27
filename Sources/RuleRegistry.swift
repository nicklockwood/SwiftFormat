//
//  RuleRegistry.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/27/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

/// All of the rules defined in the Rules directory.
/// **Generated automatically when building. Do not modify.**
let rules: [FormatRule] = [
    indent.named("indent"),
    preferForLoop.named("preferForLoop"),
    spaceAroundComments.named("spaceAroundComments"),
]

public extension _FormatRules {
    var indent: FormatRule { SwiftFormat.indent }
    var preferForLoop: FormatRule { SwiftFormat.preferForLoop }
    var spaceAroundComments: FormatRule { SwiftFormat.spaceAroundComments }
}
