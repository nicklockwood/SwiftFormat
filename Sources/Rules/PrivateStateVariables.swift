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
        help: "Adds `private` access control to @State properties without existing access control modifiers.",
        disabledByDefault: true
    ) { formatter in
        formatter.forEachToken(where: { $0 == .keyword("@State") || $0 == .keyword("@StateObject") }) { stateIndex, _ in
            guard let keywordIndex = formatter.index(after: stateIndex, where: {
                $0 == .keyword("let") || $0 == .keyword("var")
            }) else { return }

            // Don't override any existing access control:
            guard !formatter.modifiersForDeclaration(at: keywordIndex, contains: { _, modifier in
                _FormatRules.aclModifiers.contains(modifier) || _FormatRules.aclSetterModifiers.contains(modifier)
            }) else {
                return
            }

            // Check for @Previewable - we won't modify @Previewable macros.
            guard !formatter.modifiersForDeclaration(at: keywordIndex, contains: "@Previewable") else {
                return
            }

            formatter.insert([.keyword("private"), .space(" ")], at: keywordIndex)
        }
    } examples: {
        """
        ```diff
        - @State var anInt: Int
        + @State private var anInt: Int
        ```

        ```diff
        - @StateObject var myInstance: MyObject
        + @StateObject private var myInstance: MyObject
        ```
        """
    }
}
