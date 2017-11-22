//
//  FormatterTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 30/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import SwiftFormat
import XCTest

class FormatterTests: XCTestCase {

    func testRemoveCurrentTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: FormatOptions())
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i)
            }
        }
        XCTAssertEqual(output, input)
    }

    func testRemovePreviousTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: FormatOptions())
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i - 1)
            }
        }
        XCTAssertEqual(output, input)
    }

    func testRemoveNextTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: FormatOptions())
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i + 1)
            }
        }
        XCTAssertEqual(output, [Token](input.dropLast()))
    }

    func testIndexBeforeComment() {
        let input: [Token] = [
            .identifier("foo"),
            .startOfScope("//"),
            .space(" "),
            .commentBody("bar"),
            .linebreak("\n"),
        ]
        let formatter = Formatter(input, options: FormatOptions())
        let index = formatter.index(before: 4, where: { !$0.isSpaceOrComment })
        XCTAssertEqual(index, 0)
    }

    func testIndexBeforeMultilineComment() {
        let input: [Token] = [
            .identifier("foo"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("bar"),
            .space(" "),
            .endOfScope("*/"),
            .linebreak("\n"),
        ]
        let formatter = Formatter(input, options: FormatOptions())
        let index = formatter.index(before: 6, where: { !$0.isSpaceOrComment })
        XCTAssertEqual(index, 0)
    }
}
