//
//  CommandLineTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 10/01/2017.
//  Copyright 2017 Nick Lockwood
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

private func createTmpFile(_ path: String, contents: String) throws -> URL {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(path)
    let directory = url.deletingLastPathComponent()
    if !FileManager.default.fileExists(atPath: directory.path) {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    try contents.write(to: url, atomically: true, encoding: .utf8)
    return url
}

private func withTmpFile(_ path: String? = nil, contents: String, fn: (URL) -> Void) throws {
    let path = path ?? (UUID().uuidString + ".swift")
    let prefix = UUID().uuidString
    let url = try createTmpFile("\(prefix)/\(path)", contents: contents)
    fn(url)
    try FileManager.default.removeItem(at: url)
}

private func withTmpFiles(_ files: [String: String], fn: (URL) throws -> Void) throws {
    var urls = [URL]()
    defer {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
    let prefix = UUID().uuidString
    for (path, contents) in files {
        try urls.append(createTmpFile("\(prefix)/\(path)", contents: contents))
    }
    for url in urls where ["swift", "md"].contains(url.pathExtension) {
        try fn(url)
    }
}

private func withTmpDirectory(_ files: [String: String], fn: (URL) throws -> Void) throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for (path, contents) in files {
        _ = try createTmpFile("\(directory.lastPathComponent)/\(path)", contents: contents)
    }
    try fn(directory)
}

private struct TestSnapshot: Decodable {
    let version: Int
    let files: [String: String]
}

private func readSnapshot(at url: URL) throws -> TestSnapshot {
    try JSONDecoder().decode(TestSnapshot.self, from: Data(contentsOf: url))
}

final class CommandLineTests: XCTestCase {
    // MARK: stdin

    func testStdin() {
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                XCTAssertEqual(message, "func foo() {\n    bar()\n}\n")
            case .error, .warning:
                XCTFail()
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo()\n"
            case 2:
                return "{\n"
            case 3:
                return "bar()\n"
            case 4:
                return "}"
            default:
                return nil
            }
        }
        _ = processArguments([""], in: "")
        readCount = 0
        _ = processArguments(["", "stdin"], in: "")
    }

    func testStdinOutputTokens() {
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                XCTAssertEqual(message, """
                {"tokens":[\
                {"string":"func","type":"keyword"},\
                {"string":" ","type":"space"},\
                {"string":"foo","type":"identifier"},\
                {"string":"(","type":"startOfScope"},\
                {"string":")","type":"endOfScope"},\
                {"string":" ","type":"space"},\
                {"string":"{","type":"startOfScope"},\
                {"originalLine":2,"string":"\\n","type":"linebreak"},\
                {"string":"    ","type":"space"},\
                {"string":"bar","type":"identifier"},\
                {"string":"(","type":"startOfScope"},\
                {"string":")","type":"endOfScope"},\
                {"string":" ","type":"space"},\
                {"operatorType":"infix","string":"+","type":"operator"},\
                {"string":" ","type":"space"},\
                {"string":"baaz","type":"identifier"},\
                {"string":"(","type":"startOfScope"},\
                {"string":")","type":"endOfScope"},\
                {"string":" ","type":"space"},\
                {"operatorType":"infix","string":"+","type":"operator"},\
                {"string":" ","type":"space"},\
                {"numberType":"integer","string":"25","type":"number"},\
                {"originalLine":3,"string":"\\n","type":"linebreak"},\
                {"string":"}","type":"endOfScope"},\
                {"originalLine":4,"string":"\\n","type":"linebreak"}\
                ],"version":"\(swiftFormatVersion)"}
                """)
            case .error, .warning:
                XCTFail()
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo()\n"
            case 2:
                return "{\n"
            case 3:
                return "bar() + baaz() + 25\n"
            case 4:
                return "}"
            default:
                return nil
            }
        }

        _ = processArguments(["", "stdin", "--outputtokens"], in: "")
    }

    func testExcludeStdinPath() throws {
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                XCTAssertEqual(message, "func foo() {\n}\n")
            case .error, .warning:
                XCTFail()
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo() {\n"
            case 2:
                return "}\n"
            default:
                return nil
            }
        }
        try withTmpFile(contents: "") { url in
            _ = processArguments([
                "",
                "stdin",
                "--stdinpath", url.path,
                "--exclude", url.path,
            ], in: "")
        }
    }

    func testExcludeStdinPath2() throws {
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                XCTAssertEqual(message, "func foo() {\n}\n")
            case .error, .warning:
                XCTFail()
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo() {\n"
            case 2:
                return "}\n"
            default:
                return nil
            }
        }
        try withTmpFiles([
            ".swiftformat": "--exclude *",
            "foo.swift": "",
        ]) { url in
            _ = processArguments([
                "",
                "stdin",
                "--stdinpath", url.path,
            ], in: "")
        }
    }

    func testExcludeStdinPath3() throws {
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                XCTAssertEqual(message, "func foo() {\n}\n")
            case .error, .warning:
                XCTFail()
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo() {\n"
            case 2:
                return "}\n"
            default:
                return nil
            }
        }
        try withTmpFiles([
            ".swiftformat": "--exclude foo",
            "foo/bar/baz.swift": "",
        ]) { url in
            _ = processArguments([
                "",
                "stdin",
                "--stdinpath", url.path,
            ], in: "")
        }
    }

    func testUnexcludeStdinPath() throws {
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                XCTAssertEqual(message, "func foo() {}\n")
            case .error, .warning:
                XCTFail()
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo() {\n"
            case 2:
                return "}\n"
            default:
                return nil
            }
        }
        try withTmpFiles([
            ".swiftformat": """
            --exclude foo
            --unexclude **/baz.*
            """,
            "foo/bar/baz.swift": "",
        ]) { url in
            _ = processArguments([
                "",
                "stdin",
                "--stdinpath", url.path,
            ], in: "")
        }
    }

    // MARK: help

    func testOptionsHelpText() {
        for option in Descriptors.all {
            XCTAssertFalse(
                option.help.contains("\n"),
                "Help for option --\(option.argumentName) contains linebreak"
            )
        }
    }

    func testHelpOptionsImplemented() {
        CLI.print = { message, _ in
            if message.hasPrefix("--") {
                let name = String(message["--".endIndex ..< message.endIndex]).components(separatedBy: " ")[0]
                XCTAssertTrue(commandLineArguments.contains(name), name)
            }
        }
        printHelp(as: .content)
    }

    func testHelpOptionsDocumented() {
        var arguments = Set(commandLineArguments).subtracting(deprecatedArguments)
        CLI.print = { allHelpMessage, _ in
            allHelpMessage
                .components(separatedBy: "\n")
                .forEach { message in
                    if message.hasPrefix("--") {
                        let name = String(message["--".endIndex ..< message.endIndex]).components(separatedBy: " ")[0]
                        XCTAssert(arguments.contains(name), "Unknown option --\(name) in help")
                        arguments.remove(name)
                    }
                }
        }
        printHelp(as: .content)
        printOptions(as: .content)
        XCTAssert(arguments.isEmpty, "\(arguments.joined(separator: ",")) not listed in help")
    }

    func testRedundantDefaultsInHelpOptionsDescriptions() {
        var descriptions = [String]()
        CLI.print = { message, _ in
            descriptions += message
                .components(separatedBy: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        printOptions(as: .content)
        for description in descriptions {
            XCTAssertFalse(description.contains("\"default\"") && description.contains("(default)"),
                           "Found both 'default' and '(default)' in option description: \(description)")
        }
    }

    func testHelpOptionFormatting() {
        let shortOption = OptionDescriptor(
            argumentName: "option",
            displayName: "option",
            help: "Short option description",
            keyPath: \.fragment
        )

        let mediumOption = OptionDescriptor(
            argumentName: "option-medium",
            displayName: "option-medium",
            help: "Option with a medium name and description length",
            keyPath: \.fragment
        )

        let optionWithArgs = OptionDescriptor(
            argumentName: "option-with-args",
            displayName: "option-with-args",
            help: "Option description with arguments:",
            keyPath: \.fragment
        )

        let longOption = OptionDescriptor(
            argumentName: "option-with-longer-name",
            displayName: "option-with-longer-name",
            help: """
            This is a longer option with a name over the original 16 character limit, \
            and a help text over the original 80 character limit.
            """,
            keyPath: \.fragment
        )

        CLI.print = { output, _ in
            guard !output.isEmpty else { return }
            XCTAssertEqual(output, """
            --option           Short option description
            --option-medium    Option with a medium name and description length
            --option-with-args Option description with arguments: "true" or "false" (default)
            --option-with-longer-name
                               This is a longer option with a name over the original 16 character limit, and a help text over the original 80 character limit.
            """)
        }

        printOptions([shortOption, mediumOption, optionWithArgs, longOption], as: .content)
    }

    // MARK: cache

    func testHashIsFasterThanFormatting() throws {
        let sourceFile = URL(fileURLWithPath: #file)
        let source = try String(contentsOf: sourceFile, encoding: .utf8)
        let hash = computeHash(source + ";")

        let hashTime = timeEvent { _ = computeHash(source) == hash }
        let formatTime = try timeEvent { _ = try format(source) }
        XCTAssertLessThan(hashTime, formatTime)
    }

    func testCacheHit() {
        let input = "let foo = bar"
        XCTAssertEqual(computeHash(input), computeHash(input))
    }

    func testCacheMiss() {
        let input = "let foo = bar"
        let output = "let foo = bar\n"
        XCTAssertNotEqual(computeHash(input), computeHash(output))
    }

    func testCachePotentialFalsePositive() {
        let input = "let foo = bar;"
        let output = "let foo = bar\n"
        XCTAssertNotEqual(computeHash(input), computeHash(output))
    }

    func testCachePotentialFalsePositive2() {
        let input = """
        import Foo
        import Bar

        """
        let output = """
        import Bar
        import Foo

        """
        XCTAssertNotEqual(computeHash(input), computeHash(output))
    }

    func testLegacyCacheIsMigratedToVersionedFormat() throws {
        try withTmpDirectory([
            "Input.swift": "let foo = bar\n",
        ]) { directory in
            let cacheURL = directory.appendingPathComponent("swiftformat.cache")
            let legacyCache = ["legacy-entry": "legacy-value"]
            try JSONEncoder().encode(legacyCache).write(to: cacheURL)
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Input.swift --rules indent --cache \(cacheURL.path) --quiet"
            ), .ok)

            let cache = try XCTUnwrap(
                JSONSerialization.jsonObject(with: Data(contentsOf: cacheURL)) as? [String: Any]
            )
            XCTAssertEqual(cache["version"] as? Int, 1)
            let entries = try XCTUnwrap(cache["entries"] as? [String: Any])
            let legacyEntry = try XCTUnwrap(entries["legacy-entry"] as? [String: Any])
            XCTAssertEqual(legacyEntry["formatting"] as? String, "legacy-value")
        }
    }

    func testProjectIndexReusesCachedSourceSummaryForUnchangedFile() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Type.swift": "public struct Foo {}",
            "Sources/App/Extension.swift": """
            extension Foo {
                public func bar() {}
            }
            """,
        ]) { directory in
            let extensionURL = directory.appendingPathComponent("Sources/App/Extension.swift")
            let cacheURL = directory.appendingPathComponent("swiftformat.cache")
            let arguments = "Sources/App/Extension.swift --rules redundantPublic --cache \(cacheURL.path) --quiet"
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)

            var cache = try XCTUnwrap(
                JSONSerialization.jsonObject(with: Data(contentsOf: cacheURL)) as? [String: Any]
            )
            var entries = try XCTUnwrap(cache["entries"] as? [String: Any])
            let typeKey = try XCTUnwrap(entries.keys.first(where: { $0.hasSuffix("/Type.swift") }))
            var typeEntry = try XCTUnwrap(entries[typeKey] as? [String: Any])
            var sourceIndex = try XCTUnwrap(typeEntry["sourceIndex"] as? [String: Any])
            var declarations = try XCTUnwrap(sourceIndex["typeDeclarations"] as? [[String: Any]])
            declarations[0]["visibility"] = "internal"
            sourceIndex["typeDeclarations"] = declarations
            typeEntry["sourceIndex"] = sourceIndex
            entries[typeKey] = typeEntry
            cache["entries"] = entries
            try JSONSerialization.data(withJSONObject: cache).write(to: cacheURL)

            XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)
            XCTAssertEqual(try String(contentsOf: extensionURL), """
            extension Foo {
                func bar() {}
            }
            """)
        }
    }

    func testProjectIndexIsNotBuiltWhenEnabledRulesDoNotUseIt() throws {
        try withTmpDirectory([
            "Sources/App/Input.swift": "struct Foo {}\n",
            "Sources/App/Other.swift": "struct Bar {}\n",
        ]) { directory in
            let cacheURL = directory.appendingPathComponent("swiftformat.cache")
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Input.swift --rules indent --cache \(cacheURL.path) --quiet"
            ), .ok)

            let cache = try XCTUnwrap(
                JSONSerialization.jsonObject(with: Data(contentsOf: cacheURL)) as? [String: Any]
            )
            let entries = try XCTUnwrap(cache["entries"] as? [String: Any])
            XCTAssertEqual(entries.count, 1)
        }
    }

    func testProjectIndexCanBeDisabled() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Type.swift": "struct Foo {}",
            "Sources/App/Extension.swift": """
            extension Foo {
                public func bar() {}
            }
            """,
        ]) { directory in
            let extensionURL = directory.appendingPathComponent("Sources/App/Extension.swift")
            let input = try String(contentsOf: extensionURL)
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Extension.swift --rules redundantPublic --project-index disabled --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: extensionURL), input)
        }
    }

    func testProjectIndexIncludesFilesNotBeingFormatted() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Type.swift": "struct Foo {}",
            "Sources/App/Extension.swift": """
            extension Foo {
                public func bar() {}
            }
            """,
        ]) { directory in
            let extensionURL = directory.appendingPathComponent("Sources/App/Extension.swift")
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Extension.swift --rules redundantPublic --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: extensionURL), """
            extension Foo {
                func bar() {}
            }
            """)
        }
    }

    func testProjectIndexDoesNotCombineSwiftPackageTargets() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/Library/Type.swift": "struct Foo {}",
            "Sources/App/Extension.swift": """
            extension Foo {
                public func bar() {}
            }
            """,
        ]) { directory in
            let extensionURL = directory.appendingPathComponent("Sources/App/Extension.swift")
            let input = try String(contentsOf: extensionURL)
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Extension.swift --rules redundantPublic --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: extensionURL), input)
        }
    }

    func testProjectIndexUsesXcodeTargetMembership() throws {
        try withTmpDirectory([
            "App/Type.swift": "struct Foo {}\n",
            "App/Extension.swift": "extension Foo { public func bar() {} }\n",
            "Library/Type.swift": "public struct Foo {}\n",
            "Example.xcodeproj/project.pbxproj": """
            // !$*UTF8*$!
            {
                objects = {
                    APP_TYPE_REF = { isa = PBXFileReference; path = Type.swift; sourceTree = "<group>"; };
                    APP_EXTENSION_REF = { isa = PBXFileReference; path = Extension.swift; sourceTree = "<group>"; };
                    LIBRARY_TYPE_REF = { isa = PBXFileReference; path = Type.swift; sourceTree = "<group>"; };
                    APP_TYPE_BUILD = { isa = PBXBuildFile; fileRef = APP_TYPE_REF; };
                    APP_EXTENSION_BUILD = { isa = PBXBuildFile; fileRef = APP_EXTENSION_REF; };
                    LIBRARY_TYPE_BUILD = { isa = PBXBuildFile; fileRef = LIBRARY_TYPE_REF; };
                    ROOT_GROUP = {
                        isa = PBXGroup;
                        children = (APP_GROUP, LIBRARY_GROUP,);
                        sourceTree = "<group>";
                    };
                    APP_GROUP = {
                        isa = PBXGroup;
                        children = (APP_TYPE_REF, APP_EXTENSION_REF,);
                        path = App;
                        sourceTree = "<group>";
                    };
                    LIBRARY_GROUP = {
                        isa = PBXGroup;
                        children = (LIBRARY_TYPE_REF,);
                        path = Library;
                        sourceTree = "<group>";
                    };
                    APP_SOURCES = {
                        isa = PBXSourcesBuildPhase;
                        files = (APP_TYPE_BUILD, APP_EXTENSION_BUILD,);
                    };
                    LIBRARY_SOURCES = {
                        isa = PBXSourcesBuildPhase;
                        files = (LIBRARY_TYPE_BUILD,);
                    };
                    APP_TARGET = { isa = PBXNativeTarget; buildPhases = (APP_SOURCES,); name = App; };
                    LIBRARY_TARGET = { isa = PBXNativeTarget; buildPhases = (LIBRARY_SOURCES,); name = Library; };
                };
            }
            """,
        ]) { directory in
            let extensionURL = directory.appendingPathComponent("App/Extension.swift")
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "App/Extension.swift --rules redundantPublic --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: extensionURL), "extension Foo { func bar() {} }\n")
        }
    }

    func testProjectIndexChangeInvalidatesFormattingCache() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Type.swift": "public struct Foo {}",
            "Sources/App/Extension.swift": """
            extension Foo {
                public func bar() {}
            }
            """,
        ]) { directory in
            let typeURL = directory.appendingPathComponent("Sources/App/Type.swift")
            let extensionURL = directory.appendingPathComponent("Sources/App/Extension.swift")
            let cacheURL = directory.appendingPathComponent("swiftformat.cache")
            let arguments = "Sources/App/Extension.swift --rules redundantPublic --cache \(cacheURL.path) --quiet"
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)
            XCTAssertEqual(try String(contentsOf: extensionURL), """
            extension Foo {
                public func bar() {}
            }
            """)

            try "struct Foo {}".write(to: typeURL, atomically: true, encoding: .utf8)

            XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)
            XCTAssertEqual(try String(contentsOf: extensionURL), """
            extension Foo {
                func bar() {}
            }
            """)
        }
    }

    func testProjectIndexPreservesSelfInProjectAutoclosureCall() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Autoclosure.swift": """
            func verify(_ expression: @autoclosure () -> Bool) {}
            """,
            "Sources/App/Use.swift": """
            class Foo {
                let value = true
                func run() {
                    verify(self.value)
                }
            }
            """,
        ]) { directory in
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            let input = try String(contentsOf: useURL)
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Use.swift --rules redundantSelf --swift-version 5.4 --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), input)
        }
    }

    func testProjectIndexDoesNotPreserveSelfForAutoclosureInAnotherModule() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/Library/Autoclosure.swift": """
            func verify(_ expression: @autoclosure () -> Bool) {}
            """,
            "Sources/App/Use.swift": """
            class Foo {
                let value = true
                func run() {
                    verify(self.value)
                }
            }
            """,
        ]) { directory in
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Use.swift --rules redundantSelf --swift-version 5.4 --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), """
            class Foo {
                let value = true
                func run() {
                    verify(value)
                }
            }
            """)
        }
    }

    func testDisabledProjectIndexDoesNotPreserveSelfInProjectAutoclosureCall() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Autoclosure.swift": """
            func verify(_ expression: @autoclosure () -> Bool) {}
            """,
            "Sources/App/Use.swift": """
            class Foo {
                let value = true
                func run() {
                    verify(self.value)
                }
            }
            """,
        ]) { directory in
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Use.swift --rules redundantSelf --swift-version 5.4 --project-index disabled --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), """
            class Foo {
                let value = true
                func run() {
                    verify(value)
                }
            }
            """)
        }
    }

    func testProjectIndexInsertsSelfForMembersDeclaredInOtherFiles() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Type.swift": """
            struct Foo {
                var value = 0
                static var shared = 0
                func update() {}
            }
            """,
            "Sources/App/Members.swift": """
            extension Foo {
                func extensionMethod() {}
            }
            """,
            "Sources/App/Use.swift": """
            var globalValue = 0
            func globalFunction() {}

            extension Foo {
                mutating func run() {
                    value += 1
                    update()
                    extensionMethod()
                    globalValue += 1
                    globalFunction()
                }

                static func reset() {
                    shared = 0
                }

                func shadowed() {
                    let value = 1
                    print(value)
                }
            }
            """,
        ]) { directory in
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Use.swift --rules redundantSelf --self insert --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), """
            var globalValue = 0
            func globalFunction() {}

            extension Foo {
                mutating func run() {
                    self.value += 1
                    self.update()
                    self.extensionMethod()
                    globalValue += 1
                    globalFunction()
                }

                static func reset() {
                    self.shared = 0
                }

                func shadowed() {
                    let value = 1
                    print(value)
                }
            }
            """)
        }
    }

    func testProjectIndexInsertsSelfInQualifiedExtension() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Type.swift": """
            struct Outer {
                struct Inner {
                    var value = 0
                }
            }
            """,
            "Sources/App/Use.swift": """
            extension Outer.Inner {
                mutating func update() {
                    value = 1
                }
            }
            """,
        ]) { directory in
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Use.swift --rules redundantSelf --self insert --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), """
            extension Outer.Inner {
                mutating func update() {
                    self.value = 1
                }
            }
            """)
        }
    }

    func testProjectIndexDoesNotInsertSelfForMemberInAnotherModule() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/Library/Type.swift": "struct Foo { var value = 0 }",
            "Sources/App/Use.swift": """
            extension Foo {
                func update() {
                    value = 1
                }
            }
            """,
        ]) { directory in
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            let input = try String(contentsOf: useURL)
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Use.swift --rules redundantSelf --self insert --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), input)
        }
    }

    func testDisabledProjectIndexDoesNotInsertSelfForMemberInOtherFile() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Type.swift": "struct Foo { var value = 0 }",
            "Sources/App/Use.swift": """
            extension Foo {
                func update() {
                    value = 1
                }
            }
            """,
        ]) { directory in
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            let input = try String(contentsOf: useURL)
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(
                in: directory.path,
                with: "Sources/App/Use.swift --rules redundantSelf --self insert --project-index disabled --cache ignore --quiet"
            ), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), input)
        }
    }

    func testProjectMemberChangeInvalidatesFormattingCache() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Type.swift": "struct Foo {}",
            "Sources/App/Use.swift": """
            extension Foo {
                func update() {
                    value = 1
                }
            }
            """,
        ]) { directory in
            let typeURL = directory.appendingPathComponent("Sources/App/Type.swift")
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            let cacheURL = directory.appendingPathComponent("swiftformat.cache")
            let arguments = "Sources/App/Use.swift --rules redundantSelf --self insert --cache \(cacheURL.path) --quiet"
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), """
            extension Foo {
                func update() {
                    value = 1
                }
            }
            """)

            try "struct Foo { var value = 0 }".write(to: typeURL, atomically: true, encoding: .utf8)

            XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), """
            extension Foo {
                func update() {
                    self.value = 1
                }
            }
            """)
        }
    }

    func testAutoclosureChangeInvalidatesFormattingCache() throws {
        try withTmpDirectory([
            "Package.swift": "// Package marker",
            "Sources/App/Autoclosure.swift": """
            func verify(_ expression: @autoclosure () -> Bool) {}
            """,
            "Sources/App/Use.swift": """
            class Foo {
                let value = true
                func run() {
                    verify(self.value)
                }
            }
            """,
        ]) { directory in
            let autoclosureURL = directory.appendingPathComponent("Sources/App/Autoclosure.swift")
            let useURL = directory.appendingPathComponent("Sources/App/Use.swift")
            let cacheURL = directory.appendingPathComponent("swiftformat.cache")
            let arguments = "Sources/App/Use.swift --rules redundantSelf --swift-version 5.4 --cache \(cacheURL.path) --quiet"
            CLI.print = { _, _ in }

            XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)
            try "func verify(_ expression: () -> Bool) {}".write(
                to: autoclosureURL,
                atomically: true,
                encoding: .utf8
            )
            XCTAssertEqual(CLI.run(in: directory.path, with: arguments), .ok)
            XCTAssertEqual(try String(contentsOf: useURL), """
            class Foo {
                let value = true
                func run() {
                    verify(value)
                }
            }
            """)
        }
    }

    func testCreatesSnapshotWithoutFormattingFiles() throws {
        let firstInput = """
        let foo=bar
        """
        let secondInput = """
        let baz=quux
        """
        try withTmpDirectory([
            "Sources/z.swift": secondInput,
            "Sources/a.swift": firstInput,
        ]) { directory in
            let firstInputURL = directory.appendingPathComponent("Sources/a.swift")
            let secondInputURL = directory.appendingPathComponent("Sources/z.swift")
            let snapshotURL = directory.appendingPathComponent(".swiftformat-snapshot")
            CLI.print = { _, _ in }

            XCTAssertEqual(processArguments([
                "", directory.path,
                "--snapshot",
                "--cache", "ignore",
                "--rules", "spaceAroundOperators",
            ], in: ""), .ok)

            XCTAssertEqual(try String(contentsOf: firstInputURL), firstInput)
            XCTAssertEqual(try String(contentsOf: secondInputURL), secondInput)
            let snapshotJSON = try String(contentsOf: snapshotURL)
            XCTAssertEqual(snapshotJSON, """
            {
              "files" : {
                "Sources/a.swift" : "\(computeHash(firstInput))",
                "Sources/z.swift" : "\(computeHash(secondInput))"
              },
              "version" : 1
            }
            """)
            let snapshot = try readSnapshot(at: snapshotURL)
            XCTAssertEqual(snapshot.version, 1)
            XCTAssertEqual(snapshot.files, [
                "Sources/a.swift": computeHash(firstInput),
                "Sources/z.swift": computeHash(secondInput),
            ])
        }
    }

    func testDefaultSnapshotUsesCommonInputRoot() throws {
        let sourceInput = """
        let foo = bar
        """
        let testInput = """
        let baz = quux
        """
        try withTmpDirectory([
            "Sources/foo.swift": sourceInput,
            "Tests/foo.swift": testInput,
        ]) { directory in
            let sourcesURL = directory.appendingPathComponent("Sources")
            let testsURL = directory.appendingPathComponent("Tests")
            let snapshotURL = directory.appendingPathComponent(".swiftformat-snapshot")
            CLI.print = { _, _ in }

            XCTAssertEqual(processArguments([
                "", sourcesURL.path, testsURL.path,
                "--snapshot",
                "--project-index", "disabled",
                "--cache", "ignore",
            ], in: ""), .ok)
            XCTAssertEqual(try readSnapshot(at: snapshotURL).files, [
                "Sources/foo.swift": computeHash(sourceInput),
                "Tests/foo.swift": computeHash(testInput),
            ])
        }
    }

    func testDefaultSnapshotForFileUsesContainingDirectory() throws {
        let input = """
        let foo = bar
        """
        try withTmpDirectory(["Sources/foo.swift": input]) { directory in
            let inputURL = directory.appendingPathComponent("Sources/foo.swift")
            let snapshotURL = directory.appendingPathComponent("Sources/.swiftformat-snapshot")
            CLI.print = { _, _ in }

            XCTAssertEqual(processArguments([
                "", inputURL.path,
                "--snapshot",
                "--project-index", "disabled",
                "--cache", "ignore",
            ], in: ""), .ok)
            XCTAssertEqual(try readSnapshot(at: snapshotURL).files, [
                "foo.swift": computeHash(input),
            ])
        }
    }

    func testAutomaticallyDetectsAndLogsSnapshot() throws {
        let input = """
        let foo=bar
        """
        try withTmpDirectory([
            "foo.swift": input,
            ".swiftformat-snapshot": """
            {"version":1,"files":{"foo.swift":"\(computeHash(input))"}}
            """,
        ]) { directory in
            let inputURL = directory.appendingPathComponent("foo.swift")
            let snapshotURL = directory.appendingPathComponent(".swiftformat-snapshot")
            var messages = [String]()
            CLI.print = { message, _ in messages.append(message) }

            XCTAssertEqual(processArguments([
                "", directory.path,
                "--cache", "ignore",
                "--rules", "spaceAroundOperators",
            ], in: ""), .ok)
            XCTAssertEqual(try String(contentsOf: inputURL), input)
            XCTAssertTrue(messages.contains("Reading snapshot file at \(snapshotURL.path)"))
        }
    }

    func testClosestSnapshotIsUsedWithoutBeingUpdated() throws {
        let nestedInput = """
        let nested=value
        """
        let nestedOutput = """
        let nested = value
        """
        let rootSnapshot = """
        {"version":1,"files":{"Nested/nested.swift":"root-value"}}
        """
        let nestedSnapshot = """
        {"version":1,"files":{"nested.swift":"old-value"}}
        """
        try withTmpDirectory([
            "Nested/nested.swift": nestedInput,
            ".swiftformat-snapshot": rootSnapshot,
            "Nested/.swiftformat-snapshot": nestedSnapshot,
        ]) { directory in
            let nestedInputURL = directory.appendingPathComponent("Nested/nested.swift")
            let rootSnapshotURL = directory.appendingPathComponent(".swiftformat-snapshot")
            let nestedSnapshotURL = directory.appendingPathComponent("Nested/.swiftformat-snapshot")
            var messages = [String]()
            CLI.print = { message, _ in messages.append(message) }

            XCTAssertEqual(processArguments([
                "", directory.path,
                "--cache", "ignore",
                "--rules", "spaceAroundOperators",
            ], in: ""), .ok)
            XCTAssertEqual(try String(contentsOf: nestedInputURL), nestedOutput)
            XCTAssertEqual(try readSnapshot(at: rootSnapshotURL).files, [
                "Nested/nested.swift": "root-value",
            ])
            XCTAssertEqual(try readSnapshot(at: nestedSnapshotURL).files, [
                "nested.swift": "old-value",
            ])
            XCTAssertEqual(try String(contentsOf: rootSnapshotURL), rootSnapshot)
            XCTAssertEqual(try String(contentsOf: nestedSnapshotURL), nestedSnapshot)
            XCTAssertTrue(messages.contains("Reading snapshot file at \(rootSnapshotURL.path)"))
            XCTAssertTrue(messages.contains("Reading snapshot file at \(nestedSnapshotURL.path)"))
        }
    }

    func testInvalidAutomaticallyDetectedSnapshotPreventsFormatting() throws {
        let rootInput = """
        let root=value
        """
        let nestedInput = """
        let nested=value
        """
        try withTmpDirectory([
            "root.swift": rootInput,
            "Nested/nested.swift": nestedInput,
            "Nested/.swiftformat-snapshot": "not json",
        ]) { directory in
            let rootInputURL = directory.appendingPathComponent("root.swift")
            CLI.print = { _, _ in }

            XCTAssertEqual(processArguments([
                "", directory.path,
                "--cache", "ignore",
                "--rules", "spaceAroundOperators",
            ], in: ""), .error)
            XCTAssertEqual(try String(contentsOf: rootInputURL), rootInput)
        }
    }

    func testCreatesEmptySnapshotWhenThereAreNoEligibleFiles() throws {
        try withTmpDirectory([:]) { directory in
            let snapshotURL = directory.appendingPathComponent("snapshot.json")
            CLI.print = { _, _ in }

            XCTAssertEqual(processArguments([
                "", directory.path,
                "--snapshot", snapshotURL.path,
                "--cache", "ignore",
            ], in: ""), .ok)
            XCTAssertEqual(try readSnapshot(at: snapshotURL).files, [:])
        }
    }

    func testSnapshotFormatsChangedAndNewFilesWithoutUpdatingHashes() throws {
        let original = """
        let foo = bar
        """
        let changed = """
        let foo=bar
        """
        let formatted = """
        let foo = bar
        """
        let new = """
        let baz=quux
        """
        let formattedNew = """
        let baz = quux
        """
        try withTmpDirectory(["foo.swift": original]) { directory in
            let inputURL = directory.appendingPathComponent("foo.swift")
            let newInputURL = directory.appendingPathComponent("new.swift")
            let snapshotURL = directory.appendingPathComponent("snapshot.json")
            let arguments = [
                "", directory.path,
                "--snapshot", snapshotURL.path,
                "--cache", "ignore",
                "--rules", "spaceAroundOperators",
            ]
            CLI.print = { _, _ in }
            XCTAssertEqual(processArguments(arguments, in: ""), .ok)

            try changed.write(to: inputURL, atomically: true, encoding: .utf8)
            try new.write(to: newInputURL, atomically: true, encoding: .utf8)
            XCTAssertEqual(processArguments(arguments, in: ""), .ok)

            XCTAssertEqual(try String(contentsOf: inputURL), formatted)
            XCTAssertEqual(try String(contentsOf: newInputURL), formattedNew)
            let snapshot = try readSnapshot(at: snapshotURL)
            XCTAssertEqual(snapshot.files, [
                "foo.swift": computeHash(original),
            ])
        }
    }

    func testSnapshotDoesNotRecordLintFailures() throws {
        let original = """
        let foo = bar
        """
        let changed = """
        let foo=bar
        """
        try withTmpDirectory(["foo.swift": original]) { directory in
            let inputURL = directory.appendingPathComponent("foo.swift")
            let snapshotURL = directory.appendingPathComponent("snapshot.json")
            let arguments = [
                "", directory.path,
                "--snapshot", snapshotURL.path,
                "--cache", "ignore",
                "--rules", "spaceAroundOperators",
            ]
            CLI.print = { _, _ in }
            XCTAssertEqual(processArguments(arguments, in: ""), .ok)

            try changed.write(to: inputURL, atomically: true, encoding: .utf8)
            XCTAssertEqual(processArguments(arguments + ["--lint"], in: ""), .lintFailure)
            XCTAssertEqual(try String(contentsOf: inputURL), changed)
            XCTAssertEqual(try readSnapshot(at: snapshotURL).files, [
                "foo.swift": computeHash(original),
            ])
        }
    }

    func testInvalidSnapshotPreventsFormatting() throws {
        let input = """
        let foo=bar
        """
        try withTmpDirectory([
            "foo.swift": input,
            "snapshot.json": "not json",
        ]) { directory in
            let inputURL = directory.appendingPathComponent("foo.swift")
            let snapshotURL = directory.appendingPathComponent("snapshot.json")
            CLI.print = { _, _ in }

            XCTAssertEqual(processArguments([
                "", directory.path,
                "--snapshot", snapshotURL.path,
                "--cache", "ignore",
                "--rules", "spaceAroundOperators",
            ], in: ""), .error)
            XCTAssertEqual(try String(contentsOf: inputURL), input)
        }
    }

    func testUnsupportedSnapshotVersionPreventsFormatting() throws {
        let input = """
        let foo=bar
        """
        try withTmpDirectory([
            "foo.swift": input,
            "snapshot.json": #"{"version":2,"files":{}}"#,
        ]) { directory in
            let inputURL = directory.appendingPathComponent("foo.swift")
            let snapshotURL = directory.appendingPathComponent("snapshot.json")
            CLI.print = { _, _ in }

            XCTAssertEqual(processArguments([
                "", directory.path,
                "--snapshot", snapshotURL.path,
                "--cache", "ignore",
                "--rules", "spaceAroundOperators",
            ], in: ""), .error)
            XCTAssertEqual(try String(contentsOf: inputURL), input)
        }
    }

    func testDryRunDoesNotUpdateSnapshot() throws {
        let original = """
        let foo = bar
        """
        let changed = """
        let baz = quux
        """
        try withTmpDirectory(["foo.swift": original]) { directory in
            let inputURL = directory.appendingPathComponent("foo.swift")
            let snapshotURL = directory.appendingPathComponent("snapshot.json")
            let arguments = [
                "", directory.path,
                "--snapshot", snapshotURL.path,
                "--project-index", "disabled",
                "--cache", "ignore",
            ]
            CLI.print = { _, _ in }
            XCTAssertEqual(processArguments(arguments, in: ""), .ok)

            try changed.write(to: inputURL, atomically: true, encoding: .utf8)
            XCTAssertEqual(processArguments(arguments + ["--dry-run"], in: ""), .ok)
            XCTAssertEqual(try readSnapshot(at: snapshotURL).files, [
                "foo.swift": computeHash(original),
            ])
        }
    }

    func testSnapshotCannotBeCombinedWithOutputOrLineRange() throws {
        let input = """
        let foo = bar
        """
        try withTmpDirectory(["foo.swift": input]) { directory in
            let inputURL = directory.appendingPathComponent("foo.swift")
            let snapshotURL = directory.appendingPathComponent("snapshot.json")
            let outputURL = directory.appendingPathComponent("output.swift")
            CLI.print = { _, _ in }

            XCTAssertEqual(processArguments([
                "", inputURL.path,
                "--snapshot", snapshotURL.path,
                "--output", outputURL.path,
            ], in: ""), .error)
            XCTAssertEqual(processArguments([
                "", inputURL.path,
                "--snapshot", snapshotURL.path,
                "--line-range", "1,1",
            ], in: ""), .error)
        }
    }

    // MARK: rules

    func testRulesNotMarkedAsDisabled() {
        CLI.print = { message, _ in
            XCTAssert(!message.contains("(disabled by default)") ||
                FormatRules.disabledByDefault.contains(where: { message.contains($0.name) }))
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "--rules"), .ok)
    }

    func testEnableOverridesDisableAll() {
        CLI.print = { message, _ in
            XCTAssertFalse(message.contains("wrap (disabled)"))
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path,
                               with: "--disable all --enable wrap --rules"), .ok)
    }

    func testRulesAnnotations() throws {
        var messages = [String]()
        CLI.print = { message, _ in
            messages.append(message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "--rules"), .ok)
        for name in FormatRules.all.map(\.name) {
            let rule = try XCTUnwrap(FormatRules.byName[name])
            let matchingMessage = messages.first(where: { $0.contains(name) })
            XCTAssertNotNil(matchingMessage, "Rule \(name) should appear in --rules output")
            if rule.isDeprecated {
                XCTAssert(matchingMessage?.contains("(deprecated)") == true,
                          "Rule \(name) should be marked (deprecated)")
            } else if rule.disabledByDefault {
                XCTAssert(matchingMessage?.contains("(disabled by default)") == true,
                          "Rule \(name) should be marked (disabled by default)")
            } else {
                XCTAssert(matchingMessage?.contains("(enabled by default)") == true,
                          "Rule \(name) should be marked (enabled by default)")
            }
        }
    }

    // MARK: quiet mode

    func testQuietModeNoOutput() {
        CLI.print = { message, _ in
            XCTFail(message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "--quiet --dry-run"), .ok)
    }

    func testQuietModeAllowsContent() {
        CLI.print = { message, type in
            XCTAssertEqual(type, .content, message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "--quiet --help"), .ok)
    }

    func testQuietModeAllowsErrors() {
        CLI.print = { message, type in
            XCTAssertEqual(type, .error, message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "foobar.swift --quiet"), .error)
    }

    // MARK: split input paths

    func testSplitInputPaths() {
        CLI.print = { message, type in
            XCTAssertEqual(type, .error, message)
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Sources --dry-run Tests --rules indent"), .error)
    }

    // MARK: file list

    func testParseFileList() {
        let source = """
        #foo
        Package.swift #bar

        #baz
        Sources/FormatRule.swift
        CommandLineTool/*.swift
        """
        XCTAssertEqual(try parseFileList(source, in: projectDirectory.path), [
            URL(fileURLWithPath: "\(projectDirectory.path)/Package.swift"),
            URL(fileURLWithPath: "\(projectDirectory.path)/Sources/FormatRule.swift"),
            URL(fileURLWithPath: "\(projectDirectory.path)/CommandLineTool/main.swift"),
        ])
    }

    // MARK: script input files

    func testParseScriptInput() throws {
        let result = try parseScriptInput(from: [
            "SCRIPT_INPUT_FILE_COUNT": "2",
            "SCRIPT_INPUT_FILE_0": "\(projectDirectory.path)/File1.swift",
            "SCRIPT_INPUT_FILE_1": "\(projectDirectory.path)/File2.swift",
        ])
        XCTAssertEqual(
            result,
            [
                URL(fileURLWithPath: "\(projectDirectory.path)/File1.swift"),
                URL(fileURLWithPath: "\(projectDirectory.path)/File2.swift"),
            ]
        )
    }

    // MARK: config

    func testBadConfigFails() {
        var error = ""
        CLI.print = { message, type in
            if type == .error {
                error += message + "\n"
            }
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Tests/BadConfig/Test.swift --unexclude Tests/BadConfig --config Tests/BadConfig/.swiftformat --lint"), .error)
        XCTAssert(error.contains("'ifdef' is not a formatting rule"), error)
    }

    func testBadConfigFails2() {
        var error = ""
        CLI.print = { message, type in
            if type == .error {
                error += message + "\n"
            }
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "Tests/BadConfig/Test.swift --unexclude Tests/BadConfig --lint"), .error)
        XCTAssert(error.contains("'ifdef' is not a formatting rule"), error)
    }

    func testWarnIfOptionsSpecifiedForDisabledRule() {
        CLI.print = { message, type in
            if type == .warning {
                XCTAssertEqual(
                    message,
                    "warning: --header option has no effect when fileHeader rule is disabled"
                )
            }
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "stdin --lint --rules indent --header foo"), .ok)
    }

    func testWarnIfEnableUsedForDefaultRule() {
        var warnings = [String]()
        CLI.print = { message, type in
            if type == .warning {
                warnings.append(message)
            }
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "stdin --lint --enable redundantSelf"), .ok)
        XCTAssert(warnings.contains(where: { $0.contains("--enable redundantSelf is redundant") }))
        XCTAssert(warnings.contains(where: { $0.contains("--rules") }))
    }

    func testNoWarnIfRulesUsedForDefaultRule() {
        var warnings = [String]()
        CLI.print = { message, type in
            if type == .warning {
                warnings.append(message)
            }
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "stdin --lint --rules redundantSelf"), .ok)
        XCTAssertEqual(warnings.count, 0)
    }

    func testWarnIfDisableUsedForOptInRule() {
        var warnings = [String]()
        CLI.print = { message, type in
            if type == .warning {
                warnings.append(message)
            }
        }
        XCTAssertEqual(CLI.run(in: projectDirectory.path, with: "stdin --lint --disable isEmpty"), .ok)
        XCTAssert(warnings.contains(where: { $0.contains("--disable isEmpty is redundant") }))
        XCTAssert(warnings.contains(where: { $0.contains("--rules") }))
    }

    func testMultipleConfigFiles() throws {
        try withTmpFiles([
            "config1.swiftformat": """
            --indent 2
            --rules trailingCommas
            --rules redundantSelf
            """,
            "config2.swiftformat": """
            --indent 4
            --disable trailingCommas
            """,
            "test.swift": """
            func foo() {
                let array = [1, 2, 3,]
                self.bar()
            }
            """,
        ]) { url in
            guard url.pathExtension == "swift" else { return }
            let testDir = url.deletingLastPathComponent().path

            CLI.print = { _, _ in }

            XCTAssertEqual(
                CLI.run(in: testDir, with: "test.swift --config config1.swiftformat --config config2.swiftformat --project-index disabled"),
                .ok
            )

            let output = try String(contentsOf: url, encoding: .utf8)

            XCTAssertEqual(output, """
            func foo() {
                let array = [1, 2, 3,]
                bar()
            }
            """)
        }
    }

    func testMultipleConfigFilesWithCommaDelimitedPaths() throws {
        try withTmpFiles([
            "config1.swiftformat": """
            --indent 2
            --rules trailingCommas
            --rules redundantSelf
            """,
            "config2.swiftformat": """
            --indent 4
            --disable trailingCommas
            """,
            "test.swift": """
            func foo() {
                let array = [1, 2, 3,]
                self.bar()
            }
            """,
        ]) { url in
            guard url.pathExtension == "swift" else { return }
            let testDir = url.deletingLastPathComponent().path

            CLI.print = { _, _ in }

            XCTAssertEqual(
                CLI.run(in: testDir, with: "test.swift --config config1.swiftformat,config2.swiftformat --project-index disabled"),
                .ok
            )

            let output = try String(contentsOf: url, encoding: .utf8)

            XCTAssertEqual(output, """
            func foo() {
                let array = [1, 2, 3,]
                bar()
            }
            """)
        }
    }

    func testConfigFileIsReadOnceWhenGatheringOptionsConcurrently() throws {
        try withTmpFiles([
            ".swiftformat": """
            --rules indent
            """,
            "File.swift": """
            let value = 0
            """,
        ]) { url in
            guard url.pathExtension == "swift" else { return }

            let configFile = url.deletingLastPathComponent().appendingPathComponent(".swiftformat")
            var logMessages = [String]()
            var errors = [Error]()
            let logQueue = DispatchQueue(label: "swiftformat.test.config-log")

            DispatchQueue.concurrentPerform(iterations: 50) { _ in
                var options = Options.default
                do {
                    try gatherOptions(&options, for: url, with: Logger { message, type in
                        if type == .info {
                            logQueue.sync { logMessages.append(message) }
                        }
                    })
                } catch {
                    logQueue.sync { errors.append(error) }
                }
            }

            let messages = logMessages.filter { $0 == "Reading config file at \(configFile.path)" }
            XCTAssertEqual(messages.count, 1, "\(messages)")
            XCTAssertTrue(errors.isEmpty, "\(errors)")
        }
    }

    func testLintCommandOutputsOrganizeDeclarationOrderingViolations() {
        var output: [String] = []
        CLI.print = { message, _ in
            output.append(message)
        }

        let input = """
        struct Test {
            func test() {
                print("Test")
            }
            var foo: Foo
            func bar() {
                print("Bar")
            }
        }
        """

        let lines = input.components(separatedBy: "\n").map { $0 + "\n" }

        var readCount = 0
        CLI.readLine = {
            guard readCount < lines.count else { return nil }
            defer { readCount += 1 }
            return lines[readCount]
        }

        _ = processArguments(["", "stdin", "--lint", "--rules", "organizeDeclarations"], in: "")

        XCTAssertEqual(output, [
            "Running SwiftFormat...",
            "(lint mode - no files will be changed.)",
            ":2:1: error: (organizeDeclarations) Organize declarations within class, struct, enum, actor, and extension bodies.",
            ":5:1: error: (organizeDeclarations) Organize declarations within class, struct, enum, actor, and extension bodies.",
            "Source input did not pass lint check.",
        ])
    }

    func testTrailingCommasCollectionsOnlyDoesNotTriggerDeprecationWarning_issue_2141() throws {
        var warnings = [String]()
        CLI.print = { message, type in
            if type == .warning {
                warnings.append(message)
            }
        }

        try withTmpFiles([
            "foo/bar/baz.swift": "",
        ]) { url in
            _ = processArguments(["", url.path, "--trailing-commas", "collections-only", "--swift-version", "6.0", "--project-index", "disabled"], in: "")
        }

        // Should not contain the deprecation warning about --commas
        XCTAssertEqual(warnings, [])
    }

    func testFilterMatchingFileNameAppliesPerFileWithinDirectory() throws {
        CLI.print = { _, _ in }

        let configURL = try createTmpFile("Test/config.swiftformat", contents: """
        --rules indent
        --indent 1
        """)

        let testsConfigURL = try createTmpFile("Test/tests.swiftformat", contents: """
        --filter **Tests.swift
        --indent 4
        """)

        let sourceFile = try createTmpFile("Test/Foo/Foo.swift", contents: """
        func foo() {
        print("bar")
        }
        """)

        let testFile = try createTmpFile("Test/Foo/FooTests.swift", contents: """
        func foo() {
        print("bar")
        }
        """)

        _ = processArguments([
            "",
            configURL.deletingLastPathComponent().path,
            "--config", configURL.path,
            "--config", testsConfigURL.path,
        ], in: "")

        XCTAssertEqual(try String(contentsOf: sourceFile, encoding: .utf8), """
        func foo() {
         print("bar")
        }
        """)

        XCTAssertEqual(try String(contentsOf: testFile, encoding: .utf8), """
        func foo() {
            print("bar")
        }
        """)
    }

    func testConfigFilesWithFilter() throws {
        var errors = [String]()

        CLI.print = { message, type in
            print(message)
            if type == .error {
                errors.append(message)
            }
        }

        let configURL = try createTmpFile("Test/config.swiftformat", contents: """
        --rules indent
        --rules braces
        --indent 1
        """)

        let testsConfigURL = try createTmpFile("Test/tests.swiftformat", contents: """
        --filter **/Tests/**
        --indent 2
        --enable linebreakAtEndOfFile
        """)

        let toolsConfigURL = try createTmpFile("Test/tools.swiftformat", contents: """
        --filter **/Tools/**
        --indent 3
        --disable braces
        """)

        let nonTestFile = try createTmpFile("Test/Foo/Sources/Foo.swift", contents: """
        func foo()
        {
        print("bar")
        }
        """)

        let testFile = try createTmpFile("Test/Foo/Tests/FooTests.swift", contents: """
        func foo()
        {
        print("bar")
        }
        """)

        let toolsFile = try createTmpFile("Test/Tools/MyTool/FooTool.swift", contents: """
        func foo()
        {
        print("bar")
        }
        """)

        _ = processArguments([
            "",
            configURL.deletingLastPathComponent().path,
            "--config", configURL.path,
            "--config", testsConfigURL.path,
            "--config", toolsConfigURL.path,
        ], in: "")

        XCTAssertEqual(try String(contentsOf: nonTestFile, encoding: .utf8), """
        func foo() {
         print("bar")
        }
        """)

        XCTAssertEqual(try String(contentsOf: testFile, encoding: .utf8), """
        func foo() {
          print("bar")
        }

        """)

        XCTAssertEqual(try String(contentsOf: toolsFile, encoding: .utf8), """
        func foo()
        {
           print("bar")
        }
        """)

        let tempFiles = [configURL, testsConfigURL, toolsConfigURL, nonTestFile, testFile, toolsFile]
        for tempFile in tempFiles {
            try FileManager.default.removeItem(at: tempFile)
        }

        XCTAssertEqual(errors, [])
    }

    func testSingleConfigFileWithFilters() throws {
        var errors = [String]()

        CLI.print = { message, type in
            print(message)
            if type == .error {
                errors.append(message)
            }
        }

        let configURL = try createTmpFile("Test/config.swiftformat", contents: """
        --indent 1

        [Tests]
        --filter **/Tests/**
        --indent 2

        [Tools Directory]
        --filter **/Tools/**
        --indent 3
        """)

        let nonTestFile = try createTmpFile("Test/Foo/Sources/Foo.swift", contents: """
        func foo() {
        print("bar")
        }
        """)

        let testFile = try createTmpFile("Test/Foo/Tests/FooTests.swift", contents: """
        func foo() {
        print("bar")
        }
        """)

        let toolsFile = try createTmpFile("Test/Tools/MyTool/FooTool.swift", contents: """
        func foo() {
        print("bar")
        }
        """)

        _ = processArguments([
            "",
            configURL.deletingLastPathComponent().path,
            "--config", configURL.path,
            "--project-index", "disabled",
        ], in: "")

        XCTAssertEqual(try String(contentsOf: nonTestFile, encoding: .utf8), """
        func foo() {
         print("bar")
        }

        """)

        XCTAssertEqual(try String(contentsOf: testFile, encoding: .utf8), """
        func foo() {
          print("bar")
        }

        """)

        XCTAssertEqual(try String(contentsOf: toolsFile, encoding: .utf8), """
        func foo() {
           print("bar")
        }

        """)

        let tempFiles = [configURL, nonTestFile, testFile, toolsFile]
        for tempFile in tempFiles {
            try FileManager.default.removeItem(at: tempFile)
        }

        XCTAssertEqual(errors, [])
    }

    func testConfigFileWithHeaderCreationDateFilter() throws {
        var errors = [String]()

        CLI.print = { message, type in
            print(message)
            if type == .error {
                errors.append(message)
            }
        }

        let configURL = try createTmpFile("Test/config.swiftformat", contents: """
        --swift-version 6.0

        [New test files]
        --filter **/Tests/**,header-creation-date-after:2026-08-31
        --enable preferSwiftTesting
        """)

        let testCase = """
        final class MyFeatureTests: XCTestCase {
            func testMyFeatureHasNoBugs() {
                let myFeature = MyFeature()
                XCTAssertFalse(myFeature.hasBugs)
            }
        }
        """

        let newTestFile = try createTmpFile("Test/Tests/NewTests.swift", contents: """
        //  Created on 9/1/26.

        import XCTest

        \(testCase)
        """)

        let oldTestFile = try createTmpFile("Test/Tests/OldTests.swift", contents: """
        //  Created on 8/30/26.

        import XCTest

        \(testCase)
        """)

        let undatedTestFile = try createTmpFile("Test/Tests/UndatedTests.swift", contents: """
        import XCTest

        \(testCase)
        """)

        _ = processArguments([
            "",
            configURL.deletingLastPathComponent().path,
            "--config", configURL.path,
            "--project-index", "disabled",
        ], in: "")

        // Created after 8/31/26, so is converted to Swift Testing
        XCTAssertEqual(try String(contentsOf: newTestFile, encoding: .utf8), """
        //  Created on 9/1/26.

        import Foundation
        import Testing

        final class MyFeatureTests {
            @Test func myFeatureHasNoBugs() {
                let myFeature = MyFeature()
                #expect(!myFeature.hasBugs)
            }
        }

        """)

        // Created before 8/31/26, so keeps using XCTest
        XCTAssertEqual(try String(contentsOf: oldTestFile, encoding: .utf8), """
        //  Created on 8/30/26.

        import XCTest

        \(testCase)

        """)

        // Has no creation date, so doesn't match the filter
        XCTAssertEqual(try String(contentsOf: undatedTestFile, encoding: .utf8), """
        import XCTest

        \(testCase)

        """)

        for tempFile in [configURL, newTestFile, oldTestFile, undatedTestFile] {
            try FileManager.default.removeItem(at: tempFile)
        }

        XCTAssertEqual(errors, [])
    }

    func testConfigFileWithInvalidHeaderCreationDateFilter() throws {
        var errors = [String]()

        CLI.print = { message, type in
            print(message)
            if type == .error {
                errors.append(message)
            }
        }

        let configURL = try createTmpFile("Test/config.swiftformat", contents: """
        --filter header-creation-date-after:tomorrowish
        --indent 2
        """)

        let file = try createTmpFile("Test/Foo/Foo.swift", contents: """
        func foo() {}
        """)

        _ = processArguments([
            "",
            configURL.deletingLastPathComponent().path,
            "--config", configURL.path,
        ], in: "")

        XCTAssert(
            errors.contains(where: { $0.contains("Invalid date 'tomorrowish'") }),
            "\(errors)"
        )

        for tempFile in [configURL, file] {
            try FileManager.default.removeItem(at: tempFile)
        }
    }

    func testBaseConfigFileWithFilters() throws {
        var errors = [String]()

        CLI.print = { message, type in
            print(message)
            if type == .error {
                errors.append(message)
            }
        }

        let configURL = try createTmpFile("Test/config.swiftformat", contents: """
        --indent 1

        [Tests]
        --filter **/Tests/**
        --indent 2

        [Tools Directory]
        --filter **/Tools/**
        --indent 3
        """)

        let nonTestFile = try createTmpFile("Test/Foo/Sources/Foo.swift", contents: """
        func foo() {
        print("bar")
        }
        """)

        let testFile = try createTmpFile("Test/Foo/Tests/FooTests.swift", contents: """
        func foo() {
        print("bar")
        }
        """)

        let toolsFile = try createTmpFile("Test/Tools/MyTool/FooTool.swift", contents: """
        func foo() {
        print("bar")
        }
        """)

        _ = processArguments([
            "",
            configURL.deletingLastPathComponent().path,
            "--base-config", configURL.path,
            "--project-index", "disabled",
        ], in: "")

        XCTAssertEqual(try String(contentsOf: nonTestFile, encoding: .utf8), """
        func foo() {
         print("bar")
        }

        """)

        XCTAssertEqual(try String(contentsOf: testFile, encoding: .utf8), """
        func foo() {
          print("bar")
        }

        """)

        XCTAssertEqual(try String(contentsOf: toolsFile, encoding: .utf8), """
        func foo() {
           print("bar")
        }

        """)

        let tempFiles = [configURL, nonTestFile, testFile, toolsFile]
        for tempFile in tempFiles {
            try FileManager.default.removeItem(at: tempFile)
        }

        XCTAssertEqual(errors, [])
    }

    func testStdinPathFileSpecificPath() throws {
        var output = [String]()
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                output.append(message)
            case .error, .warning:
                XCTFail(message)
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo()\n"
            case 2:
                return "{\n"
            case 3:
                return "bar()\n"
            case 4:
                return "}"
            default:
                return nil
            }
        }

        let configURL = try createTmpFile("Test/config.swiftformat", contents: """
        --indent 1

        [Tests]
        --filter **/Tests/**
        --indent 2
        """)

        let testFile = try createTmpFile("Test/MyModule/Tests/Foo.swift", contents: """
        func foo()
        {
        print("bar")
        }
        """)

        _ = processArguments([
            "",
            "stdin",
            "--stdin-path", testFile.path,
            "--config", configURL.path,
        ], in: "")

        XCTAssertEqual(output, ["""
        func foo() {
          bar()
        }

        """])

        let tempFiles = [configURL, testFile]
        for tempFile in tempFiles {
            try FileManager.default.removeItem(at: tempFile)
        }
    }

    func testStdinPathWithNonExistingFile() {
        var output = [String]()
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                output.append(message)
            case .error, .warning:
                XCTFail(message)
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo()\n"
            case 2:
                return "{\n"
            case 3:
                return "bar()\n"
            case 4:
                return "}"
            default:
                return nil
            }
        }

        // Use a path that doesn't exist
        let nonExistingPath = "/tmp/deleted_file_\(UUID().uuidString).swift"

        _ = processArguments([
            "",
            "stdin",
            "--stdin-path", nonExistingPath,
        ], in: "")

        // Should still format the input, despite file not existing
        XCTAssertEqual(output, ["""
        func foo() {
            bar()
        }

        """])
    }

    func testStdinPathWithNonExistingFileExcluded() {
        var output = [String]()
        CLI.print = { message, type in
            switch type {
            case .raw, .content:
                output.append(message)
            case .error, .warning:
                XCTFail(message)
            case .info, .success:
                break
            }
        }
        var readCount = 0
        CLI.readLine = {
            readCount += 1
            switch readCount {
            case 1:
                return "func foo()\n"
            case 2:
                return "{\n"
            case 3:
                return "bar()\n"
            case 4:
                return "}"
            default:
                return nil
            }
        }

        // Use a path that doesn't exist but matches exclusion pattern
        let nonExistingPath = "/tmp/excluded/deleted_file.swift"

        _ = processArguments([
            "",
            "stdin",
            "--stdin-path", nonExistingPath,
            "--exclude", "/tmp/excluded",
        ], in: "")

        // Should NOT format because the path is excluded
        XCTAssertEqual(output, ["func foo()\n{\nbar()\n}"])
    }

    func testSwiftVersionFileWithNoConfigFile() throws {
        var errors = [String]()

        CLI.print = { message, type in
            print(message)
            if type == .error {
                errors.append(message)
            }
        }

        try withTmpFiles([
            ".swift-version": """
            6.1
            """,
            "Test.swift": """
            func foo(
                foo: Foo,
                bar: Bar
            ) {}
            """,
        ]) { url in
            guard url.pathExtension == "swift" else { return }
            _ = processArguments(["", url.path, "--rules", "trailingCommas"], in: "")

            XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), """
            func foo(
                foo: Foo,
                bar: Bar,
            ) {}
            """)
        }

        XCTAssertEqual(errors, [])
    }

    func testSwiftVersionFileWithConfigFile() throws {
        var errors = [String]()

        CLI.print = { message, type in
            print(message)
            if type == .error {
                errors.append(message)
            }
        }

        try withTmpFiles([
            ".swift-version": """
            6.1
            """,
            ".swiftformat": """
            --rules trailingCommas
            --rules indent
            --indent 2
            """,
            "Test.swift": """
            func foo(
                foo: Foo,
                bar: Bar
            ) {}
            """,
        ]) { url in
            guard url.pathExtension == "swift" else { return }
            _ = processArguments(["", url.path], in: "")

            XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), """
            func foo(
              foo: Foo,
              bar: Bar,
            ) {}
            """)
        }

        XCTAssertEqual(errors, [])
    }

    func testSwiftVersionNotReadFromExcludedDirectory() throws {
        var logMessages: [String] = []

        CLI.print = { message, _ in
            print(message)
            logMessages.append(message)
        }

        // .swift-version should NOT be read from a directory that ends up excluded.
        // The build/.swiftformat excludes itself via "--exclude ." so no files inside
        // it will be formatted, making the .swift-version there irrelevant.
        try withTmpFiles([
            "main.swift": "let x = 1\n",
            "build/.swiftformat": "--exclude .\n",
            "build/.swift-version": "5.9\n",
        ]) { url in
            let rootDir = url.deletingLastPathComponent()
            _ = processArguments(["", rootDir.path, "--project-index", "disabled"], in: rootDir.path)

            let buildVersionMsgs = logMessages.filter {
                $0.contains("swift-version") && $0.contains("build")
            }
            XCTAssertTrue(
                buildVersionMsgs.isEmpty,
                "Expected no swift-version messages from excluded build directory, got: \(buildVersionMsgs)"
            )
        }

        logMessages.removeAll()

        // .swift-version should also NOT be read from a directory excluded by
        // the root .swiftformat file via "--exclude build".
        try withTmpFiles([
            ".swiftformat": "--exclude build\n",
            "main.swift": "let x = 1\n",
            "build/.swift-version": "5.9\n",
        ]) { url in
            let rootDir = url.deletingLastPathComponent()
            _ = processArguments(["", rootDir.path, "--project-index", "disabled"], in: rootDir.path)

            let buildVersionMsgs = logMessages.filter {
                $0.contains("swift-version") && $0.contains("build")
            }
            XCTAssertTrue(
                buildVersionMsgs.isEmpty,
                "Expected no swift-version messages from build directory excluded by root config, got: \(buildVersionMsgs)"
            )
        }
    }

    // MARK: Markdown

    func testFormatMarkdownFile() throws {
        CLI.print = { message, type in
            if type == .error {
                XCTFail(message)
            }
        }

        try withTmpFiles([
            "README.md": """
            # Sample README

            This is a nice project with lots of cool APIs to know about, including:

            ```swift
            func foo(
            bar: Bar,
            baaz: Baaz
            ) -> Foo { ... }
            ```

              ```swift --indent 2
              func foo(
              bar: Bar,
              baaz: Baaz
              ) -> Foo { ... }
              ```

            ```swift --disable indent
            print( "foo" )
              print( "bar" )
                print( "baaz" )
            ```

            ```swift --disable spaceInsideParens
            print( "foo" )
              print( "bar" )
                print( "baaz" )
            ```

            ```swift --enable organizeDeclarations
            class Foo {
                init() {}
                func bar() {}
            }
            ```

            ```swift
            --markdownfiles format-lenient ignores blocks that can't be parsed:
            print("Foo
            ```

            Thanks for reading!
            """,
        ]) { url in
            _ = processArguments([
                "",
                url.path,
                "--markdownfiles", "format-lenient",
                "--rules", "indent",
                "--rules", "braces",
                "--rules", "spaceInsideParens",
                "--rules", "linebreakAtEndOfFile",
            ], in: "")

            let updatedReadme = try String(contentsOf: url, encoding: .utf8)

            // The Swift code blocks should be indented correctly:
            XCTAssertEqual(updatedReadme, """
            # Sample README

            This is a nice project with lots of cool APIs to know about, including:

            ```swift
            func foo(
                bar: Bar,
                baaz: Baaz
            ) -> Foo { ... }
            ```

              ```swift --indent 2
              func foo(
                bar: Bar,
                baaz: Baaz
              ) -> Foo { ... }
              ```

            ```swift --disable indent
            print("foo")
              print("bar")
                print("baaz")
            ```

            ```swift --disable spaceInsideParens
            print( "foo" )
            print( "bar" )
            print( "baaz" )
            ```

            ```swift --enable organizeDeclarations
            class Foo {

                // MARK: Lifecycle

                init() {}

                // MARK: Internal

                func bar() {}
            }
            ```

            ```swift
            --markdownfiles format-lenient ignores blocks that can't be parsed:
            print("Foo
            ```

            Thanks for reading!
            """)
        }
    }

    func testStrictMarkdownFormatting() throws {
        var errors = [String]()

        CLI.print = { message, type in
            if type == .error {
                errors.append(message)
            }
        }

        try withTmpFiles([
            "README.md": """
            # Sample README

            This is a nice project with lots of cool APIs to know about, including:

            ```swift
            --markdownfiles format-strict fails if there are parsing errors:
            print("Foo
            ```

            ```swift no-format
            This block is ignored
            print("Foo
            ```

            Thanks for reading!
            """,
        ]) { url in
            _ = processArguments([
                "",
                url.path,
                "--markdownfiles", "format-strict",
                "--rules", "indent",
            ], in: "")
        }

        XCTAssertEqual(errors.count, 1)
        XCTAssert(errors[0].contains("Unexpected end of file at 7:11"))
    }

    func testDoesntFormatSwiftBlockInDiffBlock() throws {
        var errors = [String]()

        CLI.print = { message, type in
            if type == .error {
                errors.append(message)
            }
        }

        try withTmpFiles([
            "README.md": """
            ````diff
              ```swift
            - func    foo(   ) {    }
            + func foo() {    }
              ```
            ````

            ```swift
            func    foo(   ) {    }
            ```

            ```swift
            ```
            """,
        ]) { url in
            _ = processArguments([
                "",
                url.path,
                "--markdownfiles", "format-strict",
                "--rules", "consecutiveSpaces",
                "--rules", "spaceInsideBrackets",
                "--rules", "spaceInsideParens",
            ], in: "")

            let updatedReadme = try String(contentsOf: url, encoding: .utf8)
            XCTAssertEqual(updatedReadme, """
            ````diff
              ```swift
            - func    foo(   ) {    }
            + func foo() {    }
              ```
            ````

            ```swift
            func foo() { }
            ```

            ```swift
            ```
            """)
        }

        XCTAssertEqual(errors, [])
    }

    func testUnbalancedCodeBlockTokens() throws {
        var errors = [String]()

        CLI.print = { message, type in
            if type == .error {
                errors.append(message)
            }
        }

        try withTmpFiles([
            "README.md": """
            # Sample README

            This markdown file has unbalanced code block tokens:

            ```swift
            print("Hello, world!")
            // Missing closing ```

            This should cause an error in strict mode.
            """,
        ]) { url in
            _ = processArguments([
                "",
                url.path,
                "--markdownfiles", "format-strict",
                "--rules", "indent",
            ], in: "")
        }

        XCTAssertEqual(errors.count, 1)
        XCTAssert(errors[0].contains("Unbalanced code block delimiters in markdown"))
    }

    // MARK: Reporters

    func testWrite() throws {
        let reporter = GithubActionsLogReporter(environment: ["GITHUB_WORKSPACE": "/bar"])
        let rule = FormatRule.consecutiveSpaces
        reporter.report([
            .init(line: 1, rule: rule, filePath: "/bar/foo.swift", isMove: false),
            .init(line: 2, rule: rule, filePath: "/bar/foo.swift", isMove: false),
        ])
        let expectedOutput = """
        ::warning file=foo.swift,line=1::\(rule.help) (\(rule.name))
        ::warning file=foo.swift,line=2::\(rule.help) (\(rule.name))

        """
        let output = try XCTUnwrap(reporter.write())
        let outputString = String(decoding: output, as: UTF8.self)
        XCTAssertEqual(outputString, expectedOutput)
    }

    func testJSONReporterEndToEnd() throws {
        try withTmpFiles([
            "foo.swift": "func foo() {\n}\n",
        ]) { url in
            CLI.print = { message, type in
                switch type {
                case .raw:
                    XCTAssert(message.contains("\"rule_id\" : \"emptyBraces\""))
                case .error, .warning:
                    break
                case .info, .success:
                    break
                case .content:
                    XCTFail()
                }
            }
            _ = processArguments([
                "",
                "--lint",
                "--reporter", "json",
                "--project-index", "disabled",
                url.path,
            ], in: "")
        }
    }

    func testJSONReporterInferredFromURL() throws {
        let outputURL = try createTmpFile("report.json", contents: "")
        try withTmpFiles([
            "foo.swift": "func foo() {\n}\n",
        ]) { url in
            CLI.print = { _, _ in }
            _ = processArguments([
                "",
                "--lint",
                "--report", outputURL.path,
                "--project-index", "disabled",
                url.path,
            ], in: "")
        }
        let output = try String(contentsOf: outputURL)
        XCTAssert(output.contains("\"rule_id\" : \"emptyBraces\""))
    }

    func testGithubActionsLogReporterEndToEnd() throws {
        try withTmpFiles([
            "foo.swift": "func foo() {\n}\n",
        ]) { url in
            CLI.print = { message, type in
                switch type {
                case .raw:
                    XCTAssert(message.hasPrefix("::warning file=foo.swift,line=1::"))
                case .error, .warning:
                    break
                case .info, .success:
                    break
                case .content:
                    XCTFail()
                }
            }
            _ = processArguments([
                "",
                "--lint",
                "--reporter", "github-actions-log",
                "--project-index", "disabled",
                url.path,
            ],
            environment: ["GITHUB_WORKSPACE": url.deletingLastPathComponent().path],
            in: "")
        }
    }

    func testGithubActionsLogReporterMisspelled() throws {
        try withTmpFiles([
            "foo.swift": "func foo() {\n}\n",
        ]) { url in
            CLI.print = { message, type in
                switch type {
                case .raw, .warning, .info:
                    break
                case .error:
                    XCTAssert(message.contains("Did you mean 'github-actions-log'?"))
                case .content, .success:
                    XCTFail()
                }
            }
            _ = processArguments([
                "",
                "--lint",
                "--reporter", "github-action-log",
                url.path,
            ], in: "")
        }
    }

    func testXMLReporterEndToEnd() throws {
        try withTmpFiles([
            "foo.swift": "func foo() {\n}\n",
        ]) { url in
            CLI.print = { message, type in
                switch type {
                case .raw:
                    XCTAssert(message.contains("<error line=\"1\" column=\"0\" severity=\"warning\""))
                case .error, .warning:
                    break
                case .info, .success:
                    break
                case .content:
                    XCTFail()
                }
            }
            _ = processArguments([
                "",
                "--lint",
                "--reporter", "xml",
                "--project-index", "disabled",
                url.path,
            ], in: "")
        }
    }

    func testXMLReporterInferredFromURL() throws {
        let outputURL = try createTmpFile("report.xml", contents: "")
        try withTmpFiles([
            "foo.swift": "func foo() {\n}\n",
        ]) { url in
            CLI.print = { _, _ in }
            _ = processArguments([
                "",
                "--lint",
                "--report", outputURL.path,
                "--project-index", "disabled",
                url.path,
            ], in: "")
        }
        let output = try String(contentsOf: outputURL)
        XCTAssert(output.contains("<error line=\"1\" column=\"0\" severity=\"warning\""))
    }

    func testSARIFReporterEndToEnd() throws {
        try withTmpFiles([
            "foo.swift": "func foo() {\n}\n",
        ]) { url in
            CLI.print = { message, type in
                switch type {
                case .raw:
                    XCTAssert(message.contains("\"ruleId\" : \"emptyBraces\""))
                case .error, .warning:
                    break
                case .info, .success:
                    break
                case .content:
                    XCTFail()
                }
            }
            _ = processArguments([
                "",
                "--lint",
                "--reporter", "sarif",
                "--project-index", "disabled",
                url.path,
            ], in: "")
        }
    }

    func testSARIFReporterInferredFromURL() throws {
        let outputURL = try createTmpFile("report.sarif", contents: "")
        try withTmpFiles([
            "foo.swift": "func foo() {\n}\n",
        ]) { url in
            CLI.print = { _, _ in }
            _ = processArguments([
                "",
                "--lint",
                "--report", outputURL.path,
                "--project-index", "disabled",
                url.path,
            ], in: "")
        }
        let output = try String(contentsOf: outputURL)
        XCTAssert(output.contains("\"ruleId\" : \"emptyBraces\""))
    }

    // MARK: Rule info

    func testRuleInfo() {
        CLI.print = { _, _ in }
        for rule in FormatRules.all {
            do {
                try printRuleInfo(for: rule.name, as: .content)
            } catch {
                XCTFail("RuleInfo for \(rule.name) threw error: \(error)")
            }
        }
    }

    func testRuleInfoShowsEnabledByDefault() throws {
        var output = ""
        CLI.print = { message, _ in output += message + "\n" }
        // Find a rule that is enabled by default
        let defaultRule = try XCTUnwrap(FormatRules.default.first)
        try? printRuleInfo(for: defaultRule.name, as: .content)
        XCTAssert(output.contains("(enabled by default)"), "Expected '(enabled by default)' in output for \(defaultRule.name)")
    }

    func testRuleInfoShowsOptIn() throws {
        var output = ""
        CLI.print = { message, _ in output += message + "\n" }
        // Find an opt-in rule that is not deprecated
        let optInRule = try XCTUnwrap(FormatRules.disabledByDefault.first { !$0.isDeprecated })
        try? printRuleInfo(for: optInRule.name, as: .content)
        XCTAssert(output.contains("(disabled by default)"), "Expected '(disabled by default)' in output for \(optInRule.name)")
    }

    func testRuleInfoShowsDeprecated() throws {
        var output = ""
        CLI.print = { message, _ in output += message + "\n" }
        let deprecatedRule = try XCTUnwrap(FormatRules.deprecated.first)
        try? printRuleInfo(for: deprecatedRule.name, as: .content)
        XCTAssert(output.contains("(deprecated:"), "Expected '(deprecated:' in output for \(deprecatedRule.name)")
        XCTAssertFalse(output.contains("(enabled by default)"))
        XCTAssertFalse(output.contains("(disabled by default)"))
    }
}
