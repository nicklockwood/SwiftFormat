//
//  RulesTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
@testable import SwiftFormat

class RulesTests: XCTestCase {
    // MARK: - shared test infra

    func testFormatting(for input: String, _ output: String? = nil, rule: FormatRule,
                        options: FormatOptions = .default, exclude: [String] = [],
                        file: StaticString = #file, line: UInt = #line)
    {
        testFormatting(for: input, output.map { [$0] } ?? [], rules: [rule],
                       options: options, exclude: exclude, file: file, line: line)
    }

    func testFormatting(for input: String, _ outputs: [String] = [], rules: [FormatRule],
                        options: FormatOptions = .default, exclude: [String] = [],
                        file: StaticString = #file, line: UInt = #line)
    {
        // The `name` property on individual rules is not populated until the first call into `rulesByName`,
        // so we have to make sure to trigger this before checking the names of the given rules.
        if rules.contains(where: { $0.name.isEmpty }) {
            _ = FormatRules.all
        }

        precondition(input != outputs.first || input != outputs.last, "Redundant output parameter")
        precondition((0 ... 2).contains(outputs.count), "Only 0, 1 or 2 output parameters permitted")
        precondition(Set(exclude).intersection(rules.map { $0.name }).isEmpty, "Cannot exclude rule under test")
        let output = outputs.first ?? input, output2 = outputs.last ?? input
        let exclude = exclude
            + (rules.first?.name == "linebreakAtEndOfFile" ? [] : ["linebreakAtEndOfFile"])
            + (rules.first?.name == "organizeDeclarations" ? [] : ["organizeDeclarations"])
            + (rules.first?.name == "extensionAccessControl" ? [] : ["extensionAccessControl"])
            + (rules.first?.name == "markTypes" ? [] : ["markTypes"])
            + (rules.first?.name == "blockToLineComments" ? [] : ["blockToLineComments"])
        XCTAssertEqual(try format(input, rules: rules, options: options), output, file: file, line: line)
        XCTAssertEqual(try format(input, rules: FormatRules.all(except: exclude), options: options),
                       output2, file: file, line: line)
        if input != output {
            XCTAssertEqual(try format(output, rules: rules, options: options),
                           output, file: file, line: line)
            if !input.hasPrefix("#!") {
                for rule in rules {
                    let disabled = "// swiftformat:disable \(rule.name)\n\(input)"
                    XCTAssertEqual(try format(disabled, rules: [rule], options: options),
                                   disabled, "Failed to disable \(rule.name) rule", file: file, line: line)
                }
            }
        }
        if input != output2, output != output2 {
            XCTAssertEqual(try format(output2, rules: FormatRules.all(except: exclude), options: options),
                           output2, file: file, line: line)
        }

        #if os(macOS)
            // These tests are flakey on Linux, and it's hard to debug
            XCTAssertEqual(try lint(output, rules: rules, options: options), [], file: file, line: line)
            XCTAssertEqual(try lint(output2, rules: FormatRules.all(except: exclude), options: options),
                           [], file: file, line: line)
        #endif
    }

    // MARK: - initCoderUnavailable

    func testInitCoderUnavailableEmptyFunction() {
        let input = """
        struct A: UIView {
            required init?(coder aDecoder: NSCoder) {}
        }
        """
        let output = """
        struct A: UIView {
            @available(*, unavailable)
            required init?(coder aDecoder: NSCoder) {}
        }
        """
        testFormatting(for: input, output, rule: FormatRules.initCoderUnavailable,
                       exclude: ["unusedArguments"])
    }

    func testInitCoderUnavailableFatalError() {
        let input = """
        extension Module {
            final class A: UIView {
                required init?(coder _: NSCoder) {
                    fatalError()
                }
            }
        }
        """
        let output = """
        extension Module {
            final class A: UIView {
                @available(*, unavailable)
                required init?(coder _: NSCoder) {
                    fatalError()
                }
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.initCoderUnavailable)
    }

    func testInitCoderUnavailableAlreadyPresent() {
        let input = """
        extension Module {
            final class A: UIView {
                @available(*, unavailable)
                required init?(coder _: NSCoder) {
                    fatalError()
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.initCoderUnavailable)
    }

    func testInitCoderUnavailableImplemented() {
        let input = """
        extension Module {
            final class A: UIView {
                required init?(coder aCoder: NSCoder) {
                    aCoder.doSomething()
                }
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.initCoderUnavailable)
    }

    func testPublicInitCoderUnavailable() {
        let input = """
        class Foo: UIView {
            public required init?(coder _: NSCoder) {
                fatalError()
            }
        }
        """
        let output = """
        class Foo: UIView {
            @available(*, unavailable)
            public required init?(coder _: NSCoder) {
                fatalError()
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.initCoderUnavailable)
    }

    func testPublicInitCoderUnavailable2() {
        let input = """
        class Foo: UIView {
            required public init?(coder _: NSCoder) {
                fatalError()
            }
        }
        """
        let output = """
        class Foo: UIView {
            @available(*, unavailable)
            required public init?(coder _: NSCoder) {
                fatalError()
            }
        }
        """
        testFormatting(for: input, output, rule: FormatRules.initCoderUnavailable,
                       exclude: ["modifierOrder", "specifiers"])
    }

    // MARK: - trailingCommas

    func testCommaAddedToSingleItem() {
        let input = "[\n    foo\n]"
        let output = "[\n    foo,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let output = "[\n    foo,\n    bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedToDictionary() {
        let input = "[\n    foo: bar\n]"
        let output = "[\n    foo: bar,\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToInlineArray() {
        let input = "[foo, bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToInlineDictionary() {
        let input = "[foo: bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedToSubscript() {
        let input = "foo[bar]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaAddedBeforeComment() {
        let input = "[\n    foo // comment\n]"
        let output = "[\n    foo, // comment\n]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedAfterComment() {
        let input = "[\n    foo, // comment\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedInsideEmptyArrayLiteral() {
        let input = "foo = [\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testCommaNotAddedInsideEmptyDictionaryLiteral() {
        let input = "foo = [:\n]"
        let options = FormatOptions(wrapCollections: .disabled)
        testFormatting(for: input, rule: FormatRules.trailingCommas, options: options)
    }

    func testTrailingCommaRemovedInInlineArray() {
        let input = "[foo,]"
        let output = "[foo]"
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript() {
        let input = "foo[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript2() {
        let input = "foo?[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscript3() {
        let input = "foo()[\n    bar\n]"
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToSubscriptInsideArrayLiteral() {
        let input = """
        let array = [
            foo
                .bar[
                    0
                ]
                .baz,
        ]
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaAddedToArrayLiteralInsideTuple() {
        let input = """
        let arrays = ([
            foo
        ], [
            bar
        ])
        """
        let output = """
        let arrays = ([
            foo,
        ], [
            bar,
        ])
        """
        testFormatting(for: input, output, rule: FormatRules.trailingCommas)
    }

    func testNoTrailingCommaAddedToArrayLiteralInsideTuple() {
        let input = """
        let arrays = ([
            Int
        ], [
            Int
        ]).self
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration() {
        let input = """
        var foo: [
            Int:
                String
        ]
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration2() {
        let input = """
        func foo(bar: [
            Int:
                String
        ])
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration3() {
        let input = """
        func foo() -> [
            String: String
        ]
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration4() {
        let input = """
        func foo() -> [String: [
            String: Int
        ]]
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration5() {
        let input = """
        let foo = [String: [
            String: Int
        ]]()
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration6() {
        let input = """
        let foo = [String: [
            (Foo<[
                String
            ]>, [
                Int
            ])
        ]]()
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration7() {
        let input = """
        func foo() -> Foo<[String: [
            String: Int
        ]]>
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToTypeDeclaration8() {
        let input = """
        extension Foo {
            var bar: [
                Int
            ] {
                fatalError()
            }
        }
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    func testTrailingCommaNotAddedToCaptureList() {
        let input = """
        let foo = { [
            self
        ] in }
        """
        testFormatting(for: input, rule: FormatRules.trailingCommas)
    }

    // trailingCommas = false

    func testCommaNotAddedToLastItem() {
        let input = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, rule: FormatRules.trailingCommas, options: options)
    }

    func testCommaRemovedFromLastItem() {
        let input = "[\n    foo,\n    bar,\n]"
        let output = "[\n    foo,\n    bar\n]"
        let options = FormatOptions(trailingCommas: false)
        testFormatting(for: input, output, rule: FormatRules.trailingCommas, options: options)
    }

    // MARK: - fileHeader

    func testStripHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testMultilineCommentHeader() {
        let input = "/****************************/\n/* Created by Nick Lockwood */\n/****************************/\n\n\n// func\nfunc foo() {}"
        let output = "// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderWhenDisabled() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: .ignore)
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripComment() {
        let input = "\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripPackageHeader() {
        let input = "// swift-tools-version:4.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripFormatDirective() {
        let input = "// swiftformat:options --swiftversion 5.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripFormatDirectiveAfterHeader() {
        let input = "// header\n// swiftformat:options --swiftversion 5.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoReplaceFormatDirective() {
        let input = "// swiftformat:options --swiftversion 5.2\n\nimport PackageDescription"
        let output = "// Hello World\n\n// swiftformat:options --swiftversion 5.2\n\nimport PackageDescription"
        let options = FormatOptions(fileHeader: "// Hello World")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testSetSingleLineHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// Hello World\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "// Hello World")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testSetMultilineHeader() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "// Hello\n// World\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "// Hello\n// World")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testSetMultilineHeaderWithMarkup() {
        let input = "//\n//  test.swift\n//  SwiftFormat\n//\n//  Created by Nick Lockwood on 08/11/2016.\n//  Copyright © 2016 Nick Lockwood. All rights reserved.\n//\n\n// func\nfunc foo() {}"
        let output = "/*--- Hello ---*/\n/*--- World ---*/\n\n// func\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "/*--- Hello ---*/\n/*--- World ---*/")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderIfRuleDisabled() {
        let input = "// swiftformat:disable fileHeader\n// test\n// swiftformat:enable fileHeader\n\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderIfNextRuleDisabled() {
        let input = "// swiftformat:disable:next fileHeader\n// test\n\nfunc foo() {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoStripHeaderDocWithNewlineBeforeCode() {
        let input = "/// Header doc\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testNoDuplicateHeaderIfMissingTrailingBlankLine() {
        let input = "// Header comment\nclass Foo {}"
        let output = "// Header comment\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "Header comment")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderYearReplacement() {
        let input = "let foo = bar"
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return "// Copyright © \(formatter.string(from: Date()))\n\nlet foo = bar"
        }()
        let options = FormatOptions(fileHeader: "// Copyright © {year}")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderCreationYearReplacement() {
        let input = "let foo = bar"
        let date = Date(timeIntervalSince1970: 0)
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            return "// Copyright © \(formatter.string(from: date))\n\nlet foo = bar"
        }()
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// Copyright © {created.year}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderCreationDateReplacement() {
        let input = "let foo = bar"
        let date = Date(timeIntervalSince1970: 0)
        let output: String = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return "// Created by Nick Lockwood on \(formatter.string(from: date)).\n\nlet foo = bar"
        }()
        let fileInfo = FileInfo(creationDate: date)
        let options = FormatOptions(fileHeader: "// Created by Nick Lockwood on {created}.", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderRuleThrowsIfCreationDateUnavailable() {
        let input = "let foo = bar"
        let options = FormatOptions(fileHeader: "// Created by Nick Lockwood on {created}.", fileInfo: FileInfo())
        XCTAssertThrowsError(try format(input, rules: [FormatRules.fileHeader], options: options))
    }

    func testFileHeaderFileReplacement() {
        let input = "let foo = bar"
        let output = "// MyFile.swift\n\nlet foo = bar"
        let fileInfo = FileInfo(filePath: "~/MyFile.swift")
        let options = FormatOptions(fileHeader: "// {file}", fileInfo: fileInfo)
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderRuleThrowsIfFileNameUnavailable() {
        let input = "let foo = bar"
        let options = FormatOptions(fileHeader: "// {file}.", fileInfo: FileInfo())
        XCTAssertThrowsError(try format(input, rules: [FormatRules.fileHeader], options: options))
    }

    func testEdgeCaseHeaderEndIndexPlusNewHeaderTokensCountEqualsFileTokensEndIndex() {
        let input = "// Header comment\n\nclass Foo {}"
        let output = "// Header line1\n// Header line2\n\nclass Foo {}"
        let options = FormatOptions(fileHeader: "// Header line1\n// Header line2")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderRemovedAfterHashbang() {
        let input = """
        #!/usr/bin/swift

        // Header line1
        // Header line2

        let foo = 5
        """
        let output = """
        #!/usr/bin/swift

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testFileHeaderPlacedAfterHashbang() {
        let input = """
        #!/usr/bin/swift

        let foo = 5
        """
        let output = """
        #!/usr/bin/swift

        // Header line1
        // Header line2

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "// Header line1\n// Header line2")
        testFormatting(for: input, output, rule: FormatRules.fileHeader, options: options)
    }

    func testBlankLineAfterHashbangNotRemovedByFileHeader() {
        let input = """
        #!/usr/bin/swift

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testLineAfterHashbangNotAffectedByFileHeaderRemoval() {
        let input = """
        #!/usr/bin/swift
        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testDisableFileHeaderCommentRespectedAfterHashbang() {
        let input = """
        #!/usr/bin/swift
        // swiftformat:disable fileHeader

        // Header line1
        // Header line2

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    func testDisableFileHeaderCommentRespectedAfterHashbang2() {
        let input = """
        #!/usr/bin/swift

        // swiftformat:disable fileHeader
        // Header line1
        // Header line2

        let foo = 5
        """
        let options = FormatOptions(fileHeader: "")
        testFormatting(for: input, rule: FormatRules.fileHeader, options: options)
    }

    // MARK: - strongOutlets

    func testRemoveWeakFromOutlet() {
        let input = "@IBOutlet weak var label: UILabel!"
        let output = "@IBOutlet var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromPrivateOutlet() {
        let input = "@IBOutlet private weak var label: UILabel!"
        let output = "@IBOutlet private var label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletOnSplitLine() {
        let input = "@IBOutlet\nweak var label: UILabel!"
        let output = "@IBOutlet\nvar label: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromNonOutlet() {
        let input = "weak var label: UILabel!"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromNonOutletAfterOutlet() {
        let input = "@IBOutlet weak var label1: UILabel!\nweak var label2: UILabel!"
        let output = "@IBOutlet var label1: UILabel!\nweak var label2: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromDelegateOutlet() {
        let input = "@IBOutlet weak var delegate: UITableViewDelegate?"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testNoRemoveWeakFromDataSourceOutlet() {
        let input = "@IBOutlet weak var dataSource: UITableViewDataSource?"
        testFormatting(for: input, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletAfterDelegateOutlet() {
        let input = "@IBOutlet weak var delegate: UITableViewDelegate?\n@IBOutlet weak var label1: UILabel!"
        let output = "@IBOutlet weak var delegate: UITableViewDelegate?\n@IBOutlet var label1: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    func testRemoveWeakFromOutletAfterDataSourceOutlet() {
        let input = "@IBOutlet weak var dataSource: UITableViewDataSource?\n@IBOutlet weak var label1: UILabel!"
        let output = "@IBOutlet weak var dataSource: UITableViewDataSource?\n@IBOutlet var label1: UILabel!"
        testFormatting(for: input, output, rule: FormatRules.strongOutlets)
    }

    // MARK: - strongifiedSelf

    func testBacktickedSelfConvertedToSelfInGuard() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let output = """
        { [weak self] in
            guard let self = self else { return }
        }
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, output, rule: FormatRules.strongifiedSelf, options: options, exclude: ["conditionalBodiesOnNewline"])
    }

    func testBacktickedSelfConvertedToSelfInIf() {
        let input = """
        { [weak self] in
            if let `self` = self else { print(self) }
        }
        """
        let output = """
        { [weak self] in
            if let self = self else { print(self) }
        }
        """
        let options = FormatOptions(swiftVersion: "4.2")
        testFormatting(for: input, output, rule: FormatRules.strongifiedSelf, options: options, exclude: ["conditionalBodiesOnNewline"])
    }

    func testBacktickedSelfNotConvertedIfVersionLessThan4_2() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        let options = FormatOptions(swiftVersion: "4.1.5")
        testFormatting(for: input, rule: FormatRules.strongifiedSelf, options: options, exclude: ["conditionalBodiesOnNewline"])
    }

    func testBacktickedSelfNotConvertedIfVersionUnspecified() {
        let input = """
        { [weak self] in
            guard let `self` = self else { return }
        }
        """
        testFormatting(for: input, rule: FormatRules.strongifiedSelf, exclude: ["conditionalBodiesOnNewline"])
    }

    // MARK: - yodaConditions

    func testNumericLiteralEqualYodaCondition() {
        let input = "5 == foo"
        let output = "foo == 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNumericLiteralGreaterYodaCondition() {
        let input = "5.1 > foo"
        let output = "foo < 5.1"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testStringLiteralNotEqualYodaCondition() {
        let input = "\"foo\" != foo"
        let output = "foo != \"foo\""
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNilNotEqualYodaCondition() {
        let input = "nil != foo"
        let output = "foo != nil"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTrueNotEqualYodaCondition() {
        let input = "true != foo"
        let output = "foo != true"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testEnumCaseNotEqualYodaCondition() {
        let input = ".foo != foo"
        let output = "foo != .foo"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testArrayLiteralNotEqualYodaCondition() {
        let input = "[5, 6] != foo"
        let output = "foo != [5, 6]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNestedArrayLiteralNotEqualYodaCondition() {
        let input = "[5, [6, 7]] != foo"
        let output = "foo != [5, [6, 7]]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testDictionaryLiteralNotEqualYodaCondition() {
        let input = "[foo: 5, bar: 6] != foo"
        let output = "foo != [foo: 5, bar: 6]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testSubscriptNotTreatedAsYodaCondition() {
        let input = "foo[5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)[5] != baz"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo![5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ [5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfCollectionNotTreatedAsYodaCondition() {
        let input = "[foo][5] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfTrailingClosureNotTreatedAsYodaCondition() {
        let input = "foo { [5] }[0] != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testSubscriptOfRhsNotMangledInYodaCondition() {
        let input = "[1] == foo[0]"
        let output = "foo[0] == [1]"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTupleYodaCondition() {
        let input = "(5, 6) != bar"
        let output = "bar != (5, 6)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testLabeledTupleYodaCondition() {
        let input = "(foo: 5, bar: 6) != baz"
        let output = "baz != (foo: 5, bar: 6)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNestedTupleYodaCondition() {
        let input = "(5, (6, 7)) != baz"
        let output = "baz != (5, (6, 7))"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testFunctionCallNotTreatedAsYodaCondition() {
        let input = "foo(5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfParenthesizedExpressionNotTreatedAsYodaCondition() {
        let input = "(foo + bar)(5) != baz"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfUnwrappedValueNotTreatedAsYodaCondition() {
        let input = "foo!(5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfExpressionWithInlineCommentNotTreatedAsYodaCondition() {
        let input = "foo /* foo */ (5) != bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testCallOfRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo(0)"
        let output = "foo(0) == (1, 2)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testTrailingClosureOnRhsNotMangledInYodaCondition() {
        let input = "(1, 2) == foo { $0 }"
        let output = "foo { $0 } == (1, 2)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInIfStatement() {
        let input = "if 5 != foo {}"
        let output = "if foo != 5 {}"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testSubscriptYodaConditionInIfStatementWithBraceOnNextLine() {
        let input = "if [0] == foo.bar[0]\n{ baz() }"
        let output = "if foo.bar[0] == [0]\n{ baz() }"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions, exclude: ["conditionalBodiesOnNewline"])
    }

    func testYodaConditionInSecondClauseOfIfStatement() {
        let input = "if foo, 5 != bar {}"
        let output = "if foo, bar != 5 {}"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInExpression() {
        let input = "let foo = 5 < bar\nbaz()"
        let output = "let foo = bar > 5\nbaz()"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInExpressionWithTrailingClosure() {
        let input = "let foo = 5 < bar { baz() }"
        let output = "let foo = bar { baz() } > 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionInFunctionCall() {
        let input = "foo(5 < bar)"
        let output = "foo(bar > 5)"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testYodaConditionFollowedByExpression() {
        let input = "5 == foo + 6"
        let output = "foo + 6 == 5"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPrefixExpressionYodaCondition() {
        let input = "!false == foo"
        let output = "foo == !false"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPrefixExpressionYodaCondition2() {
        let input = "true == !foo"
        let output = "!foo == true"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionYodaCondition() {
        let input = "5<*> == foo"
        let output = "foo == 5<*>"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testDoublePostfixExpressionYodaCondition() {
        let input = "5!! == foo"
        let output = "foo == 5!!"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionNonYodaCondition() {
        let input = "5 == 5<*>"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testPostfixExpressionNonYodaCondition2() {
        let input = "5<*> == 5"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testStringEqualsStringNonYodaCondition() {
        let input = "\"foo\" == \"bar\""
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testConstantAfterNullCoalescingNonYodaCondition() {
        let input = "foo.last ?? -1 < bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByAndOperator() {
        let input = "5 <= foo && foo <= 7"
        let output = "foo >= 5 && foo <= 7"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByOrOperator() {
        let input = "5 <= foo || foo <= 7"
        let output = "foo >= 5 || foo <= 7"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionFollowedByParentheses() {
        let input = "0 <= (foo + bar)"
        let output = "(foo + bar) >= 0"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary() {
        let input = "let z = 0 < y ? 3 : 4"
        let output = "let z = y > 0 ? 3 : 4"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary2() {
        let input = "let z = y > 0 ? 0 < x : 4"
        let output = "let z = y > 0 ? x > 0 : 4"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testNoMangleYodaConditionInTernary3() {
        let input = "let z = y > 0 ? 3 : 0 < x"
        let output = "let z = y > 0 ? 3 : x > 0"
        testFormatting(for: input, output, rule: FormatRules.yodaConditions)
    }

    func testKeyPathNotMangledAndNotTreatedAsYodaCondition() {
        let input = "\\.foo == bar"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    func testEnumCaseLessThanEnumCase() {
        let input = "XCTAssertFalse(.never < .never)"
        testFormatting(for: input, rule: FormatRules.yodaConditions)
    }

    // yodaSwap = literalsOnly

    func testNoSwapYodaDotMember() {
        let input = "foo(where: .bar == baz)"
        let options = FormatOptions(yodaSwap: .literalsOnly)
        testFormatting(for: input, rule: FormatRules.yodaConditions, options: options)
    }

    // MARK: - leadingDelimiters

    func testLeadingCommaMovedToPreviousLine() {
        let input = """
        let foo = 5
            , bar = 6
        """
        let output = """
        let foo = 5,
            bar = 6
        """
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
    }

    func testLeadingColonFollowedByCommentMovedToPreviousLine() {
        let input = """
        let foo
            : /* string */ String
        """
        let output = """
        let foo:
            /* string */ String
        """
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
    }

    func testCommaMovedBeforeCommentIfLineEndsInComment() {
        let input = """
        let foo = 5 // first
            , bar = 6
        """
        let output = """
        let foo = 5, // first
            bar = 6
        """
        testFormatting(for: input, output, rule: FormatRules.leadingDelimiters)
    }
}
