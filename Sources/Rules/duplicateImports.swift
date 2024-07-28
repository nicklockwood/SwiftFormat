//
//  duplicateImports.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove duplicate import statements
    static let duplicateImports = FormatRule(
        help: "Remove duplicate import statements."
    ) { formatter in
        for var importRanges in formatter.parseImports().reversed() {
            for i in importRanges.indices.reversed() {
                let range = importRanges.remove(at: i)
                guard let j = importRanges.firstIndex(where: { $0.module == range.module }) else {
                    continue
                }
                let range2 = importRanges[j]
                if Set(range.attributes).isSubset(of: range2.attributes) {
                    formatter.removeTokens(in: range.range)
                    continue
                }
                if j >= i {
                    formatter.removeTokens(in: range2.range)
                    importRanges.remove(at: j)
                }
                importRanges.append(range)
            }
        }
    }
}
