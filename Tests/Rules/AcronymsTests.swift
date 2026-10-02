//
//  AcronymsTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 9/28/21.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class AcronymsTests: XCTestCase {
    private func testProjectFormatting(
        for input: String,
        _ output: String,
        declarations: String,
        options: FormatOptions = .default,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        _ = FormatRules.all
        let declarationsURL = URL(fileURLWithPath: "/Project/Sources/App/Declarations.swift")
        let callURL = URL(fileURLWithPath: "/Project/Sources/App/Call.swift")
        let projectIndex = ProjectIndex(files: [
            declarationsURL.path: makeSourceFileIndex(from: declarations, moduleIdentifiers: ["App"]),
            callURL.path: makeSourceFileIndex(from: input, moduleIdentifiers: ["App"]),
        ])
        let result = try applyRules(
            [.acronyms],
            to: tokenize(input),
            with: options,
            trackChanges: false,
            range: nil,
            context: FormattingContext(currentFileURL: callURL, projectIndex: projectIndex)
        )
        XCTAssertEqual(sourceCode(for: result.tokens), output, file: file, line: line)
    }

    func testUppercaseAcronyms() {
        let input = """
        let url: URL
        let destinationUrl: URL
        let id: ID
        let screenId = "screenId" // We intentionally don't change the content of strings
        let validUrls: Set<URL>
        let validUrlschemes: Set<URL> // Edge case

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
        let validUrlschemes: Set<URL> // Edge case

        let uniqueIdentifier = UUID()

        /// Opens URLs based on their scheme
        struct URLRouter {}

        /// The ID of a screen that can be displayed in the app
        struct ScreenID {}
        """

        testFormatting(for: input, output, rule: .acronyms, exclude: [.propertyTypes])
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

    func testRespectsPreserveSymbols() {
        let input = """
        let destinationUrl = api.externallyProvidedUrl
        api.route(toUrl: destinationUrl)
        """

        let output = """
        let destinationURL = api.externallyProvidedUrl
        api.route(toUrl: destinationURL)
        """

        let options = FormatOptions(preserveAcronyms: ["externallyProvidedUrl", "toUrl"])
        testFormatting(for: input, output, rule: .acronyms, options: options)
    }

    func testAcronymMatchesPartOfOtherWordAtEndOfIdentifier() {
        let input = """
        struct MasKit {}
        struct Mask {}
        struct MaskView {}
        """

        let output = """
        struct MASKit {}
        struct Mask {}
        struct MaskView {}
        """

        testFormatting(for: input, output, rule: .acronyms, options: FormatOptions(acronyms: ["MAS"]))
    }

    func testAcronymNotMatchedAsSuffixOfAnotherAcronym() {
        let input = """
        // Ids for ds store
        var personIDs: [String]
        var userIds: [Int]
        var ids: [UUID]

        /// The Ds store
        struct DsStore {}
        """

        let output = """
        // IDs for ds store
        var personIDs: [String]
        var userIDs: [Int]
        var ids: [UUID]

        /// The DS store
        struct DSStore {}
        """

        testFormatting(for: input, output, rule: .acronyms, options: FormatOptions(acronyms: ["ID", "DS"]))
    }

    func testPreserveAcronymsAsSubstringOfIdentifier() {
        let input = """
        let kMDItemAppStoreAdamID = value
        """

        let options = FormatOptions(acronyms: ["ADAM"], preserveAcronyms: ["kMDItemAppStoreAdamID"])
        testFormatting(for: input, rule: .acronyms, options: options)
    }

    func testPreserveAcronymsDoesNotAffectOtherIdentifiers() {
        let input = """
        let kMDItemAppStoreAdamID = value
        let destinationAdamView = view
        """

        let output = """
        let kMDItemAppStoreAdamID = value
        let destinationADAMView = view
        """

        let options = FormatOptions(acronyms: ["ADAM"], preserveAcronyms: ["kMDItemAppStoreAdamID"])
        testFormatting(for: input, output, rule: .acronyms, options: options)
    }

    func testPreserveAcronymsMatchesSubstringInLongerIdentifier() {
        let input = """
        let xkMDItemAppStoreAdamIDy = value
        """

        let options = FormatOptions(acronyms: ["ADAM"], preserveAcronyms: ["kMDItemAppStoreAdamID"])
        testFormatting(for: input, rule: .acronyms, options: options)
    }

    func testDefaultVisibilityCapitalizesInternalButNotPublicDeclarations() {
        let input = """
        public let publicUrl = ""
        let internalUrl = ""
        fileprivate let fileprivateUrl = ""
        private let privateUrl = ""
        print(publicUrl, internalUrl, fileprivateUrl, privateUrl)
        """
        let output = """
        public let publicUrl = ""
        let internalURL = ""
        fileprivate let fileprivateURL = ""
        private let privateURL = ""
        print(publicUrl, internalURL, fileprivateURL, privateURL)
        """
        testFormatting(for: input, output, rule: .acronyms, exclude: [.redundantFileprivate])
    }

    func testPublicVisibilityCapitalizesPublicButNotOpenDeclarations() {
        let input = """
        public let publicUrl = ""

        open class UrlProvider {
            public func loadUrl() {}
            open func openUrl() {}
        }
        """
        let output = """
        public let publicURL = ""

        open class UrlProvider {
            public func loadURL() {}
            open func openUrl() {}
        }
        """
        testFormatting(
            for: input,
            output,
            rule: .acronyms,
            options: FormatOptions(acronymVisibility: .public)
        )
    }

    func testPrivateVisibilityPreservesUnknownAndWiderDeclarations() {
        let input = """
        let internalUrl = externalApi.loadUrl()
        private let privateUrl = internalUrl
        """
        let output = """
        let internalUrl = externalApi.loadUrl()
        private let privateURL = internalUrl
        """
        testFormatting(
            for: input,
            output,
            rule: .acronyms,
            options: FormatOptions(acronymVisibility: .private)
        )
    }

    func testPreservesNameWhenCapitalizationWouldCollide() {
        let input = """
        let destinationUrl = ""
        let destinationURL = ""
        print(destinationUrl, destinationURL)
        """
        testFormatting(for: input, rule: .acronyms)
    }

    func testPreservesProtocolAndOverrideContracts() {
        let input = """
        protocol UrlLoading {
            func loadUrl()
        }

        class UrlLoader: UrlLoading {
            func loadUrl() {}
            override func prepareUrl() {}
        }
        """
        let output = """
        protocol URLLoading {
            func loadUrl()
        }

        class URLLoader: URLLoading {
            func loadUrl() {}
            override func prepareUrl() {}
        }
        """
        testFormatting(for: input, output, rule: .acronyms)
    }

    func testProjectIndexCapitalizesInternalDeclarationsAndReferencesAcrossFiles() throws {
        let declarations = """
        struct UrlRouter {
            func loadUrl() {}
        }
        """
        let input = """
        let router = UrlRouter()
        router.loadUrl()
        """
        let output = """
        let router = URLRouter()
        router.loadURL()
        """
        try testProjectFormatting(for: input, output, declarations: declarations)
    }

    func testProjectIndexPreservesUnknownExternalReferences() throws {
        let input = """
        externalApi.loadUrl(fromUrl: sourceUrl)
        """
        try testProjectFormatting(for: input, input, declarations: "")
    }

    func testProjectIndexPreservesCrossFileCapitalizationCollision() throws {
        let declarations = """
        let destinationUrl = ""
        let destinationURL = ""
        """
        let input = """
        print(destinationUrl, destinationURL)
        """
        try testProjectFormatting(for: input, input, declarations: declarations)
    }
}
