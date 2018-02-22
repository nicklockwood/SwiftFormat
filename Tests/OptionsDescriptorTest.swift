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
    typealias OptionArgumentMapping<OPT> = (optionValue: OPT, argumentValue: String)

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

    func validateSutThrowFormatErrorOptions(_ sut: FormatOptions.Descriptor,
                                            invalidArguments: String = "invalid",
                                            testName: String = #function) {
        var options = FormatOptions()
        XCTAssertThrowsError(try sut.toOptions(invalidArguments, &options),
                             "\(testName): Invalid format Throws") { err in
            guard case FormatError.options = err else {
                XCTAssertTrue(false, "\(testName): Throws a FormatError.options error")
                return
            }
        }
    }

    func validateFromArguments<T: Equatable>(sut: FormatOptions.Descriptor,
                                             keyPath: WritableKeyPath<FormatOptions, T>,
                                             expectations: [OptionArgumentMapping<T>],
                                             testName: String = #function) {
        var options = FormatOptions()
        expectations.forEach {
            try! sut.toOptions($0.argumentValue, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument \($0.argumentValue) map to option \($0.optionValue)")
            try! sut.toOptions($0.argumentValue.uppercased(), &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument Uppercased \($0.argumentValue) map to option \($0.optionValue)")
            try! sut.toOptions($0.argumentValue.capitalized, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument capitalized \($0.argumentValue) map to option \($0.optionValue)")
        }
    }

    func validateFromOptionalArguments<T: Equatable>(sut: FormatOptions.Descriptor,
                                                     keyPath: WritableKeyPath<FormatOptions, T?>,
                                                     expectations: [OptionArgumentMapping<T?>],
                                                     testCaseVariation: Bool = true,
                                                     testName: String = #function) {
        var options = FormatOptions()
        expectations.forEach {
            try! sut.toOptions($0.argumentValue, &options)
            XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument \($0.argumentValue) map to option \(String(describing: $0.optionValue))")
            if testCaseVariation {
                try! sut.toOptions($0.argumentValue.uppercased(), &options)
                XCTAssertEqual(options[keyPath: keyPath], $0.optionValue, "\(testName): Argument Uppercased \($0.argumentValue) map to option \(String(describing: $0.optionValue))")
                try! sut.toOptions($0.argumentValue.capitalized, &options)
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
    func validateFromOptions<T>(sut: FormatOptions.Descriptor,
                                keyPath: WritableKeyPath<FormatOptions, T>,
                                expectations: [OptionArgumentMapping<T>],
                                invalid: T? = nil,
                                testName: String = #function) {
        var options = FormatOptions()
        for item in expectations {
            options[keyPath: keyPath] = item.optionValue
            XCTAssertEqual(sut.fromOptions(options), item.argumentValue, "\(testName): Option is transform to argument")
        }

        if let invalid = invalid {
            options[keyPath: keyPath] = invalid
            XCTAssertEqual(sut.fromOptions(options), sut.defaultArgument, "\(testName): invalid input return the defautl value")
        }
    }
}

// MARK: - They all exists

extension OptionsDescriptorTest {
    func allOptionsPropertyName() -> [String] {
        return Mirror(reflecting: FormatOptions()).children.flatMap { $0.label }
    }

    func test_allPropertyHaveADescriptor() {
        let allProperties = Set(allOptionsPropertyName())
        let allDescriptorWithProperty = FormatOptions.Descriptor.deprecatedWithProperty + FormatOptions.Descriptor.formats + FormatOptions.Descriptor.files
        let allDescriptorProperty = Set(allDescriptorWithProperty.map { $0.propertyName })

        XCTAssertEqual(allDescriptorWithProperty.count, allProperties.count, "Property and descriptor have equal count")
        XCTAssertEqual(allDescriptorProperty, allProperties, "Each property have a descriptor with the same property name")
    }

    func test_deprecatedPropertyList() {
        let deprecated = FormatOptions.Descriptor.deprecated
        let controlArgumentNames = Set(["insertlines", "removelines", "hexliterals"])
        let sutArgumentNames = Set(deprecated.map { $0.argumentName })
        XCTAssertEqual(sutArgumentNames, controlArgumentNames, "All deprecated name are represented by a descriptor")
    }
}

// MARK: - Binary Options

extension OptionsDescriptorTest {
    func validateArgumentsBinaryType(sut: FormatOptions.Descriptor,
                                     controlTrue: [String],
                                     controlFalse: [String],
                                     default: Bool,
                                     testName: String = #function) {
        let values: (true: [String], false: [String]) = sut.type.associatedValue()

        let defaultControl = `default` ? controlTrue : controlFalse
        XCTAssertTrue(defaultControl.contains(sut.defaultArgument), "\(testName): Default argument map to \(`default`)")

        XCTAssertEqual(values.true[0], controlTrue[0], "\(testName): First item is prefered parameter name")
        XCTAssertEqual(values.false[0], controlFalse[0], "\(testName): First item is prefered parameter name")
        XCTAssertEqual(Set(values.true), Set(controlTrue), "\(testName): All possible true value have representation")
        XCTAssertEqual(Set(values.false), Set(controlFalse), "\(testName): All possible false value have representation")
    }

    func validateFromArgumentsBinaryType(sut: FormatOptions.Descriptor,
                                         keyPath: WritableKeyPath<FormatOptions, Bool>,
                                         testName: String = #function) {
        let values: (true: [String], false: [String]) = sut.type.associatedValue()
        let mappings: [OptionArgumentMapping<Bool>] =
            values.true.map { (optionValue: true, argumentValue: $0) } + values.false.map { (optionValue: false, argumentValue: $0) }
        validateFromArguments(sut: sut, keyPath: keyPath, expectations: mappings, testName: testName)
    }
}

// MARK: -

extension OptionsDescriptorTest {
    func test_voidRepresentation() {
        let sut = FormatOptions.Descriptor.useVoid
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: false, argumentValue: "tuples"),
            (optionValue: true, argumentValue: "void"),
        ]
        validateSut(sut, id: "void-representation", name: "empty", argumentName: "empty", propertyName: "useVoid")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["void"], controlFalse: ["tuple", "tuples"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.useVoid, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.useVoid)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_allowInlineSemicolons() {
        let sut = FormatOptions.Descriptor.allowInlineSemicolons
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: false, argumentValue: "never"),
            (optionValue: true, argumentValue: "inline"),
        ]
        validateSut(sut, id: "allow-inline-semicolons", name: "allowInlineSemicolons", argumentName: "semicolons", propertyName: "allowInlineSemicolons")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["inline"], controlFalse: ["never", "false"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.allowInlineSemicolons, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.allowInlineSemicolons)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_spaceAroundRangeOperators() {
        let sut = FormatOptions.Descriptor.spaceAroundRangeOperators
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "spaced"),
            (optionValue: false, argumentValue: "nospace"),
        ]
        validateSut(sut, id: "space-around-range-operators", name: "spaceAroundRangeOperators", argumentName: "ranges", propertyName: "spaceAroundRangeOperators")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["space", "spaced", "spaces"], controlFalse: ["nospace"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.spaceAroundRangeOperators, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.spaceAroundRangeOperators)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_spaceAroundOperatorDeclarations() {
        let sut = FormatOptions.Descriptor.spaceAroundOperatorDeclarations
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "spaced"),
            (optionValue: false, argumentValue: "nospace"),
        ]
        validateSut(sut, id: "space-around-operator-declarations", name: "spaceAroundOperatorDeclarations", argumentName: "operatorfunc", propertyName: "spaceAroundOperatorDeclarations")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["space", "spaced", "spaces"], controlFalse: ["nospace"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.spaceAroundOperatorDeclarations, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.spaceAroundOperatorDeclarations)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_indentCase() {
        let sut = FormatOptions.Descriptor.indentCase
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "true"),
            (optionValue: false, argumentValue: "false"),
        ]
        validateSut(sut, id: "indent-case", name: "indentCase", argumentName: "indentcase", propertyName: "indentCase")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["true"], controlFalse: ["false"], default: false)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.indentCase, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.indentCase)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_trailingCommas() {
        let sut = FormatOptions.Descriptor.trailingCommas
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "always"),
            (optionValue: false, argumentValue: "inline"),
        ]
        validateSut(sut, id: "trailing-commas", name: "trailingCommas", argumentName: "commas", propertyName: "trailingCommas")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["always", "true"], controlFalse: ["inline", "false"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.trailingCommas, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.trailingCommas)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_indentComments() {
        let sut = FormatOptions.Descriptor.indentComments
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "indent"),
            (optionValue: false, argumentValue: "ignore"),
        ]
        validateSut(sut, id: "indent-comments", name: "indentComments", argumentName: "comments", propertyName: "indentComments")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["indent", "indented"], controlFalse: ["ignore"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.indentComments, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.indentComments)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_truncateBlankLines() {
        let sut = FormatOptions.Descriptor.truncateBlankLines
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "always"),
            (optionValue: false, argumentValue: "nonblank-lines"),
        ]
        validateSut(sut, id: "truncate-blank-lines", name: "truncateBlankLines", argumentName: "trimwhitespace", propertyName: "truncateBlankLines")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["always"], controlFalse: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank", "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.truncateBlankLines, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.truncateBlankLines)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_insertBlankLines() {
        let sut = FormatOptions.Descriptor.insertBlankLines
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "enabled"),
            (optionValue: false, argumentValue: "disabled"),
        ]
        validateSut(sut, id: "insert-blank-lines", name: "insertBlankLines", argumentName: "insertlines", propertyName: "insertBlankLines")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.insertBlankLines, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.insertBlankLines)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_removeBlankLines() {
        let sut = FormatOptions.Descriptor.removeBlankLines
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "enabled"),
            (optionValue: false, argumentValue: "disabled"),
        ]
        validateSut(sut, id: "remove-blank-lines", name: "removeBlankLines", argumentName: "removelines", propertyName: "removeBlankLines")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.removeBlankLines, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.removeBlankLines)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_allmanBraces() {
        let sut = FormatOptions.Descriptor.allmanBraces
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "true"),
            (optionValue: false, argumentValue: "false"),
        ]
        validateSut(sut, id: "allman-braces", name: "allmanBraces", argumentName: "allman", propertyName: "allmanBraces")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["true", "enabled"], controlFalse: ["false", "disabled"], default: false)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.allmanBraces, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.allmanBraces)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_hexLiteralCase() {
        let sut = FormatOptions.Descriptor.hexLiteralCase
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "uppercase"),
            (optionValue: false, argumentValue: "lowercase"),
        ]
        validateSut(sut, id: "hex-literal-case", name: "hexLiteralCase", argumentName: "hexliteralcase", propertyName: "uppercaseHex")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.uppercaseHex, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.uppercaseHex)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_exponentCase() {
        let sut = FormatOptions.Descriptor.exponentCase
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "uppercase"),
            (optionValue: false, argumentValue: "lowercase"),
        ]
        validateSut(sut, id: "exponent-case", name: "exponentCase", argumentName: "exponentcase", propertyName: "uppercaseExponent")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"], default: false)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.uppercaseExponent, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.uppercaseExponent)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_letPatternPlacement() {
        let sut = FormatOptions.Descriptor.letPatternPlacement
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "hoist"),
            (optionValue: false, argumentValue: "inline"),
        ]
        validateSut(sut, id: "let-pattern-placement", name: "patternLet", argumentName: "patternlet", propertyName: "hoistPatternLet")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["hoist"], controlFalse: ["inline"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.hoistPatternLet, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.hoistPatternLet)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_elsePosition() {
        let sut = FormatOptions.Descriptor.elsePosition
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "next-line"),
            (optionValue: false, argumentValue: "same-line"),
        ]
        validateSut(sut, id: "else-position", name: "elsePosition", argumentName: "elseposition", propertyName: "elseOnNextLine")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["next-line", "nextline"], controlFalse: ["same-line", "sameline"], default: false)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.elseOnNextLine, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.elseOnNextLine)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_removeSelf() {
        let sut = FormatOptions.Descriptor.removeSelf
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "remove"),
            (optionValue: false, argumentValue: "insert"),
        ]
        validateSut(sut, id: "remove-self", name: "removeSelf", argumentName: "self", propertyName: "removeSelf")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["remove"], controlFalse: ["insert"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.removeSelf, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.removeSelf)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_experimentalRules() {
        let sut = FormatOptions.Descriptor.experimentalRules
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "enabled"),
            (optionValue: false, argumentValue: "disabled"),
        ]
        validateSut(sut, id: "experimental-rules", name: "experimentalRules", argumentName: "experimental", propertyName: "experimentalRules")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["enabled", "true"], controlFalse: ["disabled", "false"], default: false)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.experimentalRules, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.experimentalRules)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_fragment() {
        let sut = FormatOptions.Descriptor.fragment
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "true"),
            (optionValue: false, argumentValue: "false"),
        ]
        validateSut(sut, id: "fragment", name: "fragment", argumentName: "fragment", propertyName: "fragment")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["true", "enabled"], controlFalse: ["false", "disabled"], default: false)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.fragment, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.fragment)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_ignoreConflictMarkers() {
        let sut = FormatOptions.Descriptor.ignoreConflictMarkers
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "ignore"),
            (optionValue: false, argumentValue: "reject"),
        ]
        validateSut(sut, id: "ignore-conflict-markers", name: "ignoreConflictMarkers", argumentName: "conflictmarkers", propertyName: "ignoreConflictMarkers")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["ignore", "true", "enabled"], controlFalse: ["reject", "false", "disabled"], default: false)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.ignoreConflictMarkers, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.ignoreConflictMarkers)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_hexliterals_deprecated() {
        let sut = FormatOptions.Descriptor.hexliterals_deprecated
        let fromOptionsExpectation: [OptionArgumentMapping<Bool>] = [
            (optionValue: true, argumentValue: "uppercase"),
            (optionValue: false, argumentValue: "lowercase"),
        ]
        validateSut(sut, id: "hex-literal-deprecated", name: "hexliterals_deprecated", argumentName: "hexliterals", propertyName: "hexliterals")
        validateArgumentsBinaryType(sut: sut, controlTrue: ["uppercase", "upper"], controlFalse: ["lowercase", "lower"], default: true)
        validateFromOptions(sut: sut, keyPath: \FormatOptions.uppercaseHex, expectations: fromOptionsExpectation)
        validateFromArgumentsBinaryType(sut: sut, keyPath: \FormatOptions.uppercaseHex)
        validateSutThrowFormatErrorOptions(sut)
    }
}

