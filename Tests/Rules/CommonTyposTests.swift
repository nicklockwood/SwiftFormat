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

    func testCorrectsPrivateAndInternalIdentifiersAndUses() {
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

    func testPreservesPublicAndPackageAPI() {
        let input = """
        public struct Reciever {
            public let widht: Int
            package func retreiveValue() {}
        }
        """
        testFormatting(for: input, rule: .commonTypos)
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
}
