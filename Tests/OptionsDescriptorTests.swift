//
//  OptionsDescriptorTest.swift
//  SwiftFormatTests
//
//  Created by Vincent Bernier on 10-02-18.
//  Copyright © 2018 Nick Lockwood.
//

import XCTest
@testable import SwiftFormat

class OptionsDescriptorTests: XCTestCase {
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.__allTests.count
            let darwinCount = thisClass.defaultTestSuite.testCaseCount
            XCTAssertEqual(linuxCount, darwinCount, "run swift test --generate-linuxmain")
        #endif
    }

    private typealias OptionArgumentMapping<T> = (optionValue: T, argumentValue: String)

    private func validateDescriptor(_ descriptor: FormatOptions.Descriptor,
                                    displayName: String,
                                    argumentName: String,
                                    propertyName: String,
                                    testName: String = #function) {
        XCTAssertEqual(descriptor.displayName, displayName, "\(testName) : Name is -> \(displayName)")
        XCTAssertEqual(descriptor.argumentName, argumentName, "\(testName) : argumentName is -> \(argumentName)")
        XCTAssertEqual(descriptor.propertyName, propertyName, "\(testName) : propertyName is -> \(propertyName)")
    }

    private func validateDescriptorThrowsOptionsError(_ descriptor: FormatOptions.Descriptor,
                                                      invalidArguments: String = "invalid",
                                                      testName: String = #function) {
        var options = FormatOptions.default
        XCTAssertThrowsError(try descriptor.toOptions(invalidArguments, &options),
                             "\(testName): Invalid format Throws") { err in
            guard case FormatError.options = err else {
                XCTFail("\(testName): Throws a FormatError.options error")
                return
            }
        }
    }

    private func validateFromArguments<T: Equatable>(_ descriptor: FormatOptions.Descriptor,
                                                     keyPath: WritableKeyPath<FormatOptions, T>,
                                                     expectations: [OptionArgumentMapping<T>],
                                                     testName: String = #function) {
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

    private func validateFromOptionalArguments<T: Equatable>(_ descriptor: FormatOptions.Descriptor,
                                                             keyPath: WritableKeyPath<FormatOptions, T>,
                                                             expectations: [OptionArgumentMapping<T>],
                                                             testCaseVariation: Bool = true,
                                                             testName: String = #function) {
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
    ///   - descriptor: FormatOptions.Descriptor being tested
    ///   - keyPath: to the FormatOptions property that is beeing validated
    ///   - expectations: Array of expectations for different inputs
    ///   - invalid: Provide if an invalid input can be store in FormatOptions. In Which case the default value should be return instead
    ///   - testName: for asserts clarity
    private func validateFromOptions<T>(_ descriptor: FormatOptions.Descriptor,
                                        keyPath: WritableKeyPath<FormatOptions, T>,
                                        expectations: [OptionArgumentMapping<T>],
                                        invalid: T? = nil,
                                        testName: String = #function) {
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

    private func validateArgumentsBinaryType(_ descriptor: FormatOptions.Descriptor,
                                             controlTrue: [String],
                                             controlFalse: [String],
                                             testName: String = #function) {
        let values: (true: [String], false: [String]) = descriptor.type.associatedValue()

        XCTAssertEqual(values.true[0], controlTrue[0], "\(testName): First item is prefered parameter name")
        XCTAssertEqual(values.false[0], controlFalse[0], "\(testName): First item is prefered parameter name")
        XCTAssertEqual(Set(values.true), Set(controlTrue), "\(testName): All possible true value have representation")
        XCTAssertEqual(Set(values.false), Set(controlFalse), "\(testName): All possible false value have representation")
    }

    private func validateFromArgumentsBinaryType(_ descriptor: FormatOptions.Descriptor,
                                                 keyPath: WritableKeyPath<FormatOptions, Bool>,
                                                 testName: String = #function) {
        let values: (true: [String], false: [String]) = descriptor.type.associatedValue()
        let mappings: [OptionArgumentMapping<Bool>] =
            values.true.map { (optionValue: true, argumentValue: $0) } + values.false.map { (optionValue: false, argumentValue: $0) }
        validateFromArguments(descriptor, keyPath: keyPath, expectations: mappings, testName: testName)
    }

    private func validateArgumentsListType(_ descriptor: FormatOptions.Descriptor,
                                           validArguments: Set<String>,
                                           testName: String = #function) {
        let values: [String] = descriptor.type.associatedValue()

        XCTAssertEqual(Set(values), validArguments, "\(testName): All valid arguments are accounted for")
        XCTAssertTrue(validArguments.contains(descriptor.defaultArgument), "\(testName): Default argument is part of the valide arguments")
    }

    private typealias FreeTextValidationExpectation = (input: String, isValid: Bool)

    private func validateArgumentsFreeTextType(_ descriptor: FormatOptions.Descriptor,
                                               expectations: [FreeTextValidationExpectation],
                                               testName: String = #function) {
        expectations.forEach {
            let isValid = descriptor.validateArgument($0.input)
            XCTAssertEqual(isValid, $0.isValid, "\(testName): \(isValid) != \($0.isValid)")
        }
    }

    private func validateGroupingDescriptor(_ descriptor: FormatOptions.Descriptor,
                                            displayName: String,
                                            argumentName: String,
                                            propertyName: String,
                                            keyPath: WritableKeyPath<FormatOptions, Grouping>,
                                            testName: String = #function) {
        let expectations: [FreeTextValidationExpectation] = [
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
        let fromOptionExpectations: [OptionArgumentMapping<Grouping>] = [
            (optionValue: Grouping.ignore, argumentValue: "ignore"),
            (optionValue: Grouping.none, argumentValue: "none"),
            (optionValue: Grouping.group(4, 5), argumentValue: "4,5"),
        ]
        let fromArgumentExpectations: [OptionArgumentMapping<Grouping>] = [
            (optionValue: Grouping.ignore, argumentValue: "ignore"),
            (optionValue: Grouping.none, argumentValue: "none"),
            (optionValue: Grouping.group(4, 5), argumentValue: "4,5"),
        ]

        validateDescriptor(descriptor, displayName: displayName, argumentName: argumentName, propertyName: propertyName, testName: testName)
        validateArgumentsFreeTextType(descriptor, expectations: expectations, testName: testName)
        validateFromOptions(descriptor, keyPath: keyPath, expectations: fromOptionExpectations, testName: testName)
        validateFromArguments(descriptor, keyPath: keyPath, expectations: fromArgumentExpectations, testName: testName)
        validateDescriptorThrowsOptionsError(descriptor, testName: testName)
    }

    // MARK: All options

    func testAllDescriptorsHaveProperty() {
        let allProperties = Set(FormatOptions.default.allOptions.keys)
        for descriptor in FormatOptions.Descriptor.all where !descriptor.isDeprecated {
            XCTAssert(allProperties.contains(descriptor.propertyName))
        }
    }

    func testAllPropertiesHaveDescriptor() {
        let allDescriptors = Set(FormatOptions.Descriptor.all.map { $0.propertyName })
        for property in FormatOptions.default.allOptions.keys {
            XCTAssert(allDescriptors.contains(property))
        }
    }

    func testDeprecatedPropertyList() {
        let controlArgumentNames = Set(["insertlines", "removelines", "hexliterals", "wrapelements", "experimental"])
        let descriptorArgumentNames = Set(FormatOptions.Descriptor.all.compactMap {
            $0.isDeprecated ? $0.argumentName : nil
        })
        XCTAssertEqual(descriptorArgumentNames, controlArgumentNames, "All deprecated options are represented by a descriptor")
    }

    // MARK: Individual options

    func testUseVoid() {
        let descriptor = FormatOptions.Descriptor.useVoid
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: false, argumentValue: "tuple"),
            (optionValue: true, argumentValue: "void"),
        ]
        validateDescriptor(descriptor, displayName: "Empty", argumentName: "empty", propertyName: "useVoid")
        validateArgumentsBinaryType(descriptor, controlTrue: ["void"], controlFalse: ["tuple", "tuples"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.useVoid, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.useVoid)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testAllowInlineSemicolons() {
        let descriptor = FormatOptions.Descriptor.allowInlineSemicolons
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: false, argumentValue: "never"),
            (optionValue: true, argumentValue: "inline"),
        ]
        validateDescriptor(descriptor, displayName: "Semicolons", argumentName: "semicolons", propertyName: "allowInlineSemicolons")
        validateArgumentsBinaryType(descriptor, controlTrue: ["inline"], controlFalse: ["never", "false"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.allowInlineSemicolons, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.allowInlineSemicolons)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testSpaceAroundRangeOperators() {
        let descriptor = FormatOptions.Descriptor.spaceAroundRangeOperators
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "spaced"),
            (optionValue: false, argumentValue: "no-space"),
        ]
        validateDescriptor(descriptor, displayName: "Ranges", argumentName: "ranges", propertyName: "spaceAroundRangeOperators")
        validateArgumentsBinaryType(descriptor, controlTrue: ["spaced", "space", "spaces"], controlFalse: ["no-space", "nospace"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.spaceAroundRangeOperators, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.spaceAroundRangeOperators)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testSpaceAroundOperatorDeclarations() {
        let descriptor = FormatOptions.Descriptor.spaceAroundOperatorDeclarations
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "spaced"),
            (optionValue: false, argumentValue: "no-space"),
        ]
        validateDescriptor(descriptor, displayName: "Operator Functions", argumentName: "operatorfunc", propertyName: "spaceAroundOperatorDeclarations")
        validateArgumentsBinaryType(descriptor, controlTrue: ["spaced", "space", "spaces"], controlFalse: ["no-space", "nospace"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.spaceAroundOperatorDeclarations, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.spaceAroundOperatorDeclarations)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testIndentCase() {
        let descriptor = FormatOptions.Descriptor.indentCase
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "true"),
            (optionValue: false, argumentValue: "false"),
        ]
        validateDescriptor(descriptor, displayName: "Indent Case", argumentName: "indentcase", propertyName: "indentCase")
        validateArgumentsBinaryType(descriptor, controlTrue: ["true"], controlFalse: ["false"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.indentCase, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.indentCase)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testTrailingCommas() {
        let descriptor = FormatOptions.Descriptor.trailingCommas
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "always"),
            (optionValue: false, argumentValue: "inline"),
        ]
        validateDescriptor(descriptor, displayName: "Commas", argumentName: "commas", propertyName: "trailingCommas")
        validateArgumentsBinaryType(descriptor, controlTrue: ["always", "true"], controlFalse: ["inline", "false"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.trailingCommas, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.trailingCommas)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testIndentComments() {
        let descriptor = FormatOptions.Descriptor.indentComments
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "indent"),
            (optionValue: false, argumentValue: "ignore"),
        ]
        validateDescriptor(descriptor, displayName: "Comments", argumentName: "comments", propertyName: "indentComments")
        validateArgumentsBinaryType(descriptor, controlTrue: ["indent", "indented"], controlFalse: ["ignore"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.indentComments, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.indentComments)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testTruncateBlankLines() {
        let descriptor = FormatOptions.Descriptor.truncateBlankLines
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "always"),
            (optionValue: false, argumentValue: "nonblank-lines"),
        ]
        validateDescriptor(descriptor, displayName: "Trim White Space", argumentName: "trimwhitespace", propertyName: "truncateBlankLines")
        validateArgumentsBinaryType(descriptor, controlTrue: ["always"], controlFalse: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank", "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.truncateBlankLines, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.truncateBlankLines)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testAllmanBraces() {
        let descriptor = FormatOptions.Descriptor.allmanBraces
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "true"),
            (optionValue: false, argumentValue: "false"),
        ]
        validateDescriptor(descriptor, displayName: "Allman Braces", argumentName: "allman", propertyName: "allmanBraces")
        validateArgumentsBinaryType(descriptor, controlTrue: ["true", "enabled"], controlFalse: ["false", "disabled"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.allmanBraces, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.allmanBraces)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testHexLiteralCase() {
        let descriptor = FormatOptions.Descriptor.hexLiteralCase
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "uppercase"),
            (optionValue: false, argumentValue: "lowercase"),
        ]
        validateDescriptor(descriptor, displayName: "Hex Literal Case", argumentName: "hexliteralcase", propertyName: "uppercaseHex")
        validateArgumentsBinaryType(descriptor, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.uppercaseHex, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.uppercaseHex)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testExponentCase() {
        let descriptor = FormatOptions.Descriptor.exponentCase
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "uppercase"),
            (optionValue: false, argumentValue: "lowercase"),
        ]
        validateDescriptor(descriptor, displayName: "Exponent Case", argumentName: "exponentcase", propertyName: "uppercaseExponent")
        validateArgumentsBinaryType(descriptor, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.uppercaseExponent, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.uppercaseExponent)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testLetPatternPlacement() {
        let descriptor = FormatOptions.Descriptor.letPatternPlacement
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "hoist"),
            (optionValue: false, argumentValue: "inline"),
        ]
        validateDescriptor(descriptor, displayName: "Pattern Let", argumentName: "patternlet", propertyName: "hoistPatternLet")
        validateArgumentsBinaryType(descriptor, controlTrue: ["hoist"], controlFalse: ["inline"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.hoistPatternLet, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.hoistPatternLet)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testElsePosition() {
        let descriptor = FormatOptions.Descriptor.elsePosition
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "next-line"),
            (optionValue: false, argumentValue: "same-line"),
        ]
        validateDescriptor(descriptor, displayName: "Else Position", argumentName: "elseposition", propertyName: "elseOnNextLine")
        validateArgumentsBinaryType(descriptor, controlTrue: ["next-line", "nextline"], controlFalse: ["same-line", "sameline"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.elseOnNextLine, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.elseOnNextLine)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testExplicitSelf() {
        let descriptor = FormatOptions.Descriptor.explicitSelf
        let expectedMapping: [OptionArgumentMapping<SelfMode>] = [
            (optionValue: .remove, argumentValue: "remove"),
            (optionValue: .insert, argumentValue: "insert"),
            (optionValue: .initOnly, argumentValue: "init-only"),
        ]
        validateDescriptor(descriptor, displayName: "Self", argumentName: "self", propertyName: "explicitSelf")
        validateArgumentsListType(descriptor, validArguments: ["remove", "insert", "init-only"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.explicitSelf, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.explicitSelf, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testExperimentalRules() {
        let descriptor = FormatOptions.Descriptor.experimentalRules
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "enabled"),
            (optionValue: false, argumentValue: "disabled"),
        ]
        validateDescriptor(descriptor, displayName: "Experimental Rules", argumentName: "experimental", propertyName: "experimentalRules")
        validateArgumentsBinaryType(descriptor, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.experimentalRules, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.experimentalRules)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testFragment() {
        let descriptor = FormatOptions.Descriptor.fragment
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "true"),
            (optionValue: false, argumentValue: "false"),
        ]
        validateDescriptor(descriptor, displayName: "Fragment", argumentName: "fragment", propertyName: "fragment")
        validateArgumentsBinaryType(descriptor, controlTrue: ["true", "enabled"], controlFalse: ["false", "disabled"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.fragment, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.fragment)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testIgnoreConflictMarkers() {
        let descriptor = FormatOptions.Descriptor.ignoreConflictMarkers
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "ignore"),
            (optionValue: false, argumentValue: "reject"),
        ]
        validateDescriptor(descriptor, displayName: "Conflict Markers", argumentName: "conflictmarkers", propertyName: "ignoreConflictMarkers")
        validateArgumentsBinaryType(descriptor, controlTrue: ["ignore", "true", "enabled"], controlFalse: ["reject", "false", "disabled"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.ignoreConflictMarkers, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.ignoreConflictMarkers)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testIfdefIndent() {
        let descriptor = FormatOptions.Descriptor.ifdefIndent
        let expectedMapping: [OptionArgumentMapping<IndentMode>] = [
            (optionValue: IndentMode.indent, argumentValue: "indent"),
            (optionValue: IndentMode.noIndent, argumentValue: "no-indent"),
            (optionValue: IndentMode.outdent, argumentValue: "outdent"),
        ]
        let alternateMapping: [OptionArgumentMapping<IndentMode>] = [
            (optionValue: IndentMode.noIndent, argumentValue: "noindent"),
        ]
        validateDescriptor(descriptor, displayName: "Ifdef Indent", argumentName: "ifdef", propertyName: "ifdefIndent")
        validateArgumentsListType(descriptor, validArguments: ["indent", "no-indent", "outdent"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.ifdefIndent, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.ifdefIndent, expectations: expectedMapping + alternateMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testLinebreakChar() {
        let descriptor = FormatOptions.Descriptor.lineBreak
        let expectedMapping: [OptionArgumentMapping<String>] = [
            (optionValue: "\n", argumentValue: "lf"),
            (optionValue: "\r", argumentValue: "cr"),
            (optionValue: "\r\n", argumentValue: "crlf"),
        ]
        validateDescriptor(descriptor, displayName: "Linebreak Character", argumentName: "linebreaks", propertyName: "linebreak")
        validateArgumentsListType(descriptor, validArguments: ["cr", "lf", "crlf"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.linebreak, expectations: expectedMapping, invalid: "invalid")
        validateFromArguments(descriptor, keyPath: \FormatOptions.linebreak, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testWrapArguments() {
        let descriptor = FormatOptions.Descriptor.wrapArguments
        let expectedMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "before-first"),
            (optionValue: .afterFirst, argumentValue: "after-first"),
            (optionValue: .preserve, argumentValue: "preserve"),
            (optionValue: .disabled, argumentValue: "disabled"),
        ]
        let alternateMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "beforefirst"),
            (optionValue: .afterFirst, argumentValue: "afterfirst"),
        ]
        validateDescriptor(descriptor, displayName: "Wrap Arguments", argumentName: "wraparguments", propertyName: "wrapArguments")
        validateArgumentsListType(descriptor, validArguments: [
            "before-first", "after-first", "preserve", "disabled",
        ])
        validateFromOptions(descriptor, keyPath: \FormatOptions.wrapArguments, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.wrapArguments, expectations: expectedMapping + alternateMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testWrapCollections() {
        let descriptor = FormatOptions.Descriptor.wrapCollections
        let expectedMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "before-first"),
            (optionValue: .afterFirst, argumentValue: "after-first"),
            (optionValue: .preserve, argumentValue: "preserve"),
            (optionValue: .disabled, argumentValue: "disabled"),
        ]
        let alternateMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "beforefirst"),
            (optionValue: .afterFirst, argumentValue: "afterfirst"),
        ]
        validateDescriptor(descriptor, displayName: "Wrap Collections", argumentName: "wrapcollections", propertyName: "wrapCollections")
        validateArgumentsListType(descriptor, validArguments: [
            "before-first", "after-first", "preserve", "disabled",
        ])
        validateFromOptions(descriptor, keyPath: \FormatOptions.wrapCollections, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.wrapCollections, expectations: expectedMapping + alternateMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testStripUnusedArguments() {
        let descriptor = FormatOptions.Descriptor.stripUnusedArguments
        let expectedMapping: [OptionArgumentMapping<ArgumentStrippingMode>] = [
            (optionValue: .unnamedOnly, argumentValue: "unnamed-only"),
            (optionValue: .closureOnly, argumentValue: "closure-only"),
            (optionValue: .all, argumentValue: "always"),
        ]
        validateDescriptor(descriptor, displayName: "Strip Unused Arguments", argumentName: "stripunusedargs", propertyName: "stripUnusedArguments")
        validateArgumentsListType(descriptor, validArguments: ["unnamed-only", "closure-only", "always"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.stripUnusedArguments, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.stripUnusedArguments, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testDecimalGrouping() {
        validateGroupingDescriptor(.decimalGrouping,
                                   displayName: "Decimal Grouping",
                                   argumentName: "decimalgrouping",
                                   propertyName: "decimalGrouping",
                                   keyPath: \FormatOptions.decimalGrouping)
    }

    func testBinaryGrouping() {
        validateGroupingDescriptor(.binaryGrouping,
                                   displayName: "Binary Grouping",
                                   argumentName: "binarygrouping",
                                   propertyName: "binaryGrouping",
                                   keyPath: \FormatOptions.binaryGrouping)
    }

    func testOctalGrouping() {
        validateGroupingDescriptor(.octalGrouping,
                                   displayName: "Octal Grouping",
                                   argumentName: "octalgrouping",
                                   propertyName: "octalGrouping",
                                   keyPath: \FormatOptions.octalGrouping)
    }

    func testHexGrouping() {
        validateGroupingDescriptor(.hexGrouping,
                                   displayName: "Hex Grouping",
                                   argumentName: "hexgrouping",
                                   propertyName: "hexGrouping",
                                   keyPath: \FormatOptions.hexGrouping)
    }

    func testFractionGrouping() {
        validateArgumentsBinaryType(.fractionGrouping,
                                    controlTrue: ["enabled", "true"],
                                    controlFalse: ["disabled", "false"])
    }

    func testExponentGrouping() {
        validateArgumentsBinaryType(.exponentGrouping,
                                    controlTrue: ["enabled", "true"],
                                    controlFalse: ["disabled", "false"])
    }

    func testIndentation() {
        let descriptor = FormatOptions.Descriptor.indentation
        let validations: [FreeTextValidationExpectation] = [
            (input: "tab", isValid: true),
            (input: "tabbed", isValid: true),
            (input: "tabs", isValid: true),
            (input: "tAb", isValid: true),
            (input: "TabbeD", isValid: true),
            (input: "TABS", isValid: true),
            (input: "2", isValid: true),
            (input: "4", isValid: true),
            (input: " 4", isValid: true),
            (input: "4 ", isValid: true),
            (input: "foo", isValid: false),
            (input: "4,5 6 7", isValid: false),
            (input: "", isValid: false),
            (input: " ", isValid: false),
        ]
        let fromOptionExpectations: [OptionArgumentMapping<String>] = [
            (optionValue: "\t", argumentValue: "tabs"),
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

        validateDescriptor(descriptor, displayName: "Indent", argumentName: "indent", propertyName: "indent")
        validateArgumentsFreeTextType(descriptor, expectations: validations)
        validateFromOptions(descriptor, keyPath: \FormatOptions.indent, expectations: fromOptionExpectations)
        validateFromArguments(descriptor, keyPath: \FormatOptions.indent, expectations: fromArgumentExpectations)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testFileHeader() {
        let descriptor = FormatOptions.Descriptor.fileHeader
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

        validateDescriptor(descriptor, displayName: "Header", argumentName: "header", propertyName: "fileHeader")
        validateArgumentsFreeTextType(descriptor, expectations: validations)
        validateFromOptions(descriptor, keyPath: \FormatOptions.fileHeader, expectations: fromOptionExpectations)
        validateFromOptionalArguments(descriptor, keyPath: \FormatOptions.fileHeader, expectations: fromArgumentExpectations, testCaseVariation: false)
    }

    // MARK: Deprecated

    func testInsertBlankLines() {
        let descriptor = FormatOptions.Descriptor.insertBlankLines
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "enabled"),
            (optionValue: false, argumentValue: "disabled"),
        ]
        validateDescriptor(descriptor, displayName: "Insert Lines", argumentName: "insertlines", propertyName: "insertBlankLines")
        validateArgumentsBinaryType(descriptor, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.insertBlankLines, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.insertBlankLines)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testRemoveBlankLines() {
        let descriptor = FormatOptions.Descriptor.removeBlankLines
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "enabled"),
            (optionValue: false, argumentValue: "disabled"),
        ]
        validateDescriptor(descriptor, displayName: "Remove Lines", argumentName: "removelines", propertyName: "removeBlankLines")
        validateArgumentsBinaryType(descriptor, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.removeBlankLines, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.removeBlankLines)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testHexliterals() {
        let descriptor = FormatOptions.Descriptor.hexLiterals
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "uppercase"),
            (optionValue: false, argumentValue: "lowercase"),
        ]
        validateDescriptor(descriptor, displayName: "hexliterals", argumentName: "hexliterals", propertyName: "uppercaseHex")
        validateArgumentsBinaryType(descriptor, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"])
        validateFromOptions(descriptor, keyPath: \FormatOptions.uppercaseHex, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.uppercaseHex)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testWrapElements() {
        let descriptor = FormatOptions.Descriptor.wrapElements
        let expectedMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "before-first"),
            (optionValue: .afterFirst, argumentValue: "after-first"),
            (optionValue: .preserve, argumentValue: "preserve"),
            (optionValue: .disabled, argumentValue: "disabled"),
        ]
        let alternateMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "beforefirst"),
            (optionValue: .afterFirst, argumentValue: "afterfirst"),
        ]
        validateDescriptor(descriptor, displayName: "Wrap Elements", argumentName: "wrapelements", propertyName: "wrapCollections")
        validateArgumentsListType(descriptor, validArguments: [
            "before-first", "after-first", "preserve", "disabled",
        ])
        validateFromOptions(descriptor, keyPath: \FormatOptions.wrapCollections, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.wrapCollections, expectations: expectedMapping + alternateMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }
}
