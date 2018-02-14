//
//  EnumAssociatableTest.swift
//  SwiftFormat
//
//  Created by Vincent Bernier on 13-02-18.
//  Copyright © 2018 Nick Lockwood.
//

@testable import SwiftFormat
import XCTest

class EnumAssociatableTest: XCTestCase {
}

// MARK: - Retreiving Associated Value

extension EnumAssociatableTest {
    enum Sut: EnumAssociatable {
        case nothing
        case string(String)
        case optionalString(String?)
        case intTuple(first: Int, second: Int?)
    }

    func test_givenString_thenString() {
        let sut = Sut.string("b")
        let result: String = sut.associatedValue()
        XCTAssertEqual(result, "b")
    }

    func test_givenDString_thenDString() {
        let sut = Sut.string("D")
        let result: String = sut.associatedValue()
        XCTAssertEqual(result, "D")
    }

    func test_givenOptionalNilString_thenNil() {
        let sut = Sut.optionalString(nil)
        let result: String? = sut.associatedValue()
        XCTAssertNil(result)
    }

    func test_givenOptionalBString_thenBString() {
        let sut = Sut.optionalString("D")
        let resut: String? = sut.associatedValue()
        XCTAssertTrue(resut == "D")
    }

    func test_givenIntTuple3Nil_then3Nil() {
        let sut = Sut.intTuple(first: 3, second: nil)
        let result: (Int, Int?) = sut.associatedValue()
        XCTAssertEqual(result.0, 3)
        XCTAssertNil(result.1)
    }
}

// MARK: - Not testable

extension EnumAssociatableTest {
    struct MyStruct: EnumAssociatable {
        let name: String
    }

    func test_givenCaseNothint_thenImpossibleToCall() {
        // not able to make this work
        //        let set = Sut.nothing
        //        let result: nil.self = sut.associatedValue()
        //        let result: Void = sut.associatedValue()
    }

//    func test_givenAStruct_thenCrash() {
//        //  precondition is not testable
//        let sut = MyStruct(name: "name")
//        let result: String = sut.associatedValue()
//    }
}
