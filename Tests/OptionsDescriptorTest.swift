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
                             "Throws a FormatError.options error") { err in
            guard case FormatError.options = err else {
                XCTAssertTrue(false)
                return
            }
        }
    }
}
