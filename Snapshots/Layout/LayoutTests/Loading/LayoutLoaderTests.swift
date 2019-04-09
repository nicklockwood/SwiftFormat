//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

private func createTempDirectory(_ suffix: String) throws -> URL {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(suffix)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    return directory
}

private let projectDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

class LayoutLoaderTests: XCTestCase {
    func testFindProjectDirectory() {
        let loader = LayoutLoader()
        let file = #file
        let path = loader.findProjectDirectory(at: file)
        XCTAssertEqual(path, projectDirectory)
    }

    func testFindProjectDirectoryIfPathContainsDot() {
        let directory = try! createTempDirectory("foo-4.5/bar")
        let projectURL = directory.deletingLastPathComponent().appendingPathComponent("Project.xcodeproj")
        let fileURL = directory.appendingPathComponent("baz.swift")
        do {
            try "project".data(using: .utf8)!.write(to: projectURL)
            try "file".data(using: .utf8)!.write(to: fileURL)
            let loader = LayoutLoader()
            let path = loader.findProjectDirectory(at: fileURL.path)
            XCTAssertEqual(path, projectURL.deletingLastPathComponent())
        } catch {
            XCTFail("\(error)")
        }
        try! FileManager.default.removeItem(at: directory)
    }

    func testFindXMLSourceFile() {
        let loader = LayoutLoader()
        do {
            loader.clearSourceURLs()
            let sourceURL = try loader.findSourceURL(
                forRelativePath: "Examples.xml",
                in: projectDirectory,
                usingCache: true
            )
            let expected = projectDirectory.appendingPathComponent("SampleApp/Examples.xml")
            XCTAssertEqual(sourceURL, expected)
            // Load again, this time from cache
            let cachedSourceURL = try loader.findSourceURL(
                forRelativePath: "Examples.xml",
                in: projectDirectory,
                usingCache: true
            )
            XCTAssertEqual(sourceURL, cachedSourceURL)
            loader.clearSourceURLs()
        } catch {
            XCTFail("\(error)")
        }
    }

    func testFindXMLSourceFileWithPath() {
        let loader = LayoutLoader()
        do {
            loader.clearSourceURLs()
            let sourceURL = try loader.findSourceURL(
                forRelativePath: "SampleApp/Examples.xml",
                in: projectDirectory,
                usingCache: false
            )
            let expected = projectDirectory.appendingPathComponent("SampleApp/Examples.xml")
            XCTAssertEqual(sourceURL, expected)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testFindNonexistentSourceFileThrowsError() {
        let loader = LayoutLoader()
        let file = #file
        guard let projectDirectory = loader.findProjectDirectory(at: file) else {
            XCTFail()
            return
        }
        // With cache
        XCTAssertThrowsError(try loader.findSourceURL(
            forRelativePath: "DoesntExist.xml",
            in: projectDirectory,
            usingCache: true
        )) { error in
            XCTAssertTrue("\(error)".contains("Unable to locate"))
        }
        // Without cache
        XCTAssertThrowsError(try loader.findSourceURL(
            forRelativePath: "DoesntExist.xml",
            in: projectDirectory,
            usingCache: false
        )) { error in
            XCTAssertTrue("\(error)".contains("Unable to locate"))
        }
    }
}
