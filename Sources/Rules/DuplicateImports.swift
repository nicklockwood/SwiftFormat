//
//  DuplicateImports.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 2/7/18.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove duplicate import statements
    static let duplicateImports = FormatRule(
        help: "Remove duplicate import statements."
    ) { formatter in
        let importBatches = formatter.parseImports()
        
        // Build a map of which batch each import belongs to
        var batchForImport: [Range<Int>: Int] = [:]
        for (batchIndex, batch) in importBatches.enumerated() {
            for importRange in batch {
                batchForImport[importRange.range] = batchIndex
            }
        }
        
        // Collect all imports into a single list
        var allImports = importBatches.flatMap { $0 }
        
        // Process imports from bottom to top (reversed)
        for i in allImports.indices.reversed() {
            let range = allImports.remove(at: i)
            guard let j = allImports.firstIndex(where: { $0.module == range.module }) else {
                continue
            }
            let range2 = allImports[j]
            if Set(range.attributes).isSubset(of: range2.attributes) {
                var rangeToRemove = range.range
                
                // Check if this is a cross-batch duplicate
                let isCrossBatch = batchForImport[range.range] != batchForImport[range2.range]
                
                if isCrossBatch {
                    // Apply special linebreak handling for cross-batch duplicates
                    let hasBlankLineBefore = rangeToRemove.lowerBound > 0 &&
                        formatter.tokens[rangeToRemove.lowerBound].isLinebreak &&
                        (formatter.index(of: .nonSpace, before: rangeToRemove.lowerBound).map {
                            formatter.tokens[$0].isLinebreak
                        } ?? false)
                    
                    if hasBlankLineBefore {
                        // Keep one linebreak by extending to include the trailing linebreak
                        if rangeToRemove.upperBound < formatter.tokens.count,
                           formatter.tokens[rangeToRemove.upperBound].isLinebreak
                        {
                            rangeToRemove = rangeToRemove.lowerBound ..< (rangeToRemove.upperBound + 1)
                        }
                    } else {
                        // Keep the leading linebreak, remove trailing linebreaks
                        if formatter.tokens[rangeToRemove.lowerBound].isLinebreak {
                            rangeToRemove = (rangeToRemove.lowerBound + 1) ..< rangeToRemove.upperBound
                        }
                        if rangeToRemove.upperBound < formatter.tokens.count,
                           formatter.tokens[rangeToRemove.upperBound].isLinebreak
                        {
                            var upperBound = rangeToRemove.upperBound + 1
                            if upperBound < formatter.tokens.count,
                               formatter.tokens[upperBound].isLinebreak
                            {
                                upperBound += 1
                            }
                            rangeToRemove = rangeToRemove.lowerBound ..< upperBound
                        }
                    }
                }
                
                formatter.removeTokens(in: rangeToRemove)
                continue
            }
            if j >= i {
                formatter.removeTokens(in: range2.range)
                allImports.remove(at: j)
            }
            allImports.append(range)
        }
    } examples: {
        """
        ```diff
          import Foo
          import Bar
        - import Foo
        ```

        ```diff
          import B
          #if os(iOS)
            import A
        -   import B
          #endif
        ```
        """
    }
}
