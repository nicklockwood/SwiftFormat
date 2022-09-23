//
//  main.swift
//  REPL
//
//  Created by Nick Lockwood on 02/03/2018.
//  Copyright © 2018 Nick Lockwood. All rights reserved.
//

import Foundation

/// Prevent control characters confusing parser
private let start = UnicodeScalar(63232)!
private let end = UnicodeScalar(63235)!
private let cursorCharacters = CharacterSet(charactersIn: start ... end)

/// Persistent state
private let state = State()

while true {
    print("> ", terminator: "")
    guard var input = readLine() else { break }
    input = String(input.unicodeScalars.filter { !cursorCharacters.contains($0) })
    do {
        if let result = try evaluate(input, state: state) {
            print(result)
        }
    } catch {
        print("error: \(error)")
    }
}
