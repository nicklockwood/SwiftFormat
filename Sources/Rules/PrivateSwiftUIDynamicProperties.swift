//
//  PrivateSwiftUIDynamicProperties.swift
//  SwiftFormat
//
//  Created by Kim de Vos on 8/31/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let privateSwiftUIDynamicProperties = FormatRule(
        help: "Adds `private` access control to SwiftUI dynamic properties without existing access control modifiers.",
        disabledByDefault: true
    ) { formatter in
        formatter.makeSwiftUIDynamicPropertiesPrivate()
    } examples: {
        """
        ```diff
        - @State var isEnabled = true
        + @State private var isEnabled = true
        ```

        ```diff
        - @AppStorage("isEnabled") var isEnabled = true
        + @AppStorage("isEnabled") private var isEnabled = true
        ```

        ```diff
        - @Environment(\\.colorScheme) var colorScheme
        + @Environment(\\.colorScheme) private var colorScheme
        ```
        """
    }
}
