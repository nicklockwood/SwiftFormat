//
//  OptionDescriptorTest.swift
//  SwiftFormatTests
//
//  Created by Vincent Bernier on 10-02-18.
//  Copyright © 2018 Nick Lockwood.
//

import XCTest
@testable import SwiftFormat

class OptionDescriptorTests: XCTestCase {
    private typealias OptionArgumentMapping<T> = (optionValue: T, argumentValue: String)

    private func validateDescriptorThrowsOptionsError(_ descriptor: OptionDescriptor,
                                                      invalidArguments: String = "invalid",
                                                      testName: String = #function)
    {
        var options = FormatOptions.default
        XCTAssertThrowsError(try descriptor.toOptions(invalidArguments, &options),
                             "\(testName): Invalid format Throws")
        { err in
            guard case FormatError.options = err else {
                XCTFail("\(testName): Throws a FormatError.options error")
                return
            }
        }
    }

    private func validateFromArguments<T: Equatable>(_ descriptor: OptionDescriptor,
                                                     keyPath: WritableKeyPath<FormatOptions, T>,
                                                     expectations: [OptionArgumentMapping<T>],
                                                     testName: String = #function)
    {
        var options = FormatOptions.default
        expectations.forEach {
            do {
                try descriptor.toOptions($0.argumentValue, &options)
                XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument \($0.argumentValue) map to option \($0.optionValue)")
                try descriptor.toOptions($0.argumentValue.uppercased(), &options)
                XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument Uppercased \($0.argumentValue) map to option \($0.optionValue)")
                try descriptor.toOptions($0.argumentValue.capitalized, &options)
                XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument capitalized \($0.argumentValue) map to option \($0.optionValue)")
            } catch {
                XCTFail("\(testName): error: \(error)")
            }
        }
    }

    private func validateFromOptionalArguments<T: Equatable>(_ descriptor: OptionDescriptor,
                                                             keyPath: WritableKeyPath<FormatOptions, T>,
                                                             expectations: [OptionArgumentMapping<T>],
                                                             testCaseVariation: Bool = true,
                                                             testName: String = #function)
    {
        var options = FormatOptions.default
        expectations.forEach {
            do {
                try descriptor.toOptions($0.argumentValue, &options)
                XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument \($0.argumentValue) map to option \(String(describing: $0.optionValue))")
                if testCaseVariation {
                    do {
                        try descriptor.toOptions($0.argumentValue.uppercased(), &options)
                        XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument Uppercased \($0.argumentValue) map to option \(String(describing: $0.optionValue))")
                        try descriptor.toOptions($0.argumentValue.capitalized, &options)
                        XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument capitalized \($0.argumentValue) map to option \(String(describing: $0.optionValue))")
                    } catch {
                        XCTFail("\(testName): error: \(error)")
                    }
                }
            } catch {
                XCTFail("\(testName): error: \(error)")
            }
        }
    }

    /// Validate From FormatOptions to Argument String
    ///
    /// - Parameters:
    ///   - descriptor: OptionDescriptor being tested
    ///   - keyPath: to the FormatOptions property that is being validated
    ///   - expectations: Array of expectations for different inputs
    ///   - invalid: Invalid FormatOptions value, which should yield the defaultArgument value
    ///   - testName: for assertion clarity
    private func validateFromOptions<T>(_ descriptor: OptionDescriptor,
                                        keyPath: WritableKeyPath<FormatOptions, T>,
                                        expectations: [OptionArgumentMapping<T>],
                                        invalid: T? = nil,
                                        testName: String = #function)
    {
        var options = FormatOptions.default
        for item in expectations {
            options[keyPath: keyPath] = item.optionValue
            XCTAssertEqual(descriptor.fromOptions(options), item.argumentValue, "\(testName): Option is transformed to argument")
        }

        if let invalid = invalid {
            options[keyPath: keyPath] = invalid
            XCTAssertEqual(descriptor.fromOptions(options), descriptor.defaultArgument, "\(testName): invalid input return the default value")
        }
    }

    private typealias FreeTextValidationExpectation = (input: String, isValid: Bool)

    private func validateArgumentsFreeTextType(_ descriptor: OptionDescriptor,
                                               expectations: [FreeTextValidationExpectation],
                                               testName: String = #function)
    {
        expectations.forEach {
            let isValid = descriptor.validateArgument($0.input)
            XCTAssertEqual(isValid, $0.isValid, "\(testName): \(isValid) != \($0.isValid)")
        }
    }

    // MARK: All options

    func testAllDescriptorsHaveProperty() {
        let allProperties = Set(FormatOptions.default.allOptions.keys)
        for descriptor in Descriptors.all where !descriptor.isDeprecated {
            XCTAssert(allProperties.contains(descriptor.propertyName))
        }
    }

    func testAllPropertiesHaveDescriptor() {
        let allDescriptors = Set(Descriptors.all.map { $0.propertyName })
        for property in FormatOptions.default.allOptions.keys {
            XCTAssert(allDescriptors.contains(property))
        }
    }

    func testIndentation() {
        let descriptor = Descriptors.indent
        let validations: [FreeTextValidationExpectation] = [
            (input: "tab", isValid: true),
            (input: "tabbed", isValid: true),
            (input: "tabs", isValid: true),
            (input: "tAb", isValid: true),
            (input: "TabbeD", isValid: true),
            (input: "TABS", isValid: true),
            (input: "2", isValid: true),
            (input: "4", isValid: true),
            (input: "foo", isValid: false),
            (input: "4,5 6 7", isValid: false),
            (input: "", isValid: false),
            (input: " ", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<String>] = [
            (optionValue: "\t", argumentValue: "tab"),
            (optionValue: " ", argumentValue: "1"),
            (optionValue: "1234", argumentValue: "4"),
        ]
        let fromArgumentExpectations: [OptionArgumentMapping<String>] = [
            (optionValue: "\t", argumentValue: "tabs"),
            (optionValue: "\t", argumentValue: "tab"),
            (optionValue: "\t", argumentValue: "tabbed"),
            (optionValue: "\t", argumentValue: "tabs"),
            (optionValue: " ", argumentValue: "1"),
            (optionValue: "    ", argumentValue: "4"),
        ]

        validateArgumentsFreeTextType(descriptor, expectations: validations)
        validateFromOptions(descriptor, keyPath: \FormatOptions.indent, expectations: fromOptionExpectations)
        validateFromArguments(descriptor, keyPath: \FormatOptions.indent, expectations: fromArgumentExpectations)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testFileHeader() {
        let descriptor = Descriptors.fileHeader
        let validations: [FreeTextValidationExpectation] = [
            (input: "tab", isValid: true),
            (input: "", isValid: true),
            (input: "// Bob \n\n// {year}\n", isValid: true),
            (input: "/*\n\n\n*/", isValid: true),
            (input: "\n\n\n", isValid: true),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<HeaderStrippingMode>] = [
            (optionValue: "", argumentValue: "strip"),
            (optionValue: "// Header", argumentValue: "// Header"),
            (optionValue: .ignore, argumentValue: "ignore"),
            (optionValue: "/*\n\n\n*/", argumentValue: "/*\\n\\n\\n*/"),
        ]
        let fromArgumentExpectations: [OptionArgumentMapping<HeaderStrippingMode>] = [
            (optionValue: "", argumentValue: "strip"),
            (optionValue: "// Header", argumentValue: "// Header"),
            (optionValue: .ignore, argumentValue: "ignore"),
            (optionValue: "// {year}", argumentValue: "{year}"),
            (optionValue: "/*\n\n\n*/", argumentValue: "/*\\n\\n\\n*/"),
            (optionValue: "//\n//\n//\n//\n//", argumentValue: "\\n\\n\\n\\n"),
            (optionValue: "//\n//\n// a\n//\n//", argumentValue: "\\n\\na\\n\\n"),
            (optionValue: "//\n// a\n//\n// a\n//", argumentValue: "\\na\\n\\na\\n"),
            (optionValue: "// a\n//", argumentValue: "a\\n"),
            (optionValue: "//a\n//b", argumentValue: "//a\\n//b"),
        ]

        validateArgumentsFreeTextType(descriptor, expectations: validations)
        validateFromOptions(descriptor, keyPath: \FormatOptions.fileHeader, expectations: fromOptionExpectations)
        validateFromOptionalArguments(descriptor, keyPath: \FormatOptions.fileHeader, expectations: fromArgumentExpectations, testCaseVariation: false)
    }

    func testNoSpaceOperators() {
        let descriptor = Descriptors.noSpaceOperators
        let validations: [FreeTextValidationExpectation] = [
            (input: "+", isValid: true),
            (input: "", isValid: true),
            (input: ":", isValid: true),
            (input: "foo", isValid: false),
            (input: ";", isValid: false),
            (input: "?", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<Set<String>>] = [
            (optionValue: [], argumentValue: ""),
            (optionValue: ["*", "/"], argumentValue: "*,/"),
        ]
        validateFromOptions(descriptor, keyPath: \FormatOptions.noSpaceOperators, expectations: fromOptionExpectations)
        validateArgumentsFreeTextType(descriptor, expectations: validations)
        var options = FormatOptions()
        XCTAssertNoThrow(try descriptor.toOptions("+,+", &options))
    }

    func testNoWrapOperators() {
        let descriptor = Descriptors.noWrapOperators
        let validations: [FreeTextValidationExpectation] = [
            (input: "+", isValid: true),
            (input: "", isValid: true),
            (input: ":", isValid: true),
            (input: "foo", isValid: false),
            (input: ";", isValid: true),
            (input: "?", isValid: true),
            (input: "try", isValid: false),
            (input: "as", isValid: true),
            (input: "as?", isValid: true),
            (input: "is", isValid: true),
            (input: "do", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<Set<String>>] = [
            (optionValue: [], argumentValue: ""),
            (optionValue: ["*", "/"], argumentValue: "*,/"),
        ]
        validateFromOptions(descriptor, keyPath: \FormatOptions.noWrapOperators, expectations: fromOptionExpectations)
        validateArgumentsFreeTextType(descriptor, expectations: validations)
        var options = FormatOptions()
        XCTAssertNoThrow(try descriptor.toOptions("+,+", &options))
    }

    func testModifierOrder() {
        let descriptor = Descriptors.modifierOrder
        var options = FormatOptions()
        let swiftLintDefaults = "override,acl,setterACL,dynamic,mutators,lazy,final,required,convenience,typeMethods,owned"
        XCTAssertNoThrow(try descriptor.toOptions(swiftLintDefaults, &options))
    }

    func testFormatOptionsDescriptionConsistency() {
        let options1 = FormatOptions(selfRequired: ["foo", "bar", "baz"])
        let options2 = FormatOptions(selfRequired: ["baz", "bar", "foo"])
        XCTAssertEqual(options1.description, options2.description)
    }
}