// MARK: - List Options

extension OptionsDescriptorTest {
    func validateArgumentsListType(sut: FormatOptions.Descriptor,
                                   validArguments: Set<String>,
                                   default: String,
                                   testName: String = #function) {
        let values: [String] = sut.type.associatedValue()

        XCTAssertEqual(Set(values), validArguments, "\(testName): All valid arguments are accounted for")
        XCTAssertEqual(sut.defaultArgument, `default`, "\(testName): Default argument is \(`default`)")
        XCTAssertTrue(validArguments.contains(sut.defaultArgument), "\(testName): Default argument is part of the valide arguments")
    }
}

// MARK: -

extension OptionsDescriptorTest {
    func test_ifdefIndent() {
        let sut = FormatOptions.Descriptor.ifdefIndent
        let expectedMapping: [OptionArgumentMapping<IndentMode>] = [
            (optionValue: IndentMode.indent, argumentValue: "indent"),
            (optionValue: IndentMode.noIndent, argumentValue: "noindent"),
            (optionValue: IndentMode.outdent, argumentValue: "outdent"),
        ]

        validateSut(sut, id: "if-def-indent-mode", name: "ifdefIndent", argumentName: "ifdef", propertyName: "ifdefIndent")
        validateArgumentsListType(sut: sut, validArguments: ["indent", "noindent", "outdent"], default: "indent")
        validateFromOptions(sut: sut, keyPath: \FormatOptions.ifdefIndent, expectations: expectedMapping)
        validateFromArguments(sut: sut, keyPath: \FormatOptions.ifdefIndent, expectations: expectedMapping)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_linebreakChar() {
        let sut = FormatOptions.Descriptor.lineBreak
        let expectedMapping: [OptionArgumentMapping<String>] = [
            (optionValue: "\n", argumentValue: "lf"),
            (optionValue: "\r", argumentValue: "cr"),
            (optionValue: "\r\n", argumentValue: "crlf"),
        ]
        validateSut(sut, id: "linebreak-character", name: "linebreak", argumentName: "linebreaks", propertyName: "linebreak")
        validateArgumentsListType(sut: sut, validArguments: ["cr", "lf", "crlf"], default: "lf")
        validateFromOptions(sut: sut, keyPath: \FormatOptions.linebreak, expectations: expectedMapping, invalid: "invalid")
        validateFromArguments(sut: sut, keyPath: \FormatOptions.linebreak, expectations: expectedMapping)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_wrapArguments() {
        let sut = FormatOptions.Descriptor.wrapArguments
        let expectedMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "beforefirst"),
            (optionValue: .afterFirst, argumentValue: "afterfirst"),
            (optionValue: .disabled, argumentValue: "disabled"),
        ]
        validateSut(sut, id: "wrap-arguments", name: "wrapArguments", argumentName: "wraparguments", propertyName: "wrapArguments")
        validateArgumentsListType(sut: sut, validArguments: ["beforefirst", "afterfirst", "disabled"], default: "disabled")
        validateFromOptions(sut: sut, keyPath: \FormatOptions.wrapArguments, expectations: expectedMapping)
        validateFromArguments(sut: sut, keyPath: \FormatOptions.wrapArguments, expectations: expectedMapping)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_wrapElements() {
        let sut = FormatOptions.Descriptor.wrapElements
        let expectedMapping: [OptionArgumentMapping<WrapMode>] = [
            (optionValue: .beforeFirst, argumentValue: "beforefirst"),
            (optionValue: .afterFirst, argumentValue: "afterfirst"),
            (optionValue: .disabled, argumentValue: "disabled"),
        ]
        validateSut(sut, id: "wrap-elements", name: "wrapElements", argumentName: "wrapelements", propertyName: "wrapElements")
        validateArgumentsListType(sut: sut, validArguments: ["beforefirst", "afterfirst", "disabled"], default: "beforefirst")
        validateFromOptions(sut: sut, keyPath: \FormatOptions.wrapElements, expectations: expectedMapping)
        validateFromArguments(sut: sut, keyPath: \FormatOptions.wrapElements, expectations: expectedMapping)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_stripUnusedArguments() {
        let sut = FormatOptions.Descriptor.stripUnusedArguments
        let expectedMapping: [OptionArgumentMapping<ArgumentStrippingMode>] = [
            (optionValue: .unnamedOnly, argumentValue: "unnamed-only"),
            (optionValue: .closureOnly, argumentValue: "closure-only"),
            (optionValue: .all, argumentValue: "always"),
        ]
        validateSut(sut, id: "strip-unused-arguments", name: "stripUnusedArguments", argumentName: "stripunusedargs", propertyName: "stripUnusedArguments")
        validateArgumentsListType(sut: sut, validArguments: ["unnamed-only", "closure-only", "always"], default: "always")
        validateFromOptions(sut: sut, keyPath: \FormatOptions.stripUnusedArguments, expectations: expectedMapping)
        validateFromArguments(sut: sut, keyPath: \FormatOptions.stripUnusedArguments, expectations: expectedMapping)
        validateSutThrowFormatErrorOptions(sut)
    }
}

// MARK: - Free Text Options

extension OptionsDescriptorTest {
    typealias FreeTextValidationExpectation = (input: String, isValid: Bool)

    func validateArgumentsFreeTextType(sut: FormatOptions.Descriptor,
                                       expectations: [FreeTextValidationExpectation],
                                       default: String,
                                       testName: String = #function) {
        guard case let FormatOptions.Descriptor.ArgumentType.freeText(validator) = sut.type else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(sut.defaultArgument, `default`, "\(testName): Default Argument value is: \(`default`)")
        expectations.forEach {
            XCTAssert(validator($0.input) == $0.isValid, "\(testName): \($0.input) isValid: \($0.isValid)")
        }
    }

    func validateGroupingSut(_ sut: FormatOptions.Descriptor,
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

        validateSut(sut, id: id, name: name, argumentName: argumentName, propertyName: propertyName, testName: testName)
        validateArgumentsFreeTextType(sut: sut, expectations: expectations, default: `default`, testName: testName)
        validateFromOptions(sut: sut, keyPath: keyPath, expectations: fromOptionExpectations, testName: testName)
        validateFromArguments(sut: sut, keyPath: keyPath, expectations: fromArgumentExpectations, testName: testName)
        validateSutThrowFormatErrorOptions(sut, testName: testName)
    }
}

// MARK: -

extension OptionsDescriptorTest {
    func test_decimalGrouping() {
        validateGroupingSut(FormatOptions.Descriptor.decimalGrouping,
                            id: "decimal-grouping",
                            name: "decimalGrouping",
                            argumentName: "decimalgrouping",
                            propertyName: "decimalGrouping",
                            default: "3,6",
                            keyPath: \FormatOptions.decimalGrouping)
    }

    func test_binaryGrouping() {
        validateGroupingSut(FormatOptions.Descriptor.binaryGrouping,
                            id: "binary-grouping",
                            name: "binaryGrouping",
                            argumentName: "binarygrouping",
                            propertyName: "binaryGrouping",
                            default: "4,8",
                            keyPath: \FormatOptions.binaryGrouping)
    }

    func test_octalGrouping() {
        validateGroupingSut(FormatOptions.Descriptor.octalGrouping,
                            id: "octal-grouping",
                            name: "octalGrouping",
                            argumentName: "octalgrouping",
                            propertyName: "octalGrouping",
                            default: "4,8",
                            keyPath: \FormatOptions.octalGrouping)
    }

    func test_hexGrouping() {
        validateGroupingSut(FormatOptions.Descriptor.hexGrouping,
                            id: "hex-grouping",
                            name: "hexGrouping",
                            argumentName: "hexgrouping",
                            propertyName: "hexGrouping",
                            default: "4,8",
                            keyPath: \FormatOptions.hexGrouping)
    }

    func test_indentation() {
        let sut = FormatOptions.Descriptor.indentation
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

        validateSut(sut, id: "indentation", name: "indent", argumentName: "indent", propertyName: "indent")
        validateArgumentsFreeTextType(sut: sut, expectations: validations, default: "4")
        validateFromOptions(sut: sut, keyPath: \FormatOptions.indent, expectations: fromOptionExpectations)
        validateFromArguments(sut: sut, keyPath: \FormatOptions.indent, expectations: fromArgumentExpectations)
        validateSutThrowFormatErrorOptions(sut)
    }

    func test_fileHeader() {
        let sut = FormatOptions.Descriptor.fileHeader
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

        validateSut(sut, id: "file-header", name: "fileHeader", argumentName: "header", propertyName: "fileHeader")
        validateArgumentsFreeTextType(sut: sut, expectations: validations, default: "ignore")
        validateFromOptions(sut: sut, keyPath: \FormatOptions.fileHeader, expectations: fromOptionExpectations)
        validateFromOptionalArguments(sut: sut, keyPath: \FormatOptions.fileHeader, expectations: fromArgumentExpectations, testCaseVariation: false)
    }
}
