//
//  main.swift
//  JSON
//
//  Created by Nick Lockwood on 01/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

/// Example input
let input = """
{
    "foo": true,
    "bar": [0, 1, 2.0, -0.7, null, "hello world"],
    "baz": {
        "quux": 2e-006
    }
}
"""

@discardableResult
func time<T>(_ block: () throws -> T) -> T {
    let time = CFAbsoluteTimeGetCurrent()
    var result: Any = ()
    do {
        result = try block()
    } catch {
        print(error)
    }
    print(Int((CFAbsoluteTimeGetCurrent() - time) * 1000), terminator: " ms\n\n")
    return result as! T
}

// Evaluate json using interpreted parser
time { try print("interpreted:", parseJSON(input)) }

// Evaluate json using handwritten parser
time { try print("handwritten:", parseJSON2(input)) }

// Evaluate json using compiled parser
time { try print("compiled:", parseJSON3(input)!) }

/// Update compiled parser
print("Recompiling parser...")
let compiledSwiftFile = URL(fileURLWithPath: #file)
    .deletingLastPathComponent().appendingPathComponent("compiled.swift")
let parser = time { compileJSONParser() }
try parser.write(to: compiledSwiftFile, atomically: true, encoding: .utf8)
