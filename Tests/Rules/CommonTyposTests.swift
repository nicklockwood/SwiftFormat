//
//  CommonTyposTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 9/28/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class CommonTyposTests: XCTestCase {
    func testPrefersUSSpellingWhenEnabled() {
        let input = """
        // Colour COLOUR favourite behaviour centre theatre
        // Initialise serialised optimising normalisation labelled travelling
        // Retreive the colours and organise the catalogue.
        """
        let output = """
        // Color COLOR favorite behavior center theater
        // Initialize serialized optimizing normalization labeled traveling
        // Retrieve the colors and organize the catalog.
        """
        testFormatting(for: input, output, rule: .commonTypos, options: FormatOptions(preferUSSpelling: true))
    }

    func testPreservesBritishSpellingByDefault() {
        let input = """
        /// The favourite colour is in the centre.
        private let favouriteColour = "colour"
        print(favouriteColour)
        """
        testFormatting(for: input, rule: .commonTypos)
    }

    func testPreservesBritishSpellingWhenDisabled() {
        let input = """
        /// Retreive the favourite colour from the centre.
        private let favouriteColour = "colour"
        print(favouriteColour)
        """
        let output = """
        /// Retrieve the favourite colour from the centre.
        private let favouriteColour = "colour"
        print(favouriteColour)
        """
        testFormatting(for: input, output, rule: .commonTypos, options: FormatOptions(preferUSSpelling: false))
    }

    func testUSSpellingRenamesIdentifiersAndUsesButNotStrings() {
        let input = """
        private let favouriteColour = "colour"

        public func render() {
            let centre = favouriteColour
            print(centre)
        }
        """
        let output = """
        private let favoriteColor = "colour"

        public func render() {
            let center = favoriteColor
            print(center)
        }
        """
        testFormatting(for: input, output, rule: .commonTypos, options: FormatOptions(preferUSSpelling: true))
    }

    func testUSSpellingPreservesPublicNamesAndExternalReferences() {
        let input = """
        public let colour = "blue"
        let centre = external.colour
        print(colour, centre)
        """
        testFormatting(for: input, rule: .commonTypos, options: FormatOptions(preferUSSpelling: true))
    }

    func testUSSpellingPreservesCollidingIdentifiers() {
        let input = """
        private let colour = 1
        private let color = 2
        print(colour, color)
        """
        testFormatting(for: input, rule: .commonTypos, options: FormatOptions(preferUSSpelling: true))
    }

    func testUSSpellingRespectsIgnoredWordsAndCustomCorrections() {
        let input = """
        private let favouriteColour = "" // Favourite colour behaviour
        """
        let output = """
        private let favouriteHue = "" // Favourite hue behavior
        """
        testFormatting(for: input, output, rule: .commonTypos, options: FormatOptions(
            typos: ["colour": "hue"], ignoredTypos: ["FAVOURITE"], preferUSSpelling: true
        ))
    }

    func testUSSpellingPreservesAmbiguousWordsAndUnmatchedSuffixes() {
        let input = """
        // These analyses exercise the surprise of the enterprise.
        // The size of the prize is wise.
        """
        testFormatting(for: input, rule: .commonTypos, options: FormatOptions(preferUSSpelling: true))
    }

    func testCorrectsTyposInComments() {
        let input = """
        // Retreive the value immediatly
        /* The seperate values are alligned. */
        """
        let output = """
        // Retrieve the value immediately
        /* The separate values are aligned. */
        """
        testFormatting(for: input, output, rule: .commonTypos)
    }

    func testCorrectsPrivateIdentifiersAndUses() {
        let input = """
        private struct CacheReciever {
            let maxiumumLenght: Int

            func retreiveValue(for identifer: String) -> String {
                maxiumumLenght.description + identifer
            }
        }

        private let sharedReciever: CacheReciever = .init(maxiumumLenght: 10)
        """
        let output = """
        private struct CacheReceiver {
            let maximumLength: Int

            func retrieveValue(for identifier: String) -> String {
                maximumLength.description + identifier
            }
        }

        private let sharedReceiver: CacheReceiver = .init(maximumLength: 10)
        """
        testFormatting(for: input, output, rule: .commonTypos)
    }

    func testCorrectsLocalIdentifiers() {
        let input = """
        public func render() {
            let widht = 10
            func render(adress: String) {
                print(widht, adress)
            }
            render(adress: "")
        }
        """
        let output = """
        public func render() {
            let width = 10
            func render(address: String) {
                print(width, address)
            }
            render(address: "")
        }
        """
        testFormatting(for: input, output, rule: .commonTypos)
    }

    func testPreservesReferencesToDeclarationsInOtherFilesByDefault() {
        let input = """
        let reciever: ExternalReciever = .init()
        reciever.retreiveValue(for: identifer)
        """
        testFormatting(for: input, rule: .commonTypos)
    }

    func testInternalVisibilityCorrectsReferencesToDeclarationsInOtherFiles() {
        let input = """
        let receiver: ExternalReciever = .init()
        receiver.retreiveValue(for: identifer)
        """
        let output = """
        let receiver: ExternalReceiver = .init()
        receiver.retrieveValue(for: identifier)
        """
        testFormatting(
            for: input,
            output,
            rule: .commonTypos,
            options: FormatOptions(typoVisibility: .internal)
        )
    }

    func testPreservesPublicAndPackageAPI() {
        let input = """
        public struct Reciever {
            public let widht: Int
            package func retreiveValue() {}
        }
        """
        testFormatting(for: input, rule: .commonTypos)
    }

    func testPublicVisibilityCorrectsPublicAndPackageButNotOpenAPI() {
        let input = """
        public struct Reciever {
            public let widht: Int
            package func retreiveValue() {}
        }

        open class AdressProvider {}
        """
        let output = """
        public struct Receiver {
            public let width: Int
            package func retrieveValue() {}
        }

        open class AdressProvider {}
        """
        testFormatting(
            for: input,
            output,
            rule: .commonTypos,
            options: FormatOptions(typoVisibility: .public)
        )
    }

    func testFileprivateVisibilityPreservesInternalAPI() {
        let input = """
        let internalAdress = ""
        fileprivate let privateReciever = ""
        private let privateWidht = 10
        """
        let output = """
        let internalAdress = ""
        fileprivate let privateReceiver = ""
        private let privateWidth = 10
        """
        testFormatting(
            for: input,
            output,
            rule: .commonTypos,
            options: FormatOptions(typoVisibility: .fileprivate),
            exclude: [.redundantFileprivate]
        )
    }

    func testPackageVisibilityPreservesPublicAPI() {
        let input = """
        public let publicAdress = ""
        package let packageReciever = ""
        let internalWidht = 10
        """
        let output = """
        public let publicAdress = ""
        package let packageReceiver = ""
        let internalWidth = 10
        """
        testFormatting(
            for: input,
            output,
            rule: .commonTypos,
            options: FormatOptions(typoVisibility: .package)
        )
    }

    func testPrivateVisibilityPreservesFileprivateAPI() {
        let input = """
        fileprivate let fileprivateAdress = ""
        private let privateReciever = ""
        """
        let output = """
        fileprivate let fileprivateAdress = ""
        private let privateReceiver = ""
        """
        testFormatting(
            for: input,
            output,
            rule: .commonTypos,
            options: FormatOptions(typoVisibility: .private),
            exclude: [.redundantFileprivate]
        )
    }

    func testPreservesSerializedProperties() {
        let input = """
        struct User: Codable {
            let adress: String
        }

        private struct Settings {
            @AppStorage("preferedColour") private var preferedColour: String
        }

        private enum CodingKeys: String, CodingKey {
            case preferedColour
        }
        """
        testFormatting(for: input, rule: .commonTypos)
    }

    func testPreservesStrings() {
        let input = """
        private let message = "Retreive the adress"
        """
        testFormatting(for: input, rule: .commonTypos)
    }

    func testPreservesObjCAndProtocolContracts() {
        let input = """
        protocol Receiving: AnyObject {
            func retreiveValue()
        }

        private final class Receiver: NSObject {
            @objc func retreiveValue() {}
            override func prepareForInterfaceBuilder() {}
        }
        """
        testFormatting(for: input, rule: .commonTypos)
    }

    func testPreservesNameWhenCorrectionWouldCollide() {
        let input = """
        private let widht = 10
        private let width = 20
        print(widht, width)
        """
        testFormatting(for: input, rule: .commonTypos)
    }

    func testIgnoresConfiguredTyposInCommentsAndIdentifiers() {
        let input = """
        private let retreivePreferedAdress = "" // Retreive the prefered adress
        """
        let output = """
        private let retreivePreferedAddress = "" // Retreive the prefered address
        """
        testFormatting(
            for: input,
            output,
            rule: .commonTypos,
            options: FormatOptions(ignoredTypos: ["RETREIVE", "prefered"])
        )
    }

    func testCorrectsCustomTyposInCommentsAndIdentifiers() {
        let input = """
        private let statuzColourAdress = "" // Statuz colour adress
        """
        let output = """
        private let statusColorAddress = "" // Status color address
        """
        testFormatting(
            for: input,
            output,
            rule: .commonTypos,
            options: FormatOptions(typos: ["statuz": "status", "colour": "color"])
        )
    }

    func testIgnoredTyposOverrideCustomTypos() {
        let input = """
        private let statuzColour = "" // Statuz colour
        """
        let output = """
        private let statuzColor = "" // Statuz color
        """
        testFormatting(
            for: input,
            output,
            rule: .commonTypos,
            options: FormatOptions(
                typos: ["statuz": "status", "colour": "color"],
                ignoredTypos: ["statuz"]
            )
        )
    }
}
