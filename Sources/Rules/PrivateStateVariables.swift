//
//  PrivateStateVariables.swift
//  SwiftFormatTests
//
//  Created by Dave Paul on 9/13/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let privateStateVariables = FormatRule(
        help: "Adds `private` access control to SwiftUI state properties without existing access control modifiers.",
        renamedTo: .privateSwiftUIDynamicProperties,
        options: ["private-swiftui-properties"]
    ) { formatter in
        formatter.makeSwiftUIDynamicPropertiesPrivate(formatter.options.privateSwiftUIProperties)
    } examples: { nil }
}
