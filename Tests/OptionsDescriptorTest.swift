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
    func validateSut(_ sut: FormatOptions.Descriptor,
                     id: String,
                     name: String,
                     argumentName: String,
                     propertyName: String,
                     testName: String = #function) {
        XCTAssertEqual(sut.id, id, "\(testName) : id is -> \(id)")
        XCTAssertEqual(sut.name, name, "\(testName) : id is -> \(name)")
        XCTAssertEqual(sut.argumentName, argumentName, "\(testName) : id is -> \(argumentName)")
        XCTAssertEqual(sut.propertyName, propertyName, "\(testName) : id is -> \(propertyName)")
    }

    func validateSutThrowFormatErrorOptions(_ sut: FormatOptions.Descriptor, invalidArguments _: String = "invalid", testName: String = #function) {
        var options = FormatOptions()
        XCTAssertThrowsError(try sut.toOptions("invalid", &options),
                             "\(testName): Invalid format Throws") { err in
            guard case FormatError.options = err else {
                XCTAssertTrue(false, "\(testName): Throws a FormatError.options error")
                return
            }
        }
    }
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

// MARK: - Binary Options

extension OptionsDescriptorTest {
    func validateArgumentsBinaryType(sut: FormatOptions.Descriptor, controlTrue: [String], controlFalse: [String], default: Bool, testName: String = #function) {
        let values: (true: [String], false: [String]) = sut.type.associatedValue()

        let defaultControl = `default` ? controlTrue : controlFalse
        XCTAssertTrue(defaultControl.contains(sut.defaultArgument), "\(testName): Default argument map to \(`default`)")

        XCTAssertEqual(values.true[0], controlTrue[0], "\(testName): First item is prefered parameter name")
        XCTAssertEqual(values.false[0], controlFalse[0], "\(testName): First item is prefered parameter name")
        XCTAssertEqual(Set(values.true), Set(controlTrue), "\(testName): All possible true value have representation")
        XCTAssertEqual(Set(values.false), Set(controlFalse), "\(testName): All possible false value have representation")
    }

    func validateFromOptionsBinaryType(sut: FormatOptions.Descriptor, keyPath: WritableKeyPath<FormatOptions, Bool>, mapping: [String: Bool], functionName: String = #function) {
        var options = FormatOptions()
        for (argument, propertyValue) in mapping {
            options[keyPath: keyPath] = propertyValue
            XCTAssertEqual(sut.fromOptions(options), argument, "\(functionName): propertye value \(propertyValue) map to \(argument)")
        }
    }

    func validateFromArgumentsBinaryType(sut: FormatOptions.Descriptor, keyPath: WritableKeyPath<FormatOptions, Bool>, functionName: String = #function) {
        var options = FormatOptions()

        let values: (true: [String], false: [String]) = sut.type.associatedValue()
        let mappings: [(String, Bool)] = values.true.map { ($0, true) } + values.false.map { ($0, false) }

        mappings.forEach {
            options[keyPath: keyPath] = !$0.1
            try! sut.toOptions($0.0, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.1, "\(functionName): argument: \($0.0) transform to options Value: \($0.1)")

            options[keyPath: keyPath] = !$0.1
            try! sut.toOptions($0.0.uppercased(), &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.1, "\(functionName): uppercased argument: \($0.0) transform to options Value: \($0.1)")

            options[keyPath: keyPath] = !$0.1
            try! sut.toOptions($0.0.capitalized, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.1, "\(functionName): capitalized argument: \($0.0) transform to options Value: \($0.1)")
        }
    }
}

// MARK: void-representation

extension OptionsDescriptorTest {
    func test_voidRepresentation_IdentifierProperties() {
        let sut = FormatOptions.Descriptor.useVoid
        validateSut(sut, id: "void-representation", name: "empty", argumentName: "empty", propertyName: "useVoid")
    }

    func test_voidRepresentation_argumentValues() {
        let sut = FormatOptions.Descriptor.useVoid
        validateArgumentsBinaryType(sut: sut, controlTrue: ["void"], controlFalse: ["tuple", "tuples"], default: true)
    }

    func test_voidRepresentation_transformsFromOptions() {
        let sut = FormatOptions.Descriptor.useVoid
        validateFromOptionsBinaryType(sut: sut, keyPath: \FormatOptions.useVoid, mapping: ["tuples": false, "void": true])
    }

    func test_voidRepresentation_tranformsFromArguments() {
        let sut = FormatOptions.Descriptor.useVoid
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.useVoid)
        validateSutThrowFormatErrorOptions(sut)
    }
}

