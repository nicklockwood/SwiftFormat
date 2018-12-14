//
//  EnumAssociableTest.swift
//  SwiftFormat
//
//  Created by Vincent Bernier on 13-02-18.
//  Copyright © 2018 Nick Lockwood.
//

import XCTest
@testable import SwiftFormat

class EnumAssociableTests: XCTestCase {
    // MARK: associatedValue

    private enum TestEnum: EnumAssociable {
        case nothing
        case string(String)
        case optionalString(String?)
        case intTuple(first: Int, second: Int?)
        case closure((Bool) -> Bool) // this case don't work properly
    }

    func testString() {
        let input = TestEnum.string("b")
        XCTAssertEqual(input.associatedValue(), "b")
    }

    func testOptionalString() {
        let input = TestEnum.optionalString("D")
        XCTAssertEqual(input.associatedValue(), "D")
    }

    func testNilOptionalString() {
        let input = TestEnum.optionalString(nil)
        XCTAssertNil(input.associatedValue())
    }

    func testTuple() {
        let input = TestEnum.intTuple(first: 3, second: nil)
        let result: (Int?, Int?) = input.associatedValue()
        XCTAssertEqual(result.0, 3)
        XCTAssertNil(result.1)
    }

    func testNothingAsAnyOptional() {
        // not able to make this work
        let input = TestEnum.nothing
        let result: String? = input.associatedValue()
        XCTAssertNil(result)
    }

    // MARK: Not testable

//    struct MyStruct: EnumAssociable {
//        let name: String
//    }
//
//    func testCrashIfValueIsStruct() {
//        //  precondition is not testable
//        let input = MyStruct(name: "name")
//        XCTAssertNotNil(input.associatedValue()) // Crashes
//    }
//
//    func testCrashIfValueIsClosure() {
//        let input = TestEnum.closure { return $0 == true }
//        let result: (Bool) -> Bool = input.associatedValue()
//        XCTAssertTrue(result(true)) // Crashes
//    }
}
