//
//  GlobsTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 31/12/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class GlobsTests: XCTestCase {
    // MARK: glob matching

    func testExpandWildcardPathWithExactName() {
        let path = "Tokenizer.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithWildcardInMiddle() {
        let path = "Rule*.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithSingleCharacterWildcardInMiddle() {
        let path = "Rule?.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithWildcardAtEnd() {
        let path = "Options*"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 2)
    }

    func testExpandPathWithDoubleWildcardAtEnd() {
        let path = "Options**"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 2)
    }

    func testExpandPathWithCharacterClass() {
        let path = "Options[DS]*.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithCharacterClassRange() {
        let path = "Options[E-T]*.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("EditorExtension/Shared")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandPathWithEitherOr() {
        let path = "Option{s,sDescriptor}.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 2)
    }

    func testExpandPathsWithEitherOr() {
        let path = "Option{s,sDescriptor}.swift, SwiftFormat.{h,swift}"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 4)
    }

    func testExpandPathWithEitherOrContainingDot() {
        let path = "SwiftFormat{.h,.swift}"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 2)
    }

    func testExpandPathWithWildcardAtStart() {
        let path = "*Tests.swift"
        let directory = URL(fileURLWithPath: #file).deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 11)
    }

    func testExpandPathWithSubdirectoryAndWildcard() {
        let path = "Tests/*Tests.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 11)
    }

    func testSingleWildcardDoesNotMatchDirectorySlash() {
        let path = "*/SwiftFormatTests.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 0)
    }

    func testDoubleWildcardMatchesDirectorySlash() {
        let path = "**/SwiftFormatTests.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testDoubleWildcardMatchesNoSubdirectories() {
        let path = "Tests/**/SwiftFormatTests.swift"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    func testExpandGlobsChecksForExactPaths() {
        let path = "Tests/Glob?Test[5]*.txt"
        let directory = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(matchGlobs(expandGlobs(path, in: directory.path), in: directory.path).count, 1)
    }

    // MARK: glob regex

    func testWildcardRegex() {
        let path = "/Rule*.swift"
        let directory = URL(fileURLWithPath: #file)
        guard case let .regex(regex) = expandGlobs(path, in: directory.path)[0] else {
            return
        }
        XCTAssertEqual(regex.pattern, "^/Rule([^/]+)?\\.swift$")
    }

    func testDoubleWildcardRegex() {
        let path = "/**Rule.swift"
        let directory = URL(fileURLWithPath: #file)
        guard case let .regex(regex) = expandGlobs(path, in: directory.path)[0] else {
            return
        }
        XCTAssertEqual(regex.pattern, "^/.+Rule\\.swift$")
    }

    func testDoubleWildcardSlashRegex() {
        let path = "/**/Rule.swift"
        let directory = URL(fileURLWithPath: #file)
        guard case let .regex(regex) = expandGlobs(path, in: directory.path)[0] else {
            return
        }
        XCTAssertEqual(regex.pattern, "^/(.+/)?Rule\\.swift$")
    }

    func testEitherOrRegex() {
        let path = "/SwiftFormat.{h,swift}"
        let directory = URL(fileURLWithPath: #file)
        guard case let .regex(regex) = expandGlobs(path, in: directory.path)[0] else {
            return
        }
        XCTAssertEqual(regex.pattern, "^/SwiftFormat\\.(h|swift)$")
    }

    func testEitherOrContainingDotRegex() {
        let path = "/SwiftFormat{.h,.swift}"
        let directory = URL(fileURLWithPath: #file)
        guard case let .regex(regex) = expandGlobs(path, in: directory.path)[0] else {
            return
        }
        XCTAssertEqual(regex.pattern, "^/SwiftFormat(\\.h|\\.swift)$")
    }

    // MARK: glob description

    func testGlobPathDescription() {
        let path = "/foo/bar.swift"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }

    func testGlobWildcardDescription() {
        let path = "/foo/*.swift"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }

    func testGlobDoubleWildcardDescription() {
        let path = "/foo/**bar.swift"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }

    func testGlobDoubleWildcardSlashDescription() {
        let path = "/foo/**/bar.swift"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }

    func testGlobSingleCharacterWildcardDescription() {
        let path = "/foo/ba?.swift"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }

    func testGlobEitherOrDescription() {
        let path = "/foo/{bar,baz}.swift"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }

    func testGlobEitherOrWithDotsDescription() {
        let path = "/foo{.swift,.txt}"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }

    func testGlobCharacterClassDescription() {
        let path = "/Options[DS]*.swift"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }

    func testGlobCharacterRangeDescription() {
        let path = "/Options[D-S]*.swift"
        let directory = URL(fileURLWithPath: #file)
        let globs = expandGlobs(path, in: directory.path)
        XCTAssertEqual(globs[0].description, path)
    }
}
