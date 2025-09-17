// Created by Andy Bartholomew on 5/30/25.
// Copyright © 2025 Airbnb Inc. All rights reserved.

import Foundation

public extension FormatRule {
    static let throwingTests = FormatRule(
        help: "Write tests that use `throws` instead of using `try!`.",
        deprecationMessage: "Renamed to `noForceTryInTests`.",
        disabledByDefault: true
    ) { formatter in
        FormatRule.noForceTryInTests.apply(with: formatter)
    } examples: {
        nil
    }
}
