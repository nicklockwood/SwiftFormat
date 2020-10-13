//
//  shared.swift
//  JSON
//
//  Created by Nick Lockwood on 01/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

/// This code is shared between the interpreted and compiled versions of the JSON parser

/// JSON parsing errors
enum JSONError: Swift.Error {
    case invalidNumber(String)
    case invalidCodePoint(String)
}

/// Labels
enum JSONLabel: String {
    case null
    case boolean
    case number
    case string
    case json
    case array
    case object

    // Internal types
    case unichar
    case keyValue
}

/// Transform
func jsonTransform(_ name: JSONLabel, _ values: [Any]) throws -> Any? {
    switch name {
    case .json:
        return values[0]
    case .boolean:
        return values[0] as! String == "true"
    case .null:
        return nil as Any? as Any
    case .string:
        return (values as! [String]).joined()
    case .number:
        let value = values[0] as! String
        guard let number = Double(value) else {
            throw JSONError.invalidNumber(value)
        }
        return number
    case .array:
        return values
    case .object:
        return Dictionary(values as! [(String, Any)]) { $1 }
    case .keyValue:
        return (values[0] as! String, values[1])
    case .unichar:
        let value = values[0] as! String
        guard let hex = UInt32(value, radix: 16),
              let char = UnicodeScalar(hex)
        else {
            throw JSONError.invalidCodePoint(value)
        }
        return String(char)
    }
}
