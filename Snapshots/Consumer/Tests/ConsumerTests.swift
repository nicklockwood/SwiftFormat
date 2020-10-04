//
//  ConsumerTests.swift
//  ConsumerTests
//
//  Created by Nick Lockwood on 01/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Consumer
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
@testable import Consumer

class ConsumerTests: XCTestCase {
    // MARK: Primitives

    func testString() {
        let parser: Consumer<String> = .string("foo")
        XCTAssertEqual(try parser.match("foo"), .token("foo", .at(0 ..< 3)))
        XCTAssertThrowsError(try parser.match("foobar"))
        XCTAssertThrowsError(try parser.match("barfoo"))
        XCTAssertThrowsError(try parser.match(""))
    }

    func testCharacter() {
        let parser: Consumer<String> = .character(in: "a" ... "c")
        XCTAssertEqual(try parser.match("a"), .token("a", .at(0 ..< 1)))
        XCTAssertEqual(try parser.match("c"), .token("c", .at(0 ..< 1)))
        XCTAssertThrowsError(try parser.match("d"))
        XCTAssertThrowsError(try parser.match("A"))
        XCTAssertThrowsError(try parser.match(""))
    }

    // MARK: Combinators

    func testAnyOf() {
        let parser: Consumer<String> = .any([.string("foo"), .string("bar")])
        XCTAssertEqual(try parser.match("foo"), .token("foo", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match("bar"), .token("bar", .at(0 ..< 3)))
        XCTAssertThrowsError(try parser.match("foobar"))
        XCTAssertThrowsError(try parser.match("barfoo"))
        XCTAssertThrowsError(try parser.match(""))
    }

    func testSequence() {
        let parser: Consumer<String> = .sequence([.string("foo"), .string("bar")])
        XCTAssertEqual(try parser.match("foobar"), .node(nil, [.token("foo", .at(0 ..< 3)), .token("bar", .at(3 ..< 6))]))
        XCTAssertThrowsError(try parser.match("foo"))
        XCTAssertThrowsError(try parser.match("barfoo"))
        XCTAssertThrowsError(try parser.match(""))
    }

    func testOptional() {
        let parser: Consumer<String> = .optional(.string("foo"))
        XCTAssertEqual(try parser.match("foo"), .token("foo", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertThrowsError(try parser.match("foobar"))
        XCTAssertThrowsError(try parser.match("barfoo"))
    }

    func testOptional2() {
        let parser: Consumer<String> = .sequence([.optional(.string("foo")), .string("bar")])
        XCTAssertEqual(try parser.match("bar"), .node(nil, [.token("bar", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("foobar"), .node(nil, [.token("foo", .at(0 ..< 3)), .token("bar", .at(3 ..< 6))]))
        XCTAssertThrowsError(try parser.match("foo"))
        XCTAssertThrowsError(try parser.match("barfoo"))
        XCTAssertThrowsError(try parser.match(""))
    }

    func testZeroOrMore() {
        let parser: Consumer<String> = .zeroOrMore(.string("foo"))
        XCTAssertEqual(try parser.match("foo"), .node(nil, [.token("foo", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("foofoo"), .node(nil, [.token("foo", .at(0 ..< 3)), .token("foo", .at(3 ..< 6))]))
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertThrowsError(try parser.match("foobar"))
        XCTAssertThrowsError(try parser.match("barfoo"))
    }

    func testZeroOrMore2() {
        let parser: Consumer<String> = .zeroOrMore(.character(in: "a" ... "f"))
        XCTAssertEqual(try parser.match("abc"), .node(nil, [.token("a", .at(0 ..< 1)), .token("b", .at(1 ..< 2)), .token("c", .at(2 ..< 3))]))
    }

    func testNot() {
        let parser: Consumer<String> = .not("foo")
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertThrowsError(try parser.match("foo"))
    }

    func testNot2() {
        let parser: Consumer<String> = .flatten(["/*", .zeroOrMore([.not("*/"), .anyCharacter()]), "*/"])
        XCTAssertEqual(try parser.match("/* abc */"), .token("/* abc */", .at(0 ..< 9)))
        XCTAssertEqual(try parser.match("/*******/"), .token("/*******/", .at(0 ..< 9)))
    }

    // MARK: Standard transforms

    func testFlattenOptional() {
        let parser: Consumer<String> = .flatten(.optional(.string("foo")))
        XCTAssertEqual(try parser.match("foo"), .token("foo", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match(""), .token("", .at(0 ..< 0)))
    }

    func testFlattenAnyString() {
        let parser: Consumer<String> = .flatten("foo" | "bar")
        XCTAssertEqual(try parser.match("bar"), .token("bar", .at(0 ..< 3)))
    }

    func testFlattenAnySequence() {
        let parser: Consumer<String> = .flatten(["a", "b"] | ["b", "a"])
        XCTAssertEqual(try parser.match("ab"), .token("ab", .at(0 ..< 2)))
    }

    func testFlattenStringSequence() {
        let parser: Consumer<String> = .flatten(["foo", "bar"])
        XCTAssertEqual(try parser.match("foobar"), .token("foobar", .at(0 ..< 6)))
    }

    func testFlattenZeroOrMoreStrings() {
        let parser: Consumer<String> = .flatten(.zeroOrMore("foo"))
        XCTAssertEqual(try parser.match("foofoofoo"), .token("foofoofoo", .at(0 ..< 9)))
    }

    func testFlattenZeroOrMoreCharacters() {
        let parser: Consumer<String> = .flatten(.zeroOrMore(.character(in: "a" ... "f")))
        XCTAssertEqual(try parser.match("abcefecba"), .token("abcefecba", .at(0 ..< 9)))
    }

    func testDiscardAnyString() {
        let parser: Consumer<String> = .discard("foo" | "bar")
        XCTAssertEqual(try parser.match("bar"), .node(nil, []))
    }

    func testDiscardAnySequence() {
        let parser: Consumer<String> = .discard(["a", "b"] | ["b", "a"])
        XCTAssertEqual(try parser.match("ab"), .node(nil, []))
    }

    func testDiscardStringSequence() {
        let parser: Consumer<String> = .discard(["foo", "bar"])
        XCTAssertEqual(try parser.match("foobar"), .node(nil, []))
    }

    func testDiscardZeroOrMoreStrings() {
        let parser: Consumer<String> = .discard(.zeroOrMore("foo"))
        XCTAssertEqual(try parser.match("foofoofoo"), .node(nil, []))
    }

    func testDiscardZeroOrMoreCharacters() {
        let parser: Consumer<String> = .discard(.zeroOrMore(.character(in: "a" ... "f")))
        XCTAssertEqual(try parser.match("abcefecba"), .node(nil, []))
    }

    func testReplaceSequence() {
        let parser: Consumer<String> = .replace([.string("foo"), .string("bar")], "baz")
        XCTAssertEqual(try parser.match("foobar"), .token("baz", .at(0 ..< 6)))
    }

    // MARK: Sugar

    func testStringLiteralConstructor() {
        let foo: Consumer<String> = "foo"
        XCTAssertEqual(foo, .string("foo"))
    }

    func testArrayLiteralConstructor() {
        let foobar: Consumer<String> = ["foo", "bar"]
        XCTAssertEqual(foobar, .sequence(["foo", "bar"]))
    }

    func testArrayLiteralConstructor2() {
        let foobar: Consumer<String> = ["foo"]
        XCTAssertEqual(foobar, "foo")
    }

    func testOrOperator() {
        let fooOrBar: Consumer<String> = "foo" | "bar"
        XCTAssertEqual(fooOrBar, .any(["foo", "bar"]))
    }

    func testOrOperator2() {
        let fooOrBarOrBaz: Consumer<String> = "foo" | .any(["bar", "baz"])
        XCTAssertEqual(fooOrBarOrBaz, .any(["foo", "bar", "baz"]))
    }

    func testOrOperator3() {
        let fooOrBarOrBaz: Consumer<String> = .any(["foo", "bar"]) | "baz"
        XCTAssertEqual(fooOrBarOrBaz, .any(["foo", "bar", "baz"]))
    }

    func testOrOperator4() {
        let fooOrBarOrBazOrQuux: Consumer<String> = .any(["foo", "bar"]) | .any(["baz", "quux"])
        XCTAssertEqual(fooOrBarOrBazOrQuux, .any(["foo", "bar", "baz", "quux"]))
    }

    func testOrOperator5() {
        let aOrB: Consumer<String> = .character("a") | .character("b")
        XCTAssertEqual(aOrB, .character(in: "a" ... "b"))
    }

    func testOrOperator6() {
        let aToE: Consumer<String> = .character(in: "a" ... "c") | .character(in: "b" ... "e")
        XCTAssertEqual(aToE, .character(in: "abcde"))
    }

    func testOrOperator7() {
        let aOrC: Consumer<String> = .anyCharacter(except: "a", "c")
        XCTAssertEqual(aOrC, .anyCharacter(except: "a", "b", "c") | .character("b"))
    }

    func testOrOperator8() {
        let aOrC: Consumer<String> = .anyCharacter(except: "a", "c")
        XCTAssertEqual(aOrC, .character("b") | .anyCharacter(except: "a", "b", "c"))
    }

    // MARK: Composite rules

    func testOneOrMore() {
        let parser: Consumer<String> = .oneOrMore(.string("foo"))
        XCTAssertEqual(try parser.match("foo"), .node(nil, [.token("foo", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("foofoo"), .node(nil, [.token("foo", .at(0 ..< 3)), .token("foo", .at(3 ..< 6))]))
        XCTAssertThrowsError(try parser.match("foobar"))
        XCTAssertThrowsError(try parser.match("barfoo"))
        XCTAssertThrowsError(try parser.match(""))
    }

    func testInterleaved() {
        let parser: Consumer<String> = .interleaved("a", ",")
        XCTAssertEqual(try parser.match("a,a"), .node(nil, [
            .token("a", .at(0 ..< 1)), .token(",", .at(1 ..< 2)), .token("a", .at(2 ..< 3)),
        ]))
        XCTAssertEqual(try parser.match("a"), .node(nil, [.token("a", .at(0 ..< 1))]))
        XCTAssertThrowsError(try parser.match("a,"))
        XCTAssertThrowsError(try parser.match("a,a,"))
        XCTAssertThrowsError(try parser.match("a,b"))
        XCTAssertThrowsError(try parser.match("aa"))
        XCTAssertThrowsError(try parser.match(""))
    }

    func testIgnoreInSequenceAndAny() {
        let space: Consumer<String> = .discard(.zeroOrMore(.character(in: .whitespaces)))
        let parser: Consumer<String> = .ignore(space, in: ["a" | "b", "=", "c"])
        XCTAssertEqual(try parser.match("a=c"), .node(nil, [
            .token("a", .at(0 ..< 1)), .token("=", .at(1 ..< 2)), .token("c", .at(2 ..< 3)),
        ]))
        XCTAssertEqual(try parser.match(" b = c "), .node(nil, [
            .token("b", .at(1 ..< 2)), .token("=", .at(3 ..< 4)), .token("c", .at(5 ..< 6)),
        ]))
        XCTAssertEqual(try parser.match("a  = c"), .node(nil, [
            .token("a", .at(0 ..< 1)), .token("=", .at(3 ..< 4)), .token("c", .at(5 ..< 6)),
        ]))
    }

    func testIgnoreInOneOrMoreAndOptional() {
        let space: Consumer<String> = .discard(.zeroOrMore(.character(in: .whitespaces)))
        let parser: Consumer<String> = .ignore(space, in: .zeroOrMore("foo"))
        XCTAssertEqual(try parser.match("foofoo"), .node(nil, [
            .token("foo", .at(0 ..< 3)), .token("foo", .at(3 ..< 6)),
        ]))
        XCTAssertEqual(try parser.match(" foo foo "), .node(nil, [
            .token("foo", .at(1 ..< 4)), .token("foo", .at(5 ..< 8)),
        ]))
        XCTAssertEqual(try parser.match(" "), .node(nil, []))
    }

    func testNoIgnoreInFlatten() {
        let space: Consumer<String> = .discard(.zeroOrMore(.character(in: .whitespaces)))
        let parser: Consumer<String> = .ignore(space, in: .flatten(.oneOrMore(.character(in: "a" ... "z"))))
        XCTAssertEqual(try parser.match(" abc "), .node(nil, [.token("abc", .at(1 ..< 4))]))
        XCTAssertThrowsError(try parser.match("ab c"))
    }

    // MARK: Errors

    func testUnmatchedInput() {
        let parser: Consumer<String> = "foo"
        let input = "foo "
        XCTAssertThrowsError(try parser.match(input)) { error in
            let error = error as! Consumer<String>.Error
            switch error.kind {
            case .unexpectedToken:
                XCTAssertEqual(error.location?.offset.column, 4)
            default:
                XCTFail()
            }
            XCTAssertEqual(error.description, "Unexpected token ' ' at 1:4")
        }
    }

    func testEmptyInput() {
        let parser: Consumer<String> = "foo"
        let input = ""
        XCTAssertThrowsError(try parser.match(input)) { error in
            let error = error as! Consumer<String>.Error
            switch error.kind {
            case .expected("foo"):
                XCTAssertEqual(error.location?.offset.column, 1)
            default:
                XCTFail()
            }
            XCTAssertEqual(error.description, "Expected 'foo' at 1:1")
        }
    }

    func testUnexpectedToken() {
        let parser: Consumer<String> = ["foo", "bar"]
        let input = "foofoobar"
        XCTAssertThrowsError(try parser.match(input)) { error in
            let error = error as! Consumer<String>.Error
            switch error.kind {
            case .expected("bar"):
                XCTAssertEqual(error.location?.offset.column, 4)
            default:
                XCTFail()
            }
            XCTAssertEqual(error.description, "Unexpected token 'foobar' at 1:4 (expected 'bar')")
        }
    }

    func testBestMatch() {
        let parser: Consumer<String> = ["foo", "bar"] | [.oneOrMore("foo"), "baz"]
        let input = "foofoobar"
        XCTAssertThrowsError(try parser.match(input)) { error in
            let error = error as! Consumer<String>.Error
            switch error.kind {
            case .expected("baz"):
                XCTAssertEqual(error.location?.offset.column, 7)
            default:
                XCTFail()
            }
            XCTAssertEqual(error.description, "Unexpected token 'bar' at 1:7 (expected 'baz')")
        }
    }

    func testUnterminatedSequence() {
        let parser: Consumer<String> = ["a", "=", "5"]
        let input = "a=6"
        XCTAssertThrowsError(try parser.match(input)) { error in
            let error = error as! Consumer<String>.Error
            switch error.kind {
            case .expected("5"):
                XCTAssertEqual(error.location?.offset.column, 3)
            default:
                XCTFail()
            }
            XCTAssertEqual(error.description, "Unexpected token '6' at 1:3 (expected '5')")
        }
    }

    // MARK: Consumer description

    func testLabelAndReferenceDescription() {
        XCTAssertEqual(Consumer<String>.label("foo", "bar").description, "foo")
        XCTAssertEqual(Consumer<String>.reference("foo").description, "foo")
    }

    func testStringDescription() {
        XCTAssertEqual(Consumer<String>.string("foo").description, "'foo'")
        XCTAssertEqual(Consumer<String>.string("\0").description, "'\\0'")
        XCTAssertEqual(Consumer<String>.string("\t").description, "'\\t'")
        XCTAssertEqual(Consumer<String>.string("\r").description, "'\\r'")
        XCTAssertEqual(Consumer<String>.string("\n").description, "'\\n'")
        XCTAssertEqual(Consumer<String>.string("\r\n").description, "'\\r\\n'")
        XCTAssertEqual(Consumer<String>.string("\"").description, "'\"'")
        XCTAssertEqual(Consumer<String>.string("'").description, "'''")
        XCTAssertEqual(Consumer<String>.string("' ").description, "'' '")
        XCTAssertEqual(Consumer<String>.string("ö").description, "'ö'")
        XCTAssertEqual(Consumer<String>.string("👍").description, "'👍'")
        XCTAssertEqual(Consumer<String>.string("\u{8}").description, "'\\u{8}'")
        XCTAssertEqual(Consumer<String>.string("Thanks 👍").description, "'Thanks 👍'")
    }

    func testCharacterDescription() {
        XCTAssertEqual(Consumer<String>.character("!").description, "'!'")
        XCTAssertEqual(Consumer<String>.character(in: "A" ... "F").description, "'A' – 'F'")
        XCTAssertEqual(Consumer<String>
            .character(in: UnicodeScalar(11)! ... UnicodeScalar(17)!).description, "U+000B – U+0011")
        XCTAssertEqual(Consumer<String>.character(in: "👍" ... "👍").description, "'👍'")
        XCTAssertEqual(Consumer<String>.character(in: "12").description, "'1' or '2'")
        XCTAssertEqual(Consumer<String>.character(in: "1356").description, "'1', '3', '5' or '6'")
        XCTAssertEqual(Consumer<String>.character(in: "\"").description, "'\"'")
        XCTAssertEqual(Consumer<String>.character(in: "'").description, "'''")
        XCTAssertEqual(Consumer<String>.character(in: "").description, "nothing")
        XCTAssertEqual(Consumer<String>.character("\u{8}").description, "U+0008")
        XCTAssertEqual(Consumer<String>.anyCharacter(except: "\"").description, "any character except '\"'")
        XCTAssertEqual(Consumer<String>.anyCharacter().description, "any character")
    }

    func testAnyDescription() {
        XCTAssertEqual(Consumer<String>.any(["foo", "bar"]).description, "'foo' or 'bar'")
        XCTAssertEqual(Consumer<String>.any(["foo", "foo"]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.any(["a", "b", "c"]).description, "'a', 'b' or 'c'")
        XCTAssertEqual(Consumer<String>.any(["a", "b", "a"]).description, "'a' or 'b'")
        XCTAssertEqual(Consumer<String>.any(["a", "a", "b"]).description, "'a' or 'b'")
        XCTAssertEqual(Consumer<String>.any([.optional("a"), "b"]).description, "'a' or 'b'")
        XCTAssertEqual(Consumer<String>.any([.optional("foo"), "bar"]).description, "'foo' or 'bar'")
        XCTAssertEqual(Consumer<String>.any(["foo"]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.any([]).description, "nothing")
    }

    func testSequenceDescription() {
        XCTAssertEqual(Consumer<String>.sequence(["foo", "bar"]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.sequence(["a" | "b"]).description, "'a' or 'b'")
        XCTAssertEqual(Consumer<String>.sequence([.optional("a"), "b"]).description, "'a' or 'b'")
        XCTAssertEqual(Consumer<String>.sequence(["foo"]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.sequence([.reference("foo")]).description, "foo")
        XCTAssertEqual(Consumer<String>.sequence([.label("foo", "bar")]).description, "foo")
        XCTAssertEqual(Consumer<String>.sequence([.sequence(["foo"])]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.sequence([[.optional("foo"), "b"]]).description, "'foo' or 'b'")
        XCTAssertEqual(Consumer<String>.sequence([[.optional("foo"), "foo"]]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.sequence([.flatten("foo")]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.sequence([.discard("foo")]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.sequence([.replace("foo", "bar")]).description, "'foo'")
        XCTAssertEqual(Consumer<String>.sequence([]).description, "nothing")
    }

    func testOptionalAndZeroOrMore() {
        XCTAssertEqual(Consumer<String>.optional("foo").description, "'foo'")
        XCTAssertEqual(Consumer<String>.zeroOrMore("foo").description, "'foo'")
        XCTAssertEqual(Consumer<String>.zeroOrMore(.optional("foo")).description, "'foo'")
    }

    func testFlattenDiscardReplace() {
        XCTAssertEqual(Consumer<String>.flatten("foo").description, "'foo'")
        XCTAssertEqual(Consumer<String>.discard("foo").description, "'foo'")
        XCTAssertEqual(Consumer<String>.replace("foo", "bar").description, "'foo'")
    }

    // MARK: Match descriptions

    func testTokenDescription() {
        XCTAssertEqual(Consumer<String>.Match.token("foo", .at(0 ..< 3)).description, "'foo'")
        XCTAssertEqual(Consumer<String>.Match.token("a", .at(1 ..< 2)).description, "'a'")
    }

    func testNodeDescription() {
        XCTAssertEqual(Consumer<String>.Match.node(nil, [.token("foo", .at(0 ..< 3))]).description, "('foo')")
        XCTAssertEqual(Consumer<String>.Match.node(nil, []).description, "()")
        XCTAssertEqual(Consumer<String>.Match.node(nil, [
            .token("foo", .at(0 ..< 3)), .token("bar", .at(0 ..< 3)),
        ]).description, "(\n    'foo'\n    'bar'\n)")
        XCTAssertEqual(Consumer<String>.Match.node("foo", [.token("bar", .at(0 ..< 3))]).description, "(foo 'bar')")
        XCTAssertEqual(Consumer<String>.Match.node("foo", []).description, "(foo)")
        XCTAssertEqual(Consumer<String>.Match.node("foo", [
            .token("bar", .at(0 ..< 3)), .token("baz", .at(0 ..< 3)),
        ]).description, "(foo\n    'bar'\n    'baz'\n)")
    }

    func testNestedNodeDescription() {
        XCTAssertEqual(Consumer<String>.Match.node("foo", [
            .node("bar", [.token("baz", .at(0 ..< 3)), .token("quux", .at(0 ..< 4))]),
        ]).description, """
        (foo (bar
            'baz'
            'quux'
        ))
        """)
        XCTAssertEqual(Consumer<String>.Match.node("foo", [
            .node("bar", [.token("baz", .at(0 ..< 3))]),
            .node("quux", []),
        ]).description, """
        (foo
            (bar 'baz')
            (quux)
        )
        """)
    }

    // MARK: isOptional

    func testStringIsNotOptional() {
        let parser: Consumer<String> = .string("abc")
        XCTAssertFalse(parser.isOptional)
    }

    func testEmptyStringIsOptional() {
        let parser: Consumer<String> = .string("")
        XCTAssertTrue(parser.isOptional)
    }

    func testCharsetIsNotOptional() {
        let parser: Consumer<String> = .character("a")
        XCTAssertFalse(parser.isOptional)
    }

    func testEmptyCharsetIsNotOptional() {
        let parser: Consumer<String> = .character(in: CharacterSet(charactersIn: ""))
        XCTAssertFalse(parser.isOptional)
    }

    func testAnyNonOptionalIsNotOptional() {
        let parser: Consumer<String> = .any(["foo", "bar"])
        XCTAssertFalse(parser.isOptional)
    }

    func testAnyWithOneOptionalIsOptional() {
        let parser: Consumer<String> = .any([.optional("foo"), "bar"])
        XCTAssertTrue(parser.isOptional)
    }

    func testEmptyAnyIsOptional() {
        let parser: Consumer<String> = .any([])
        XCTAssertTrue(parser.isOptional)
    }

    func testSequenceWithOneIsOptionalIsNotOptional() {
        let parser: Consumer<String> = .sequence([.optional("foo"), "bar"])
        XCTAssertFalse(parser.isOptional)
    }

    func testSequenceWithAllOptionalIsOptional() {
        let parser: Consumer<String> = .sequence([.optional("foo"), .optional("bar")])
        XCTAssertTrue(parser.isOptional)
    }

    func testEmptySequenceIsOptional() {
        let parser: Consumer<String> = .sequence([])
        XCTAssertTrue(parser.isOptional)
    }

    func testOptionalIsOptional() {
        let parser: Consumer<String> = .optional("foo")
        XCTAssertTrue(parser.isOptional)
    }

    func testOneOrMoreNonOptionalIsNotOptional() {
        let parser: Consumer<String> = .oneOrMore("foo")
        XCTAssertFalse(parser.isOptional)
    }

    func testOneOrMoreOptionalIsOptional() {
        let parser: Consumer<String> = .oneOrMore(.optional("foo"))
        XCTAssertTrue(parser.isOptional)
    }

    func testFlattenNonOptionalIsNotOptional() {
        let parser: Consumer<String> = .flatten("foo")
        XCTAssertFalse(parser.isOptional)
    }

    func testFlattenOptionalIsOptional() {
        let parser: Consumer<String> = .flatten(.optional("foo"))
        XCTAssertTrue(parser.isOptional)
    }

    func testDiscardNonOptionalIsNotOptional() {
        let parser: Consumer<String> = .discard("foo")
        XCTAssertFalse(parser.isOptional)
    }

    func testDiscardOptionalIsOptional() {
        let parser: Consumer<String> = .discard(.optional("foo"))
        XCTAssertTrue(parser.isOptional)
    }

    func testReplaceNonOptionalIsNotOptional() {
        let parser: Consumer<String> = .replace("foo", "bar")
        XCTAssertFalse(parser.isOptional)
    }

    func testReplaceOptionalIsOptional() {
        let parser: Consumer<String> = .replace(.optional("foo"), "bar")
        XCTAssertTrue(parser.isOptional)
    }

    func testLabelNonOptionalIsNotOptional() {
        let parser: Consumer<String> = .label("foo", "bar")
        XCTAssertFalse(parser.isOptional)
    }

    func testLabelOptionalIsOptional() {
        let parser: Consumer<String> = .label("foo", .optional("bar"))
        XCTAssertTrue(parser.isOptional)
    }

    func testReferenceNonOptionalIsNotOptional() {
        let parser: Consumer<String> = .label("foo", .oneOrMore(.reference("foo") | .string("bar")))
        XCTAssertFalse(parser.isOptional)
    }

    func testReferenceOptionalIsOptional() {
        let parser: Consumer<String> = .label("foo", .oneOrMore(.reference("foo") | .optional(.string("bar"))))
        XCTAssertTrue(parser.isOptional)
    }

    // MARK: Edge cases with optionals

    func testReplaceOptional() {
        // Replacement is applied even if nothing is matched
        let parser: Consumer<String> = .replace(.optional("foo"), "bar")
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match("foo"), .token("bar", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match(""), .token("bar", .at(0 ..< 0)))
        XCTAssertThrowsError(try parser.match("bar"))
    }

    func testDiscardOptional() {
        let parser: Consumer<String> = .discard(.optional("foo"))
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match("foo"), .node(nil, []))
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertThrowsError(try parser.match("bar"))
    }

    func testOneOrMoreOptionals() {
        let parser: Consumer<String> = .oneOrMore(.optional("foo"))
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertEqual(try parser.match("foo"), .node(nil, [.token("foo", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("foofoo"), .node(nil, [
            .token("foo", .at(0 ..< 3)), .token("foo", .at(3 ..< 6)),
        ]))
    }

    func testFlattenOneOrMoreOptionals() {
        let parser: Consumer<String> = .flatten(.oneOrMore(.optional("foo")))
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match(""), .token("", .at(0 ..< 0)))
        XCTAssertEqual(try parser.match("foo"), .token("foo", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match("foofoo"), .token("foofoo", .at(0 ..< 6)))
    }

    func testDiscardOneOrMoreOptionals() {
        let parser: Consumer<String> = .discard(.oneOrMore(.optional("foo")))
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertEqual(try parser.match("foo"), .node(nil, []))
        XCTAssertEqual(try parser.match("foofoo"), .node(nil, []))
    }

    func testOneOrMoreReplaceOptionals() {
        // This behavior sort of makes sense, but is very weird
        let parser: Consumer<String> = .oneOrMore(.replace(.optional("foo"), "bar"))
        XCTAssertEqual(try parser.match(""), .node(nil, [.token("bar", .at(0 ..< 0))]))
        XCTAssertEqual(try parser.match("foo"), .node(nil, [
            .token("bar", .at(0 ..< 3)), .token("bar", .at(3 ..< 3)),
        ]))
        XCTAssertEqual(try parser.match("foofoo"), .node(nil, [
            .token("bar", .at(0 ..< 3)), .token("bar", .at(3 ..< 6)), .token("bar", .at(6 ..< 6)),
        ]))
    }

    func testFlattenOneOrMoreReplaceOptionals() {
        let parser: Consumer<String> = .flatten(.oneOrMore(.replace(.optional("foo"), "bar")))
        XCTAssertEqual(try parser.match(""), .token("bar", .at(0 ..< 0)))
        XCTAssertEqual(try parser.match("foo"), .token("barbar", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match("foofoo"), .token("barbarbar", .at(0 ..< 6)))
    }

    func testOneOrMoreZeroOrMores() {
        let parser: Consumer<String> = .oneOrMore(.zeroOrMore("foo"))
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertEqual(try parser.match("foo"), .node(nil, [.token("foo", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("foofoo"), .node(nil, [
            .token("foo", .at(0 ..< 3)), .token("foo", .at(3 ..< 6)),
        ]))
    }

    func testAnyOptionals() {
        let parser: Consumer<String> = .optional("foo") | .optional("bar")
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertEqual(try parser.match("foo"), .token("foo", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match("bar"), .token("bar", .at(0 ..< 3)))
    }

    func testFlattenAnyOptionals() {
        let parser: Consumer<String> = .flatten(.optional("foo") | .optional("bar"))
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match(""), .token("", .at(0 ..< 0)))
        XCTAssertEqual(try parser.match("foo"), .token("foo", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match("bar"), .token("bar", .at(0 ..< 3)))
    }

    func testDiscardAnyOptionals() {
        let parser: Consumer<String> = .discard(.optional("foo") | .optional("bar"))
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertEqual(try parser.match("foo"), .node(nil, []))
        XCTAssertEqual(try parser.match("bar"), .node(nil, []))
    }

    func testSequenceOfOptionals() {
        let parser: Consumer<String> = [.optional("foo"), .optional("bar")]
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertEqual(try parser.match("foo"), .node(nil, [.token("foo", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("bar"), .node(nil, [.token("bar", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("foobar"), .node(nil, [
            .token("foo", .at(0 ..< 3)), .token("bar", .at(3 ..< 6)),
        ]))
    }

    func testFlattenSequenceOfOptionals() {
        let parser: Consumer<String> = .flatten([.optional("foo"), .optional("bar")])
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match(""), .token("", .at(0 ..< 0)))
        XCTAssertEqual(try parser.match("foo"), .token("foo", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match("bar"), .token("bar", .at(0 ..< 3)))
        XCTAssertEqual(try parser.match("foobar"), .token("foobar", .at(0 ..< 6)))
    }

    func testDiscardSequenceOfOptionals() {
        let parser: Consumer<String> = .discard([.optional("foo"), .optional("bar")])
        XCTAssertTrue(parser.isOptional)
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertEqual(try parser.match("foo"), .node(nil, []))
        XCTAssertEqual(try parser.match("bar"), .node(nil, []))
        XCTAssertEqual(try parser.match("foobar"), .node(nil, []))
    }

    func testEmptyAny() {
        let parser: Consumer<String> = .any([])
        XCTAssertEqual(try parser.match(""), .node(nil, []))
    }

    func testFlattenEmptyAny() {
        let parser: Consumer<String> = .flatten(.any([]))
        XCTAssertEqual(try parser.match(""), .token("", .at(0 ..< 0)))
    }

    func testDiscardEmptyAny() {
        let parser: Consumer<String> = .discard(.any([]))
        XCTAssertEqual(try parser.match(""), .node(nil, []))
    }

    func testEmptySequence() {
        let parser: Consumer<String> = .sequence([])
        XCTAssertEqual(try parser.match(""), .node(nil, []))
    }

    func testFlattenEmptySequence() {
        let parser: Consumer<String> = .flatten(.sequence([]))
        XCTAssertEqual(try parser.match(""), .token("", .at(0 ..< 0)))
    }

    func testDiscardEmptySequence() {
        let parser: Consumer<String> = .discard(.sequence([]))
        XCTAssertEqual(try parser.match(""), .node(nil, []))
    }

    func testOneOrMoreAnyOptionals() {
        let parser: Consumer<String> = .oneOrMore(.optional("foo") | .optional("bar"))
        XCTAssertEqual(try parser.match(""), .node(nil, []))
        XCTAssertEqual(try parser.match("foo"), .node(nil, [.token("foo", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("bar"), .node(nil, [.token("bar", .at(0 ..< 3))]))
        XCTAssertEqual(try parser.match("barfoo"), .node(nil, [
            .token("bar", .at(0 ..< 3)), .token("foo", .at(3 ..< 6)),
        ]))
    }

    func testInterleavedSequenceFollowedByOptionalSeparator() {
        let item: Consumer<String> = .character(in: "0" ... "9")
        let parser: Consumer<String> = [
            "[", .optional(" "), .interleaved(item, " "), .optional(" "), "]",
        ]
        XCTAssertEqual(try parser.match("[ 1 2 3 ]"), .node(nil, [
            .token("[", .at(0 ..< 1)), .token(" ", .at(1 ..< 2)),
            .token("1", .at(2 ..< 3)), .token(" ", .at(3 ..< 4)),
            .token("2", .at(4 ..< 5)), .token(" ", .at(5 ..< 6)),
            .token("3", .at(6 ..< 7)), .token(" ", .at(7 ..< 8)),
            .token("]", .at(8 ..< 9)),
        ]))
    }

    // MARK: Edge case with character sets

    func testCharacterSet() {
        let parser: Consumer<String> = .character(in: CharacterSet(charactersIn: "𝚨󌞑"))
        guard case let .charset(charset) = parser else {
            XCTFail()
            return
        }
        XCTAssertEqual(charset.ranges, [120488 ... 120488, 837521 ... 837521])
    }

    // MARK: Transforms

    func testStringTransform() {
        let parser: Consumer<String> = "foo"
        XCTAssertEqual(try parser.match("foo").transform { _, _ in XCTFail(); return () } as? String, "foo")
    }

    func testLabelledStringTransform() {
        let parser: Consumer<String> = .label("foo", "foo")
        XCTAssertEqual(try parser.match("foo").transform { $1[0] } as? String, "foo")
    }

    func testLabelledListTransform() {
        let parser: Consumer<String> = .oneOrMore("foo")
        XCTAssertEqual(try parser.match("foofoo").transform { $1 } as! [String], ["foo", "foo"])
    }
}
