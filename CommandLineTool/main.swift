//
//  main.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 12/08/2016.
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

import Foundation

extension String {
    private static let black = "\u{001B}[0;30m"
    var inBlack: String { return "\(String.black)\(self)" }
    var inRed: String { return "\u{001B}[0;31m\(self)\(String.black)" }
    var inGreen: String { return "\u{001B}[0;32m\(self)\(String.black)" }
    var inYellow: String { return "\u{001B}[0;33m\(self)\(String.black)" }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            write(data)
        }
    }
}

private var stderr = FileHandle.standardError

CLI.print = { message, type in
    switch type {
    case .info:
        print(message.inBlack)
    case .success:
        print(message.inGreen)
    case .error:
        print(message.inRed, to: &stderr)
    case .warning:
        print(message.inYellow, to: &stderr)
    case .output:
        print(message)
    }
}

// Pass in arguments
processArguments(CommandLine.arguments)
