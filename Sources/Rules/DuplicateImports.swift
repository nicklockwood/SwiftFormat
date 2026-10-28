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
        for var importRanges in formatter.parseImports().reversed() {
            for i in importRanges.indices.reversed() {
                let range = importRanges.remove(at: i)
                guard let j = importRanges.firstIndex(where: { $0.module == range.module }) else {
                    continue
                }
                let range2 = importRanges[j]
                // Only remove an import that is redundant with the other one. For example
                // `import Foo` is redundant with `@testable import Foo`, but neither
                // `@testable import Foo` nor `@_spi(Foo) import Foo` is redundant.
                if Set(range.attributes).isSubset(of: range2.attributes) {
                    formatter.removeTokens(in: range.range)
                    continue
                }
                if j >= i, Set(range2.attributes).isSubset(of: range.attributes) {
                    formatter.removeTokens(in: range2.range)
                    importRanges.remove(at: j)
                }
                importRanges.append(range)
            }
        }
        formatter.removeDuplicateImportsAcrossGroups()
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

extension Formatter {
    /// Remove ordinary file-scope duplicates without combining conditional import groups.
    func removeDuplicateImportsAcrossGroups() {
        guard !options.fragment else { return }
        let imports = parseImports().flatMap { $0 }.filter { range in
            guard range.attributes.isEmpty, range.accessLevel == nil,
                  let importIndex = index(of: .keyword("import"), in: range.range),
                  startOfScope(at: importIndex) == nil,
                  next(.nonSpaceOrCommentOrLinebreak, after: importIndex)?.isIdentifier == true
            else { return false }
            return true
        }
        for range in imports.reversed()
            where imports.first(where: { $0.module == range.module })?.range != range.range
        {
            guard !tokens[range.range].contains(where: { $0.isComment || $0 == .delimiter(";") }) else {
                continue
            }
            removeImportGroupLines([range])
        }
    }
}
