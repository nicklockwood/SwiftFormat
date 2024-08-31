//
//  ApplicationMainTests.swift
//  SwiftFormatTests
//
//  Created by Nick Lockwood on 5/20/23.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

class ApplicationMainTests: XCTestCase {
    func testUIApplicationMainReplacedByMain() {
        let input = """
        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {}
        """
        let output = """
        @main
        class AppDelegate: UIResponder, UIApplicationDelegate {}
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .applicationMain, options: options)
    }

    func testNSApplicationMainReplacedByMain() {
        let input = """
        @NSApplicationMain
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """
        let output = """
        @main
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """
        let options = FormatOptions(swiftVersion: "5.3")
        testFormatting(for: input, output, rule: .applicationMain, options: options)
    }

    func testNSApplicationMainNotReplacedInSwift5_2() {
        let input = """
        @NSApplicationMain
        class AppDelegate: NSObject, NSApplicationDelegate {}
        """
        let options = FormatOptions(swiftVersion: "5.2")
        testFormatting(for: input, rule: .applicationMain, options: options)
    }
}
