//
//  OptionsDescriptorTest.swift
//  SwiftFormatTests
//
//  Created by Vincent Bernier on 10-02-18.
//  Copyright © 2018 Nick Lockwood.
//

@testable import SwiftFormat
import XCTest

class OptionsDescriptorTests: XCTestCase {
    private typealias OptionArgumentMapping<T> = (optionValue: T, argumentValue: String)

    private func validateDescriptor(_ descriptor: FormatOptions.Descriptor,
                                    id: String,
                                    name: String,
                                    argumentName: String,
                                    propertyName: String,
                                    testName: String = #function) {
        XCTAssertEqual(descriptor.id, id, "\(testName) : id is -> \(id)")
        XCTAssertEqual(descriptor.name, name, "\(testName) : Name is -> \(name)")
        XCTAssertEqual(descriptor.argumentName, argumentName, "\(testName) : argumentName is -> \(argumentName)")
        XCTAssertEqual(descriptor.propertyName, propertyName, "\(testName) : propertyName is -> \(propertyName)")
    }

    private func validateDescriptorThrowsOptionsError(_ descriptor: FormatOptions.Descriptor,
                                                      invalidArguments: String = "invalid",
                                                      testName: String = #function) {
        var options = FormatOptions()
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
        var options = FormatOptions()
        expectations.forEach {
            try! descriptor.toOptions($0.argumentValue, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument \($0.argumentValue) map to option \($0.optionValue)")
            try! descriptor.toOptions($0.argumentValue.uppercased(), &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument Uppercased \($0.argumentValue) map to option \($0.optionValue)")
            try! descriptor.toOptions($0.argumentValue.capitalized, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument capitalized \($0.argumentValue) map to option \($0.optionValue)")
        }
    }

    private func validateFromOptionalArguments<T: Equatable>(_ descriptor: FormatOptions.Descriptor,
                                                             keyPath: WritableKeyPath<FormatOptions, T?>,
                                                             expectations: [OptionArgumentMapping<T?>],
                                                             testCaseVariation: Bool = true,
                                                             testName: String = #function) {
        var options = FormatOptions()
        expectations.forEach {
            try! descriptor.toOptions($0.argumentValue, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument \($0.argumentValue) map to option \(String(describing: $0.optionValue))")
            if testCaseVariation {
                try! descriptor.toOptions($0.argumentValue.uppercased(), &options)
                XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument Uppercased \($0.argumentValue) map to option \(String(describing: $0.optionValue))")
                try! descriptor.toOptions($0.argumentValue.capitalized, &options)
                XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument capitalized \($0.argumentValue) map to option \(String(describing: $0.optionValue))")
            }
        }
    }

    /// Validate From FormatOptions to Argument String
    ///
    /// - Parameters:
    ///   - sut: System Under Test
    ///   - keyPath: to the FormatOptions property that is beeing validated
    ///   - expectations: Array of expectations for different inputs
    ///   - invalid: Provide if an invalid input can be store in FormatOptions. In Which case the default value should be return instead
    ///   - testName: for asserts clarity
    private func validateFromOptions<T>(_ descriptor: FormatOptions.Descriptor,
                                        keyPath: WritableKeyPath<FormatOptions, T>,
                                        expectations: [OptionArgumentMapping<T>],
                                        invalid: T? = nil,
                                        testName: String = #function) {
        var options = FormatOptions()
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
                                             default: Bool,
                                             testName: String = #function) {
        let values: (true: [String], false: [String]) = descriptor.type.associatedValue()

        let defaultControl = `default` ? controlTrue : controlFalse
        XCTAssertTrue(defaultControl.contains(descriptor.defaultArgument), "\(testName): Default argument map to \(`default`)")

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
                                           default: String,
                                           testName: String = #function) {
        let values: [String] = descriptor.type.associatedValue()

        XCTAssertEqual(Set(values), validArguments, "\(testName): All valid arguments are accounted for")
        XCTAssertEqual(descriptor.defaultArgument, `default`, "\(testName): Default argument is \(`default`)")
        XCTAssertTrue(validArguments.contains(descriptor.defaultArgument), "\(testName): Default argument is part of the valide arguments")
    }

    private typealias FreeTextValidationExpectation = (input: String, isValid: Bool)

    private func validateArgumentsFreeTextType(_ descriptor: FormatOptions.Descriptor,
                                               expectations: [FreeTextValidationExpectation],
                                               default: String,
                                               testName: String = #function) {
        guard case let FormatOptions.Descriptor.ArgumentType.freeText(validator) = descriptor.type else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(descriptor.defaultArgument, `default`, "\(testName): Default Argument value is: \(`default`)")
        expectations.forEach {
            XCTAssert(validator($0.input) == $0.isValid, "\(testName): \($0.input) isValid: \($0.isValid)")
        }
    }

    private func validateGroupingDescriptor(_ descriptor: FormatOptions.Descriptor,
                                            id: String,
                                            name: String,
                                            argumentName: String,
                                            propertyName: String,
                                            default: String,
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

        validateDescriptor(descriptor, id: id, name: name, argumentName: argumentName, propertyName: propertyName, testName: testName)
        validateArgumentsFreeTextType(descriptor, expectations: expectations, default: `default`, testName: testName)
        validateFromOptions(descriptor, keyPath: keyPath, expectations: fromOptionExpectations, testName: testName)
        validateFromArguments(descriptor, keyPath: keyPath, expectations: fromArgumentExpectations, testName: testName)
        validateDescriptorThrowsOptionsError(descriptor, testName: testName)
    }

    // MARK: All options

    func testAllPropertyHaveDescriptor() {
        let allProperties = Set(FormatOptions().allOptions.keys)
        let allDescriptorWithProperty = FormatOptions.Descriptor.deprecatedWithProperty +
            FormatOptions.Descriptor.formats + FormatOptions.Descriptor.files
        let allDescriptorProperty = Set(allDescriptorWithProperty.map { $0.propertyName })

        XCTAssertEqual(allDescriptorWithProperty.count, allProperties.count, "Property and descriptor have equal count")
        XCTAssertEqual(allDescriptorProperty, allProperties, "Each property have a descriptor with the same property name")
    }

    func testDeprecatedPropertyList() {
        let deprecated = FormatOptions.Descriptor.deprecated
        let controlArgumentNames = Set(["insertlines", "removelines", "hexliterals", "wrapelements"])
        let sutArgumentNames = Set(deprecated.map { $0.argumentName })
        XCTAssertEqual(sutArgumentNames, controlArgumentNames, "All deprecated name are represented by a descriptor")
    }

    // MARK: Individual options

    func testUseVoid() {
        let descriptor = FormatOptions.Descriptor.useVoid
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: false, argumentValue: "tuples"),
            (optionValue: true, argumentValue: "void"),
        ]
        validateDescriptor(descriptor, id: "empty", name: "Empty", argumentName: "empty", propertyName: "useVoid")
        validateArgumentsBinaryType(descriptor, controlTrue: ["void"], controlFalse: ["tuple", "tuples"], default: true)
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
        validateDescriptor(descriptor, id: "semicolons", name: "Semicolons", argumentName: "semicolons", propertyName: "allowInlineSemicolons")
        validateArgumentsBinaryType(descriptor, controlTrue: ["inline"], controlFalse: ["never", "false"], default: true)
        validateFromOptions(descriptor, keyPath: \FormatOptions.allowInlineSemicolons, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.allowInlineSemicolons)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testSpaceAroundRangeOperators() {
        let descriptor = FormatOptions.Descriptor.spaceAroundRangeOperators
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "spaced"),
            (optionValue: false, argumentValue: "nospace"),
        ]
        validateDescriptor(descriptor, id: "ranges", name: "Ranges", argumentName: "ranges", propertyName: "spaceAroundRangeOperators")
        validateArgumentsBinaryType(descriptor, controlTrue: ["space", "spaced", "spaces"], controlFalse: ["nospace"], default: true)
        validateFromOptions(descriptor, keyPath: \FormatOptions.spaceAroundRangeOperators, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.spaceAroundRangeOperators)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testSpaceAroundOperatorDeclarations() {
        let descriptor = FormatOptions.Descriptor.spaceAroundOperatorDeclarations
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "spaced"),
            (optionValue: false, argumentValue: "nospace"),
        ]
        validateDescriptor(descriptor, id: "operator-func", name: "Operator Func", argumentName: "operatorfunc", propertyName: "spaceAroundOperatorDeclarations")
        validateArgumentsBinaryType(descriptor, controlTrue: ["space", "spaced", "spaces"], controlFalse: ["nospace"], default: true)
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
        validateDescriptor(descriptor, id: "indent-case", name: "Indent Case", argumentName: "indentcase", propertyName: "indentCase")
        validateArgumentsBinaryType(descriptor, controlTrue: ["true"], controlFalse: ["false"], default: false)
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
        validateDescriptor(descriptor, id: "commas", name: "Commas", argumentName: "commas", propertyName: "trailingCommas")
        validateArgumentsBinaryType(descriptor, controlTrue: ["always", "true"], controlFalse: ["inline", "false"], default: true)
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
        validateDescriptor(descriptor, id: "comments", name: "Comments", argumentName: "comments", propertyName: "indentComments")
        validateArgumentsBinaryType(descriptor, controlTrue: ["indent", "indented"], controlFalse: ["ignore"], default: true)
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
        validateDescriptor(descriptor, id: "trim-white-space", name: "Trim White Space", argumentName: "trimwhitespace", propertyName: "truncateBlankLines")
        validateArgumentsBinaryType(descriptor, controlTrue: ["always"], controlFalse: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank", "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"], default: true)
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
        validateDescriptor(descriptor, id: "allman", name: "Allman Braces", argumentName: "allman", propertyName: "allmanBraces")
        validateArgumentsBinaryType(descriptor, controlTrue: ["true", "enabled"], controlFalse: ["false", "disabled"], default: false)
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
        validateDescriptor(descriptor, id: "hex-literal-case", name: "Hex Literal Case", argumentName: "hexliteralcase", propertyName: "uppercaseHex")
        validateArgumentsBinaryType(descriptor, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"], default: true)
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
        validateDescriptor(descriptor, id: "exponent-case", name: "Exponent Case", argumentName: "exponentcase", propertyName: "uppercaseExponent")
        validateArgumentsBinaryType(descriptor, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"], default: false)
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
        validateDescriptor(descriptor, id: "pattern-let", name: "Pattern Let", argumentName: "patternlet", propertyName: "hoistPatternLet")
        validateArgumentsBinaryType(descriptor, controlTrue: ["hoist"], controlFalse: ["inline"], default: true)
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
        validateDescriptor(descriptor, id: "else-position", name: "Else Position", argumentName: "elseposition", propertyName: "elseOnNextLine")
        validateArgumentsBinaryType(descriptor, controlTrue: ["next-line", "nextline"], controlFalse: ["same-line", "sameline"], default: false)
        validateFromOptions(descriptor, keyPath: \FormatOptions.elseOnNextLine, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.elseOnNextLine)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testRemoveSelf() {
        let descriptor = FormatOptions.Descriptor.removeSelf
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "remove"),
            (optionValue: false, argumentValue: "insert"),
        ]
        validateDescriptor(descriptor, id: "self", name: "Self", argumentName: "self", propertyName: "removeSelf")
        validateArgumentsBinaryType(descriptor, controlTrue: ["remove"], controlFalse: ["insert"], default: true)
        validateFromOptions(descriptor, keyPath: \FormatOptions.removeSelf, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.removeSelf)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testExperimentalRules() {
        let descriptor = FormatOptions.Descriptor.experimentalRules
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "enabled"),
            (optionValue: false, argumentValue: "disabled"),
        ]
        validateDescriptor(descriptor, id: "experimental", name: "Experimental Rules", argumentName: "experimental", propertyName: "experimentalRules")
        validateArgumentsBinaryType(descriptor, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"], default: false)
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
        validateDescriptor(descriptor, id: "fragment", name: "Fragment", argumentName: "fragment", propertyName: "fragment")
        validateArgumentsBinaryType(descriptor, controlTrue: ["true", "enabled"], controlFalse: ["false", "disabled"], default: false)
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
        validateDescriptor(descriptor, id: "conflict-markers", name: "Conflict Markers", argumentName: "conflictmarkers", propertyName: "ignoreConflictMarkers")
        validateArgumentsBinaryType(descriptor, controlTrue: ["ignore", "true", "enabled"], controlFalse: ["reject", "false", "disabled"], default: false)
        validateFromOptions(descriptor, keyPath: \FormatOptions.ignoreConflictMarkers, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.ignoreConflictMarkers)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testIfdefIndent() {
        let descriptor = FormatOptions.Descriptor.ifdefIndent
        let expectedMapping: [OptionArgumentMapping<IndentMode>] = [
            (optionValue: IndentMode.indent, argumentValue: "indent"),
            (optionValue: IndentMode.noIndent, argumentValue: "noindent"),
            (optionValue: IndentMode.outdent, argumentValue: "outdent"),
        ]

        validateDescriptor(descriptor, id: "ifdef", name: "ifdef Indent", argumentName: "ifdef", propertyName: "ifdefIndent")
        validateArgumentsListType(descriptor, validArguments: ["indent", "noindent", "outdent"], default: "indent")
        validateFromOptions(descriptor, keyPath: \FormatOptions.ifdefIndent, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.ifdefIndent, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testLinebreakChar() {
        let descriptor = FormatOptions.Descriptor.lineBreak
        let expectedMapping: [OptionArgumentMapping<String>] = [
            (optionValue: "\n", argumentValue: "lf"),
            (optionValue: "\r", argumentValue: "cr"),
            (optionValue: "\r\n", argumentValue: "crlf"),
        ]
        validateDescriptor(descriptor, id: "linebreaks", name: "Linebreaks Character", argumentName: "linebreaks", propertyName: "linebreak")
        validateArgumentsListType(descriptor, validArguments: ["cr", "lf", "crlf"], default: "lf")
        validateFromOptions(descriptor, keyPath: \FormatOptions.linebreak, expectations: expectedMapping, invalid: "invalid")
        validateFromArguments(descriptor, keyPath: \FormatOptions.linebreak, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testWrapArguments() {
        let descriptor = FormatOptions.Descriptor.wrapArguments
        let expectedMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "beforefirst"),
            (optionValue: .afterFirst, argumentValue: "afterfirst"),
            (optionValue: .disabled, argumentValue: "disabled"),
        ]
        validateDescriptor(descriptor, id: "wrap-arguments", name: "Wrap Arguments", argumentName: "wraparguments", propertyName: "wrapArguments")
        validateArgumentsListType(descriptor, validArguments: ["beforefirst", "afterfirst", "disabled"], default: "disabled")
        validateFromOptions(descriptor, keyPath: \FormatOptions.wrapArguments, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.wrapArguments, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testWrapCollections() {
        let descriptor = FormatOptions.Descriptor.wrapCollections
        let expectedMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "beforefirst"),
            (optionValue: .afterFirst, argumentValue: "afterfirst"),
            (optionValue: .disabled, argumentValue: "disabled"),
        ]
        validateDescriptor(descriptor, id: "wrap-collections", name: "Wrap Collections", argumentName: "wrapcollections", propertyName: "wrapCollections")
        validateArgumentsListType(descriptor, validArguments: ["beforefirst", "afterfirst", "disabled"], default: "beforefirst")
        validateFromOptions(descriptor, keyPath: \FormatOptions.wrapCollections, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.wrapCollections, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testStripUnusedArguments() {
        let descriptor = FormatOptions.Descriptor.stripUnusedArguments
        let expectedMapping: [OptionArgumentMapping<ArgumentStrippingMode>] = [
            (optionValue: .unnamedOnly, argumentValue: "unnamed-only"),
            (optionValue: .closureOnly, argumentValue: "closure-only"),
            (optionValue: .all, argumentValue: "always"),
        ]
        validateDescriptor(descriptor, id: "strip-unused-args", name: "Strip Unused Arguments", argumentName: "stripunusedargs", propertyName: "stripUnusedArguments")
        validateArgumentsListType(descriptor, validArguments: ["unnamed-only", "closure-only", "always"], default: "always")
        validateFromOptions(descriptor, keyPath: \FormatOptions.stripUnusedArguments, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.stripUnusedArguments, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testDecimalGrouping() {
        validateGroupingDescriptor(.decimalGrouping,
                                   id: "decimal-grouping",
                                   name: "Decimal Grouping",
                                   argumentName: "decimalgrouping",
                                   propertyName: "decimalGrouping",
                                   default: "3,6",
                                   keyPath: \FormatOptions.decimalGrouping)
    }

    func testBinaryGrouping() {
        validateGroupingDescriptor(.binaryGrouping,
                                   id: "binary-grouping",
                                   name: "Binary Grouping",
                                   argumentName: "binarygrouping",
                                   propertyName: "binaryGrouping",
                                   default: "4,8",
                                   keyPath: \FormatOptions.binaryGrouping)
    }

    func testOctalGrouping() {
        validateGroupingDescriptor(.octalGrouping,
                                   id: "octal-grouping",
                                   name: "Octal Grouping",
                                   argumentName: "octalgrouping",
                                   propertyName: "octalGrouping",
                                   default: "4,8",
                                   keyPath: \FormatOptions.octalGrouping)
    }

    func testHexGrouping() {
        validateGroupingDescriptor(.hexGrouping,
                                   id: "hex-grouping",
                                   name: "Hex Grouping",
                                   argumentName: "hexgrouping",
                                   propertyName: "hexGrouping",
                                   default: "4,8",
                                   keyPath: \FormatOptions.hexGrouping)
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

        validateDescriptor(descriptor, id: "indent", name: "Indent", argumentName: "indent", propertyName: "indent")
        validateArgumentsFreeTextType(descriptor, expectations: validations, default: "4")
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
        let fromOptionExpectations: [OptionArgumentMapping<String?>] = [
            (optionValue: "", argumentValue: "strip"),
            (optionValue: "// Header", argumentValue: "// Header"),
            (optionValue: nil, argumentValue: "ignore"),
            (optionValue: "/*\n\n\n*/", argumentValue: "/*\n\n\n*/"),
        ]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let thisYear = formatter.string(from: Date())
        let fromArgumentExpectations: [OptionArgumentMapping<String?>] = [
            (optionValue: "", argumentValue: "strip"),
            (optionValue: "// Header", argumentValue: "// Header"),
            (optionValue: nil, argumentValue: "ignore"),
            (optionValue: "//\(thisYear)", argumentValue: "{year}"),
            (optionValue: "/*\n\n\n*/", argumentValue: "/*\\n\\n\\n*/"),
            (optionValue: "//\n//\n//\n//\n//", argumentValue: "\\n\\n\\n\\n"),
            (optionValue: "//\n//\n//a\n//\n//", argumentValue: "\\n\\na\\n\\n"),
            (optionValue: "//\n//a\n//\n//a\n//", argumentValue: "\\na\\n\\na\\n"),
            (optionValue: "//a\n//", argumentValue: "a\\n"),
            (optionValue: "//a\n//b", argumentValue: "//a\\n//b"),
        ]

        validateDescriptor(descriptor, id: "header", name: "Header", argumentName: "header", propertyName: "fileHeader")
        validateArgumentsFreeTextType(descriptor, expectations: validations, default: "ignore")
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
        validateDescriptor(descriptor, id: "insert-lines", name: "Insert Lines", argumentName: "insertlines", propertyName: "insertBlankLines")
        validateArgumentsBinaryType(descriptor, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"], default: true)
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
        validateDescriptor(descriptor, id: "remove-lines", name: "Remove Lines", argumentName: "removelines", propertyName: "removeBlankLines")
        validateArgumentsBinaryType(descriptor, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"], default: true)
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
        validateDescriptor(descriptor, id: "hex-literals", name: "hexliterals", argumentName: "hexliterals", propertyName: "hexLiteralCase")
        validateArgumentsBinaryType(descriptor, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"], default: true)
        validateFromOptions(descriptor, keyPath: \FormatOptions.uppercaseHex, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(descriptor, keyPath: \FormatOptions.uppercaseHex)
        validateDescriptorThrowsOptionsError(descriptor)
    }

    func testWrapElements() {
        let descriptor = FormatOptions.Descriptor.wrapElements
        let expectedMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "beforefirst"),
            (optionValue: .afterFirst, argumentValue: "afterfirst"),
            (optionValue: .disabled, argumentValue: "disabled"),
        ]
        validateDescriptor(descriptor, id: "wrap-elements", name: "Wrap Elements", argumentName: "wrapelements", propertyName: "wrapCollections")
        validateArgumentsListType(descriptor, validArguments: ["beforefirst", "afterfirst", "disabled"], default: "beforefirst")
        validateFromOptions(descriptor, keyPath: \FormatOptions.wrapCollections, expectations: expectedMapping)
        validateFromArguments(descriptor, keyPath: \FormatOptions.wrapCollections, expectations: expectedMapping)
        validateDescriptorThrowsOptionsError(descriptor)
    }
}
