//
//  AcronymsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 7/28/2024.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class AcronymsTests: XCTestCase {
    func testUppercaseAcronyms() {
        let input = """
        let url: URL
        let destinationUrl: URL
        let id: ID
        let screenId = "screenId" // We intentionally don't change the content of strings
        let validUrls: Set<URL>
        let validUrlschemes: Set<URL>

        let uniqueIdentifier = UUID()

        /// Opens Urls based on their scheme
        struct UrlRouter {}

        /// The Id of a screen that can be displayed in the app
        struct ScreenId {}
        """

        let output = """
        let url: URL
        let destinationURL: URL
        let id: ID
        let screenID = "screenId" // We intentionally don't change the content of strings
        let validURLs: Set<URL>
        let validUrlschemes: Set<URL>

        let uniqueIdentifier = UUID()

        /// Opens URLs based on their scheme
        struct URLRouter {}

        /// The ID of a screen that can be displayed in the app
        struct ScreenID {}
        """

        testFormatting(for: input, output, rule: .acronyms, exclude: [.propertyType])
    }

    func testUppercaseCustomAcronym() {
        let input = """
        let url: URL
        let destinationUrl: URL
        let pngData: Data
        let imageInPngFormat: UIImage
        """

        let output = """
        let url: URL
        let destinationUrl: URL
        let pngData: Data
        let imageInPNGFormat: UIImage
        """

        testFormatting(for: input, output, rule: .acronyms, options: FormatOptions(acronyms: ["png"]))
    }

    func testDisableUppercaseAcronym() {
        let input = """
        // swiftformat:disable:next acronyms
        typeNotOwnedByAuthor.destinationUrl = URL()
        typeOwnedByAuthor.destinationURL = URL()
        """

        testFormatting(for: input, rule: .acronyms)
    }
}
