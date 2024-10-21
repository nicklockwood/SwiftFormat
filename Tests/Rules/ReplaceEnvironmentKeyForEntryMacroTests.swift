// Created by miguel_jimenez on 10/16/24.
// Copyright © 2024 Airbnb Inc. All rights reserved.

import XCTest

final class ReplaceEnvironmentKeyForEntryMacroTests: XCTestCase {
    func testReplaceEnvironmentKeyDefinitionForEntryMacro() {
        let input = """
        struct ScreenNameEnvironmentKey: EnvironmentKey {
          static var defaultValue: Identifier? {
           .init("undefined") 
          }
        }

        extension EnvironmentValues {
          var screenName: Identifier? {
            get { self[ScreenNameEnvironmentKey.self] }
            set { self[ScreenNameEnvironmentKey.self] = newValue }
          }
        }
        """
        let output = """
        extension EnvironmentValues {
            @Entry var screenName: Identifier? = .init("undefined")
        }
        """
        testFormatting(for: input, output, rule: .replaceEnvironmentKeyForEntryMacro)
    }

    func testReplaceEnvironmentKeyDefinitionForEntryMacroWithKeyDefinitionAfterEnvironmentValue() {
        let input = """
        extension EnvironmentValues {
            var darkModeEnabled: Bool {
              get { self[DarkModeEnabledEnvironmentKey.self] }
              set { self[DarkModeEnabledEnvironmentKey.self] = newValue }
            }
        }

        struct DarkModeEnabledEnvironmentKey: EnvironmentKey {
          static var defaultValue: Bool { false }
        }
        """
        let output = """
        extension EnvironmentValues {
          @Entry var darkModeEnabled: Bool = false
        }
        """
        testFormatting(for: input, output, rule: .replaceEnvironmentKeyForEntryMacro)
    }
}