// MARK: allowInlineSemicolons

extension OptionsDescriptorTest {
    func test_allowInlineSemicolons_IdentifierProperties() {
        let sut = FormatOptions.Descriptor.allowInlineSemicolons
        validateSut(sut, id: "allow-inline-semicolons", name: "allowInlineSemicolons", argumentName: "semicolons", propertyName: "allowInlineSemicolons")
    }

    func test_allowInlineSemicolons_argumentValues() {
        let sut = FormatOptions.Descriptor.allowInlineSemicolons
        validateArgumentsBinaryType(sut: sut, controlTrue: ["inline"], controlFalse: ["never", "false"], default: true)
    }

    func test_allowInlineSemicolons_transformsFromOptions() {
        let sut = FormatOptions.Descriptor.allowInlineSemicolons
        validateFromOptionsBinaryType(sut: sut, keyPath: \FormatOptions.allowInlineSemicolons, mapping: ["never": false, "inline": true])
    }

    func test_allowInlineSemicolons_tranformsFromArguments() {
        let sut = FormatOptions.Descriptor.allowInlineSemicolons
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.allowInlineSemicolons)
        validateSutThrowFormatErrorOptions(sut)
    }
}

// MARK: - linebreak-character

extension OptionsDescriptorTest {
    func test_linebreakChar_idenrifierProperties() {
        let sut = FormatOptions.Descriptor.lineBreak
        validateSut(sut, id: "linebreak-character", name: "linebreak", argumentName: "linebreaks", propertyName: "linebreak")
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

        validateSutThrowFormatErrorOptions(sut)
    }
}

// MARK: - decimal-grouping

extension OptionsDescriptorTest {
    func test_decimalGrouping_idenrifierProperties() {
        let sut = FormatOptions.Descriptor.decimalGrouping
        validateSut(sut, id: "decimal-grouping", name: "decimalGrouping", argumentName: "decimalgrouping", propertyName: "decimalGrouping")
    }

    func test_decimalGrouping_argumentValues() {
        let sut = FormatOptions.Descriptor.decimalGrouping
        guard case let FormatOptions.Descriptor.ArgumentType.freeText(validator) = sut.type else {
            XCTAssert(false)
            return
        }

        let expectedMapping: [(input: String, isValid: Bool)] = [
            (input: "3,4", isValid: true),
            (input: " 3 , 5 ", isValid: true),
            (input: "ignore", isValid: true),
            (input: "none", isValid: true),
            (input: "4", isValid: true),
            (input: "foo", isValid: false),
            (input: "4,5 6 7", isValid: false),
            (input: "", isValid: false),
            (input: " ", isValid: false),
        ]

        XCTAssertEqual(sut.defaultArgument, "3,6")
        expectedMapping.forEach {
            XCTAssert(validator($0.input) == $0.isValid, "\($0.input) isValid: \($0.isValid)")
        }
    }

    func test_decimalGrouping_transformsFromOptions() {
        let sut = FormatOptions.Descriptor.decimalGrouping
        var options = FormatOptions()
        let expectedMapping: [(optionValue: Grouping, argumentValue: String)] = [
            (optionValue: Grouping.ignore, argumentValue: "ignore"),
            (optionValue: Grouping.none, argumentValue: "none"),
            (optionValue: Grouping.group(4, 5), argumentValue: "4,5"),
        ]

        expectedMapping.forEach {
            options.decimalGrouping = $0.optionValue
            XCTAssertEqual(sut.fromOptions(options), $0.argumentValue, "option: \($0.optionValue) map to argumentValue: \($0.argumentValue)")
        }
    }

    func test_decimalGrouping_tranformsFromArguments() {
        let sut = FormatOptions.Descriptor.decimalGrouping
        var options = FormatOptions()

        let expectedMapping: [(optionValue: Grouping, argumentValue: String)] = [
            (optionValue: Grouping.ignore, argumentValue: "ignore"),
            (optionValue: Grouping.none, argumentValue: "none"),
            (optionValue: Grouping.group(4, 5), argumentValue: "4,5"),
        ]

        options.decimalGrouping = Grouping.group(99, 99)
        expectedMapping.forEach {
            try! sut.toOptions($0.argumentValue, &options)
            XCTAssertEqual(options.decimalGrouping, $0.optionValue)
        }
        expectedMapping.forEach {
            try! sut.toOptions($0.argumentValue.uppercased(), &options)
            XCTAssertEqual(options.decimalGrouping, $0.optionValue)
        }

        validateSutThrowFormatErrorOptions(sut)
    }
}
