//
//  SortImportsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class SortImportsTests: XCTestCase {
    func testSortImportsSimpleCase() {
        let input = "import Foo\nimport Bar"
        let output = "import Bar\nimport Foo"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testSortImportsKeepsPreviousCommentWithImport() {
        let input = "import Foo\n// important comment\n// (very important)\nimport Bar"
        let output = "// important comment\n// (very important)\nimport Bar\nimport Foo"
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testSortImportsKeepsPreviousCommentWithImport2() {
        let input = "// important comment\n// (very important)\nimport Foo\nimport Bar"
        let output = "import Bar\n// important comment\n// (very important)\nimport Foo"
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testSortImportsDoesntMoveHeaderComment() {
        let input = "// header comment\n\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\nimport Foo"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testSortImportsDoesntMoveHeaderCommentFollowedByImportComment() {
        let input = "// header comment\n\n// important comment\nimport Foo\nimport Bar"
        let output = "// header comment\n\nimport Bar\n// important comment\nimport Foo"
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testSortImportsOnSameLine() {
        let input = "import Foo; import Bar\nimport Baz"
        let output = "import Baz\nimport Foo; import Bar"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testSortImportsWithSemicolonAndCommentOnSameLine() {
        let input = "import Foo; // foobar\nimport Bar\nimport Baz"
        let output = "import Bar\nimport Baz\nimport Foo; // foobar"
        testFormatting(for: input, output, rule: .sortImports, exclude: [.semicolons])
    }

    func testSortImportEnum() {
        let input = "import enum Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport enum Foo.baz"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testSortImportFunc() {
        let input = "import func Foo.baz\nimport Foo.bar"
        let output = "import Foo.bar\nimport func Foo.baz"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testAlreadySortImportsDoesNothing() {
        let input = "import Bar\nimport Foo"
        testFormatting(for: input, rule: .sortImports)
    }

    func testPreprocessorSortImports() {
        let input = "#if os(iOS)\n    import Foo2\n    import Bar2\n#else\n    import Foo1\n    import Bar1\n#endif\nimport Foo3\nimport Bar3"
        let output = "#if os(iOS)\n    import Bar2\n    import Foo2\n#else\n    import Bar1\n    import Foo1\n#endif\nimport Bar3\nimport Foo3"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testTestableSortImports() {
        let input = "@testable import Foo3\nimport Bar3"
        let output = "import Bar3\n@testable import Foo3"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testLengthSortImports() {
        let input = "import Foo\nimport Module\nimport Bar3"
        let output = "import Foo\nimport Bar3\nimport Module"
        let options = FormatOptions(importGrouping: .length)
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testTestableImportsWithTestableOnPreviousLine() {
        let input = "@testable\nimport Foo3\nimport Bar3"
        let output = "import Bar3\n@testable\nimport Foo3"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testTestableImportsWithGroupingTestableBottom() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "import Foo\n@testable import Bar\n@testable import UIKit"
        let options = FormatOptions(importGrouping: .testableLast)
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testTestableImportsWithGroupingTestableTop() {
        let input = "@testable import Bar\nimport Foo\n@testable import UIKit"
        let output = "@testable import Bar\n@testable import UIKit\nimport Foo"
        let options = FormatOptions(importGrouping: .testableFirst)
        testFormatting(for: input, output, rule: .sortImports, options: options)
    }

    func testCaseInsensitiveSortImports() {
        let input = "import Zlib\nimport lib"
        let output = "import lib\nimport Zlib"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testCaseInsensitiveCaseDifferingSortImports() {
        let input = "import c\nimport B\nimport A.a\nimport A.A"
        let output = "import A.A\nimport A.a\nimport B\nimport c"
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testNoDeleteCodeBetweenImports() {
        let input = "import Foo\nfunc bar() {}\nimport Bar"
        testFormatting(for: input, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testNoDeleteCodeBetweenImports2() {
        let input = "import Foo\nimport Bar\nfoo = bar\nimport Bar"
        let output = "import Bar\nimport Foo\nfoo = bar\nimport Bar"
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testNoDeleteCodeBetweenImports3() {
        let input = """
        import Z

        // one

        #if FLAG
            print("hi")
        #endif

        import A
        """
        testFormatting(for: input, rule: .sortImports)
    }

    func testSortContiguousImports() {
        let input = "import Foo\nimport Bar\nfunc bar() {}\nimport Quux\nimport Baz"
        let output = "import Bar\nimport Foo\nfunc bar() {}\nimport Baz\nimport Quux"
        testFormatting(for: input, output, rule: .sortImports,
                       exclude: [.blankLineAfterImports])
    }

    func testNoMangleImportsPrecededByComment() {
        let input = """
        // evil comment

        #if canImport(Foundation)
            import Foundation
            #if canImport(UIKit) && canImport(AVFoundation)
                import UIKit
                import AVFoundation
            #endif
        #endif
        """
        let output = """
        // evil comment

        #if canImport(Foundation)
            import Foundation
            #if canImport(UIKit) && canImport(AVFoundation)
                import AVFoundation
                import UIKit
            #endif
        #endif
        """
        testFormatting(for: input, output, rule: .sortImports)
    }

    func testNoMangleFileHeaderNotFollowedByLinebreak() {
        let input = """
        //
        //  Code.swift
        //  Module
        //
        //  Created by Someone on 4/30/20.
        //
        import AModuleUI
        import AModule
        import AModuleHelper
        import SomeOtherModule
        """
        let output = """
        //
        //  Code.swift
        //  Module
        //
        //  Created by Someone on 4/30/20.
        //
        import AModule
        import AModuleHelper
        import AModuleUI
        import SomeOtherModule
        """
        testFormatting(for: input, output, rule: .sortImports)
    }
}
