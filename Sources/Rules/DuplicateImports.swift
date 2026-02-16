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
        
        // Process each batch for internal duplicates and cross-batch duplicates
        for batchIndex in importBatches.indices.reversed() {
            var batch = importBatches[batchIndex]
            
            // Get all imports from earlier batches (those that appear first in the file)
            let importsFromEarlierBatches = importBatches[..<batchIndex].flatMap { $0 }
            
            // Process imports in this batch in reverse order
            for i in batch.indices.reversed() {
                let range = batch.remove(at: i)
                
                // First check against imports from earlier batches
                if let matchInEarlierBatch = importsFromEarlierBatches.first(where: { $0.module == range.module }) {
                    // Found a duplicate in an earlier batch - remove this one
                    if Set(range.attributes).isSubset(of: matchInEarlierBatch.attributes) {
                        // The range from parseImports is startLinebreak ..< endLinebreak.
                        // startLinebreak is the linebreak before the import, endLinebreak is after.
                        // The range is exclusive of endLinebreak, so we need to extend it.
                        var rangeToRemove = range.range
                        
                        // Check if there's a blank line BEFORE the import
                        let hasBlankLineBefore = rangeToRemove.lowerBound > 0 &&
                            formatter.tokens[rangeToRemove.lowerBound].isLinebreak &&
                            (formatter.index(of: .nonSpace, before: rangeToRemove.lowerBound).map {
                                formatter.tokens[$0].isLinebreak
                            } ?? false)
                        
                        if hasBlankLineBefore {
                            // Remove the blank line and the import, but keep one linebreak
                            // The range already starts with one linebreak, so just extend to include
                            // the trailing linebreak, and that will leave one linebreak before
                            if rangeToRemove.upperBound < formatter.tokens.count,
                               formatter.tokens[rangeToRemove.upperBound].isLinebreak
                            {
                                rangeToRemove = rangeToRemove.lowerBound ..< (rangeToRemove.upperBound + 1)
                            }
                        } else {
                            // No blank line before. Remove the import line, but keep the linebreak before it.
                            // Adjust the range to NOT include the leading linebreak.
                            if formatter.tokens[rangeToRemove.lowerBound].isLinebreak {
                                rangeToRemove = (rangeToRemove.lowerBound + 1) ..< rangeToRemove.upperBound
                            }
                            
                            // Include trailing linebreak and any blank line after
                            if rangeToRemove.upperBound < formatter.tokens.count,
                               formatter.tokens[rangeToRemove.upperBound].isLinebreak
                            {
                                var upperBound = rangeToRemove.upperBound + 1
                                
                                // Also include any blank line after the import
                                if upperBound < formatter.tokens.count,
                                   formatter.tokens[upperBound].isLinebreak
                                {
                                    upperBound += 1
                                }
                                
                                rangeToRemove = rangeToRemove.lowerBound ..< upperBound
                            }
                        }
                        
                        formatter.removeTokens(in: rangeToRemove)
                        continue
                    }
                }
                
                // Then check against other imports in the same batch
                if let j = batch.firstIndex(where: { $0.module == range.module }) {
                    let range2 = batch[j]
                    if Set(range.attributes).isSubset(of: range2.attributes) {
                        formatter.removeTokens(in: range.range)
                        continue
                    }
                    if j >= i {
                        formatter.removeTokens(in: range2.range)
                        batch.remove(at: j)
                    }
                    batch.append(range)
                    continue
                }
                
                // No duplicate found, keep the import
                batch.append(range)
            }
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
