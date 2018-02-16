//
//  OptionsDescriptorTest.swift
//  SwiftFormatTests
//
//  Created by Vincent Bernier on 10-02-18.
//  Copyright © 2018 Nick Lockwood.
//

@testable import SwiftFormat
import XCTest

class OptionsDescriptorTest: XCTestCase {
}

// MARK: - They all exists

extension OptionsDescriptorTest {
    func allOptionsPropertyName() -> [String] {
        return Mirror(reflecting: FormatOptions()).children.flatMap { $0.label }
    }

//    let allArguments = Set(formatArguments + fileArguments)
//    let allOptions = allOptionsPropertyName()
//    XCTAssertTrue(allOptions.contains(sut.propertyName), "Property Name exist on FormatOptions")
//    XCTAssertTrue(allArguments.contains(sut.argumentName), "Argument Name exist in declared format and file arguments")
}

// MARK: - void-representation

extension OptionsDescriptorTest {
    func test_voidRepresentation_IdentifierProperties() {
        let sut = FormatOptions.Descriptor.useVoid

        XCTAssertEqual(sut.id, "void-representation")
        XCTAssertEqual(sut.name, "empty")
        XCTAssertEqual(sut.argumentName, "empty")
        XCTAssertEqual(sut.propertyName, "useVoid")
    }

    func test_voidRepresentation_argumentValues() {
        let sut = FormatOptions.Descriptor.useVoid
        let controlTrue = ["void"]
        let controlFalse = ["tuple", "tuples"]

        let values: (true: [String], false: [String]) = sut.type.associatedValue()

        XCTAssertEqual(values.true[0], controlTrue[0], "First item is prefered parameter name")
        XCTAssertEqual(values.false[0], controlFalse[0], "First item is prefered parameter name")
        XCTAssertTrue(controlTrue.contains(sut.defaultArgument), "Default argument map to True")
        XCTAssertEqual(Set(values.true), Set(controlTrue), "All possible true value have representation")
        XCTAssertEqual(Set(values.false), Set(controlFalse), "All possible false value have representation")
    }

    func test_voidRepresentation_transformsFromOptions() {
        let sut = FormatOptions.Descriptor.useVoid
        var options = FormatOptions()
        options.useVoid = false
        XCTAssertEqual(sut.fromOptions(options), "tuples")
        options.useVoid = true
        XCTAssertEqual(sut.fromOptions(options), "void")
    }

    func test_voidRepresentation_tranformsFromArguments() {
        let sut = FormatOptions.Descriptor.useVoid
        var options = FormatOptions()
        options.useVoid = false
        let values: (true: [String], false: [String]) = sut.type.associatedValue()
        //  TODO: Add test for lowecase()
        for t in values.true {
            options.useVoid = false
            try! sut.toOptions(t, &options)
            XCTAssertEqual(options.useVoid, true, "true arguments values map to true")
        }
        for f in values.false {
            options.useVoid = true
            try! sut.toOptions(f, &options)
            XCTAssertEqual(options.useVoid, false, "false arguments values map to false")
        }
        XCTAssertThrowsError(try sut.toOptions("invalid", &options),
                             "Invalid format Throws") { err in
            guard case FormatError.options = err else {
                XCTAssertTrue(false, "Throws a FormatError.options error")
                return
            }
        }
    }
}

// MARK: - linebreak-character

extension OptionsDescriptorTest {
    func test_linebreakChar_idenrifierProperties() {
        let sut = FormatOptions.Descriptor.lineBreak

        XCTAssertEqual(sut.id, "linebreak-character")
        XCTAssertEqual(sut.name, "linebreak")
        XCTAssertEqual(sut.argumentName, "linebreaks")
        XCTAssertEqual(sut.propertyName, "linebreak")
    }

    func test_lineBreakChar_argumentValues() {
        let sut = FormatOptions.Descriptor.lineBreak
        let controlSet = Set(["cr", "lf", "crlf"])

        let values: [String] = sut.type.associatedValue()

        XCTAssertEqual(Set(values), controlSet)
        XCTAssertEqual(sut.defaultArgument, "lf")
        XCTAssertTrue(controlSet.contains(sut.defaultArgument))
    }

    func test_lineBreakChar_transformsFromOptions() {
        let sut = FormatOptions.Descriptor.lineBreak
        var options = FormatOptions()

        let expectedMapping: [(optionValue: String, argumentValue: String)] = [
            (optionValue: "\n", argumentValue: "lf"),
            (optionValue: "\r", argumentValue: "cr"),
            (optionValue: "\r\n", argumentValue: "crlf"),
        ]

        for item in expectedMapping {
            options.linebreak = item.optionValue
            XCTAssertEqual(sut.fromOptions(options), item.argumentValue)
        }
        options.linebreak = "invalid"
        XCTAssertEqual(sut.fromOptions(options), sut.defaultArgument, "invalid input return the defautl value")
    }

    func test_lineBreakChar_tranformsFromArguments() {
        let sut = FormatOptions.Descriptor.lineBreak
        var options = FormatOptions()

        let expectedMapping: [(optionValue: String, argumentValue: String)] = [
            (optionValue: "\n", argumentValue: "lf"),
            (optionValue: "\r", argumentValue: "cr"),
            (optionValue: "\r\n", argumentValue: "crlf"),
        ]

        for item in expectedMapping {
            try! sut.toOptions(item.argumentValue, &options)
            XCTAssertEqual(options.linebreak, item.optionValue)
        }
        for item in expectedMapping {
            let arg = item.argumentValue.uppercased()
            try! sut.toOptions(arg, &options)
            XCTAssertEqual(options.linebreak, item.optionValue)
        }

        //  TODO: Exact copy paste
        XCTAssertThrowsError(try sut.toOptions("invalid", &options),
                             "Invalid format Throws") { err in
            guard case FormatError.options = err else {
                XCTAssertTrue(false, "Throws a FormatError.options error")
                return
            }
        }
    }
}
