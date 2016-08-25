//
//  SwiftFormat
//  SwiftFormat.swift
//
//  Version 0.5
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Charcoal Design
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

/// Format code with specified rules and options
public func format(source: String,
    rules: [FormatRule] = defaultRules,
    options: FormattingOptions = FormattingOptions()) -> String {

    // Parse
    var tokens = tokenize(source)

    // Format
    let formatter = Formatter(tokens, options: options)
    rules.forEach { $0(formatter) }
    tokens = formatter.tokens

    // Output
    return tokens.reduce("", combine: { $0 + $1.string })
}
