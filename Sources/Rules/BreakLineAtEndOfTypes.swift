//
//  BreakLineAtEndOfTypes.swift
//  SwiftFormat
//
//  Created by Amir Ardalani on 2024.
//  Copyright © 2024 Amir Ardalani. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Add line break at the end of type declarations (class, actor, struct, enum, protocol, extension)
    static let breakLineAtEndOfTypes = FormatRule(
        help: "Add line break at the end of type declarations (class, actor, struct, enum, protocol, extension).",
        options: ["breaklineendoftypes"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        print("🔍 Rule started: breakLineAtEndOfTypes")
        guard formatter.options.breakLineAtEndOfTypes else {
            print("❌ Rule disabled via options")
            return
        }

        formatter.forEach(.startOfScope("{")) { i, token in
            print("📦 Processing scope at index: \(i), token: \(token)")

            // Only process type declarations
            guard let lastKeyword = formatter.lastSignificantKeyword(at: i, excluding: ["where"]) else {
                print("❌ No last significant keyword found")
                return
            }

            print("🔑 Last keyword: \(lastKeyword)")

            guard ["class", "actor", "struct", "enum", "protocol", "extension"].contains(lastKeyword) else {
                print("❌ Not a type declaration: \(lastKeyword)")
                return
            }

            guard let endIndex = formatter.endOfScope(at: i) else {
                print("❌ No matching end scope found")
                return
            }

            print("🎯 End scope index: \(endIndex)")

            // Find last non-space token before closing brace
            guard let lastToken = formatter.index(of: .nonSpace, before: endIndex) else {
                print("❌ No non-space token found before end scope")
                return
            }

            print("📍 Last token index: \(lastToken), token: \(formatter.tokens[lastToken])")

            // Check how many linebreaks exist between the last token and the closing brace
            let tokens = formatter.tokens[(lastToken + 1) ..< endIndex]
            let linebreaks = tokens.filter(\.isLinebreak).count

            print("📏 Found \(linebreaks) linebreaks between content and closing brace")
            print("🔍 Tokens between: \(tokens)")

            // We need 2 linebreaks for a blank line
            if linebreaks != 2 {
                print("🛠 Modifying: need 2 linebreaks, found \(linebreaks)")

                // First, remove any existing content
                print("🗑 Removing tokens from \(lastToken + 1) to \(endIndex)")
                formatter.removeTokens(in: (lastToken + 1) ..< endIndex)

                // Insert two linebreaks and indentation
                let indent = formatter.options.indent
                print("➕ Inserting linebreak at \(lastToken + 1)")
                formatter.insertLinebreak(at: lastToken + 1)

                print("➕ Inserting linebreak at \(lastToken + 2)")
                formatter.insertLinebreak(at: lastToken + 2)

                print("➕ Inserting indent \"\(indent)\" at \(lastToken + 3)")
                formatter.insertSpace(indent, at: lastToken + 3)

                print("✅ Modification complete")
            } else {
                print("✅ Already has correct blank line formatting")
            }
        }

        print("✅ Rule completed: breakLineAtEndOfTypes")
    } examples: {
        """
        ```diff
          class MyClass {
              // Implementation
        -     }
        +
        +     }
        ```

        ```diff
          struct MyStruct {
              let property: String
        -     }
        +
        +     }
        ```

        ```diff
          enum MyEnum {
              case one
              case two
        -     }
        +
        +     }
        ```
        """
    }
}
