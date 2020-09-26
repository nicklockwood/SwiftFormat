//
//  json.swift
//  JSON
//
//  Created by Nick Lockwood on 12/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

/// JSON parser
public func parseJSON(_ input: String) throws -> Any {
    let match = try json.match(input)
    return try match.transform(jsonTransform)!
}

/// JSON compiler
public func compileJSONParser() -> String {
    return json.compile("parseJSON3", transformFunction: "jsonTransform")
}

// JSON grammar
private let space: Consumer<JSONLabel> = .discard(.zeroOrMore(.character(in: " \t\n\r")))
private let null: Consumer<JSONLabel> = .label(.null, "null")
private let boolean: Consumer<JSONLabel> = .label(.boolean, "true" | "false")
private let digit: Consumer<JSONLabel> = .character(in: "0" ... "9")
private let number: Consumer<JSONLabel> = .label(.number, .flatten([
    .optional("-"),
    .any(["0", [.character(in: "1" ... "9"), .zeroOrMore(digit)]]),
    .optional([".", .oneOrMore(digit)]),
    .optional([
        .character(in: "eE"),
        .optional(.character(in: "+-")),
        .oneOrMore(digit),
    ]),
]))
private let hexdigit: Consumer<JSONLabel> = digit | .character(in: "a" ... "f") | .character(in: "A" ... "F")
private let string: Consumer<JSONLabel> = .label(.string, [
    .discard("\""),
    .zeroOrMore(.any([
        .flatten(.oneOrMore(.anyCharacter(except: "\"", "\\"))),
        [.discard("\\"), .any([
            "\"", "\\", "/",
            .replace("b", "\u{8}"),
            .replace("f", "\u{C}"),
            .replace("n", "\n"),
            .replace("r", "\r"),
            .replace("t", "\t"),
            .label(.unichar, .flatten([
                .discard("u"), hexdigit, hexdigit, hexdigit, hexdigit,
            ])),
        ])],
    ])),
    .discard("\""),
])
private let array: Consumer<JSONLabel> = .label(.array, [
    .discard("["),
    .optional(.interleaved(
        .reference(.json),
        .discard(",")
    )),
    .discard("]"),
])
private let object: Consumer<JSONLabel> = .label(.object, [
    .discard("{"),
    .optional(.interleaved(
        .label(.keyValue, [
            space, string, space,
            .discard(":"),
            .reference(.json),
        ]),
        .discard(",")
    )),
    .discard("}"),
])
private let json: Consumer<JSONLabel> = .label(.json, [
    space, boolean | null | number | string | object | array, space,
])
